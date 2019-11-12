ADDON_NAME, VGT = ...
VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
FRAME = CreateFrame("Frame")
ACE = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0")

-- ############################################################
-- ##### HELPERS ##############################################
-- ############################################################

function StringAppend(...)
	local args = {...}
	local str = ""
	for _,v in ipairs(args) do
		if (v ~= nil) then
			str = str..tostring(v)
		end
	end
	return str
end

function TableJoinToArray(a, b)
	local nt = {}
	for _,v in pairs(a) do
		nt[v] = v
	end
	for _,v in pairs(b) do
		nt[v] = v
	end
	return nt
end

function TableToString(t, d, sort)
	local s = ""

	if (t == nil) then
		return s
	end

	if (d == nil) then
		d = ","
	end

	if (sort == true) then
		table.sort(t)
		local nt = {}
		for _,v in pairs(t) do
			table.insert(nt, v)
		end
		table.sort(nt)
		t = nt
	end

	for _,v in pairs(t) do
		s = s..","..v
	end

	return string.sub(s, 2)
end

function TableContains(t, m)
	if (t == nil) then
		return false
	end

	for _,v in pairs(t) do
		if (v == m) then
			return true
		end
	end

	return false
end

function RandomUUID()
    local template ='xxxxxxxx'
    return string.gsub(template, '[xy]', function (c) local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb) return string.format('%x', v) end)
end

function GetMyGuildName()
	if (IsInGuild()) then
		return GetGuildInfo("player")
	else
		return nil
	end
end

function IsInMyGuild(playerName)
	if (playerName == nil) then
		return false
	end

	local playerGuildName = GetGuildInfo(playerName)
	if (playerGuildName == nil) then
		return false
	end

	local myGuildName = GetMyGuildName()
	if (myGuildName == nil) then
		return false
	end

	if (myGuildName == playerGuildName) then
		return true
	end

	return false
end

function CheckGroupForGuildies()
	if (IsInGroup() ~= true) then
		return nil
	end

	local groupMembers = GetHomePartyInfo()
	local guildGroupMembers = {}
	local p = 0
	for i = 0, GetNumGroupMembers() do
		local groupMember = groupMembers[i]
		if (IsInMyGuild(groupMember)) then
			guildGroupMembers[p] = groupMember
			VGT.Log(VGT.LOG_TYPE.INFO, "%s is in my guild", guildGroupMembers[p])
			p = p + 1
		end
	end
	return guildGroupMembers
end

function PrintAbout()
	VGT.Log(VGT.LOG_TYPE.SYSTEM, "installed version: %s", VERSION)
end


-- ############################################################
-- ##### SLASH COMMANDS #######################################
-- ############################################################

SLASH_VGT1 = "/vgt"
SlashCmdList["VGT"] = function(message)
	local command, arg1 = strsplit(" ", message)

	if (command == "about") then
		PrintAbout()
	elseif (command == "loglevel") then
		VGT.SetLogLevel(arg1)
	elseif (command == "eptest") then
		HandleUnitDeath("TEST"..RandomUUID(), "TestDungeon", "TestBoss")
	elseif (command == "dungeons") then
		PrintDungeonList(tonumber(arg1), VGT.debug)
	else
		VGT.Log(VGT.LOG_TYPE.SYSTEM, "Command List:")
		VGT.Log(VGT.LOG_TYPE.SYSTEM, "/vgt about - displays version information about the addon")
		VGT.Log(VGT.LOG_TYPE.SYSTEM, "/vgt loglevel <%s> - changes the verbosity of addon messages", TableToString(VGT.LOG_TYPES, "|"))
		VGT.Log(VGT.LOG_TYPE.SYSTEM, "/vgt dungeontest - sends a dungeon kill test event")
		VGT.Log(VGT.LOG_TYPE.SYSTEM, "/vgt dungeons [timeframeInDays:7] - prints the list of players that killed a dungeon boss within the timeframe")
	end
end
