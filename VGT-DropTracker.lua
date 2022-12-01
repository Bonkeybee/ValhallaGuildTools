local dropTracker = VGT:NewModule("dropTracker")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

function dropTracker:ResetItems(force)
  if force or (self.char.expiration and GetTime() > self.char.expiration) then
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
    if not item.won and not item.passed and not item.interested then
      return false
    end
  end
  return true
end

function dropTracker:Track(itemId)
  if not VGT:Equippable(itemId) then
    return
  end
  self:ResetItems()
  self.char.expiration = self.char.expiration or (GetTime() + 21600)
  local trackedItem = self:GetForItem(itemId)
  if not trackedItem then
    trackedItem = {
      id = itemId
    }
    tinsert(self.char.items, trackedItem)
    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
      trackedItem.name = item:GetItemName()
      trackedItem.link = item:GetItemLink()
      trackedItem.icon = item:GetItemIcon()
      self:Refresh()
    end)
    return true
  end
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
    item.won = won
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

function dropTracker:NotifyPassing(item)
  local previouslyResponded = item.passed or item.interested
  item.passed = true
  item.interested = nil
  VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_PASSING, item.id)
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
    local label = AceGUI:Create("Label")
    label:SetText("No items have dropped yet.")
    label:SetFullWidth(true)
    label:SetFont(GameFontHighlight:GetFont(), 16)
    self.scroll:AddChild(label)
    return
  end

  for _, i in ipairs(self.char.items) do
    local item = i
    local shouldShow = true
    if item.won then
      shouldShow = self.profile.showWon
    elseif item.interested then
      shouldShow = self.profile.showInterested
    elseif item.passed then
      shouldShow = self.profile.showPassed
    end
    if shouldShow then
      local group = AceGUI:Create("InlineGroup")
      group:SetFullWidth(true)
      group:SetLayout("Flow")
      self.scroll:AddChild(group)

      local text = item.link

      if item.won then
        text = text .. " - |cff00ff00Won|r"
      elseif item.passed then
        text = text .. " - |cffffff00Passing|r"
      elseif item.interested then
        text = text .. " - |cff00ff00Interested|r"
      end

      local label = AceGUI:Create("InteractiveLabel")
      label:SetFont(GameFontHighlight:GetFont(), 16)
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

      if not item.won then
        local interestedButton = AceGUI:Create("Button")
        interestedButton:SetText("Interested")
        interestedButton:SetHeight(24)
        interestedButton:SetWidth(100)
        interestedButton:SetCallback("OnClick", function()
          self:NotifyInterested(item)
        end)
        group:AddChild(interestedButton)

        local passButton = AceGUI:Create("Button")
        passButton:SetText("Pass")
        passButton:SetHeight(24)
        passButton:SetWidth(100)
        passButton:SetCallback("OnClick", function()
          self:NotifyPassing(item)
        end)
        group:AddChild(passButton)
      end
    end
  end

  local showPassedToggle = AceGUI:Create("CheckBox")
  showPassedToggle:SetLabel("Show Passed Items")
  showPassedToggle:SetValue(self.profile.showPassed and true or false)
  showPassedToggle:SetCallback("OnValueChanged", function()
    self.profile.showPassed = not self.profile.showPassed
    self:Refresh()
  end)
  self.scroll:AddChild(showPassedToggle)

  local showInterestedToggle = AceGUI:Create("CheckBox")
  showInterestedToggle:SetLabel("Show Interested Items")
  showInterestedToggle:SetValue(self.profile.showInterested and true or false)
  showInterestedToggle:SetCallback("OnValueChanged", function()
    self.profile.showInterested = not self.profile.showInterested
    self:Refresh()
  end)
  self.scroll:AddChild(showInterestedToggle)

  local showWonToggle = AceGUI:Create("CheckBox")
  showWonToggle:SetLabel("Show Won Items")
  showWonToggle:SetValue(self.profile.showWon and true or false)
  showWonToggle:SetCallback("OnValueChanged", function()
    self.profile.showWon = not self.profile.showWon
    self:Refresh()
  end)
  self.scroll:AddChild(showWonToggle)

  local resetButton = AceGUI:Create("Button")
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
  self.frame = AceGUI:Create("Window")
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
  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  self.frame:AddChild(scrollcontainer)

  self.scroll = AceGUI:Create("ScrollFrame")
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

function dropTracker:ITEM_TRACKED(_, sender, id)
  Item:CreateFromItemID(id):ContinueOnItemLoad(function()
    if self:Track(id) and self.profile.autoShow then
      self:Show()
    end
  end)
end

function dropTracker:OnEnable()
  self:RegisterCommand(VGT.Commands.ASSIGN_ITEM)
  self:RegisterCommand(VGT.Commands.UNASSIGN_ITEM)
  self:RegisterCommand(VGT.Commands.ITEM_TRACKED)
end
