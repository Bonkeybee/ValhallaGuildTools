local MODULE_NAME = "VGT-Map"

local bufferSize = 0
local bufferPins = {}
local players = {}

local FRAME_TYPE = "Frame"
local PLAYER = "player"
local COMM_CHANNEL = "GUILD"
local WHISPER_CHANNEL = "WHISPER"
local COMM_PRIORITY = "NORMAL"
local PERCENT = "%"
local NEW_LINE = "\n"
local DELIMITER = ":"
local NAME_SEPERATOR = "-"
local HP_SEPERATOR = " - "
local BACKGROUND = "BACKGROUND"
local SCRIPT_ENTER = "OnEnter"
local SCRIPT_LEAVE = "OnLeave"
local PIN_TEXTURE = "Interface\\MINIMAP\\ObjectIcons.blp"
local REQUEST_LOCATION_MESSAGE = "RL"

local PIN_SIZE = 10

local blizzardPins
local originalPinsHidden = false
local originalPartyAppearanceData
local originalRaidAppearanceData
local hiddenAppearanceData = {
  size = 0,
  sublevel = UNIT_POSITION_FRAME_DEFAULT_SUBLEVEL,
  texture = UNIT_POSITION_FRAME_DEFAULT_TEXTURE,
  shouldShow = false,
  useClassColor = false,
  showRotation = false
}

local HereBeDragons = LibStub("HereBeDragons-2.0")
local HereBeDragonsPins = LibStub("HereBeDragons-Pins-2.0")

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local colorString = function(colorHex, str)
  return "|c" .. colorHex .. str .. "|r"
end

local getClass = function(name, guildIndex)
  if (guildIndex ~= nil) then
    return select(11, GetGuildRosterInfo(guildIndex))
  end

  if (UnitPlayerOrPetInParty(name)) then
    for i = 1, 5 do
      local unitId = "party" .. i
      if (UnitName(unitId) == name) then
        local class = select(2, UnitClass(unitId))
        if class then
          return class
        end
      end
    end
  end
  if (UnitPlayerOrPetInRaid(name)) then
    for i = 1, 40 do
      local unitId = "raid" .. i
      if (UnitName(unitId) == name) then
        local class = select(2, UnitClass(unitId))
        if class then
          return class
        end
      end
    end
  end
  local numTotalMembers = GetNumGuildMembers()
  for i = 1, numTotalMembers do
    local fullname, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
    if (fullname ~= nil) then
      local memberName = strsplit(NAME_SEPERATOR, fullname)
      if (memberName == name) then
        return class
      end
    end
  end
end

local formatPlayerTooltip = function(player, class)
  if (not class) then
    class = getClass(player.Name, player.GuildNumber)
  end

  local text = colorString(select(4, GetClassColor(class)), player.Name)

  if (player.HP ~= nil) then
    return text ..
      HP_SEPERATOR ..
        colorString(
          "ff" .. VGT.RGBToHex(VGT.ColorGradient(tonumber(player.HP), 1, 0, 0, 1, 1, 0, 0, 1, 0)),
          VGT.Round(player.HP * 100, 0) .. PERCENT
        )
  end
end

local getGuildNumber = function(name)
  local numTotalMembers = GetNumGuildMembers()
  for i = 1, numTotalMembers do
    local fullname = select(1, GetGuildRosterInfo(i))
    if (fullname ~= nil) then
      local memberName = strsplit(NAME_SEPERATOR, fullname)
      if (name == memberName) then
        return i
      end
    end
  end
  return nil
end

local formatTooltip = function(player, distance)
  local text = ""
  local class
  local zone

  if (not player.NotInGuild and player.GuildNumber == nil) then
    player.GuildNumber = getGuildNumber(player.Name)
    if (player.GuildNumber == nil) then
      player.NotInGuild = true
    end
  end

  if (player.GuildNumber ~= nil) then
    _, _, _, _, _, zone, _, _, _, _, class = GetGuildRosterInfo(player.GuildNumber)
    player.Class = class
    if (zone ~= nil) then
      text = zone .. NEW_LINE
    end
  elseif (player.Zone ~= nil) then
    text = player.Zone .. NEW_LINE
  end

  text = text .. formatPlayerTooltip(player, class)

  for _, otherPlayer in pairs(players) do
    if
      (otherPlayer ~= player and otherPlayer.X ~= nil and otherPlayer.Y ~= nil and player.X ~= nil and player.Y ~= nil and
        (math.abs(player.X - otherPlayer.X) + math.abs(player.Y - otherPlayer.Y) < distance))
     then
      text = text .. NEW_LINE .. formatPlayerTooltip(otherPlayer, otherPlayer.Class)
    end
  end

  return text
end

local onLeavePin = function(_)
  GameTooltip:Hide()
end

local createNewPin = function()
  local pin = CreateFrame(FRAME_TYPE, nil, WorldFrame)
  pin:SetWidth(PIN_SIZE)
  pin:SetHeight(PIN_SIZE)
  local texture = pin:CreateTexture(nil, BACKGROUND)
  local width = 0.07
  local height = 0.30
  local x = 0.53
  local y = 0.10
  texture:SetTexCoord(x, x+width, y, y+height) -- Green
  texture:SetAllPoints()
  pin:EnableMouse(true)
  pin.Texture = texture
  return pin
end

local takeFromBufferPool = function()
  if (bufferSize == 0) then
    return createNewPin()
  end
  local pin = bufferPins[bufferSize]
  bufferSize = bufferSize - 1
  return pin
end

local returnToBufferPool = function(pin)
  bufferSize = bufferSize + 1
  bufferPins[bufferSize] = pin
end

local createWorldmapPin = function(player)
  local onEnterPin = function(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    local distance = 50
    local mapId = HereBeDragonsPins.worldmapProvider:GetMap():GetMapID()
    if (mapId) then
      local mapData = HereBeDragons.mapData[mapId]
      if (mapData and mapData.mapType) then
        --todo: these are just my best guesses of distances. Probably should be tweaked.
        if (mapData.mapType == 1) then --world
          distance = 300
        end
        if (mapData.mapType == 2) then --continent
          distance = 100
        end
        if (mapData.mapType == 3) then --zone or city
          distance = 25
        end
      end
    end
    GameTooltip:SetText(formatTooltip(self.Player, distance))
    GameTooltip:Show()
  end
  local pin = takeFromBufferPool()
  pin:SetScript(SCRIPT_ENTER, onEnterPin)
  pin:SetScript(SCRIPT_LEAVE, onLeavePin)
  pin.Texture:SetTexture(PIN_TEXTURE)
  pin.Player = player
  player.WorldmapPin = pin
  player.WorldmapTexture = pin.Texture
end

local createMinimapPin = function(player)
  local onEnterPin = function(self)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    local distance = 15
    --todo set distance for minimap based on zoom level
    GameTooltip:SetText(formatTooltip(self.Player, distance))
    GameTooltip:Show()
  end
  local pin = takeFromBufferPool()
  pin:SetScript(SCRIPT_ENTER, onEnterPin)
  pin:SetScript(SCRIPT_LEAVE, onLeavePin)
  pin.Texture:SetTexture(PIN_TEXTURE)
  pin.Player = player
  player.MinimapPin = pin
  player.MinimapTexture = pin.Texture
end

local addOrUpdatePlayer = function(name, x, y, continentId, hp, fromCommMessage, zone)
  local player = players[name]
  if (not player) then
    player = {}
    createMinimapPin(player)
    createWorldmapPin(player)
    player.X = 0
    player.Y = 0
    player.ContinentId = nil
    player.Name = name
    player.HasCommMessages = false
    player.LastCommReceived = 0
    if (UnitName("target") == name) then
      player.Targeted = true
    end
    players[name] = player
  end

  if (fromCommMessage) then
    player.HasCommMessages = true
    player.LastCommReceived = GetTime()
  end

  player.HP = hp
  player.Zone = zone
  player.PendingLocationChange = (x ~= player.X or y ~= player.Y or continentId ~= player.ContinentId)
  player.X = x
  player.Y = y
  player.ContinentId = continentId
end

local destroyPlayer = function(name)
  local player = players[name]
  if (player ~= nil) then
    players[name] = nil
    HereBeDragonsPins:RemoveWorldMapIcon(MODULE_NAME, player.WorldmapPin)
    HereBeDragonsPins:RemoveMinimapIcon(MODULE_NAME, player.MinimapPin)
    returnToBufferPool(player.WorldmapPin)
    returnToBufferPool(player.MinimapPin)
  end
end

local worldPosition = function(decimals)
  local x, y, instanceMapId = HereBeDragons:GetPlayerWorldPosition()
  local instance = VGT:GetInstance(instanceMapId)
  if (instance) then
    x = instance.X
    y = instance.Y
  end
  return VGT.Round(x, decimals or 0), VGT.Round(y, decimals or 0), instanceMapId
end

local sendMyLocation = function(target)
  if (IsInGuild() and VGT.db.profile.map.sendMyLocation) then
    local x, y, instanceMapId = worldPosition()
    local hp = UnitHealth(PLAYER) / UnitHealthMax(PLAYER)
    if (instanceMapId ~= nil and x ~= nil and y ~= nil and hp ~= nil) then
      local data = instanceMapId .. DELIMITER .. x .. DELIMITER .. y .. DELIMITER .. hp
      if (target ~= nil) then
        VGT:SendCommMessage(MODULE_NAME, data, WHISPER_CHANNEL, target, COMM_PRIORITY)
      else
        if (IsInGuild()) then
          VGT:SendCommMessage(MODULE_NAME, data, COMM_CHANNEL, nil, COMM_PRIORITY)
        end
      end
    end
  end
end

local updatePinColors = function(name, player)
  local width = 0.07
  local height = 0.30
  if (player.Targeted) then
    local x = 0.28
    local y = 0.10
    player.MinimapTexture:SetTexCoord(x, x+width, y, y+height) -- Red
    player.WorldmapTexture:SetTexCoord(x, x+width, y, y+height) -- Red
  elseif (UnitInParty(name)) then
    local x = 0.03
    local y = 0.10
    player.MinimapTexture:SetTexCoord(x, x+width, y, y+height) -- Blue
    player.WorldmapTexture:SetTexCoord(x, x+width, y, y+height) -- Blue
  else
    local x = 0.53
    local y = 0.10
    player.MinimapTexture:SetTexCoord(x, x+width, y, y+height) -- Green
    player.WorldmapTexture:SetTexCoord(x, x+width, y, y+height) -- Green
  end
end

local toggleBlizzardPins = function(show)
  if (not blizzardPins) then
    for bpin in HereBeDragonsPins.worldmapProvider:GetMap():EnumeratePinsByTemplate("GroupMembersPinTemplate") do
      blizzardPins = bpin
      if (not originalRaidAppearanceData) then
        originalPartyAppearanceData = bpin.unitAppearanceData["raid"]
      end
      if (not originalPartyAppearanceData) then
        originalRaidAppearanceData = bpin.unitAppearanceData["party"]
      end
      originalPinsHidden = false
    end
  end
  if (show) then
    if (originalPinsHidden) then
      blizzardPins.unitAppearanceData["raid"] = originalRaidAppearanceData
      blizzardPins.unitAppearanceData["party"] = originalPartyAppearanceData
      originalPinsHidden = false
    end
  else
    if (not originalPinsHidden) then
      blizzardPins.unitAppearanceData["raid"] = hiddenAppearanceData
      blizzardPins.unitAppearanceData["party"] = hiddenAppearanceData
      originalPinsHidden = true
    end
  end
end

local updatePins = function()
  for name, player in pairs(players) do
    if (player.PendingLocationChange) then
      --HereBeDragonsPins:RemoveWorldMapIcon(MODULE_NAME, player.WorldmapPin)
      --HereBeDragonsPins:RemoveMinimapIcon(MODULE_NAME, player.MinimapPin)
      updatePinColors(name, player)
      if (player.ContinentId ~= nil and player.X ~= nil and player.Y ~= nil) then
        if (VGT.db.profile.map.mode ~= VGT.MapOutput.MINIMAP) then
          HereBeDragonsPins:AddWorldMapIconWorld(
            MODULE_NAME,
            player.WorldmapPin,
            player.ContinentId,
            player.X,
            player.Y,
            3,
            "PIN_FRAME_LEVEL_GROUP_MEMBER"
          )
        end
        if (VGT.db.profile.map.mode ~= VGT.MapOutput.MAP and not UnitIsUnit(name, "player")) then
          HereBeDragonsPins:AddMinimapIconWorld(
            MODULE_NAME,
            player.MinimapPin,
            player.ContinentId,
            player.X,
            player.Y,
            VGT.db.profile.map.showMinimapOutOfBounds and UnitInParty(name)
          )
        end
      end
      player.PendingLocationChange = false
    end
  end
  HereBeDragonsPins.worldmapProvider:RefreshAllData()
end

local addOrUpdatePartyMember = function(unit)
  local name = UnitName(unit)
  if (name ~= nil) then
    local x, y, continentOrInstanceId = HereBeDragons:GetUnitWorldPosition(name)

    if (x == nil or y == nil) then
      local instance = VGT:GetInstance(continentOrInstanceId)
      if (instance) then
        addOrUpdatePlayer(
          name,
          instance.X,
          instance.Y,
          instance.ContinentId,
          UnitHealth(unit) / UnitHealthMax(unit),
          false,
          instance.Name
        )
        return
      else
        --destroyPlayer(name) -- Unit is in an unknown instance. Don't show a pin.
      end
    end

    local zone
    local mapId = C_Map.GetBestMapForUnit(unit)
    if (mapId) then
      local mapInfo = C_Map.GetMapInfo(mapId)
      if (mapInfo) then
        zone = mapInfo.name
      end
    end

    addOrUpdatePlayer(name, x, y, continentOrInstanceId, UnitHealth(unit) / UnitHealthMax(unit), false, zone)
  end
end

local updatePartyMembers = function()
  if (VGT.db.profile.map.showMe) then
    addOrUpdatePartyMember("player")
  else
    destroyPlayer(UnitName("player"))
  end
  if (IsInRaid()) then
    for i = 1, 40 do
      local unit = "raid" .. i
      if (not UnitIsUnit(unit, "player")) then
        addOrUpdatePartyMember(unit)
      end
    end
  elseif (IsInGroup()) then
    for i = 1, 4 do
      addOrUpdatePartyMember("party" .. i)
    end
  end
end

local parseMessage = function(message)
  local continentIdString, xString, yString, hpString = strsplit(DELIMITER, message)
  return tonumber(continentIdString), tonumber(xString), tonumber(yString), tonumber(hpString)
end

local handleMapMessageReceivedEvent = function(prefix, message, _, sender)
  if (prefix ~= MODULE_NAME) then
    return
  end

  if (message == REQUEST_LOCATION_MESSAGE) then
    sendMyLocation(sender)
  else
    local continentId, x, y, hp = parseMessage(message)

    if (continentId ~= nil and x ~= nil and y ~= nil and not UnitIsUnit(sender, PLAYER) and not UnitInParty(sender)) then
      addOrUpdatePlayer(sender, x, y, continentId, hp, true)
    end
  end
end

local cleanUnusedPins = function()
  for name, player in pairs(players) do
    if
      (not VGT.db.profile.map.enabled or -- remove all pins if the addon is disabled.
        (not UnitInParty(name) and not player.HasCommMessages and not UnitIsUnit(name, PLAYER)) or -- remove non-party members that aren't sending comm messages
        (player.HasCommMessages and player.LastCommReceived and (GetTime() - player.LastCommReceived) > 180))
     then -- remove pins that haven't had a new comm message in 3 minutes. (happens if a user disables reporting, or if the addon crashes)
      destroyPlayer(name)
    elseif (VGT.db.profile.map.mode == VGT.MapOutput.MINIMAP) then -- remove the worldmap pin if the user changed to minimap only.
      HereBeDragonsPins:RemoveWorldMapIcon(MODULE_NAME, player.WorldmapPin)
    elseif (VGT.db.profile.map.mode == VGT.MapOutput.MAP) then -- remove the minimap pin if the user changed to worldmap only.
      HereBeDragonsPins:RemoveMinimapIcon(MODULE_NAME, player.MinimapPin)
    end
  end
end

local lastUpdate = GetTime()
local main = function()
  if (VGT.db.profile.map.enabled) then
    updatePartyMembers()
    cleanUnusedPins()
    toggleBlizzardPins(VGT.db.profile.map.mode == VGT.MapOutput.MINIMAP or C_PvP.IsPVPMap())
    updatePins()

    local now = GetTime()
    local delay = 3
    if (UnitAffectingCombat(PLAYER)) then
      delay = 6
    end
    if (select(1, IsInInstance())) then
      delay = 60
    end
    if (UnitIsAFK(PLAYER)) then
      delay = 120
    end

    if (now - lastUpdate >= delay) then
      sendMyLocation()
      lastUpdate = now
    end
  else
    cleanUnusedPins()
    toggleBlizzardPins(true)
  end
end

local function OnGuildRosterUpdate()
  for _, player in pairs(players) do
    player.GuildNumber = nil
  end
end

local function OnPlayerTargetChanged()
  local targetName = UnitName("target")
  for name, player in pairs(players) do
    if (name == targetName) then
      player.Targeted = true
      updatePinColors(name, player)
    elseif (player.Targeted) then
      player.Targeted = false
      updatePinColors(name, player)
    end
  end
end

local function OnEvent(self, event)
  if event == "PLAYER_TARGET_CHANGED" then
    OnPlayerTargetChanged()
  elseif event == "GUILD_ROSTER_UPDATE" then
    OnGuildRosterUpdate()
  end
end

function VGT:InitializeMap()
  self:RegisterComm(MODULE_NAME, handleMapMessageReceivedEvent)
  self.map = { frame = CreateFrame("Frame") }
  self.map.frame:RegisterEvent("GUILD_ROSTER_UPDATE")
  self.map.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  self.map.frame:SetScript("OnUpdate", main)
  self.map.frame:SetScript("OnEvent", OnEvent)

  if not self.db.profile.map.enabled then
    self.map.frame:Hide()
  elseif IsInGuild() then
    self:SendCommMessage(MODULE_NAME, REQUEST_LOCATION_MESSAGE, COMM_CHANNEL, nil, COMM_PRIORITY)
  end
end

function VGT:RefreshMapConfig()
  if self.db.profile.map.enabled then
    self.map.frame:Show()
  else
    self.map.frame:Hide()
    cleanUnusedPins()
    toggleBlizzardPins(true)
  end
end
