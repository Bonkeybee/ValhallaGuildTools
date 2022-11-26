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
