local lootTracker = VGT:NewModule("lootTracker")
local AceGUI = LibStub("AceGUI-3.0")
VGT_MasterLootData = VGT_MasterLootData or {}

lootTracker.currentTrades = {}
lootTracker.activeSlots = {}
lootTracker.responses = {}

-- https://wowpedia.fandom.com/wiki/InstanceID
lootTracker.trackedInstances = {
  [624] = true, -- Vault of Archavon

  [533] = true, -- Naxxramas
  [615] = true, -- Obsidian Sanctum
  [616] = true, -- Eye of Eternity

  [603] = true, -- Ulduar

  [649] = true, -- Trial of the Crusader
  [249] = true, -- Onyxia's Lair

  [631] = true, -- Icecrown Citadel

  [724] = true -- Ruby Sanctum
}

function lootTracker:GetOrCreatePreemtiveResponse(itemId)
  if not VGT_MasterLootData.PreemptiveResponses then
    VGT_MasterLootData.PreemptiveResponses = {}
  end
  local itemResponses = VGT_MasterLootData.PreemptiveResponses[itemId]
  if not itemResponses then
    itemResponses = {}
    VGT_MasterLootData.PreemptiveResponses[itemId] = itemResponses
  end
  return itemResponses
end

function lootTracker:SendGroupMessage(message, nowarn)
  local channel
  if UnitInRaid("player") then
    if nowarn then
      channel = "RAID"
    elseif IsEveryoneAssistant() then
      channel = "RAID_WARNING"
    else
      channel = "RAID"
      for i = 1, 40 do
        if (UnitIsUnit("player", "raid" .. i)) then
          local _, rank = GetRaidRosterInfo(i)
          if (rank and rank > 0) then
            channel = "RAID_WARNING"
          end
        end
      end
    end
  elseif UnitInParty("player") then
    channel = "PARTY"
  end

  if channel then
    SendChatMessage(message, channel)
  else
    VGT.LogSystem(message)
  end
end

function lootTracker:ReadData(creatureGuid, itemId, itemIndex)
  if not creatureGuid then
    return
  end

  for _, creatureData in ipairs(VGT_MasterLootData) do
    if creatureData.id == creatureGuid then
      if itemId then
        itemId = tonumber(itemId)
        itemIndex = tonumber(itemIndex)
        for _, itemData in ipairs(creatureData.items) do
          if (itemData.id == itemId and itemData.index == itemIndex) then
            return creatureData, itemData
          end
        end
      end
      return creatureData
    end
  end
end

function lootTracker:GetRollData()
  return self:ReadData(self.rollCreature, self.rollItem, self.rollIndex)
end

function lootTracker:AddPrioToStandings(itemId, name, prio)
  if VGT_MasterLootData.Standings then
    local itemStandings = VGT_MasterLootData.Standings[itemId]
    if itemStandings then
      for i, standing in ipairs(itemStandings) do
        if standing.Prio == prio then
          tinsert(standing.Names, name)
          return
        elseif standing.Prio < prio then
          tinsert(itemStandings, i, {
            Prio = prio,
            Names = {name}
          })
          return
        end
      end
    end
  end
end

function lootTracker:TakePrioFromStandings(itemId, name)
  if VGT_MasterLootData.Standings then
    local itemStandings = VGT_MasterLootData.Standings[itemId]
    if itemStandings then
      for _, standing in ipairs(itemStandings) do
        for i, n in ipairs(standing.Names) do
          if n == name then
            tremove(standing.Names, i)
            return standing.Prio
          end
        end
      end
    end
  end
end

function lootTracker:IncrementStandings(itemId, characters)
  if VGT_MasterLootData.Standings then
    for _, character in ipairs(characters) do
      local prios = {}

      while true do
        local prio = self:TakePrioFromStandings(itemId, character.Name)
        if type(prio) == "number" then
          tinsert(prios, prio)
        else
          break
        end
      end

      if #prios > 0 then
        for _, prio in ipairs(prios) do
          self:AddPrioToStandings(itemId, character.Name, prio + 1)
        end
      end
    end
  end
end

function lootTracker:FindExpiringItems()
  local items = {}
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local containerItemId = GetContainerItemID(bag, slot)
      if containerItemId then
        local icon, _, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
        VGTScanningTooltip:ClearLines()
        VGTScanningTooltip:SetBagItem(bag, slot)
        local isSoulbound = false
        local tradableText
        for i = 1, VGTScanningTooltip:NumLines() do
          local line = _G["VGTScanningTooltipTextLeft" .. i]
          local text = line and line:GetText() or ""
          if text == ITEM_SOULBOUND then
            isSoulbound = true
          elseif isSoulbound and VGT.IsBindTimeRemainingLine(text) then
            tradableText = text
            break
          end
        end
        if tradableText then
          local timeRemaining = VGT.ExtractSoulboundTimeRemaining(tradableText)
          if timeRemaining and timeRemaining > 0 then
            tinsert(items, {
              id = containerItemId,
              expiration = timeRemaining,
              icon = icon,
              link = itemLink
            })
          end
        end
      end
    end
  end
  table.sort(items, function(l, r)
    return l.expiration < r.expiration
  end)
  return items
end

function lootTracker:ConfigureEncounter(creatureGuid)
  local label = AceGUI:Create("InteractiveLabel")
  label:SetText("Unknown")
  label:SetFullWidth(true)
  label:SetFont(GameFontHighlight:GetFont(), 16)
  self.scroll:AddChild(label)

  local spacer = AceGUI:Create("InteractiveLabel")
  spacer:SetFullWidth(true)
  spacer:SetText(" ")
  self.scroll:AddChild(spacer)

  local creatureData = self:ReadData(creatureGuid)

  if creatureData then
    label:SetText(creatureData.name or VGT:UnitNameFromGuid(creatureGuid))

    local exportButton = AceGUI:Create("Button")
    exportButton:SetText("Export Items")
    exportButton:SetFullWidth(true)
    exportButton:SetCallback("OnClick", function()
      local items = {}
      local allowedClasses = {
        [2] = true, -- Weapon
        [4] = true, -- Armor
        [15] = true -- Miscellaneous
      }
      local ignoredItems = {
        [44569] = true, -- Key to the Focusing Iris
        [44577] = true -- Heroic Key to the Focusing Iris
      }

      for _, itemData in ipairs(creatureData.items) do
        if (not itemData.class or itemData.quality == 4) and (not itemData.class or allowedClasses[itemData.class]) and not ignoredItems[itemData.id] then
          tinsert(items, itemData.id)
        end
      end

      VGT:ShowKillExport(items, creatureData.characters)
    end)
    self.scroll:AddChild(exportButton)

    if strsplit("-", creatureData.id, 2) == "Unknown" then
      local renameButton = AceGUI:Create("Button")
      renameButton:SetText("Rename")
      renameButton:SetFullWidth(true)
      renameButton:SetCallback("OnClick", function()
        VGT:ShowInputDialog("Rename", creatureData.name, function(name)
          creatureData.name = name
          if creatureData.id == "Unknown-0-0-0-0-0-0-0" then
            local i = 1
            local newId = "Unknown-0-0-0-0-0-0-" .. i
            while self:ReadData(newId) do
              i = i + 1
              newId = "Unknown-0-0-0-0-0-0-" .. i
            end
            creatureData.id = newId
            self.tree:Select("encounter+" .. newId)
          end
          self:Refresh()
        end)
      end)
      self.scroll:AddChild(renameButton)

      local manualTrackButton = AceGUI:Create("Button")
      manualTrackButton:SetText("Manual Track Item")
      manualTrackButton:SetFullWidth(true)
      manualTrackButton:SetCallback("OnClick", function()
        local infoType, itemId, itemLink = GetCursorInfo()
        ClearCursor()
        if infoType == "item" then
          self:TrackUnknown(itemId, creatureData.id)
        else
          VGT.LogSystem("Click this button while holding an item to add it to the tracker.")
        end
      end)
      self.scroll:AddChild(manualTrackButton)
    end

    local deleteButton = AceGUI:Create("Button")
    deleteButton:SetText("Delete")
    deleteButton:SetFullWidth(true)
    deleteButton:SetCallback("OnClick", function()
      self:Delete(creatureGuid)
    end)
    self.scroll:AddChild(deleteButton)
  end
end

function lootTracker:ConfigureItem(creatureId, itemId, itemIndex)
  local creatureData, itemData = self:ReadData(creatureId, itemId, itemIndex)

  local label = AceGUI:Create("InteractiveLabel")
  label:SetImage(itemData.icon)
  label:SetImageSize(24, 24)
  label:SetText(itemData.link)
  label:SetFullWidth(true)
  label:SetFont(GameFontHighlight:GetFont(), 16)
  label:SetCallback("OnEnter", function()
    GameTooltip:SetOwner(label.frame, "ANCHOR_CURSOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. itemId)
    GameTooltip:Show()
  end)
  label:SetCallback("OnLeave", function()
    GameTooltip:Hide()
  end)
  self.scroll:AddChild(label)

  label = AceGUI:Create("InteractiveLabel")
  label:SetFullWidth(true)
  label:SetFont(GameFontHighlight:GetFont(), 16)
  label:SetText(itemData.winner and ((itemData.disenchanted and "|cff2196f3Disenchanted by " or "|cff00ff00Assigned to ") .. itemData.winner .. "|r") or "|cffff0000Unassigned|r")
  self.scroll:AddChild(label)

  local spacer = AceGUI:Create("InteractiveLabel")
  spacer:SetFullWidth(true)
  spacer:SetText(" ")
  self.scroll:AddChild(spacer)

  if itemData.winner then
    local unassignButton = AceGUI:Create("Button")
    unassignButton:SetText("Unassign Item")
    unassignButton:SetFullWidth(true)
    unassignButton:SetCallback("OnClick", function()
      local oldWinner = itemData.winner
      local oldPrio = itemData.winningPrio
      itemData.winner = nil
      itemData.traded = nil
      itemData.winningPrio = nil
      itemData.disenchanted = nil

      if oldPrio then
        self:AddPrioToStandings(itemData.id, oldWinner, oldPrio)
      end

      self:SendGroupMessage(itemData.link .. " unassigned from " .. oldWinner)
      VGT:SendPlayerAddonCommand(oldWinner, VGT.Commands.UNASSIGN_ITEM, itemData.id)
      self:Refresh()
    end)
    self.scroll:AddChild(unassignButton)

    local toggleTradeButton = AceGUI:Create("CheckBox")
    toggleTradeButton:SetLabel("Traded")
    toggleTradeButton:SetValue(itemData.traded and true or false)
    toggleTradeButton:SetCallback("OnValueChanged", function()
      itemData.traded = not itemData.traded
      self:Refresh()
    end)
    self.scroll:AddChild(toggleTradeButton)
  else
    local rollCreature, rollItem = self:GetRollData()

    if rollItem then
      if rollItem == itemData then
        local stopButton = AceGUI:Create("Button")
        stopButton:SetText("End Rolling")
        stopButton:SetCallback("OnClick", function()
          self:EndRoll()
        end)
        self.scroll:AddChild(stopButton)

        local countdownButton = AceGUI:Create("Button")
        countdownButton:SetText("5-Second Countdown")
        countdownButton:SetCallback("OnClick", function()
          self:CountdownRoll()
        end)
        self.scroll:AddChild(countdownButton)

        local remindButton = AceGUI:Create("Button")
        remindButton:SetText("Remind Rollers")
        remindButton:SetCallback("OnClick", function()
          self:RemindRoll()
        end)
        self.scroll:AddChild(remindButton)

        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel Rolling")
        cancelButton:SetCallback("OnClick", function()
          self:CancelRoll()
        end)
        self.scroll:AddChild(cancelButton)

        local orderedResponses = {}
        local responseCount, totalCount = 0, 0

        if self.rollWhitelist then
          for _, name in ipairs(self.rollWhitelist) do
            totalCount = totalCount + 1
            local response = self.responses[name]
            if response then
              responseCount = responseCount + 1
              tinsert(orderedResponses, response)
            else
              tinsert(orderedResponses, {
                name = name
              })
            end
          end
        else
          for _, character in ipairs(rollCreature.characters) do
            totalCount = totalCount + 1
            local response = self.responses[character.Name]
            if response then
              responseCount = responseCount + 1
              tinsert(orderedResponses, response)
            else
              tinsert(orderedResponses, {
                name = character.Name
              })
            end
          end
        end

        table.sort(orderedResponses, function(l, r)
          if l.pass == r.pass then
            if l.roll == r.roll or l.pass then
              return l.name < r.name
            end
            return (l.roll or 0) > (r.roll or 0)
          end
          return (l.pass and 1 or 0) < (r.pass and 1 or 0)
        end)

        local label = AceGUI:Create("Label")
        label:SetText(responseCount .. " of " .. totalCount .. " responded.")
        self.scroll:AddChild(label)

        for i, v in ipairs(orderedResponses) do
          local text = v.name

          if v.pass then
            text = text .. " - passed"
          elseif v.roll then
            text = text .. " - |cff00ff00" .. v.roll .. "|r"
          else
            text = text .. " - |cffff0000no response|r"
          end

          local label = AceGUI:Create("Label")
          label:SetText(text)
          self.scroll:AddChild(label)
        end
      else
        local label = AceGUI:Create("Label")
        label:SetFullWidth(true)
        label:SetFont(GameFontHighlight:GetFont(), 16)
        label:SetText("|cffff0000Currently rolling on " .. rollItem.name .. "|r")
        self.scroll:AddChild(label)

        local spacer = AceGUI:Create("Label")
        spacer:SetFullWidth(true)
        spacer:SetText(" ")
        self.scroll:AddChild(spacer)
      end
    else
      if VGT_MasterLootData.Standings then
        local itemStandings = VGT_MasterLootData.Standings[itemData.id]
        if itemStandings then
          for _, s in ipairs(itemStandings) do
            local standing = s
            local whitelist = {}
            local lookup = {}

            for _, name in ipairs(standing.Names) do
              lookup[name] = true
            end

            for _, character in ipairs(creatureData.characters) do
              if lookup[character.Name] then
                tinsert(whitelist, character.Name)
              end
            end

            if #whitelist > 0 then
              local standingButton = AceGUI:Create("Button")
              standingButton:SetFullWidth(true)
              local sText = "(" .. standing.Prio .. ") "
              local addComma = false

              for _, name in ipairs(whitelist) do
                if addComma then
                  sText = sText .. ", "
                end
                addComma = true
                sText = sText .. name
              end

              standingButton:SetText(sText)
              standingButton:SetCallback("OnClick", function()
                if #whitelist == 1 then
                  itemData.winner = whitelist[1]
                  itemData.winningPrio = self:TakePrioFromStandings(itemData.id, itemData.winner)
                  itemData.traded = UnitIsUnit(itemData.winner, "player")
                  VGT:SendPlayerAddonCommand(itemData.winner, VGT.Commands.ASSIGN_ITEM, itemData.id)
                  self:SendGroupMessage(itemData.link .. " assigned to " .. itemData.winner .. " (" .. itemData.winningPrio .. " Prio)")
                  self:Refresh()
                else
                  self:LimitedRoll(creatureData.id, itemData.id, itemData.index, whitelist)
                end
              end)

              self.scroll:AddChild(standingButton)
            end
          end
        end
      end

      local rollButton = AceGUI:Create("Button")
      rollButton:SetText("Open Roll")
      rollButton:SetFullWidth(true)
      rollButton:SetCallback("OnClick", function()
        self:OpenRoll(creatureId, itemId, itemIndex)
      end)
      self.scroll:AddChild(rollButton)

      local manualAssign = AceGUI:Create("Dropdown")
      manualAssign:SetLabel("Manual Assign")
      self.scroll:AddChild(manualAssign)
      local characters = {}
      for i, character in ipairs(creatureData.characters) do
        characters[character.Name] = VGT:ColorizeCharacterName(character)
      end
      table.sort(characters)
      manualAssign:SetList(characters)
      manualAssign:SetCallback("OnValueChanged", function(s, e, value)
        itemData.winner = value
        itemData.winningPrio = self:TakePrioFromStandings(itemData.id, value)
        itemData.traded = UnitIsUnit(value, "player")
        VGT:SendPlayerAddonCommand(value, VGT.Commands.ASSIGN_ITEM, itemData.id)
        self:SendGroupMessage(itemData.link .. " assigned to " .. value)
        self:Refresh()
      end)

      local deAssign = AceGUI:Create("Dropdown")
      deAssign:SetLabel("Disenchant Assign")
      deAssign:SetList(characters)
      deAssign:SetCallback("OnValueChanged", function(s, e, value)
        itemData.winner = value
        itemData.winningPrio = self:TakePrioFromStandings(itemData.id, value)
        itemData.traded = UnitIsUnit(value, "player")
        itemData.disenchanted = true
        VGT:SendPlayerAddonCommand(value, VGT.Commands.ASSIGN_ITEM, itemData.id, true)
        self:SendGroupMessage(itemData.link .. " will be disenchanted by " .. value)
        self:Refresh()
      end)
      self.scroll:AddChild(deAssign)

      local preemptiveResponses = self:GetOrCreatePreemtiveResponse(itemData.id)

      if next(preemptiveResponses) then
        local interested = {}
        local passCount = 0

        for name, response in pairs(preemptiveResponses) do
          if response then
            tinsert(interested, name)
          else
            passCount = passCount + 1
          end
        end

        if #interested > 0 then
          table.sort(interested)
          local label = AceGUI:Create("Label")
          label:SetText("Wanted by: " .. strjoin(", ", unpack(interested)))
          self.scroll:AddChild(label)
        end

        if passCount > 0 then
          local label = AceGUI:Create("Label")
          label:SetText("Passed by " .. passCount .. " of " .. #creatureData.characters .. " people.")
          self.scroll:AddChild(label)
        end
      end
    end
  end
end

function lootTracker:ConfigureHome()
  local rsbutton = AceGUI:Create("Button")
  rsbutton:SetText("Raid Start")
  rsbutton:SetCallback("OnClick", function()
    VGT:ShowRaidStartExport()
  end)
  self.scroll:AddChild(rsbutton)

  local importStatus = AceGUI:Create("Label")
  importStatus:SetText(" ")

  local importText = AceGUI:Create("EditBox")
  importText:SetMaxLetters(0)
  importText:SetLabel("Import Standings")
  importText:SetCallback("OnEnterPressed", function()
    local text = importText:GetText()
    importText:SetText("")

    local success = pcall(function()
      local items = json.decode(text)
      VGT_MasterLootData.Standings = {}

      for _, item in ipairs(items) do
        VGT_MasterLootData.Standings[item.Id] = item.Standings
      end
    end)
    if not success then
      importStatus:SetText("|cffff0000Import failed.|r")
      VGT_MasterLootData.Standings = nil
    else
      self:Refresh()
      importStatus:SetText("|cff00ff00Import Succeeded.|r")
    end
  end)

  self.scroll:AddChild(importText)
  self.scroll:AddChild(importStatus)

  local manualTrackButton = AceGUI:Create("Button")
  manualTrackButton:SetText("Manual Track Item")
  manualTrackButton:SetCallback("OnClick", function()
    local infoType, itemId, itemLink = GetCursorInfo()
    ClearCursor()
    if infoType == "item" then
      self:TrackUnknown(itemId)
    else
      VGT.LogSystem("Click this button while holding an item to add it to the tracker.")
    end
  end)
  self.scroll:AddChild(manualTrackButton)

  local clearButton = AceGUI:Create("Button")
  clearButton:SetText("Clear All")
  clearButton:SetCallback("OnClick", function()
    self:ClearAll()
  end)
  self.scroll:AddChild(clearButton)

  local vCheckButton = AceGUI:Create("Button")
  vCheckButton:SetText("Check Group for Addon")
  vCheckButton:SetCallback("OnClick", function()
    self:GroupVersionCheck()
  end)
  self.scroll:AddChild(vCheckButton)

  local treeToggle = AceGUI:Create("CheckBox")
  treeToggle:SetLabel("Group By Winner")
  treeToggle:SetValue(self.profile.groupByWinner and true or false)
  treeToggle:SetCallback("OnValueChanged", function()
    self.profile.groupByWinner = not self.profile.groupByWinner
    self:Refresh()
  end)
  self.scroll:AddChild(treeToggle)

  local pendingTrades = {}

  for _, creatureData in ipairs(VGT_MasterLootData) do
    for _, itemData in ipairs(creatureData.items) do
      if itemData.winner and not itemData.traded then
        pendingTrades[itemData.winner] = true
      end
    end
  end

  if next(pendingTrades) then
    local pendingTradeText = "Pending Trade: "
    local sep

    for name in pairs(pendingTrades) do
      if sep then
        pendingTradeText = pendingTradeText .. ", "
      else
        sep = true
      end
      pendingTradeText = pendingTradeText .. name
    end

    local label = AceGUI:Create("Label")
    label:SetText(pendingTradeText)
    self.scroll:AddChild(label)
  end

  -- local expiringItems = self:FindExpiringItems()
  --
  -- if #expiringItems > 0 then
  --    local expiringLabel = AceGUI:Create("Label")
  --    expiringLabel:SetText("Expiring Items:")
  --    self.scroll:AddChild(expiringLabel)
  --    for _,v in ipairs(expiringItems) do
  --        if v.expiration > 1800 then
  --            --break
  --        end 
  --        local itemLabel = AceGUI:Create("Label")
  --        itemLabel:SetImage(v.icon)
  --        itemLabel:SetImageSize(16, 16)
  --        itemLabel:SetText("(|cff" .. VGT.RGBToHex(VGT.ColorGradient(v.expiration / 7200, 1, 0, 0, 1, 1, 0, 0, 1, 0)) .. VGT.TimeToString(v.expiration) .. "|r) " .. v.link)
  --        itemLabel:SetFullWidth(true)
  --        self.scroll:AddChild(itemLabel)
  --    end
  -- end
end

function lootTracker:ConfigureCharacter(characterName)
  local label = AceGUI:Create("InteractiveLabel")
  label:SetText(characterName or "Unassigned")
  label:SetFullWidth(true)
  label:SetFont(GameFontHighlight:GetFont(), 16)
  self.scroll:AddChild(label)
end

function lootTracker:ConfigureSelection(groupId)
  local currentScroll = self.scroll.localstatus.scrollvalue

  local lastId = self.groupId
  self.groupId = groupId

  self.scroll:ReleaseChildren()

  if groupId then
    local parentKey, childKey = strsplit("\001", groupId)
    if childKey then
      local creatureId, itemId, itemIndex = strsplit("+", childKey)
      self:ConfigureItem(creatureId, tonumber(itemId), tonumber(itemIndex) or 1)
    else
      local nodeType, nodeId = strsplit("+", parentKey)
      if nodeType == "character" then
        self:ConfigureCharacter(nodeId)
      elseif nodeType == "encounter" then
        self:ConfigureEncounter(nodeId)
      end
    end
  else
    self:ConfigureHome()
  end

  self.scroll:SetScroll(lastId == groupId and currentScroll or 0)
  self.scroll:FixScroll()
end

function lootTracker:CreateRoot()
  self.root = AceGUI:Create("Window")
  self.root:SetTitle("Valhalla Master Looter")
  self.root:SetLayout("Fill")
  self:RefreshWindowConfig() -- SetPoint, SetWidth, SetHeight
  self.root:SetCallback("OnClose", function()
    local point, _, _, x, y = self.root.frame:GetPoint(1)
    self.profile.x = x
    self.profile.y = y
    self.profile.point = point
    self.profile.width = self.root.frame:GetWidth()
    self.profile.height = self.root.frame:GetHeight()
  end)

  local tree = AceGUI:Create("TreeGroup")
  tree:EnableButtonTooltips(false)
  tree:SetFullWidth(true)
  tree:SetFullHeight(true)
  tree:SetLayout("Fill")
  tree:SetAutoAdjustHeight(false)
  tree:SetCallback("OnGroupSelected", function(s, e, groupId)
    self:ConfigureSelection(groupId)
  end)
  self.root:AddChild(tree)
  self.tree = tree

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  self.tree:AddChild(scroll)
  self.scroll = scroll

  self:Refresh()
end

function lootTracker:RefreshWindowConfig()
  if self.root then
    self.root:SetHeight(self.profile.height < 240 and 240 or self.profile.height)
    self.root:SetWidth(self.profile.width < 400 and 400 or self.profile.width)
    self.root:SetPoint(self.profile.point, UIParent, self.profile.point, self.profile.x, self.profile.y)
  end
end

function lootTracker:RefreshConfig()
  self:RefreshWindowConfig()
  self:Refresh()
end

function lootTracker:GroupVersionCheck()
  local unitType, maxUnits
  if IsInRaid() then
    unitType, maxUnits = "raid", 40
  elseif IsInGroup() then
    unitType, maxUnits = "party", 4
  else
    VGT.LogError("You are not in a group.")
    return
  end

  VGT:GetModule("userFinder"):EnumerateUsers(function(results)
    local versions = {}
    for i = 1, maxUnits do
      local unitName = unitType .. i
      if UnitExists(unitName) then
        local name = UnitName(unitName)
        local version = results[name]
        if version ~= VGT.version then
          local versionUsers = versions[version or "Not installed"]
          if versionUsers then
            tinsert(versionUsers, name)
          else
            versions[version or "Not installed"] = {name}
          end
        end
      end
    end
    VGT.LogSystem("Your version: " .. VGT.version)
    if not next(versions) then
      VGT.LogSystem("All players are using your version.")
    else
      for version, users in pairs(versions) do
        table.sort(users)
        local text = version .. ": "
        local sep
        for _, name in ipairs(users) do
          if sep then
            text = text .. ", "
          else
            sep = true
          end
          text = text .. name
        end
        VGT.LogSystem(text)
      end
    end
  end, 2, true)
end

function lootTracker:ClearAll()
  VGT:Confirm(function()
    VGT_MasterLootData = {}
    self.tree:Select()
    self:Refresh()
  end)
end

function lootTracker:Delete(creatureGuid)
  VGT:Confirm(function()
    for i, creature in ipairs(VGT_MasterLootData) do
      if creature.id == creatureGuid then
        tremove(VGT_MasterLootData, i)
        self.tree:Select()
        self:Refresh()
        return
      end
    end
  end)
end

function lootTracker:Toggle()
  if not self.enabledState then
    VGT.LogWarning("Master loot tracker module is disabled.")
    return
  end
  if not self.root then
    self:CreateRoot()
  else
    if self.root:IsShown() then
      self.root.frame:Hide()
    else
      self:Refresh()
      self.root.frame:Show()
    end
  end
end

function lootTracker:Refresh()
  if self.root then
    local function buildItemNodes(node, items, creatureId)
      local allAssigned, allTraded = true, true
      local anyAssigned, anyUnassigned
      node.children = {}

      for _, item in ipairs(items) do
        local itemNode = {
          text = item.name,
          value = (creatureId or item.creatureId) .. "+" .. item.id .. "+" .. item.index,
          icon = item.traded and "Interface\\RAIDFRAME\\ReadyCheck-Ready.blp" or item.icon
        }
        item.creatureId = nil

        tinsert(node.children, itemNode)

        if item.winner then
          if not item.traded then
            allTraded = false
          end
          itemNode.text = (item.disenchanted and "|cff2196f3" or "|cff00ff00") .. item.name .. "|r"
        else
          allAssigned = false
          allTraded = false
        end
      end

      if allTraded then
        node.icon = "Interface\\RAIDFRAME\\ReadyCheck-Ready.blp"
      else
        node.icon = "Interface\\Buttons\\UI-StopButton.blp"
      end

      if allAssigned then
        node.text = "|cff00ff00" .. node.text .. "|r"
      end
    end

    local data = {{
      text = "Home",
      value = nil,
      icon = "Interface\\Buttons\\UI-HomeButton.blp"
    }}

    if VGT_MasterLootData.expiration and GetTime() > VGT_MasterLootData.expiration then
      VGT_MasterLootData = {}
      self.tree:Select()
    end

    if self.profile.groupByWinner then
      local characters = {}
      local unassigned = {}
      for _, creatureData in ipairs(VGT_MasterLootData) do
        for _, itemData in ipairs(creatureData.items) do
          itemData.creatureId = creatureData.id
          if itemData.winner then
            local charItems = characters[itemData.winner]
            if not charItems then
              charItems = {}
              characters[itemData.winner] = charItems
            end
            tinsert(charItems, itemData)
          else
            tinsert(unassigned, itemData)
          end
        end
      end
      table.sort(characters)

      for characterName, charItems in pairs(characters) do
        local characterNode = {
          value = "character+" .. characterName,
          text = characterName
        }
        buildItemNodes(characterNode, charItems)
        tinsert(data, characterNode)
      end

      local unassignedNode = {
        value = "character",
        text = "Unassigned"
      }
      buildItemNodes(unassignedNode, unassigned)
      tinsert(data, unassignedNode)
    else
      for _, creatureData in ipairs(VGT_MasterLootData) do
        local creatureNode = {
          value = "encounter+" .. creatureData.id,
          text = creatureData.name or VGT:UnitNameFromGuid(creatureData.id)
        }
        buildItemNodes(creatureNode, creatureData.items, creatureData.id)
        tinsert(data, creatureNode)
      end
    end

    self.tree:SetTree(data)
    self:ConfigureSelection(self.groupId)
  end
end

function lootTracker:TrackUnknown(itemId, creatureId)
  creatureId = creatureId or "Unknown-0-0-0-0-0-0-0"
  VGT.LogTrace("Tracking item:%s for %s", itemId, creatureId)
  local creatureData, itemData = self:Track(itemId, creatureId)
  local item = Item:CreateFromItemID(itemId)
  item:ContinueOnItemLoad(function()
    itemData.name = item:GetItemName()
    itemData.link = item:GetItemLink()
    itemData.icon = item:GetItemIcon()
    itemData.quality = item:GetItemQuality()
    itemData.class = select(6, GetItemInfoInstant(itemId))
    self.tree:Select("encounter+" .. creatureId)
    self:Refresh()
  end)
  return creatureData, itemData
end

function lootTracker:TrackLoot()
  local guid = GetLootSourceInfo(1)
  VGT.LogTrace("Tracking loot for %s", guid)
  local instanceId = select(4, strsplit("-", guid or ""))
  instanceId = tonumber(instanceId)

  if (instanceId and (self.trackedInstances[instanceId] or self.profile.trackAllInstances)) then
    for _, v in ipairs(VGT_MasterLootData) do
      if v.id == guid then
        return
      end
    end

    local anyAdded

    for i = 1, GetNumLootItems() do
      if GetLootSlotType(i) == 1 then -- 1 = Item
        local link = GetLootSlotLink(i)
        if link then
          local itemId, _, _, _, _, classId = GetItemInfoInstant(link)
          if classId ~= 10 then -- 10 = Money (currency)
            local icon, name, _, currencyId, quality = GetLootSlotInfo(i)
            if not currencyId and (quality == 4 or (self.profile.trackUncommon and quality > 1)) then
              VGT.LogTrace("Tracking $s", link)
              local creatureData, itemData = self:Track(itemId, guid)
              itemData.name = name
              itemData.link = link
              itemData.icon = icon
              itemData.quality = quality
              itemData.class = classId
              anyAdded = true
            end
          end
        end
      end
    end

    if anyAdded then
      self:Refresh()
    end
  end
end

function lootTracker:Track(itemId, creatureId)
  creatureId = creatureId or "Unknown-0-0-0-0-0-0-0"
  local creatureData, newCreature

  for i, v in ipairs(VGT_MasterLootData) do
    if v.id == creatureId then
      creatureData = v
      break
    end
  end

  if not creatureData then
    creatureData = {
      id = creatureId,
      name = VGT:UnitNameFromGuid(creatureId),
      items = {},
      characters = VGT:GetCharacters()
    }
    newCreature = true
  end

  local nextItemIndex = 1

  for i, v in ipairs(creatureData.items) do
    if v.id == itemId then
      nextItemIndex = nextItemIndex + 1
    end
  end

  local itemData = {
    id = itemId,
    index = nextItemIndex
  }

  if newCreature then
    tinsert(VGT_MasterLootData, creatureData)
  end
  tinsert(creatureData.items, itemData)

  self:IncrementStandings(itemId, creatureData.characters)

  local preemptiveResponses = self:GetOrCreatePreemtiveResponse(itemId)

  for _, character in ipairs(creatureData.characters) do
    if not VGT:Equippable(itemId, select(2, VGT:CharacterClassInfo(character))) then
      preemptiveResponses[character.Name] = false
    end
  end

  VGT_MasterLootData.expiration = (GetTime() + 21600)

  self:Refresh()

  VGT:SendGroupAddonCommand(VGT.Commands.ITEM_TRACKED, itemData.id, creatureData.id)

  return creatureData, itemData
end

function lootTracker:LimitedRoll(creatureId, itemId, itemIndex, whitelist)
  local creatureData, itemData = self:ReadData(creatureId, itemId, itemIndex)

  if (creatureData and itemData) then
    self.rollCreature = creatureId
    self.rollItem = itemId
    self.rollIndex = itemIndex
    self.rollWhitelist = whitelist

    local text = "Roll on " .. itemData.link .. " for "
    local addComma = false
    local preemptiveResponses = self:GetOrCreatePreemtiveResponse(itemData.id)
    for _, name in ipairs(whitelist) do
      if preemptiveResponses[name] == false then
        local ended = self:RecordPassResponse(name)
        if ended then
          return
        end
      else
        if addComma then
          text = text .. ", "
        end
        addComma = true
        text = text .. name
        if UnitInRaid(name) then
          VGT:SendPlayerAddonCommand(name, VGT.Commands.START_ROLL, itemData.id)
        end
      end
    end

    self:Refresh()
    self:SendGroupMessage(text)
    self:SendGroupMessage("/roll or type \"pass\" in chat", true)
  end
end

function lootTracker:OpenRoll(creatureId, itemId, itemIndex)
  local creatureData, itemData = self:ReadData(creatureId, itemId, itemIndex)

  if (creatureData and itemData) then
    self.rollCreature = creatureId
    self.rollItem = itemId
    self.rollIndex = itemIndex
    self.rollWhitelist = nil

    local preemptiveResponses = self:GetOrCreatePreemtiveResponse(itemData.id)
    for _, character in ipairs(creatureData.characters) do
      if preemptiveResponses[character.Name] == false then
        local ended = self:RecordPassResponse(character.Name)
        if ended then
          return
        end
      end
    end

    self:Refresh()
    self:SendGroupMessage("Open Roll on " .. itemData.link)
    self:SendGroupMessage("/roll or type \"pass\" in chat", true)
    VGT:SendGroupAddonCommand(VGT.Commands.START_ROLL, itemId)
  end
end

function lootTracker:CountdownRoll()
  local t = 5
  local function tick()
    if not self.rollItem then
      return -- stop if rolls were manually ended during the countdown
    end
    if t > 0 then
      self:SendGroupMessage(t)
      C_Timer.After(1, tick)
    else
      self:EndRoll()
    end
    t = t - 1
  end
  C_Timer.After(1, tick)
end

function lootTracker:EndRoll()
  local creatureData, itemData = self:GetRollData()

  if not itemData then
    return
  end

  local hasRoll

  for _, response in pairs(self.responses) do
    if response.roll and not response.pass then
      hasRoll = true
      break
    end
  end

  if hasRoll then
    local topRoll = 0

    for _, response in pairs(self.responses) do
      if not response.pass and response.roll and response.roll > topRoll then
        topRoll = response.roll
      end
    end

    local winners = {}

    for _, response in pairs(self.responses) do
      if response.roll == topRoll then
        tinsert(winners, response.name)
      end
    end

    if #winners == 1 then
      itemData.winner = winners[1]
      itemData.winningPrio = self:TakePrioFromStandings(itemData.id, itemData.winner)
      itemData.traded = UnitIsUnit(itemData.winner, "player")
      VGT:SendPlayerAddonCommand(itemData.winner, VGT.Commands.ASSIGN_ITEM, itemData.id)
      local msg = itemData.link .. " won by " .. itemData.winner .. " (" .. topRoll
      if itemData.winningPrio then
        msg = msg .. " rolled, " .. itemData.winningPrio .. " prio)"
      else
        msg = msg .. " rolled)"
      end

      self:SendGroupMessage(msg)
    else
      self.responses = {}
      self.rollWhitelist = winners

      local msg = "Reroll: "

      for i, v in ipairs(winners) do
        if i > 1 then
          msg = msg .. ", "
        end
        msg = msg .. v
      end

      self:SendGroupMessage(msg)
      self:Refresh()
      return
    end
  else
    self:SendGroupMessage(itemData.link .. " passed by all.")
  end

  self.rollCreature = nil
  self.rollItem = nil
  self.rollIndex = nil
  self.responses = {}
  self.rollWhitelist = nil
  self:Refresh()
  VGT:SendGroupAddonCommand(VGT.Commands.CANCEL_ROLL)
end

function lootTracker:RemindRoll()
  local creatureData, itemData = self:GetRollData()

  if itemData then
    local msg = "Rolling on " .. itemData.link .. "."

    if #self.responses > 0 then
      local topRoll = 0

      for _, response in pairs(self.responses) do
        if not response.pass and response.roll and response.roll > topRoll then
          topRoll = response.roll
        end
      end

      local winners = {}

      for _, response in pairs(self.responses) do
        if response.roll == topRoll then
          tinsert(winners, response.name)
        end
      end

      if #winners == 1 then
        msg = msg .. " Current Winner: " .. winners[1] .. " (" .. topRoll .. " rolled)"
      else
        msg = msg .. " Current Winners: "
        for i, v in ipairs(winners) do
          if i > 1 then
            msg = msg .. ", "
          end
          msg = msg .. v
        end
        msg = msg .. " (" .. topRoll .. " rolled)"
      end
    end
    self:SendGroupMessage(msg, true)

    msg = "Missing rolls from: "

    local needsComma

    if self.rollWhitelist then
      for _, name in ipairs(self.rollWhitelist) do
        if not self.responses[name] then
          if needsComma then
            msg = msg .. ", "
          end
          msg = msg .. name
          needsComma = true
        end
      end
    else
      for _, character in ipairs(creatureData.characters) do
        if not self.responses[character.Name] then
          if needsComma then
            msg = msg .. ", "
          end
          msg = msg .. character.Name
          needsComma = true
        end
      end
    end

    self:SendGroupMessage(msg, true)
    self:SendGroupMessage("/roll or type \"pass\" in chat.", true)
  end
end

function lootTracker:CancelRoll()
  local creatureData, itemData = self:GetRollData()

  if (creatureData and itemData) then
    self.rollCreature = nil
    self.rollItem = nil
    self.rollIndex = nil
    self.responses = {}
    self.rollWhitelist = nil
    self:Refresh()
    VGT:SendGroupAddonCommand(VGT.Commands.CANCEL_ROLL)
    self:SendGroupMessage("Roll for " .. itemData.link .. " cancelled.")
  end
end

function lootTracker:AddDummyData()
  self:TrackUnknown(39272)
  self:TrackUnknown(39270)
  self:TrackUnknown(39276)
  self:TrackUnknown(39280)
end

function lootTracker:Whitelisted(name)
  if not self.rollWhitelist then
    return true
  end

  for _, name2 in ipairs(self.rollWhitelist) do
    if name == name2 then
      return true
    end
  end
end

function lootTracker:GetOrCreateResponse(name)
  if self:Whitelisted(name) then
    local response = self.responses[name]
    if not response then
      response = {
        name = name
      }
      self.responses[name] = response
    end
    return response
  end
end

function lootTracker:TryEndRoll()
  if self.profile.autoEndRoll then
    local creatureData, itemData = self:GetRollData()

    if creatureData and itemData then
      if self.rollWhitelist then
        for _, name in ipairs(self.rollWhitelist) do
          if not self.responses[name] then
            return
          end
        end
      else
        for _, character in ipairs(creatureData.characters) do
          if not self.responses[character.Name] then
            return
          end
        end
      end
      self:EndRoll()
      return true
    end
  end
end

function lootTracker:RecordPassResponse(name)
  local response = self:GetOrCreateResponse(name)
  if response then
    VGT.LogTrace("Recorded %s's pass message", name)
    response.pass = true
    local ended = self:TryEndRoll()
    self:Refresh()
    return ended
  end
end

function lootTracker:BagSlotActive(bag, slot)
  local v = bag .. "," .. slot
  for i = 1, 6 do
    if self.activeSlots[i] == v then
      return true
    end
  end
end

function lootTracker:FindEligibleItemLoc(itemId)
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      if not self:BagSlotActive(bag, slot) then
        local containerItemId = GetContainerItemID(bag, slot)
        if containerItemId == itemId then
          VGTScanningTooltip:ClearLines()
          VGTScanningTooltip:SetBagItem(bag, slot)
          local isSoulbound = false
          local hasTradableText = false
          for i = 1, VGTScanningTooltip:NumLines() do
            local line = _G["VGTScanningTooltipTextLeft" .. i]
            local text = line and line:GetText() or ""
            if text == ITEM_SOULBOUND then
              isSoulbound = true
            elseif string.find(text, "You may trade this item with players") then
              hasTradableText = true
            end
          end
          if not isSoulbound or hasTradableText then
            return bag, slot
          end
        end
      end
    end
  end
end

function lootTracker:ClearTable(t)
  for i = 1, 6 do
    t[i] = nil
  end
end

function lootTracker:HandleChatCommand(_, channel, text, playerName)
  if self.rollItem then
    if (text == "pass" or text == "Pass" or text == "PASS") then
      VGT.LogTrace("Received pass message from %s", playerName)
      self:RecordPassResponse(playerName)
    end
  end
end

function lootTracker:CHAT_MSG_SYSTEM(_, text)
  if self.rollItem then
    local name, roll, minRoll, maxRoll = text:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")
    if name and roll and minRoll and maxRoll then
      VGT.LogTrace("Found roll message from %s of %s (%s-%s)", name, roll, minRoll, maxRoll)
      roll = tonumber(roll)
      minRoll = tonumber(minRoll)
      maxRoll = tonumber(maxRoll)
      if minRoll == 1 and maxRoll == 100 then
        VGT.LogTrace("%s's roll message is valid", name)
        local response = self:GetOrCreateResponse(name)
        if response then
          VGT.LogTrace("Recorded %s's roll message", name)
          local preemptiveResponses = self:GetOrCreatePreemtiveResponse(self.rollItem)
          preemptiveResponses[name] = nil
          response.pass = false
          response.roll = response.roll or roll
          self:TryEndRoll()
          self:Refresh()
        end
      end
    end
  end
end

function lootTracker:TRADE_SHOW()
  if self.profile.autoTrade then
    self:ClearTable(self.currentTrades)
    self:ClearTable(self.activeSlots)
    local name = UnitName("npc")
    local targetSlot = 1
    VGT.LogTrace("Checking autotrades for %s", name)
    for _, creatureData in ipairs(VGT_MasterLootData) do
      for _, itemData in ipairs(creatureData.items) do
        if targetSlot > 6 then
          VGT.LogTrace("Reached autotrade limit")
          return
        end
        if itemData.winner and name == itemData.winner and not itemData.traded then
          VGT.LogTrace("%s needs to be traded %s", name, itemData.link)
          local bagId, slotId = self:FindEligibleItemLoc(itemData.id)
          if bagId ~= nil and slotId ~= nil then
            local thisSlot = targetSlot
            C_Timer.After(thisSlot / 10, function()
              VGT.LogTrace("Assigning %s (bag %s, slot %s) to trade slot %s", itemData.link, bagId, slotId, targetSlot)
              ClearCursor()
              PickupContainerItem(bagId, slotId)
              ClickTradeButton(thisSlot)
              self.currentTrades[thisSlot] = itemData
              self.activeSlots[thisSlot] = bagId .. "," .. slotId
            end)
            targetSlot = targetSlot + 1
          end
        end
      end
    end
    VGT.LogTrace("Autotrade complete")
  end
end

function lootTracker:TRADE_PLAYER_ITEM_CHANGED(_, slot)
  if self.profile.autoTrade then
    local data = self.currentTrades[slot]
    if data then
      VGT.LogTrace("Trade slot %s changed. Clearing autotrade info.", slot)
      self.currentTrades[slot] = nil
    end
    self.activeSlots[slot] = nil
  end
end

function lootTracker:UI_INFO_MESSAGE(_, arg1, arg2)
  if arg2 == ERR_TRADE_COMPLETE and self.profile.autoTrade then
    for i = 1, 6 do
      local itemData = self.currentTrades[i]
      self.currentTrades[i] = nil
      self.activeSlots[i] = nil
      if itemData then
        VGT.LogTrace("Auto trade in slot %s for %s complete.", i, itemData.link)
        itemData.traded = true
      end
    end
    self:Refresh()
  end
end

function lootTracker:NOTIFY_INTERESTED(_, sender, id)
  local lootmethod, masterlooterPartyID = GetLootMethod()
  if lootmethod == "master" and masterlooterPartyID == 0 then
    VGT.LogTrace("Received interested message from %s for %s", sender, id)
    local itemResponses = self:GetOrCreatePreemtiveResponse(id)
    itemResponses[sender] = true
    self:Refresh()
  end
end

function lootTracker:NOTIFY_PASSING(_, sender, id)
  local lootmethod, masterlooterPartyID = GetLootMethod()
  if lootmethod == "master" and masterlooterPartyID == 0 then
    VGT.LogTrace("Received preemptive pass message from %s for %s", sender, id)
    local itemResponses = self:GetOrCreatePreemtiveResponse(id)
    itemResponses[sender] = false
    self:Refresh()
  end
end

function lootTracker:ROLL_PASS(_, sender, id)
  VGT.LogTrace("Received pass message from %s for %s", sender, id)
  if self.rollItem and self.rollItem == tonumber(id) then
    VGT.LogTrace("%s's pass message is valid for %s", sender, id)
    self:RecordPassResponse(sender)
  end
end

function lootTracker:OnEnable()
  self:RegisterEvent("CHAT_MSG_SYSTEM")
  self:RegisterEvent("CHAT_MSG_RAID", "HandleChatCommand")
  self:RegisterEvent("CHAT_MSG_RAID_LEADER", "HandleChatCommand")
  self:RegisterEvent("CHAT_MSG_PARTY", "HandleChatCommand")
  self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "HandleChatCommand")
  self:RegisterEvent("CHAT_MSG_WHISPER", "HandleChatCommand")
  self:RegisterEvent("TRADE_SHOW")
  self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
  self:RegisterEvent("UI_INFO_MESSAGE")
  self:RegisterMessage("VGT_MASTER_LOOT_READY", "TrackLoot")
  self:RegisterCommand(VGT.Commands.NOTIFY_INTERESTED)
  self:RegisterCommand(VGT.Commands.NOTIFY_PASSING)
  self:RegisterCommand(VGT.Commands.ROLL_PASS)
end
