local class = {}

function class.new(path, writeFile)
    local methods = {}

    -- create the file if necessary
    if writeFile then
        pcall(function()
            io.open(path, 'w'):write()
        end)
    end

    function methods.write(data)
        local openedFile = io.open(path, 'w')

        openedFile:write(data or "")

        openedFile:close()
    end


    function methods.append(data)
        methods.write(methods.read() .. (data or ""))
    end


    function methods.read()
        local openedFile = io.open(path)

        local contents = openedFile:read("*all")
        openedFile:close()

        return contents
    end

    function methods.readLine()
        local openedFile = io.open(path)
        openedFile:close()

        return openedFile:read()
    end

    function methods.close()
        --openedFile:close()
    end

    -- error safety

    function methods.errorIfNonExistent()

    end


    return methods
end





return class