local methods = {}
local state = require("converter.states.fileState")

function methods.convert(mainFileName, config)
    local config = config or {}
    local outputLocation = config.output == nil and "output/" or config.output
    local inputLocation = config.input == nil and "input/" or config.inputLocation
    local isLuaDLL = mainFileName == nil --[[ incase we are trying to convert a lua DLL to C code
    (which is probably the most common use case.]]

    -- TODO: add a system to parse a DLL into C code (IF POSSIBLE).


    state.new(inputLocation .. (mainFileName or "main.c"))
end







return methods