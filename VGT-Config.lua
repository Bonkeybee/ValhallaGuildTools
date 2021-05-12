local loaded = false

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
  options.enabled = default(options.enabled, true)
  options.LOG = default(options.LOG, {})
  options.MAP = default(options.MAP, {})
  options.LOG.enabled = default(options.LOG.enabled, true)
  options.LOG.logLevel = default(options.LOG.logLevel, VGT.LOG.LEVELS[VGT.LOG_LEVEL.INFO])
  options.MAP.enabled = default(options.MAP.enabled, true)
  options.MAP.sendMyLocation = default(options.MAP.sendMyLocation, true)
  options.MAP.showMinimapOutOfBounds = default(options.MAP.showMinimapOutOfBounds, false)
  if (options.MAP.mode == nil) then
    options.MAP.mode = "both"
    options.MAP.showMe = false
  else
    options.MAP.showMe = default(options.MAP.showMe, false)
  end
  options.FUN = default(options.FUN, {})
  options.FUN.enabled = default(options.FUN.enabled, true)
  return options
end

local function OnAddonLoaded(_, isInitialLogin, isReloadingUI)
  if (not loaded and (isInitialLogin or isReloadingUI)) then
    loaded = true
    VGT.OPTIONS = DefaultConfig(VGT_OPTIONS)
  end
end

local function OnPlayerLogout()
  if (loaded) then
    VGT_OPTIONS = VGT.OPTIONS
  end
end

-- ############################################################
-- ##### OPTIONS ##############################################
-- ############################################################

--https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
local options = {
  type = "group",
  args = {
    enable = {
      name = "Enable",
      desc = "REQUIRES RELOAD",
      type = "toggle",
      set = function(_, val)
        VGT.OPTIONS.enabled = val
      end,
      get = function(_)
        return VGT.OPTIONS.enabled
      end
    },
    vgt_logging = {
      name = "VGT-Logging",
      type = "group",
      args = {
        enable = {
          name = "Enable",
          type = "toggle",
          set = function(_, val)
            VGT.OPTIONS.LOG.enabled = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOG.enabled
          end
        },
        log_level = {
          name = "Log Level",
          desc = "verbosity of the addon",
          type = "select",
          values = {
            VGT.LOG_LEVEL.ALL,
            VGT.LOG_LEVEL.TRACE,
            VGT.LOG_LEVEL.DEBUG,
            VGT.LOG_LEVEL.INFO,
            VGT.LOG_LEVEL.WARN,
            VGT.LOG_LEVEL.ERROR,
            VGT.LOG_LEVEL.SYSTEM,
            VGT.LOG_LEVEL.OFF
          },
          set = function(_, val)
            VGT.OPTIONS.LOG.logLevel = val
          end,
          get = function(_)
            return VGT.OPTIONS.LOG.logLevel
          end
        }
      }
    },
    vgt_map = {
      name = "VGT-Map",
      type = "group",
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
    }
  }
}
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(VGT.Name, options, SLASH_VGT1)
VGT.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(VGT.Name, VGT.Name)

VGT:RegisterEvent("PLAYER_ENTERING_WORLD", OnAddonLoaded)
VGT:RegisterEvent("PLAYER_LOGOUT", OnPlayerLogout)
