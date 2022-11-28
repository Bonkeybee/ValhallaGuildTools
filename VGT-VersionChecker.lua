local versionChecker = VGT:NewModule("versionChecker")

versionChecker.warnedPlayers = {}
versionChecker.warned = false

function versionChecker:GET_VERSION(_, sender, version)
  version = tonumber(version)
  if not version or (not self.warnedPlayers[sender] and not UnitIsUnit(sender, "player") and version < tonumber(VGT.version)) then
    VGT.LogTrace("Responding to version request from %s. Their version: %s; our version: %s", sender, version, VGT.version)
    VGT:SendPlayerAddonCommand(sender, VGT.Commands.VERSION_RESPOND, VGT.version)
    self.warnedPlayers[sender] = true
  end
end

function versionChecker:VERSION_RESPOND(_, sender, version)
  if not UnitIsUnit(sender, "player") then
    VGT.LogTrace("Recieved addon version response from %s (%s)", sender, version)
    if not self.warned and version and tonumber(VGT.version) < tonumber(version) then
      VGT.LogWarning("there is a newer version of this addon (%s < %s)", VGT.version, version)
      self.warned = true
    end
  end
end

function versionChecker:OnEnable()
  self:RegisterCommand(VGT.Commands.GET_VERSION)
  self:RegisterCommand(VGT.Commands.VERSION_RESPOND)
end
