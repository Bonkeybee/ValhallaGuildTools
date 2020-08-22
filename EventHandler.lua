EventHandler = {}

function EventHandler:Add(callback)
    if type(callback) ~= "function" then
        error("callback parameter must be a function")
    end
    self[#self + 1] = callback
    return self
end

function EventHandler:Remove(callback)
    local indexOfCallback
    for i,v in ipairs(self) do
        if v == callback then
            indexOfCallback = i
            break
        end
    end
    if indexOfCallback then
        for i = indexOfCallback,#self do
            self[i] = self[i + 1]
        end
    end
    return self
end

function EventHandler:Invoke(...)
    for _,callback in ipairs(self) do
        callback(...)
    end
end

function EventHandler:New()
    return setmetatable({}, self)
end

EventHandler.__index = EventHandler
EventHandler.__call = EventHandler.Invoke
EventHandler.__add = EventHandler.Add
EventHandler.__sub = EventHandler.Remove