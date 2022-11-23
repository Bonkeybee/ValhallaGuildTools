local MODULE_NAME = "VGT-Map"
local DELIMITER = ":"
local REQUEST_LOCATION_MESSAGE = "RL"
local MAP_ICON_TEXTURE = "Interface\\AddOns\\ValhallaGuildTools\\MapIcon.tga"
local MAP_ICON_DOT_TEXTURE = "Interface\\AddOns\\ValhallaGuildTools\\MapIconDot.tga"

local HereBeDragons = LibStub("HereBeDragons-2.0")
local HereBeDragonsPins = LibStub("HereBeDragons-Pins-2.0")

local bufferPins = {}
local extendedGuildRoster = { members = {}, memberNames = {} }
local nextUpdate = GetTime()
local nextSend = nextUpdate

function extendedGuildRoster:GetMember(nameOrGuid)
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
        thisMember = { name = name, class = class, guid = guid }
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

function extendedGuildRoster:EnumerateMembers()
  local guid

  return function()
    guid = next(extendedGuildRoster.memberNames, guid)
    if guid then
      return extendedGuildRoster.members[guid]
    end
  end
end

function TakePin()
  if #bufferPins == 0 then
    local pin = CreateFrame("Frame", nil, WorldFrame)
    pin:SetWidth(VGT.db.profile.map.size)
    pin:SetHeight(VGT.db.profile.map.size)
    local texture = pin:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetTexture(MAP_ICON_TEXTURE)
    texture:SetVertexColor(0.14, 0.67, 0.02) -- Green
    pin:EnableMouse(true)
    pin.texture = texture
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
  end
  return table.remove(bufferPins)
end

local function UnitHasDefaultPin(unit)
  return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit)
end

local function FormatPlayerTooltip(player)
  local text = "|c" .. select(4, GetClassColor(player.class)) .. player.name .. "|r"

  if (player.hp ~= nil) then
    text = text .. " |cffffffff-|r |cff" .. VGT.RGBToHex(VGT.ColorGradient(tonumber(player.hp), 1, 0, 0, 1, 1, 0, 0, 1, 0)) .. VGT.Round(player.hp * 100, 0) .. "%|r"
  end
  return text
end

local function FormatTooltip(player, distance)
  local text = ""
  local zone
  local timeNow = GetTime()

  text = text .. FormatPlayerTooltip(player)

  for otherPlayer in extendedGuildRoster:EnumerateMembers() do
    if otherPlayer ~= player and otherPlayer.x ~= nil and otherPlayer.y ~= nil and player.x ~= nil and player.y ~= nil
    and otherPlayer.lastUpdate and (timeNow - otherPlayer.lastUpdate) < 180
    and math.sqrt(math.pow(player.x - otherPlayer.x, 2) + math.pow(player.y - otherPlayer.y, 2)) < distance
    then
      text = text .. "\n" .. FormatPlayerTooltip(otherPlayer)
    end
  end

  return text
end

local function SendMyLocation(target)
  if (IsInGuild() and VGT.db.profile.map.sendMyLocation) then
    local x, y, continent = HereBeDragons:GetPlayerWorldPosition()
    x = VGT.Round(x, 0)
    y = VGT.Round(y, 0)
    local hp = UnitHealth("player") / UnitHealthMax("player")
    if (instanceMapId ~= nil and x ~= nil and y ~= nil and hp ~= nil) then
      local data = instanceMapId .. DELIMITER .. x .. DELIMITER .. y .. DELIMITER .. hp
      if (target ~= nil) then
        VGT:SendCommMessage(MODULE_NAME, data, "WHISPER", target)
      elseif (IsInGuild()) then
        VGT:SendCommMessage(MODULE_NAME, data, "GUILD")
      end
    end
  end
end

local function UpdatePinColors(player)
  if not player.minimapPin and not player.worldPin then
    return
  end
  local r, g, b
  if player.targeted then
    r, g, b = 0.59, 0.01, 0.01 -- Red
  elseif VGT.db.profile.map.useClassColor then
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

local function UpdatePins(timeNow)
  for player in extendedGuildRoster:EnumerateMembers() do
    local shouldDisplay = player.lastUpdate and (timeNow - player.lastUpdate) < 180 and VGT.db.profile.map.enabled and not UnitHasDefaultPin(player.name)
    local shouldDisplayWorld = shouldDisplay and VGT.db.profile.map.mode ~= VGT.MapOutput.MINIMAP
    local shouldDisplayMinimap = shouldDisplay and VGT.db.profile.map.mode ~= VGT.MapOutput.MAP

    if shouldDisplayWorld then
      if not player.worldPin then
        player.worldPin = TakePin()
        player.worldPin.player = player
        player.worldPin:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
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
          GameTooltip:SetText(FormatTooltip(self.player, distance))
          GameTooltip:Show()
        end)
      end
      if player.needsUpdate then
        HereBeDragonsPins:AddWorldMapIconWorld(MODULE_NAME, player.worldPin, player.continent, player.x, player.y, 3, "PIN_FRAME_LEVEL_GROUP_MEMBER")
      end
    elseif player.worldPin then
      HereBeDragonsPins:RemoveWorldMapIcon(MODULE_NAME, player.worldPin)
      table.insert(bufferPins, player.worldPin)
      player.worldPin = nil
    end

    if shouldDisplayMinimap then
      if not player.minimapPin then
        player.minimapPin = TakePin()
        player.minimapPin.player = player
        player.minimapPin:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
          local distance = 15
          --todo set distance for minimap based on zoom level
          GameTooltip:SetText(FormatTooltip(self.player, distance))
          GameTooltip:Show()
        end)
      end
      if player.needsUpdate then
        HereBeDragonsPins:AddMinimapIconWorld(MODULE_NAME, player.minimapPin, player.continent, player.x, player.y)
      end
    elseif player.minimapPin then
      HereBeDragonsPins:RemoveMinimapIcon(MODULE_NAME, player.minimapPin)
      table.insert(bufferPins, player.minimapPin)
      player.minimapPin = nil
    end

    if shouldDisplay then
      UpdatePinColors(player)
    end

    player.needsUpdate = false
  end
  HereBeDragonsPins.worldmapProvider:RefreshAllData()
  nextUpdate = timeNow + 6
end

local function OnMessageReceived(prefix, message, _, sender)
  if (prefix ~= MODULE_NAME) then
    return
  end

  if (message == REQUEST_LOCATION_MESSAGE) then
    SendMyLocation(sender)
  elseif not UnitHasDefaultPin(sender) then
    local continent, x, y, hp = strsplit(DELIMITER, message)
    continent = tonumber(continent)
    x = tonumber(x)
    y = tonumber(y)
    hp = tonumber(hp)

    if continent ~= nil and x ~= nil and y ~= nil then
      local player = extendedGuildRoster:GetMember(sender)
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

local function GetSendDelay()
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

local function TrimDelay()
  local now = GetTime()
  local delay = GetSendDelay()
  if nextSend - now > delay then
    nextSend = now + delay
  end
end

local function OnUpdate()
  local now = GetTime()

  if now >= nextUpdate then
    UpdatePins(now)
  end

  if now >= nextSend then
    SendMyLocation()
    nextSend = now + GetSendDelay()
  end
end

local function OnPlayerTargetChanged()
  VGT.LogTrace("Target Changed")
  local targetName = UnitName("target") -- UnitIsUnit does not work for non party members
  for player in extendedGuildRoster:EnumerateMembers() do
    if player.targeted then
      player.targeted = false
      UpdatePinColors(player)
      VGT.LogTrace("Untargeted %s", player.name)
    elseif player.name == targetName then
      player.targeted = true
      UpdatePinColors(player)
      VGT.LogTrace("Targeted %s", player.name)
    end
  end
end

local function OnEvent(self, event, arg1)
  if event == "PLAYER_TARGET_CHANGED" then
    OnPlayerTargetChanged()
  elseif event == "PLAYER_LEAVE_COMBAT" then
    TrimDelay()
  elseif event == "PLAYER_FLAGS_CHANGED" and UnitIsUnit(arg1, "player") then
    TrimDelay()
  end
end

local originalUpdateUnitTooltips = UnitPositionFrameMixin.UpdateUnitTooltips
local function newUpdateUnitTooltips(self, tooltipFrame)
  VGT.LogTrace("Custom UnitPositionFrameMixin")
	local tooltipText = ""
	local prefix = ""
	local timeNow = GetTime()

	for unit in pairs(self.currentMouseOverUnits) do
		local unitName = UnitName(unit)
		if not self:IsMouseOverUnitExcluded(unit) then
			local formattedUnitName = 
        GetIsPVPInactive(unit, timeNow) and format(PLAYER_IS_PVP_AFK, unitName) or
        ("|c" .. select(4, GetClassColor(select(2, UnitClass(unit)))) .. unitName .. "|r")
      
			tooltipText = tooltipText .. prefix .. formattedUnitName
      
      local unitHp = UnitHealth(unitName)
      if type(unitHp) == "number" then
        unitHp = unitHp / UnitHealthMax(unitName)
        tooltipText = tooltipText .. " |cffffffff-|r |cff" ..
          VGT.RGBToHex(VGT.ColorGradient(unitHp, 1, 0, 0, 1, 1, 0, 0, 1, 0)) ..
          VGT.Round(unitHp * 100, 0) .. "%|r"
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

local originalGetUnitColor = UnitPositionFrameMixin.GetUnitColor
local function newGetUnitColor(self, timeNow, unit, appearanceData)
	if appearanceData.shouldShow then
		local r, g, b  = 1, 1, 1

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

local function UpdateBlizzardPins()
  local override = VGT.db.profile.map.enabled and VGT.db.profile.map.improveBlizzardPins
  for pin in WorldMapFrame:EnumeratePinsByTemplate("GroupMembersPinTemplate") do
    if override then
      pin.UpdateUnitTooltips = newUpdateUnitTooltips
      pin.GetUnitColor = newGetUnitColor
      pin:SetPinTexture("raid", MAP_ICON_TEXTURE)
      pin:SetPinTexture("party", MAP_ICON_TEXTURE)
      if not pin.hooked then
        hooksecurefunc(pin, "UpdateAppearanceData", function(self)
          self.UpdateUnitTooltips = newUpdateUnitTooltips
          self.GetUnitColor = newGetUnitColor
          self:SetPinTexture("raid", MAP_ICON_TEXTURE)
          self:SetPinTexture("party", MAP_ICON_TEXTURE)
        end)
        pin.hooked = true
      end
    else
      pin.UpdateUnitTooltips = originalUpdateUnitTooltips
      pin.GetUnitColor = originalGetUnitColor
    end
  end
end

function VGT:InitializeMap()
  UpdateBlizzardPins()
  self:RegisterComm(MODULE_NAME, OnMessageReceived)
  self.map = { frame = CreateFrame("Frame") }
  self.map.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  self.map.frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
  self.map.frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
  self.map.frame:SetScript("OnUpdate", OnUpdate)
  self.map.frame:SetScript("OnEvent", OnEvent)

  if not self.db.profile.map.enabled then
    self.map.frame:Hide()
  elseif IsInGuild() then
    self:SendCommMessage(MODULE_NAME, REQUEST_LOCATION_MESSAGE, "GUILD")
  end
end

function VGT:RefreshPinSizeAndColor()
  for player in extendedGuildRoster:EnumerateMembers() do
    UpdatePinColors(player)
    if player.minimapPin then
      player.minimapPin:SetWidth(VGT.db.profile.map.size)
      player.minimapPin:SetHeight(VGT.db.profile.map.size)
    end
    if player.worldPin then
      player.worldPin:SetWidth(VGT.db.profile.map.size)
      player.worldPin:SetHeight(VGT.db.profile.map.size)
    end
  end
end

function VGT:RefreshMapConfig()
  UpdateBlizzardPins()
  if self.db.profile.map.enabled then
    self:RefreshPinSizeAndColor()
    self.map.frame:Show()
  else
    self.map.frame:Hide()
    UpdatePins()
  end
end
