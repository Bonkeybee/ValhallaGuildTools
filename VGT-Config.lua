local LSM = LibStub("LibSharedMedia-3.0")

LSM:Register("sound", "An Awesome Choice", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\anawesomechoice.ogg")
LSM:Register("sound", "Navi Hey Listen", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\heylisten.ogg")
LSM:Register("sound", "What Are You Buyin", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\whatareyoubuyin.ogg")
LSM:Register("sound", "What Can I Do For Ya", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\whatcanidoforya.ogg")
LSM:Register("sound", "Tatl Hey", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\tatlhey.ogg")
LSM:Register("sound", "Tatl Listen", "Interface\\Addons\\ValhallaGuildTools\\Sounds\\tatllisten.ogg")

function VGT:InitializeOptions()
  ---@class VGT.db : AceDBObject-3.0
  local defaults = {
    ---@class CharacterSettings
    char = {
      ---@class AutoMasterLootCharacterSettings
      autoMasterLoot = {
        ---@type string
        target = "",
        ---@type string
        disenchantTarget = ""
      },
      ---@class DropTrackerCharacterSettings
      dropTracker = {
        ---@type DropTrackerItem[]
        items = {},
        ---@type table<integer, DropTrackerPass>
        autoPasses = {},
        ---@type number?
        expiration = nil
      },
      activities = {
        selectedRoles = {},
        selectedActivities = {}
      },
      ---@class LootTrackerCharacterSettings
      lootTracker = {
        ---@type CreatureData[]
        creatures = {},
        ---@type table<integer, table<string, VGT.PreemptiveResponse>>
        preemptiveResponses = {},
        ---@type Standing[][]
        standings = {},
        ---@type number?
        expiration = nil,
        ---@type table<string, true>
        disenchanters = {}
      }
    },
    ---@class ProfileSettings
    profile = {
      ---@class MinimapButtonProfileSettings : LibDBIcon.button.DB
      minimapButton = {
        hide = false,
        oldIcon = false
      },
      ---@class LoggingProfileSettings
      logging = {
        enabled = false,
        ---@type VGT.LogLevel
        level = VGT.LogLevel.INFO
      },
      ---@class MapProfileSettings
      map = {
        enabled = true,
        sendMyLocation = true,
        ---@type VGT.MapOutput
        mode = VGT.MapOutput.BOTH,
        improveBlizzardPins = true,
        useClassColor = false,
        size = 14
      },
      ---@class AutoMasterLootProfileSettings
      autoMasterLoot = {
        enabled = false,
        ignoredItems = ""
      },
      ---@class LootTrackerProfileSettings
      lootTracker = {
        enabled = true,
        autoTrade = true,
        trackAllInstances = false,
        trackUncommon = false,
        groupByWinner = false,
        autoEndRoll = true,
        countdownTimer = 5,
        x = 0,
        y = 0,
        width = 400,
        height = 240,
        point = "CENTER"
      },
      ---@class RollerProfileSettings
      roller = {
        enabled = true,
        showPasses = false,
        sound = "What Are You Buyin",
        x = 0,
        y = 0,
        point = "CENTER"
      },
      ---@class DropTrackerProfileSettings
      dropTracker = {
        enabled = true,
        wonSound = "An Awesome Choice",
        autoShow = true,
        autoClose = true,
        showPassed = false,
        showInterested = false,
        showWon = false,
        x = 100,
        y = 0,
        width = 512,
        height = 240,
        point = "LEFT"
      },
      activities = {
        enabled = true,
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
    local path = "VGT.db." .. db
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

  -- https://www.wowace.com/projects/ace3/pages/ace-config-3-0-options-tables
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
          about = {
            name = "Valhalla Guild Tools",
            type = "description",
            order = 0,
            fontSize = "large",
            width = "full"
          },
          version = {
            name = "Version " .. VGT.version,
            type = "description",
            order = 0,
            fontSize = "medium",
            width = "full"
          },
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
              VGT:GetModule("map")--[[@as MapModule]]:RefreshPinSizeAndColor()
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
              VGT:GetModule("map")--[[@as MapModule]]:RefreshPinSizeAndColor()
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
            desc = "Enables automatic tracking of looted items while master looting."
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
            desc = "Enables the drop tracker window."
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
          },
          autoHide = {
            order = 3,
            name = "Auto Hide on All Responded",
            type = "toggle",
            desc = "When enabled, the drop tracker will hide when you have responded to all iems.",
            width = "full"
          },
          autoPassSingle = {
            order = 4,
            name = "Clear Auto-Pass for Item",
            desc = "Picking an item in this list will clear your auto-pass preferences for it and allow you to see it for rolling on again",
            type = "select",
            values = function ()
              local items = {}
              for itemId, ap in pairs(VGT.db.char.dropTracker.autoPasses) do
                items[itemId] = ap.name
              end
              return items
            end,
            sorting = function()
              local sortedItems = {}
              for itemId, ap in pairs(VGT.db.char.dropTracker.autoPasses) do
                table.insert(sortedItems, {id=itemId,name=ap.name})
              end
              table.sort(sortedItems, function(l,r) return l.name < r.name end)
              local array = {}
              for i,v in ipairs(sortedItems) do
                array[i] = v.id
              end
              return array
            end,
            get = function() end,
            set = function(_, id)
              VGT.db.char.dropTracker.autoPasses[id] = nil
            end,
            width = "full"
          },
          autoPassAll = {
            order = 5,
            name = "Clear All Auto-Passes for Character",
            desc = "Click to clear all auto-pass preferences for all items, allowing you to see them again for rolling on.",
            type = "execute",
            func = function ()
              VGT:Confirm(function() VGT.db.char.dropTracker.autoPasses = {} end, "Are you sure you want to clear all auto-pass preferences? All items you can equip will show up in the tracker again.")
            end,
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
  LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(self.name, options)
  VGT.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end
