VGT_ADDON_NAME, VGT = ...
VGT.VERSION = GetAddOnMetadata(VGT_ADDON_NAME, "Version")
VGT.LIBS = LibStub("AceAddon-3.0"):NewAddon(VGT_ADDON_NAME, "AceComm-3.0", "AceTimer-3.0", "AceEvent-3.0")
VGT.LIBS.HBD = LibStub("HereBeDragons-2.0")
VGT.LIBS.HBDP = LibStub("HereBeDragons-Pins-2.0")
VGT.CORE_FRAME = CreateFrame("Frame")
VGT.CoreMessageReceived = EventHandler:New()

local MODULE_NAME = "VGT-Core"

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local handleInstanceChangeEvent = function()
  local _, instanceType, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
  if (instanceType == "party" or instanceType == "raid") then
    local dungeonData = nil
    if (VGT.trackedRaids[tonumber(instanceID)]) then
      dungeonData = VGT.raids[tonumber(instanceID)]
    else
      dungeonData = VGT.dungeons[tonumber(instanceID)]
    end
    if (dungeonData ~= nil) then
      local dungeonName = dungeonData[1]
      if (dungeonName ~= nil) then
        VGT.Log(VGT.LOG_LEVEL.INFO, "Started logging for %s, goodluck!", dungeonName)
        VGT.CORE_FRAME:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      else
        VGT.Log(VGT.LOG_LEVEL.DEBUG, "Entered %s(%s) but it is not a tracked dungeon.", (dungeonName or "?"), (instanceID or "?"))
      end
    end
  else
    VGT.CORE_FRAME:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  end
end

local handleTargetChangeEvent = function()
  if (UnitClassification("target") == "worldboss") then
    local unitType, _, _, _, _, unitID = strsplit("-", cUID)
    local bossData = VGT.bosses[unitID]
    if (unitType == "creature" and bossData and VGT.CheckGroupForGuildies()) then
      if (not VGT_LOTTERY_DB) then
        VGT_LOTTERY_DB = {}
      end

      if (guildName) then
        if (VGT_LOTTERY_DB[guildName]) then
          VGT_LOTTERY_DB[guildName] = {}
        end

        local player = UnitName("player")
        if (not VGT_LOTTERY_DB[guildName][player]) then
          VGT_LOTTERY_DB[guildName][player] = {}
        end

         if (not VGT_LOTTERY_DB[guildName][player].WORLDBOSS) then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS = {}
        end

        local bossName = bossData[1]
        if (bossName == "Azuregos") then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS.Azuregos = GetServerTime()
        elseif (bossName == "Lord Kazzak") then
           VGT_LOTTERY_DB[guildName][player].WORLDBOSS.LordKazzak = GetServerTime()
        elseif (bossName == "Ysondre") then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS.Ysondre = GetServerTime()
        elseif (bossName == "Lethon") then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS.Lethon = GetServerTime()
        elseif (bossName == "Ermeriss") then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS.Ermeriss = GetServerTime()
        elseif (bossName == "Taerar") then
          VGT_LOTTERY_DB[guildName][player].WORLDBOSS.Taerar = GetServerTime()
        end
      end
    end
  end
end

local handleCoreMessageReceivedEvent = function(prefix, message, _, sender)
  if prefix == MODULE_NAME then
    VGT.CoreMessageReceived(message, sender)
  end
end

local loaded = false
local entered = false
local rostered = false
local function onEvent(_, event)
  if (not loaded and event == "ADDON_LOADED") then
    VGT.OPTIONS = VGT.DefaultConfig(VGT_OPTIONS)
    loaded = true
  end

  if (VGT.OPTIONS.enabled) then
    if (loaded and event == "ADDON_LOADED") then
      VGT.Map_Initialize()
      VGT.LIBS:RegisterComm(MODULE_NAME, handleCoreMessageReceivedEvent)
    end
    if (loaded) then
      if (event == "PLAYER_ENTERING_WORLD") then
        handleInstanceChangeEvent()
        if (not entered) then
          GuildRoster()
          VGT.VersionChecker:Check()
          VGT.Log(VGT.LOG_LEVEL.TRACE, "initialized with version %s", VGT.VERSION)
          entered = true
        end
      end
      if (not rostered and event == "GUILD_ROSTER_UPDATE") then
        if (IsInGuild()) then
          VGT.EP_Initialize()
          VGT.Lottery_Initialize()
          rostered = true
        end
      end
      if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        VGT.HandleCombatLogEvent()
      end
      if (event == "PLAYER_TARGET_CHANGED") then
        handleTargetChangeEvent()
      end
    end
  end
  if (loaded and event == "PLAYER_LOGOUT") then
    VGT_OPTIONS = VGT.OPTIONS
  end
end
VGT.CORE_FRAME:RegisterEvent("ADDON_LOADED")
VGT.CORE_FRAME:RegisterEvent("PLAYER_ENTERING_WORLD")
VGT.CORE_FRAME:RegisterEvent("GUILD_ROSTER_UPDATE")
VGT.CORE_FRAME:RegisterEvent("PLAYER_LOGOUT")
VGT.CORE_FRAME:SetScript("OnEvent", onEvent)

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

function VGT:SendCoreMessage(message, channel, target)
  self.LIBS:SendCommMessage(MODULE_NAME, message, channel, target)
end
