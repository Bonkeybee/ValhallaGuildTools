local AceGUI = VGT.Gui
local root = nil
VGT.MasterLooter = { Rolls = {}, Passes = {} }
VGT_MasterLootData = VGT_MasterLootData or {}

local function sendMLMessage(message, nowarn)
    if UnitInRaid("player") then
        if nowarn then
            channel = "RAID"
        elseif IsEveryoneAssistant() then
            channel = "RAID_WARNING"
        else
            channel = "RAID"
            for i=1,40 do
                if (UnitIsUnit("player", "raid"..i)) then
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
        print(message)
    end
end

local function readData(creatureGuid, itemId, itemIndex)
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

local function getRollData()
    return readData(VGT.MasterLooter.RollCreature, VGT.MasterLooter.RollItem, VGT.MasterLooter.RollIndex)
end

local function addPrioToStandings(itemId, name, prio)
    if VGT_MasterLootData.Standings then
        local itemStandings = VGT_MasterLootData.Standings[itemId]
        if itemStandings then
            for i,standing in ipairs(itemStandings) do
                if standing.Prio == prio then
                    tinsert(standing.Names, name)
                    return
                elseif standing.Prio < prio then
                    tinsert(itemStandings, i, {Prio = prio, Names = {name}})
                    return
                end
            end
        end
    end
end

local function takePrioFromStandings(itemId, name)
    if VGT_MasterLootData.Standings then
        local itemStandings = VGT_MasterLootData.Standings[itemId]
        if itemStandings then
            for _,standing in ipairs(itemStandings) do
                for i,n in ipairs(standing.Names) do
                    if n == name then
                        tremove(standing.Names, i)
                        return standing.Prio
                    end
                end
            end
        end
    end
end

local function getPrio(name)
    if VGT_MasterLootData.Standings then
        local itemStandings = VGT_MasterLootData.Standings[itemId]
        if itemStandings then
            for _,standing in ipairs(itemStandings) do
                for _,n in ipairs(standing.Names) do
                    if n == name then
                        return standing.Prio
                    end
                end
            end
        end
    end
end

local function incrementStandings(itemId, characters)
    if VGT_MasterLootData.Standings then
        for _,character in ipairs(characters) do
            local prios = {}

            while true do
                local prio = takePrioFromStandings(itemId, character.Name)
                if type(prio) == "number" then
                    tinsert(prios, prio)
                else
                    break
                end
            end
            
            if #prios > 0 then
                for _,prio in ipairs(prios) do
                    addPrioToStandings(itemId, character.Name, prio + 1)
                end
            end
        end
    end
end

local function configureEncounter(creatureGuid)
    local label = AceGUI:Create("InteractiveLabel")
    label:SetText(VGT:UnitNameFromGuid(creatureGuid))
    label:SetFullWidth(true)
    label:SetFont(GameFontHighlight:GetFont(), 16)
    root.scroll:AddChild(label)

    local spacer = AceGUI:Create("InteractiveLabel")
    spacer:SetFullWidth(true)
    spacer:SetText(" ")
    root.scroll:AddChild(spacer)

    local exportButton = AceGUI:Create("Button")
    exportButton:SetText("Export Items")
    exportButton:SetFullWidth(true)
    exportButton:SetCallback(
        "OnClick",
        function()
            local creatureData = readData(creatureGuid)

            if creatureData then
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

                for _,itemData in ipairs(creatureData.items) do
                    if (not itemData.class or itemData.quality == 4)
                    and (not itemData.class or allowedClasses[itemData.class])
                    and not ignoredItems[itemData.id] then
                        tinsert(items, itemData.id)
                    end
                end
                
                VGT:ShowKillExport(items, creatureData.characters)
            end
        end
    )
    root.scroll:AddChild(exportButton)
end

local function configureItem(creatureId, itemId, itemIndex)
    local creatureData, itemData = readData(creatureId, itemId, itemIndex)

    local label = AceGUI:Create("InteractiveLabel")
    label:SetImage(itemData.icon)
    label:SetImageSize(24, 24)
    label:SetText(itemData.link)
    label:SetFullWidth(true)
    label:SetFont(GameFontHighlight:GetFont(), 16)
    label:SetCallback(
        "OnEnter",
        function()
            GameTooltip:SetOwner(label.frame, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOP", label.frame, "BOTTOM", 0, 0)
            GameTooltip:SetHyperlink("item:" .. itemId)
            GameTooltip:Show()
        end
    )
    label:SetCallback(
        "OnLeave",
        function()
            GameTooltip:Hide()
        end
    )
    root.scroll:AddChild(label)

    label = AceGUI:Create("InteractiveLabel")
    label:SetFullWidth(true)
    label:SetFont(GameFontHighlight:GetFont(), 16)
    label:SetText(
        itemData.winner and ("|cff00ff00Assigned to " .. itemData.winner .. "|r") or "|cffff0000Unassigned|r"
    )
    root.scroll:AddChild(label)

    local spacer = AceGUI:Create("InteractiveLabel")
    spacer:SetFullWidth(true)
    spacer:SetText(" ")
    root.scroll:AddChild(spacer)

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

            if oldPrio then
                addPrioToStandings(itemData.id, oldWinner, oldPrio)
            end

            sendMLMessage(itemData.link .. " unassigned from " .. oldWinner)
            VGT:SendCoreMessage("UA\001" .. itemData.id, "WHISPER", oldWinner)
            VGT.MasterLooter.Refresh()
        end)
        root.scroll:AddChild(unassignButton)
    else
        local rollCreature, rollItem = getRollData()
        
        if rollItem then
            if rollItem == itemData then
                local stopButton = AceGUI:Create("Button")
                stopButton:SetText("End Rolling")
                stopButton:SetCallback("OnClick", function()
                    VGT.MasterLooter:EndRoll()
                end)
                root.scroll:AddChild(stopButton)

                local countdownButton = AceGUI:Create("Button")
                countdownButton:SetText("5-Second Countdown")
                countdownButton:SetCallback("OnClick", function()
                    VGT.MasterLooter:CountdownRoll()
                end)
                root.scroll:AddChild(countdownButton)

                local remindButton = AceGUI:Create("Button")
                remindButton:SetText("Remind Rollers")
                remindButton:SetCallback("OnClick", function()
                    VGT.MasterLooter:RemindRoll()
                end)
                root.scroll:AddChild(remindButton)

                local cancelButton = AceGUI:Create("Button")
                cancelButton:SetText("Cancel Rolling")
                cancelButton:SetCallback("OnClick", function()
                    VGT.MasterLooter:CancelRoll()
                end)
                root.scroll:AddChild(cancelButton)

                for i,v in ipairs(VGT.MasterLooter.Rolls) do
                    local label = AceGUI:Create("Label")
                    label:SetText(v.name .. ": " .. v.roll .. "\n")
                    root.scroll:AddChild(label)
                end
        
                for name,_ in pairs(VGT.MasterLooter.Passes) do
                    local label = AceGUI:Create("Label")
                    label:SetText(name .. ": Pass\n")
                    root.scroll:AddChild(label)
                end
            else
                local label = AceGUI:Create("Label")
                label:SetFullWidth(true)
                label:SetFont(GameFontHighlight:GetFont(), 16)
                label:SetText("|cffff0000Currently rolling on "..rollItem.name.."|r")
                root.scroll:AddChild(label)
            
                local spacer = AceGUI:Create("Label")
                spacer:SetFullWidth(true)
                spacer:SetText(" ")
                root.scroll:AddChild(spacer)
            end
        else
            if VGT_MasterLootData.Standings then
                local itemStandings = VGT_MasterLootData.Standings[itemData.id]
                if itemStandings then
                    for _, s in ipairs(itemStandings) do
                        local standing = s
                        local whitelist = {}
                        local lookup = {}

                        for _,name in ipairs(standing.Names) do
                            lookup[name] = true
                        end

                        for _,character in ipairs(creatureData.characters) do
                            if lookup[character.Name] then
                                tinsert(whitelist, character.Name)
                            end
                        end

                        if #whitelist > 0 then
                            local standingButton = AceGUI:Create("Button")
                            standingButton:SetFullWidth(true)
                            local sText = "(" .. standing.Prio .. ") "
                            local addComma = false
    
                            for _,name in ipairs(whitelist) do
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
                                    itemData.winningPrio = takePrioFromStandings(itemData.id, itemData.winner)
                                    VGT:SendCoreMessage("AI\001" .. itemData.id, "WHISPER", itemData.winner)
                                    sendMLMessage(itemData.link .. " assigned to " .. itemData.winner .. " (" .. itemData.winningPrio .. " Prio)")
                                    VGT.MasterLooter.Refresh()
                                else
                                    VGT.MasterLooter:LimitedRoll(creatureData.id, itemData.id, itemData.index, whitelist)
                                end
                            end)

                            root.scroll:AddChild(standingButton)
                        end
                    end
                end
            end

            local rollButton = AceGUI:Create("Button")
            rollButton:SetText("Open Roll")
            rollButton:SetFullWidth(true)
            rollButton:SetCallback("OnClick", function()
                VGT.MasterLooter:OpenRoll(creatureId, itemId, itemIndex)
            end)
            root.scroll:AddChild(rollButton)

            local manualAssign = AceGUI:Create("Dropdown")
            manualAssign:SetLabel("Manual Assign")
            root.scroll:AddChild(manualAssign)
            local characters = {}
            for i, character in ipairs(creatureData.characters) do
                characters[character.Name] = VGT:ColorizeCharacterName(character)
            end
            table.sort(characters)
            manualAssign:SetList(characters)
            manualAssign:SetCallback("OnValueChanged", function(self, e, value)
                itemData.winner = value
                itemData.winningPrio = takePrioFromStandings(itemData.id, value)
                VGT:SendCoreMessage("AI\001" .. itemData.id, "WHISPER", value)
                sendMLMessage(itemData.link .. " assigned to " .. value)
                VGT.MasterLooter.Refresh()
            end)
        end
    end
end

local function configureHome()
    local rsbutton = AceGUI:Create("Button")
    rsbutton:SetText("Raid Start")
    rsbutton:SetCallback("OnClick", VGT.ShowRaidStartExport)
    root.scroll:AddChild(rsbutton)

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

            for _,item in ipairs(items) do
                VGT_MasterLootData.Standings[item.Id] = item.Standings
            end
        end)
        if not success then
            importStatus:SetText("|cffff0000Import failed.|r")
            VGT_MasterLootData.Standings = nil
        else
            VGT.MasterLooter.Refresh()
            importStatus:SetText("|cff00ff00Import Succeeded.|r")
        end
    end)

    root.scroll:AddChild(importText)
    root.scroll:AddChild(importStatus)

    local manualTrackButton = AceGUI:Create("Button")
    manualTrackButton:SetText("Manual Track Item")
    manualTrackButton:SetCallback("OnClick", function()
        local infoType, itemId, itemLink = GetCursorInfo()
        ClearCursor()
        if infoType == "item" then
            VGT.MasterLooter.TrackUnknown(nil, itemId)
        else
            print("Click this button while holding an item to add it to the tracker.")
        end
    end)
    root.scroll:AddChild(manualTrackButton)

    local clearButton = AceGUI:Create("Button")
    clearButton:SetText("Clear All")
    clearButton:SetCallback("OnClick", VGT.MasterLooter.ClearAll)
    root.scroll:AddChild(clearButton)
end

local function configureSelection(groupId)
    root.scroll:ReleaseChildren()
    VGT.MasterLooter.groupId = groupId

    if groupId then
        local creatureId, itemIdAndIndex = strsplit("\001", groupId)
        if itemIdAndIndex then
            local itemId, itemIndex = strsplit("+", itemIdAndIndex)
            configureItem(creatureId, tonumber(itemId), tonumber(itemIndex) or 1)
        else
            configureEncounter(creatureId)
        end
    else
        configureHome()
    end
end

local function createRoot()
    root = AceGUI:Create("Window")
    VGT.MasterLooter.Root = root
    root:SetTitle("Valhalla Master Looter")
    root:SetLayout("Fill")
    root:SetHeight(VGT.OPTIONS.LOOTLIST.Height < 240 and 240 or VGT.OPTIONS.LOOTLIST.Height)
    root:SetWidth(VGT.OPTIONS.LOOTLIST.Width < 400 and 400 or VGT.OPTIONS.LOOTLIST.Width)
    root:SetPoint(
      VGT.OPTIONS.LOOTLIST.Point,
      UIParent,
      VGT.OPTIONS.LOOTLIST.Point,
      VGT.OPTIONS.LOOTLIST.X,
      VGT.OPTIONS.LOOTLIST.Y
    )
    root:SetCallback("OnClose", function()
        local point, _, _, x, y = root.frame:GetPoint(1)
        VGT.OPTIONS.LOOTLIST.X = x
        VGT.OPTIONS.LOOTLIST.Y = y
        VGT.OPTIONS.LOOTLIST.Point = point
        VGT.OPTIONS.LOOTLIST.Width = root.frame:GetWidth()
        VGT.OPTIONS.LOOTLIST.Height = root.frame:GetHeight()
    end)

    local tree = AceGUI:Create("TreeGroup")
    tree:EnableButtonTooltips(false)
    tree:SetFullWidth(true)
    tree:SetFullHeight(true)
    tree:SetLayout("Fill")
    tree:SetAutoAdjustHeight(false)
    tree:SetCallback(
        "OnGroupSelected",
        function(self, e, groupId)
            configureSelection(groupId)
        end
    )
    root:AddChild(tree)
    root.tree = tree

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    root.tree:AddChild(scroll)
    root.scroll = scroll

    VGT.MasterLooter.Refresh()
end

function VGT.MasterLooter.ClearAllConfirmed()
    VGT_MasterLootData = {}
    VGT.MasterLooter.Refresh()
end

function VGT.MasterLooter.ClearAll()
    StaticPopupDialogs["CONFIRM_VGTML_CLEAR"] =
    StaticPopupDialogs["CONFIRM_VGTML_CLEAR"] or
        {
            text = CONFIRM_CONTINUE,
            button1 = ACCEPT,
            button2 = CANCEL,
            hideOnEscape = true,
            OnAccept = VGT.MasterLooter.ClearAllConfirmed
        }
    StaticPopup_Show("CONFIRM_VGTML_CLEAR")
end

function VGT.MasterLooter.Toggle()
    if not root then
        createRoot()
    else
        if root:IsShown() then
            root.frame:Hide()
        else
            VGT.MasterLooter:Refresh()
            root.frame:Show()
        end
    end
end

function VGT.MasterLooter.Refresh()
    local data = {
        {
            text = "Home",
            value = nil
        }
    }

    for _, creatureData in ipairs(VGT_MasterLootData) do
        local creatureNode = {
            value = creatureData.id,
            text = VGT:UnitNameFromGuid(creatureData.id),
            icon = "Interface\\RAIDFRAME\\ReadyCheck-NotReady.blp",
            children = {}
        }

        tinsert(data, creatureNode)

        local anyUnassigned, anyAssigned

        for _, item in pairs(creatureData.items) do
            local itemNode = {
                text = item.name,
                value = item.id .. "+" .. item.index,
                icon = item.icon
            }

            tinsert(creatureNode.children, itemNode)

            if item.winner then
                itemNode.text = "|cff00ff00" .. item.name .. "|r"
                anyAssigned = true
            else
                anyUnassigned = true
            end
        end

        if anyAssigned then
            if anyUnassigned then
                creatureNode.icon = "Interface\\RAIDFRAME\\ReadyCheck-Waiting.blp"
            else
                creatureNode.icon = "Interface\\RAIDFRAME\\ReadyCheck-Ready.blp"
            end
        end
    end

    if root then
        root.tree:SetTree(data)
        configureSelection(VGT.MasterLooter.groupId)
    end
end

function VGT.MasterLooter.TrackUnknown(creatureId, itemId)
    local creatureData, itemData = VGT.MasterLooter.Track(creatureId or "Creature-0-0-0-0-0-0-0", itemId)
    local item = Item:CreateFromItemID(itemId)
    item:ContinueOnItemLoad(function()
        itemData.name = item:GetItemName()
        itemData.link = item:GetItemLink()
        itemData.icon = item:GetItemIcon()
        local itemQuality, _, _, _, _, _, _, _, _, classId = select(3, GetItemInfo(itemData.link))
        itemData.class = classId
        itemData.quality = itemQuality
        VGT.MasterLooter.Refresh()
    end)
    return creatureData, itemData
end

function VGT.MasterLooter.TrackAllForCreature(creatureId, itemLinks)
    local creatureData

    for i, v in ipairs(VGT_MasterLootData) do
        if v.id == creatureId then
            creatureData = v
            break
        end
    end

    if not creatureData then
        for _,link in ipairs(itemLinks) do
            local item = Item:CreateFromItemLink(link)
            item:ContinueOnItemLoad(function()
              VGT.MasterLooter.Track(creatureId, item:GetItemID(), item:GetItemName(), link, item:GetItemIcon())
            end)
        end
    end
end

function VGT.MasterLooter.Track(creatureId, itemId, itemName, itemLink, itemIcon)
    local creatureData

    for i, v in ipairs(VGT_MasterLootData) do
        if v.id == creatureId then
            creatureData = v
            break
        end
    end

    if not creatureData then
        creatureData = {
            id = creatureId,
            items = {},
            characters = VGT:GetCharacters()
        }
        tinsert(VGT_MasterLootData, creatureData)
    end

    local nextItemIndex = 1

    for i, v in ipairs(creatureData.items) do
        if v.id == itemId then
            nextItemIndex = nextItemIndex + 1
        end
    end

    local itemData = {
        id = itemId,
        index = nextItemIndex,
        name = itemName,
        link = itemLink,
        icon = itemIcon
    }
    if itemLink then
        local itemQuality, _, _, _, _, _, _, _, _, classId = select(3, GetItemInfo(link))
        itemData.quality = itemQuality
        itemData.class = classId
    end

    tinsert(creatureData.items, itemData)

    incrementStandings(itemId, creatureData.characters)

    VGT.MasterLooter.Refresh()

    return creatureData, itemData
end

function VGT.MasterLooter:LimitedRoll(creatureId, itemId, itemIndex, whitelist)
    local creatureData, itemData = readData(creatureId, itemId, itemIndex)

    if (creatureData and itemData) then
        self.RollCreature = creatureId
        self.RollItem = itemId
        self.RollIndex = itemIndex
        self.RollWhitelist = whitelist
        self.Refresh()

        local text = "Roll on " .. itemData.link .. " for "
        local msg = "SR\001" .. itemData.id
        local addComma = false
        for _,name in ipairs(whitelist) do
            if addComma then
                text = text .. ", "
            end
            addComma = true
            text = text .. name

            if UnitInRaid(name) then
                VGT:SendCoreMessage(msg, "WHISPER", name)
            end
        end

        sendMLMessage(text)
        sendMLMessage("/roll or type \"pass\" in chat", true)
    end
end

function VGT.MasterLooter:OpenRoll(creatureId, itemId, itemIndex)
    local creatureData, itemData = readData(creatureId, itemId, itemIndex)

    if (creatureData and itemData) then
        self.RollCreature = creatureId
        self.RollItem = itemId
        self.RollIndex = itemIndex
        self.RollWhitelist = nil
        self.Refresh()
        sendMLMessage("Open Roll on " .. itemData.link)
        sendMLMessage("/roll or type \"pass\" in chat", true)
        VGT:SendCoreMessage("SR\001" .. itemId, "RAID")
    end
end

function VGT.MasterLooter:CountdownRoll()
    local t = 5
    local function tick()
        if t > 0 then
            sendMLMessage(t)
            VGT:ScheduleTimer(tick, 1)
        else
            self:EndRoll()
        end
        t = t - 1
    end
    VGT:ScheduleTimer(tick, 1)
end

function VGT.MasterLooter:EndRoll()
    local creatureData, itemData = getRollData()

    if not itemData then
        return
    end

    if #self.Rolls > 0 then
        local winningAmt = self.Rolls[1].roll
        local winners = {}
        
        for i,v in ipairs(self.Rolls) do
            if v.roll == winningAmt then
                tinsert(winners, v.name)
            end
        end

        if #winners == 1 then
            itemData.winner = winners[1]
            itemData.winningPrio = takePrioFromStandings(itemData.id, itemData.winner)
            VGT:SendCoreMessage("AI\001" .. itemData.id, "WHISPER", itemData.winner)
            local msg = itemData.link .. " won by " .. itemData.winner .. " (" .. winningAmt
            if itemData.winningPrio then
                msg = msg .. " rolled, " .. itemData.winningPrio .. " prio)"
            else
                msg = msg .. ")"
            end

            sendMLMessage(msg)
        else
            self.Rolls = {}
            self.RollWhitelist = winners

            local msg = "Reroll: "

            for i,v in ipairs(winners) do
                if i > 1 then
                    msg = msg .. ", "
                end
                msg = msg .. v
            end
            
            sendMLMessage(msg)
            VGT.MasterLooter.Refresh()
            return
        end
    else
        sendMLMessage(itemData.link .. " passed by all.")
    end

    self.RollCreature = nil
    self.RollItem = nil
    self.RollIndex = nil
    self.Rolls = {}
    self.Passes = {}
    self.RollWhitelist = nil
    self.Refresh()
    VGT:SendCoreMessage("CR", "RAID")
end

function VGT.MasterLooter:RemindRoll()
    local creatureData, itemData = getRollData()

    if itemData then
        local msg = "Rolling on " .. itemData.link .. "."

        if #self.Rolls > 0 then
            local winningAmt = self.Rolls[1].roll
            local winners = {}
            
            for i,v in ipairs(self.Rolls) do
                if v.roll == winningAmt then
                    tinsert(winners, v.name)
                end
            end
    
            if #winners == 1 then
                msg = msg .. " Current Winner: " .. winners[1] .. " (" .. winningAmt .. ")"
            else
                msg = msg .. " Current Winners: "
                for i,v in ipairs(winners) do
                    if i > 1 then
                        msg = msg .. ", "
                    end
                    msg = msg .. v
                end
                msg = msg .. " (" .. winningAmt .. ")"
            end
        end
        sendMLMessage(msg, true)

        msg = "Missing rolls from: "

        local responded = {}

        for playerName,_ in pairs(VGT.MasterLooter.Passes) do
            responded[playerName] = true
        end

        for _,v in ipairs(VGT.MasterLooter.Rolls) do
            responded[v.name] = true
        end

        local needsComma

        if VGT.MasterLooter.RollWhitelist then
            for _, name in ipairs(VGT.MasterLooter.RollWhitelist) do
                if not responded[name] then
                    if needsComma then
                        msg = msg .. ", "
                    end
                    msg = msg .. name
                    needsComma = true
                end
            end
        else
            for _,character in ipairs(creatureData.characters) do
                if not responded[character.Name] then
                    if needsComma then
                        msg = msg .. ", "
                    end
                    msg = msg .. character.Name
                    needsComma = true
                end
            end
        end

        sendMLMessage(msg, true)
        sendMLMessage("/roll or type \"pass\" in chat.", true)
    end
end

function VGT.MasterLooter:CancelRoll()
    local creatureData, itemData = getRollData()

    if (creatureData and itemData) then
        self.RollCreature = nil
        self.RollItem = nil
        self.RollIndex = nil
        self.Rolls = {}
        self.Passes = {}
        self.RollWhitelist = nil
        self.Refresh()
        VGT:SendCoreMessage("CR", "RAID")
        sendMLMessage("Roll for " .. itemData.link .. " cancelled.")
    end
end

function VGT.MasterLooter:AddDummyData()
    VGT.MasterLooter.TrackUnknown(nil, 39272)
    VGT.MasterLooter.TrackUnknown(nil, 39270)
    VGT.MasterLooter.TrackUnknown(nil, 39276)
    VGT.MasterLooter.TrackUnknown(nil, 39280)
end

local function whitelisted(name)
    if not VGT.MasterLooter.RollWhitelist then
        return true
    end

    for _,name2 in ipairs(VGT.MasterLooter.RollWhitelist) do
        if name == name2 then
            return true
        end
    end
end

VGT:RegisterEvent("CHAT_MSG_SYSTEM", function(channel, text)
    if VGT.MasterLooter.RollItem then
        local name, roll, minRoll, maxRoll = text:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")
        if name and roll and minRoll and maxRoll then
            roll = tonumber(roll)
            minRoll = tonumber(minRoll)
            maxRoll = tonumber(maxRoll)
            if minRoll == 1 and maxRoll == 100 and whitelisted(name) then
                local existingRoll = false
                for i,v in ipairs(VGT.MasterLooter.Rolls) do
                    if (v.name == name) then
                        existingRoll = true
                        break
                    end
                end
                if not existingRoll then
                    tinsert(VGT.MasterLooter.Rolls, {name = name, roll = roll})
                    table.sort(VGT.MasterLooter.Rolls, function(a,b) return a.roll > b.roll end)
                    VGT.MasterLooter.Refresh()
                elseif VGT.MasterLooter.Passes[name] then
                    VGT.MasterLooter.Passes[name] = nil
                    VGT.MasterLooter.Refresh()
                end
            end
        end
    end
end)

local function handleChatCommand(channel, text, playerName)
    if VGT.MasterLooter.RollItem then
        if (text == "pass" or text == "Pass" or text == "PASS") and whitelisted(playerName) then
            VGT.MasterLooter.Passes[playerName] = true
            VGT.MasterLooter.Refresh()
        end
    end
end

VGT:RegisterCoreMessageHandler(function(message, sender)
    if VGT.MasterLooter.RollItem then
        local cmd, id = strsplit("\001", message)
        
        if cmd == "RP" and VGT.MasterLooter.RollItem.id == tonumber(id) then
            VGT.MasterLooter.Passes[sender] = true
            VGT.MasterLooter.Refresh()
        end
    end
end)

VGT:RegisterEvent("CHAT_MSG_RAID", handleChatCommand)
VGT:RegisterEvent("CHAT_MSG_RAID_LEADER", handleChatCommand)
VGT:RegisterEvent("CHAT_MSG_PARTY", handleChatCommand)
VGT:RegisterEvent("CHAT_MSG_PARTY_LEADER", handleChatCommand)
VGT:RegisterEvent("CHAT_MSG_WHISPER", handleChatCommand)
