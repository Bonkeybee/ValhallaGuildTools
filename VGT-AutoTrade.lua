local currentTrades = {}
local activeSlots = {}

CreateFrame("GameTooltip", "VGTAutoTradeScanningTooltip", nil, "GameTooltipTemplate")
VGTAutoTradeScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
VGTAutoTradeScanningTooltip:AddFontStrings(
    VGTAutoTradeScanningTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
    VGTAutoTradeScanningTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText"))

local function bagSlotActive(bag, slot)
    local v = bag..","..slot
    for i=1,6 do
        if activeSlots[i] == v then
            return true
        end
    end
end

local function findEligibleItemLoc(itemId)
    for bag=0,4 do
        for slot=1,GetContainerNumSlots(bag) do
            if not bagSlotActive(bag, slot) then
                local containerItemId = GetContainerItemID(bag, slot)
                if containerItemId == itemId then
                    VGTAutoTradeScanningTooltip:ClearLines()
                    VGTAutoTradeScanningTooltip:SetBagItem(bag, slot)
                    local isSoulbound = false
                    local hasTradableText = false
                    for i=1,VGTAutoTradeScanningTooltip:NumLines() do
                        local line = _G["VGTAutoTradeScanningTooltipTextLeft"..i]
                        local text = line and line:GetText() or ""
                        if text == "Soulbound" then
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

VGT:RegisterEvent("TRADE_SHOW", function()
    if VGT_OPTIONS.AUTOTRADE.enabled then
        currentTrades[1] = nil
        currentTrades[2] = nil
        currentTrades[3] = nil
        currentTrades[4] = nil
        currentTrades[5] = nil
        currentTrades[6] = nil
        activeSlots[1] = nil
        activeSlots[2] = nil
        activeSlots[3] = nil
        activeSlots[4] = nil
        activeSlots[5] = nil
        activeSlots[6] = nil
        local name = UnitName("npc")
        local targetSlot = 1
        for _,creatureData in ipairs(VGT_MasterLootData) do
            for _,itemData in ipairs(creatureData.items) do
                if targetSlot > 6 then
                    return
                end
                if itemData.winner and name == itemData.winner and not itemData.traded then
                    local bagId, slotId = findEligibleItemLoc(itemData.id)
                    if bagId ~= nil and slotId ~= nil then
                        ClearCursor()
                        PickupContainerItem(bagId, slotId)
                        ClickTradeButton(targetSlot)
                        currentTrades[targetSlot] = itemData
                        activeSlots[targetSlot] = bagId..","..slotId
                        targetSlot = targetSlot + 1
                    end
                end
            end
        end
    end
end)

VGT:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", function(event, slot)
    currentTrades[slot] = nil
    activeSlots[slot] = nil
end)

VGT:RegisterEvent("UI_INFO_MESSAGE", function(event, arg1, arg2)
    if arg2 == ERR_TRADE_COMPLETE then
        for i=1,6 do
            local itemData = currentTrades[i]
            currentTrades[i] = nil
            activeSlots[i] = nil
            if itemData then
                itemData.traded = true
            end
        end
        VGT.masterLooter.Refresh()
    end
end)
