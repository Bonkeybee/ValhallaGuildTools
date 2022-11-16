local StaticPopupDialogs, StaticPopup_Show = StaticPopupDialogs, StaticPopup_Show
---@diagnostic disable-next-line: undefined-field
local gfind = string.gfind

do
  local function NOP()
    return
  end

  local PopupId = "VLL_EXPORT"

  function VGT:ExportPopup(title, export)
    if (StaticPopupDialogs[PopupId] == nil) then
      local popup = {
        button2 = "Close",
        hasEditBox = 1,
        hasWideEditBox = 1,
        editBoxWidth = 350,
        preferredIndex = 3,
        OnHide = NOP,
        OnAccept = NOP,
        OnCancel = NOP,
        EditBoxOnEscapePressed = function(this)
          this:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
      }
      function popup:OnShow()
        self:SetWidth(420)
        local editBox = _G[self:GetName() .. "WideEditBox"] or _G[self:GetName() .. "EditBox"]
        editBox:SetText(StaticPopupDialogs[PopupId].export)
        editBox:SetFocus()
        editBox:HighlightText(false)
        local button = _G[self:GetName() .. "Button2"]
        button:ClearAllPoints()
        button:SetWidth(200)
        button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
      end

      StaticPopupDialogs[PopupId] = popup
    end

    StaticPopupDialogs[PopupId].text = title
    StaticPopupDialogs[PopupId].export = export
    StaticPopup_Show(PopupId, export)
  end
end

local classLookup = {
  [1] = 1, -- Warrior
  [2] = 2, -- Paladin
  [3] = 4, -- Hunter
  [4] = 8, -- Rogue
  [5] = 16, -- Priest
  [6] = 32, -- Death Knight
  [7] = 64, -- Shaman
  [8] = 128, -- Mage
  [9] = 256, -- Warlock
  [11] = 1024 -- Druid
}

local reverseClassLookup = {}

for k,v in pairs(classLookup) do
  reverseClassLookup[v] = k
end

local raceLookup = {
  [1] = 0, -- Human
  [3] = 1, -- Dwarf
  [4] = 2, -- NightElf
  [7] = 3, -- Gnome
  [11] = 4 -- Draenei
}

-- https://wowpedia.fandom.com/wiki/InstanceID
local trackedInstances = {
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

function VGT:ColorizeCharacterName(character)
  local _, _, _, color = GetClassColor(select(2, GetClassInfo(reverseClassLookup[character.Class])))
  if not color then
    return character.Name
  else
    return "|c" .. color .. character.Name .. "|r"
  end
end

function VGT:GetCharacters()

  local function insertCharacter(characters, id)
    local name, _ = UnitName(id)
    if (name) then
      local _, _, raceId = UnitRace(id)
      local gender = UnitSex(id)
      local _, _, classId = UnitClass(id)

      if (raceId and gender and classId) then
        table.insert(
          characters,
          {
            Name = name,
            Gender = gender - 2,
            Class = classLookup[classId],
            Race = raceLookup[raceId]
          }
        )
      end
    end
  end

  local characters = {}
  if UnitInRaid("player") then
    for i = 1, 40 do
      insertCharacter(characters, "raid" .. i)
    end
  else
    insertCharacter(characters, "player")
    if UnitInParty("player") then
      for i = 1, 4 do
        insertCharacter(characters, "party" .. i)
      end
    end
  end
  return characters
end

function VGT:ExportRaidStart()
  return json.encode({ Characters = self:GetCharacters() })
end

function VGT:ShowRaidStartExport()
  VGT:ExportPopup("Export Raid Start", VGT:ExportRaidStart())
end

function VGT:ExportKill(items, characters)
  return json.encode({ Items = items, Characters = characters or self:GetCharacters() })
end

function VGT:ShowKillExport(items, characters)
  self:ExportPopup("Export Kill", self:ExportKill(items, characters))
end

local function ShouldTrack(link)
  if (not link) then
    return false
  end

  local _, _, itemQuality, _, _, itemType = GetItemInfo(link)

  return (itemQuality == 4 or VGT.OPTIONS.LOOTLIST.trackEverything) and itemType ~= "Money"
end

local function ExportItems()
  local guid, _ = GetLootSourceInfo(1)
  local instanceId = select(4, strsplit("-", guid or ""))

  if (instanceId) then
    instanceId = tonumber(instanceId)
  end

  if (instanceId and (trackedInstances[instanceId] or VGT.OPTIONS.LOOTLIST.trackEverything)) then
    local itemLinks = {}

    for i = 1, GetNumLootItems() do
      local link = GetLootSlotLink(i)
      if (ShouldTrack(link)) then
        tinsert(itemLinks, link)
      end
    end

    VGT.masterLooter.TrackAllForCreature(guid, itemLinks)
  end
end

local function ShouldIgnore(ignores, link)
  if not link then
    return true
   end
  local itemName, _ = GetItemInfo(link)
  for _, value in pairs(ignores) do
    local ignoreName, _ = GetItemInfo(value)
    if (ignoreName == itemName) then
      return true
    end
  end
end

local function GetAutoMasterLootTarget(ignores, lootIndex)
  local quality, locked = select(5, GetLootSlotInfo(slot))
  if locked or quality > 4 then
    return
  end
  if ShouldIgnore(ignores, GetLootSlotLink(lootIndex)) then
    return
  end

  local target

  if quality < 4 then
    target = VGT.OPTIONS.LOOTLIST.masterLootDisenchantTarget
    if UnitExists(target) then
      return target
    end
  end

  target = VGT.OPTIONS.LOOTLIST.masterLootTarget
  if UnitExists(target) then
    return target
  end

  return UnitName("player")
end

local function AutoMasterLoot()
  local ignores = { strsplit(";", VGT.OPTIONS.LOOTLIST.ignoredItems or "") }
  tinsert(ignores, 22726) -- Splinter of Atiesh
  for lootIndex = 1, GetNumLootItems() do
    local target = GetAutoMasterLootTarget(ignores, lootIndex)
    if target then
      for raidIndex = 1, 40 do
        if (GetMasterLootCandidate(lootIndex, raidIndex) == target) then
          GiveMasterLoot(lootIndex, raidIndex)
        end
      end
    end
  end
end

local function OnLootOpened(_, autoLoot, isFromItem)
  local lootmethod, masterlooterPartyID, _ = GetLootMethod()
  if (GetNumLootItems() > 0 and lootmethod == "master" and masterlooterPartyID == 0) then
    if isFromItem then
      -- Not doing this check can cause errors if an inventory item is looted while in master loot mode
      local guid, _ = GetLootSourceInfo(1)
      if not VGT:UnitNameFromGuid(guid, true) then
        -- 'isFromItem' seems to also be true for chests. Since there is a comprehensive list of chest items
        -- built-in, this can be used to look up whether we should export and auto loot or not.
        return
      end
    end
    ExportItems()
    if (autoLoot and VGT.OPTIONS.LOOTLIST.autoMasterLoot) then
      AutoMasterLoot()
    end
  end
end

VGT:RegisterEvent("LOOT_OPENED", OnLootOpened)
