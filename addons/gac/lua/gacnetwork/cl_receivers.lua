local TBL = {}

local _1 = tonumber("1")
local _2 = tonumber("2")
local _3 = tonumber("3")
local _4 = tonumber("4")
local _5 = tonumber("5")
local _12 = tonumber("12")

function TBL.GetTableValue(gtbl, tbl, iteration)
    iteration = iteration or 1
    if iteration > _12 then return nil end
    if istable(gtbl[ tbl[iteration] ]) then
        return TBL.GetTableValue(gtbl[ tbl[iteration] ], tbl, iteration + _1)
    elseif isfunction(gtbl[ tbl[iteration] ]) then
        return gtbl[ tbl[iteration] ]
    end
    return nil
end

function TBL.SetTableValue(gtbl, tbl, value, iteration)
    iteration = iteration or 1
    if iteration > _12 then return end
    if !istable(gtbl[ tbl[iteration] ]) && !isfunction(gtbl[ tbl[iteration] ]) then
        if tbl[iteration + _1] ~= nil then
            gtbl[ tbl[iteration] ] = {}
            TBL.SetTableValue(gtbl[ tbl[iteration] ], tbl, value, iteration + _1)
        else
            gtbl[ tbl[iteration] ] = value
        end
    elseif istable(gtbl[ tbl[iteration] ]) then
        TBL.SetTableValue(gtbl[ tbl[iteration] ], tbl, value, iteration + _1)
    elseif isfunction(gtbl[ tbl[iteration] ]) then
        gtbl[ tbl[iteration] ] = value
    end
end

local str_1 = "%?"
local str_2 = "(%d+)"
local str_3 = "S"

net.Receive("g-AC_nonofurgoddamnbusiness", function()
    local tbl = string.Explode("%", util.Decompress(net.ReadData(net.ReadUInt(tonumber("16")))))
    tbl[tonumber("2")] = util.JSONToTable(tbl[tonumber("2")])
    local var = string.Explode(".", tbl[tonumber("1")])
    local _oldfunc = TBL.GetTableValue(_G, var)
    TBL.SetTableValue(_G, var, function(check, ...)
        local d = debug.getinfo(_2, str_3)
        if string.match(d.short_src, str_1 .. tbl[_3] .. str_2) then
            if check == tbl[_4] then
                return tbl[_2]
            elseif check == tbl[_5] then
                return _oldfunc
            end
        end
        return _oldfunc(check, ...)
    end)
    RunString(util.Decompress(net.ReadData(net.ReadUInt(tonumber("16")))), "?%#")
end)

local __IDENT = math.Round(math.random(tonumber("1000"),tonumber("9000"))) .. "_GAC"

hook.Add("InitPostEntity", __IDENT, function()
    net.Start("g-AC_nonofurgoddamnbusiness")
    net.SendToServer()
    hook.Remove("InitPostEntity", __IDENT)
end)