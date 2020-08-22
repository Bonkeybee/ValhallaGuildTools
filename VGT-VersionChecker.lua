local _, VGT = ...
local VersionChecker = {WarnedPlayers = {}, Warned = false}
VGT.VersionChecker = VersionChecker

local function OnCoreMessageReceived(message, sender)
  if not UnitIsUnit(sender, "player") then
    local event, version = strsplit(":", message)
    if (event == "SYNCHRONIZATION_REQUEST") then
      if (not VersionChecker.WarnedPlayers[sender] and version ~= nil and tonumber(version) < tonumber(VGT.VERSION)) then
        VGT:SendCoreMessage("VERSION:" .. VGT.VERSION, "WHISPER", sender)
        VersionChecker.WarnedPlayers[sender] = true
      end
    elseif (event == "VERSION") then
      local myVersion = tonumber(VGT.VERSION)
      local theirVersion = tonumber(version)
      if (not VersionChecker.Warned and myVersion < theirVersion) then
        VGT.Log(VGT.LOG_LEVEL.WARN, "there is a newer version of this addon (%s < %s)", myVersion, theirVersion)
        VersionChecker.Warned = true
      end
    end
  end
end

function VersionChecker:Check()
  if (IsInGuild()) then
    VGT:SendCoreMessage("SYNCHRONIZATION_REQUEST:" .. VGT.VERSION, "GUILD")
  end
end

VGT.CoreMessageReceived:Add(OnCoreMessageReceived)
