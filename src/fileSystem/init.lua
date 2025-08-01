local module = {}
local file = require("fileSystem.file")

function module.create(name, overwrites)
    if (not overwrites and io.open(name)) then
        error("Attempt to create a file which already exists! Overwriting will not occur unless specified in the create method.\n" ..
                "NAME.create( <name : string>, <overwrites : boolean>  )")
    end

    return file.new(name, true)
end


-- file MUST exist
function module.getFile(name)
    local file = file.new(name, false)
    file.errorIfNonExistent()

    return file
end


-- ask for the file and get it if it exists.

function module.requestFile(name)
    local file = file.new(name, false)

    return file
end







return module