--TODO need to add unlock timer

local _, class = UnitClass("player")
if (class == "PALADIN") then
  local RandomFun = CreateFrame("Frame")

  local MIN_DELAY = 450
  local MAX_DELAY = 900
  local ASH_PHRASE_START = 1
  local ASH_PHRASE_END = 12

  local delay = random(MIN_DELAY, MAX_DELAY)
  function RandomFun:onUpdate(sinceLastUpdate, lastPhrase)
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate
    if (not InCombatLockdown() and self.sinceLastUpdate >= delay) then
      if (VGT_OPTIONS.FUN.enabled) then
        local phrase = random(ASH_PHRASE_START, ASH_PHRASE_END)
        while phrase == lastPhrase do
          phrase = random(ASH_PHRASE_START, ASH_PHRASE_END)
        end
        PlaySoundFile("Interface\\AddOns\\ValhallaGuildTools\\Sounds\\Ashbringer\\"..phrase.."q.ogg", "Master")
        self.lastPhrase = phrase
      end
      self.sinceLastUpdate = 0
      delay = random(MIN_DELAY, MIN_DELAY)
    end
  end

  RandomFun:SetScript("OnUpdate", function(_, sinceLastUpdate) RandomFun:onUpdate(sinceLastUpdate, 0) end)
end
