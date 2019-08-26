local _debug_getinfo = debug.getinfo
local _debug_getregistry = debug.getregistry
local _jit_util_funcinfo = jit.util.funcinfo
local _jit_util_funcbc = jit.util.funcbc
local _jit_attach = jit.attach
local _tostring = tostring
local _istable = istable
local _math_random = math.random
local _bit_rol = bit.rol
local _util_TableToJSON = util.TableToJSON
local _bit_band = bit.band
local _bit_rshift = bit.rshift
local _string_char = string.char
local _string_gsub = string.gsub
local _string_sub = string.sub
local _timer_Simple = timer.Simple
local _tonumber = tonumber
local _table_concat = table.concat
local _net_ReadData = net.ReadData
local _net_Receive = net.Receive
local _string_Explode = string.Explode
local _table_remove = table.remove
local _util_CRC = util.CRC
local _math_ceil = math.ceil
local _util_Compress = util.Compress
local _util_Decompress = util.Decompress
local _util_JSONToTable = util.JSONToTable
local _string_match = string.match
local _net_Start = net.Start
local _net_SendToServer = net.SendToServer
local _net_WriteUInt = net.WriteUInt
local _net_WriteData = net.WriteData
local _CompileString = CompileString
local _hook_Add = hook.Add
local _hook_Remove = hook.Remove
local _engine_TickInterval = engine.TickInterval

local _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _1000, _9000 = 0,1,2,3,4,5,6,7,8,9,10,11,12,13,1000,9000
local __5, _97, _65, _49, _122, _90, _57, _26, _15, _32, _16, _30, _24 = .5,97,65,49,122,90,57,26,15,32,16,30,24
local _250 = 250

local function floor(number)
    return number - (number % _1)
end

local function bxor (a,b)
    local r = _0
    for i = _0, 31 do
        local x = (a * __5) + (b * __5)
        if x ~= floor (x) then
        r = r + _2^i
        end
        a = floor (a * __5)
        b = floor (b * __5)
    end
    return r
end

local _gAC = {
    OrigFuncs = {},
    OrigNames = {},
    ToSend = {},
    AntiLua = true
}

local _Tick = _1/_engine_TickInterval()

function _gAC._D( old, new, name )
    name = name or ""
    _gAC.OrigFuncs[new] = old
    _gAC.OrigNames[new] = name
    return new
end 

function _gAC.hs(str)
    local len = #str
    for i=_1, #str do
        len = bxor(len, _bit_rol(len, _6) + str:byte(i))
    end
    return _bit_rol(len, _3)
end

function _gAC.dirtosvlua(loc)
    local _loc = loc
    _loc = _string_Explode("/",_loc)
    if _loc[1] == "addons" then 
        _table_remove(_loc, 1)
        _table_remove(_loc, 1)
        _table_remove(_loc, 1)
        loc = _table_concat(_loc,"/")
    elseif _loc[1] == "lua" then
        _table_remove(_loc, 1)
        loc = _table_concat(_loc,"/")
    elseif _loc[1] == "gamemodes" then
        _table_remove(_loc, 1)
        loc = _table_concat(_loc,"/")
    end
    return loc
end

function _gAC.stringrandom(length)
	local str = ""
	for i = _1, length do
		local typo =  floor(_math_random(_1, _4) + __5)
		if typo == _1 then
			str = str.. _string_char(_math_random(_97, _122))
		elseif typo == _2 then
			str = str.. _string_char(_math_random(_65, _90))
		elseif typo == _3 then
			str = str.. _string_char(_math_random(_49, _57))
		end
	end
	return str
end

local SafeCode = _gAC.stringrandom(floor(_math_random(_12, _32) + __5))

function _gAC.GetTableValue(gtbl, tbl)
    local TBL = gtbl
    for k=_1, #tbl do
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

function _gAC.SetTableValue(gtbl, tbl, value)
    local TBL = gtbl
    for k=_1, #tbl do
        local v = tbl[k]
        if k ~= #tbl then
            if TBL[v] == nil then
                TBL[v] = {}
                TBL = TBL[v]
            elseif _istable(TBL[v]) then
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

function _gAC.SendBuffer(data)
    if !_gAC.AntiLua then return end
    local ID = #_gAC.ToSend
    if ID < _1 then
        _gAC.ToSend[_1] = { [_1] = data }
    elseif !_gAC.ToSend[ID] then
        _gAC.ToSend[ID] = { [_1] = data }
    elseif #_gAC.ToSend[ID] >= _250 then
        _gAC.ToSend[ID + _1] = { [_1] = data }
    else
        _gAC.ToSend[ID][#_gAC.ToSend[ID] + _1] = data
    end
end

function _gAC.CompileData(data)
    return {
        func = data.func,
        source = data.source,
        short_src = data.short_src,
        what = data.what,
        lastlinedefined = data.lastlinedefined,
        linedefined = data.linedefined,
        proto = data.proto,
        funcname = data.funcname,
        execidentifier = data.execidentifier
    }
end

local opcodemap =
{
	[0x49] = 0x49,
	[0x4A] = 0x49,
	[0x4B] = 0x4B,
	[0x4C] = 0x4B,
	[0x4D] = 0x4B,
	[0x4E] = 0x4E,
	[0x4F] = 0x4E,
	[0x50] = 0x4E,
	[0x51] = 0x51,
	[0x52] = 0x51,
	[0x53] = 0x51,
}

local opcodemap2 =
{
	[0x44] = 0x54,
	[0x42] = 0x41,
}

local function bytecodetoproto(func, funcinfo)
    local data = {}
    for i = _1, funcinfo.bytecodes - _1 do
        local bytecode = _jit_util_funcbc (func, i)
        local byte = _bit_band (bytecode, 0xFF)
        if opcodemap[byte] then
            bytecode = opcodemap[byte]
        end
        if opcodemap2[byte] then
            bytecode = bytecode - byte
            bytecode = bytecode + opcodemap2[byte]
        end
        data [#data + _1] = _string_char (
            _bit_band (bytecode, 0xFF),
            _bit_band (_bit_rshift(bytecode,  _8), 0xFF),
            _bit_band (_bit_rshift(bytecode, _16), 0xFF),
            _bit_band (_bit_rshift(bytecode, _24), 0xFF)
        )
    end
    return _tonumber(_util_CRC(_table_concat(data)))
end

_gAC.LuaVM = function(proto)
    local jitinfo = _jit_util_funcinfo(proto)
    jitinfo.source = _string_gsub(jitinfo.source, "^@", "")
    if jitinfo.source == SafeCode then return end
    jitinfo.source = _gAC.dirtosvlua(jitinfo.source)
    jitinfo.proto = bytecodetoproto(proto, jitinfo)
    _gAC.SendBuffer(_gAC.CompileData(jitinfo))
end

local Detourables = {
    {{"hook","Add"}, "hook.Add"},
    {{"hook","Remove"}, "hook.Remove"},
    {{"hook","GetTable"}, "hook.GetTable"},
    {{"surface","CreateFont"}, "surface.CreateFont"},
    {{"concommand","Add"}, "concommand.Add"},
    {{"AddConsoleCommand"}, "AddConsoleCommand"}
}

for k=_1, #Detourables do
    local v = Detourables[k]
    local func = _gAC.GetTableValue(_G, v[_1])
    if func == nil then continue end
    local newfunc = _gAC._D( func, function(...)
        local dbginfo = _debug_getinfo(_2, "fS")
        dbginfo.funcname = v[_2]
        dbginfo.func = _tostring(dbginfo.func)
        dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
        dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
        _gAC.SendBuffer(_gAC.CompileData(dbginfo))
        return func(...)
    end, funcname )
    _gAC.SetTableValue(_G, v[_1], newfunc)
end

local _RunString = RunString
RunString = _gAC._D( RunString, function(code, ident, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if func == nil then return err end
    if ident then
        ident = ident .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    else
        ident = "RunString-" .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    end
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "RunString"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    return _RunString(code, ident, ...)
end, "RunString" )

local _RunStringEx = RunStringEx
RunStringEx = _gAC._D( RunStringEx, function(code, ident, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if func == nil then return err end
    if ident then
        ident = ident .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    else
        ident = "RunStringEx-" .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    end
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "RunStringEx"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    return _RunStringEx(code, ident, ...)
end, "RunStringEx" )

CompileString = _gAC._D( CompileString, function(code, ident, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if func == nil then return nil, err end
    if ident then
        ident = ident .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    else
        ident = "CompileString-" .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))
    end
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "CompileString"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    return _CompileString(code, ident, ...)
end, "CompileString" )

local _Det_CompileString = CompileString

local HASHID = _gAC.hs('bc')

local _R = _debug_getregistry()
_R._VMEVENTS = _R._VMEVENTS or {}
_R._VMEVENTS[HASHID] = _gAC.LuaVM

_jit_attach(function() end, "")

local ID = _gAC.stringrandom(floor(_math_random(_12, _26) + __5))
local Interval = _15*_Tick
local TickTime = Interval - _1

_hook_Add( "Tick", ID, function()
    if _R._VMEVENTS[HASHID] ~= _gAC.LuaVM then
        _R._VMEVENTS[HASHID] = _gAC.LuaVM
    end
    if _gAC.gAC_Send && TickTime > Interval then
        _gAC.AntiLua = gAC.config.AntiLua_CHECK
        if _gAC.AntiLua then
            local data = _gAC.ToSend[_1]
            if data then
                _gAC.gAC_Send("g-AC_LuaExec", _util_TableToJSON(data))
                _table_remove(_gAC.ToSend, _1)
            else
                _gAC.gAC_Send("g-AC_LuaExec", "1")
            end
        end
        TickTime = _0
    end
    TickTime = TickTime + _1
end ) 

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
    local _oldfunc = _gAC.GetTableValue(_G, var)
    if _oldfunc == nil then
        return 
    end

    local succ = _gAC.SetTableValue(_G, var, function(check, ...)
        local d = _debug_getinfo(_2, "S")
        if _string_match(d.short_src, codec[_8] .. codec[_11] .. "%w+") == d.short_src then
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

    _gAC.gAC_Send = function(channelName, data)
        data = _util_Compress(data)
        _net_Start(codec[_3])
            _net_WriteUInt (_tonumber(_util_CRC (channelName .. codec[_5])), _32)
            _net_WriteData (data, #data)
        _net_SendToServer()
    end

    local func = _Det_CompileString( codec[_1], codec[_2] )
    func(codec)
end)

local __IDENT = _gAC.stringrandom(floor(_math_random(_12, _26) + __5))

_hook_Add("InitPostEntity", __IDENT, function()
    _net_Start("g-AC_nonofurgoddamnbusiness")
    _net_SendToServer()
    _hook_Remove("InitPostEntity", __IDENT)
end)
