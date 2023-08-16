---@class MapModule : Module, AceComm-3.0, AceTimer-3.0, { profile: MapProfileSettings }
local map = VGT:NewModule("map", "AceComm-3.0", "AceTimer-3.0")

local MODULE_NAME = "VGT-Map"
local DELIMITER = ":"
local REQUEST_LOCATION_MESSAGE = "RL"
local MAP_ICON_TEXTURE = "Interface\\AddOns\\ValhallaGuildTools\\MapIcon.tga"
local MAP_ICON_DOT_TEXTURE = "Interface\\AddOns\\ValhallaGuildTools\\MapIconDot.tga"

local HereBeDragons = LibStub("HereBeDragons-2.0")
local HereBeDragonsPins = LibStub("HereBeDragons-Pins-2.0")

map.bufferPins = {}
map.extendedGuildRoster = {
  members = {},
  memberNames = {}
}

function map.extendedGuildRoster:GetMember(nameOrGuid)
  local member = self.members[nameOrGuid]
  if not member then
    for i = 1, GetNumGuildMembers() do
      local name, _, _, _, _, _, _, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
      name = strsplit("-", name, 2)

      self.memberNames[guid] = name
      local thisMember = self.members[guid]
      if thisMember then
        thisMember.name = name
        thisMember.class = class
        thisMember.guid = guid
      else
        thisMember = {
          name = name,
          class = class,
          guid = guid
        }
        self.members[name] = thisMember
        self.members[guid] = thisMember
      end

      if nameOrGuid == name or nameOrGuid == guid then
        member = thisMember
      end
    end
  end
  return member
end

function map.extendedGuildRoster:EnumerateMembers()
  local guid

  return function()
    guid = next(self.memberNames, guid)
    if guid then
      return self.members[guid]
    end
  end
end

function map:TakePin()
  if #self.bufferPins == 0 then
    local pin = CreateFrame("Frame", nil, WorldFrame)
    pin:SetWidth(self.profile.size)
    pin:SetHeight(self.profile.size)
    local texture = pin:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetTexture(MAP_ICON_TEXTURE)
    texture:SetVertexColor(0.14, 0.67, 0.02) -- Green
    pin:EnableMouse(true)
    pin.texture = texture
    pin:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    return pin
  end
  return table.remove(self.bufferPins)
end

function map:UnitHasDefaultPin(unit)
  return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit)
end

function map:FormatPlayerTooltip(player)
  local text = "|c" .. select(4, GetClassColor(player.class)) .. player.name .. "|r"

  if (player.hp ~= nil) then
    text = text .. " |cffffffff-|r |cff" .. VGT.GetColorGradientHex(player.hp) .. VGT.Round(player.hp * 100, 0) .. "%|r"
  end
  return text
end

function map:FormatTooltip(player, distance)
  local text = ""
  local zone
  local timeNow = GetTime()

  text = text .. self:FormatPlayerTooltip(player)

  for otherPlayer in self.extendedGuildRoster:EnumerateMembers() do
    if otherPlayer ~= player and otherPlayer.x ~= nil and otherPlayer.y ~= nil and player.x ~= nil and player.y ~= nil and otherPlayer.lastUpdate and (timeNow - otherPlayer.lastUpdate) < 180 and math.sqrt(math.pow(player.x - otherPlayer.x, 2) + math.pow(player.y - otherPlayer.y, 2)) < distance then
      text = text .. "\n" .. self:FormatPlayerTooltip(otherPlayer)
    end
  end

  return text
end

function map:SendMyLocation(target)
  if IsInGuild() and self.profile.sendMyLocation then
    local x, y, continent = HereBeDragons:GetPlayerWorldPosition()
    local hp = UnitHealth("player") / UnitHealthMax("player")
    if continent and x and y then
      local data = string.format("%.0f:%.2f:%.2f:%.3f", continent, x, y, hp)
      if target ~= nil then
        VGT.LogTrace("Sending map location to %s", target)
        VGT:SendCommMessage(MODULE_NAME, data, "WHISPER", target)
      else
        VGT.LogTrace("Sending map location to guild")
        VGT:SendCommMessage(MODULE_NAME, data, "GUILD")
      end
    end
  end
end

function map:UpdatePinColors(player)
  if not player.minimapPin and not player.worldPin then
    return
  end
  local r, g, b
  if player.targeted then
    r, g, b = 0.59, 0.01, 0.01 -- Red
  elseif self.profile.useClassColor then
    r, g, b = GetClassColor(player.class)
  elseif UnitInParty(player.name) then
    r, g, b = 0.21, 0.38, 0.79 -- Blue
  else
    r, g, b = 0.14, 0.67, 0.02 -- Green
  end
  if player.minimapPin then
    player.minimapPin.texture:SetVertexColor(r, g, b)
  end
  if player.worldPin then
    player.worldPin.texture:SetVertexColor(r, g, b)
  end
end

function map:UpdatePins(timeNow)
  for player in self.extendedGuildRoster:EnumerateMembers() do
    local shouldDisplay = player.lastUpdate and (timeNow - player.lastUpdate) < 180 and self.profile.enabled and not self:UnitHasDefaultPin(player.name)
    local shouldDisplayWorld = shouldDisplay and self.profile.mode ~= VGT.MapOutput.MINIMAP
    local shouldDisplayMinimap = shouldDisplay and self.profile.mode ~= VGT.MapOutput.MAP

    if shouldDisplayWorld then
      if not player.worldPin then
        player.worldPin = self:TakePin()
        player.worldPin.player = player
        player.worldPin:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
          local distance = 50
          local mapId = HereBeDragonsPins.worldmapProvider:GetMap():GetMapID()
          if (mapId) then
            local mapData = HereBeDragons.mapData[mapId]
            if (mapData and mapData.mapType) then
              -- todo: these are just my best guesses of distances. Probably should be tweaked.
              if (mapData.mapType == 1) then -- world
                distance = 300
              end
              if (mapData.mapType == 2) then -- continent
                distance = 100
              end
              if (mapData.mapType == 3) then -- zone or city
                distance = 25
              end
            end
          end
          GameTooltip:SetText(map:FormatTooltip(self.player, distance))
          GameTooltip:Show()
        end)
      end
      if player.needsUpdate then
        HereBeDragonsPins:AddWorldMapIconWorld(MODULE_NAME, player.worldPin, player.continent, player.x, player.y, 3, "PIN_FRAME_LEVEL_GROUP_MEMBER")
      end
    elseif player.worldPin then
      HereBeDragonsPins:RemoveWorldMapIcon(MODULE_NAME, player.worldPin)
      table.insert(self.bufferPins, player.worldPin)
      player.worldPin = nil
    end

    if shouldDisplayMinimap then
      if not player.minimapPin then
        player.minimapPin = self:TakePin()
        player.minimapPin.player = player
        player.minimapPin:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
          local distance = 15
          -- todo set distance for minimap based on zoom level
          GameTooltip:SetText(map:FormatTooltip(self.player, distance))
          GameTooltip:Show()
        end)
      end
      if player.needsUpdate then
        HereBeDragonsPins:AddMinimapIconWorld(MODULE_NAME, player.minimapPin, player.continent, player.x, player.y)
      end
    elseif player.minimapPin then
      HereBeDragonsPins:RemoveMinimapIcon(MODULE_NAME, player.minimapPin)
      table.insert(self.bufferPins, player.minimapPin)
      player.minimapPin = nil
    end

    if shouldDisplay then
      self:UpdatePinColors(player)
    end

    player.needsUpdate = false
  end
  HereBeDragonsPins.worldmapProvider:RefreshAllData()
  self.nextUpdate = timeNow + 6
end

function map:OnMessageReceived(prefix, message, _, sender)
  if (prefix ~= MODULE_NAME) then
    return
  end

  if (message == REQUEST_LOCATION_MESSAGE) then
    self:SendMyLocation(sender)
  elseif not self:UnitHasDefaultPin(sender) then
    local continent, x, y, hp = strsplit(DELIMITER, message)
    continent = tonumber(continent)
    x = tonumber(x)
    y = tonumber(y)
    hp = tonumber(hp)

    if continent ~= nil and x ~= nil and y ~= nil then
      local player = self.extendedGuildRoster:GetMember(sender)
      if player then
        player.needsUpdate = (x ~= player.x or y ~= player.y or continent ~= player.continent)
        player.x = x
        player.y = y
        player.continent = continent
        player.hp = hp
        player.lastUpdate = GetTime()
      end
    end
  end
end

function map:GetSendDelay()
  if UnitIsAFK("player") then
    return 120
  end
  if IsInInstance() then
    return 60
  end
  if UnitAffectingCombat("player") then
    return 10
  end
  return 3
end

function map:TrimDelay()
  local now = GetTime()
  local delay = self:GetSendDelay()
  if self.nextSend - now > delay then
    self.nextSend = now + delay
  end
end

function map:OnTick()
  local now = GetTime()

  if now >= self.nextUpdate then
    self:UpdatePins(now)
  end

  if now >= self.nextSend then
    self:SendMyLocation()
    self.nextSend = now + self:GetSendDelay()
  end
end

function map:PLAYER_TARGET_CHANGED()
  VGT.LogTrace("Target Changed")
  local targetName = UnitName("target") -- UnitIsUnit does not work for non party members
  for player in self.extendedGuildRoster:EnumerateMembers() do
    if player.targeted then
      player.targeted = false
      self:UpdatePinColors(player)
      VGT.LogTrace("Untargeted %s", player.name)
    elseif player.name == targetName then
      player.targeted = true
      self:UpdatePinColors(player)
      VGT.LogTrace("Targeted %s", player.name)
    end
  end
end

function map:PLAYER_LEAVE_COMBAT()
  self:TrimDelay()
end

function map:PLAYER_FLAGS_CHANGED(_, arg)
  if UnitIsUnit(arg, "player") then
    self:TrimDelay()
  end
end

map.originalUpdateUnitTooltips = UnitPositionFrameMixin.UpdateUnitTooltips
---@param self any
---@param tooltipFrame GameTooltip
function map.newUpdateUnitTooltips(self, tooltipFrame)
  local tooltipText = ""
  local prefix = ""
  local timeNow = GetTime()

  for unit in pairs(self.currentMouseOverUnits) do
    local unitName = UnitName(unit)
    if unitName and not self:IsMouseOverUnitExcluded(unit) then
      local formattedUnitName = GetIsPVPInactive(unit, timeNow) and format(PLAYER_IS_PVP_AFK, unitName) or ("|c" .. select(4, GetClassColor(select(2, UnitClass(unit)))) .. unitName .. "|r")

      tooltipText = tooltipText .. prefix .. formattedUnitName

      local unitHp = UnitHealth(unitName)
      if type(unitHp) == "number" then
        unitHp = unitHp / UnitHealthMax(unitName)
        tooltipText = tooltipText .. " |cffffffff-|r |cff" .. VGT.GetColorGradientHex(unitHp) .. VGT.Round(unitHp * 100, 0) .. "%|r"
      end

      prefix = "\n"
    end
  end

  if tooltipText ~= "" then
    self.previousOwner = tooltipFrame:GetOwner()
    tooltipFrame:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
    tooltipFrame:SetText(tooltipText)
  elseif tooltipFrame:GetOwner() == self then
    tooltipFrame:ClearLines()
    tooltipFrame:Hide()
    if self.previousOwner and self.previousOwner ~= self and self.previousOwner:IsVisible() and self.previousOwner:IsMouseOver() then
      local func = self.previousOwner:HasScript("OnEnter") and self.previousOwner:GetScript("OnEnter")
      if func then
        func(self.previousOwner)
      end
    end
    self.previousOwner = nil
  end
end

map.originalGetUnitColor = UnitPositionFrameMixin.GetUnitColor
---@param self any
---@param timeNow number
---@param unit UnitId
---@param appearanceData table
---@return boolean, number?, number?, number?
function map.newGetUnitColor(self, timeNow, unit, appearanceData)
  if appearanceData.shouldShow then
    local r, g, b = 1, 1, 1

    if not UnitIsUnit(unit, "player") then
      if UnitIsUnit(unit, "target") then
        r, g, b = 0.59, 0.01, 0.01 -- Red
      elseif VGT.db.profile.map.useClassColor then
        local class = select(2, UnitClass(unit))
        r, g, b = GetClassColor(class)
      elseif UnitInParty(unit) or UnitInRaid(unit) then
        r, g, b = 0.21, 0.38, 0.79 -- Blue
      elseif appearanceData.useClassColor then
        local class = select(2, UnitClass(unit))
        r, g, b = GetClassColor(class)
      end
    end

    return true, CheckColorOverrideForPVPInactive(unit, timeNow, r, g, b)
  end

  return false
end

function map:UpdateBlizzardPins()
  local override = self.profile.enabled and self.profile.improveBlizzardPins
  for pin in WorldMapFrame:EnumeratePinsByTemplate("GroupMembersPinTemplate") do
    if override then
      pin.UpdateUnitTooltips = self.newUpdateUnitTooltips
      pin.GetUnitColor = self.newGetUnitColor
      pin:SetPinTexture("raid", MAP_ICON_TEXTURE)
      pin:SetPinTexture("party", MAP_ICON_TEXTURE)
      if not pin.hooked then
        hooksecurefunc(pin, "UpdateAppearanceData", function(self)
          self.UpdateUnitTooltips = map.newUpdateUnitTooltips
          self.GetUnitColor = map.newGetUnitColor
          self:SetPinTexture("raid", MAP_ICON_TEXTURE)
          self:SetPinTexture("party", MAP_ICON_TEXTURE)
        end)
        pin.hooked = true
      end
    else
      pin.UpdateUnitTooltips = self.originalUpdateUnitTooltips
      pin.GetUnitColor = self.originalGetUnitColor
    end
  end
end

function map:RefreshPinSizeAndColor()
  for player in self.extendedGuildRoster:EnumerateMembers() do
    self:UpdatePinColors(player)
    if player.minimapPin then
      player.minimapPin:SetWidth(self.profile.size)
      player.minimapPin:SetHeight(self.profile.size)
    end
    if player.worldPin then
      player.worldPin:SetWidth(self.profile.size)
      player.worldPin:SetHeight(self.profile.size)
    end
  end
end

function map:OnEnable()
  self.nextUpdate = GetTime()
  self.nextSend = self.nextUpdate
  self:UpdateBlizzardPins()
  self:RegisterComm(MODULE_NAME, "OnMessageReceived")
  self:RegisterEvent("PLAYER_TARGET_CHANGED")
  self:RegisterEvent("PLAYER_LEAVE_COMBAT")
  self:RegisterEvent("PLAYER_FLAGS_CHANGED")
  self:ScheduleRepeatingTimer("OnTick", 1)

  if IsInGuild() then
    self:SendCommMessage(MODULE_NAME, REQUEST_LOCATION_MESSAGE, "GUILD")
  end
end

function map:OnDisable()
  self:UpdatePins(GetTime())
end

function map:RefreshConfig()
  self:UpdateBlizzardPins()
  self:RefreshPinSizeAndColor()
  self:UpdatePins(GetTime())
end
