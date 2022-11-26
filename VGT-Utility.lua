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

VGT.overrideEquipTable = {}
local classesPrefix = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.*)")

local function BuildRestrictions(itemId)
  VGTAutoTradeScanningTooltip:ClearLines()
  VGTAutoTradeScanningTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
  for i=1,VGTAutoTradeScanningTooltip:NumLines() do
      local line = _G["VGTAutoTradeScanningTooltipTextLeft"..i]
      local text = line and line:GetText() or ""
      text = string.match(text, classesPrefix)
      if text then
        local overrides = {}
        local classes = {}
        for i=1,GetNumClasses() do
          local name, fileName = GetClassInfo(i)
          if name and fileName then
            classes[name] = fileName
          end
        end
        for class in string.gmatch(text, "([%a]+[ ]?[%a]*)[, ]?") do
          overrides[classes[class]] = true
        end
        return overrides
      end
  end
  return true
end

local function GetClassRestrictions(itemId)
  local overrideResult = VGT.overrideEquipTable[itemId]
  if not overrideResult then
    overrideResult = BuildRestrictions(itemId)
    VGT.overrideEquipTable[itemId] = overrideResult
  end
  return overrideResult
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

  local classRestrictions = GetClassRestrictions(itemId)
  if classRestrictions == true then
    return GetNextLevel(self.equipTable, { classId, subclassId, equipLocId }, 1, playerClass)
  else
    VGT.LogTrace("Found class restrictions for item #%s", itemId)
    return classRestrictions[playerClass]
  end
end

function VGT:Confirm(func)
  local dialogId = "VLL_CONFIRM_DIALOG"
  local dlg = StaticPopupDialogs[dialogId]
  if not dlg then
    dlg = {
      text = CONFIRM_CONTINUE,
      button1 = ACCEPT,
      button2 = CANCEL,
      hideOnEscape = true
    }
    StaticPopupDialogs[dialogId] = dlg
  end
  dlg.OnAccept = func
  StaticPopup_Show(dialogId)
end

function VGT:ShowInputDialog(title, text, callback)
  local dialogId = "VLL_INPUT_DIALOG"
  local dlg = StaticPopupDialogs[dialogId]
  if not dlg then
    local function NOP()
      return
    end
    dlg = {
      hasEditBox = 1,
      hasWideEditBox = 1,
      editBoxWidth = 350,
      preferredIndex = 3,
      OnHide = NOP,
      OnAccept = NOP,
      OnCancel = NOP,
      timeout = 0,
      whileDead = 1,
      hideOnEscape = 1
    }
    function dlg:EditBoxOnEscapePressed()
      self:GetParent():Hide()
    end
    function dlg:OnAccept()
      local dlg = StaticPopupDialogs[dialogId]
      if dlg.callback then
        local editBox = _G[self:GetName() .. "WideEditBox"] or _G[self:GetName() .. "EditBox"]
        dlg.callback(editBox:GetText())
      end
    end
    function dlg:OnShow()
      local dlg = StaticPopupDialogs[dialogId]

      self:SetWidth(420)

      local editBox = _G[self:GetName() .. "WideEditBox"] or _G[self:GetName() .. "EditBox"]
      editBox:SetText(dlg.inputText or "")
      editBox:SetFocus()
      editBox:HighlightText(false)

      if not dlg.callback then
        local button = _G[self:GetName() .. "Button2"]
        button:ClearAllPoints()
        button:SetWidth(200)
        button:SetPoint("CENTER", editBox, "CENTER", 0, -30)
      end
    end
    StaticPopupDialogs[dialogId] = dlg
  end
  
  dlg.text = title
  dlg.inputText = text

  if callback then
    dlg.callback = callback
    dlg.button1 = OKAY
    dlg.button2 = CANCEL
  else
    dlg.callback = nil
    dlg.button1 = nil
    dlg.button2 = CLOSE
  end

  StaticPopup_Show(dialogId)
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
