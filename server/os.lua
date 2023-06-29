local WINDOWS = 'windows'
local LINUX = 'linux'

function validateOsString (string)
    if string == nil or string == "" then
        return false
    end

    if string.lower(string) == WINDOWS or string.lower(string) == LINUX then
        return true
    else
        print("Invalid OS string provided: " .. string) 
        return false
    end

    return true
end

function isLinux ()
    return string.lower(Config.OS) == LINUX
end

function isWindows ()
    return string.lower(Config.OS) == WINDOWS
end

function getOs ()
    if isLinux() then
        return LINUX
    elseif isWindows() then
        return WINDOWS
    end
end

function buildPath(path, ...)
    
    if isLinux() then
        return string.format(path, ...)
    elseif isWindows() then
        return string.gsub(string.format(path, ...), "/", "\\")
    end
end