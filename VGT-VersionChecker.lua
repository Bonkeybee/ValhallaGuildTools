---@class VersionCheckerModule : Module
local versionChecker = VGT:NewModule("versionChecker")

versionChecker.latestVersion = VGT.version

function versionChecker:GET_VERSION(_, sender)
  local version = VGT.version or ""
  VGT.LogTrace("Responding to version request from %s with version %s", sender, version)
  VGT:SendPlayerAddonCommand(sender, VGT.Commands.VERSION_RESPOND, version)
end

function versionChecker:VERSION_RESPOND(_, sender, version)
  if not UnitIsUnit(sender, "player") then
    VGT.LogTrace("Recieved addon version response from %s (%s)", sender, version)
    if type(version) == "number" and version > self.latestVersion then
      self.latestVersion = version
      VGT.LogWarning("there is a newer version of this addon (%s)", version)
    end
  end
end

function versionChecker:OnEnable()
  self:RegisterCommand(VGT.Commands.GET_VERSION)
  self:RegisterCommand(VGT.Commands.VERSION_RESPOND)
end
