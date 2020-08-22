local _, VGT = ...
local UserFinder = {Results = {}, EnumeratingUsers = false}
VGT.UserFinder = UserFinder

local REQUEST_VERSION_MESSAGE = "ReqV"
local RESPOND_VERSION_MESSAGE = "ResV"

local function OnCoreMessageReceived(message, sender)
  if (message == REQUEST_VERSION_MESSAGE) then
    VGT:SendCoreMessage(RESPOND_VERSION_MESSAGE .. VGT.VERSION, "WHISPER", sender)
  elseif (string.sub(message, 1, RESPOND_VERSION_MESSAGE:len()) == RESPOND_VERSION_MESSAGE) then
    UserFinder.Results[sender] = string.sub(message, RESPOND_VERSION_MESSAGE:len() + 1)
  end
end

VGT.CoreMessageReceived:Add(OnCoreMessageReceived)

function UserFinder:EnumerateUsers(callback, wait)
  if (self.EnumeratingUsers) then
    return
  end
  self.EnumeratingUsers = true

  if (IsInGuild()) then
    VGT:SendCoreMessage(REQUEST_VERSION_MESSAGE, "GUILD")
  end
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "Requesting addon user info...")

  C_Timer.After(
    wait or 3,
    function()
      callback(UserFinder.Results)
      self.EnumeratingUsers = false
      UserFinder.Results = {}
    end
  )
end

function UserFinder:PrintUserCountCallback(by)
  if (by == "version") then
    local versions = {}

    for player, version in pairs(self.Results) do
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

      VGT.Log(VGT.LOG_LEVEL.SYSTEM, report)
    end
  elseif (by == "name") then
    local players = {}

    for player, _ in pairs(self.Results) do
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

    VGT.Log(VGT.LOG_LEVEL.SYSTEM, report)
  else
    local usersCount = 0
    local usingThisVersionCount = 0

    for _, value in pairs(self.Results) do
      usersCount = usersCount + 1

      if (value == VGT.VERSION) then
        usingThisVersionCount = usingThisVersionCount + 1
      end
    end
    VGT.Log(
      VGT.LOG_LEVEL.SYSTEM,
      "%d players are using the addon, and %d are using the same version as you.",
      usersCount,
      usingThisVersionCount
    )
  end
end

function UserFinder:PrintUserCount(by)
  self:EnumerateUsers(
    function()
      self:PrintUserCountCallback(by)
    end
  )
end
