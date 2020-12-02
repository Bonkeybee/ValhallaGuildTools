local MODULE_NAME = "VGT-Lottery"
local CleanDatabase = CreateFrame("Frame")
local PushDatabase = CreateFrame("Frame")
local synchronize = false
local cleaning = false
local dbSnapshot = {}
local data



-- function CleanDatabase:onUpdate(_, firstPlayerKey, _, currentGuidKey)
--   local guildName = VGT.GetMyGuildName()
--   if (guildName == nil or VGT_DUNGEON_DB[guildName] == nil or VGT.IsInRaid() or VGT.withinDays(VGT_DB_TIMESTAMP, 0)) then
--     -- Stop the loop
--     cleaning = false
--     CleanDatabase:SetScript("OnUpdate", nil)
--     return nil
--   end

--   self.firstPlayerKey = (self.firstPlayerKey or firstPlayerKey)
--   self.currentPlayerKey = (self.currentPlayerKey or next(VGT_DUNGEON_DB[guildName], self.currentPlayerKey))
--   self.currentGuidKey = (self.currentGuidKey or currentGuidKey)
--   if (self.firstPlayerKey == self.currentPlayerKey) then
--     -- Stop the loop
--     cleaning = false
--     VGT_DB_TIMESTAMP = GetServerTime()
--     CleanDatabase:SetScript("OnUpdate", nil)
--     return nil
--   end

--   -- Check if player exists
--   if (self.currentPlayerKey ~= nil) then
--     -- Get next guid data
--     if (VGT_DUNGEON_DB[guildName][self.currentPlayerKey] ~= nil) then
--       if (VGT.Count(VGT_DUNGEON_DB[guildName][self.currentPlayerKey]) == 0) then
--         VGT.Log(VGT.LOG_LEVEL.DEBUG, "CLEANING %s", self.currentPlayerKey)
--         VGT_DUNGEON_DB[guildName][self.currentPlayerKey] = nil
--       else
--         self.currentGuidKey, data = next(VGT_DUNGEON_DB[guildName][self.currentPlayerKey], self.currentGuidKey)
--       end
--     else
--       self.currentGuidKey = nil
--     end
--     -- Set the firstKeys
--     if (self.firstPlayerKey == nil and self.currentGuidKey == nil) then
--       self.firstPlayerKey = self.currentPlayerKey
--     end
--     -- Check if data exists
--     if (self.currentGuidKey) then
--       local _, dungeonId, bossId = strsplit("-", self.currentGuidKey)
--       dungeonId = tonumber(dungeonId)
--       bossId = tonumber(bossId)

--       local dungeonData = VGT.dungeons[dungeonId]
--       if (not dungeonData and VGT.trackedRaids[dungeonId]) then
--         dungeonData = VGT.raids[dungeonId]
--       end

--       -- Check if data is valid
--       if (not data or type(data) ~= "table" or not dungeonData or not validateRecord(guildName, data[1], dungeonData[1], VGT.bosses[bossId], nil)) then
--         VGT.Log(VGT.LOG_LEVEL.DEBUG, "CLEANING %s", self.currentGuidKey)
--         VGT_DUNGEON_DB[guildName][self.currentPlayerKey][self.currentGuidKey] = nil
--         if (VGT.Count(VGT_DUNGEON_DB[guildName][self.currentPlayerKey]) == 0) then
--           VGT.Log(VGT.LOG_LEVEL.DEBUG, "CLEANING %s", self.currentPlayerKey)
--           VGT_DUNGEON_DB[guildName][self.currentPlayerKey] = nil
--         end
--       end
--     else
--       -- Get the next player data
--       self.currentPlayerKey = next(VGT_DUNGEON_DB[guildName], self.currentPlayerKey)
--     end
--   end
-- end

local function validateTime(timestamp)
    if (timestamp and not VGT.withinDays(timestamp, 8)) then
        return false
    end
    return true
end

-- Send a snapshot of the EPDB
function PushDatabase:onUpdate(sinceLastUpdate, firstPlayerKey, _)
  self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate
  if (synchronize and not cleaning and VGT.CommAvailability() > 50 and self.sinceLastUpdate >= 0.05 and IsInGuild()) then
    local guildName = VGT.GetMyGuildName()
    if (not dbSnapshot or not dbSnapshot[guildName]) then
      return nil
    end

    self.firstPlayerKey = (self.firstPlayerKey or firstPlayerKey)
    self.currentPlayerKey = (self.currentPlayerKey or next(dbSnapshot[guildName], self.currentPlayerKey))

    if (guildName == nil or VGT.IsInRaid() or self.firstPlayerKey == self.currentPlayerKey) then
      -- Stop the loop
      synchronize = false
      self.firstPlayerKey = nil
      self.currentPlayerKey = nil
      return nil
    end

    -- Check if player exists
    if (self.currentPlayerKey ~= nil) then
      -- Get next data
      data = dbSnapshot[guildName][self.currentPlayerKey].WORLDBOSS
      -- Set the firstKeys
      if (self.firstPlayerKey == nil and data == nil) then
        self.firstPlayerKey = self.currentPlayerKey
      end
      -- Check if data exists
      if (data and type(data) == "table") then
        local key = format("%s:%s", guildName, self.currentPlayerKey)
        local value = ""

        -- Check if data is valid
        if (validateTime(data.Azuregos)) then
          value = format("%s", data.Azuregos)
        else
          value = "0"
        end
        if (validateTime(data.LordKazzak)) then
          value = format("%s:%s", value, data.LordKazzak)
        else
          value = format("%s:%s", value, 0)
        end
        if (validateTime(data.Ysondre)) then
          value = format("%s:%s", value, data.Ysondre)
        else
          value = format("%s:%s", value, 0)
        end
        if (validateTime(data.Lethon)) then
          value = format("%s:%s", value, data.Lethon)
        else
          value = format("%s:%s", value, 0)
        end
        if (validateTime(data.Ermeriss)) then
          value = format("%s:%s", value, data.Ermeriss)
        else
          value = format("%s:%s", value, 0)
        end
        if (validateTime(data.Taerar)) then
          value = format("%s:%s", value, data.Taerar)
        else
          value = format("%s:%s", value, 0)
        end

        if (value ~= "" or value ~= "0:0:0:0:0:0") then
            local message = format("%s;%s", key, value)

            -- Send the data
            VGT.Log(VGT.LOG_LEVEL.INFO, "sending %s to GUILD for %s:SYNCHRONIZATION_REQUEST.", message, MODULE_NAME)
            VGT.LIBS:SendCommMessage(MODULE_NAME, message, "GUILD", nil, "BULK")
        end
      else
        -- Get the next player data
        self.currentPlayerKey = next(dbSnapshot[guildName], self.currentPlayerKey)
      end
    end
    self.sinceLastUpdate = 0
  end
end

local handleLotteryMessageReceivedEvent = function(prefix, message, distribution, sender)
  if (prefix ~= MODULE_NAME) then
    return
  end
  local playerName = UnitName("player")
  if (sender == playerName) then
    return
  end

  if (distribution == "GUILD") then
    local key, value = strsplit(";", message)
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

local initialized = false
VGT.Lottery_Initialize = function()
  if (VGT.OPTIONS.LOTTERY.enabled) then
    if (not initialized) then
      if (VGT_LOTTERY_DB == nil) then
        VGT_LOTTERY_DB = {}
      end
    --   CleanDatabase:SetScript(
    --     "OnUpdate",
    --     function(_, sinceLastUpdate, firstPlayerKey, currentPlayerKey, currentGuidKey)
    --       CleanDatabase:onUpdate(sinceLastUpdate, firstPlayerKey, currentPlayerKey, currentGuidKey)
    --     end
    --   )
    --   cleaning = true
      PushDatabase:SetScript(
        "OnUpdate",
        function(_, sinceLastUpdate, firstPlayerKey, currentPlayerKey)
          PushDatabase:onUpdate(sinceLastUpdate, firstPlayerKey, currentPlayerKey)
        end
      )
      dbSnapshot = VGT.DeepCopy(VGT_DUNGEON_DB)
      synchronize = true
      VGT.LIBS:RegisterComm(MODULE_NAME, handleLotteryMessageReceivedEvent)
      initialized = true
    end
  end
end