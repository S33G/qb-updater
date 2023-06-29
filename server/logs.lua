function success(message)
    log(Emoji.Success, message)
end

function info(message)
    log(Emoji.Info, message)
end

function fail(message)
    log(Emoji.Fail, message)
end

function log(prefix, message)
    print(prefix .. " " .. message:gsub("\t", ""))
end
