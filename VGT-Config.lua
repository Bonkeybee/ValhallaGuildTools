local loaded = false
local LSM = LibStub("LibSharedMedia-3.0")

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function default(value, def)
  if (value == nil) then
    return def
  end
  return value
end

local function DefaultConfig(options)
  options = default(options, {})

  options.LOGGING = default(options.LOGGING, { enabled = false, level = VGT.LogLevel.INFO })

  options.MAP = default(options.MAP, {})
  options.MAP.enabled = default(options.MAP.enabled, true)
  options.MAP.sendMyLocation = default(options.MAP.sendMyLocation, true)
  options.MAP.showMinimapOutOfBounds = default(options.MAP.showMinimapOutOfBounds, false)
  if (options.MAP.mode == nil) then
    options.MAP.mode = "both"
    options.MAP.showMe = false
  else
    options.MAP.showMe = default(options.MAP.showMe, false)
  end

  options.LOOTLIST = default(options.LOOTLIST, {enabled = true, autoMasterLoot = true})
  options.LOOTLIST.ignoredItems = default(options.LOOTLIST.ignoredItems, "")
  options.LOOTLIST.X = default(options.LOOTLIST.X, 0)
  options.LOOTLIST.Y = default(options.LOOTLIST.Y, 0)
  options.LOOTLIST.Width = default(options.LOOTLIST.Width, 400)
  options.LOOTLIST.Height = default(options.LOOTLIST.Height, 240)
  options.LOOTLIST.Point = default(options.LOOTLIST.Point, "CENTER")

  options.MINIMAP = default(options.MINIMAP, {hide = false})

  options.AUTOTRADE = default(options.AUTOTRADE, {enabled=true})

  options.ROLL = default(options.ROLL, {enabled = true, X = 0, Y = 0, Point = "CENTER", Width = 400, Height = 240, sound = "Info" })

  return options
end

-- ############################################################
-- ##### OPTIONS ##############################################
-- ############################################################

--https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
local options = {
  type = "group",
  args = {
    general = {
      name = "General",
      type = "group",
      order = 1,
      args = {
        minimap = {
          name = "Show Minimap Button",
          type = "toggle",
          order = 1,
          set = function(_, val)
            if val then
              LibStub("LibDBIcon-1.0"):Show(VGT.name)
              VGT.OPTIONS.MINIMAP.hide = false
            else
              LibStub("LibDBIcon-1.0"):Hide(VGT.name)
              VGT.OPTIONS.MINIMAP.hide = true
            end
          end,
          get = function(_)
            return not VGT.OPTIONS.MINIMAP.hide
          end
        },
        mmi = {
          name = "Use Old Button Icon",
          type = "toggle",
          desc = "Use the old green logo for the minimap button.",
          order = 2,
          set = function(_, val)
            VGT.OPTIONS.oldIcon = val
            VGT.minimapButton:UpdateIcon()
          end,
          get = function()
            return VGT.OPTIONS.oldIcon
          end
        }
      }
    },
    vgt_map = {
      name = "Guild Map",
      type = "group",
      order = 2,
      args = {
        enable = {
          order = 0,
          name = "Enable",
          desc = "REQUIRES RELOAD",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.MAP.enabled = val
          end,
          get = function(_)
            return VGT.OPTIONS.MAP.enabled
          end
        },
        send_my_location = {
          order = 1,
          name = "Send My Location",
          desc = "sends your location to other addon users",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.MAP.sendMyLocation = val
          end,
          get = function(_)
            return VGT.OPTIONS.MAP.sendMyLocation
          end
        },
        show_me = {
          order = 2,
          name = "Show My Pin",
          desc = "shows your own pin on the map",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.MAP.showMe = val
          end,
          get = function(_)
            return VGT.OPTIONS.MAP.showMe
          end
        },
        show_minimap_oob = {
          order = 3,
          name = "Show Distant Players on Minimap",
          desc = "shows party member pins on the minimap borders if they are out of range",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.MAP.showMinimapOutOfBounds = val
          end,
          get = function(_)
            return VGT.OPTIONS.MAP.showMinimapOutOfBounds
          end
        },
        map_mode = {
          order = 4,
          name = "Display Mode",
          desc = "choose where pins are shown",
          values = {
            ["map"] = "Only World Map",
            ["minimap"] = "Only Minimap",
            ["both"] = "World Map and Minimap"
          },
          type = "select",
          style = "dropdown",
          get = function(_)
            return VGT.OPTIONS.MAP.mode
          end,
          set = function(_, val)
            VGT.OPTIONS.MAP.mode = val
          end
        }
      }
    },
    vgt_lootlist = {
      name = "Auto Master Looting",
      type = "group",
      order = 4,
      args = {
        enable = {
          order = 0,
          name = "Enable",
          desc = "When enabled, using auto-loot will work for the Master Looter loot method.",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.LOOTLIST.autoMasterLoot = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOOTLIST.autoMasterLoot
          end
        },
        trackEverything = {
          order = 1,
          name = "Track Everything",
          desc = "When checked, all loot will be tracked regardless of where it was looted or what its quality is.",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.LOOTLIST.trackEverything = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOOTLIST.trackEverything
          end
        },
        masterLootTarget = {
          order = 2,
          name = "Master-Loot Target",
          desc = "Who to send items to when auto-looting. Leave blank to send to yourself.",
          type = "input",
          set = function(_, val)
            VGT.OPTIONS.LOOTLIST.masterLootTarget = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOOTLIST.masterLootTarget
          end
        },
        masterLootDisenchantTarget = {
          order = 3,
          name = "Rare and Uncommon Target",
          desc = "Who to send items with |cff0070ddRare|r and |cff1eff00Uncommon|r quality to. Leave blank to use the Master-Loot Target.",
          type = "input",
          set = function(_, val)
            VGT.OPTIONS.LOOTLIST.masterLootDisenchantTarget = val
          end,
          get = function()
            return VGT.OPTIONS.LOOTLIST.masterLootDisenchantTarget
          end
        },
        ignoredItems = {
          order = 4,
          name = "Ignored items",
          desc = "A list of item links to ignore while auto-looting. Shift-click an item to add. Separate each entry with a semicolon (;)",
          type = "input",
          width = "full",
          multiline = 5,
          set = function(_, val)
            VGT.OPTIONS.LOOTLIST.ignoredItems = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOOTLIST.ignoredItems
          end
        }
      }
    },
    vgt_logging = {
      name = "Logging",
      type = "group",
      order = 99,
      args = {
        enable = {
          name = "Enable",
          type = "toggle",
          desc = "When enabled, addon logs will be sent to the chat window.",
          set = function(_, val)
            VGT.OPTIONS.LOGGING.enabled = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOGGING.enabled
          end
        },
        log_level = {
          name = "Log Level",
          desc = "verbosity of the addon",
          type = "select",
          values = {
            [VGT.LogLevel.TRACE] = "Trace",
            [VGT.LogLevel.DEBUG] = "Debug",
            [VGT.LogLevel.INFO] = "Info"
          },
          set = function(_, val)
            VGT.OPTIONS.LOGGING.level = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOGGING.level
          end
        }
      }
    },
    vgt_roll = {
      name = "Roll Window",
      type = "group",
      order = 3,
      args = {
        enable = {
          name = "Enable",
          type = "toggle",
          desc = "When enabled, master looters opening rolls using VGT will show a roll window for easier rolling and passing.",
          set = function(_, val)
            VGT.OPTIONS.ROLL.enabled = val
          end,
          get = function(_)
            return VGT.OPTIONS.ROLL.enabled
          end
        },
        log_level = {
          name = "Sound",
          desc = "Sound to play when the loot window shows.",
          type = "select",
          values = LSM:List("sound"),
          set = function(_, val)
            VGT.OPTIONS.ROLL.sound = LSM:List("sound")[val]
            local sound = LSM:Fetch("sound", VGT.OPTIONS.ROLL.sound, true)
            if sound then
              PlaySoundFile(sound, "Master")
            end
          end,
          get = function(_)
            for key, value in pairs(LSM:List("sound")) do
              if value == VGT.OPTIONS.ROLL.sound then
                return key
              end
            end
          end
        }
      }
    }
  }
}
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(VGT.name, options, SLASH_VGT1)
VGT.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(VGT.name, VGT.name)

VGT:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUI)
  if (not loaded and (isInitialLogin or isReloadingUI)) then
    loaded = true
    VGT.OPTIONS = DefaultConfig(VGT_OPTIONS)
  end
end)

VGT:RegisterEvent("PLAYER_LOGOUT", function()
  if (loaded) then
    VGT_OPTIONS = VGT.OPTIONS
  end
end)
