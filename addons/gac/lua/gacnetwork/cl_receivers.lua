local _CompileString = CompileString
local _net_ReadData = net.ReadData
local _net_Receive = net.Receive
local _string_Explode = string.Explode
local _util_Decompress = util.Decompress
local _util_JSONToTable = util.JSONToTable
local _debug_getinfo = debug.getinfo
local _string_match = string.match
local _hook_Add = hook.Add
local _hook_Remove = hook.Remove
local _net_Start = net.Start
local _net_SendToServer = net.SendToServer
local _math_floor = math.floor
local _math_random = math.random
local _istable = istable
local _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _1000, _9000 = 1,2,3,4,5,6,7,8,9,10,11,12,1000,9000

local TBL = {}

function TBL.GetTableValue(gtbl, tbl)
    local TBL = gtbl
    for k=1, #tbl do
        local v = tbl[k]
        if _istable(TBL[v]) then
            TBL = TBL[v]
        elseif k == #tbl then
            return TBL[v]
        else
            return nil 
        end
    end
    return nil
end

function TBL.SetTableValue(gtbl, tbl, value)
    local TBL = gtbl
    for k=1, #tbl do
        local v = tbl[k]
        if k ~= #tbl then
            if !_istable(TBL[v]) then
                TBL[v] = {}
                TBL = TBL[v]
            elseif TBL[v] == nil or _istable(TBL[v]) then
                TBL = TBL[v]
            else
                return false
            end
        else
            TBL[v] = value
            return true
        end
    end
    return false
end

_net_Receive("g-AC_nonofurgoddamnbusiness", function(len)
    local codec = _string_Explode("[EXLD]", _net_ReadData(len))
    for i=_1, #codec do
        if i == #codec then
            codec[i] = codec[i]:sub(_1, codec[i]:len()-_2)
        end
        codec[i] = _util_Decompress(codec[i])
    end

    codec[_10] = _util_JSONToTable(codec[_10])

    local var = _string_Explode(".", codec[_9])
    local _oldfunc = TBL.GetTableValue(_G, var)
    if _oldfunc == nil then
        return 
    end

    local succ = TBL.SetTableValue(_G, var, function(check, ...)
        local d = _debug_getinfo(_2, "S")
        if _string_match(d.short_src, codec[_8] .. codec[_11] .. "%d+") then
            if check == codec[_12] then
                return codec[_10]
            elseif check == codec[_13] then
                return _oldfunc
            end
        end
        return _oldfunc(check, ...)
    end)

    if succ == false then
        return 
    end

    local func = _CompileString( codec[_1], codec[_2] )
    func(codec)
end)

local __IDENT = _math_floor(_math_random(_1000,_9000)) .. "_GAC"

_hook_Add("InitPostEntity", __IDENT, function()
    _net_Start("g-AC_nonofurgoddamnbusiness")
    _net_SendToServer()
    _hook_Remove("InitPostEntity", __IDENT)
end)
