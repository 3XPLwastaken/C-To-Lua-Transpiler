local module = {}


function module.print(table, tabs)
    local tabs = tabs or ""
    local tabsPlus = tabs .. "\t"
    print(tabs .. "{")

    for i, v in pairs(table) do
        local type = type(v)
        local output = v

        if (type == 'table') then
            module.print(output, tabsPlus)
            goto continue
        elseif (type == 'string') then
            output = '"' .. tostring(output) .. '"'
        else
            output = tostring(output)
        end

        print(tabsPlus .. output .. ",")

        ::continue::
    end

    print(tabs .. "}")
end


return module