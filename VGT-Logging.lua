local logColors = {
  [VGT.LogLevel.TRACE] = GRAY_FONT_COLOR_CODE,
  [VGT.LogLevel.DEBUG] = LIGHTYELLOW_FONT_COLOR_CODE,
  [VGT.LogLevel.INFO] = YELLOW_FONT_COLOR_CODE,
  [VGT.LogLevel.WARN] = ORANGE_FONT_COLOR_CODE,
  [VGT.LogLevel.ERROR] = RED_FONT_COLOR_CODE,
  [VGT.LogLevel.SYSTEM] = NORMAL_FONT_COLOR_CODE
}

local function ShouldLog(level)
  if level > VGT.LogLevel.INFO then
    -- Errors, warnings, and system messages should always be displayed.
    return true
  end
  if VGT.db and VGT.db.profile.logging.enabled then
    local userLevel = VGT.db.profile.logging.level
    return type(userLevel) ~= "number" or level >= userLevel
  end
end

local function Sanitize(param)
  local t = type(param)
  if t == "string" or t == "number" then
    return param
  elseif t == "nil" then
    return ""
  elseif t == "boolean" then
    return param and "true" or "false"
  elseif t == "table" then
    return strjoin(", ", unpack(param))
  else
    return tostring(param)
  end
end

local function SanitizeParams(...)
  local count = select("#", ...)
  if count == 0 then
    return
  else
    local p1, p2, p3, p4, p5 = ...
    if count == 1 then
      return Sanitize(p1)
    elseif count == 2 then
      return Sanitize(p1), Sanitize(p2)
    elseif count == 3 then
      return Sanitize(p1), Sanitize(p2), Sanitize(p3)
    elseif count == 4 then
      return Sanitize(p1), Sanitize(p2), Sanitize(p3), Sanitize(p4)
    elseif count == 5 then
      return Sanitize(p1), Sanitize(p2), Sanitize(p3), Sanitize(p4), Sanitize(p5)
    else
      return Sanitize(p1), Sanitize(p2), Sanitize(p3), Sanitize(p4), Sanitize(p5), SanitizeParams(select(6, ...))
    end
  end
end

---Formats a string.
---* `string` and `number` values are treated the same as with `string.format`
---* `nil` is treated as an empty string
---* `boolean` values are treated as "true" and "false" strings
---* `table` arrays are unpacked and have their values displayed comma-separated
---* All other types go through the `tostring` function
---@param message string
---@param ... any
---@return string
function VGT.Format(message, ...)
  return string.format(message, SanitizeParams(...))
end

---Logs (prints) a given message at the specified log level
---@param level VGT.LogLevel the log level to print at
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.Log(level, message, ...)
  if ShouldLog(level) then
    if select("#", ...) > 0 then
      message = VGT.Format(message, ...)
    end
    local color = logColors[level] or NORMAL_FONT_COLOR_CODE
    print(color .. "[" .. VGT.name .. "]", message)
  end
end

---Logs (prints) a trace message
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogTrace(message, ...)
  VGT.Log(VGT.LogLevel.TRACE, message, ...)
end

---Logs (prints) a debug message
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogDebug(message, ...)
  VGT.Log(VGT.LogLevel.DEBUG, message, ...)
end

---Logs (prints) an informational message
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogInfo(message, ...)
  VGT.Log(VGT.LogLevel.INFO, message, ...)
end

---Logs (prints) a warning message
---
---This message cannot be filtered
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogWarning(message, ...)
  VGT.Log(VGT.LogLevel.WARN, message, ...)
end

---Logs (prints) an error message
---
---This message cannot be filtered
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogError(message, ...)
  VGT.Log(VGT.LogLevel.ERROR, message, ...)
end

---Logs (prints) a system message
---
---This message cannot be filtered
---@param message string the unformatted message
---@param ... any values to format the message with
function VGT.LogSystem(message, ...)
  VGT.Log(VGT.LogLevel.SYSTEM, message, ...)
end
