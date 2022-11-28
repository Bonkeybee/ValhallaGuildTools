local VGT_ADDON_NAME, ValhallaGuildTools = ...
local COMMAND_MODULE = "VGT-CMD"

VGT = LibStub("AceAddon-3.0"):NewAddon(ValhallaGuildTools, VGT_ADDON_NAME, "AceComm-3.0", "AceEvent-3.0")
VGT.version = GetAddOnMetadata(VGT_ADDON_NAME, "Version")
VGT:SetDefaultModuleState(true)
VGT:SetDefaultModuleLibraries("AceEvent-3.0")

-- Module proto
local Module = {}

function Module:OnInitialize()
  VGT.LogTrace("Initialized module %q", self.moduleName)
  self.profile = VGT.db.profile[self.moduleName]
  self.char = VGT.db.char[self.moduleName]
  if self.profile and self.profile.enabled ~= nil then
    self:SetEnabledState(self.profile.enabled)
  end
end

function Module:RegisterCommand(command, handler)
  local commandName = VGT.CommandNames[command]
  if not commandName then
    VGT.LogError("Unknown command %q", command)
    return
  end
  self:RegisterMessage("VGT_CMD_" .. commandName, handler or commandName)
end

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

VGT.MapOutput = {
  MAP = 1,
  MINIMAP = 2,
  BOTH = 3
}

VGT.LogLevel = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
  SYSTEM = 6
}

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

VGT.CommandNames = {}

for name, id in pairs(VGT.Commands) do
  VGT.CommandNames[id] = name
end

CreateFrame("GameTooltip", "VGTScanningTooltip", nil, "GameTooltipTemplate")
VGTScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function serializeArg(arg)
  local t = type(arg)
  if t == "nil" or t == "string" or t == "number" or t == "boolean" then
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

  self:InitializeMinimapButton()
  
  if IsInGuild() then
    GuildRoster()
    self.LogTrace("Requesting addon version from guild")
    self:SendGuildAddonCommand(VGT.Commands.GET_VERSION, self.version)
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

function VGT:SendGuildAddonCommand(command, ...)
  if IsInGuild() then
    self:SendAddonCommand("GUILD", nil, command, ...)
  else
    VGT.LogInfo("Tried to send guild command %s while not in a guild.")
  end
end

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

function VGT:SendPlayerAddonCommand(player, command, ...)
  self:SendAddonCommand("WHISPER", player, command, ...)
end

function VGT:SendAddonCommand(channel, target, command, ...)
  local message = command
  local paramCount = select("#", ...)

  for i = 1, paramCount do
    message = message .. "\001" .. serializeArg(select(i, ...))
  end

  self:SendCommMessage(COMMAND_MODULE, message, channel, target)
end

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

function VGT:LOOT_READY(_, autoLoot)
  self.LogTrace("Loot ready. Auto-Loot is %s", autoLoot)
  local lootmethod, masterlooterPartyID, _ = GetLootMethod()
  if (GetNumLootItems() > 0 and lootmethod == "master" and masterlooterPartyID == 0) then
    if strsplit("-", GetLootSourceInfo(1) or "", 2) ~= "Item" then
      self:SendMessage("VGT_MASTER_LOOT_READY", autoLoot)
    end
  end
end
