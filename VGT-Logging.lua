ADDON_NAME, VGT = ...
VERSION = GetAddOnMetadata(ADDON_NAME, "Version")

VGT.LOG_TYPE.ALL = "ALL"; VGT.LOG_TYPE[VGT.LOG_TYPE.ALL] = 0; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.ALL]] = VGT.LOG_TYPE.ALL;
VGT.LOG_TYPE.TRACE = "TRACE"; VGT.LOG_TYPE[VGT.LOG_TYPE.TRACE] = 1; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.TRACE]] = VGT.LOG_TYPE.TRACE;
VGT.LOG_TYPE.DEBUG = "DEBUG"; VGT.LOG_TYPE[VGT.LOG_TYPE.DEBUG] = 2; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.DEBUG]] = VGT.LOG_TYPE.DEBUG;
VGT.LOG_TYPE.INFO = "INFO"; VGT.LOG_TYPE[VGT.LOG_TYPE.INFO] = 3; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.INFO]] = VGT.LOG_TYPE.INFO;
VGT.LOG_TYPE.WARN = "WARN"; VGT.LOG_TYPE[VGT.LOG_TYPE.WARN] = 4; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.WARN]] = VGT.LOG_TYPE.WARN;
VGT.LOG_TYPE.ERROR = "ERROR"; VGT.LOG_TYPE[VGT.LOG_TYPE.ERROR] = 5; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.ERROR]] = VGT.LOG_TYPE.ERROR;
VGT.LOG_TYPE.SYSTEM = "SYSTEM"; VGT.LOG_TYPE[VGT.LOG_TYPE.SYSTEM] = 6; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.SYSTEM]] = VGT.LOG_TYPE.SYSTEM;
VGT.LOG_TYPE.OFF = "OFF"; VGT.LOG_TYPE[VGT.LOG_TYPE.OFF] = 7; VGT.LOG_TYPE[VGT.LOG_TYPE[VGT.LOG_TYPE.OFF]] = VGT.LOG_TYPE.OFF;
VGT.LOG_TYPES = {VGT.LOG_TYPE.ALL, VGT.LOG_TYPE.TRACE, VGT.LOG_TYPE.DEBUG, VGT.LOG_TYPE.INFO, VGT.LOG_TYPE.WARN, VGT.LOG_TYPE.ERROR, VGT.LOG_TYPE.SYSTEM, VGT.LOG_TYPE.OFF}

VGT.LOG.level = VGT.LOG_TYPE[VGT.LOG_TYPE.WARN]

VGT.Log = function(logLevel, message, ...)
    if (VGT.LOG_TYPE[logLevel] == VGT.LOG_TYPE.SYSTEM or VGT.LOG.level <= VGT.LOG_TYPE[logLevel]) then
        print(format("[%s] "..message, ADDON_NAME, ...))
    end
end

VGT.SetLogLevel = function(logLevel)
    if (TableContains(VGT.LOG_TYPES, logLevel)) then
        VGT.LOG.level = VGT.LOG_TYPE[logLevel]
        VGT.Log(VGT.LOG_TYPE.SYSTEM, "log level set to %s", VGT.LOG_TYPE[VGT.LOG.level])
    else
        VGT.Log(VGT.LOG_TYPE.SYSTEM, "%s is not a valid log level", logLevel)
    end
end
