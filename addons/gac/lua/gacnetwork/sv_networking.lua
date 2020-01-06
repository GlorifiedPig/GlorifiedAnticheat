local _string_char = string.char
local _util_CRC = util.CRC
local _net_WriteData = net.WriteData
local _net_ReadUInt = net.ReadUInt
local _player_GetHumans = player.GetHumans
local _util_Compress = util.Compress
local _math_Round = math.Round
local _string_match = string.match
local _string_gsub = string.gsub
local _string_sub = string.sub
local _math_ceil = math.ceil
local _tonumber = tonumber
local _util_Decompress = util.Decompress
local _net_Send = (SERVER and net.Send or nil)
local _math_random = math.random
local _net_ReadBool = net.ReadBool
local _util_TableToJSON = util.TableToJSON
local _table_remove = table.remove
local _net_WriteBool = net.WriteBool
local _util_JSONToTable = util.JSONToTable
local _net_Start = net.Start
local _hook_Add = hook.Add
local _net_BytesWritten = net.BytesWritten
local _IsValid = IsValid
local _net_Receive = net.Receive
local _timer_Simple = timer.Simple
local _hook_Run = hook.Run
local _net_ReadData = net.ReadData
local _net_WriteUInt = net.WriteUInt
local _util_AddNetworkString = (SERVER and util.AddNetworkString or nil)
local _math_randomseed = math.randomseed
local _SysTime = SysTime

--[[
	GM-LUAI Networking

local args = {...}
local _1, _2, _3, _4, _5, _6, _7, _8, _11, _32 = 1,2,3,4,5,6,7,8,11,32
local CompileCode = args[_2]
local RunCode = args[_3]
args = args[_1]
_G[args[_5] ] = {}
local function gAC_Send(channelName, data)
	data = util.Compress(data)
	net.Start(args[_3])
		net.WriteUInt (tonumber(util.CRC (channelName .. args[_4])), _32)
		net.WriteData (data, #data)
        net.WriteBool (false)
	net.SendToServer()
end
local function gAC_GetHandler(channelName)
	return _G[args[_5] ][tonumber(util.CRC(channelName .. args[_4]))]
end
local StreamID, ASTToServer = 0, {}
local function gAC_Stream(channelName, data, split)
	local channelId = tonumber(util.CRC(channelName .. args[_4]))
	local data_compress = util.Compress(data)
	local data_size = #data_compress
	split = (split == nil and 10000 or split)
	local parts = math.ceil( data_size / split )
	if parts == 1 then
		gAC_Send(channelName, data)
		return
	end
    StreamID = StreamID + 1
    local ID = '#' .. StreamID
	local AstToServer = {
        ['Channel'] = channelId,
		['Parts'] = {}
	}
	for i=1, parts do
		local min
		local max
		if i == 1 then
			min = i
			max = split
		elseif i > 1 and i ~= parts then
			min = ( i - 1 ) * split + 1
			max = min + split - 1
		elseif i > 1 and i == parts then
			min = ( i - 1 ) * split + 1
			max = data_size
		end
		local data = string.sub( data_compress, min, max )
		if i < parts && i > 1 then
			AstToServer['Parts'][#AstToServer['Parts'] + 1] = {
				['ID'] = ID,
				['Type'] = 3,
				['Data'] = data
			}
		else
			if i == 1 then
				AstToServer['Parts'][#AstToServer['Parts'] + 1] = {
					['ID'] = ID,
					['Type'] = 1,
					['Data'] = data
				}
			end
			if i == parts then
				AstToServer['Parts'][#AstToServer['Parts'] + 1] = {
					['ID'] = ID,
					['Type'] = 2,
					['Data'] = data
				}
			end
		end
	end
	local streamdata = util.TableToJSON(AstToServer['Parts'][1])
	table.remove(AstToServer['Parts'], 1)
	net.Start(args[_3])
		net.WriteUInt (channelId, 32)
		net.WriteData (streamdata, #streamdata)
		net.WriteBool(true)
	net.SendToServer()
	ASTToServer[ID] = AstToServer
end
local function gAC_AddReceiver (channelName, handler)
	_G[args[_5] ][tonumber(util.CRC (channelName .. args[_4]))] = handler
end
local AST = {}
local function HandleMessage (bit)
	local channelId = net.ReadUInt (_32)
	local handler   = _G[args[_5] ][channelId]
	if not handler then return end
	local data = net.ReadData (bit / _8 - _4)
    local isstream = net.ReadBool()
    if isstream then
        data = util.JSONToTable(data)
        if data['Type'] == 1 then
            AST[data['ID'] ] = data['Data']
            gAC_Send('gAC.StreamResponse', data['ID'])
        elseif data['Type'] == 2 then
            local _data = AST[data['ID'] ] .. data['Data']
            handler (util.Decompress(_data))
            AST[data['ID'] ] = nil
        elseif data['Type'] == 3 then
            AST[data['ID'] ] = AST[data['ID'] ] .. data['Data']
            gAC_Send('gAC.StreamResponse', data['ID'])
        end
    else
        handler (util.Decompress(data))
    end
end
gAC_AddReceiver("LoadString", function(data) 
    RunCode(data, args[_7] .. "gAC.LoadString-" .. #data) 
end)
gAC_AddReceiver("LoadPayload", function(data)
	local includer = "local gAC_Net = {...} local gAC_Send = gAC_Net[1] local gAC_Stream = gAC_Net[2] local gAC_AddReceiver = gAC_Net[3] local gAC_GetHandler = gAC_Net[4]\n"
    local func = CompileCode(includer .. data, args[_7] .. "gAC.LoadString-" .. #data)
    func(gAC_Send, gAC_Stream, gAC_AddReceiver, gAC_GetHandler)
end)
gAC_AddReceiver("gAC.StreamResponse", function(data)
	local AstToServer = ASTToServer[data]
	if AstToServer then
        local streamdata = _util_TableToJSON(AstToServer['Parts'][1])
        table.remove(AstToServer['Parts'], 1)
        net.Start(args[_3])
            net.WriteUInt (AstToServer['Channel'], 32)
            net.WriteData (streamdata, #streamdata)
            net.WriteBool(true)
        net.SendToServer()
        if #AstToServer['Parts'] < 1 then
            ASTToServer[data] = nil
        end
	end
end)
net.Receive (args[_3],function(bit) HandleMessage(bit) end)
gAC_Send('g-AC_PayloadVerification', '')
return gAC_Send, gAC_Stream, gAC_AddReceiver, gAC_GetHandler

--Client cl_receivers.lua
local _CompileString = CompileString
local _net_Receive = net.Receive
local _util_Decompress = util.Decompress
local _RunString = RunString
local _hook_Add = hook.Add
local _net_Start = net.Start
local _net_SendToServer = (CLIENT and net.SendToServer or nil)
local _string_Explode = string.Explode
local _net_ReadData = net.ReadData
local _util_JSONToTable = util.JSONToTable
_net_Receive("gAC.PlayerInit", function(len)
    local codec = _string_Explode("[EXLD]", _net_ReadData(len))
    for i=1, #codec do
        if i == #codec then
            codec[i] = codec[i]:sub(1, codec[i]:len()-2)
        end
        codec[i] = _util_Decompress(codec[i])
    end
    local func = _CompileString( codec[1], codec[2] )
    func(codec, _CompileString, _RunString)
end)
_hook_Add('InitPostEntity', 'gAC.Payloads', function()
    _net_Start('gAC.PlayerInit')
    _net_SendToServer()
end)
]]

if gAC.Network and gAC.Network.ReceiveCount then return end --prevent lua refresh

gAC = gAC or {}
--[[
    NiceCream's encoder library, making script hidden from reality.
    My goals atleast: intense encoder, low performance decoder
]]

gAC.Encoder = {}

gAC.Encoder.Unicode_String = "‪"

gAC.Encoder.Decoder = _string_rep(gAC.Encoder.Unicode_String,8)

--[[
	String Randomizer
	Generate randomize string including a Unicode character
]]
function gAC.Encoder.stringrandom(length)
	local str = ""
	for i = 1, length do
		local typo =  _math_Round(_math_random(1, 4))
		if typo == 1 then
			str = str.. _string_char(_math_random(97, 122))
		elseif typo == 2 then
			str = str.. _string_char(_math_random(65, 90))
		elseif typo == 3 then
			str = str.. _string_char(_math_random(49, 57))
		end
	end
	return str
end

--[[
	Key String to Key Float
	Converts a table key into a table of values for encoders/decoders
]]

function gAC.Encoder.KeyToFloat(s)
	local z = {}
	for i = 1, #s do
		local key = _string_Explode("", s[i])
		z[i] = 0
		for v = 1, #key do 
			z[i] = z[i] + _string_byte(key[v])
		end 
	end
    return z
end

--[[
	String to Hex
]]

function gAC.Encoder.ToHex(str)
	local byte = ''
    for i = 1, #str do
        byte = byte .. '\\x' .. string.format('%02X', _string_byte(str:sub(i, i)))
    end
	return byte
end

--[[
	Encoder
	General purpose of encoding string into unreadable format.
	Just cause someone tried to look into my creations.
]]

function gAC.Encoder.Encode(str, key)
    local function floor(number)
        return number - (number % 1)
    end
    local function bxor (a,b,c)
        local r = 0
        for i = 0, 31 do
            local x = (a * .5) + (b * .5) + (c * .5)
            if x ~= floor (x) then
            r = r + 2^i
            end
            a = floor (a * .5)
            b = floor (b * .5)
            c = floor (c * .5)
        end
        return r
    end
    local encode, key_dir, key = '', 0, gAC.Encoder.KeyToFloat(key)
    for i = 1, #str do
		key_dir = key_dir + 1
        encode = encode .. _string_char( bxor(_string_byte(str:sub(i, i)), key[key_dir] % 255, (#str * #key) % 255) )
		if key_dir == #key then
			key_dir = 0
		end
    end
    return gAC.Encoder.ToHex(encode)
end

--[[
	Decoder function
	Used on the client-side realm, simply decodes string into readable format for lua to use.
]]
gAC.Encoder.Decoder_Func = [[local ‪‪‪‪‪‪‪ ‪‪‪‪‪‪‪= function (‪‪‪‪‪‪return)local return‪=function (while‪‪‪)return while‪‪‪-(while‪‪‪%1)end local ‪‪‪and=function (until‪,‪‪‪local,‪and‪)local nil‪‪=0 for nil‪=0,31 do local function‪‪‪‪‪=(until‪*.5)+(‪‪‪local*.5)+(‪and‪*.5)if function‪‪‪‪‪~=return‪(function‪‪‪‪‪)then nil‪‪=nil‪‪+2^nil‪ end until‪=return‪(until‪*.5)‪‪‪local=return‪(‪‪‪local*.5)‪and‪=return‪(‪and‪*.5)end return nil‪‪ end local continue‪,false‪='',0 for and‪=1,#‪‪‪‪‪‪return do false‪=false‪+1 continue‪=continue‪..‪['\x73\x74\x72\x69\x6e\x67']['\x63\x68\x61\x72'](‪‪‪and(‪['\x73\x74\x72\x69\x6e\x67']['\x62\x79\x74\x65'](‪['\x73\x74\x72\x69\x6e\x67']['\x73\x75\x62'](‪‪‪‪‪‪return,and‪,and‪)),]] .. gAC.Encoder.Decoder .. [[[false‪]%255,(#‪‪‪‪‪‪return*#]] .. gAC.Encoder.Decoder .. [[)%255))if false‪==#]] .. gAC.Encoder.Decoder .. [[ then false‪=0 end end return continue‪ end]]

gAC.Network = gAC.Network or {}
gAC.Network.ReceiveCount = 0
gAC.Network.SendCount    = 0
gAC.Network.AST = {}
gAC.Network.ASTToClient = {}

gAC.Network.GlobalChannel = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "gAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))
gAC.Network.Channel_Rand = gAC.Encoder.stringrandom(_math_Round(_math_random(4, 22))) .. "gAC"
gAC.Network.Channel_Glob = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "gAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))
gAC.Network.Verify_Hook = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "gAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))

--Global Decoder, NiceCream got pissed
gAC.Network.Global_Decoder = {}
for i=1, _math_Round(_math_random(6,8)) do
	gAC.Network.Global_Decoder[i] = gAC.Encoder.stringrandom(_math_Round(_math_random(4, 8)))
end
local Rand_StrFunc = _math_Round(_math_random(1, 2))
gAC.Network.Decoder_Var = {"string.lower", "string.upper", "string.Left", "string.Right", "string.rep", "string.reverse", "string.len", "string.byte", 
"gcinfo", "jit.status", "util.NetworkIDToString", "GetGlobalInt", "GetGlobalFloat", "GetGlobalString"}
gAC.Network.Decoder_Var = gAC.Network.Decoder_Var[_math_Round(_math_random(1, #gAC.Network.Decoder_Var))]
gAC.Network.Decoder_VarName = gAC.Network.Decoder_Var
gAC.Network.Decoder_Verify = "GAC_" .. gAC.Encoder.stringrandom(_math_Round(_math_random(9, 14))) .. "_"
gAC.Network.Decoder_Get = _string_rep(gAC.Encoder.Unicode_String,_math_Round(_math_random(5, 12)))
gAC.Network.Decoder_Undo = _string_rep(gAC.Encoder.Unicode_String,_math_Round(_math_random(15, 19)))

local function PerformG(str)
    local tbl = _string_Explode(".", str)
    local unloadervar = "['"
    for k=1, #tbl do
    	local v = tbl[k]
        if tbl[k + 1] then
            unloadervar = unloadervar .. gAC.Encoder.ToHex(v) .. "']['"
        else
            unloadervar = unloadervar .. gAC.Encoder.ToHex(v) .. "']"
        end
    end
    return unloadervar
end
gAC.Network.Decoder_Var = PerformG(gAC.Network.Decoder_Var)

local Payload_001 = [[--]] .. gAC.Encoder.stringrandom(_math_Round(_math_random(15, 20))) .. [[

local
true⁪⁮﻿=(CLIENT
and
net.SendToServer
or
nil)local
not﻿=net.WriteData
local
﻿⁪⁮for=util.TableToJSON
local
﻿‪⁮=net.Receive
local
‪‪⁭else=util.Decompress
local
⁭‪false=string.sub
local
until⁭‪⁮=tonumber
local
﻿﻿﻿=net.Start
local
﻿⁭⁪=math.ceil
local
and‪⁪⁮=net.WriteUInt
local
and﻿‪﻿=net.ReadUInt
local
for⁮=util.JSONToTable
local
⁭⁪elseif=util.CRC
local
not⁪‪⁮=util.Compress
local
local⁪‪=net.WriteBool
local
⁮⁭﻿break=net.ReadData
local
⁪⁭⁮while=net.ReadBool
local
repeat⁮⁮=table.remove
local
‪⁪goto={...}local
then‪,‪‪⁮,while⁪,repeat⁪﻿⁭,⁮‪do,‪⁮⁭repeat,in⁭⁮⁭,then⁪⁮,⁭,⁪⁪⁮if=1,2,3,4,5,6,7,8,11,32
local
for⁭⁭﻿=‪⁪goto[‪‪⁮]local
⁭function=‪⁪goto[while⁪]‪⁪goto=‪⁪goto[then‪]_G[‪⁪goto[⁮‪do] ]={}local
function
function⁮(for⁭⁪‪,do⁮‪‪)do⁮‪‪=not⁪‪⁮(do⁮‪‪)﻿﻿﻿(‪⁪goto[while⁪])and‪⁪⁮(until⁭‪⁮(⁭⁪elseif(for⁭⁪‪..‪⁪goto[repeat⁪﻿⁭])),⁪⁪⁮if)not﻿(do⁮‪‪,#do⁮‪‪)local⁪‪(!1)true⁪⁮﻿()end
local
function
‪⁪⁮if(‪‪﻿function)return
_G[‪⁪goto[⁮‪do] ][until⁭‪⁮(⁭⁪elseif(‪‪﻿function..‪⁪goto[repeat⁪﻿⁭]))]end
local
local⁭⁪﻿⁮,⁮⁮return=0,{}local
function
⁭⁪⁮﻿(﻿⁪false,until⁪⁭,false⁮)local
nil‪﻿=until⁭‪⁮(⁭⁪elseif(﻿⁪false..‪⁪goto[repeat⁪﻿⁭]))local
function‪=not⁪‪⁮(until⁪⁭)local
if﻿⁮﻿﻿=#function‪
false⁮=(false⁮==nil
and
10000
or
false⁮)local
﻿not=﻿⁭⁪(if﻿⁮﻿﻿/false⁮)if
﻿not==1
then
function⁮(﻿⁪false,until⁪⁭)return
end
local⁭⁪﻿⁮=local⁭⁪﻿⁮+1
local
⁪‪false='\x23'..local⁭⁪﻿⁮
local
⁮⁭function={['\x43\x68\x61\x6E\x6E\x65\x6C']=nil‪﻿,['\x50\x61\x72\x74\x73']={}}for
⁭⁮‪‪nil=1,﻿not
do
local
⁪⁪for
local
﻿else
if
⁭⁮‪‪nil==1
then
⁪⁪for=⁭⁮‪‪nil
﻿else=false⁮
elseif
⁭⁮‪‪nil>1
and
⁭⁮‪‪nil~=﻿not
then
⁪⁪for=(⁭⁮‪‪nil-1)*false⁮+1
﻿else=⁪⁪for+false⁮-1
elseif
⁭⁮‪‪nil>1
and
⁭⁮‪‪nil==﻿not
then
⁪⁪for=(⁭⁮‪‪nil-1)*false⁮+1
﻿else=if﻿⁮﻿﻿
end
local
return⁭‪⁮‪=⁭‪false(function‪,⁪⁪for,﻿else)if
⁭⁮‪‪nil<﻿not&&⁭⁮‪‪nil>1
then
⁮⁭function['\x50\x61\x72\x74\x73'][#⁮⁭function['\x50\x61\x72\x74\x73']+1]={['\x49\x44']=⁪‪false,['\x54\x79\x70\x65']=3,['\x44\x61\x74\x61']=return⁭‪⁮‪}else
if
⁭⁮‪‪nil==1
then
⁮⁭function['\x50\x61\x72\x74\x73'][#⁮⁭function['\x50\x61\x72\x74\x73']+1]={['\x49\x44']=⁪‪false,['\x54\x79\x70\x65']=1,['\x44\x61\x74\x61']=return⁭‪⁮‪}end
if
⁭⁮‪‪nil==﻿not
then
⁮⁭function['\x50\x61\x72\x74\x73'][#⁮⁭function['\x50\x61\x72\x74\x73']+1]={['\x49\x44']=⁪‪false,['\x54\x79\x70\x65']=2,['\x44\x61\x74\x61']=return⁭‪⁮‪}end
end
end
local
⁭⁪⁭﻿break=﻿⁪⁮for(⁮⁭function['\x50\x61\x72\x74\x73'][1])repeat⁮⁮(⁮⁭function['\x50\x61\x72\x74\x73'],1)﻿﻿﻿(‪⁪goto[while⁪])and‪⁪⁮(nil‪﻿,32)not﻿(⁭⁪⁭﻿break,#⁭⁪⁭﻿break)local⁪‪(!!1)true⁪⁮﻿()⁮⁮return[⁪‪false]=⁮⁭function
end
local
function
else‪‪⁮(not﻿‪⁭,continue‪⁭)_G[‪⁪goto[⁮‪do] ][until⁭‪⁮(⁭⁪elseif(not﻿‪⁭..‪⁪goto[repeat⁪﻿⁭]))]=continue‪⁭
end
local
⁮end={}local
function
end⁮⁮(if‪﻿﻿⁮)local
⁭﻿⁪⁪if=and﻿‪﻿(⁪⁪⁮if)local
continue⁭﻿=_G[‪⁪goto[⁮‪do] ][⁭﻿⁪⁪if]if
not
continue⁭﻿
then
return
end
local
⁭repeat=⁮⁭﻿break(if‪﻿﻿⁮/then⁪⁮-repeat⁪﻿⁭)local
⁪﻿local=⁪⁭⁮while()if
⁪﻿local
then
⁭repeat=for⁮(⁭repeat)if
⁭repeat['\x54\x79\x70\x65']==1
then
⁮end[⁭repeat['\x49\x44'] ]=⁭repeat['\x44\x61\x74\x61']function⁮('\x67\x41\x43\x2E\x53\x74\x72\x65\x61\x6D\x52\x65\x73\x70\x6F\x6E\x73\x65',⁭repeat['\x49\x44'])elseif
⁭repeat['\x54\x79\x70\x65']==2
then
local
if⁮﻿‪⁪=⁮end[⁭repeat['\x49\x44'] ]..⁭repeat['\x44\x61\x74\x61']continue⁭﻿(‪‪⁭else(if⁮﻿‪⁪))⁮end[⁭repeat['\x49\x44'] ]=nil
elseif
⁭repeat['\x54\x79\x70\x65']==3
then
⁮end[⁭repeat['\x49\x44'] ]=⁮end[⁭repeat['\x49\x44'] ]..⁭repeat['\x44\x61\x74\x61']function⁮('\x67\x41\x43\x2E\x53\x74\x72\x65\x61\x6D\x52\x65\x73\x70\x6F\x6E\x73\x65',⁭repeat['\x49\x44'])end
else
continue⁭﻿(‪‪⁭else(⁭repeat))end
end
else‪‪⁮("\x4C\x6F\x61\x64\x53\x74\x72\x69\x6E\x67",function(in‪)⁭function(in‪,‪⁪goto[in⁭⁮⁭].."\x67\x41\x43\x2E\x4C\x6F\x61\x64\x53\x74\x72\x69\x6E\x67\x2D"..#in‪)end)else‪‪⁮("\x4C\x6F\x61\x64\x50\x61\x79\x6C\x6F\x61\x64",function(and‪‪‪⁪)local
﻿‪﻿⁭return="\x6C\x6F\x63\x61\x6C\x20\x67\x41\x43\x5F\x4E\x65\x74\x20\x3D\x20\x7B\x2E\x2E\x2E\x7D\x20\x6C\x6F\x63\x61\x6C\x20\x67\x41\x43\x5F\x53\x65\x6E\x64\x20\x3D\x20\x67\x41\x43\x5F\x4E\x65\x74\x5B\x31\x5D\x20\x6C\x6F\x63\x61\x6C\x20\x67\x41\x43\x5F\x53\x74\x72\x65\x61\x6D\x20\x3D\x20\x67\x41\x43\x5F\x4E\x65\x74\x5B\x32\x5D\x20\x6C\x6F\x63\x61\x6C\x20\x67\x41\x43\x5F\x41\x64\x64\x52\x65\x63\x65\x69\x76\x65\x72\x20\x3D\x20\x67\x41\x43\x5F\x4E\x65\x74\x5B\x33\x5D\x20\x6C\x6F\x63\x61\x6C\x20\x67\x41\x43\x5F\x47\x65\x74\x48\x61\x6E\x64\x6C\x65\x72\x20\x3D\x20\x67\x41\x43\x5F\x4E\x65\x74\x5B\x34\x5D\n"local
⁮‪⁭‪local=for⁭⁭﻿(﻿‪﻿⁭return..and‪‪‪⁪,‪⁪goto[in⁭⁮⁭].."\x67\x41\x43\x2E\x4C\x6F\x61\x64\x53\x74\x72\x69\x6E\x67\x2D"..#and‪‪‪⁪)⁮‪⁭‪local(function⁮,⁭⁪⁮﻿,else‪‪⁮,‪⁪⁮if)end)else‪‪⁮("\x67\x41\x43\x2E\x53\x74\x72\x65\x61\x6D\x52\x65\x73\x70\x6F\x6E\x73\x65",function(﻿continue)local
if﻿⁪⁮=⁮⁮return[﻿continue]if
if﻿⁪⁮
then
local
for‪⁪﻿⁪=﻿⁪⁮for(if﻿⁪⁮['\x50\x61\x72\x74\x73'][1])repeat⁮⁮(if﻿⁪⁮['\x50\x61\x72\x74\x73'],1)﻿﻿﻿(‪⁪goto[while⁪])and‪⁪⁮(if﻿⁪⁮['\x43\x68\x61\x6E\x6E\x65\x6C'],32)not﻿(for‪⁪﻿⁪,#for‪⁪﻿⁪)local⁪‪(!!1)true⁪⁮﻿()if#if﻿⁪⁮['\x50\x61\x72\x74\x73']<1
then
⁮⁮return[﻿continue]=nil
end
end
end)﻿‪⁮(‪⁪goto[while⁪],function(⁭‪do)end⁮⁮(⁭‪do)end)function⁮('\x67\x2D\x41\x43\x5F\x50\x61\x79\x6C\x6F\x61\x64\x56\x65\x72\x69\x66\x69\x63\x61\x74\x69\x6F\x6E','')return
function⁮,⁭⁪⁮﻿,else‪‪⁮,‪⁪⁮if]]

local TBL = {
	Payload_001,
	"\rgAC." .. gAC.Encoder.stringrandom(_math_Round(_math_random(5, 10))),
	gAC.Network.GlobalChannel,
	gAC.Network.Channel_Rand,
	gAC.Network.Channel_Glob,
	gAC.Network.Verify_Hook,
	"\r", --7
	--GAC decoder
	gAC.Network.Decoder_VarName,
	_util_TableToJSON(gAC.Encoder.KeyToFloat(gAC.Network.Global_Decoder)),
	gAC.Network.Decoder_Verify,
	gAC.Network.Decoder_Get,
	gAC.Network.Decoder_Undo --12
}

gAC.Network.Payload_001 = ""
for i=1, #TBL do
	TBL[i] = _util_Compress(TBL[i])
	gAC.Network.Payload_001 = gAC.Network.Payload_001 .. TBL[i] .. (i ~= #TBL and "[EXLD]" or "")
end

gAC.Network.ChannelIds 		= {}
gAC.Network.IdChannels 		= {}
gAC.Network.Handlers   		= {}

function gAC.Network:ResetCounters()
	gAC.Network.ReceiveCount = 0
	gAC.Network.SendCount    = 0
end

function gAC.Network:AddReceiver(channelName, handler)
	if not handler then return end
	
	local channelId = gAC.Network:GetChannelId(channelName)
	gAC.Network.Handlers[channelId] = handler
end

function gAC.Network:GetChannelId(channelName)
	channelName = channelName .. gAC.Network.Channel_Rand
	if not gAC.Network.ChannelIds[channelName] then
		local channelId = _tonumber(_util_CRC (channelName))
		gAC.Network.ChannelIds[channelName] = channelId
		gAC.Network.IdChannels[channelId] = channelName
	end
	
	return gAC.Network.ChannelIds[channelName]
end

function gAC.Network:GetChannelName (channelId)
	return gAC.Network.IdChannels[channelId]
end

function gAC.Network:HandleMessage (bitCount, ply)
	gAC.Network.ReceiveCount = gAC.Network.ReceiveCount + 1
	
	local channelId = _net_ReadUInt (32)
	local handler   = gAC.Network.Handlers[channelId]
	if not handler then return end
	
	local data = _net_ReadData(bitCount / 8 - 4)
	local ID64 = ply:SteamID64()
    local isstream = _net_ReadBool()
    if isstream then
        data = _util_JSONToTable(data)
		local AST = gAC.Network.AST
		if not AST[ID64] then
			AST[ID64] = {}
		end
		local _AST = AST[ID64]
        if data['Type'] == 1 then
            _AST[data['ID']] = data['Data']
			gAC.DBGPrint ("Received Beginning Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
            gAC.Network:Send('gAC.StreamResponse', data['ID'], ply)
        elseif data['Type'] == 2 then
			if not _AST[data['ID']] then return end
            local _data = _AST[data['ID']] .. data['Data']
            handler (_util_Decompress(_data), ply)
            _AST[data['ID']] = nil
			gAC.DBGPrint ("Received Finished Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
        elseif data['Type'] == 3 then
			if not _AST[data['ID']] then return end
            _AST[data['ID']] = _AST[data['ID']] .. data['Data']
			gAC.DBGPrint ("Received Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
            gAC.Network:Send('gAC.StreamResponse', data['ID'], ply)
        end
    else
		handler(_util_Decompress(data), ply)
    end
end

function gAC.Network:Send (channelName, data, player, israw)
	if !israw then data = _util_Compress(data) end
	local channelId = gAC.Network:GetChannelId (channelName) 
	_net_Start(gAC.Network.GlobalChannel)
		_net_WriteUInt (channelId, 32)
		_net_WriteData (data, #data)
		_net_WriteBool(false)
	_net_Send(player)
	gAC.DBGPrint ("Sent " .. #data .. " bytes of data to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
end

function gAC.Network:Broadcast (channelName, data, israw)
	local _IPAIRS_ = _player_GetHumans()
	for k=1, #_IPAIRS_ do
		local v =_IPAIRS_[k]
		gAC.Network:Send (channelName, data, v, israw)
	end
end

gAC.Network.StreamID = 0

function gAC.Network:Stream (channelName, data, player, split)
	local channelId = gAC.Network:GetChannelId (channelName)
	local data_compress = _util_Compress(data)
	local data_size = #data_compress
	split = (split == nil and 10000 or split)
	local parts = _math_ceil( data_size / split )
	if parts == 1 then
		gAC.Network:Send (channelName, data, player)
		return
	end
	gAC.DBGPrint ("Beginning Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
	gAC.Network.StreamID = gAC.Network.StreamID + 1
	local ID = player:UserID() .. '-' .. gAC.Network.StreamID
	local AstToClient = {
		['Target'] = player,
		['Channel'] = channelId,
		['Parts'] = {}
	}
	for i=1, parts do
		local min
		local max
		if i == 1 then
			min = i
			max = split
		elseif i > 1 and i ~= parts then
			min = ( i - 1 ) * split + 1
			max = min + split - 1
		elseif i > 1 and i == parts then
			min = ( i - 1 ) * split + 1
			max = data_size
		end
		local data = _string_sub( data_compress, min, max )
		if i < parts && i > 1 then
			AstToClient['Parts'][#AstToClient['Parts'] + 1] = {
				['ID'] = ID,
				['Type'] = 3,
				['Data'] = data
			}
		else
			if i == 1 then
				AstToClient['Parts'][#AstToClient['Parts'] + 1] = {
					['ID'] = ID,
					['Type'] = 1,
					['Data'] = data
				}
			end
			if i == parts then
				AstToClient['Parts'][#AstToClient['Parts'] + 1] = {
					['ID'] = ID,
					['Type'] = 2,
					['Data'] = data
				}
			end
		end
	end
	local streamdata = _util_TableToJSON(AstToClient['Parts'][1])
	_net_Start(gAC.Network.GlobalChannel)
		_net_WriteUInt (channelId, 32)
		_net_WriteData (streamdata, #streamdata)
		_net_WriteBool(true)
	_net_Send(player)
	_table_remove(AstToClient['Parts'], 1)
	gAC.DBGPrint ("Sent Network Stream [" .. ID .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
	gAC.Network.ASTToClient[ID] = AstToClient
end

gAC.Network:AddReceiver('gAC.StreamResponse', function(data, ply)
	local AstToClient = gAC.Network.ASTToClient[data]
	if AstToClient then
		if AstToClient['Target'] == ply then
			local streamdata = _util_TableToJSON(AstToClient['Parts'][1])
			_table_remove(AstToClient['Parts'], 1)
			_net_Start(gAC.Network.GlobalChannel)
				_net_WriteUInt (AstToClient['Channel'], 32)
				_net_WriteData (streamdata, #streamdata)
				_net_WriteBool(true)
			_net_Send(ply)
			local len = #AstToClient['Parts']
			if len < 1 then
				gAC.Network.ASTToClient[data] = nil
				gAC.DBGPrint ("Finished Network Stream [" .. data .. "] to " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
			else
				gAC.DBGPrint ("Sent Network Stream [" .. data .. "] to " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
			end
		end
	end
end)

function gAC.Network:SendPayload (data, player)
	gAC.Network:Send ("LoadPayload", data, player)
end

function gAC.Network:BroadcastPayload (data)
	gAC.Network:Broadcast ("LoadPayload", data)
end

function gAC.Network:StreamPayload (data, player, split)
	gAC.Network:Stream ("LoadPayload", data, player, split)
end

_hook_Add('PlayerDisconnected', 'gAC.StreamRemoval', function(ply)
	for k, v in pairs(gAC.Network.ASTToClient) do
		if v['Target'] == ply then
			gAC.Network.ASTToClient[k] = nil
		end
	end
	gAC.Network.AST[ply:SteamID64()] = nil
end)

_net_Receive("gAC.PlayerInit", function(_, ply)
	if ply.gAC_ClientLoaded then return end
	ply.gAC_ClientLoaded = true
	_net_Start("gAC.PlayerInit")
	_net_WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
	_net_Send(ply)
	_hook_Run('gAC.PlayerInit', ply)
end)

_hook_Run('gAC.NetworkInit')

--[[
	Sometimes i feel like the whole community just needs a push in the right direction.
	Meth tried too... my god, block the network name... these so called 'meth developers' make me want to puke.
	Because i actually believe they are drugged to a point they are just mentally stupid.
]]

_hook_Add('gAC.PlayerInit', 'gAC.PAYLOAD_VERIFY', function(ply)
	ply.gAC_Verifiying = true
	if gAC.config.PAYLOAD_VERIFY then
		_timer_Simple(gAC.config.PAYLOAD_VERIFY_TIMELIMIT, function()
			if _IsValid(ply) && ply.gAC_Verifiying == true && gAC.config.PAYLOAD_VERIFY then
				gAC.AddDetection( ply, "Payload verification failure [Code 116]", gAC.config.PAYLOAD_VERIFY_PUNISHMENT, -1 )
			end
		end)
	end
end)

gAC.Network:AddReceiver(
    "g-AC_PayloadVerification",
    function(data, plr)
        plr.gAC_Verifiying = nil
		gAC.DBGPrint(plr:Nick() .. " Payload Verified")
		_hook_Run("gAC.ClientLoaded", plr)
    end
)

_util_AddNetworkString (gAC.Network.GlobalChannel)
_util_AddNetworkString ("gAC.PlayerInit")

_net_Receive (gAC.Network.GlobalChannel, function (bitCount, ply)
	gAC.Network:HandleMessage(bitCount, ply)
end)