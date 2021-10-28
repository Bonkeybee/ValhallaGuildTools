VGT.LootListTracker = {_entries = {}}

function VGT.LootListTracker:Add(guid, name, link, count)
  local entry = self._entries[guid]

  if (not entry) then
    entry = {Name = name, Items = {}, Characters = VGT:GetCharacters()}

    function entry:Export()
      local items = {}

      for _, item in pairs(self.Items) do
        for _ = 1, item.Count do
          table.insert(items, item:GetItemID())
        end
      end

      VGT:ShowKillExport(items, self.Characters)
    end

    self._entries[guid] = entry
  end

  local item = entry.Items[link]

  if (not item) then
    item = Item:CreateFromItemLink(link)
    item.Count = count
    entry.Items[link] = item
  end

  if (item.Count < count) then
    item.Count = count
  end

  self:UpdateTracked()
end

function VGT.LootListTracker:Print()
  for _, value in pairs(self._entries) do
    local msg = value.Name .. ": "

    for _, item in pairs(value.Items) do
      msg = msg .. item:GetItemName() .. " (x" .. item.Count .. "), "
    end

    VGT.Log(VGT.LOG_LEVEL.SYSTEM, msg)
  end
end

local function CreateTrackingRow(parent, showBackdrop)
  local root = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
  root:SetHeight(48)

  if showBackdrop then
    root:SetBackdrop(
      {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
      }
    )
  end

  root.RemoveButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.RemoveButton:SetSize(24, 24)
  root.RemoveButton:SetPoint("TOPRIGHT", root, "TOPRIGHT")
  root.RemoveButton:SetText("X")
  root.RemoveButton:SetScript(
    "OnClick",
    function()
      if root.Guid then
        VGT.LootListTracker._entries[root.Guid] = nil
        VGT.LootListTracker:UpdateTracked()
      end
    end
  )

  root.ExportButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.ExportButton:SetSize(60, 24)
  root.ExportButton:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT")
  root.ExportButton:SetText("Export")
  root.ExportButton:SetScript(
    "OnClick",
    function()
      if root.Entry then
        root.Entry:Export()
      end
    end
  )

  root.ItemText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.ItemText:SetHeight(16)
  root.ItemText:SetPoint("TOPLEFT", root, "TOPLEFT")
  root.ItemText:SetPoint("TOPRIGHT", root.RemoveButton, "TOPLEFT")
  root.ItemText:SetText("Boss goes here")

  function root:Track(guid, entry)
    self.Guid = guid
    self.Entry = entry
    if entry then
      self.ItemText:SetText(entry.Name)
      self:Show()
    else
      self:Hide()
    end
  end

  return root
end

local function TableCount(table)
  local count = 0
  for _, _ in pairs(table) do
    count = count + 1
  end
  return count
end

function VGT.LootListTracker:UpdateTracked()
  if (not LootListTrackerFrame) then
    return
  end

  local count = TableCount(VGT.LootListTracker._entries)
  local existingRows = #LootListTrackerFrame.Tracked

  for i = count + 1, existingRows do
    LootListTrackerFrame.Tracked[i]:Hide()
  end

  for i = existingRows + 1, count do
    local row = CreateTrackingRow(LootListTrackerFrame.Tracked.ScrollChild, i % 2 == 0)
    LootListTrackerFrame.Tracked[i] = row
    if i == 1 then
      row:SetPoint("TOPLEFT", LootListTrackerFrame.Tracked.ScrollChild, "TOPLEFT")
      row:SetPoint("TOPRIGHT", LootListTrackerFrame.Tracked.ScrollChild, "TOPRIGHT")
    else
      row:SetPoint("TOPLEFT", LootListTrackerFrame.Tracked[i - 1], "BOTTOMLEFT")
      row:SetPoint("TOPRIGHT", LootListTrackerFrame.Tracked[i - 1], "BOTTOMRIGHT")
    end
  end

  local i = 1
  for guid, entry in pairs(VGT.LootListTracker._entries) do
    local row = LootListTrackerFrame.Tracked[i]
    row:Show()
    row:Track(guid, entry)
    i = i + 1
  end

  LootListTrackerFrame.Tracked.ScrollChild:SetHeight(48 * count)
end

function VGT.LootListTracker:Open()
  if not LootListTrackerFrame then
    LootListTrackerFrame =
      CreateFrame("Frame", "LootListTrackerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    LootListTrackerFrame:SetFrameStrata("DIALOG")
    LootListTrackerFrame:SetSize(VGT.OPTIONS.LOOTLIST.Width, VGT.OPTIONS.LOOTLIST.Height)
    LootListTrackerFrame:SetPoint(
      VGT.OPTIONS.LOOTLIST.Point,
      UIParent,
      VGT.OPTIONS.LOOTLIST.Point,
      VGT.OPTIONS.LOOTLIST.X,
      VGT.OPTIONS.LOOTLIST.Y
    )
    LootListTrackerFrame:SetClampedToScreen(true)
    LootListTrackerFrame:EnableMouse(true)
    LootListTrackerFrame:SetToplevel(true)
    LootListTrackerFrame:SetMovable(true)
    LootListTrackerFrame:SetResizable(true)
    LootListTrackerFrame:SetMinResize(300, 175)
    LootListTrackerFrame:RegisterForDrag("LeftButton")
    LootListTrackerFrame:SetBackdrop(
      {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
      }
    )
    LootListTrackerFrame:SetScript(
      "OnDragStart",
      function(self)
        self:StartMoving()
      end
    )
    LootListTrackerFrame:SetScript(
      "OnDragStop",
      function(s)
        s:StopMovingOrSizing()
        local point, _, _, x, y = s:GetPoint(1)
        VGT.OPTIONS.LOOTLIST.X = x
        VGT.OPTIONS.LOOTLIST.Y = y
        VGT.OPTIONS.LOOTLIST.Point = point
      end
    )
    LootListTrackerFrame:SetScript(
      "OnSizeChanged",
      function(self)
        if self.Tracked then
          self.Tracked.ScrollChild:SetWidth(self.Tracked.ScrollFrame:GetWidth())
        end
        VGT.OPTIONS.LOOTLIST.Width = self:GetWidth()
        VGT.OPTIONS.LOOTLIST.Height = self:GetHeight()
      end
    )

    local resizeButton = CreateFrame("Button", nil, LootListTrackerFrame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT")
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript(
      "OnMouseDown",
      function()
        LootListTrackerFrame:StartSizing("BOTTOMRIGHT")
        LootListTrackerFrame:SetUserPlaced(true)
      end
    )

    resizeButton:SetScript(
      "OnMouseUp",
      function()
        LootListTrackerFrame:StopMovingOrSizing()
      end
    )
    local padding = 4

    local closeButton = CreateFrame("Button", nil, LootListTrackerFrame, "UIPanelButtonTemplate")
    closeButton:SetText("X")
    closeButton:SetPoint("TOPRIGHT", LootListTrackerFrame, "TOPRIGHT", -padding, -padding)
    closeButton:SetScript(
      "OnClick",
      function()
        LootListTrackerFrame:Hide()
      end
    )

    local raidStartButton = CreateFrame("Button", nil, LootListTrackerFrame, "UIPanelButtonTemplate")
    raidStartButton:SetText("Raid Start")
    raidStartButton:SetSize(72, 24)
    raidStartButton:SetPoint("TOP", closeButton, "BOTTOM", 0, -padding)
    raidStartButton:SetPoint("RIGHT", closeButton, "RIGHT")
    raidStartButton:SetScript(
      "OnClick",
      function()
        VGT:ShowRaidStartExport()
      end
    )

    LootListTrackerFrame.Tracked =
      CreateFrame("Frame", nil, LootListTrackerFrame, BackdropTemplateMixin and "BackdropTemplate")
    LootListTrackerFrame.Tracked:SetPoint("RIGHT", raidStartButton, "LEFT", -padding, -padding)
    LootListTrackerFrame.Tracked:SetPoint("LEFT", padding, padding)
    LootListTrackerFrame.Tracked:SetPoint("TOP", -padding, -padding)
    LootListTrackerFrame.Tracked:SetPoint("BOTTOM", padding, padding)
    LootListTrackerFrame.Tracked:SetBackdrop(
      {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        tile = true,
        tileSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
      }
    )

    local trackedRoot = LootListTrackerFrame.Tracked
    local scrollFrame =
      CreateFrame("ScrollFrame", "LootListTrackerScrollFrame", trackedRoot, "UIPanelScrollFrameTemplate")
    local scrollChild = CreateFrame("Frame")
    trackedRoot.ScrollFrame = scrollFrame
    trackedRoot.ScrollChild = scrollChild
    trackedRoot:SetScript(
      "OnShow",
      function()
        VGT.LootListTracker:UpdateTracked()
      end
    )
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:SetPoint("TOPLEFT", 6, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    scrollChild:SetSize(scrollFrame:GetWidth(), 48)

    function LootListTrackerFrame:SetItem(itemLink, icon)
      self.Item = itemLink
      self.Dropper.Texture:SetTexture(icon)
      if icon then
        self.Dropper.Text:Hide()
      else
        self.Dropper.Text:Show()
      end
    end
  end

  LootListTrackerFrame:Show()
  VGT.LootListTracker:UpdateTracked()
end

function VGT.LootListTracker:Close()
  if (LootListTrackerFrame) then
    LootListTrackerFrame:Hide()
  end
end

function VGT.LootListTracker:Toggle()
  if LootListTrackerFrame and LootListTrackerFrame:IsShown() then
    self:Close()
  else
    self:Open()
  end
end
