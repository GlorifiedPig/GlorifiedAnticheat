local function InitRendering()
    if ( !render ) then return end

    --[[---------------------------------------------------------
    Short aliases for stencil constants
    -----------------------------------------------------------]]  

    STENCIL_NEVER = STENCILCOMPARISONFUNCTION_NEVER
    STENCIL_LESS = STENCILCOMPARISONFUNCTION_LESS
    STENCIL_EQUAL = STENCILCOMPARISONFUNCTION_EQUAL
    STENCIL_LESSEQUAL = STENCILCOMPARISONFUNCTION_LESSEQUAL
    STENCIL_GREATER = STENCILCOMPARISONFUNCTION_GREATER
    STENCIL_NOTEQUAL = STENCILCOMPARISONFUNCTION_NOTEQUAL
    STENCIL_GREATEREQUAL = STENCILCOMPARISONFUNCTION_GREATEREQUAL
    STENCIL_ALWAYS = STENCILCOMPARISONFUNCTION_ALWAYS

    STENCIL_KEEP = STENCILOPERATION_KEEP
    STENCIL_ZERO = STENCILOPERATION_ZERO
    STENCIL_REPLACE = STENCILOPERATION_REPLACE
    STENCIL_INCRSAT = STENCILOPERATION_INCRSAT
    STENCIL_DECRSAT = STENCILOPERATION_DECRSAT
    STENCIL_INVERT = STENCILOPERATION_INVERT
    STENCIL_INCR = STENCILOPERATION_INCR
    STENCIL_DECR = STENCILOPERATION_DECR

    --[[---------------------------------------------------------
    Name:	ClearRenderTarget
    Params: 	<texture> <color>
    Desc:	Clear a render target
    -----------------------------------------------------------]]   
    function render.ClearRenderTarget( rt, color )

        local OldRT = render.GetRenderTarget();
            render.SetRenderTarget( rt )
            render.Clear( color.r, color.g, color.b, color.a )
        render.SetRenderTarget( OldRT )

    end


    --[[---------------------------------------------------------
    Name:	SupportsHDR
    Params: 	
    Desc:	Return true if the client supports HDR
    -----------------------------------------------------------]]   
    function render.SupportsHDR( )

        if ( render.GetDXLevel() < 80 ) then return false end

        return true
        
    end


    --[[---------------------------------------------------------
    Name:	CopyTexture
    Params: 	<texture from> <texture to>
    Desc:	Copy the contents of one texture to another
    -----------------------------------------------------------]]   
    function render.CopyTexture( from, to )

        local OldRT = render.GetRenderTarget();
            
            render.SetRenderTarget( from )
            render.CopyRenderTargetToTexture( to )
            
        render.SetRenderTarget( OldRT )

    end

    local matColor = Material( "color" )

    function render.SetColorMaterial()
        render.SetMaterial( matColor )
    end

    local matColorIgnoreZ = Material( "color_ignorez" )

    function render.SetColorMaterialIgnoreZ()
        render.SetMaterial( matColorIgnoreZ )
    end

    local mat_BlurX			= Material( "pp/blurx" )
    local mat_BlurY			= Material( "pp/blury" )
    local tex_Bloom1		= render.GetBloomTex1()

    function render.BlurRenderTarget( rt, sizex, sizey, passes )

        mat_BlurX:SetTexture( "$basetexture", rt )
        mat_BlurY:SetTexture( "$basetexture", tex_Bloom1  )
        mat_BlurX:SetFloat( "$size", sizex )
        mat_BlurY:SetFloat( "$size", sizey )
        
        for i=1, passes+1 do

            render.SetRenderTarget( tex_Bloom1 )
            render.SetMaterial( mat_BlurX )
            render.DrawScreenQuad()

            render.SetRenderTarget( rt )
            render.SetMaterial( mat_BlurY )
            render.DrawScreenQuad()

        end

    end

    function cam.Start2D()

        return cam.Start( { type = '2D' } )

    end

    function cam.Start3D( pos, ang, fov, x, y, w, h, znear, zfar )

        local tab = {}

        tab.type = '3D';
        tab.origin = pos
        tab.angles = ang

        if ( fov != nil ) then tab.fov = fov end

        if ( x != nil && y != nil && w != nil && h != nil ) then

            tab.x			= x
            tab.y			= y
            tab.w			= w
            tab.h			= h
            tab.aspect		= (w / h)

        end

        if ( znear != nil && zfar != nil ) then

            tab.znear	= znear
            tab.zfar	= zfar

        end

        return cam.Start( tab )

    end

    local matFSB			= Material( "pp/motionblur" )

    function render.DrawTextureToScreen( tex )

        matFSB:SetFloat( "$alpha", 1.0 )
        matFSB:SetTexture( "$basetexture", tex )

        render.SetMaterial( matFSB )
        render.DrawScreenQuad()

    end

    function render.DrawTextureToScreenRect( tex, x, y, w, h )

        matFSB:SetFloat( "$alpha", 1.0 )
        matFSB:SetTexture( "$basetexture", tex )

        render.SetMaterial( matFSB )
        render.DrawScreenQuadEx( x, y, w, h )

    end


    --
    -- This isn't very fast. If you're doing something every frame you should find a way to 
    -- cache a ClientsideModel and keep it around! This is fine for rendering to a render 
    -- target once - or something.
    --

    function render.Model( tbl, ent )

        local inent = ent

        if ( ent == nil ) then
            ent = ClientsideModel( tbl.model or "error.mdl", RENDERGROUP_OTHER )
        end
        
        if ( !IsValid( ent ) ) then return end

        ent:SetModel( tbl.model or "error.mdl" )
        ent:SetNoDraw( true )

        ent:SetPos( tbl.pos or Vector( 0, 0, 0 ) )
        ent:SetAngles( tbl.angle or Angle( 0, 0, 0 ) )
        ent:DrawModel()

        --
        -- If we created the model, then remove it!
        --
        if ( inent != ent ) then
            ent:Remove()
        end

    end
end
InitRendering()

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
local _isfunction = isfunction
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
local _FindMetaTable = FindMetaTable
local _util_NetworkStringToID = util.NetworkStringToID

local _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _1000, _9000 = 0,1,2,3,4,5,6,7,8,9,10,11,12,13,1000,9000
local __5, _97, _65, _49, _122, _90, _57, _26, _15, _32, _16, _30, _24 = .5,97,65,49,122,90,57,26,15,32,16,30,24
local _500 = 500

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

local SafeCode = _string_char(_10) .. _gAC.stringrandom(floor(_math_random(_12, _32) + __5))

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
    elseif #_gAC.ToSend[ID] >= _500 then
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
        funcname = data.funcname,
        code = data.code,
        proto = data.proto,
        execidentifier = data.execidentifier
    }
end

local opcodemap = {
	[0x46] = 0x51,
	[0x47] = 0x51,
	[0x48] = 0x51,
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
	[0x53] = 0x51
}

local opcodemap2 = {
	[0x44] = 0x54,
	[0x42] = 0x41
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
            _bit_band (_bit_rshift(bytecode,  8), 0xFF),
            _bit_band (_bit_rshift(bytecode, 16), 0xFF),
            _bit_band (_bit_rshift(bytecode, 24), 0xFF)
        )
    end
    return _tonumber(_util_CRC(_table_concat(data)))
end

_gAC.BCJitFuncs = {}

local function LuaVMResponse(...)
    if _gAC.BCJitFuncs['bc'] then
        _gAC.BCJitFuncs['bc'](...)
    end
end

_gAC.LuaVM = function(proto, ...)
    local jitinfo = _jit_util_funcinfo(proto)
    jitinfo.source = _string_gsub(jitinfo.source, "^@", "")
    if jitinfo.source == SafeCode then return LuaVMResponse(proto, ...) end
    jitinfo.source = _gAC.dirtosvlua(jitinfo.source)
    jitinfo.proto = bytecodetoproto(proto, jitinfo)
    _gAC.SendBuffer(_gAC.CompileData(jitinfo))
    LuaVMResponse(proto, ...)
end

local Detourables = {
    {{"hook","Add"}, "hook.Add"},
    {{"hook","Remove"}, "hook.Remove"},
    {{"hook","GetTable"}, "hook.GetTable"},
    {{"surface","CreateFont"}, "surface.CreateFont"},
    {{"AddConsoleCommand"}, "AddConsoleCommand"}
}

for k=_1, #Detourables do
    local v = Detourables[k]
    local func = _gAC.GetTableValue(_G, v[_1])
    if func == nil or !_isfunction(func) then continue end
    local newfunc = _gAC._D( func, function(...)
        local dbginfo = _debug_getinfo(_2, "fS")
        dbginfo.funcname = v[_2]
        dbginfo.func = _tostring(dbginfo.func)
        dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
        dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
        _gAC.SendBuffer(_gAC.CompileData(dbginfo))
        return func(...)
    end, v[_2] )
    _gAC.SetTableValue(_G, v[_1], newfunc)
end

local MetaTables = {
    ['Player'] = _FindMetaTable('Player'),
    ['Entity'] = _FindMetaTable('Entity'),
    ['CUserCmd'] = _FindMetaTable('CUserCmd'),
}

local MetaDetourables = {
    {"Player", "ConCommand"},
}

for k=_1, #MetaDetourables do
    local v = MetaDetourables[k]
    local func = nil
    if MetaTables[v[_1]] then
        local meta = MetaTables[v[_1]]
        if meta[v[_2]] and _isfunction(meta[v[_2]]) then
            func = meta[v[_2]]
        end
    end
    if func == nil then continue end
    local newfunc = _gAC._D( func, function(...)
        local dbginfo = _debug_getinfo(_2, "fS")
        dbginfo.funcname = v[_1] .. ':' .. v[_2]
        dbginfo.func = _tostring(dbginfo.func)
        dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
        dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
        _gAC.SendBuffer(_gAC.CompileData(dbginfo))
        return func(...)
    end, v[_1] .. ':' .. v[_2] )
    MetaTables[v[_1]][v[_2]] = newfunc
end

local CompileID = 0
local Compiled = {}

function _gAC.CreateIdentifier(ident, funcname)
    if ident then
        if Compiled[ident] then
            CompileID = CompileID + 1
            ident = ident .. CompileID
        end
    else
        ident = funcname
        if Compiled[ident] then
            CompileID = CompileID + 1
            ident = funcname .. CompileID
        end
    end
    Compiled[ident] = true
    return ident
end

local _RunString = _G.RunString
_G.RunString = _gAC._D( _G.RunString, function(code, ident, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if !func && err then return err end
    ident = _gAC.CreateIdentifier(ident, "RunString")
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "RunString"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.code = code
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    func = _CompileString(code, ident)
    return func()
end, "RunString" )

local _RunStringEx = _G.RunStringEx
_G.RunStringEx = _gAC._D( _G.RunStringEx, function(code, ident, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if !func && err then return err end
    ident = _gAC.CreateIdentifier(ident, "RunStringEx")
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "RunStringEx"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.code = code
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    func = _CompileString(code, ident)
    return func()
end, "RunStringEx" )

_G.CompileString = _gAC._D( _G.CompileString, function(code, ident, safemode, ...)
    local func, err = _CompileString(code, SafeCode, false)
    if !func && err then return nil, err end
    ident = _gAC.CreateIdentifier(ident, "CompileString")
    local dbginfo = _debug_getinfo(_2, "fS")
    dbginfo.funcname = "CompileString"
    dbginfo.func = _tostring(dbginfo.func)
    dbginfo.execidentifier = ident
    dbginfo.code = code
    dbginfo.source = _string_gsub(dbginfo.source, "^@", "")
    dbginfo.source = _gAC.dirtosvlua(dbginfo.source)
    _gAC.SendBuffer(_gAC.CompileData(dbginfo))
    return _CompileString(code, ident, safemode)
end, "CompileString" )

local _gACCompile = _G.CompileString
local _gACRunCode = _G.RunString

local HASHID = _gAC.hs('bc')

local _R = _debug_getregistry()
_R._VMEVENTS = _R._VMEVENTS or {}
_R._VMEVENTS[HASHID] = _gAC.LuaVM

_jit_attach(function() end, "")

jit.attach = _gAC._D( _jit_attach, function(func, ident, ...)
    if ident == 'bc' && _isfunction(func) then
        _gAC.BCJitFuncs['bc'] = func
        return
    end
    return _jit_attach(func, ident, ...)
end, "jit.attach" )

local ID = _gAC.stringrandom(floor(_math_random(_12, _26) + __5))

_hook_Add( "PostGamemodeLoaded", ID, function()
    if gAC.config.AntiLua_IgnoreBoot then
        _gAC.ToSend = {}
    end
    _hook_Remove("PostGamemodeLoaded", ID)
end )

_net_Receive("gAC.PlayerInit", function(len)
    local codec = _string_Explode("[EXLD]", _net_ReadData(len))
    for i=_1, #codec do
        if i == #codec then
            codec[i] = codec[i]:sub(_1, codec[i]:len()-_2)
        end
        codec[i] = _util_Decompress(codec[i])
    end

    codec[_9] = _util_JSONToTable(codec[_9])

    local var = _string_Explode(".", codec[_8])
    local _oldfunc = _gAC.GetTableValue(_G, var)
    if _oldfunc == nil then
        return 
    end

    local succ = _gAC.SetTableValue(_G, var, function(check, ...)
        local d = _debug_getinfo(_2, "S")
        if _string_match(d.short_src, codec[_7] .. codec[_10] .. "%d+") == d.short_src then
            if check == codec[_11] then
                return codec[_9]
            elseif check == codec[_12] then
                return _oldfunc
            end
        end
        return _oldfunc(check, ...)
    end)

    if succ == false then
        return 
    end

    local func = _gACCompile( codec[_1], codec[_2] )
    local gAC_Send, gAC_Stream, gAC_AddReceiver = func(codec, _gACCompile, _gACRunCode)

    _gAC.gAC_Send = gAC_Send
    _gAC.gAC_Stream = gAC_Stream

    gAC_AddReceiver('g-AC_LuaExec', function(data)
        if _gAC.AntiLua then
            local data = _gAC.ToSend[_1]
            if data then
                gAC_Stream("g-AC_LuaExec", _util_TableToJSON(data))
                _table_remove(_gAC.ToSend, _1)
            else
                gAC_Send("g-AC_LuaExec", "1")
            end
        end
    end)
end)

local __IDENT = _gAC.stringrandom(floor(_math_random(_12, _26) + __5))

_hook_Add("InitPostEntity", __IDENT, function()
    if _util_NetworkStringToID('gAC.PlayerInit') ~= 0 then
        _net_Start("gAC.PlayerInit")
        _net_SendToServer()
        _hook_Remove("InitPostEntity", __IDENT)
    end
end)
