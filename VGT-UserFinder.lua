local userFinder = VGT:NewModule("userFinder")

local REQUEST_VERSION_MESSAGE = "ReqV"
local RESPOND_VERSION_MESSAGE = "ResV"

userFinder.results = {}
userFinder.enumerating = false

function userFinder:EnumerateUsers(callback, wait, group)
  if (self.enumerating) then
    return
  end

  if (IsInGuild()) then
    VGT.LogSystem("Requesting addon user info...")
    self.enumerating = true
    self:RegisterCommand(VGT.Commands.VERSION_RESPOND)

    if group then
      VGT:SendGroupAddonCommand(VGT.Commands.GET_VERSION)
    else
      VGT:SendGuildAddonCommand(VGT.Commands.GET_VERSION)
    end
  
    C_Timer.After(wait or 3, function()
      callback(self.results)
      self.enumerating = false
      self.results = {}
      self:UnregisterCommand(VGT.Commands.VERSION_RESPOND)
    end)
  else
    VGT.LogError("You are not in a guild.")
  end
end

function userFinder:PrintUserCount(by)
  if not self.enabledState then
    VGT.LogWarning("User Finder module is disabled.")
  end
  self:EnumerateUsers(function(results)
    if (by == "version") then
      local versions = {}
  
      for player, version in pairs(results) do
        local versionPlayers = versions[version]
        if (not versionPlayers) then
          versionPlayers = {}
          versions[version] = versionPlayers
        end
        versionPlayers[#versionPlayers + 1] = player
      end
  
      table.sort(versions)
  
      for version, versionUsers in pairs(versions) do
        table.sort(versionUsers)
  
        local report = string.format("Version %s: ", version)
  
        for i, player in ipairs(versionUsers) do
          if (i > 1) then
            report = string.format("%s, %s", report, player)
          else
            report = report .. player
          end
        end
  
        VGT.LogSystem(report)
      end
    elseif (by == "name") then
      local players = {}
  
      for player, _ in pairs(results) do
        players[#players + 1] = player
      end
  
      table.sort(players)
      local report = "Players using VGT: "
  
      for i, player in ipairs(players) do
        if (i > 1) then
          report = string.format("%s, %s", report, player)
        else
          report = report .. player
        end
      end
  
      VGT.LogSystem(report)
    else
      local usersCount = 0
      local usingThisVersionCount = 0
  
      for _, value in pairs(results) do
        usersCount = usersCount + 1
  
        if (value == VGT.version) then
          usingThisVersionCount = usingThisVersionCount + 1
        end
      end
      VGT.LogSystem(
        "%d players are using the addon, and %d are using the same version as you.",
        usersCount,
        usingThisVersionCount
      )
    end
  end)
end

function userFinder:VERSION_RESPOND(_, sender, version)
  if self.enumerating and version then
    VGT.LogTrace("Gathered user finder version response from %s", sender)
    self.results[sender] = version
  end
end
