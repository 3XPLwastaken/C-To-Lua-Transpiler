local module = {}


function module.split(str, spliterator, inclusive)
    local splitBy = {}
    local segment = ""

    for i = 1, #str do
        local char = string.sub(str, i, i)

        if char == spliterator then
            table.insert(splitBy, segment)

            if (inclusive) then
                table.insert(splitBy, spliterator)
            end

            segment = ""
            goto continue
        end

        segment = segment .. char

        :: continue ::
    end

    return splitBy
end


function module.splitBy(str, spliterators, inclusive)
    local splitBy = {}
    local segment = ""

    for i = 1, #str do
        local char = string.sub(str, i, i)

        if spliterators[char] then
            table.insert(splitBy, segment)

            if (inclusive) then
                table.insert(splitBy, char)
            end

            segment = ""
            goto continue
        end

        segment = segment .. char

        :: continue ::
    end

    table.insert(splitBy, segment)

    return splitBy
end





return module