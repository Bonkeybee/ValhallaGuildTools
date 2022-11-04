local AceGUI = VGT.Gui
local LSM = LibStub("LibSharedMedia-3.0")

VGT:RegisterCoreMessageHandler(function(message, sender)
    if not VGT.OPTIONS.ROLL.enabled then
        return
    end

    local cmd, id = strsplit("\001", message)
    id = tonumber(id)
    
    if cmd == "SR" and id then
        VGT:ShowRollWindow(id, true)
    elseif cmd == "CR" and VGT.RollWindow then
        VGT.RollWindow:Hide()
    end
end)

function VGT:ShowRollWindow(itemId, auto)
    if auto and self.OPTIONS.ROLL.sound then
        local sound = LSM:Fetch("sound", self.OPTIONS.ROLL.sound, true)
        if sound then
            PlaySoundFile(sound, "Master")
        end
    end

    if not self.RollWindow then
        self:BuildRollWindow()
    end

    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
        VGT.RollWindow.Item = item
        VGT.RollWindow.Title:SetText(item:GetItemLink())
        VGT.RollWindow.Picture.Texture:SetTexture(item:GetItemIcon())
        VGT.RollWindow:Show()
    end)
end

function VGT:BuildRollWindow()
    self.RollWindow = CreateFrame("Frame", "VgtRollFrame", UIParent, "BackdropTemplate")
    self.RollWindow:SetFrameStrata("DIALOG")
    self.RollWindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
    })
    self.RollWindow:SetPoint(
        VGT.OPTIONS.ROLL.Point,
        UIParent,
        VGT.OPTIONS.ROLL.Point,
        VGT.OPTIONS.ROLL.X,
        VGT.OPTIONS.ROLL.Y
    )
    self.RollWindow:SetSize(400, 24)
    self.RollWindow:SetClampedToScreen(true)
    self.RollWindow:EnableMouse(true)
    self.RollWindow:SetToplevel(true)
    self.RollWindow:SetMovable(true)
    self.RollWindow:RegisterForDrag("LeftButton")
    self.RollWindow:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.RollWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        VGT.OPTIONS.ROLL.X = x
        VGT.OPTIONS.ROLL.Y = y
        VGT.OPTIONS.ROLL.Point = point
    end)

    local title = self.RollWindow:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    title:SetPoint("TOPLEFT", self.RollWindow, "TOPLEFT")
    --title:SetPoint("BOTTOMRIGHT", self.RollWindow, "BOTTOMRIGHT")
    title:SetTextColor(1, 1, 1, 1)
    title:SetText(" ")
    title:SetFont(GameFontHighlight:GetFont(), 16)
    title:Show()
    self.RollWindow.Title = title

    local pictureFrame = CreateFrame("Frame", nil, self.RollWindow)
    pictureFrame:SetSize(24, 24)
    pictureFrame:SetPoint("RIGHT", self.RollWindow, "LEFT")
    pictureFrame:Show()
    pictureFrame:EnableMouse(true)
    pictureFrame:RegisterForDrag("LeftButton")
    pictureFrame:SetScript("OnDragStart", function()
        VGT.RollWindow:StartMoving()
    end)
    pictureFrame:SetScript("OnDragStop", function()
        VGT.RollWindow:StopMovingOrSizing()
        local point, _, _, x, y = VGT.RollWindow:GetPoint(1)
        VGT.OPTIONS.ROLL.X = x
        VGT.OPTIONS.ROLL.Y = y
        VGT.OPTIONS.ROLL.Point = point
    end)
    pictureFrame:SetScript("OnEnter", function(self)
        if VGT.RollWindow.Item then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetHyperlink(VGT.RollWindow.Item:GetItemLink())
            GameTooltip:Show()
        end
    end)
    pictureFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    pictureFrame:SetScript("OnMouseUp", function()
        if VGT.RollWindow.Item and IsControlKeyDown() then
            DressUpItemLink(VGT.RollWindow.Item:GetItemLink())
        end
    end)
    local pictureTexture = pictureFrame:CreateTexture(nil, "BACKGROUND")
    pictureTexture:SetAllPoints()
    pictureFrame.Texture = pictureTexture
    self.RollWindow.Picture = pictureFrame

    local rollButton = CreateFrame("Button", nil, self.RollWindow)
    local rollTexture = rollButton:CreateTexture(nil, "BACKGROUND")
    rollButton.texture = rollTexture
    rollTexture:SetAllPoints()
    rollTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up.blp")
    rollButton:SetSize(24, 24)
    rollButton:SetText("Roll")
    rollButton:Show()
    rollButton:SetScript("OnClick", function()
        RandomRoll(1, 100)
        VGT.RollWindow:Hide()
    end)
    rollButton:SetScript("OnMouseDown", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight.blp")
    end)
    rollButton:SetScript("OnMouseUp", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up.blp")
    end)
    rollButton:SetScript("OnEnter", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Down.blp")
    end)
    rollButton:SetScript("OnLeave", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up.blp")
    end)

    local passButton = CreateFrame("Button", nil, self.RollWindow)
    local passTexture = passButton:CreateTexture(nil, "BACKGROUND")
    local passHighlight = passButton:CreateTexture(nil, "HIGHLIGHT")
    passButton.texture = passTexture
    passHighlight:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight.blp")
    passHighlight:SetBlendMode("ADD")
    passHighlight:SetAllPoints()
    passTexture:SetAllPoints()
    passTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up.blp")
    passTexture:SetBlendMode("ADD")
    passButton:SetSize(24, 24)
    passButton:Show()
    passButton:SetScript("OnClick", function()
        local channel
        if UnitInRaid("player") then
            channel = "RAID"
        elseif UnitInParty("player") then
            channel = "PARTY"
        end

        if channel then
            VGT:SendCoreMessage("RP\001" .. VGT.RollWindow.Item:GetItemID(), "RAID")
        end
        VGT.RollWindow:Hide()
    end)
    passButton:SetScript("OnMouseDown", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down.blp")
    end)
    passButton:SetScript("OnMouseUp", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up.blp")
    end)
    passButton:SetScript("OnEnter", function(self)
        --self.texture:SetTexture("")
    end)
    passButton:SetScript("OnLeave", function(self)
        self.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up.blp")
    end)
    
    title:SetPoint("BOTTOMRIGHT", rollButton, "BOTTOMLEFT", 1, 2)
    rollButton:SetPoint("BOTTOMRIGHT", passButton, "BOTTOMLEFT", 1, -2)
    passButton:SetPoint("BOTTOMRIGHT", self.RollWindow, "BOTTOMRIGHT")
end