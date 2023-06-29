function writeFile(path, data)

    file, _error = io.open(path, "w+")

    if file then
        log(Emoji.File, string.format("Writing file to %s", path))
        file:write(data)
    else
        fail(_error)
        error("Failed to write file to " .. path)
    end

    file:close()
end