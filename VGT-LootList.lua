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

function VGT:ColorizeCharacterName(character)
  local _, _, _, color = GetClassColor(select(2, self:CharacterClassInfo(character)))
  if not color then
    return character.Name
  else
    return "|c" .. color .. character.Name .. "|r"
  end
end

function VGT:CharacterClassInfo(character)
  return GetClassInfo(reverseClassLookup[character.Class])
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
  self:ShowInputDialog("Export Raid Start", VGT:ExportRaidStart())
end

function VGT:ExportKill(items, characters)
  return json.encode({ Items = items, Characters = characters or self:GetCharacters() })
end

function VGT:ShowKillExport(items, characters)
  self:ShowInputDialog("Export Kill", self:ExportKill(items, characters))
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
  local quality, locked = select(5, GetLootSlotInfo(lootIndex))
  if locked or not quality or quality > 4 then
    return
  end
  if ShouldIgnore(ignores, GetLootSlotLink(lootIndex)) then
    return
  end

  local target

  if quality < 4 then
    target = VGT.db.char.autoMasterLoot.disenchantTarget
    if UnitExists(target) then
      return target
    end
  end

  target = VGT.db.char.autoMasterLoot.target
  if UnitExists(target) then
    return target
  end

  return UnitName("player")
end

local function AutoMasterLoot()
  VGT.LogTrace("Auto masterlooting")
  local ignores = { strsplit(";", VGT.db.profile.autoMasterLoot.ignoredItems or "") }
  for lootIndex = 1, GetNumLootItems() do
    local target = GetAutoMasterLootTarget(ignores, lootIndex)
    if target then
      for raidIndex = 1, 40 do
        if (GetMasterLootCandidate(lootIndex, raidIndex) == target) then
          VGT.LogTrace("Giving %s to %s", GetLootSlotLink(lootIndex), target)
          GiveMasterLoot(lootIndex, raidIndex)
        end
      end
    end
  end
end

VGT:RegisterEvent("LOOT_READY", function(_, autoLoot)
  local lootmethod, masterlooterPartyID, _ = GetLootMethod()
  if (GetNumLootItems() > 0 and lootmethod == "master" and masterlooterPartyID == 0) then
    local guid = GetLootSourceInfo(1)
    if guid then
      local sourceType = strsplit("-", guid, 2)
      if sourceType ~= "Item" then
        VGT.masterLooter:TrackLoot()
        if (autoLoot and VGT.db.profile.autoMasterLoot.enabled) then
          AutoMasterLoot()
        end
      end
    end
  end
end)
