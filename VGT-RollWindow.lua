local roller = VGT:NewModule("roller")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

function roller:Show(itemId, auto)
    if not self.enabledState then
        VGT.LogWarning("Roll Window module is disabled.")
        return
    end
    if auto then
        if not VGT:Equippable(itemId) then
            return
        end

        if not self.profile.showPasses then
            local dropTracker = VGT:GetModule("dropTracker")
            if dropTracker.enabledState then
                dropTracker:ResetItems()
                local item = dropTracker:GetForItem(itemId)
                if item and item.passed then
                    return
                end
            end
        end
    
        if self.profile.sound then
            local sound = LSM:Fetch("sound", self.profile.sound, true)
            if sound then
                PlaySoundFile(sound, "Master")
            end
        end
    end

    if not self.rollWindow then
        self:Build()
    end

    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
        self.rollWindow.item = item
        self.rollWindow.Title:SetText(item:GetItemLink())
        self.rollWindow.Picture.Texture:SetTexture(item:GetItemIcon())
        self.rollWindow:Show()
    end)
end

function roller:Build()
    self.rollWindow = CreateFrame("Frame", "VgtRollFrame", UIParent, "BackdropTemplate")
    self.rollWindow:SetFrameStrata("DIALOG")
    self.rollWindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
    })
    self:RefreshConfig() -- SetPoint
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
        roller.profile.x = x
        roller.profile.y = y
        roller.profile.point = point
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
        self.rollWindow:StartMoving()
    end)
    pictureFrame:SetScript("OnDragStop", function()
        self.rollWindow:StopMovingOrSizing()
        local point, _, _, x, y = roller.rollWindow:GetPoint(1)
        roller.profile.x = x
        roller.profile.y = y
        roller.profile.point = point
    end)
    pictureFrame:SetScript("OnEnter", function(self)
        if roller.rollWindow.item then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetHyperlink(roller.rollWindow.item:GetItemLink())
            GameTooltip:Show()
        end
    end)
    pictureFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    pictureFrame:SetScript("OnMouseUp", function()
        if self.rollWindow.item and IsControlKeyDown() then
            DressUpItemLink(self.rollWindow.item:GetItemLink())
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
        self.rollWindow:Hide()
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
        VGT:SendGroupAddonCommand(VGT.Commands.ROLL_PASS, self.rollWindow.item:GetItemID())
        self.rollWindow:Hide()
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

function roller:RefreshConfig()
    if self.rollWindow then
        self.rollWindow:SetPoint(self.profile.point, UIParent, self.profile.point, self.profile.x, self.profile.y)
    end
end

function roller:START_ROLL(_, sender, id)
    id = tonumber(id)
    if id then
        self:Show(id, true)
    end
end

function roller:CANCEL_ROLL(_, sender, id)
    if self.rollWindow then
        self.rollWindow:Hide()
    end
end

function roller:OnEnable()
    self:RegisterCommand(VGT.Commands.START_ROLL)
    self:RegisterCommand(VGT.Commands.CANCEL_ROLL)
end
