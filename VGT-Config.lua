local LSM = LibStub("LibSharedMedia-3.0")

local function MigrateOptionsToDB(db)
  if VGT_OPTIONS and not VGT_OPTIONS.migrated then
    if VGT_OPTIONS.LOGGING then
      db.profile.logging.enabled = VGT_OPTIONS.LOGGING.enabled
      db.profile.logging.level = VGT_OPTIONS.LOGGING.level
    end
    if VGT_OPTIONS.MAP then
      db.profile.map.enabled = VGT_OPTIONS.MAP.enabled
      db.profile.map.sendMyLocation = VGT_OPTIONS.MAP.sendMyLocation
      db.profile.map.showMinimapOutOfBounds = VGT_OPTIONS.MAP.showMinimapOutOfBounds
      db.profile.map.showMe = VGT_OPTIONS.MAP.showMe
      if VGT_OPTIONS.MAP.mode == "map" then
        db.profile.map.mode = VGT.MapOutput.MAP
      elseif VGT_OPTIONS.MAP.mode == "minimap" then
        db.profile.map.mode = VGT.MapOutput.MINIMAP
      else
        db.profile.map.mode = VGT.MapOutput.BOTH
      end
    end
    if VGT_OPTIONS.LOOTLIST then
      db.profile.autoMasterLoot.enabled = VGT_OPTIONS.LOOTLIST.autoMasterLoot
      db.profile.autoMasterLoot.ignoredItems = VGT_OPTIONS.LOOTLIST.ignoredItems
      db.char.autoMasterLoot.target = VGT_OPTIONS.LOOTLIST.masterLootTarget
      db.char.autoMasterLoot.disenchantTarget = VGT_OPTIONS.LOOTLIST.masterLootDisenchantTarget
      db.profile.lootTracker.x = VGT_OPTIONS.LOOTLIST.X
      db.profile.lootTracker.y = VGT_OPTIONS.LOOTLIST.Y
      db.profile.lootTracker.width = VGT_OPTIONS.LOOTLIST.Width
      db.profile.lootTracker.height = VGT_OPTIONS.LOOTLIST.Height
      db.profile.lootTracker.point = VGT_OPTIONS.LOOTLIST.Point
    end
    if VGT_OPTIONS.MINIMAP then
      db.profile.minimapButton.hide = VGT_OPTIONS.MINIMAP.hide
    end
    if VGT_OPTIONS.AUTOTRADE then
      db.profile.lootTracker.autoTrade = VGT_OPTIONS.AUTOTRADE.enabled
    end
    if VGT_OPTIONS.ROLL then
      db.profile.roller.enabled = VGT_OPTIONS.ROLL.enabled
      db.profile.roller.sound = VGT_OPTIONS.ROLL.sound
      db.profile.roller.x = VGT_OPTIONS.ROLL.X
      db.profile.roller.y = VGT_OPTIONS.ROLL.Y
      db.profile.roller.point = VGT_OPTIONS.ROLL.Point
    end
    if VGT_OPTIONS.oldIcon then
      db.profile.minimapButton.oldIcon = true
    end
    VGT_OPTIONS.migrated = true
    VGT.LogInfo("Migrated options from previous addon version.")
  end
end

function VGT:InitializeOptions()
  local defaults = {
    char = {
      autoMasterLoot = {
        target = "",
        disenchantTarget = ""
      }
    },
    profile = {
      minimapButton = {
        hide = false,
        oldIcon = false
      },
      logging = {
        enabled = false,
        level = VGT.LogLevel.INFO
      },
      map = {
        enabled = true,
        sendMyLocation = true,
        showMinimapOutOfBounds = false,
        mode = VGT.MapOutput.BOTH,
        showMe = false
      },
      autoMasterLoot = {
        enabled = false,
        ignoredItems = ""
      },
      lootTracker = {
        enabled = true,
        autoTrade = true,
        trackAllInstances = false,
        trackUncommon = false,
        groupByWinner = false,
        autoEndRoll = true,
        x = 0,
        y = 0,
        width = 400,
        height = 240,
        point = "CENTER"
      },
      roller = {
        enabled = true,
        sound = "Info",
        x = 0,
        y = 0,
        point = "CENTER"
      }
    }
  }

  self.db = LibStub("AceDB-3.0"):New("VGT_DB", defaults, true)
  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
  MigrateOptionsToDB(self.db)

  local function GetValue(db, info)
    local v = VGT.db[db]
    for i = 1, #info do
      v = v[info[i]]
    end
    return v
  end

  local function GetProfileValue(info)
    return GetValue("profile", info)
  end

  local function GetCharValue(info)
    return GetValue("char", info)
  end

  local function SetValue(db, info, value)
    local section = VGT.db[db]
    local path = "VGT.db." ..db
    local sectionName
    for i = 1, #info - 1 do
      sectionName = info[i]
      section = section[sectionName]
      path = path .. "." .. sectionName
    end
    sectionName = info[#info]
    section[sectionName] = value
    VGT.LogDebug("Set %s.%s to %s", path, sectionName, tostring(value))
  end

  local function SetProfileValue(info, value)
    SetValue("profile", info, value)
  end

  local function SetCharValue(info, value)
    SetValue("char", info, value)
  end
  
  --https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
  local options = {
    type = "group",
    disabled = function(info)
      if #info < 2 then
        return
      end
      if info[2] == "enabled" then
        return
      end
      local section = VGT.db.profile[info[1]]
      if section then
        return not section.enabled
      end
    end,
    get = GetProfileValue,
    set = SetProfileValue,
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
            get = function()
              return not VGT.db.profile.minimapButton.hide
            end,
            set = function(_, value)
              VGT.db.profile.minimapButton.hide = not value
              VGT:RefreshMinimapButtonConfig()
            end
          },
          minimapIcon = {
            name = "Use Old Button Icon",
            type = "toggle",
            desc = "Use the old green logo for the minimap button.",
            order = 2,
            get = function()
              return VGT.db.profile.minimapButton.oldIcon
            end,
            set = function(_, value)
              VGT.db.profile.minimapButton.oldIcon = value
              VGT:RefreshMinimapButtonConfig()
            end
          }
        }
      },
      map = {
        name = "Guild Map",
        type = "group",
        order = 2,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            desc = "Shows the positions of guild members on the map and minimap",
            type = "toggle",
            set = function(info, value)
              SetProfileValue(info, value)
              VGT:RefreshMapConfig()
            end
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          sendMyLocation = {
            order = 2,
            name = "Send My Location",
            desc = "sends your location to other addon users",
            type = "toggle"
          },
          showMe = {
            order = 3,
            name = "Show My Pin",
            desc = "shows your own pin on the map",
            type = "toggle"
          },
          showMinimapOutOfBounds = {
            order = 4,
            name = "Show Distant Players on Minimap",
            desc = "shows party member pins on the minimap borders if they are out of range",
            type = "toggle"
          },
          mode = {
            order = 5,
            name = "Display Mode",
            desc = "choose where pins are shown",
            values = {
              [VGT.MapOutput.MAP] = "Only World Map",
              [VGT.MapOutput.MINIMAP] = "Only Minimap",
              [VGT.MapOutput.BOTH] = "World Map and Minimap"
            },
            type = "select",
            style = "dropdown"
          }
        }
      },
      autoMasterLoot = {
        name = "Auto Master Looting",
        type = "group",
        order = 4,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            desc = "When enabled, using auto-loot will work for the Master Looter loot method.",
            type = "toggle"
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          target = {
            order = 2,
            name = "Master-Loot Target",
            desc = "Who to send items to when auto-looting. Leave blank to send to yourself.",
            type = "input",
            get = GetCharValue,
            set = SetCharValue
          },
          disenchantTarget = {
            order = 3,
            name = "Rare and Uncommon Target",
            desc = "Who to send items with |cff0070ddRare|r and |cff1eff00Uncommon|r quality to. Leave blank to use the Master-Loot Target.",
            type = "input",
            get = GetCharValue,
            set = SetCharValue
          },
          ignoredItems = {
            order = 4,
            name = "Ignored items",
            desc = "A list of item links to ignore while auto-looting. Shift-click an item to add. Separate each entry with a semicolon (;)",
            type = "input",
            width = "full",
            multiline = 5
          }
        }
      },
      lootTracker = {
        name = "Master Loot Tracker",
        type = "group",
        order = 5,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            type = "toggle",
            desc = "Enables automatic tracking of looted items while master looting.",
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          autoEndRoll = {
            order = 2,
            name = "End rolling on last response",
            desc = "When checked, rolling items will automatically end when everyone eligible to roll responds.",
            type = "toggle",
            width = "full"
          },
          trackAllInstances = {
            order = 3,
            name = "Track All Instances",
            desc = "When checked, all loot will be tracked regardless of what zone it was looted in.",
            type = "toggle"
          },
          trackUncommon = {
            order = 4,
            name = "Track Rare and Uncommon",
            desc = "When checked, |cff0070ddRare|r and |cff1eff00Uncommon|r items will be tracked.",
            type = "toggle"
          }
        }
      },
      roller = {
        name = "Roll Window",
        type = "group",
        order = 3,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            type = "toggle",
            desc = "When enabled, master looters opening rolls using VGT will show a roll window for easier rolling and passing."
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          sound = {
            order = 2,
            name = "Sound",
            desc = "Sound to play when the loot window shows.",
            type = "select",
            values = LSM:List("sound"),
            get = function(_)
              for key, value in pairs(LSM:List("sound")) do
                if value == VGT.db.profile.roller.sound then
                  return key
                end
              end
            end,
            set = function(_, val)
              VGT.db.profile.roller.sound = LSM:List("sound")[val]
              local sound = LSM:Fetch("sound", VGT.db.profile.roller.sound, true)
              if sound then
                PlaySoundFile(sound, "Master")
              end
            end
          }
        }
      },
      logging = {
        name = "Logging",
        type = "group",
        order = 99,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            type = "toggle",
            desc = "When enabled, addon logs will be sent to the chat window."
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          level = {
            order = 2,
            name = "Log Level",
            desc = "verbosity of the addon",
            type = "select",
            values = {
              [VGT.LogLevel.TRACE] = "Trace",
              [VGT.LogLevel.DEBUG] = "Debug",
              [VGT.LogLevel.INFO] = "Info"
            }
          }
        }
      }
    }
  }
  options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(self.name, options, SLASH_VGT1)
  VGT.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end
