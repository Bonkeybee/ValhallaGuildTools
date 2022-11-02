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

VGT.ClassLookup = {
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

VGT.RaceLookup = {
  [1] = 0, -- Human
  [3] = 1, -- Dwarf
  [4] = 2, -- NightElf
  [7] = 3, -- Gnome
  [11] = 4 -- Draenei
}

-- https://wowpedia.fandom.com/wiki/InstanceID
VGT.TrackedInstances = {
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
            Class = VGT.ClassLookup[classId],
            Race = VGT.RaceLookup[raceId]
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

local function GetSameItemCount(link)
  local count = 0

  for i = 1, GetNumLootItems() do
    if (link == GetLootSlotLink(i)) then
      count = count + 1
    end
  end

  return count
end

local function ShouldTrack(link)
  if (not link) then
    return false
  end

  if (VGT.OPTIONS.LOOTLIST.trackEverything) then
    return true
  end

  local _, _, itemQuality, _, _, itemType, _, _, _, _, _, classID = GetItemInfo(link)

  if (itemQuality == 4) then --epic only
    if (itemType == "Money") then
      return false
    end
    return classID == 2 or --weapon
        classID == 4 or --armor/jewelry
        classID == 15 --misc (tokens)
  end

  return false
end

local function ExportItems()
  local guid, _ = GetLootSourceInfo(1)
  local instanceId = select(4, strsplit("-", guid or ""))

  if (instanceId) then
    instanceId = tonumber(instanceId)
  end

  if (instanceId and (VGT.TrackedInstances[instanceId] or VGT.OPTIONS.LOOTLIST.trackEverything)) then
    local itemLinks = {}

    for i = 1, GetNumLootItems() do
      local link = GetLootSlotLink(i)
      if (ShouldTrack(link)) then
        tinsert(itemLinks, link)
      end
    end

    VGT.MasterLooter.TrackAllForCreature(guid, itemLinks)
  end
end

local function ShouldIgnore(ignores, link)
  local itemName, _ = GetItemInfo(link)
  for _, value in pairs(ignores) do
    local ignoreName, _ = GetItemInfo(value)
    if (ignoreName == itemName) then
      return true
    end
  end
end

local function GetAutoMasterLootTargetName()
  local target = VGT.OPTIONS.LOOTLIST.masterLootTarget
  if (target ~= nil) then
    return target
  end
  return UnitName("player")
end

local function AutoMasterLoot()
  local target = GetAutoMasterLootTargetName()
  local ignores = { strsplit(";", VGT.OPTIONS.LOOTLIST.ignoredItems or "") }
  tinsert(ignores, 22726) -- Splinter of Atiesh
  for lootIndex = 1, GetNumLootItems() do
    local _, _, _, _, _, locked = GetLootSlotInfo(lootIndex)
    if (not locked) then
      local link = GetLootSlotLink(lootIndex)
      if (link and not ShouldIgnore(ignores, link)) then
        for raidIndex = 1, 40 do
          if (GetMasterLootCandidate(lootIndex, raidIndex) == target) then
            GiveMasterLoot(lootIndex, raidIndex)
          end
        end
      end
    end
  end
end

local function OnLootOpened(_, autoLoot, isFromItem)
  if not isFromItem then
    local lootmethod, masterlooterPartyID, _ = GetLootMethod()
    if (GetNumLootItems() > 0 and lootmethod == "master" and masterlooterPartyID == 0) then
      ExportItems()
      if (autoLoot and VGT.OPTIONS.LOOTLIST.autoMasterLoot) then
        AutoMasterLoot()
      end
    end
  end
end

VGT:RegisterEvent("LOOT_OPENED", OnLootOpened)
