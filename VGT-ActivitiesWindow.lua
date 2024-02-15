local activities = VGT:NewModule("activities", "AceComm-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local moduleName = "VGT-Activities"
local cleanupTimer = 5
local sendTimer = 3
local oldTimer = 15
local possibleRoles = { "Tank", "Heal", "Damage" }
local rolesTexture = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local roleTexturesNormalized = {
  Tank = { 0, 0.25, 0.25, 0.50 },
  Heal = { 0.25, 0.5, 0, 0.25 },
  Damage = { 0.25, 0.5, 0.25, 0.5 }
}
local roleTexturesPixels = {
  Tank = { 0, 64, 64, 128 },
  Heal = { 64, 128, 0, 64 },
  Damage = { 64, 128, 64, 128 }
}
local possibleActivities = {
  { name = "Leveling" },
  { name = "Dungeons" },
  { name = "Raids" }
}
local possibleDungeons = {
  { name = "Ragefire Chasm", minLevel = 13, maxLevel = 18 },
  { name = "Wailing Caverns", minLevel = 15, maxLevel = 25 },
  { name = "The Deadmines", minLevel = 18, maxLevel = 23 },
  { name = "Shadowfang Keep", minLevel = 22, maxLevel = 30 },
  { name = "The Stockade", minLevel = 22, maxLevel = 30 },
  { name = "Razorfen Kraul", minLevel = 30, maxLevel = 40 },
  { name = "Scarlet Monastery: Graveyard", minLevel = 28, maxLevel = 38 },
  { name = "Scarlet Monastery: Library", minLevel = 29, maxLevel = 39 },
  { name = "Scarlet Monastery: Armory", minLevel = 32, maxLevel = 42 },
  { name = "Scarlet Monastery: Cathedral", minLevel = 35, maxLevel = 45 },
  { name = "Razorfen Downs", minLevel = 40, maxLevel = 50 },
  { name = "Uldaman", minLevel = 42, maxLevel = 52 },
  { name = "Zul'Farrak", minLevel = 44, maxLevel = 54 },
  { name = "Maraudon: Wicked Grotto", minLevel = 45, maxLevel = 53 },
  { name = "Maraudon: Foulspore Cavern", minLevel = 45, maxLevel = 53 },
  { name = "Maraudon: Earth Song Falls", minLevel = 48, maxLevel = 57 },
  { name = "The Temple of Atal'Hakkar", minLevel = 50, maxLevel = 60 },
  { name = "Blackrock Depths", minLevel = 52, maxLevel = 60 },
  { name = "Blackrock Spire: Lower", minLevel = 55, maxLevel = 60 },
  { name = "Scholomance", minLevel = 58, maxLevel = 60 },
  { name = "Stratholme", minLevel = 58, maxLevel = 60 },
  { name = "Diremaul: North", minLevel = 58, maxLevel = 60 },
  { name = "Diremaul: East", minLevel = 58, maxLevel = 60 },
  { name = "Diremaul: West", minLevel = 58, maxLevel = 60 }
}
local dungeonLookup = {}
for _, dungeon in ipairs(possibleDungeons) do
  dungeonLookup[dungeon.name] = {
    name = dungeon.name,
    minLevel = dungeon.minLevel,
    maxLevel = dungeon.maxLevel
  }
end
local possibleRaids = {
  { name = "Blackfathom Deeps", minLevel = 25, maxLevel = 25 },
  { name = "Gnomeregan", minLevel = 40, maxLevel = 40 },
  { name = "Blackrock Spire: Upper", minLevel = 58, maxLevel = 60 },
  { name = "Zul'Gurub", minLevel = 60, maxLevel = 60 },
  { name = "Onyxia's Lair", minLevel = 60, maxLevel = 60 },
  { name = "Molten Core", minLevel = 60, maxLevel = 60 },
  { name = "Blackwing Lair", minLevel = 60, maxLevel = 60 },
  { name = "Ruins of Ahn'Qiraj", minLevel = 60, maxLevel = 60 },
  { name = "Temple of Ahn'Qiraj", minLevel = 60, maxLevel = 60 },
  { name = "Naxxramas", minLevel = 60, maxLevel = 60 }
}
local raidLookup = {}
for _, raid in ipairs(possibleRaids) do
  raidLookup[raid.name] = {
    name = raid.name,
    minLevel = raid.minLevel,
    maxLevel = raid.maxLevel
  }
end
activities.playerLevel = UnitLevel("PLAYER")

local function IsDungeonOrRaid(activity)
  if dungeonLookup[activity] or raidLookup[activity] then
    return true
  end
  return false
end

function activities:CleanupSelectedActivities()
  local validActivities = {}
  for _, activity in ipairs(possibleActivities) do
    validActivities[activity.name] = true
  end
  for _, dungeon in ipairs(possibleDungeons) do
    validActivities[dungeon.name] = true
  end
  for _, raid in ipairs(possibleRaids) do
    validActivities[raid.name] = true
  end

  for activity in pairs(self.char.selectedActivities) do
    if not validActivities[activity] then
      self.char.selectedActivities[activity] = nil
    end
  end
end

function activities:PLAYER_LEVEL_UP()
  self.playerLevel = UnitLevel("PLAYER")
  self:RefreshActivityWindow()
end

function activities:RefreshActivityWindow()
  if self.activityWindow then
    --self:BuildTabs()
  end
end

function activities:Toggle()
  if not self.enabledState then
    VGT.LogWarning("Activities module is disabled.")
    return
  end
  if not self.activityWindow then
    self.activityWindow = self:BuildWindow()
  elseif self.activityWindow:IsShown() then
    self.activityWindow:Hide()
  else
    self.activityWindow:Show()
  end
end

function activities:Show()
  if not self.enabledState then
    VGT.LogWarning("Activities module is disabled.")
    return
  end
  if not self.activityWindow then
    self:BuildWindow()
  end
  self.activityWindow:Show()
end

local function CreateCheckboxWithTooltip(label, tooltipText, isChecked, callbackFunc)
  local checkbox = AceGUI:Create("CheckBox")
  checkbox:SetLabel(label)
  checkbox:SetValue(isChecked)
  if tooltipText then
    checkbox:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
      GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    checkbox:SetCallback("OnLeave", function(widget)
      GameTooltip:Hide()
    end)
  end
  if callbackFunc then
    checkbox:SetCallback("OnValueChanged", callbackFunc)
  end
  return checkbox
end

function activities:BuildSelectActivitiesTab(container)
  if not container.selectActivitiesScrollContainer then
    container.selectActivitiesScrollContainer = AceGUI:Create("ScrollFrame")
    container.selectActivitiesScrollContainer:SetFullWidth(true)
    container.selectActivitiesScrollContainer:SetFullHeight(true)
    container.selectActivitiesScrollContainer:SetLayout("Flow")
    container:AddChild(container.selectActivitiesScrollContainer)
  end

  if not container.selectActivitiesScrollContainer.roleDivider then
    container.selectActivitiesScrollContainer.roleDivider = AceGUI:Create("Heading")
    container.selectActivitiesScrollContainer.roleDivider:SetText("Select Roles")
    container.selectActivitiesScrollContainer.roleDivider:SetFullWidth(true)
    container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.roleDivider)
  end

  if not container.selectActivitiesScrollContainer.possibleRoles then
    container.selectActivitiesScrollContainer.possibleRoles = {}
    for _, role in ipairs(possibleRoles) do
      if not container.selectActivitiesScrollContainer.possibleRoles[role] then
        container.selectActivitiesScrollContainer.possibleRoles[role] = AceGUI:Create("CheckBox")
        container.selectActivitiesScrollContainer.possibleRoles[role]:SetLabel(role)
        container.selectActivitiesScrollContainer.possibleRoles[role]:SetValue(self.char.selectedRoles[role])
        container.selectActivitiesScrollContainer.possibleRoles[role]:SetImage(rolesTexture)
        local coords = roleTexturesNormalized[role]
        container.selectActivitiesScrollContainer.possibleRoles[role].image:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        container.selectActivitiesScrollContainer.possibleRoles[role]:SetCallback("OnValueChanged", function(widget, event, value)
          self.char.selectedRoles[role] = value
        end)
        container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.possibleRoles[role])
      end
    end
  end

  if not container.selectActivitiesScrollContainer.activityDivider then
    container.selectActivitiesScrollContainer.activityDivider = AceGUI:Create("Heading")
    container.selectActivitiesScrollContainer.activityDivider:SetText("Select Activities")
    container.selectActivitiesScrollContainer.activityDivider:SetFullWidth(true)
    container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.activityDivider)
  end

  if not container.selectActivitiesScrollContainer.possibleActivities then
    container.selectActivitiesScrollContainer.possibleActivities = {}
    for _, activity in ipairs(possibleActivities) do
      if not container.selectActivitiesScrollContainer.possibleActivities[activity.name] then
        container.selectActivitiesScrollContainer.possibleActivities[activity.name] = AceGUI:Create("CheckBox")
        container.selectActivitiesScrollContainer.possibleActivities[activity.name]:SetLabel(activity.name)
        container.selectActivitiesScrollContainer.possibleActivities[activity.name]:SetValue(self.char.selectedActivities[activity.name])
        container.selectActivitiesScrollContainer.possibleActivities[activity.name]:SetCallback("OnValueChanged", function(widget, event, value)
          self.char.selectedActivities[activity.name] = value
          if activity.name == "Dungeons" then
            for _, dungeon in ipairs(possibleDungeons) do
              container.selectActivitiesScrollContainer.possibleDungeons[dungeon.name]:SetDisabled(not value)
              if value then
                container.selectActivitiesScrollContainer.possibleDungeons[dungeon.name]:SetLabel(string.format("%s %s", VGT:ColorizeByLevel(dungeon.name, self.playerLevel, dungeon.minLevel, dungeon.maxLevel), VGT:GetMinMaxLevelParenthesis(dungeon.minLevel, dungeon.maxLevel)))
              else
                container.selectActivitiesScrollContainer.possibleDungeons[dungeon.name]:SetLabel(string.format("%s %s", "|cffC0C0C0"..dungeon.name.."|r", VGT:GetMinMaxLevelParenthesis(dungeon.minLevel, dungeon.maxLevel)))
              end
            end
          end
          if activity.name == "Raids" then
            for _, raid in ipairs(possibleRaids) do
              container.selectActivitiesScrollContainer.possibleRaids[raid.name]:SetDisabled(not value)
              if value then
                container.selectActivitiesScrollContainer.possibleRaids[raid.name]:SetLabel(string.format("%s %s", VGT:ColorizeByLevel(raid.name, self.playerLevel, raid.minLevel, raid.maxLevel), VGT:GetMinMaxLevelParenthesis(raid.minLevel, raid.maxLevel)))
              else
                container.selectActivitiesScrollContainer.possibleRaids[raid.name]:SetLabel(string.format("%s %s", "|cffC0C0C0"..raid.name.."|r", VGT:GetMinMaxLevelParenthesis(raid.minLevel, raid.maxLevel)))
              end
            end
          end
        end)
        container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.possibleActivities[activity.name])
      end
    end
  end

  if not container.selectActivitiesScrollContainer.dungeonDivider then
    container.selectActivitiesScrollContainer.dungeonDivider = AceGUI:Create("Heading")
    container.selectActivitiesScrollContainer.dungeonDivider:SetFullWidth(true)
    container.selectActivitiesScrollContainer.dungeonDivider:SetText("Select Dungeons")
    container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.dungeonDivider)
  end
  if not container.selectActivitiesScrollContainer.possibleDungeons then
    container.selectActivitiesScrollContainer.possibleDungeons = {}
    for _, activity in ipairs(possibleDungeons) do
      if not container.selectActivitiesScrollContainer.possibleDungeons[activity.name] then
      	local label = nil
      	if self.char.selectedActivities[activity.name] then
		  label = string.format("%s %s", VGT:ColorizeByLevel(activity.name, self.playerLevel, activity.minLevel, activity.maxLevel), VGT:GetMinMaxLevelParenthesis(activity.minLevel, activity.maxLevel))
      	else
      	  label = string.format("%s %s", "|cffC0C0C0"..activity.name.."|r", VGT:GetMinMaxLevelParenthesis(activity.minLevel, activity.maxLevel))
      	end
        container.selectActivitiesScrollContainer.possibleDungeons[activity.name] = CreateCheckboxWithTooltip(label, label, self.char.selectedActivities[activity.name], function(widget, event, value)
          self.char.selectedActivities[activity.name] = value
        end)
        container.selectActivitiesScrollContainer.possibleDungeons[activity.name]:SetDisabled(not self.char.selectedActivities["Dungeons"])
        container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.possibleDungeons[activity.name])
      end
    end
  end

  if not container.selectActivitiesScrollContainer.raidDivider then
    container.selectActivitiesScrollContainer.raidDivider = AceGUI:Create("Heading")
    container.selectActivitiesScrollContainer.raidDivider:SetFullWidth(true)
    container.selectActivitiesScrollContainer.raidDivider:SetText("Select Raids")
    container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.raidDivider)
  end
  if not container.selectActivitiesScrollContainer.possibleRaids then
    container.selectActivitiesScrollContainer.possibleRaids = {}
    for _, activity in ipairs(possibleRaids) do
      if not container.selectActivitiesScrollContainer.possibleRaids[activity.name] then
      	local label = nil
      	if self.char.selectedActivities[activity.name] then
		  label = string.format("%s %s", VGT:ColorizeByLevel(activity.name, self.playerLevel, activity.minLevel, activity.maxLevel), VGT:GetMinMaxLevelParenthesis(activity.minLevel, activity.maxLevel))
      	else
      	  label = string.format("%s %s", "|cffC0C0C0"..activity.name.."|r", VGT:GetMinMaxLevelParenthesis(activity.minLevel, activity.maxLevel))
      	end
        container.selectActivitiesScrollContainer.possibleRaids[activity.name] = CreateCheckboxWithTooltip(label, label, self.char.selectedActivities[activity.name], function(widget, event, value)
          self.char.selectedActivities[activity.name] = value
        end)
        container.selectActivitiesScrollContainer.possibleRaids[activity.name]:SetDisabled(not self.char.selectedActivities["Raids"])
        container.selectActivitiesScrollContainer:AddChild(container.selectActivitiesScrollContainer.possibleRaids[activity.name])
      end
    end
  end

  container.selectActivitiesScrollContainer:DoLayout()
  return container
end

function activities:BuildViewActivitiesTab(container)
  self.receivedActivitiesSummary = self.receivedActivitiesSummary or {}

  if not container.viewActivitiesScrollContainer then
    container.viewActivitiesScrollContainer = AceGUI:Create("ScrollFrame")
    container.viewActivitiesScrollContainer:SetFullWidth(true)
    container.viewActivitiesScrollContainer:SetFullHeight(true)
    container.viewActivitiesScrollContainer:SetLayout("Flow")
    container:AddChild(container.viewActivitiesScrollContainer)
  end

  local function displayActivity(container, activity)
    container.activities = container.activities or {}
    if not container.activities[activity.name].label then
		container.activities[activity.name].label = AceGUI:Create("Label")
		local fontName, _, fontFlags = container.activities[activity.name].label.label:GetFont()
		container.activities[activity.name].label.label:SetFont(fontName, 14, fontFlags)
		if IsDungeonOrRaid(activity.name) then
		  container.activities[activity.name].label:SetText(string.format("%s %s", VGT:ColorizeByLevel(activity.name, self.playerLevel, activity.minLevel, activity.maxLevel), VGT:GetMinMaxLevelParenthesis(activity.minLevel, activity.maxLevel)))
		else
		  container.activities[activity.name].label:SetText(string.format("%s", activity.name))
		end
		container.activities[activity.name].label:SetFullWidth(true)
		container:AddChild(container.activities[activity.name].label)
    end

    local playersData = self.receivedActivitiesSummary[activity.name] or {}
    local sortablePlayers = {}
    for player, data in pairs(playersData) do
      table.insert(sortablePlayers, {
        player = player,
        level = VGT.guildRoster[player].level,
        class = VGT.guildRoster[player].class,
        roles = data.roles
      })
    end
    table.sort(sortablePlayers, function(a, b)
      if a.level == b.level then
        return a.player < b.player
      else
        return a.level > b.level
      end
    end)

    -- Display sorted players
    for _, playerData in ipairs(sortablePlayers) do
      local playerLabel = AceGUI:Create("InteractiveLabel")

      -- Customizing the font size
      local plfontName, _, plfontFlags = playerLabel.label:GetFont()
      playerLabel.label:SetFont(plfontName, 12, plfontFlags)  -- Increase font size by 2

      local colorizedLevel = "|cffFFFF00" .. playerData.level .. "|r"
      local colorizedName = VGT:ColorizeCharacterName(playerData.player, playerData.class)
      local roleString = ""
      for _, role in pairs(playerData.roles) do
        local coords = roleTexturesPixels[role]
        roleString = roleString .. string.format("|T%s:14:14:0:0:256:256:%d:%d:%d:%d|t", rolesTexture, coords[1], coords[2], coords[3], coords[4])
      end
      playerLabel:SetText(string.format("    %s %s%s", colorizedLevel, colorizedName, roleString))

      -- Adding mouse click script to invite player
      playerLabel:SetCallback("OnClick", function(widget, event, button)
        if IsAltKeyDown() and button == "LeftButton" then
          InviteUnit(playerData.player)
        end
      end)

      container:AddChild(playerLabel)
    end

	if not container.activities[activity.name].activityDivider then
		container.activities[activity.name].activityDivider = AceGUI:Create("Heading")
		container.activities[activity.name].activityDivider:SetFullWidth(true)
		container:AddChild(container.activities[activity.name].activityDivider)
    end
  end

  -- Display main activities first
  for _, activity in ipairs(possibleActivities) do
    displayActivity(container.viewActivitiesScrollContainer, activity)
  end

  -- Display other activities
  for _, activity in pairs(possibleDungeons) do
    displayActivity(container.viewActivitiesScrollContainer, activity)
  end

  for _, activity in pairs(possibleRaids) do
    displayActivity(container.viewActivitiesScrollContainer, activity)
  end

  -- Update the layout of the container
  container.viewActivitiesScrollContainer:DoLayout()
  return container
end

function activities:BuildTabs()
  if not self.activityWindow.tabGroup then
    self.activityWindow.tabGroup = AceGUI:Create("TabGroup")
    self.activityWindow.tabGroup:SetFullWidth(true)
    self.activityWindow.tabGroup:SetFullHeight(true)
    self.activityWindow.tabGroup:SetLayout("Flow")
    self.activityWindow.tabGroup:SetTabs({
      {text = "Select Activities", value = "selectTab"},
      {text = "View Activities", value = "viewTab"}
    })
    self.activityWindow:AddChild(self.activityWindow.tabGroup)

    local activityWindow = self.activityWindow
    self.activityWindow.tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
      if group == "selectTab" then
        activityWindow.tabGroup.selectActivitiesTab = self:BuildSelectActivitiesTab(container)
        if container.viewActivitiesScrollContainer then
          container.viewActivitiesScrollContainer.frame:Hide()
	    end
        container.selectActivitiesScrollContainer.frame:Show()
        activityWindow:SetStatusText("Select your roles and activities to broadcast to your guild silently")
      elseif group == "viewTab" then
        activityWindow.tabGroup.viewActivitiesTab = self:BuildViewActivitiesTab(container)
        if container.selectActivitiesScrollContainer then
          container.selectActivitiesScrollContainer.frame:Hide()
        end
        container.viewActivitiesScrollContainer.frame:Show()
        activityWindow:SetStatusText("View guild activities and alt+click to invite players")
      end
    end)

    self.activityWindow.tabGroup:SelectTab(self.activityWindow.tabGroup.currentTab or "selectTab")
  end
end

function activities:BuildWindow()
  if not self.activityWindow then
    self.activityWindow = AceGUI:Create("Frame")
    self.activityWindow:SetTitle("Valhalla Activity Finder")
    self.activityWindow:SetStatusText("Select your roles and activities to broadcast to your guild silently")
    self.activityWindow:SetWidth(680)
    self.activityWindow:SetHeight(680)
    self.activityWindow:SetLayout("Flow")
    self.activityWindow:SetPoint("CENTER", self.profile.x, self.profile.y)
    self.activityWindow:EnableResize(false)
    _G["VGTActivityWindow"] = self.activityWindow.frame
    tinsert(UISpecialFrames, "VGTActivityWindow")
    self.activityWindow:SetCallback("OnDragStop", function(widget, event, left, top)
      self.profile.x = left
      self.profile.y = top
    end)
    self:BuildTabs()
  end
end

function activities:OnMessageReceived(prefix, message, channel, sender)
  if prefix ~= moduleName or channel ~= "GUILD" then
    return
  end

  local activitiesSection, rolesSection = string.match(message, "Activities:(.*)Roles:(.*)")

  local receivedActivities = {}
  for activity in string.gmatch(activitiesSection or "", "([^;]+)") do
    table.insert(receivedActivities, activity)
  end

  local receivedRoles = {}
  for role in string.gmatch(rolesSection or "", "([^;]+)") do
    table.insert(receivedRoles, role)
  end

  VGT.LogTrace("Received activities from %s", sender)

  self:UpdateWithReceivedActivities(receivedActivities, receivedRoles, sender)
end

-- Function to update your addon with the received activities
function activities:UpdateWithReceivedActivities(receivedActivities, receivedRoles, sender)
  local currentTime = time()
  -- Initialize the storage structure if it doesn't exist
  self.receivedActivitiesSummary = self.receivedActivitiesSummary or {}

  -- Track activities received in the current update
  local currentReceivedActivities = {}

  -- Process the received activities
  for _, activity in ipairs(receivedActivities) do
    currentReceivedActivities[activity] = true
    self.receivedActivitiesSummary[activity] = self.receivedActivitiesSummary[activity] or {}
    self.receivedActivitiesSummary[activity][sender] = { roles = receivedRoles, lastUpdated = currentTime }
  end

  -- Remove activities not present in the current batch but exist in the summary for this sender
  for activity, senders in pairs(self.receivedActivitiesSummary) do
    if senders[sender] and not currentReceivedActivities[activity] then
      senders[sender] = nil
    end
  end

  -- Update the UI if the 'View Activities' tab is currently displayed
  if self.activityWindow and self.activityWindow.currentTab == "viewTab" then
    self:RefreshActivityWindow()
  end
end

function activities:PrintReceivedActivities()
  --TODO
end

function activities:SetupActivityNotifierTimer()
  self:ScheduleRepeatingTimer(function() self:PrintReceivedActivities() end, sendTimer)
end

-- Function to serialize and send selected activities
function activities:SendSelectedActivities()
  if not IsInGuild() then
    return
  end

  if next(self.char.selectedActivities) == nil then
    return
  end

  local dungeonSelected = self.char.selectedActivities["Dungeons"]
  local raidSelected = self.char.selectedActivities["Raids"]

  local data = "Activities:"
  for activity, isSelected in pairs(self.char.selectedActivities) do
    if isSelected then
      if (dungeonLookup[activity] and dungeonSelected) or (raidLookup[activity] and raidSelected) or (not IsDungeonOrRaid(activity)) then
        data = data .. activity .. ";"
      end
    end
  end

  data = data .. "Roles:"
  for role, isSelected in pairs(self.char.selectedRoles) do
    if isSelected then
      data = data .. role .. ";"
    end
  end

  if data ~= "" then
    VGT.LogTrace("Sending activity selections to guild")
    self:SendCommMessage(moduleName, data, "GUILD")
  end
end

function activities:SetupActivitySenderTimer()
  self:ScheduleRepeatingTimer(function() self:SendSelectedActivities() end, sendTimer)
end

function activities:CleanupOldActivities()
  local currentTime = time()
  local cutoffTime = oldTimer

  if not self.receivedActivitiesSummary then
    return
  end

  for activity, playersData in pairs(self.receivedActivitiesSummary) do
    for player, data in pairs(playersData) do
      if (currentTime - data.lastUpdated) > cutoffTime then
        self.receivedActivitiesSummary[activity][player] = nil
      end
    end
  end

  -- Update the UI if necessary
  if self.activityWindow and self.activityWindow.currentTab == "viewTab" then
    self:RefreshActivityWindow()
  end
end

function activities:SetupCleanupTimer()
  self:ScheduleRepeatingTimer(function() self:CleanupOldActivities() end, cleanupTimer)
end

function activities:OnEnable()
  self:CleanupSelectedActivities()
  self:RegisterEvent("PLAYER_LEVEL_UP")
  self:RegisterComm(moduleName, "OnMessageReceived")
  self:SetupActivityNotifierTimer()
  self:SetupActivitySenderTimer()
  self:SetupCleanupTimer()
  self:SendSelectedActivities()
end
