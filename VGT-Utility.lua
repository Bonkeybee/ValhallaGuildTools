---@param perc number
---@param ... number
---@return number r, number g, number b
local function colorGradient(perc, ...)
  if perc >= 1 then
    local r, g, b = select(select("#", ...) - 2, ...)
    return r, g --[[@as number]], b --[[@as number]]
  elseif perc <= 0 then
    local r, g, b = ...
    return r, g, b
  end
  local num = select("#", ...) / 3
  local segment, relperc = math.modf(perc * (num - 1))
  local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)
  return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

---Converts RGB magnitude valus to their hexadecimal representation
---@param r number 0-1 red value
---@param g number 0-1 green value
---@param b number 0-1 blue value
---@return string result Hexadecimal string representation of the color
function VGT.RGBToHex(r, g, b)
  r = r <= 1 and r >= 0 and r or 0
  g = g <= 1 and g >= 0 and g or 0
  b = b <= 1 and b >= 0 and b or 0
  return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

---Converts a percentage value to a hexadecimal representation of a color gradient from red to green
---@param percentage number
---@return string
function VGT.GetColorGradientHex(percentage)
  return VGT.RGBToHex(colorGradient(percentage, 1, 0, 0, 1, 1, 0, 0, 1, 0))
end

---Rounds a number to a specified decimal
---@param number integer
---@param decimals integer|nil
---@return string
function VGT.Round(number, decimals)
  local fmt
  if decimals == nil or decimals <= 0 then
    fmt = "%.0f"
  elseif decimals == 1 then
    fmt = "%.1f"
  elseif decimals == 2 then
    fmt = "%.2f"
  else
    fmt = string.format("%%.%df", decimals)
  end
  return string.format(fmt, number or 0)
end

---@alias ItemRestriction boolean|table<string, true>

---@type table<integer|string,ItemRestriction>
VGT.overrideEquipTable = {}
local classesPrefix = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.*)")

---@private
---@param itemId integer|string
---@return ItemRestriction
function VGT:BuildRestrictions(itemId)
  VGTScanningTooltip:ClearLines()
  VGTScanningTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
  for i = 1, VGTScanningTooltip:NumLines() do
    local line = _G["VGTScanningTooltipTextLeft" .. i]
    local text = line and line:GetText() or ""
    text = string.match(text, classesPrefix)
    if text then
      local overrides = {}
      local classes = {}
      for i = 1, GetNumClasses() do
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

---@private
---@param itemId integer|string
---@return ItemRestriction
function VGT:GetClassRestrictions(itemId)
  local overrideResult = VGT.overrideEquipTable[itemId]
  if not overrideResult then
    overrideResult = self:BuildRestrictions(itemId)
    VGT.overrideEquipTable[itemId] = overrideResult
  end
  return overrideResult
end

---@class RestrictionLevel
---@field [integer|string|"*"] RestrictionLevel|boolean

---@type table<integer, RestrictionLevel|boolean>
VGT.equipTable = {
  [Enum.ItemClass.Consumable] = true,
  [Enum.ItemClass.Container] = {
    [0] = true, -- Bag
    [1] = {
      WARLOCK = true
    }, -- Soul Bag
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
      ["*"] = {
        DEATHKNIGHT = true,
        HUNTER = true,
        PALADIN = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      }, -- 1h axe
      INVTYPE_WEAPONOFFHAND = {
        DEATHKNIGHT = true,
        HUNTER = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      } -- oh axe
    },
    [Enum.ItemWeaponSubclass.Axe2H] = {
      DEATHKNIGHT = true,
      HUNTER = true,
      PALADIN = true,
      SHAMAN = true,
      WARRIOR = true
    }, -- 2h axe
    [Enum.ItemWeaponSubclass.Bows] = {
      HUNTER = true,
      ROGUE = true,
      WARRIOR = true
    }, -- bow
    [Enum.ItemWeaponSubclass.Guns] = {
      HUNTER = true,
      ROGUE = true,
      WARRIOR = true
    }, -- gun
    [Enum.ItemWeaponSubclass.Mace1H] = {
      ["*"] = {
        DEATHKNIGHT = true,
        DRUID = true,
        PALADIN = true,
        PRIEST = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      }, -- 1h mace
      INVTYPE_WEAPONOFFHAND = {
        DEATHKNIGHT = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      } -- oh mace
    },
    [Enum.ItemWeaponSubclass.Mace2H] = {
      DEATHKNIGHT = true,
      DRUID = true,
      PALADIN = true,
      SHAMAN = true,
      WARRIOR = true
    }, -- 2h mace
    [Enum.ItemWeaponSubclass.Polearm] = {
      DEATHKNIGHT = true,
      DRUID = true,
      HUNTER = true,
      PALADIN = true,
      WARRIOR = true
    }, -- polearm
    [Enum.ItemWeaponSubclass.Sword1H] = {
      ["*"] = {
        DEATHKNIGHT = true,
        HUNTER = true,
        MAGE = true,
        PALADIN = true,
        ROGUE = true,
        WARLOCK = true,
        WARRIOR = true
      }, -- 1h sword
      INVTYPE_WEAPONOFFHAND = {
        DEATHKNIGHT = true,
        HUNTER = true,
        ROGUE = true,
        WARRIOR = true
      } -- oh sword
    },
    [Enum.ItemWeaponSubclass.Sword2H] = {
      DEATHKNIGHT = true,
      HUNTER = true,
      PALADIN = true,
      WARRIOR = true
    }, -- 2h sword
    [Enum.ItemWeaponSubclass.Warglaive] = false,
    [Enum.ItemWeaponSubclass.Staff] = {
      DRUID = true,
      HUNTER = true,
      MAGE = true,
      PRIEST = true,
      SHAMAN = true,
      WARLOCK = true,
      WARRIOR = true
    }, -- staff
    [Enum.ItemWeaponSubclass.Bearclaw] = false, -- bearclaw
    [Enum.ItemWeaponSubclass.Catclaw] = false, -- catclaw
    [Enum.ItemWeaponSubclass.Unarmed] = {
      ["*"] = {
        DRUID = true,
        HUNTER = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      }, -- 1h unarmed
      INVTYPE_WEAPONOFFHAND = {
        HUNTER = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      } -- oh unarmed
    },
    [Enum.ItemWeaponSubclass.Generic] = true, -- generic
    [Enum.ItemWeaponSubclass.Dagger] = {
      ["*"] = {
        DRUID = true,
        HUNTER = true,
        MAGE = true,
        PRIEST = true,
        ROGUE = true,
        SHAMAN = true,
        WARLOCK = true,
        WARRIOR = true
      }, -- 1h dagger
      INVTYPE_WEAPONOFFHAND = {
        HUNTER = true,
        ROGUE = true,
        SHAMAN = true,
        WARRIOR = true
      } -- oh dagger
    },
    [Enum.ItemWeaponSubclass.Thrown] = {
      HUNTER = true,
      ROGUE = true,
      WARRIOR = true
    }, -- thrown
    [Enum.ItemWeaponSubclass.Obsolete3] = false, -- spear
    [Enum.ItemWeaponSubclass.Crossbow] = {
      HUNTER = true,
      ROGUE = true,
      WARRIOR = true
    }, -- crossbow
    [Enum.ItemWeaponSubclass.Wand] = {
      MAGE = true,
      PRIEST = true,
      WARLOCK = true
    }, -- wand
    [Enum.ItemWeaponSubclass.Fishingpole] = true -- fishing pole
  },
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.Armor] = {
    [Enum.ItemArmorSubclass.Generic] = true,
    [Enum.ItemArmorSubclass.Cloth] = true,
    [Enum.ItemArmorSubclass.Leather] = {
      DEATHKNIGHT = true,
      DRUID = true,
      HUNTER = true,
      PALADIN = true,
      ROGUE = true,
      SHAMAN = true,
      WARRIOR = true
    },
    [Enum.ItemArmorSubclass.Mail] = {
      DEATHKNIGHT = true,
      HUNTER = true,
      PALADIN = true,
      SHAMAN = true,
      WARRIOR = true
    },
    [Enum.ItemArmorSubclass.Plate] = {
      DEATHKNIGHT = true,
      PALADIN = true,
      WARRIOR = true
    },
    [Enum.ItemArmorSubclass.Cosmetic] = true,
    [Enum.ItemArmorSubclass.Shield] = {
      PALADIN = true,
      SHAMAN = true,
      WARRIOR = true
    },
    [Enum.ItemArmorSubclass.Libram] = {
      PALADIN = true
    },
    [Enum.ItemArmorSubclass.Idol] = {
      DRUID = true
    },
    [Enum.ItemArmorSubclass.Totem] = {
      SHAMAN = true
    },
    [Enum.ItemArmorSubclass.Sigil] = {
      DEATHKNIGHT = true
    },
    [Enum.ItemArmorSubclass.Relic] = {
      DEATHKNIGHT = true,
      DRUID = true,
      PALADIN = true,
      SHAMAN = true
    }
  },
  [Enum.ItemClass.Reagent] = true,
  [Enum.ItemClass.Projectile] = {
    HUNTER = true,
    ROGUE = true,
    WARRIOR = true
  },
  [Enum.ItemClass.Tradegoods] = true,
  [Enum.ItemClass.ItemEnhancement] = true,
  [Enum.ItemClass.Recipe] = true,
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.CurrencyTokenObsolete] = false,
  [Enum.ItemClass.Quiver] = {
    HUNTER = true,
    ROGUE = true,
    WARRIOR = true
  },
  [Enum.ItemClass.Questitem] = true,
  [Enum.ItemClass.Key] = true,
  [Enum.ItemClass.Gem] = true,
  [Enum.ItemClass.PermanentObsolete] = false,
  [Enum.ItemClass.Miscellaneous] = true,
  [Enum.ItemClass.Glyph] = {
    [1] = {
      WARRIOR = true
    },
    [2] = {
      PALADIN = true
    },
    [3] = {
      HUNTER = true
    },
    [4] = {
      ROGUE = true
    },
    [5] = {
      PRIEST = true
    },
    [6] = {
      DEATHKNIGHT = true
    },
    [7] = {
      SHAMAN = true
    },
    [8] = {
      MAGE = true
    },
    [9] = {
      WARLOCK = true
    },
    [11] = {
      DRUID = true
    }
  },
  [Enum.ItemClass.Battlepet] = true,
  [Enum.ItemClass.WoWToken] = true
}

---@private
---@param source RestrictionLevel|boolean
---@param levels (string|integer)[]
---@param level integer
---@param playerClass string
---@return boolean|nil
local function GetNextLevel(source, levels, level, playerClass)
  if type(source) ~= "table" then
    VGT.LogTrace("Level %s was %s; returning as value", level, source)
    return source --[[@as boolean]]
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

---Gets a value indicating whether an item is equippable by a class.
---@param item string|integer The id, name, or link for an item.
---@param playerClass string|nil
---@return boolean|nil
function VGT:Equippable(item, playerClass)
  local itemId, _, _, equipLocId, _, classId, subclassId = GetItemInfoInstant(item)
  playerClass = playerClass or UnitClassBase("player")
  VGT.LogTrace("Equippable invoked. equipLocId = %s; classId = %s; subclassId = %s; playerClass = %s", equipLocId, classId, subclassId, playerClass)

  local classRestrictions = self:GetClassRestrictions(itemId)
  if classRestrictions == true then
    return GetNextLevel(self.equipTable, {classId, subclassId, equipLocId}, 1, playerClass)
  else
    VGT.LogTrace("Found class restrictions for item #%s", itemId)
    return classRestrictions[playerClass]
  end
end

---Shows a confirmation dialog, then runs an action if it was confirmed.
---@param func fun() The function to run if an `ACCEPT` button is clicked.
---@param text string|nil The text to show in the dialog. If `nil`, the default confirmation text is used.
function VGT:Confirm(func, text)
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
  dlg.text = text or CONFIRM_CONTINUE
  StaticPopup_Show(dialogId)
end

---Shows an input dialog
---@param title string The title of the dialog
---@param text string The initial text in the dialog
---@param callback fun(text:string)|nil The callback for when the dialog closes with an `OKAY` button. When nil, no `OKAY` button is shown.
function VGT:ShowInputDialog(title, text, callback)
  local dialogId = "VLL_INPUT_DIALOG"
  local dlg = StaticPopupDialogs[dialogId]
  if not dlg then
    local function NOP()
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
      editBox:HighlightText(0, -1)

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

---@type table<integer, integer>
local reverseClassLookup = {}

for k, v in pairs(classLookup) do
  reverseClassLookup[v] = k
end

local raceLookup = {
  [1] = 0, -- Human
  [3] = 1, -- Dwarf
  [4] = 2, -- NightElf
  [7] = 3, -- Gnome
  [11] = 4 -- Draenei
}

---@param character JsonCharacter
---@return string
function VGT:ColorizeCharacterName(character)
  local _, _, _, color = GetClassColor(select(2, self:CharacterClassInfo(character)))
  if not color then
    return character.Name
  else
    return "|c" .. color .. character.Name .. "|r"
  end
end

---@param character JsonCharacter
---@return string? className, string? classFile, number? classId
function VGT:CharacterClassInfo(character)
  return GetClassInfo(reverseClassLookup[character.Class])
end

---@return JsonCharacter[]
function VGT:GetCharacters()

  ---@param characters JsonCharacter[]
  ---@param id string
  local function insertCharacter(characters, id)
    local name, _ = UnitName(id)
    if (name) then
      local _, _, raceId = UnitRace(id)
      local _, _, classId = UnitClass(id)

      if (raceId and classId) then
        ---@class JsonCharacter
        local character = {
          Name = name,
          Class = classLookup[classId],
          Race = raceLookup[raceId]
        }
        table.insert(characters, character)
      end
    end
  end

  ---@type JsonCharacter[]
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
  return json.encode({
    Characters = self:GetCharacters()
  })
end

function VGT:ShowRaidStartExport()
  self:ShowInputDialog("Export Raid Start", VGT:ExportRaidStart())
end

function VGT:ExportKill(drops, characters, timestamp)
  return json.encode({
    Drops = drops,
    Characters = characters or self:GetCharacters(),
    Timestamp = timestamp
  })
end

function VGT:ShowKillExport(drops, characters, timestamp)
  self:ShowInputDialog("Export Kill", self:ExportKill(drops, characters, timestamp))
end
