local _debug_getinfo = debug.getinfo
local _debug_getregistry = debug.getregistry
local _jit_util_funcinfo = jit.util.funcinfo
local _jit_attach = jit.attach
local _tostring = tostring
local _math_random = math.random
local _bit_rol = bit.rol

local _hook_Add = hook.Add
local _hook_Remove = hook.Remove

local function floor(number)
    return number - (number % 1)
end

local function bxor (a,b)
    local r = 0
    for i = 0, 31 do
        local x = (a * .5) + (b * .5)
        if x ~= floor (x) then
        r = r + 2^i
        end
        a = floor (a * .5)
        b = floor (b * .5)
    end
    return r
end

local _LuaD = {
    OrigFuncs = {}
    OrigNames = {}
    _R = _debug_getregistry()
}

function _LuaD._D( old, new, name )
    name = name or ""
    _LuaD.OrigFuncs[new] = old
    _LuaD.OrigNames[new] = name
    return new
end 

function _LuaD.hs(str)
    local len = #str
    for i=1, #str do
        len = bxor(len, _bit_rol(len, 6) + str:byte(i))
    end
    return _bit_rol(len, 3)
end

hook.Add = _LuaD._D( hook.Add, function(...)
    gAC_Send("g-AC_CheckLuaExec", _util_TableToJSON(_debug_getinfo(2)))
    return _hook_Add(...)
end, "hook.Add" )

hook.Remove = _LuaD._D( hook.Remove, function(...)
    gAC_Send("g-AC_CheckLuaExec", _util_TableToJSON(_debug_getinfo(2)))
    return _hook_Remove(...)
end, "hook.Remove" )

_LuaD.LuaVM = function(proto)
    local jitinfo = jit.util.funcinfo(proto)
    jitinfo["bytecodes"] = jit.util.funcbc(proto, jitinfo["bytecodes"]) or 1
    gAC_Send("g-AC_CompileExec", _util_TableToJSON(jitinfo))
end

local HASHID = _LuaD.hs('bc')

_LuaD._R._VMEVENTS = _LuaD._R._VMEVENTS or {}
_LuaD._R._VMEVENTS[HASHID] = _LuaD.LuaVM

_jit_attach(function() end, "")

local ID = _tostring(floor(_math_random(10000, 90000) + 0.5))

_hook_Add( "Tick", ID, function()
    if _LuaD._R._VMEVENTS[HASHID] ~= _LuaD.LuaVM then
        _LuaD._R._VMEVENTS[HASHID] = _LuaD.LuaVM
        gAC_Send("g-AC_Detections", _util_TableToJSON({
            "Lua Manipulation on LuaVM", 
            true,
            -1
        }))
        _hook_Remove("Tick", ID)
    end
end ) 