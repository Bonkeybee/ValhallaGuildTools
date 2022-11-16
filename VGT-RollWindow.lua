local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

VGT:RegisterCommandHandler("SR", function(sender, id)
    id = tonumber(id)
    if id and VGT.OPTIONS.ROLL.enabled then
        VGT:ShowRollWindow(id, true)
    end
end)

VGT:RegisterCommandHandler("CR", function(sender)
    if VGT.rollWindow then
        VGT.rollWindow:Hide()
    end
end)

function VGT:ShowRollWindow(itemId, auto)
    if auto and self.OPTIONS.ROLL.sound then
        local sound = LSM:Fetch("sound", self.OPTIONS.ROLL.sound, true)
        if sound then
            PlaySoundFile(sound, "Master")
        end
    end

    if not self.rollWindow then
        self:BuildRollWindow()
    end

    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
        VGT.rollWindow.item = item
        VGT.rollWindow.Title:SetText(item:GetItemLink())
        VGT.rollWindow.Picture.Texture:SetTexture(item:GetItemIcon())
        VGT.rollWindow:Show()
    end)
end

function VGT:BuildRollWindow()
    self.rollWindow = CreateFrame("Frame", "VgtRollFrame", UIParent, "BackdropTemplate")
    self.rollWindow:SetFrameStrata("DIALOG")
    self.rollWindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
    })
    self.rollWindow:SetPoint(
        VGT.OPTIONS.ROLL.Point,
        UIParent,
        VGT.OPTIONS.ROLL.Point,
        VGT.OPTIONS.ROLL.X,
        VGT.OPTIONS.ROLL.Y
    )
    self.rollWindow:SetSize(400, 24)
    self.rollWindow:SetClampedToScreen(true)
    self.rollWindow:EnableMouse(true)
    self.rollWindow:SetToplevel(true)
    self.rollWindow:SetMovable(true)
    self.rollWindow:RegisterForDrag("LeftButton")
    self.rollWindow:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    self.rollWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        VGT.OPTIONS.ROLL.X = x
        VGT.OPTIONS.ROLL.Y = y
        VGT.OPTIONS.ROLL.Point = point
    end)

    local title = self.rollWindow:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    title:SetPoint("TOPLEFT", self.rollWindow, "TOPLEFT")
    --title:SetPoint("BOTTOMRIGHT", self.rollWindow, "BOTTOMRIGHT")
    title:SetTextColor(1, 1, 1, 1)
    title:SetText(" ")
    title:SetFont(GameFontHighlight:GetFont(), 16)
    title:Show()
    self.rollWindow.Title = title

    local pictureFrame = CreateFrame("Frame", nil, self.rollWindow)
    pictureFrame:SetSize(24, 24)
    pictureFrame:SetPoint("RIGHT", self.rollWindow, "LEFT")
    pictureFrame:Show()
    pictureFrame:EnableMouse(true)
    pictureFrame:RegisterForDrag("LeftButton")
    pictureFrame:SetScript("OnDragStart", function()
        VGT.rollWindow:StartMoving()
    end)
    pictureFrame:SetScript("OnDragStop", function()
        VGT.rollWindow:StopMovingOrSizing()
        local point, _, _, x, y = VGT.rollWindow:GetPoint(1)
        VGT.OPTIONS.ROLL.X = x
        VGT.OPTIONS.ROLL.Y = y
        VGT.OPTIONS.ROLL.Point = point
    end)
    pictureFrame:SetScript("OnEnter", function(self)
        if VGT.rollWindow.item then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetHyperlink(VGT.rollWindow.item:GetItemLink())
            GameTooltip:Show()
        end
    end)
    pictureFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    pictureFrame:SetScript("OnMouseUp", function()
        if VGT.rollWindow.item and IsControlKeyDown() then
            DressUpItemLink(VGT.rollWindow.item:GetItemLink())
        end
    end)
    local pictureTexture = pictureFrame:CreateTexture(nil, "BACKGROUND")
    pictureTexture:SetAllPoints()
    pictureFrame.Texture = pictureTexture
    self.rollWindow.Picture = pictureFrame

    local rollButton = CreateFrame("Button", nil, self.rollWindow)
    local rollTexture = rollButton:CreateTexture(nil, "BACKGROUND")
    rollButton.texture = rollTexture
    rollTexture:SetAllPoints()
    rollTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up.blp")
    rollButton:SetSize(24, 24)
    rollButton:SetText("Roll")
    rollButton:Show()
    rollButton:SetScript("OnClick", function()
        RandomRoll(1, 100)
        VGT.rollWindow:Hide()
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

    local passButton = CreateFrame("Button", nil, self.rollWindow)
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
        VGT:SendGroupAddonCommand("RP", VGT.rollWindow.item:GetItemID())
        VGT.rollWindow:Hide()
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
    passButton:SetPoint("BOTTOMRIGHT", self.rollWindow, "BOTTOMRIGHT")
end