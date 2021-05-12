function VGT.PrintAbout()
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "installed version: %s", VGT.VERSION)
end

function VGT.PrintHelp()
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "Command List:")
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "/vgt about - version information")
  VGT.Log(VGT.LOG_LEVEL.SYSTEM, "/vgt options - opens the VGT options window")
  VGT.Log(
    VGT.LOG_LEVEL.SYSTEM,
    "/vgt users [by version] - shows how many people online in the guild are using the addon, and optionally lists their addon versions."
  )
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
    VGT.UserFinder:PrintUserCount(arg1 == "by" and arg2 or nil)
  else
    VGT.Log(VGT.LOG_LEVEL.ERROR, "invalid command - type `/vgt help` for a list of commands")
  end
end

SLASH_VGT1 = "/vgt"
