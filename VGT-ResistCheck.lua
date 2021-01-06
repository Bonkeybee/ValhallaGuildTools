local _, VGT = ...
local ResistCheck = {Results = {}, EnumeratingResists = false}
VGT.ResistCheck = ResistCheck

local REQUEST_RESIST_MESSAGE = "ReqR"
local RESPOND_RESIST_MESSAGE = "ResR"

local function OnCoreMessageReceived(message, sender)
  if (message == REQUEST_RESIST_MESSAGE) then
    local _, armorTotal = UnitResistance("PLAYER", 0)
    local _, holyTotal = UnitResistance("PLAYER", 1)
    local _, fireTotal = UnitResistance("PLAYER", 2)
    local _, natureTotal = UnitResistance("PLAYER", 3)
    local _, frostTotal = UnitResistance("PLAYER", 4)
    local _, shadowTotal = UnitResistance("PLAYER", 5)
    local _, arcaneTotal = UnitResistance("PLAYER", 6)
    local payload = armorTotal..":"..holyTotal..":"..fireTotal..":"..natureTotal..":"..frostTotal..":"..shadowTotal..":"..arcaneTotal
    VGT:SendCoreMessage(RESPOND_RESIST_MESSAGE .. payload, "WHISPER", sender)
  elseif (string.sub(message, 1, RESPOND_RESIST_MESSAGE:len()) == RESPOND_RESIST_MESSAGE) then
    local payload = string.sub(message, RESPOND_RESIST_MESSAGE:len() + 1)
    local armorTotal, holyTotal, fireTotal, natureTotal, frostTotal, shadowTotal, arcaneTotal = strsplit(":", payload)
    ResistCheck.Results[sender] = {}
    ResistCheck.Results[sender].armor = armorTotal
    ResistCheck.Results[sender].holy = holyTotal
    ResistCheck.Results[sender].fire = fireTotal
    ResistCheck.Results[sender].nature = natureTotal
    ResistCheck.Results[sender].frost = frostTotal
    ResistCheck.Results[sender].shadow = shadowTotal
    ResistCheck.Results[sender].arcane = arcaneTotal
  end
end

VGT.CoreMessageReceived:Add(OnCoreMessageReceived)

function ResistCheck:EnumerateResists(callback, wait)
  if (self.EnumeratingResists) then
    return
  end
  self.EnumeratingResists = true

  if (IsInRaid()) then
    VGT:SendCoreMessage(REQUEST_RESIST_MESSAGE, "RAID")
  end
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "Requesting resist info...")

  C_Timer.After(
    wait or 3,
    function()
      callback(ResistCheck.Results)
      self.EnumeratingResists = false
      ResistCheck.Results = {}
    end
  )
end

function ResistCheck:PrintResistsCallback(resist)
  -- if (resist == "frost") then
  --   local versions = {}
  --   local usersCount = 0
  --   local usingThisVersionCount = 0

  --   for _, value in pairs(self.Results) do
  --     usersCount = usersCount + 1

  --     if (value == VGT.VERSION) then
  --       usingThisVersionCount = usingThisVersionCount + 1
  --     end
  --   end
  --   VGT.Log(
  --     VGT.LOG_LEVEL.SYSTEM,
  --     "%d players are using the addon, and %d are using the same version as you.",
  --     usersCount,
  --     usingThisVersionCount
  --   )
  -- end
end

function ResistCheck:PrintRaidResists(resist)
  self:EnumerateResists(
    function()
      self:PrintResistsCallback(resist)
    end
  )
end
