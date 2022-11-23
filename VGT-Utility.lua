function VGT.ColorGradient(perc, ...)
  if perc >= 1 then
    local r, g, b = select(select("#", ...) - 2, ...)
    return r, g, b
  elseif perc <= 0 then
    local r, g, b = ...
    return r, g, b
  end
  local num = select("#", ...) / 3
  local segment, relperc = math.modf(perc * (num - 1))
  local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)
  return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

function VGT.RGBToHex(r, g, b)
  r = r <= 1 and r >= 0 and r or 0
  g = g <= 1 and g >= 0 and g or 0
  b = b <= 1 and b >= 0 and b or 0
  return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function VGT.Round(number, decimals)
  if (number == nil) then
    number = 0
  end
  if (decimals == nil) then
    decimals = 0
  end
  return (("%%.%df"):format(decimals)):format(number)
end

do
  VGT.overrideEquipTable = {}
  local ppw = { PALADIN = true, PRIEST = true, WARLOCK = true }
  local whs = { WARRIOR = true, HUNTER = true, SHAMAN = true }
  local rdmd = { ROGUE = true, DEATHKNIGHT = true, MAGE = true, DRUID = true }
  local ppwItems = { 40610, 40613, 40616, 40619, 40622, 40625, 40628, 40631, 40634, 40637, 45632, 45635, 45638, 45641, 45644, 45647, 45650, 45653, 45656, 45659, 47557, 52027, 52030 }
  local whsItems = { 40611, 40614, 40617, 40620, 40623, 40626, 40629, 40632, 40635, 40638, 45633, 45636, 45639, 45642, 45645, 45648, 45651, 45654, 45657, 45660, 47558, 52026, 52029 }
  local rdmdItems = { 40612, 40615, 40618, 40621, 40624, 40627, 40630, 40633, 40636, 40639, 45634, 45637, 45640, 45643, 45646, 45649, 45652, 45655, 45658, 45661, 47559, 52025, 52028 }
  local function AddOverrides(classes, items)
    for _,itemId in ipairs(items) do
      VGT.overrideEquipTable[itemId] = classes
    end
  end
  AddOverrides(ppw, ppwItems)
  AddOverrides(whs, whsItems)
  AddOverrides(rdmd, rdmdItems)
end

VGT.equipTable = {
  [Enum.ItemClass.Consumable] = true,
  [Enum.ItemClass.Container] = {
    [0] = true, -- Bag
    [1] = { WARLOCK = true }, -- Soul Bag
    [2] = true, -- Herb Bag
    [3] = true, -- Enchanting Bag
    [4] = true, -- Engineering Bag
    [5] = true, -- Gem Bag
    [6] = true, -- Mining Bag
    [7] = true, -- Leatherworking Bag
    [8] = true, -- Inscription Bag
    [9] = true, -- Tackle Box
    [10] = true -- Cooking Bag
  },
  [Enum.ItemClass.Weapon] = {
    [Enum.ItemWeaponSubclass.Axe1H] = {
      ["*"] = { DEATHKNIGHT = true, HUNTER = true, PALADIN = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- 1h axe
      INVTYPE_WEAPONOFFHAND = { DEATHKNIGHT = true, HUNTER = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- oh axe
    },
    [Enum.ItemWeaponSubclass.Axe2H] = { DEATHKNIGHT = true, HUNTER = true, PALADIN = true, SHAMAN = true, WARRIOR = true }, -- 2h axe
    [Enum.ItemWeaponSubclass.Bows] = { HUNTER = true, ROGUE = true, WARRIOR = true }, -- bow
    [Enum.ItemWeaponSubclass.Guns] = { HUNTER = true, ROGUE = true, WARRIOR = true }, -- gun
    [Enum.ItemWeaponSubclass.Mace1H] = {
      ["*"] = { DEATHKNIGHT = true, DRUID = true, PALADIN = true, PRIEST = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- 1h mace
      INVTYPE_WEAPONOFFHAND = { DEATHKNIGHT = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- oh mace
    },
    [Enum.ItemWeaponSubclass.Mace2H] = { DEATHKNIGHT = true, DRUID = true, PALADIN = true, SHAMAN = true, WARRIOR = true }, -- 2h mace
    [Enum.ItemWeaponSubclass.Polearm] = { DEATHKNIGHT = true, DRUID = true, HUNTER = true, PALADIN = true, WARRIOR = true }, -- polearm
    [Enum.ItemWeaponSubclass.Sword1H] = {
      ["*"] = { DEATHKNIGHT = true, HUNTER = true, MAGE = true, PALADIN = true, ROGUE = true, WARLOCK = true, WARRIOR = true }, -- 1h sword
      INVTYPE_WEAPONOFFHAND = { DEATHKNIGHT = true, HUNTER = true, ROGUE = true, WARRIOR = true }, -- oh sword
    },
    [Enum.ItemWeaponSubclass.Sword2H] = { DEATHKNIGHT = true, HUNTER = true, PALADIN = true, WARRIOR = true }, -- 2h sword
    [Enum.ItemWeaponSubclass.Warglaive] = false,
    [Enum.ItemWeaponSubclass.Staff] = { DRUID = true, HUNTER = true, MAGE = true, PRIEST = true, SHAMAN = true, WARLOCK = true, WARRIOR = true }, -- staff
    [Enum.ItemWeaponSubclass.Bearclaw] = false, -- bearclaw
    [Enum.ItemWeaponSubclass.Catclaw] = false, -- catclaw
    [Enum.ItemWeaponSubclass.Unarmed] = {
      ["*"] = { DRUID = true, HUNTER = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- 1h unarmed
      INVTYPE_WEAPONOFFHAND = { HUNTER = true, ROGUE = true, SHAMAN = true, WARRIOR = true } -- oh unarmed
    },
    [Enum.ItemWeaponSubclass.Generic] = true, -- generic
    [Enum.ItemWeaponSubclass.Dagger] = {
      ["*"] = { DRUID = true, HUNTER = true, MAGE = true, PRIEST = true, ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true }, -- 1h dagger
      INVTYPE_WEAPONOFFHAND = { HUNTER = true, ROGUE = true, SHAMAN = true, WARRIOR = true }, -- oh dagger
    },
    [Enum.ItemWeaponSubclass.Thrown] = { HUNTER = true, ROGUE = true, WARRIOR = true }, -- thrown
    [Enum.ItemWeaponSubclass.Obsolete3] = false, -- spear
    [Enum.ItemWeaponSubclass.Crossbow] = { HUNTER = true, ROGUE = true, WARRIOR = true }, -- crossbow
    [Enum.ItemWeaponSubclass.Wand] = { MAGE = true, PRIEST = true, WARLOCK = true }, -- wand
    [Enum.ItemWeaponSubclass.Fishingpole] = true -- fishing pole
  },
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.Armor] = {
    [Enum.ItemArmorSubclass.Generic] = true,
    [Enum.ItemArmorSubclass.Cloth] = true,
    [Enum.ItemArmorSubclass.Leather] = { DEATHKNIGHT = true, DRUID = true, HUNTER = true, PALADIN = true, ROGUE = true, SHAMAN = true, WARRIOR = true },
    [Enum.ItemArmorSubclass.Mail] = { DEATHKNIGHT = true, HUNTER = true, PALADIN = true, SHAMAN = true, WARRIOR = true },
    [Enum.ItemArmorSubclass.Plate] = { DEATHKNIGHT = true, PALADIN = true, WARRIOR = true },
    [Enum.ItemArmorSubclass.Cosmetic] = true,
    [Enum.ItemArmorSubclass.Shield] = { PALADIN = true, SHAMAN = true, WARRIOR = true },
    [Enum.ItemArmorSubclass.Libram] = { PALADIN = true },
    [Enum.ItemArmorSubclass.Idol] = { DRUID = true },
    [Enum.ItemArmorSubclass.Totem] = { SHAMAN = true },
    [Enum.ItemArmorSubclass.Sigil] = { DEATHKNIGHT = true },
    [Enum.ItemArmorSubclass.Relic] = { DEATHKNIGHT = true, DRUID = true, PALADIN = true, SHAMAN = true }
  },
  [Enum.ItemClass.Reagent] = true,
  [Enum.ItemClass.Projectile] = { HUNTER = true, ROGUE = true, WARRIOR = true },
  [Enum.ItemClass.Tradegoods] = true,
  [Enum.ItemClass.ItemEnhancement] = true,
  [Enum.ItemClass.Recipe] = true,
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.CurrencyTokenObsolete] = false,
  [Enum.ItemClass.Quiver] = { HUNTER = true, ROGUE = true, WARRIOR = true },
  [Enum.ItemClass.Questitem] = true,
  [Enum.ItemClass.Key] = true,
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.PermanentObsolete] = false,
  [Enum.ItemClass.Miscellaneous] = true,
  [Enum.ItemClass.Glyph] = {
    [1] = { WARRIOR = true },
    [2] = { PALADIN = true },
    [3] = { HUNTER = true },
    [4] = { ROGUE = true },
    [5] = { PRIEST = true },
    [6] = { DEATHKNIGHT = true },
    [7] = { SHAMAN = true },
    [8] = { MAGE = true },
    [9] = { WARLOCK = true },
    [11] = { DRUID = true }
  },
  [Enum.ItemClass.Battlepet] = true,
  [Enum.ItemClass.WoWToken] = true,
}

local function GetNextLevel(source, levels, level, playerClass)
  if type(source) ~= "table" then
    VGT.LogTrace("Level %s was %s; returning as value", level, source)
    return source
  end

  if source[playerClass] then
    VGT.LogTrace("Level %s had %q class override; returning true", level, playerClass)
    return true
  end
  
  if level > #levels then
    VGT.LogTrace("Level %s exceeds the maximum; returning false", level)
    return false
  end

  local nextLevel = levels[level]
  local nextSource = source[nextLevel]

  if nextSource then
    VGT.LogTrace("Found %s match at level %s", type(nextSource), level)
  else
    nextSource = source["*"]

    if nextSource then
      VGT.LogTrace("Found wildcard %s match at level %s", type(nextSource), level)
    else
      VGT.LogTrace("No match found for level %s", level)
      return
    end
  end

  return GetNextLevel(nextSource, levels, level + 1, playerClass)
end

function VGT:Equippable(item, playerClass)
  local itemId, _, _, equipLocId, _, classId, subclassId = GetItemInfoInstant(item)
  playerClass = playerClass or UnitClassBase("player")
  VGT.LogTrace("Equippable invoked. equipLocId = %s; classId = %s; subclassId = %s; playerClass = %s", equipLocId, classId, subclassId, playerClass)

  local overrideClasses = self.overrideEquipTable[itemId]
  if overrideClasses then
    VGT.LogTrace("Found override table for item #%s", itemId)
    return overrideClasses[playerClass]
  end
  return GetNextLevel(self.equipTable, { classId, subclassId, equipLocId }, 1, playerClass)
end
