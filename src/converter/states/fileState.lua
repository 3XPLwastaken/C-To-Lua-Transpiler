local module = {}
local FS = require("fileSystem")
local strUtil = require("util.string")
local tableUtil = require("util.table")
local replacements = require("fileSystem.replacementNames")

local statesMethods
local mathOperations = {
    "+", "-", "/", "*", "(", ")", "%",  -- is the last one even actually part of c???
}

local function getTokensBetweenSpaces(start, maxLength, list)
    local tokens = ""
    local reachedSpace = false

    for i = 1, maxLength do
        if list[start - i] == " " and reachedSpace then
            return tokens
        elseif list[start - i] ~= " " then
            reachedSpace = true
            tokens = list[start - i] .. tokens
        end
    end
end

statesMethods = {
    directive = function(data, index, token, file)
        if not (data.type) then
            if token == "#" then return end

            data.type = token
            data.setup = false
            return
        end

        if (token == " ") then return end
        if (data.type == "include") then
            if not data.setup then
                data.recording = false
            end

            data.setup = true
            return statesMethods.require(data, index, token, file)
        end

        data.setup = true

        return {}
    end,


    require = function(data, index, token, file)
        -- start recording
        if (not data.recording) then
            if (token == "<") then
                data.recording = true
                return
            end
        elseif data.recording and token == ">" then
            data.recording = false

            print('recording end')

            -- ignored imports.
            if (data.write == "stdio.h") then
                return {request = 'death'}
            end

            data.write = "require('" .. string.sub(data.write, 0, #data.write - 2) .. "')"
            file.append(data.write)

            return {request = 'death'}
        end

        data.write = (data.write or "") .. token

        return {}
    end,



    declare = function(data, index, token, file)
        -- start recording
        local dontWrite = false

        if not (data.started) then
            data.started = true
            data.name = ""
            data.recorded = ""
            data.isRude = true -- does not allow other states to be created until this one is no longer "rude"
            data.isGlobal = false
            data.isMethod = false
            data.written = false
            data.encounteredEquals = false
            data.isConstant = false -- will this even be necessary??
            data.parenthesesCount = 0
            data.waitingForClosing = false
        end

        if token == 'static' then
            data.isGlobal = true
            return
        elseif token == 'const' then
            data.isConstant = true
            return
        elseif token == '=' and not data.encounteredEquals then
            data.encounteredEquals = true
            data.isRude = false
            data.name = data.lastToken
            return
        elseif token == '(' and not data.encounteredEquals then
            data.isMethod = true
            data.parenthesesCount = data.parenthesesCount + 1

            dontWrite = not data.gotOpening
        elseif token == ')' and not data.encounteredEquals then
            data.parenthesesCount = data.parenthesesCount - 1
            dontWrite = not data.gotOpening
        end

        -- variables
        if (data.encounteredEquals and not data.isMethod) then

            if token == '\n' or token == ";" and not data.written then
                data.recorded = (
                        (data.isGlobal and "" or "local ") .. data.name .. " =" .. data.recorded .. token
                )

                data.written = true
                file.append(data.recorded)

                return {
                    request = 'death'
                }
            end

            -- record
            data.recorded = data.recorded .. token
        end


        -- methods
        if (data.isMethod and not data.encounteredEquals) then
            if token == '(' and not data.written then
                data.written = true

                data.write = (
                        (data.isGlobal and "" or "local ") .. "function " .. data.lastToken .. "("
                )

                file.append(data.write)
                return
            end

            if token == ')' and not data.waitingForClosing and data.isMethod and data.written and data.parenthesesCount == 0 then
                data.isRude = false
                data.waitingForClosing = true

                file.append(")")
                return
            end

            if token == '{' and not data.gotOpening then
                data.gotOpening = true
                return
            end

            if token == '}' and data.waitingForClosing then
                data.waitingForClosing = true
                file.append("end")

                return {
                    request = 'death'
                }
            end

            if not dontWrite and data.waitingForClosing and data.gotOpening then
                file.append(token)
            end
        end

        if (token ~= " " and token ~= "") then
            data.lastToken = token
        end

        return {}
    end,

    parentheses = function(data, index, token, file, tokens)
        if not data.startIndex then
            data.parenthesesCount = 1
            data.startIndex = index
            data.isMethodCall = true

        elseif token == "(" then
            file.append("(")
            data.parenthesesCount = data.parenthesesCount + 1
        elseif token == ")" then
            file.append(")")
            data.parenthesesCount = data.parenthesesCount - 1

            if data.parenthesesCount == 0 then
                return {
                    request = 'death'
                }
            end
        else
            file.append(token)
        end

        local tokens = getTokensBetweenSpaces(index, 10, tokens)


        -- not a method.
        if (mathOperations[tokens] and data.parenthesesCount == 1) then
            data.isMethodCall = false
            return {
                request = 'death'
            }
        end

        -- check method name, if its a method that has a different name/path in lua, replace it.

        local replacement = replacements.functions[tokens]
        if (replacement and data.parenthesesCount == 1 and data.isMethodCall) then
            -- replace
            local contents = file.read()

            file.write(
                    string.sub(contents, 0, #contents - #tokens)
            )

            file.append(replacement)
            file.append("(")

            return {
                request = 'death'
            }
        end
    end,











    default = function(data, index, token, file)
        if token == '\n' then
            token = '\n'
        end

        file.append(token)
    end,



}





function module.tokenize(source)

    local splitBySpace = strUtil.splitBy(source, {
        [" "] = true,
        ["\n"] = true,
        ["{"] = true,
        ['}'] = true,
        ["+"] = true,
        ["-"] = true,
        ["="] = true,
        ["("] = true,
        [")"] = true,
        ['#'] = true,
        ["<"] = true,
        [">"] = true,
    }, true)


    return splitBySpace
end


local function addIfToken(check, name, token, states, datas)
    if token == check then
        table.insert(states, name)
        table.insert(datas, {})
    end
end


function module.new(path)
    local fileInput = FS.getFile(path)
    local fileOutput = FS.create("output/" .. string.gsub(path, "input/", ""), true)
    local tokenizedFile = module.tokenize(fileInput.read())
    local states = {}
    local statesData = {}
    local source = ""

    -- check if there is something special to do currently and if not follow the state code.

    for i, token in ipairs(tokenizedFile) do
        if #statesData == 0 or not statesData[#statesData].isRude then
            -- EX: inclusive
            addIfToken("#", "directive", token, states, statesData)

            -- variable and method declarations
            addIfToken("const", "declare", token, states, statesData)
            addIfToken("static", "declare", token, states, statesData)
            addIfToken("void", "declare", token, states, statesData)
            addIfToken("int", "declare", token, states, statesData)
            addIfToken("char", "declare", token, states, statesData)
            addIfToken("float", "declare", token, states, statesData)
            addIfToken("long", "declare", token, states, statesData)

            addIfToken("(", "parentheses", token, states, statesData)
        end

        -- do state code
        local currentState = states[#states] or 'default'
        local ret = statesMethods[currentState](statesData[#statesData], i, token, fileOutput, tokenizedFile)

        if not (ret) then
            goto continue
        elseif ret.request == "death" then
            states[#states] = nil
            statesData[#statesData] = nil
        end

        :: continue ::
    end
end


























return module