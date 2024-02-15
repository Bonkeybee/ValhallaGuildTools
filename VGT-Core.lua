local VGT_ADDON_NAME, ValhallaGuildTools = ...
local COMMAND_MODULE = "VGT-CMD"

---@class VGT : AceAddon, AceEvent-3.0, AceComm-3.0, { db: VGT.db }
VGT = LibStub("AceAddon-3.0"):NewAddon(ValhallaGuildTools, VGT_ADDON_NAME, "AceComm-3.0", "AceEvent-3.0")
VGT.version = tonumber(C_AddOns.GetAddOnMetadata(VGT_ADDON_NAME, "Version"))

VGT:SetDefaultModuleState(true)
VGT:SetDefaultModuleLibraries("AceEvent-3.0")

---@class Module : AceModule, AceEvent-3.0
local Module = {}

---@private
function Module:OnInitialize()
  VGT.LogTrace("Initialized module %q", self.moduleName)
  self.profile = VGT.db.profile[self.moduleName]
  self.char = VGT.db.char[self.moduleName]
  if self.profile and self.profile.enabled ~= nil then
    self:SetEnabledState(self.profile.enabled)
  end
end

---Registers this module to handle an addon command
---@param command VGT.Command The command to handle
---@param handler string|fun(...)? The callback to invoke when this command is received. Can also be the name of a function on this module. If `nil`, a function with the name of the command on this module is used instead.
function Module:RegisterCommand(command, handler)
  local commandName = VGT.CommandNames[command]
  if not commandName then
    VGT.LogError("Unknown command %q", command)
    return
  end
  self:RegisterMessage("VGT_CMD_" .. commandName, handler or commandName)
end

---Unregisters any command handlers on this module for a command
---@param command VGT.Command the command to unregister
function Module:UnregisterCommand(command)
  local commandName = VGT.CommandNames[command]
  if not commandName then
    VGT.LogError("Unknown command %q", command)
    return
  end
  self:UnregisterMessage("VGT_CMD_" .. commandName)
end

VGT:SetDefaultModulePrototype(Module)

-- Define enums

---@enum VGT.MapOutput
VGT.MapOutput = {
  MAP = 1,
  MINIMAP = 2,
  BOTH = 3
}

---@enum VGT.LogLevel
VGT.LogLevel = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
  SYSTEM = 6
}

---@enum VGT.Command
VGT.Commands = {
  GET_VERSION = "GV",
  VERSION_RESPOND = "VR",
  START_ROLL = "SR",
  CANCEL_ROLL = "CR",
  ASSIGN_ITEM = "AI",
  UNASSIGN_ITEM = "UI",
  ROLL_PASS = "RP",
  NOTIFY_INTERESTED = "NI",
  NOTIFY_PASSING = "NP",
  ITEM_TRACKED = "IT"
}

---@enum VGT.PreemptiveResponse
VGT.PreemptiveResponses = {
  INTERESTED = 1,
  SOFT_PASS = 2,
  HARD_PASS = 3
}

---@type table<string, string>
VGT.CommandNames = {}

for name, id in pairs(VGT.Commands) do
  VGT.CommandNames[id] = name
end

VGT.guildRoster = {}

VGTScanningTooltip = CreateFrame("GameTooltip", "VGTScanningTooltip", nil, "GameTooltipTemplate") --[[@as GameTooltip]]
VGTScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function serializeArg(arg)
  local t = type(arg)
  if t == "nil" or t == "string" or t == "number" or t == "boolean" or t == "table" then
    return json.encode(arg)
  else
    error("Unsupported argument type " .. t)
  end
end

local function deserializeArgs(...)
  local values = {}
  local count = select("#", ...)

  for i = 1, count do
    values[i] = json.decode(select(i, ...))
  end

  return unpack(values)
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

function VGT:OnInitialize()
  self:InitializeOptions()

  self.LogTrace("Initializing addon version %s", self.version)

  self:RegisterComm(COMMAND_MODULE, "HandleCommand")
  self:RegisterEvent("LOOT_READY")
  self:RegisterEvent("GUILD_ROSTER_UPDATE")

  self:InitializeMinimapButton()

  if IsInGuild() then
    C_GuildInfo.GuildRoster()
    self.LogTrace("Requesting addon version from guild")
    self:SendGuildAddonCommand(VGT.Commands.GET_VERSION)
  end
end

function VGT:RefreshConfig()
  self.LogTrace("Configuration changed")

  self:RefreshMinimapButtonConfig()

  for name, module in self:IterateModules() do
    module.profile = VGT.db.profile[module.moduleName]
    module.char = VGT.db.char[module.moduleName]
    if module.profile then
      if module.enabledState and not module.profile.enabled then
        module:Disable()
      elseif not module.enabledState and module.profile.enabled then
        module:Enable()
      end
    end

    if module.enabledState and module.RefreshConfig then
      module:RefreshConfig()
    end
  end
end

---Sends a command to everyone in the guild
---@param command VGT.Command The command to send
---@param ... any The parameters of the command
function VGT:SendGuildAddonCommand(command, ...)
  if IsInGuild() then
    self:SendAddonCommand("GUILD", nil, command, ...)
  else
    VGT.LogInfo("Tried to send guild command %s while not in a guild.")
  end
end

---Sends a command to everyone in the current raid or party
---@param command VGT.Command The command to send
---@param ... any The parameters of the command
function VGT:SendGroupAddonCommand(command, ...)
  local channel
  if UnitInRaid("player") then
    channel = "RAID"
  elseif UnitInParty("player") then
    channel = "PARTY"
  else
    self:SendPlayerAddonCommand(UnitName("player"), command, ...)
  end

  if channel then
    self:SendAddonCommand(channel, nil, command, ...)
  end
end

---Sends a command to the target player
---@param command VGT.Command The command to send
---@param ... any The parameters of the command
function VGT:SendPlayerAddonCommand(player, command, ...)
  self:SendAddonCommand("WHISPER", player, command, ...)
end

---Sends a command to everyone in the current raid or party
---@param channel string The channel to send the command over
---@param target string|nil The name of the target when sending a whisper; the name of a channel when sent over a custom channel; otherwise ignored.
---@param command VGT.Command The command to send
---@param ... any The parameters of the command
function VGT:SendAddonCommand(channel, target, command, ...)
  local message = command
  local paramCount = select("#", ...)

  for i = 1, paramCount do
    message = message .. "\001" .. serializeArg(select(i, ...))
  end

  self:SendCommMessage(COMMAND_MODULE, message, channel, target)
end

---@private
function VGT:HandleCommand(module, message, channel, sender)
  local command, rest = strsplit("\001", message, 2)
  if not command then
    return
  end
  local commandName = self.CommandNames[command]
  if commandName then
    if type(rest) == "string" then
      self:SendMessage("VGT_CMD_" .. commandName, sender, deserializeArgs(strsplit("\001", rest)))
    else
      self:SendMessage("VGT_CMD_" .. commandName, sender)
    end
  end
end

---@private
function VGT:LOOT_READY(_, autoLoot)
  self.LogTrace("Loot ready. Auto-Loot is %s", autoLoot)
  local lootmethod, masterlooterPartyID, _ = GetLootMethod()
  if (GetNumLootItems() > 0 and lootmethod == "master" and masterlooterPartyID == 0) then
    if strsplit("-", GetLootSourceInfo(1) or "", 2) ~= "Item" then
      self:SendMessage("VGT_MASTER_LOOT_READY", autoLoot)
    end
  end
end

function VGT:GUILD_ROSTER_UPDATE()
  if IsInGuild() then
    for i = 1, GetNumGuildMembers() do
      local name, _, _, level, _, _, _, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
      name = strsplit("-", name, 2)
      self.guildRoster[name] = {level = level, class = class}
    end
  end
end
