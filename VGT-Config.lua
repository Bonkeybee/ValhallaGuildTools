local LSM = LibStub("LibSharedMedia-3.0")

LSM:Register("sound", "An Awesome Choice", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\anawesomechoice.ogg")
LSM:Register("sound", "Navi Hey Listen", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\heylisten.ogg")
LSM:Register("sound", "What Are You Buyin", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\whatareyoubuyin.ogg")
LSM:Register("sound", "What Can I Do For Ya", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\whatcanidoforya.ogg")
LSM:Register("sound", "Tatl Hey", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\tatlhey.ogg")
LSM:Register("sound", "Tatl Listen", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\tatllisten.ogg")

local function MigrateOptionsToDB(db)
  if VGT_OPTIONS and not VGT_OPTIONS.migrated then
    if VGT_OPTIONS.LOGGING then
      db.profile.logging.enabled = VGT_OPTIONS.LOGGING.enabled
      db.profile.logging.level = VGT_OPTIONS.LOGGING.level
    end
    if VGT_OPTIONS.MAP then
      db.profile.map.enabled = VGT_OPTIONS.MAP.enabled
      db.profile.map.sendMyLocation = VGT_OPTIONS.MAP.sendMyLocation
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
      },
      dropTracker = {
        items = {}
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
        mode = VGT.MapOutput.BOTH,
        improveBlizzardPins = true,
        useClassColor = false,
        size = 14
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
        showPasses = false,
        sound = "Tatl Hey",
        x = 0,
        y = 0,
        point = "CENTER"
      },
      dropTracker = {
        enabled = true,
        wonSound = "Tatl Listen",
        autoShow = true,
        showPassed = false,
        showInterested = false,
        showWon = false,
        x = 100,
        y = 0,
        width = 512,
        height = 240,
        point = "LEFT"
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
    if sectionName == "enabled" then
      local m = VGT:GetModule(info[#info - 1], true)
      if m then
        if value then
          m:Enable()
        else
          m:Disable()
        end
      end
    end
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
            type = "toggle"
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          mode = {
            order = 2,
            name = "Display Mode",
            desc = "Choose where pins are shown",
            values = {
              [VGT.MapOutput.MAP] = "Only World Map",
              [VGT.MapOutput.MINIMAP] = "Only Minimap",
              [VGT.MapOutput.BOTH] = "World Map and Minimap"
            },
            type = "select",
            style = "dropdown"
          },
          size = {
            order = 3,
            name = "Pin Size",
            desc = "Sets the size of guild pins.",
            type = "range",
            min = 1,
            max = 32,
            set = function(info, value)
              SetProfileValue(info, value)
              VGT:GetModule("map"):RefreshPinSizeAndColor()
            end
          },
          sendMyLocation = {
            order = 4,
            name = "Send My Location",
            desc = "sends your location to other addon users",
            type = "toggle"
          },
          improveBlizzardPins = {
            order = 5,
            name = "Configure Raid & Party Pins",
            desc = "When checked, the minimap icons for raid and party members will match the style of the guild pins. Disabling this requires a UI reload.",
            type = "toggle"
          },
          useClassColor = {
            order = 6,
            name = "Use Class Colors",
            desc = "When checked, minimap icons will use the pin's class color instead of green for guild and blue for party or raid.",
            type = "toggle",
            set = function(info, value)
              SetProfileValue(info, value)
              VGT:GetModule("map"):RefreshPinSizeAndColor()
            end
          }
        }
      },
      autoMasterLoot = {
        name = "Auto Master Looting",
        type = "group",
        order = 5,
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
        order = 6,
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
            name = "New Roll Sound",
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
          },
          wonSound = {
            order = 3,
            name = "Won Item Sound",
            desc = "Sound to play when you win an item.",
            type = "select",
            values = LSM:List("sound"),
            get = function(_)
              for key, value in pairs(LSM:List("sound")) do
                if value == VGT.db.profile.dropTracker.wonSound then
                  return key
                end
              end
            end,
            set = function(_, val)
              VGT.db.profile.dropTracker.wonSound = LSM:List("sound")[val]
              local sound = LSM:Fetch("sound", VGT.db.profile.dropTracker.wonSound, true)
              if sound then
                PlaySoundFile(sound, "Master")
              end
            end
          },
          showPasses = {
            order = 4,
            name = "Show on passed items",
            desc = "When checked, the roll window will show even for items you have passed on.",
            type = "toggle"
          }
        }
      },
      dropTracker = {
        name = "Drop Tracker",
        type = "group",
        order = 4,
        args = {
          enabled = {
            order = 0,
            name = "Enable",
            type = "toggle",
            desc = "Enables the drop tracker window.",
          },
          sep = {
            order = 1,
            name = "",
            type = "header"
          },
          autoShow = {
            order = 2,
            name = "Auto Show on New Loot",
            type = "toggle",
            desc = "When enabled, the drop tracker will pop up whenever new loot is tracked.",
            width = "full"
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
