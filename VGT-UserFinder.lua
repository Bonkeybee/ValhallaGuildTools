local REQUEST_VERSION_MESSAGE = "ReqV"
local RESPOND_VERSION_MESSAGE = "ResV"

VGT.userFinder = { results = {}, enumerating = false }

function VGT.userFinder:EnumerateUsers(callback, wait)
  if (self.enumerating) then
    return
  end
  self.enumerating = true

  if (IsInGuild()) then
    VGT.LogSystem("Requesting addon user info...")
    VGT:SendGuildAddonCommand(VGT.Commands.GET_VERSION)
  
    C_Timer.After(wait or 3, function()
      callback(VGT.userFinder.results)
      VGT.userFinder.enumerating = false
      VGT.userFinder.results = {}
    end)
  else
    VGT.LogError("You are not in a guild.")
  end
end

function VGT.userFinder:PrintUserCount(by)
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

VGT:RegisterCommandHandler(VGT.Commands.VERSION_RESPOND, function(sender, version)
  if VGT.userFinder.enumerating and version then
    VGT.LogTrace("Gathered user finder version response from %s", sender)
    VGT.userFinder.results[sender] = version
  end
end)
