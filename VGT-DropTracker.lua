local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

VGT.dropTracker = {}

function VGT.dropTracker:ResetItems(force)
    if force or (VGT.db.char.dropTracker.expiration and GetTime() > VGT.db.char.dropTracker.expiration) then
        VGT.db.char.dropTracker.expiration = nil
        VGT.db.char.dropTracker.items = {}
    end
end

function VGT.dropTracker:Track(itemId)
    if not VGT:Equippable(itemId) then
        return
    end
    self:ResetItems()
    VGT.db.char.dropTracker.expiration = VGT.db.char.dropTracker.expiration or (GetTime() + 21600)
    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
        local name = item:GetItemName()
        VGT.db.char.dropTracker.items[name] = VGT.db.char.dropTracker.items[name] or {
            id = itemId,
            name = name,
            link = item:GetItemLink(),
            icon = item:GetItemIcon()
        }
        VGT.dropTracker:Refresh()
    end)
end

function VGT.dropTracker:SetWon(itemId, won)
    if won and VGT.db.profile.dropTracker.wonSound then
        local sound = LSM:Fetch("sound", VGT.db.profile.dropTracker.wonSound, true)
        if sound then
            PlaySoundFile(sound, "Master")
        end
    end
    for _,item in pairs(VGT.db.char.dropTracker.items) do
        if item.id == itemId then
            item.won = won
            self:Refresh()
            return
        end
    end
end

function VGT.dropTracker:NotifyInterested(item)
    item.passed = nil
    item.interested = true
    VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_INTERESTED, item.id)
    self:Refresh()
end

function VGT.dropTracker:NotifyPassing(item)
    item.passed = true
    item.interested = nil
    VGT:SendGroupAddonCommand(VGT.Commands.NOTIFY_PASSING, item.id)
    self:Refresh()
end

function VGT.dropTracker:Refresh()
    if not self.frame then
        return
    end
    self:ResetItems()
    local currentScroll = self.scroll.localstatus.scrollvalue
    self.scroll:ReleaseChildren()
    if not next(VGT.db.char.dropTracker.items) then
        local label  = AceGUI:Create("Label")
        label:SetText("No items have dropped yet.")
        label:SetFullWidth(true)
        label:SetFont(GameFontHighlight:GetFont(), 16)
        self.scroll:AddChild(label)
        return
    end

    for _, i in pairs(VGT.db.char.dropTracker.items) do
        local item = i
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
        label:SetCallback("OnLeave",function()
            GameTooltip:Hide()
        end)
        group:AddChild(label)

        if not item.won then
            local interestedButton = AceGUI:Create("Button")
            interestedButton:SetText("Interested")
            interestedButton:SetHeight(24)
            interestedButton:SetCallback("OnClick", function()
                VGT.dropTracker:NotifyInterested(item)
            end)
            group:AddChild(interestedButton)
    
            local passButton = AceGUI:Create("Button")
            passButton:SetText("Pass")
            passButton:SetHeight(24)
            passButton:SetCallback("OnClick", function()
                VGT.dropTracker:NotifyPassing(item)
            end)
            group:AddChild(passButton)
        end
    end

    local resetButton = AceGUI:Create("Button")
    resetButton:SetFullWidth(true)
    resetButton:SetText("Clear All")
    resetButton:SetCallback("OnClick", function()
        VGT.dropTracker:ResetItems(true)
        VGT.dropTracker:Refresh()
    end)
    self.scroll:AddChild(resetButton)
    self.scroll:SetScroll(currentScroll)
    self.scroll:FixScroll()
end

function VGT.dropTracker:Toggle()
    if not self.frame then
        self:BuildWindow()
    elseif self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:Refresh()
    end
end

function VGT.dropTracker:BuildWindow()
    self.frame = AceGUI:Create("Window")
    self.frame:SetTitle("Valhalla Drop Tracker")
    self.frame:SetLayout("Fill")
    self:RefreshWindowConfig() -- SetPoint, SetWidth, SetHeight
    self.frame:SetCallback("OnClose", function()
        local point, _, _, x, y = VGT.dropTracker.frame.frame:GetPoint(1)
        VGT.db.profile.dropTracker.x = x
        VGT.db.profile.dropTracker.y = y
        VGT.db.profile.dropTracker.point = point
        VGT.db.profile.dropTracker.width = VGT.dropTracker.frame.frame:GetWidth()
        VGT.db.profile.dropTracker.height = VGT.dropTracker.frame.frame:GetHeight()
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

function VGT.dropTracker:RefreshWindowConfig()
    if not self.frame then
        return
    end
    
    self.frame:SetHeight(VGT.db.profile.dropTracker.height < 240 and 240 or VGT.db.profile.dropTracker.height)
    self.frame:SetWidth(VGT.db.profile.dropTracker.width < 400 and 400 or VGT.db.profile.dropTracker.width)
    self.frame:SetPoint(
        VGT.db.profile.dropTracker.point,
        UIParent,
        VGT.db.profile.dropTracker.point,
        VGT.db.profile.dropTracker.x,
        VGT.db.profile.dropTracker.y
    )
end

VGT:RegisterCommandHandler(VGT.Commands.ASSIGN_ITEM, function(sender, id)
    VGT.dropTracker:SetWon(id, true)
end)

VGT:RegisterCommandHandler(VGT.Commands.UNASSIGN_ITEM, function(sender, id)
    VGT.dropTracker:SetWon(id, false)
end)

VGT:RegisterCommandHandler(VGT.Commands.ITEM_TRACKED, function(sender, itemId, creatureId)
    VGT.dropTracker:Track(itemId)
end)