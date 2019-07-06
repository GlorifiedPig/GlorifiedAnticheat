local TBL = {}

function TBL.GetTableValue(gtbl, tbl, iteration)
    iteration = iteration or tonumber("1")
    if iteration > tonumber("14") then return nil end
    if istable(gtbl[ tbl[iteration] ]) then
        return TBL.GetTableValue(gtbl[ tbl[iteration] ], tbl, iteration + tonumber("1"))
    elseif isfunction(gtbl[ tbl[iteration] ]) then
        return gtbl[ tbl[iteration] ]
    end
    return nil
end

function TBL.SetTableValue(gtbl, tbl, value, iteration)
    iteration = iteration or tonumber("1")
    if iteration > tonumber("14") then return end
    if !istable(gtbl[ tbl[iteration] ]) && !isfunction(gtbl[ tbl[iteration] ]) then
        if tbl[iteration + tonumber("1")] ~= nil then
            gtbl[ tbl[iteration] ] = {}
            TBL.SetTableValue(gtbl[ tbl[iteration] ], tbl, value, iteration + tonumber("1"))
        else
            gtbl[ tbl[iteration] ] = value
        end
    elseif istable(gtbl[ tbl[iteration] ]) then
        TBL.SetTableValue(gtbl[ tbl[iteration] ], tbl, value, iteration + tonumber("1"))
    elseif isfunction(gtbl[ tbl[iteration] ]) then
        gtbl[ tbl[iteration] ] = value
    end
end

net.Receive("g-AC_nonofurgoddamnbusiness", function()
    local tbl = string.Explode("%", util.Decompress(net.ReadData(net.ReadUInt(tonumber("16")))))
    tbl[tonumber("2")] = util.JSONToTable(tbl[tonumber("2")])
    local var = string.Explode(".", tbl[tonumber("1")])
    local _oldfunc = TBL.GetTableValue(_G, var)
    TBL.SetTableValue(_G, var, function(check, ...)
        local d = debug.getinfo(tonumber("2"), "S")
        if string.match(d.short_src, "%?" .. tbl[tonumber("3")] .. "(%d+)") then
            if check == tbl[tonumber("4")] then
                return tbl[tonumber("2")]
            elseif check == tbl[tonumber("5")] then
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