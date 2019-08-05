local _isfunction = isfunction
local _istable = istable
local _pcall = pcall
local _tonumber = tonumber
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON
local _coroutine_create = coroutine.create
local _coroutine_resume = coroutine.resume
local _string_Explode = string.Explode
local _tostring = tostring
local _string_format = string.format
local _string_dump = string.dump
local _jit_off = jit.off
local _jit_on = jit.on
local _jit_flush = jit.flush

--[[
    Note, This is a detection method was created by Cake himself, i've just reworked some areas which are critical in detections
    
    How this works,
        Due to an update pushed by Gmod Developers,
        functions like debug.setupvalue became depreciated
        and removed due to security concerns which is correct.
        However in C++ you can re-add these function into the debug library
        So if they exists it would mean the user is likely cheating & altering variables in lua stack.

        The function detour_check determines if a function has been detoured
        if it's been detoured by meth, it would come out with a different number
        which would be the amount of iterations that could be accompished before failing.
        Detours cause this number to decrease over time.

        NOTE: This function is BYPASSABLE!
        I've tested this with my own cheat which uses setupvalue to alter detour_check's local variables 'level'
        Used debug.getupvalue to get the function that was pushed into coroutine to search for 'level',
        once found use debug.setupvalue to alter the variable's value to the correct value.

        This is still experimental - NiceCream
]]

local Utils = {}

function Utils.GetTableValue(gtbl, tbl, iteration)
    iteration = iteration or _tonumber("1")
    if iteration > _tonumber("14") then return nil end
    if _istable(gtbl[ tbl[iteration] ]) then
        return Utils.GetTableValue(gtbl[ tbl[iteration] ], tbl, iteration + _tonumber("1"))
    elseif _isfunction(gtbl[ tbl[iteration] ]) then
        return gtbl[ tbl[iteration] ]
    end
    return nil
end

gAC_AddReceiver("g-ACDebugLibResponse", function(_, data)
    local err = _pcall(function()
        local response = {}

        local function detour_check (var1, var2, var3)
            local level = 0
            local __ = 0 -- if they do getupvalue it will go here instead
            local thread = _coroutine_create(function()
                local function _func() -- Remember that string stripper converts this to local _func = function(), make sure this does not happen.
                    var1(var2, var3)
                    level = level + 1
                    _func()
                end
                _func()
            end)
            _coroutine_resume(thread)
            return level
        end

        data = _util_JSONToTable(data)

        local id
        for k=1, #data do
        	local v = data[k]
            if v["type"] then
                if v["check_01"] ~= nil then
                    id = #response + 1
                    response[id] = {}
                    response[id]["check_01"] = (Utils.GetTableValue(_G, _string_Explode(".", v["type"])) ~= nil)
                    continue
                end
                v["type"] = Utils.GetTableValue(_G, _string_Explode(".", v["type"]))
                if v["type"] == nil then continue end
                id = #response + 1
                response[id] = {}
                if v["check_02"] ~= nil then
                    _jit_off()
                    _jit_flush()
                    response[id]["check_02"] = detour_check(v["type"], v["check_02_ext"] and function() end or v["type"])
                    _jit_on()
                end
                if v["check_03"] ~= nil then
                    response[id]["check_03"] = _tostring(v["type"])
                    response[id]["check_03_ext"] = _string_format("%s",v["type"])
                end
                if v["check_04"] ~= nil then
                    response[id]["check_04"] = _pcall(_string_dump,v["type"])
                end
            end
        end

        gAC_Send("g-ACDebugLibResponse", _util_TableToJSON(response))
    end)
    if !err then
        gAC_Send("g-ACDebugLibResponse", "1")
    end
end)