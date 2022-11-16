VGT.LogLevel = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
  SYSTEM = 6
}

local logColors = {
  [VGT.LogLevel.TRACE] = GRAY_FONT_COLOR_CODE,
  [VGT.LogLevel.DEBUG] = LIGHTYELLOW_FONT_COLOR_CODE,
  [VGT.LogLevel.INFO] = YELLOW_FONT_COLOR_CODE,
  [VGT.LogLevel.WARN] = ORANGE_FONT_COLOR_CODE,
  [VGT.LogLevel.ERROR] = RED_FONT_COLOR_CODE,
  [VGT.LogLevel.SYSTEM] = NORMAL_FONT_COLOR_CODE,
}

local function ShouldLog(level)
  if level > VGT.LogLevel.INFO then
    -- Errors, warnings, and system messages should always be displayed.
    return true
  end
  if VGT.OPTIONS.LOGGING.enabled then
    local userLevel = VGT.OPTIONS.LOGGING.level
    return type(userLevel) ~= "number" or level >= userLevel
  end
end

-- Logs (prints) a given message at the specified log level
--  level: the log level to print at
--  message: the unformatted message
--  ...: values to format the message with
function VGT.Log(level, message, ...)
  if ShouldLog(level) then
    if select("#", ...) > 0 then
      message = format(message, ...)
    end
    local color = logColors[level] or NORMAL_FONT_COLOR_CODE
    print(color .. "[" .. VGT.name .. "]", message)
  end
end

function VGT.LogTrace(message, ...)
  VGT.Log(VGT.LogLevel.TRACE, message, ...)
end

function VGT.LogDebug(message, ...)
  VGT.Log(VGT.LogLevel.DEBUG, message, ...)
end

function VGT.LogInfo(message, ...)
  VGT.Log(VGT.LogLevel.INFO, message, ...)
end

function VGT.LogWarning(message, ...)
  VGT.Log(VGT.LogLevel.WARN, message, ...)
end

function VGT.LogError(message, ...)
  VGT.Log(VGT.LogLevel.ERROR, message, ...)
end

function VGT.LogSystem(message, ...)
  VGT.Log(VGT.LogLevel.SYSTEM, message, ...)
end
