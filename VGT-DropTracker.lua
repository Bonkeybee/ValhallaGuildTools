---@class DropTrackerModule : Module, { char: DropTrackerCharacterSettings, profile: DropTrackerProfileSettings }
local dropTracker = VGT:NewModule("dropTracker")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

function dropTracker:AutoPassing(itemId)
  local ap = self.char.autoPasses[itemId]
  return ap and ap.passed or false
end

function dropTracker:ResetItems(force)
  if force or not self.char.expiration or time() > self.char.expiration then
    self.char.expiration = nil
    self.char.items = {}
  end
end

function dropTracker:ClearAll()
  VGT:Confirm(function()
    self:ResetItems(true)
    self:Refresh()
  end)
end

function dropTracker:GetForItem(itemId)
  for _, item in ipairs(self.char.items) do
    if item.id == itemId then
      return item
    end
  end
end

function dropTracker:AllResponded()
  for _, item in ipairs(self.char.items) do
    if item.winCount == 0 and not item.passed and not item.interested then
      return false
    end
  end
  return true
end

---@param itemId integer
---@param itemIndex integer
---@param creatureId string
---@param hasStanding boolean
function dropTracker:Track(itemId, itemIndex, creatureId, hasStanding)
  self:ResetItems()
  self.char.expiration = self.char.expiration or (time() + 21600)
  local uniqueId = itemIndex .. creatureId
  local item = Item:CreateFromItemID(itemId)
  item:ContinueOnItemLoad(function()
    local existingItem = self:GetForItem(itemId)
    if existingItem then
      for _, id in ipairs(existingItem.uniqueIds) do
        if id == uniqueId then
          if self:AutoPassing(itemId) then
            VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_PASSING, itemId, true)
          end
          return
        end
      end
      tinsert(existingItem.uniqueIds, uniqueId)
      self:Refresh()
    else
      if not VGT:Equippable(itemId) then
        return
      end
      local autoPassing = self:AutoPassing(itemId)
      ---@class DropTrackerItem
      ---@field interested boolean?
      local dropTrackerItem = {
        id = itemId,
        winCount = 0,
        hasStanding = hasStanding,
        name = item:GetItemName(),
        link = item:GetItemLink(),
        ---@type string|number
        icon = item:GetItemIcon(),
        ---@type string[]
        uniqueIds = {uniqueId},
        passed = autoPassing
      }
      tinsert(self.char.items, dropTrackerItem)
      if self.profile.autoShow and not autoPassing then
        self:Show()
      else
        self:Refresh()
        if autoPassing then
          VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_PASSING, itemId, true)
        end
      end
    end
  end)
end

function dropTracker:SetWon(itemId, won)
  if won and self.profile.wonSound then
    local sound = LSM:Fetch("sound", self.profile.wonSound, true)
    if sound then
      PlaySoundFile(sound, "Master")
    end
  end
  local item = self:GetForItem(itemId)
  if item then
    item.winCount = item.winCount + (won and 1 or -1)
    self:Refresh()
  end
end

function dropTracker:NotifyInterested(item)
  local previouslyResponded = item.passed or item.interested
  item.passed = nil
  item.interested = true
  VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_INTERESTED, item.id)
  if self.profile.autoClose and not previouslyResponded and self:AllResponded() then
    self.frame:Hide()
  else
    self:Refresh()
  end
end

function dropTracker:NotifyPassing(item, hardPass)
  local previouslyResponded = item.passed or item.interested
  item.passed = true
  item.interested = nil
  VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_PASSING, item.id, hardPass)
  if self.profile.autoClose and not previouslyResponded and self:AllResponded() then
    self.frame:Hide()
  else
    self:Refresh()
  end
end

function dropTracker:Refresh()
  if not self.frame then
    return
  end
  self:ResetItems()
  local currentScroll = self.scroll.localstatus.scrollvalue
  self.scroll:ReleaseChildren()
  if not next(self.char.items) then
    local label = AceGUI:Create("Label") --[[@as AceGUILabel]]
    label:SetText("No items have dropped yet.")
    label:SetFullWidth(true)
    label:SetFont(GameFontHighlight:GetFont(), 16, "")
    self.scroll:AddChild(label)
    return
  end

  for _, i in ipairs(self.char.items) do
    local item = i
    if not item.winCount then
      item.winCount = 0
    end
    if not item.uniqueIds then
      item.uniqueIds = {""}
    end
    local shouldShow = true
    if item.winCount > 0 then
      shouldShow = self.profile.showWon
    elseif item.interested then
      shouldShow = self.profile.showInterested
    elseif item.passed then
      shouldShow = self.profile.showPassed
    end
    if shouldShow then
      local group = AceGUI:Create("InlineGroup") --[[@as AceGUIInlineGroup]]
      group:SetFullWidth(true)
      group:SetLayout("Flow")
      self.scroll:AddChild(group)

      local text = item.link

      if item.hasStanding then
        text = text .. " (On Your List)"
      end

      if item.winCount > 0 then
        if #item.uniqueIds == 1 then
          text = text .. " - |cff00ff00Won|r"
        else
          text = text .. " - |cff00ff00Won " .. item.winCount .. " of " .. #item.uniqueIds .. "|r"
        end
      elseif item.passed then
        text = text .. " - |cffffff00Passing|r"
      elseif item.interested then
        text = text .. " - |cff00ff00Interested|r"
      end

      local label = AceGUI:Create("InteractiveLabel") --[[@as AceGUIInteractiveLabel]]
      label:SetFont(GameFontHighlight:GetFont(), 16, "")
      label:SetImage(item.icon)
      label:SetImageSize(24, 24)
      label:SetHeight(24)
      label:SetFullWidth(true)
      label:SetText(text)
      label:SetCallback("OnEnter", function()
        GameTooltip:SetOwner(label.frame, "ANCHOR_CURSOR_RIGHT")
        GameTooltip:SetHyperlink(item.link)
        GameTooltip:Show()
      end)
      label:SetCallback("OnLeave", function()
        GameTooltip:Hide()
      end)
      group:AddChild(label)

      if item.winCount < #item.uniqueIds then
        local interestedButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
        interestedButton:SetText("Interested")
        interestedButton:SetHeight(24)
        interestedButton:SetWidth(100)
        interestedButton:SetCallback("OnClick", function()
          self:NotifyInterested(item)
        end)
        group:AddChild(interestedButton)

        local passButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
        passButton:SetText("Pass")
        passButton:SetHeight(24)
        passButton:SetWidth(120)
        passButton:SetCallback("OnClick", function()
          self:NotifyPassing(item)
        end)
        group:AddChild(passButton)

        local autoPassButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
        autoPassButton:SetText("Always Pass")
        autoPassButton:SetHeight(24)
        autoPassButton:SetWidth(120)
        autoPassButton:SetCallback("OnClick", function()
          VGT:Confirm(
            function()
              self:NotifyPassing(item, true)
              ---@class DropTrackerPass
              self.char.autoPasses[item.id] = {
                passed = true,
                name = item.name,
                link = item.link
              }
            end,
            "Are you sure you want to auto-pass " .. item.link .. "? You will not be prompted to roll on this item again!"
          )
        end)
        group:AddChild(autoPassButton)
      end
    end
  end

  local showPassedToggle = AceGUI:Create("CheckBox") --[[@as AceGUICheckBox]]
  showPassedToggle:SetLabel("Show Passed Items")
  showPassedToggle:SetValue(self.profile.showPassed and true or false)
  showPassedToggle:SetCallback("OnValueChanged", function()
    self.profile.showPassed = not self.profile.showPassed
    self:Refresh()
  end)
  self.scroll:AddChild(showPassedToggle)

  local showInterestedToggle = AceGUI:Create("CheckBox") --[[@as AceGUICheckBox]]
  showInterestedToggle:SetLabel("Show Interested Items")
  showInterestedToggle:SetValue(self.profile.showInterested and true or false)
  showInterestedToggle:SetCallback("OnValueChanged", function()
    self.profile.showInterested = not self.profile.showInterested
    self:Refresh()
  end)
  self.scroll:AddChild(showInterestedToggle)

  local showWonToggle = AceGUI:Create("CheckBox") --[[@as AceGUICheckBox]]
  showWonToggle:SetLabel("Show Won Items")
  showWonToggle:SetValue(self.profile.showWon and true or false)
  showWonToggle:SetCallback("OnValueChanged", function()
    self.profile.showWon = not self.profile.showWon
    self:Refresh()
  end)
  self.scroll:AddChild(showWonToggle)

  local resetButton = AceGUI:Create("Button") --[[@as AceGUIButton]]
  resetButton:SetFullWidth(true)
  resetButton:SetText("Clear All")
  resetButton:SetCallback("OnClick", function()
    self:ClearAll()
  end)
  self.scroll:AddChild(resetButton)
  self.scroll:SetScroll(currentScroll)
  self.scroll:FixScroll()
end

function dropTracker:Toggle()
  if not self.enabledState then
    VGT.LogWarning("Drop tracker module is disabled.")
    return
  end
  if not self.frame then
    self:BuildWindow()
  elseif self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
    self:Refresh()
  end
end

function dropTracker:Show()
  if self.frame then
    if not self.frame:IsShown() then
      self.frame:Show()
    end
    self:Refresh()
  else
    self:BuildWindow()
  end
end

function dropTracker:BuildWindow()
  self.frame = AceGUI:Create("Window") --[[@as AceGUIWindow]]
  self.frame:SetTitle("Valhalla Drop Tracker")
  self.frame:SetLayout("Fill")
  self:RefreshConfig() -- SetPoint, SetWidth, SetHeight
  self.frame:SetCallback("OnClose", function()
    local point, _, _, x, y = self.frame.frame:GetPoint(1)
    self.profile.x = x
    self.profile.y = y
    self.profile.point = point
    self.profile.width = self.frame.frame:GetWidth()
    self.profile.height = self.frame.frame:GetHeight()
  end)
  local scrollcontainer = AceGUI:Create("SimpleGroup") --[[@as AceGUISimpleGroup]]
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  self.frame:AddChild(scrollcontainer)

  self.scroll = AceGUI:Create("ScrollFrame") --[[@as AceGUIScrollFrame]]
  self.scroll:SetLayout("Flow")
  scrollcontainer:AddChild(self.scroll)
  self:Refresh()
end

function dropTracker:RefreshConfig()
  if not self.frame then
    return
  end

  self.frame:SetHeight(self.profile.height < 240 and 240 or self.profile.height)
  self.frame:SetWidth(self.profile.width < 400 and 400 or self.profile.width)
  self.frame:SetPoint(self.profile.point, UIParent, self.profile.point, self.profile.x, self.profile.y)
end

function dropTracker:ASSIGN_ITEM(_, sender, id, disenchant)
  if not disenchant then
    self:SetWon(id, true)
  end
end

function dropTracker:UNASSIGN_ITEM(_, sender, id)
  self:SetWon(id, false)
end

function dropTracker:ITEM_TRACKED(_, sender, id, index, creature, charactersWithStandings)
  local hasStanding
  for _, name in ipairs(charactersWithStandings) do
    if UnitIsUnit(name, "player") then
      hasStanding = true
      break
    end
  end
  VGT.LogTrace("Track message received from %s for %s", sender, id)
  self:Track(id, index, creature, hasStanding)
end

function dropTracker:OnEnable()
  self:RegisterCommand(VGT.Commands.ASSIGN_ITEM)
  self:RegisterCommand(VGT.Commands.UNASSIGN_ITEM)
  self:RegisterCommand(VGT.Commands.ITEM_TRACKED)
end
