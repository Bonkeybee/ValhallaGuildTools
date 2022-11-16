function VGT.PrintAbout()
  VGT.LogSystem("installed version: %s", VGT.version)
end

function VGT.PrintHelp()
  VGT.LogSystem("Command List:")
  VGT.LogSystem("/vgt about - version information")
  VGT.LogSystem("/vgt options - opens the VGT options window")
  VGT.LogSystem("/vgt raidstart - shows raid start import code for loot masters")
  VGT.LogSystem("/vgt loot - shows the loot tracking window")
  VGT.LogSystem("/vgt users [by version] - shows how many people online in the guild are using the addon, and optionally lists their addon versions.")
end

-- ############################################################
-- ##### SLASH COMMANDS #######################################
-- ############################################################

SlashCmdList["VGT"] = function(message)
  local command, arg1, arg2 = strsplit(" ", message:lower())
  if (command == "" or command == "help") then
    VGT.PrintHelp()
  elseif (command == "options") then
    InterfaceOptionsFrame_OpenToCategory(VGT.menu)
    InterfaceOptionsFrame_OpenToCategory(VGT.menu)
  elseif (command == "about") then
    VGT.PrintAbout()
  elseif (command == "users") then
    VGT.userFinder:PrintUserCount(arg1 == "by" and arg2 or nil)
  elseif (command == "raidstart") then
    VGT:ShowRaidStartExport()
  elseif (command == "loot") then
    VGT.masterLooter:Toggle()
  else
    VGT.LogError("invalid command - type `/vgt help` for a list of commands")
  end
end

SLASH_VGT1 = "/vgt"
