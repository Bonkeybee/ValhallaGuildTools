local VGT_ADDON_NAME, ValhallaGuildTools = ...
local COMMAND_MODULE = "VGT-CMD"

VGT = LibStub("AceAddon-3.0"):NewAddon(ValhallaGuildTools, VGT_ADDON_NAME, "AceComm-3.0", "AceTimer-3.0", "AceEvent-3.0")
VGT.version = GetAddOnMetadata(VGT_ADDON_NAME, "Version")

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

  self:InitializeMinimapButton()

  self:InitializeMap()
  
  GuildRoster()
  self:CheckVersion()
end

function VGT:RefreshConfig()
  self.LogTrace("Configuration changed")

  self:RefreshMinimapButtonConfig()

  self:RefreshRollWindowConfig()

  self.masterLooter.Refresh()
  self.masterLooter:RefreshWindowConfig()

  self:RefreshMapConfig()
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

VGT._commands = {}

function VGT:HandleCommand(module, message, channel, sender)
  local command, rest = strsplit("\001", message, 2)
  if not command then
    return
  end
  local handler = self._commands[command]
  if handler then
    if type(rest) == "string" then
      handler:Execute(sender, deserializeArgs(strsplit("\001", rest)))
    else
      handler:Execute(sender)
    end
  end
end

function VGT:RegisterCommandHandler(command, handler)
  local handlers = self._commands[command]
  if not handlers then
    handlers = {}
    self._commands[command] = handlers
    function handlers:Execute(sender, ...)
      for _, handler in ipairs(self) do
        handler(sender, ...)
      end
    end
  end
  tinsert(handlers, handler)
  self:RegisterComm(COMMAND_MODULE, "HandleCommand")
end

do
  local registerEvent = VGT.RegisterEvent
  VGT._events = {}

  function VGT:RegisterEvent(event, callback)
    local eventList = self._events[event]
    if (not eventList) then
      eventList = {}
      self._events[event] = eventList
      self[event] = function(s, ...)
        for _, c in ipairs(s._events[event]) do
          c(...)
        end
      end
      registerEvent(self, event)
    end
    table.insert(eventList, callback)
  end
end
