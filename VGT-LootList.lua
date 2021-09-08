local StaticPopupDialogs, StaticPopup_Show = StaticPopupDialogs, StaticPopup_Show
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

-- https://wowpedia.fandom.com/wiki/UiMapID
VGT.ZoneSetup = {
  magtheridonslair = {100, "Hellfire Peninsula", 331, "Magtheridon's Lair"},
  gruulslair = {105, "Blade's Edge Mountains", 330, "Gruul's Lair"},
  serpentshrinecavern = {102, "Zangarmarsh", 332, "Serpentshrine Cavern"},
  tempestkeep = {109, "Netherstorm", 334, "Tempest Keep", 1555},
  blacktemple = {104, "Shadowmoon Valley", 759, "Black Temple"},
  hyjalsummit = {
    329,
    "Hyjal Summit",
    1556,
    74,
    "Caverns of Time - Timeless Tunnel",
    75,
    "Caverns of Time - Caverns of Time",
    71,
    "Tanaris"
  },
  sunwellplateau = {
    122,
    "Isle of Quel'Danas",
    335,
    "Sunwell Plateau - Sunwell Plateau",
    336,
    "Sunwell Plateau - Shrine of the Eclipse",
    973,
    "The Sunwell"
  }
}

VGT.ZoneLookup = {}

for instanceId, zoneNames in pairs(VGT.ZoneSetup) do
  for _, zone in pairs(zoneNames) do
    VGT.ZoneLookup[zone] = instanceId
  end
end

VGT.ClassLookup = {
  [1] = 1, -- Warrior
  [2] = 2, -- Paladin
  [3] = 4, -- Hunter
  [4] = 8, -- Rogue
  [5] = 16, -- Priest
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

VGT.TrackedInstances = {
  [534] = true, -- Hyjal Summit
  [544] = true, -- Magtheridon's Lair
  [548] = true, -- Serpentshrine Cavern
  [550] = true, -- Tempest Keep
  [564] = true, -- Black Temple
  [565] = true, -- Gruul's Lair
  [580] = true -- Sunwell Plateau
}

function VGT:GetRaidId()
  return self.ZoneLookup[C_Map.GetBestMapForUnit("player")] or self.ZoneLookup[GetRealZoneText()] or ""
end

function VGT:GetCharacters()
  local characters = {}
  for i = 1, 40 do
    local id = "raid" .. i
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
  return characters
end

function VGT:ExportRaidStart()
  return json.encode({EncounterId = self:GetRaidId(), Characters = self:GetCharacters()})
end

function VGT:ShowRaidStartExport()
  self:ExportPopup("Export Raid Start", self:ExportRaidStart())
end

function VGT:ExportKill(items, characters)
  return json.encode({Items = items, Characters = characters or self:GetCharacters()})
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

local function ExportItems()
  local guid, _ = GetLootSourceInfo(1)
  local instanceId = select(4, strsplit("-", guid or ""))

  if (instanceId) then
    instanceId = tonumber(instanceId)
  end

  if (instanceId and (VGT.TrackedInstances[instanceId] or VGT.OPTIONS.LOOTLIST.trackEverything)) then
    local targetName, targetGuid = UnitName("target"), UnitGUID("target")
    if (guid ~= targetGuid) then
      targetName = "<Unknown>"
    end

    for i = 1, GetNumLootItems() do
      local _, _, _, _, quality = GetLootSlotInfo(i)
      local link = GetLootSlotLink(i)
      if (link and (quality == 4 or VGT.OPTIONS.LOOTLIST.trackEverything)) then
        VGT.LootListTracker:Add(guid, targetName, link, GetSameItemCount(link) or 1)
      end
    end
  end
end

local function ShouldIgnore(ignores, link)
  for _, value in pairs(ignores) do
    if (value) then
      if (value == link) then
        return true
      end
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
  local ignores = {strsplit(";", VGT.OPTIONS.LOOTLIST.ignoredItems or ""), "|cffa335ee|Hitem:30183::::::::70:::::::::|h[Nether Vortex]|h|r", "|cffff8000|Hitem:22726::::::::70:::::::::|h[Splinter of Atiesh]|h|r"}
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
  if (not isFromItem and VGT.OPTIONS.LOOTLIST.enabled) then
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
