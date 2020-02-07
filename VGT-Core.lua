VGT_ADDON_NAME, VGT = ...
VGT_VERSION = GetAddOnMetadata(VGT_ADDON_NAME, "Version")
local MODULE_NAME = "VGT-Core"
local LIB = LibStub("AceAddon-3.0"):NewAddon(MODULE_NAME,
"AceComm-3.0", "AceTimer-3.0", "AceEvent-3.0")
local VGT_FRAME = CreateFrame("Frame")

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local HandleInstanceChangeEvent = function()
  local _, instanceType, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
  if (instanceType == "party" or instanceType == "raid") then
    local dungeonName = VGT.dungeons[tonumber(instanceID)]
    if (dungeonName ~= nil) then
      Log(VGT_LOG_LEVEL.INFO, "Started logging for %s, goodluck!", dungeonName)
      VGT_FRAME:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
      Log(VGT_LOG_LEVEL.DEBUG, "Entered %s(%s) but it is not a tracked dungeon.", dungeonName, instanceID)
    end
  else
    VGT_FRAME:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################
function Round(number, decimals)
  return (("%%.%df"):format(decimals)):format(number)
end

function Safe(s)
  if (s == nil) then
    return ""
  end
  return s
end

function Count(t)
  local c = 0
  if (t == nil) then
    return c
  end
  if (type(t) ~= "table") then
    return c
  end
  for _, _ in pairs(t) do
    c = c + 1
  end
  return c
end

function ArrayToSet(array)
  local t = {}
  for _, item in pairs(array) do
    t[item] = true
  end
  return t
end

function SubsetCount(a, b)
  local c = 0
  for k, _ in pairs(a) do
    if (b[k]) then
      c = c + 1
    end
  end
  return c
end

function StringAppend(...)
  local args = {...}
  local str = ""
  for _, v in ipairs(args) do
    if (v ~= nil) then
      str = str..tostring(v)
    end
  end
  return str
end

function TableJoinToArray(a, b)
  local nt = {}
  for _, v in pairs(a) do
    nt[v] = v
  end
  for _, v in pairs(b) do
    nt[v] = v
  end
  return nt
end

function TableKeysToString(t, d)
  return TableToString(t, d, true)
end

function TableToString(t, d, keys, sort, line)
  local s = ""

  if (t == nil) then
    return s
  end

  if (d == nil) then
    d = ","
  end

  if (sort == true) then
    table.sort(t)
    local nt = {}
    for _, v in pairs(t) do
      table.insert(nt, v)
    end
    table.sort(nt)
    t = nt
  end

  for k, v in pairs(t) do
    s = s..d
    if (type(v) == "table") then
      s = s..TableToString(v, d, keys, sort, line)
    else
      local c = nil
      if (keys) then
        c = k
      else
        c = v
      end
      if (line) then
        s = s..c.."\n"
      else
        s = s..c
      end
    end
  end

  if (d ~= nil and d ~= "") then
    return string.sub(s, 2)
  else
    return s
  end
end

function TableContains(t, m)
  if (t == nil) then
    return false
  end

  for _, v in pairs(t) do
    if (v == m) then
      return true
    end
  end

  return false
end

function RandomUUID()
  local template = 'xxxxxxxx'
  return string.gsub(template, '[xy]', function (c) local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb) return string.format('%x', v) end)
end

function GetMyGuildName()
  if (IsInGuild()) then
    return GetGuildInfo("player")
  else
    return nil
  end
end

function IsInMyGuild(playerName)
  if (playerName == nil) then
    return false
  end

  local playerGuildName = GetGuildInfo(playerName)
  if (playerGuildName == nil) then
    return false
  end

  local myGuildName = GetMyGuildName()
  if (myGuildName == nil) then
    return false
  end

  if (myGuildName == playerGuildName) then
    return true
  end

  return false
end

function CheckGroupForGuildies()
  if (IsInGroup() ~= true) then
    return nil
  end

  local groupMembers = GetHomePartyInfo()
  local guildGroupMembers = {}
  local p = 0
  for i = 0, GetNumGroupMembers() do
    local groupMember = groupMembers[i]
    if (IsInMyGuild(groupMember)) then
      guildGroupMembers[p] = groupMember
      Log(VGT_LOG_LEVEL.TRACE, "%s is in my guild", guildGroupMembers[p])
      p = p + 1
    end
  end
  return guildGroupMembers
end

function TableSize(t)
  if (t == nil) then
    return 0
  end

  if (type(t) ~= "table") then
    return 0
  end

  local c = 0
  for k, v in pairs(t) do
    if (v ~= nil) then
      c = c + 1
    end
  end
  return c
end

function PrintAbout()
  Log(VGT_LOG_LEVEL.SYSTEM, "installed version: %s", VGT_VERSION)
end

function PrintHelp()
  Log(VGT_LOG_LEVEL.SYSTEM, "Command List:")
  Log(VGT_LOG_LEVEL.SYSTEM, "/vgt about - version information")
  Log(VGT_LOG_LEVEL.SYSTEM, "/vgt loglevel <%s> - set the addon verbosity (%s)", TableToString(VGT_LOG_LEVELS, "|"), VGT_LOG_LEVELS[logLevel])
  Log(VGT_LOG_LEVEL.SYSTEM, "/vgt dungeontest - sends a dungeon kill test event")
  Log(VGT_LOG_LEVEL.SYSTEM, "/vgt dungeons [timeframeInDays:7] - list of players that killed a dungeon boss within the timeframe")
end

local warnedPlayers = {}
function HandleCoreMessageReceivedEvent(prefix, message, _, sender)
  if (prefix ~= MODULE_NAME) then
    return
  end

  local playerName = UnitName("player")
  if (sender == playerName) then
    return
  end

  local event, version = strsplit(":", message)
  if (event == "SYNCHRONIZATION_REQUEST") then
    if (not warnedPlayers[sender] and version ~= nil and tonumber(version) < tonumber(VGT_VERSION)) then
      SendChatMessage("There is a newer version of "..VGT_ADDON_NAME.." (yours "..version.." < mine "..VGT_VERSION..")", "WHISPER", nil, sender)
      warnedPlayers[sender] = true
    end
  end
end

local function DefaultOrSet(default, value1, value2)
  if (value1 == nil or value1 == value2) then
    return default
  end
  return value1
end

local loaded = false
local entered = false
local rostered = false
local function OnEvent(_, event)
  if (not loaded and event == "ADDON_LOADED") then
    if (VGT_CONFIGURATION == nil) then
      VGT_CONFIGURATION = {
        logLevel = VGT_LOG.LEVELS[VGT_LOG_LEVEL.INFO]
      }
    end
    logLevel = DefaultOrSet(VGT_LOG.LEVELS[VGT_LOG_LEVEL.INFO], VGT_CONFIGURATION.logLevel, 0)

    VGT_Douse_Initialize()
    VGT_Map_Initialize()
    LIB:RegisterComm(MODULE_NAME, HandleCoreMessageReceivedEvent)
    loaded = true
  end

  if (loaded) then
    if (event == "PLAYER_ENTERING_WORLD") then
      HandleInstanceChangeEvent(event)

      if (not entered) then
        GuildRoster()
        LIB:SendCommMessage(MODULE_NAME, "SYNCHRONIZATION_REQUEST:"..VGT_VERSION, "GUILD")
        Log(VGT_LOG_LEVEL.TRACE, "initialized with version %s", VGT_VERSION)
        entered = true
      end
    end

    if (not rostered and event == "GUILD_ROSTER_UPDATE") then
      if (IsInGuild()) then
        LIB:ScheduleTimer(VGT_EP_Initialize, 5)
        rostered = true
      end
    end

    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
      HandleCombatLogEvent(event)
    end

    if (event == "PLAYER_LOGOUT") then
      VGT_CONFIGURATION.logLevel = logLevel
    end
  end

end
VGT_FRAME:RegisterEvent("ADDON_LOADED")
VGT_FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
VGT_FRAME:RegisterEvent("GUILD_ROSTER_UPDATE")
VGT_FRAME:RegisterEvent("PLAYER_LOGOUT")
VGT_FRAME:SetScript("OnEvent", OnEvent)

-- ############################################################
-- ##### SLASH COMMANDS #######################################
-- ############################################################

SLASH_VGT1 = "/vgt"
SlashCmdList["VGT"] = function(message)
  local command, arg1 = strsplit(" ", message)
  if (command == "" or command == "help") then
    PrintHelp()
    return
  end

  if (command == "about") then
    PrintAbout()
  elseif (command == "loglevel") then
    SetLogLevel(arg1)
  elseif (command == "dungeontest") then
    HandleUnitDeath("TEST"..RandomUUID(), "TestDungeon", "TestBoss")
  elseif (command == "dungeons") then
    PrintDungeonList(tonumber(arg1), VGT.debug)
  elseif (command == "douse") then
    CheckForDouse()
  else
    Log(VGT_LOG_LEVEL.ERROR, "invalid command - type `/vgt help` for a list of commands")
  end
end
