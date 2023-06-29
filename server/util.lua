function GenerateIgnoredPaths(resourcePath, resourceName)
    local ignorePaths = {}
    local configResource = Config.Resources[resourceName]
    if not configResource then return ignoredPaths end 

    local configIgnore = configResource.ignore
    if not configIgnore then return ignoredPaths end
    
    for _, ignoredPath in ipairs(configIgnore) do
        if string.find(ignoredPath, "*", 1, true) then
            local pattern = string.gsub(ignoredPath, "*", ".*")
            local files = io.popen("dir /b /s " .. resourcePath .. "\\" .. pattern):lines()
            for file in files do
                ignorePaths[#ignorePaths + 1] = {
                    path = file,
                    relativePath = string.gsub(file, resourcePath .. "\\", "")
                }

            end
        else
            local path = resourcePath .. '\\' .. ignoredPath
            ignorePaths[#ignorePaths + 1] = {
                path = path,
                relativePath = ignoredPath,
            }
        end
    end

    return ignorePaths
end

function GetRepoNameFromUrl(url)
    local username, repository = url:match("github.com/([^/]+)/([^/]+)")
    assert(username and repository, "Invalid URL provided!")
    return username, repository
end