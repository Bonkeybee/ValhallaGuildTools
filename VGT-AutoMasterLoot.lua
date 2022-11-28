local autoMasterLoot = VGT:NewModule("autoMasterLoot")

function autoMasterLoot:ShouldIgnore(ignores, link)
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

function autoMasterLoot:GetAutoMasterLootTarget(ignores, lootIndex)
  local quality, locked = select(5, GetLootSlotInfo(lootIndex))
  if locked or not quality or quality > 4 then
    return
  end
  if self:ShouldIgnore(ignores, GetLootSlotLink(lootIndex)) then
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

function autoMasterLoot:Run()
  VGT.LogTrace("Auto masterlooting")
  local ignores = {strsplit(";", self.profile.ignoredItems or "")}
  for lootIndex = 1, GetNumLootItems() do
    local target = self:GetAutoMasterLootTarget(ignores, lootIndex)
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

function autoMasterLoot:VGT_MASTER_LOOT_READY(_, autoLoot)
  if autoLoot then
    self:Run()
  end
end

function autoMasterLoot:OnEnable()
  self:RegisterMessage("VGT_MASTER_LOOT_READY")
end
