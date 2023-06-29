local couldNotPullFXManifest = {}

-- function DownloadCommand(zipPath, downloadUrl)
--     local downloadCMD = string.format("curl -L -o \"%s\" \"%s\"", zipPath, downloadUrl)
--     print('----DL CMD', downloadCMD)
--     local downloadHandle = io.popen(downloadCMD)
--     print('----DL HANDLE', downloadHandle)
--     local downloadResult = downloadHandle:read("*a")
--     print('----DL RESULT', downloadResult)

--     local a, b = downloadHandle:close()
--     print('----DL CLOSE', a, b)
--     return downloadResult
-- end

RegisterNetEvent('extraction-complete', function(data, cb)
    print('unzip-success', data)
    cb(true)
end)


function DownloadCommand(zipPath, downloadUrl, cb)
    log(Emoji.Download, string.format("Attempting Download... \nDownload URL: %s \nDownload Path: %s",
        downloadUrl,
        zipPath
    ))

    PerformHttpRequest(downloadUrl, function(errorCode, resultData, resultHeaders)
        if errorCode ~= 200 then
            error("Error downloading " .. downloadUrl .. " from GitHub!")
            couldNotPullFXManifest[resourceName] = false
            return cb(resultData)
        else 
            success("Downloaded " .. downloadUrl .. " from GitHub!")
            writeFile(zipPath, resultData)
            return cb(zipPath)
        end
    end)
end

function DeleteResourceCommand(path)
    local deleteResourceCMD = string.format("if exist \"%s\" rmdir /s /q \"%s\"", path, path)
    local deleteResourceHandle = io.popen(deleteResourceCMD)
    local deleteResourceResult = deleteResourceHandle:read("*a")
    deleteResourceHandle:close()
    return deleteResourceResult
end

function RenameAndMoveCommand(tempZipFolder, path, dryRun)
    local renameAndMoveCMD = string.format("move \"%s\" \"%s\"", tempZipFolder, path)
    if Config.Debug then
        print(renameAndMoveCMD)
    end
    if Config.DryRun then
        return true
    end

    local renameAndMoveHandle = io.popen(renameAndMoveCMD)
    local renameAndMoveResult = renameAndMoveHandle:read("*a")
    renameAndMoveHandle:close()
    return renameAndMoveResult
end

function CleanUpCommand(zipPath)
    local cleanupCMD = string.format("del /f \"%s\"", zipPath)
    local cleanupHandle = io.popen(cleanupCMD)
    local cleanupResult = cleanupHandle:read("*a")
    cleanupHandle:close()
    return cleanupResult
end

function MoveIgnoredToUnzipPath(ignorePaths, unzipPath)
    local moveResult = ""
    for _, v in ipairs(ignorePaths or {}) do
        local ignoredPath = v.path
        local tempPath = unzipPath .. '\\' .. v.relativePath
        moveResult = RenameAndMoveCommand(ignoredPath, tempPath)
    end
    return moveResult
end

function DownloadAndInstallGitHubRepo(url, branch, path, ignorePaths, useLatestReleaseLink, cb)
    local username, repository = GetRepoNameFromUrl(url)
    print(Emoji.Fail .. Emoji.Fail .. Emoji.Fail)
    print(GetRepoNameFromUrl(url))
    local downloadUrl = string.format("https://github.com/%s/%s/archive/refs/heads/%s.zip", username, repository, branch)
    local tempFolder = "/tmp"

    if isWindows() then
        print("Running in Windows Server Mode")
        tempFolder = os.getenv("temp")
    else 
        print("Running in Linux Server Mode")
    end

    tempFolder = tempFolder .. "/qb-updater"

    assert(tempFolder, "Error getting temp folder! Check `Config.OS` in config.lua!")
        
    local zipPath = buildPath("%s/%s.zip", tempFolder, repository)
    local tmpPath = buildPath("%s/%s-%s", tempFolder, repository, branch)

    if useLatestReleaseLink then
        downloadUrl = string.format("https://github.com/%s/%s/releases/latest/download/%s.zip", username, repository, repository)
        tempZipFolder = buildPath("%s/%s", tempFolder, repository)
    end    

    print('downloadUrl', downloadUrl)
    local downloadResult = DownloadCommand(zipPath, downloadUrl, function(zipPath)

        -- TODO: Unzip?
        print('zipPath', zipPath)
        -- assert(downloadResult == '', error("Error downloading " .. repository .. " from GitHub!"))
        
        if not zipPath then 
          error("Error downloading " .. repository .. " from GitHub!")
        end

        TriggerEvent('qb-updater:unzip', zipPath, string.format('%s/%s', tempFolder, repository), function(result)
            if not result then
                fail(string.format("Failed to unzip %s to %s", zipPath, tempZipFolder))
            end
        -- local ignoreResult = MoveIgnoredToUnzipPath(ignorePaths, tempZipFolder)
        -- assert(ignoreResult, error("Error moving ignored files for " .. repository .. " from GitHub!"))
    
        -- local deleteResourceResult = DeleteResourceCommand(path)
        -- assert(deleteResourceResult, "Error deleting " .. repository .. " from GitHub!")
    
        -- local renameAndMoveResult = RenameAndMoveCommand(tempZipFolder, path)
        -- assert(renameAndMoveResult, "Error moving " .. repository .. " from GitHub!")
    
        -- local cleanupResult = CleanUpCommand(zipPath)
        -- assert(cleanupResult, "Error cleaning up " .. repository .. " from GitHub!")
    
        -- local result = [[
        --     ]] .. downloadResult .. [[
        --     ]] .. unpackResult .. [[
        --     ]] .. "deleteResourceResult" .. [[
        --     ]] .. renameAndMoveResult .. [[
        --     ]] .. cleanupResult .. [[
        -- ]]
    
        -- result = result:gsub("%s+", "")
        -- if result then 
        --     print(
        --         "\n\t============================= Downloaded and Installed: " .. repository .. " =============================",
        --         "\n\tDownload URL:", downloadUrl,
        --         "\n\tDownload Path:", zipPath,
        --         "\n\tUnpack Path:", tempZipFolder,
        --         "\n\tMove Path:", path,
        --         "\n\tResult:", result,
        --         "\n\t=================================================================================================="
        --     )
        --     if cb and type(cb) == "function" then
        --         cb(result)
        --     end
        --     return true
        -- end
    
        print('pee poopoo')

        end)
        print(unPackResult)
        assert(unpackResult, error("Error unpacking " .. repository .. " from GitHub!"))
    end)

end

function GetFileTextFromGitHubRepo(url, branch, filename, cb)
    if not cb or type(cb) ~= "function" then return end
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    local fileURL = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", username, repository, branch, filename)
    PerformHttpRequest(fileURL, function(response, responseText, responseHeaders)
        cb(response, responseText, responseHeaders)
    end)
end

function GetVersionNumberFromFile(filePath)
    local file = io.open(filePath, "r")
    if not file then return end

    local fileContents = file:read("*a")
    file:close()

    local versionNumber = fileContents:match("version%s+'([%d%.]+)'")
    return versionNumber
end

local function CompareVersionNumbers(version1, version2)
    local version1Parts = {}
    for part in version1:gmatch("%d+") do
        table.insert(version1Parts, tonumber(part))
    end

    local version2Parts = {}
    for part in version2:gmatch("%d+") do
        table.insert(version2Parts, tonumber(part))
    end

    for i = 1, math.max(#version1Parts, #version2Parts) do
        local part1 = version1Parts[i] or 0
        local part2 = version2Parts[i] or 0
        if part1 > part2 then
            return 1
        elseif part1 < part2 then
            return -1
        end
    end
    return 0
end

function RetrieveResourceVersionAndDownload(resourceName, resourcePath, branch, url, useLatestReleaseLink, cb)
    local resourceVersionFilePath = string.format("%s\\fxmanifest.lua", resourcePath)
    local resourceVersion = GetVersionNumberFromFile(resourceVersionFilePath)
    branch = branch or "main"
    GetFileTextFromGitHubRepo(url, branch, "fxmanifest.lua", function(error, responseText, responseHeaders)
        print(error)
        if error ~= 200 then
            error("Error getting fxmanifest.lua for " .. resourceName .. " from GitHub!")
            couldNotPullFXManifest[resourceName] = true
            return
        end
        local versionNumber = responseText:match("version%s+'([%d%.]+)'")
        
        if not versionNumber or not resourceVersion or CompareVersionNumbers(versionNumber, resourceVersion) > 0 then 
            local ignoredPaths = GenerateIgnoredPaths(resourcePath, resourceName)
            DownloadAndInstallGitHubRepo(url, branch, resourcePath, ignoredPaths, useLatestReleaseLink)
        end
    end)
end

function UpdateServer(cb)
    local currentResourceName = string.gsub(GetCurrentResourceName(), " ", ""):lower()
    print("Updating all registered resources from GitHub...")
    
    CreateThread(function()
        local fallbackPath = GetResourcePath(currentResourceName)
        local errors = {}
        if not fallbackPath then
            error("Error getting fallback path!")
        return end
        fallbackPath = string.gsub(fallbackPath, "//", "/")
        fallbackPath = string.gsub(fallbackPath, "/", "\\")

        for resourceName, v in pairs(Config.Resources) do
            print("Updating " .. resourceName .. " from GitHub...")
            local url = v.url
            local branch = v.branch or "main"
            local useLatestReleaseLink = v.useLatestReleaseLink
            local resourcePathRaw = GetResourcePath(resourceName) or ''
            if resourcePathRaw == '' then
                local pattern = 'qb%-updater'
                resourcePathRaw = string.gsub(fallbackPath, pattern, resourceName )                     
            end     
            
            if resourcePathRaw then 
                --C:/Users/User/AppData/Local/FiveM/FiveM.app/Contents/runtime/resources/[local]/qb-updater..//qb-updater

                --C:\\Users\\User\\AppData\\Local\\FXServer\\resources\\qb-updater\\qb-updater
                
                local resourcePath = string.gsub(resourcePathRaw, "//", "/")
                resourcePath = string.gsub(resourcePath, "/", "\\")
                local status, error = pcall(function()
                  RetrieveResourceVersionAndDownload( resourceName, resourcePath, branch, url, useLatestReleaseLink, cb)
                end)
                print(status, error)

                if (status) then
                    print("exiting loop.......")
                    print("Error updating " .. resourceName .. " from GitHub!")
                    print(error)
                    errors[resourceName] = error
                    goto finish
                    return false
                end
            end
            Wait(100)
        end
        
        for resource, cNPFFXM in pairs(couldNotPullFXManifest) do
            if cNPFFXM then
                error("Could not pull fxmanifest.lua from " .. resource)
            end
        end
        couldNotPullFXManifest = {}

        ::finish::

        if (next(errors)) then
            error("Errors updating resources from GitHub!")
            print(errors)
            return
        else 
            print("All registered resources updated!")
        end
    end)    
end

function RemoveResouce(resourceName)
    local resourcePathRaw = GetResourcePath(resourceName)
    if not resourcePathRaw then return end

    local resourcePath = string.gsub(resourcePathRaw, "//", "/")
    resourcePath = string.gsub(resourcePath, "/", "\\")
    
    local removeCMD = string.format("rmdir /s /q \"%s\"", resourcePath)
    local handle = io.popen(removeCMD)
    local result = handle:read("*a")
    handle:close()
    if result then 
        print(
            "\n\t============================= Removed: " .. resourceName .. " =============================",
            "\n\tPath:", resourcePath,
            "\n\tResult:", result,
            "\n\t=================================================================================================="
        )
        return true
    end

    return false 
end

local RemoveAllResources = function()
    for resourceName, url in pairs(Config.Resources) do
        RemoveResouce(resourceName)
    end
    print("All registered resources removed!")
end

local function TriggerSuggestion(src)
    TriggerClientEvent('chat:addSuggestion', src, '/qb-update', 'Update all qb resources', {
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-freshupdate', 'Remove all qb resources and update them', {
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-install', 'Download and soft-install GitHub resource', {
        { name="url", help="The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'" },
        { name="branch/password", help="[Branch] OPTIONAL: The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') [Password] OPTIONAL: The password set in qb-updater. *Required* if enabled in config.lua AND the resource is not already installed."},
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua AND the resource is not already installed." },
    })
    TriggerClientEvent('chat:addSuggestion', src, '/qb-installrelease', 'Download and soft-install GitHub resource from latest release', {
        { name="url", help="The GitHub URL of the resource you want to install. Example: 'https://github.com/gononono64/qb-updater'"},
        { name="branch/password", help="[Branch] OPTIONAL: The branch of the resource you want to install. Example: 'main' or 'master' (DEFAULT: 'main') [Password] OPTIONAL: The password set in qb-updater. *Required* if enabled in config.lua AND the resource is not already installed."},
        { name="password", help="OPTIONAL: The password set in qb-updater. [Required] if enabled in config.lua AND the resource is not already installed." },
    })
end

RegisterNetEvent('playerJoining', function(oldId)
    local src = source
    TriggerSuggestion(src)    
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerSuggestion(-1)
    end
end)
