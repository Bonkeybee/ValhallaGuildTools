local warnedPlayers = {}
local warned = false

function VGT:CheckVersion()
  if (IsInGuild()) then
    self.LogTrace("Requesting addon version from guild")
    self:SendGuildAddonCommand("GV", self.version)
  end
end

VGT:RegisterCommandHandler("GV", function(sender, version)
  version = tonumber(version)
  if not version or (not warnedPlayers[sender] and not UnitIsUnit(sender, "player") and version < tonumber(VGT.version)) then
    VGT.LogTrace("Responding to version request from %s. Their version: %s; our version: %s", sender, version or "unspecified", VGT.version)
    VGT:SendPlayerAddonCommand(sender, "VR", VGT.version)
    warnedPlayers[sender] = true
  end
end)

VGT:RegisterCommandHandler("VR", function(sender, version)
  if not UnitIsUnit(sender, "player") then
    VGT.LogTrace("Recieved addon version response from %s (%s)", sender, version)
    if not warned and version and tonumber(VGT.version) < tonumber(version) then
      VGT.LogWarning("there is a newer version of this addon (%s < %s)", myVersion, theirVersion)
      warned = true
    end
  end
end)

VGT:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUI)
  if (isInitialLogin or isReloadingUI) then
    VGT.LogTrace("initialized with version %s", VGT.version)
    GuildRoster()
    VGT:CheckVersion()
  end
end)
