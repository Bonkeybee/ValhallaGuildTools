local VGT_ADDON_NAME, ValhallaGuildTools = ...
local MODULE_NAME = "VGT-Core"

VGT = ValhallaGuildTools
LibStub("AceAddon-3.0"):NewAddon(VGT, VGT_ADDON_NAME, "AceComm-3.0", "AceTimer-3.0", "AceEvent-3.0")
VGT.VERSION = GetAddOnMetadata(VGT_ADDON_NAME, "Version")
VGT.HBD = LibStub("HereBeDragons-2.0")
VGT.HBDP = LibStub("HereBeDragons-Pins-2.0")
VGT.Name = VGT_ADDON_NAME

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

function VGT:SendCoreMessage(message, channel, target)
  self:SendCommMessage(MODULE_NAME, message, channel, target)
end

function VGT:RegisterCoreMessageHandler(handler)
  self:RegisterComm(
    MODULE_NAME,
    function(prefix, message, _, sender)
      if (prefix == MODULE_NAME) then
        handler(message, sender)
      end
    end
  )
end

do
  local registerEvent = VGT.RegisterEvent
  VGT._events = {}

  function VGT:RegisterEvent(event, callback)
    local eventList = self._events[event]
    if (not eventList) then
      eventList = {}
      self._events[event] = eventList
      self[event] = function(s, ...)
        for _, c in ipairs(s._events[event]) do
          c(...)
        end
      end
      registerEvent(self, event)
    end
    table.insert(eventList, callback)
  end
end
