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
local _string_Explode = string.Explode
local _string_byte = string.byte
local _string_format = string.format
local _util_JSONToTable = util.JSONToTable
local _string_rep = string.rep
local _net_Start = net.Start
local _hook_Add = hook.Add
local _net_BytesWritten = net.BytesWritten
local _IsValid = IsValid
local _net_Receive = net.Receive
local _player_GetBySteamID64 = player.GetBySteamID64
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
local _1, _2, _3, _4, _5, _6, _7, _8, _10, _11, _32 = 1,2,3,4,5,6,7,8,10,11,32
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
    local func = CompileCode(includer .. data, args[_7] .. args[_10] .. #data)
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
	if z[i] == 0 or z[i] == 255 then
		z[i] = z[i] + _math_Round(_math_random(1, 10))
	end
    return z
end

--[[
	String to Hex
]]

function gAC.Encoder.ToHex(str)
	local byte = ''
    for i = 1, #str do
        byte = byte .. '\\x' .. _string_format('%02X', _string_byte(str:sub(i, i)))
    end
	return byte
end

--[[
    Table to String
]]

function gAC.Encoder.Tabletostring(tbl)
	local str = "{"
	local len = #tbl
	for i = 1, len do
		local v = tbl[i]
		if v .. '' ~= v then
			str = str .. v .. (i ~= len and ',' or '')
		else
			str = str .. "'" .. v .. "'" .. (i ~= len and ',' or '')
		end
	end
	str = str .. '}'
	return str
end

--[[
	Encoder
	General purpose of encoding string into unreadable format.
	Just cause someone tried to look into my creations.
]]

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

local CharacterForEscape = {['b'] = '\b', ['x'] = true, ['f'] = '\f', ['v'] = '\v', ['0'] = '\0', ['r'] = '\r', ['n'] = '\n', ['t'] = '\t', ['"'] = '"', ["'"] = "'", ['\\'] = '\\'}

local _isnumber = isnumber
function gAC.Encoder.Encode(data, key)
	local function peek(n)
		return (data:sub(n, n) or '')
	end
	key = gAC.Encoder.KeyToFloat(key)
	local encode, key_dir, key_len, data_len, skips = {}, 0, #key, #data, 0
	for i = 1, data_len do
		key_dir = key_dir + 1
		local CanContinue = true
		if peek(i) == '\\' then
			if _isnumber(_tonumber(peek(i + 1))) then
				skips = skips + 1
				local id = #encode + 1
				encode[id] = '\\' .. peek(i + 1)
				for v=1, 2 do
					if _isnumber(_tonumber(peek(i + 1 + v))) then
						skips = skips + 1
						encode[id] = encode[id] .. peek(i + 1 + v)
					end
				end
				CanContinue = false
			elseif peek(i + 1) == 'x' and peek(i + 2) ~= '' then
				skips = skips + 3
				encode[#encode + 1] = '\\' .. peek(i + 1) .. peek(i + 2) .. peek(i + 3)
				CanContinue = false
			elseif CharacterForEscape[peek(i + 1)] and peek(i + 1) ~= 'x' then
				skips = skips + 1
				encode[#encode + 1] = '\\' .. peek(i + 1)
				CanContinue = false
			end
		end
		if CanContinue then
			if skips > 0 then
				skips = skips - 1
				encode[#encode + 1] = ''
				CanContinue = false 
			end
			if CanContinue then
				--encode[#encode + 1] = bxor(_string_byte(data:sub(i, i)), key[key_dir] % 255, (data_len * key_len) % 255)
				encode[#encode + 1] = (_string_byte(data:sub(i, i)) * (key[key_dir]) * ((data_len * key_len)))
			end
		end
		if key_dir == key_len then
			key_dir = 0
		end
	end
    return gAC.Encoder.Tabletostring(encode)
end

--[[
	Decoder function
	Used on the client-side realm, simply decodes string into readable format for lua to use.

function(data)
    local key = __EXTK
    local decode, key_dir, data_len, key_len = '', 0, #data, #key
    for i = 1, data_len do
		key_dir = key_dir + 1
		local v = data[i]
		if v .. '' ~= v then
			--decode = decode .. __CHAR( __XOR(v, key[key_dir] % 255, (data_len * key_len) % 255) )
			decode = decode .. __CHAR( v/((data_len * key_len) % 255)/(key[key_dir] % 255) )
		else
			decode = decode .. v
		end
		if key_dir == key_len then
			key_dir = 0
		end
    end
    return decode
end
]]
gAC.Encoder.Decoder_Func = [[function(_lvar1)local
_lvar2=__EXTK
local
_lvar3,_lvar4,_lvar5,_lvar6='',0,#_lvar1,#_lvar2
for
_lvar7=1,_lvar5
do
_lvar4=_lvar4+1
local
_lvar8=_lvar1[_lvar7]if
_lvar8..''~=_lvar8
then
_lvar3=_lvar3..__CHAR(_lvar8/((_lvar5*_lvar6)%255)/(_lvar2[_lvar4]%255))else
_lvar3=_lvar3.._lvar8
end
if
_lvar4==_lvar6
then
_lvar4=0
end
end
return
_lvar3
end]]

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
__CHAR,__FLOOR,__XOR
__CHAR=function(⁭)local
‪‪⁮={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
‪⁭⁮⁮=‪‪⁮[⁭]if
not
‪⁭⁮⁮
then
‪⁭⁮⁮=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](⁭)end
return
‪⁭⁮⁮
end
__FLOOR=function(⁭⁭)return
⁭⁭-(⁭⁭%1)end
__XOR=function(...)local
⁭﻿﻿,⁮⁪⁪=0,{...}for
﻿﻿⁮⁮=0,31
do
local
⁪⁭=0
for
⁪‪⁪⁮=1,#⁮⁪⁪
do
⁪⁭=⁪⁭+(⁮⁪⁪[⁪‪⁪⁮]*.5)end
if
⁪⁭~=__FLOOR(⁪⁭)then
⁭﻿﻿=⁭﻿﻿+2^﻿﻿⁮⁮
end
for
‪﻿⁭=1,#⁮⁪⁪
do
⁮⁪⁪[‪﻿⁭]=__FLOOR(⁮⁪⁪[‪﻿⁭]*.5)end
end
return
⁭﻿﻿
end
local
昨={夜=(function(⁪⁪﻿﻿,⁭⁮﻿)local
⁪,⁪⁮,‪⁪﻿,﻿﻿‪‪='',0,#⁭⁮﻿,#⁪⁪﻿﻿
for
⁭⁮=1,‪⁪﻿
do
⁪⁮=⁪⁮+1
local
‪⁮‪=⁭⁮﻿[⁭⁮]if
‪⁮‪..''~=‪⁮‪
then
⁪=⁪..__CHAR(‪⁮‪/(⁪⁪﻿﻿[⁪⁮])/((‪⁪﻿*﻿﻿‪‪)))else
⁪=⁪..‪⁮‪
end
if
⁪⁮==﻿﻿‪‪
then
⁪⁮=0
end
end
return
⁪
end)({552,111,168},{546480,100899,175392}),の=(function(⁪⁮,⁪)local
⁮⁭‪,⁮⁭,⁭⁪﻿﻿,⁪‪⁪⁮='',0,#⁪,#⁪⁮
for
‪⁮﻿﻿=1,⁭⁪﻿﻿
do
⁮⁭=⁮⁭+1
local
⁪‪⁮=⁪[‪⁮﻿﻿]if
⁪‪⁮..''~=⁪‪⁮
then
⁮⁭‪=⁮⁭‪..__CHAR(⁪‪⁮/(⁪⁮[⁮⁭])/((⁭⁪﻿﻿*⁪‪⁪⁮)))else
⁮⁭‪=⁮⁭‪..⁪‪⁮
end
if
⁮⁭==⁪‪⁪⁮
then
⁮⁭=0
end
end
return
⁮⁭‪
end)({235,449,549,139,189,480},{1404360,3265128,4348080,1000800,1143072,3836160,1404360,3265128,4506192,1180944,1374408,3939840}),コ=(function(⁭⁭⁭,⁭‪⁮)local
⁭‪⁪⁮,‪⁮⁮‪,⁭,⁪='',0,#⁭‪⁮,#⁭⁭⁭
for
⁭⁪=1,⁭
do
‪⁮⁮‪=‪⁮⁮‪+1
local
﻿=⁭‪⁮[⁭⁪]if
﻿..''~=﻿
then
⁭‪⁪⁮=⁭‪⁪⁮..__CHAR(﻿/(⁭⁭⁭[‪⁮⁮‪])/((⁭*⁪)))else
⁭‪⁪⁮=⁭‪⁪⁮..﻿
end
if
‪⁮⁮‪==⁪
then
‪⁮⁮‪=0
end
end
return
⁭‪⁪⁮
end)({103,85,309},{101970,77265,322596}),ン=(function(⁭,⁭⁭⁪)local
‪⁪⁪,⁮﻿,﻿⁮,⁮⁮='',0,#⁭⁭⁪,#⁭
for
⁪⁮﻿⁪=1,﻿⁮
do
⁮﻿=⁮﻿+1
local
﻿‪⁭‪=⁭⁭⁪[⁪⁮﻿⁪]if
﻿‪⁭‪..''~=﻿‪⁭‪
then
‪⁪⁪=‪⁪⁪..__CHAR(﻿‪⁭‪/(⁭[⁮﻿])/((﻿⁮*⁮⁮)))else
‪⁪⁪=‪⁪⁪..﻿‪⁭‪
end
if
⁮﻿==⁮⁮
then
⁮﻿=0
end
end
return
‪⁪⁪
end)({266,112,377,122},{833112,459648,1425060,509472,967176,274176,1316484,509472,928872})}local
夜={サ=(function(⁮,⁮‪⁪⁪)local
⁪,﻿⁭,⁮⁮,⁭='',0,#⁮‪⁪⁪,#⁮
for
⁪⁪=1,⁮⁮
do
﻿⁭=﻿⁭+1
local
‪⁮=⁮‪⁪⁪[⁪⁪]if
‪⁮..''~=‪⁮
then
⁪=⁪..__CHAR(‪⁮/(⁮[﻿⁭])/((⁮⁮*⁭)))else
⁪=⁪..‪⁮
end
if
﻿⁭==⁭
then
﻿⁭=0
end
end
return
⁪
end)({479,543,103},{672516,755856,129780,620784}),ー=(function(﻿‪‪,‪‪‪)local
⁮⁭⁭,﻿⁪﻿⁮,﻿⁮,‪⁮⁮='',0,#‪‪‪,#﻿‪‪
for
‪⁭﻿=1,﻿⁮
do
﻿⁪﻿⁮=﻿⁪﻿⁮+1
local
﻿⁭⁪=‪‪‪[‪⁭﻿]if
﻿⁭⁪..''~=﻿⁭⁪
then
⁮⁭⁭=⁮⁭⁭..__CHAR(﻿⁭⁪/(﻿‪‪[﻿⁪﻿⁮])/((﻿⁮*‪⁮⁮)))else
⁮⁭⁭=⁮⁭⁭..﻿⁭⁪
end
if
﻿⁪﻿⁮==‪⁮⁮
then
﻿⁪﻿⁮=0
end
end
return
⁮⁭⁭
end)({305,373,712},{845460,1193973,2302608,1087020,1243209,1973664,1117215,910866,1950168,795135,960102}),ト=(function(‪﻿,‪⁭⁪‪)local
‪﻿⁭⁪,⁪,⁭⁭﻿⁪,⁮⁭⁮⁪='',0,#‪⁭⁪‪,#‪﻿
for
⁭⁮=1,⁭⁭﻿⁪
do
⁪=⁪+1
local
﻿⁮=‪⁭⁪‪[⁭⁮]if
﻿⁮..''~=﻿⁮
then
‪﻿⁭⁪=‪﻿⁭⁪..__CHAR(﻿⁮/(‪﻿[⁪])/((⁭⁭﻿⁪*⁮⁭⁮⁪)))else
‪﻿⁭⁪=‪﻿⁭⁪..﻿⁮
end
if
⁪==⁮⁭⁮⁪
then
⁪=0
end
end
return
‪﻿⁭⁪
end)({101,311,512},{99990,282699,534528}),は=(function(‪,⁪⁪)local
﻿‪,⁮﻿,⁪⁮⁭⁮,⁮⁮‪='',0,#⁪⁪,#‪
for
⁭⁪﻿⁮=1,⁪⁮⁭⁮
do
⁮﻿=⁮﻿+1
local
﻿⁭=⁪⁪[⁭⁪﻿⁮]if
﻿⁭..''~=﻿⁭
then
﻿‪=﻿‪..__CHAR(﻿⁭/(‪[⁮﻿])/((⁪⁮⁭⁮*⁮⁮‪)))else
﻿‪=﻿‪..﻿⁭
end
if
⁮﻿==⁮⁮‪
then
⁮﻿=0
end
end
return
﻿‪
end)({104,119,261,375},{238784,336532,723492,1060500,305760,393176,738108}),最=(function(⁪⁮,⁮⁮)local
⁭,‪,⁮,⁭⁮﻿⁪='',0,#⁮⁮,#⁪⁮
for
⁮‪‪⁪=1,⁮
do
‪=‪+1
local
⁮﻿=⁮⁮[⁮‪‪⁪]if
⁮﻿..''~=⁮﻿
then
⁭=⁭..__CHAR(⁮﻿/(⁪⁮[‪])/((⁮*⁭⁮﻿⁪)))else
⁭=⁭..⁮﻿
end
if
‪==⁭⁮﻿⁪
then
‪=0
end
end
return
⁭
end)({211,501,78},{296244,697392,98280,273456}),高=(function(﻿⁭,﻿⁮⁮)local
⁮,‪﻿,﻿,⁪﻿='',0,#﻿⁮⁮,#﻿⁭
for
⁪﻿‪=1,﻿
do
‪﻿=‪﻿+1
local
⁮﻿=﻿⁮⁮[⁪﻿‪]if
⁮﻿..''~=⁮﻿
then
⁮=⁮..__CHAR(⁮﻿/(﻿⁭[‪﻿])/((﻿*⁪﻿)))else
⁮=⁮..⁮﻿
end
if
‪﻿==⁪﻿
then
‪﻿=0
end
end
return
⁮
end)({52,242,212,124,81,125,452,392,203},{318240,2199780,1888920,1238760,794610,1260000,4637520,3563280,2101050,538200}),で=(function(‪﻿﻿,﻿⁮)local
⁮⁪⁪,‪⁮⁪,‪﻿,﻿‪﻿‪='',0,#﻿⁮,#‪﻿﻿
for
⁮⁮‪⁪=1,‪﻿
do
‪⁮⁪=‪⁮⁪+1
local
⁮⁭⁭⁭=﻿⁮[⁮⁮‪⁪]if
⁮⁭⁭⁭..''~=⁮⁭⁭⁭
then
⁮⁪⁪=⁮⁪⁪..__CHAR(⁮⁭⁭⁭/(‪﻿﻿[‪⁮⁪])/((‪﻿*﻿‪﻿‪)))else
⁮⁪⁪=⁮⁪⁪..⁮⁭⁭⁭
end
if
‪⁮⁪==﻿‪﻿‪
then
‪⁮⁪=0
end
end
return
⁮⁪⁪
end)({121,170,472},{250470,354960,968544,228690,336600,875088}),し=(function(‪﻿﻿﻿,﻿‪⁪)local
‪﻿⁭,⁭﻿‪,⁪⁪,⁭='',0,#﻿‪⁪,#‪﻿﻿﻿
for
‪‪﻿=1,⁪⁪
do
⁭﻿‪=⁭﻿‪+1
local
⁮=﻿‪⁪[‪‪﻿]if
⁮..''~=⁮
then
‪﻿⁭=‪﻿⁭..__CHAR(⁮/(‪﻿﻿﻿[⁭﻿‪])/((⁪⁪*⁭)))else
‪﻿⁭=‪﻿⁭..⁮
end
if
⁭﻿‪==⁭
then
⁭﻿‪=0
end
end
return
‪﻿⁭
end)({85,192,464},{87975,202176,409248}),た=(function(﻿,⁮⁭)local
﻿﻿﻿⁮,⁮,⁭,⁭‪⁭﻿='',0,#⁮⁭,#﻿
for
⁭⁮=1,⁭
do
⁮=⁮+1
local
⁭⁮‪﻿=⁮⁭[⁭⁮]if
⁭⁮‪﻿..''~=⁭⁮‪﻿
then
﻿﻿﻿⁮=﻿﻿﻿⁮..__CHAR(⁭⁮‪﻿/(﻿[⁮])/((⁭*⁭‪⁭﻿)))else
﻿﻿﻿⁮=﻿﻿﻿⁮..⁭⁮‪﻿
end
if
⁮==⁭‪⁭﻿
then
⁮=0
end
end
return
﻿﻿﻿⁮
end)({332,576,543,449,67,464},{1848576,3068928,2867040,2521584,350544,2182656,1609536,3151872}),。=(function(﻿⁮,⁮﻿)local
⁭﻿⁮‪,﻿,⁮⁮⁭‪,⁭⁭‪⁪='',0,#⁮﻿,#﻿⁮
for
⁮‪=1,⁮⁮⁭‪
do
﻿=﻿+1
local
⁮‪‪=⁮﻿[⁮‪]if
⁮‪‪..''~=⁮‪‪
then
⁭﻿⁮‪=⁭﻿⁮‪..__CHAR(⁮‪‪/(﻿⁮[﻿])/((⁮⁮⁭‪*⁭⁭‪⁪)))else
⁭﻿⁮‪=⁭﻿⁮‪..⁮‪‪
end
if
﻿==⁭⁭‪⁪
then
﻿=0
end
end
return
⁭﻿⁮‪
end)({402,151,261},{397980,137259,272484})}local
の={昨夜=(function(﻿⁭,﻿﻿﻿)local
⁮⁭⁭⁪,⁭⁪,⁮,﻿⁮⁮﻿='',0,#﻿﻿﻿,#﻿⁭
for
⁪⁪⁭⁪=1,⁮
do
⁭⁪=⁭⁪+1
local
﻿⁪⁮⁭=﻿﻿﻿[⁪⁪⁭⁪]if
﻿⁪⁮⁭..''~=﻿⁪⁮⁭
then
⁮⁭⁭⁪=⁮⁭⁭⁪..__CHAR(﻿⁪⁮⁭/(﻿⁭[⁭⁪])/((⁮*﻿⁮⁮﻿)))else
⁮⁭⁭⁪=⁮⁭⁭⁪..﻿⁪⁮⁭
end
if
⁭⁪==﻿⁮⁮﻿
then
⁭⁪=0
end
end
return
⁮⁭⁭⁪
end)({51,328,437,296,292},{105825,951200,1059725,843600,846800}),夜夜=(function(﻿,﻿‪﻿‪)local
﻿⁭﻿﻿,⁪‪⁭﻿,⁪⁪⁮⁭,‪='',0,#﻿‪﻿‪,#﻿
for
⁭‪﻿=1,⁪⁪⁮⁭
do
⁪‪⁭﻿=⁪‪⁭﻿+1
local
‪⁪⁪⁪=﻿‪﻿‪[⁭‪﻿]if
‪⁪⁪⁪..''~=‪⁪⁪⁪
then
﻿⁭﻿﻿=﻿⁭﻿﻿..__CHAR(‪⁪⁪⁪/(﻿[⁪‪⁭﻿])/((⁪⁪⁮⁭*‪)))else
﻿⁭﻿﻿=﻿⁭﻿﻿..‪⁪⁪⁪
end
if
⁪‪⁭﻿==‪
then
⁪‪⁭﻿=0
end
end
return
﻿⁭﻿﻿
end)({385,322,293,251},{671440,499744,543808,417664}),の夜=(function(﻿⁪‪‪,⁮)local
⁭⁭﻿⁮,﻿,﻿⁭‪,‪⁭='',0,#⁮,#﻿⁪‪‪
for
﻿﻿⁭⁭=1,﻿⁭‪
do
﻿=﻿+1
local
⁮﻿﻿=⁮[﻿﻿⁭⁭]if
⁮﻿﻿..''~=⁮﻿﻿
then
⁭⁭﻿⁮=⁭⁭﻿⁮..__CHAR(⁮﻿﻿/(﻿⁪‪‪[﻿])/((﻿⁭‪*‪⁭)))else
⁭⁭﻿⁮=⁭⁭﻿⁮..⁮﻿﻿
end
if
﻿==‪⁭
then
﻿=0
end
end
return
⁭⁭﻿⁮
end)({288,293,51},{342144,355116,64260,373248}),コ夜=(function(⁮⁪,⁮)local
‪,⁭⁭⁪⁪,⁭‪,⁭⁮='',0,#⁮,#⁮⁪
for
⁮﻿⁮⁪=1,⁭‪
do
⁭⁭⁪⁪=⁭⁭⁪⁪+1
local
﻿⁮=⁮[⁮﻿⁮⁪]if
﻿⁮..''~=﻿⁮
then
‪=‪..__CHAR(﻿⁮/(⁮⁪[⁭⁭⁪⁪])/((⁭‪*⁭⁮)))else
‪=‪..﻿⁮
end
if
⁭⁭⁪⁪==⁭⁮
then
⁭⁭⁪⁪=0
end
end
return
‪
end)({135,130,199},{133650,118170,207756}),ン夜=(function(⁮⁪⁭⁭,⁭)local
﻿⁮⁪,﻿﻿,⁮,﻿⁪⁭='',0,#⁭,#⁮⁪⁭⁭
for
⁪﻿⁮⁮=1,⁮
do
﻿﻿=﻿﻿+1
local
⁪⁮⁪=⁭[⁪﻿⁮⁮]if
⁪⁮⁪..''~=⁪⁮⁪
then
﻿⁮⁪=﻿⁮⁪..__CHAR(⁪⁮⁪/(⁮⁪⁭⁭[﻿﻿])/((⁮*﻿⁪⁭)))else
﻿⁮⁪=﻿⁮⁪..⁪⁮⁪
end
if
﻿﻿==﻿⁪⁭
then
﻿﻿=0
end
end
return
﻿⁮⁪
end)({397,223,182,133,451,284,153,424},{2486808,1830384,1375920,1110816,3279672,1738080,804168,3358080,3315744}),サ夜=(function(⁭,‪⁭⁭)local
⁮‪,⁪﻿⁪,⁪⁪‪,⁪⁮⁪='',0,#‪⁭⁭,#⁭
for
﻿=1,⁪⁪‪
do
⁪﻿⁪=⁪﻿⁪+1
local
⁭⁮⁮⁮=‪⁭⁭[﻿]if
⁭⁮⁮⁮..''~=⁭⁮⁮⁮
then
⁮‪=⁮‪..__CHAR(⁭⁮⁮⁮/(⁭[⁪﻿⁪])/((⁪⁪‪*⁪⁮⁪)))else
⁮‪=⁮‪..⁭⁮⁮⁮
end
if
⁪﻿⁪==⁪⁮⁪
then
⁪﻿⁪=0
end
end
return
⁮‪
end)({485,399,409},{480150,362691,426996}),ー夜=(function(‪⁭,⁪‪)local
⁮⁭,‪⁪⁮,﻿⁭⁭,⁮⁭﻿='',0,#⁪‪,#‪⁭
for
⁪⁪⁮⁪=1,﻿⁭⁭
do
‪⁪⁮=‪⁪⁮+1
local
﻿=⁪‪[⁪⁪⁮⁪]if
﻿..''~=﻿
then
⁮⁭=⁮⁭..__CHAR(﻿/(‪⁭[‪⁪⁮])/((﻿⁭⁭*⁮⁭﻿)))else
⁮⁭=⁮⁭..﻿
end
if
‪⁪⁮==⁮⁭﻿
then
‪⁪⁮=0
end
end
return
⁮⁭
end)({241,170,268,396,245},{790480,686800,1039840,1584000,833000,703720,748000,1243520}),ト夜=(function(﻿‪,‪)local
⁭⁮⁪,⁭⁪,⁪⁭,﻿⁭‪='',0,#‪,#﻿‪
for
⁮﻿﻿﻿=1,⁪⁭
do
⁭⁪=⁭⁪+1
local
⁮⁭‪⁭=‪[⁮﻿﻿﻿]if
⁮⁭‪⁭..''~=⁮⁭‪⁭
then
⁭⁮⁪=⁭⁮⁪..__CHAR(⁮⁭‪⁭/(﻿‪[⁭⁪])/((⁪⁭*﻿⁭‪)))else
⁭⁮⁪=⁭⁮⁪..⁮⁭‪⁭
end
if
⁭⁪==﻿⁭‪
then
⁭⁪=0
end
end
return
⁭⁮⁪
end)({383,357,417},{537732,496944,525420,496368}),は夜=(function(﻿⁪⁭,⁭)local
‪﻿﻿,‪⁮﻿⁪,⁭⁮⁭,⁪='',0,#⁭,#﻿⁪⁭
for
⁭‪⁮=1,⁭⁮⁭
do
‪⁮﻿⁪=‪⁮﻿⁪+1
local
⁪⁭⁪﻿=⁭[⁭‪⁮]if
⁪⁭⁪﻿..''~=⁪⁭⁪﻿
then
‪﻿﻿=‪﻿﻿..__CHAR(⁪⁭⁪﻿/(﻿⁪⁭[‪⁮﻿⁪])/((⁭⁮⁭*⁪)))else
‪﻿﻿=‪﻿﻿..⁪⁭⁪﻿
end
if
‪⁮﻿⁪==⁪
then
‪⁮﻿⁪=0
end
end
return
‪﻿﻿
end)({186,586,330,218,413,297,57},{1059828,3745126,2007390,1309308,2671284,2538459,368676,1389234,4421956,2744280,1695386}),最夜=(function(⁭﻿﻿⁪,﻿)local
⁪⁪⁮﻿,⁭﻿‪,﻿‪⁭‪,‪='',0,#﻿,#⁭﻿﻿⁪
for
⁪‪⁮⁮=1,﻿‪⁭‪
do
⁭﻿‪=⁭﻿‪+1
local
﻿‪﻿⁪=﻿[⁪‪⁮⁮]if
﻿‪﻿⁪..''~=﻿‪﻿⁪
then
⁪⁪⁮﻿=⁪⁪⁮﻿..__CHAR(﻿‪﻿⁪/(⁭﻿﻿⁪[⁭﻿‪])/((﻿‪⁭‪*‪)))else
⁪⁪⁮﻿=⁪⁪⁮﻿..﻿‪﻿⁪
end
if
⁭﻿‪==‪
then
⁭﻿‪=0
end
end
return
⁪⁪⁮﻿
end)({171,298,201,406},{320112,553088,337680,701568})}local
コ={高夜=(function(⁮⁭,‪)local
‪⁭,⁮﻿,⁪,﻿⁭⁭⁭='',0,#‪,#⁮⁭
for
﻿=1,⁪
do
⁮﻿=⁮﻿+1
local
⁮‪‪=‪[﻿]if
⁮‪‪..''~=⁮‪‪
then
‪⁭=‪⁭..__CHAR(⁮‪‪/(⁮⁭[⁮﻿])/((⁪*﻿⁭⁭⁭)))else
‪⁭=‪⁭..⁮‪‪
end
if
⁮﻿==﻿⁭⁭⁭
then
⁮﻿=0
end
end
return
‪⁭
end)({319,52,332},{192357,38376,200196}),で夜=(function(﻿﻿,⁪)local
⁭⁮,﻿‪⁪⁮,⁪﻿,⁭⁪='',0,#⁪,#﻿﻿
for
⁪﻿⁮=1,⁪﻿
do
﻿‪⁪⁮=﻿‪⁪⁮+1
local
⁪‪⁮=⁪[⁪﻿⁮]if
⁪‪⁮..''~=⁪‪⁮
then
⁭⁮=⁭⁮..__CHAR(⁪‪⁮/(﻿﻿[﻿‪⁪⁮])/((⁪﻿*⁭⁪)))else
⁭⁮=⁭⁮..⁪‪⁮
end
if
﻿‪⁪⁮==⁭⁪
then
﻿‪⁪⁮=0
end
end
return
⁭⁮
end)({83,436,168},{116532,606912,211680,107568}),し夜=(function(⁪﻿⁭,⁭⁭)local
⁮﻿,⁭﻿⁪,⁪⁭⁪,﻿﻿⁭‪='',0,#⁭⁭,#⁪﻿⁭
for
⁮‪⁪=1,⁪⁭⁪
do
⁭﻿⁪=⁭﻿⁪+1
local
⁪=⁭⁭[⁮‪⁪]if
⁪..''~=⁪
then
⁮﻿=⁮﻿..__CHAR(⁪/(⁪﻿⁭[⁭﻿⁪])/((⁪⁭⁪*﻿﻿⁭‪)))else
⁮﻿=⁮﻿..⁪
end
if
⁭﻿⁪==﻿﻿⁭‪
then
⁭﻿⁪=0
end
end
return
⁮﻿
end)({263,185,616,188,141,358,370,118},{1127744,1314240,4297216,1347584,1028736,2314112,2723200,868480}),た夜=(function(⁪⁮⁪⁪,﻿⁪)local
⁭⁭⁮⁪,﻿⁭﻿,‪,⁭='',0,#﻿⁪,#⁪⁮⁪⁪
for
﻿=1,‪
do
﻿⁭﻿=﻿⁭﻿+1
local
⁪⁭=﻿⁪[﻿]if
⁪⁭..''~=⁪⁭
then
⁭⁭⁮⁪=⁭⁭⁮⁪..__CHAR(⁪⁭/(⁪⁮⁪⁪[﻿⁭﻿])/((‪*⁭)))else
⁭⁭⁮⁪=⁭⁭⁮⁪..⁪⁭
end
if
﻿⁭﻿==⁭
then
﻿⁭﻿=0
end
end
return
⁭⁭⁮⁪
end)({481,168,241},{476190,152712,251604}),。夜=(function(⁮,⁪‪⁪)local
‪‪⁭,﻿⁪⁭﻿,⁪⁭⁭,⁮⁭⁭⁮='',0,#⁪‪⁪,#⁮
for
﻿‪‪﻿=1,⁪⁭⁭
do
﻿⁪⁭﻿=﻿⁪⁭﻿+1
local
⁭⁭=⁪‪⁪[﻿‪‪﻿]if
⁭⁭..''~=⁭⁭
then
‪‪⁭=‪‪⁭..__CHAR(⁭⁭/(⁮[﻿⁪⁭﻿])/((⁪⁭⁭*⁮⁭⁭⁮)))else
‪‪⁭=‪‪⁭..⁭⁭
end
if
﻿⁪⁭﻿==⁮⁭⁭⁮
then
﻿⁪⁭﻿=0
end
end
return
‪‪⁭
end)({585,246,193,149},{1832220,1009584,729540,622224,2127060,584496,771228,595404,2274480}),昨の=(function(⁭‪,⁮)local
⁪‪⁮⁮,‪﻿⁮,﻿⁭‪‪,﻿='',0,#⁮,#⁭‪
for
‪﻿=1,﻿⁭‪‪
do
‪﻿⁮=‪﻿⁮+1
local
⁪=⁮[‪﻿]if
⁪..''~=⁪
then
⁪‪⁮⁮=⁪‪⁮⁮..__CHAR(⁪/(⁭‪[‪﻿⁮])/((﻿⁭‪‪*﻿)))else
⁪‪⁮⁮=⁪‪⁮⁮..⁪
end
if
‪﻿⁮==﻿
then
‪﻿⁮=0
end
end
return
⁪‪⁮⁮
end)({295,265,226},{292050,240885,235944}),夜の=(function(‪⁮‪,‪‪⁪)local
⁪‪,⁭⁭‪⁪,⁭‪⁪﻿,⁮='',0,#‪‪⁪,#‪⁮‪
for
﻿⁪=1,⁭‪⁪﻿
do
⁭⁭‪⁪=⁭⁭‪⁪+1
local
‪=‪‪⁪[﻿⁪]if
‪..''~=‪
then
⁪‪=⁪‪..__CHAR(‪/(‪⁮‪[⁭⁭‪⁪])/((⁭‪⁪﻿*⁮)))else
⁪‪=⁪‪..‪
end
if
⁭⁭‪⁪==⁮
then
⁭⁭‪⁪=0
end
end
return
⁪‪
end)({313,192,407,118,190,120,313,137},{1642624,1241088,2526656,755200,826880,744960,2323712,850496}),のの=(function(‪﻿‪‪,﻿⁮⁮)local
⁭⁪,⁮,‪,⁮⁮='',0,#﻿⁮⁮,#‪﻿‪‪
for
‪⁭⁮=1,‪
do
⁮=⁮+1
local
⁭=﻿⁮⁮[‪⁭⁮]if
⁭..''~=⁭
then
⁭⁪=⁭⁪..__CHAR(⁭/(‪﻿‪‪[⁮])/((‪*⁮⁮)))else
⁭⁪=⁭⁪..⁭
end
if
⁮==⁮⁮
then
⁮=0
end
end
return
⁭⁪
end)({223,410,540},{220770,372690,563760}),コの=(function(⁪﻿﻿﻿,⁮⁭⁭)local
⁭﻿‪‪,‪,‪⁪﻿‪,﻿⁭='',0,#⁮⁭⁭,#⁪﻿﻿﻿
for
⁭⁭=1,‪⁪﻿‪
do
‪=‪+1
local
⁮⁮=⁮⁭⁭[⁭⁭]if
⁮⁮..''~=⁮⁮
then
⁭﻿‪‪=⁭﻿‪‪..__CHAR(⁮⁮/(⁪﻿﻿﻿[‪])/((‪⁪﻿‪*﻿⁭)))else
⁭﻿‪‪=⁭﻿‪‪..⁮⁮
end
if
‪==﻿⁭
then
‪=0
end
end
return
⁭﻿‪‪
end)({165,318,286,136,239,83,482},{757680,1798608,1553552,761600,883344,515928,2996112,997920}),ンの=(function(⁪‪⁭⁪,﻿﻿)local
⁮‪⁮,﻿‪⁮‪,⁭,﻿='',0,#﻿﻿,#⁪‪⁭⁪
for
⁮⁪=1,⁭
do
﻿‪⁮‪=﻿‪⁮‪+1
local
‪⁭=﻿﻿[⁮⁪]if
‪⁭..''~=‪⁭
then
⁮‪⁮=⁮‪⁮..__CHAR(‪⁭/(⁪‪⁭⁪[﻿‪⁮‪])/((⁭*﻿)))else
⁮‪⁮=⁮‪⁮..‪⁭
end
if
﻿‪⁮‪==﻿
then
﻿‪⁮‪=0
end
end
return
⁮‪⁮
end)({422,203,239,257,214},{1223800,492275,585550,693900,540350})}local
ン={サの=(function(﻿⁮⁭‪,⁪⁭﻿⁭)local
‪﻿﻿,‪‪⁭‪,⁭,﻿‪⁮='',0,#⁪⁭﻿⁭,#﻿⁮⁭‪
for
‪⁭‪=1,⁭
do
‪‪⁭‪=‪‪⁭‪+1
local
⁮⁮﻿⁮=⁪⁭﻿⁭[‪⁭‪]if
⁮⁮﻿⁮..''~=⁮⁮﻿⁮
then
‪﻿﻿=‪﻿﻿..__CHAR(⁮⁮﻿⁮/(﻿⁮⁭‪[‪‪⁭‪])/((⁭*﻿‪⁮)))else
‪﻿﻿=‪﻿﻿..⁮⁮﻿⁮
end
if
‪‪⁭‪==﻿‪⁮
then
‪‪⁭‪=0
end
end
return
‪﻿﻿
end)({366,400,354},{751032,727200,694548,731268,849600,643572}),ーの=(function(⁮,⁮⁪)local
‪⁭﻿,‪﻿⁭⁮,﻿﻿‪,﻿‪﻿='',0,#⁮⁪,#⁮
for
﻿=1,﻿﻿‪
do
‪﻿⁭⁮=‪﻿⁭⁮+1
local
⁭⁭⁭﻿=⁮⁪[﻿]if
⁭⁭⁭﻿..''~=⁭⁭⁭﻿
then
‪⁭﻿=‪⁭﻿..__CHAR(⁭⁭⁭﻿/(⁮[‪﻿⁭⁮])/((﻿﻿‪*﻿‪﻿)))else
‪⁭﻿=‪⁭﻿..⁭⁭⁭﻿
end
if
‪﻿⁭⁮==﻿‪﻿
then
‪﻿⁭⁮=0
end
end
return
‪⁭﻿
end)({323,249,265},{33915}),トの=(function(⁮⁪⁮,⁮⁮)local
‪⁭⁪,‪﻿⁪,﻿⁭⁭⁮,⁮⁮‪⁪='',0,#⁮⁮,#⁮⁪⁮
for
‪=1,﻿⁭⁭⁮
do
‪﻿⁪=‪﻿⁪+1
local
‪⁮‪=⁮⁮[‪]if
‪⁮‪..''~=‪⁮‪
then
‪⁭⁪=‪⁭⁪..__CHAR(‪⁮‪/(⁮⁪⁮[‪﻿⁪])/((﻿⁭⁭⁮*⁮⁮‪⁪)))else
‪⁭⁪=‪⁭⁪..‪⁮‪
end
if
‪﻿⁪==⁮⁮‪⁪
then
‪﻿⁪=0
end
end
return
‪⁭⁪
end)({238,328,524,405,505,452},{669732,1432704,2134776,1871100,2333100,1917384,1079568}),はの=(function(⁪,﻿⁭⁪‪)local
⁭⁪﻿,⁮‪‪,﻿‪,‪‪﻿='',0,#﻿⁭⁪‪,#⁪
for
﻿⁪‪⁪=1,﻿‪
do
⁮‪‪=⁮‪‪+1
local
﻿⁮=﻿⁭⁪‪[﻿⁪‪⁪]if
﻿⁮..''~=﻿⁮
then
⁭⁪﻿=⁭⁪﻿..__CHAR(﻿⁮/(⁪[⁮‪‪])/((﻿‪*‪‪﻿)))else
⁭⁪﻿=⁭⁪﻿..﻿⁮
end
if
⁮‪‪==‪‪﻿
then
⁮‪‪=0
end
end
return
⁭⁪﻿
end)({151,325,224,269,217},{302000,788125,638400,780100,623875}),最の=(function(⁪⁪,⁪‪⁪)local
⁪,⁭,﻿﻿⁮⁪,‪⁮⁭='',0,#⁪‪⁪,#⁪⁪
for
‪⁪=1,﻿﻿⁮⁪
do
⁭=⁭+1
local
⁭⁪=⁪‪⁪[‪⁪]if
⁭⁪..''~=⁭⁪
then
⁪=⁪..__CHAR(⁭⁪/(⁪⁪[⁭])/((﻿﻿⁮⁪*‪⁮⁭)))else
⁪=⁪..⁭⁪
end
if
⁭==‪⁮⁭
then
⁭=0
end
end
return
⁪
end)({363,438,276},{435600,637290,471960,631620,755550}),高の=(function(﻿⁮,⁭⁮)local
⁭‪⁪﻿,⁭,⁪,‪⁭⁪='',0,#⁭⁮,#﻿⁮
for
⁮=1,⁪
do
⁭=⁭+1
local
⁮⁮⁭=⁭⁮[⁮]if
⁮⁮⁭..''~=⁮⁮⁭
then
⁭‪⁪﻿=⁭‪⁪﻿..__CHAR(⁮⁮⁭/(﻿⁮[⁭])/((⁪*‪⁭⁪)))else
⁭‪⁪﻿=⁭‪⁪﻿..⁮⁮⁭
end
if
⁭==‪⁭⁪
then
⁭=0
end
end
return
⁭‪⁪﻿
end)({242,280,263},{290400,407400,449730,421080,483000}),での=(function(﻿,⁮﻿)local
⁭⁮﻿,⁪,⁭﻿,⁭‪='',0,#⁮﻿,#﻿
for
‪‪⁮‪=1,⁭﻿
do
⁪=⁪+1
local
⁪⁮=⁮﻿[‪‪⁮‪]if
⁪⁮..''~=⁪⁮
then
⁭⁮﻿=⁭⁮﻿..__CHAR(⁪⁮/(﻿[⁪])/((⁭﻿*⁭‪)))else
⁭⁮﻿=⁭⁮﻿..⁪⁮
end
if
⁪==⁭‪
then
⁪=0
end
end
return
⁭⁮﻿
end)({254,367,359},{111252,149736}),しの=(function(⁪⁪,‪)local
⁪⁪‪⁭,⁭‪⁮⁮,⁪,⁭='',0,#‪,#⁪⁪
for
‪⁭⁮=1,⁪
do
⁭‪⁮⁮=⁭‪⁮⁮+1
local
⁮⁭⁮⁭=‪[‪⁭⁮]if
⁮⁭⁮⁭..''~=⁮⁭⁮⁭
then
⁪⁪‪⁭=⁪⁪‪⁭..__CHAR(⁮⁭⁮⁭/(⁪⁪[⁭‪⁮⁮])/((⁪*⁭)))else
⁪⁪‪⁭=⁪⁪‪⁭..⁮⁭⁮⁭
end
if
⁭‪⁮⁮==⁭
then
⁭‪⁮⁮=0
end
end
return
⁪⁪‪⁭
end)({398,236,258,375},{534912,456896,462336,606000}),たの=(function(⁭⁭,⁭⁭⁮⁭)local
⁮⁮﻿⁮,⁪‪,⁭﻿‪‪,﻿⁪⁮='',0,#⁭⁭⁮⁭,#⁭⁭
for
﻿⁮⁮﻿=1,⁭﻿‪‪
do
⁪‪=⁪‪+1
local
﻿⁮⁮=⁭⁭⁮⁭[﻿⁮⁮﻿]if
﻿⁮⁮..''~=﻿⁮⁮
then
⁮⁮﻿⁮=⁮⁮﻿⁮..__CHAR(﻿⁮⁮/(⁭⁭[⁪‪])/((⁭﻿‪‪*﻿⁪⁮)))else
⁮⁮﻿⁮=⁮⁮﻿⁮..﻿⁮⁮
end
if
⁪‪==﻿⁪⁮
then
⁪‪=0
end
end
return
⁮⁮﻿⁮
end)({408,214,151,340},{443904,332128,280256,527680}),。の=(function(‪⁮﻿﻿,⁭⁭⁭⁪)local
⁭,⁪,⁪⁭,‪='',0,#⁭⁭⁭⁪,#‪⁮﻿﻿
for
‪⁭‪=1,⁪⁭
do
⁪=⁪+1
local
﻿=⁭⁭⁭⁪[‪⁭‪]if
﻿..''~=﻿
then
⁭=⁭..__CHAR(﻿/(‪⁮﻿﻿[⁪])/((⁪⁭*‪)))else
⁭=⁭..﻿
end
if
⁪==‪
then
⁪=0
end
end
return
⁭
end)({316,252,347,415,187},{632000,611100,988950,1203500,537625})}local
サ={昨コ=(function(﻿,⁭﻿⁮)local
﻿﻿,⁮‪,⁭⁪,⁪='',0,#⁭﻿⁮,#﻿
for
‪⁮‪‪=1,⁭⁪
do
⁮‪=⁮‪+1
local
⁭=⁭﻿⁮[‪⁮‪‪]if
⁭..''~=⁭
then
﻿﻿=﻿﻿..__CHAR(⁭/(﻿[⁮‪])/((⁭⁪*⁪)))else
﻿﻿=﻿﻿..⁭
end
if
⁮‪==⁪
then
⁮‪=0
end
end
return
﻿﻿
end)({325,157,111,416},{520000,304580,253080,965120,747500}),夜コ=(function(⁮⁪﻿,‪)local
⁪,⁭,﻿⁪⁭⁮,﻿⁮⁭='',0,#‪,#⁮⁪﻿
for
⁮⁮﻿=1,﻿⁪⁭⁮
do
⁭=⁭+1
local
﻿=‪[⁮⁮﻿]if
﻿..''~=﻿
then
⁪=⁪..__CHAR(﻿/(⁮⁪﻿[⁭])/((﻿⁪⁭⁮*﻿⁮⁭)))else
⁪=⁪..﻿
end
if
⁭==﻿⁮⁭
then
⁭=0
end
end
return
⁪
end)({120,175,526},{52560,71400}),のコ=(function(⁪‪,⁮)local
⁪,⁭,﻿,⁪⁮﻿='',0,#⁮,#⁪‪
for
⁮⁪﻿=1,﻿
do
⁭=⁭+1
local
⁪⁭﻿‪=⁮[⁮⁪﻿]if
⁪⁭﻿‪..''~=⁪⁭﻿‪
then
⁪=⁪..__CHAR(⁪⁭﻿‪/(⁪‪[⁭])/((﻿*⁪⁮﻿)))else
⁪=⁪..⁪⁭﻿‪
end
if
⁭==⁪⁮﻿
then
⁭=0
end
end
return
⁪
end)({278,67,337},{280224,97284,452928,336936}),ココ=(function(⁭‪,⁭⁪‪⁮)local
﻿⁮‪⁪,⁭,⁮﻿⁭,⁭⁪='',0,#⁭⁪‪⁮,#⁭‪
for
⁪=1,⁮﻿⁭
do
⁭=⁭+1
local
﻿﻿=⁭⁪‪⁮[⁪]if
﻿﻿..''~=﻿﻿
then
﻿⁮‪⁪=﻿⁮‪⁪..__CHAR(﻿﻿/(⁭‪[⁭])/((⁮﻿⁭*⁭⁪)))else
﻿⁮‪⁪=﻿⁮‪⁪..﻿﻿
end
if
⁭==⁭⁪
then
⁭=0
end
end
return
﻿⁮‪⁪
end)({175,6,4},{142800,6984,5568,203700}),ンコ=(function(‪,⁮)local
⁭‪‪,‪‪,⁪⁪⁪,﻿⁪='',0,#⁮,#‪
for
⁪⁭=1,⁪⁪⁪
do
‪‪=‪‪+1
local
⁭=⁮[⁪⁭]if
⁭..''~=⁭
then
⁭‪‪=⁭‪‪..__CHAR(⁭/(‪[‪‪])/((⁪⁪⁪*﻿⁪)))else
⁭‪‪=⁭‪‪..⁭
end
if
‪‪==﻿⁪
then
‪‪=0
end
end
return
⁭‪‪
end)({75,376,160,495},{120000,729440,364800,1148400,172500}),サコ=(function(⁪⁪⁮⁭,⁭﻿)local
‪⁮⁪⁪,⁪⁪,‪⁮‪,⁭='',0,#⁭﻿,#⁪⁪⁮⁭
for
﻿⁪﻿⁭=1,‪⁮‪
do
⁪⁪=⁪⁪+1
local
﻿⁮‪⁮=⁭﻿[﻿⁪﻿⁭]if
﻿⁮‪⁮..''~=﻿⁮‪⁮
then
‪⁮⁪⁪=‪⁮⁪⁪..__CHAR(﻿⁮‪⁮/(⁪⁪⁮⁭[⁪⁪])/((‪⁮‪*⁭)))else
‪⁮⁪⁪=‪⁮⁪⁪..﻿⁮‪⁮
end
if
⁪⁪==⁭
then
⁪⁪=0
end
end
return
‪⁮⁪⁪
end)({378,271,336,187,90},{756000,657175,957600,542300,258750}),ーコ=(function(﻿﻿﻿,⁪⁭)local
﻿‪,‪‪﻿,‪⁮⁪,⁪⁪⁭﻿='',0,#⁪⁭,#﻿﻿﻿
for
‪⁪=1,‪⁮⁪
do
‪‪﻿=‪‪﻿+1
local
⁮⁪=⁪⁭[‪⁪]if
⁮⁪..''~=⁮⁪
then
﻿‪=﻿‪..__CHAR(⁮⁪/(﻿﻿﻿[‪‪﻿])/((‪⁮⁪*⁪⁪⁭﻿)))else
﻿‪=﻿‪..⁮⁪
end
if
‪‪﻿==⁪⁪⁭﻿
then
‪‪﻿=0
end
end
return
﻿‪
end)({233,306,309},{102054,124848}),トコ=(function(⁪,﻿)local
﻿⁪⁭,﻿﻿⁪⁪,⁭,﻿﻿‪='',0,#﻿,#⁪
for
⁮=1,⁭
do
﻿﻿⁪⁪=﻿﻿⁪⁪+1
local
⁪⁮=﻿[⁮]if
⁪⁮..''~=⁪⁮
then
﻿⁪⁭=﻿⁪⁭..__CHAR(⁪⁮/(⁪[﻿﻿⁪⁪])/((⁭*﻿﻿‪)))else
﻿⁪⁭=﻿⁪⁭..⁪⁮
end
if
﻿﻿⁪⁪==﻿﻿‪
then
﻿﻿⁪⁪=0
end
end
return
﻿⁪⁭
end)({77,176,223},{77616,255552,299712,93324}),はコ=(function(‪⁭‪⁭,⁭)local
⁪⁮⁮﻿,⁭﻿,﻿⁪﻿,﻿‪﻿﻿='',0,#⁭,#‪⁭‪⁭
for
⁪=1,﻿⁪﻿
do
⁭﻿=⁭﻿+1
local
⁮=⁭[⁪]if
⁮..''~=⁮
then
⁪⁮⁮﻿=⁪⁮⁮﻿..__CHAR(⁮/(‪⁭‪⁭[⁭﻿])/((﻿⁪﻿*﻿‪﻿﻿)))else
⁪⁮⁮﻿=⁪⁮⁮﻿..⁮
end
if
⁭﻿==﻿‪﻿﻿
then
⁭﻿=0
end
end
return
⁪⁮⁮﻿
end)({536,260,672,399},{583168,403520,1247232,619248}),最コ=(function(﻿⁪‪‪,⁮﻿⁭⁪)local
⁮,⁮⁪‪,⁪﻿⁮‪,⁭⁮‪='',0,#⁮﻿⁭⁪,#﻿⁪‪‪
for
﻿⁪⁮⁭=1,⁪﻿⁮‪
do
⁮⁪‪=⁮⁪‪+1
local
⁮⁪﻿‪=⁮﻿⁭⁪[﻿⁪⁮⁭]if
⁮⁪﻿‪..''~=⁮⁪﻿‪
then
⁮=⁮..__CHAR(⁮⁪﻿‪/(﻿⁪‪‪[⁮⁪‪])/((⁪﻿⁮‪*⁭⁮‪)))else
⁮=⁮..⁮⁪﻿‪
end
if
⁮⁪‪==⁭⁮‪
then
⁮⁪‪=0
end
end
return
⁮
end)({352,233,193,349},{563200,452020,440040,809680,809600})}local
ー={高コ=(function(﻿⁮⁪‪,⁮⁪⁮⁮)local
﻿,‪﻿﻿⁮,⁮,⁭='',0,#⁮⁪⁮⁮,#﻿⁮⁪‪
for
‪⁮⁪‪=1,⁮
do
‪﻿﻿⁮=‪﻿﻿⁮+1
local
⁪⁮⁪⁮=⁮⁪⁮⁮[‪⁮⁪‪]if
⁪⁮⁪⁮..''~=⁪⁮⁪⁮
then
﻿=﻿..__CHAR(⁪⁮⁪⁮/(﻿⁮⁪‪[‪﻿﻿⁮])/((⁮*⁭)))else
﻿=﻿..⁪⁮⁪⁮
end
if
‪﻿﻿⁮==⁭
then
‪﻿﻿⁮=0
end
end
return
﻿
end)({258,343,414},{309600,499065,707940,448920,591675}),でコ=(function(‪,⁭⁮‪⁪)local
⁪⁪,⁭⁭‪,﻿﻿⁭,﻿‪='',0,#⁭⁮‪⁪,#‪
for
﻿⁭‪=1,﻿﻿⁭
do
⁭⁭‪=⁭⁭‪+1
local
⁪﻿⁮⁭=⁭⁮‪⁪[﻿⁭‪]if
⁪﻿⁮⁭..''~=⁪﻿⁮⁭
then
⁪⁪=⁪⁪..__CHAR(⁪﻿⁮⁭/(‪[⁭⁭‪])/((﻿﻿⁭*﻿‪)))else
⁪⁪=⁪⁪..⁪﻿⁮⁭
end
if
⁭⁭‪==﻿‪
then
⁭⁭‪=0
end
end
return
⁪⁪
end)({572,378,251,414},{768768,731808,449792,669024}),しコ=(function(﻿⁮,⁭⁮⁭)local
⁮⁭,‪⁮,⁪,﻿﻿⁪='',0,#⁭⁮⁭,#﻿⁮
for
﻿﻿﻿‪=1,⁪
do
‪⁮=‪⁮+1
local
⁮=⁭⁮⁭[﻿﻿﻿‪]if
⁮..''~=⁮
then
⁮⁭=⁮⁭..__CHAR(⁮/(﻿⁮[‪⁮])/((⁪*﻿﻿⁪)))else
⁮⁭=⁮⁭..⁮
end
if
‪⁮==﻿﻿⁪
then
‪⁮=0
end
end
return
⁮⁭
end)({224,122,330},{98112,49776}),たコ=(function(﻿⁮‪,⁮⁪‪﻿)local
⁭‪,⁭⁮,‪⁭⁮,‪='',0,#⁮⁪‪﻿,#﻿⁮‪
for
⁮⁮⁭﻿=1,‪⁭⁮
do
⁭⁮=⁭⁮+1
local
‪⁮=⁮⁪‪﻿[⁮⁮⁭﻿]if
‪⁮..''~=‪⁮
then
⁭‪=⁭‪..__CHAR(‪⁮/(﻿⁮‪[⁭⁮])/((‪⁭⁮*‪)))else
⁭‪=⁭‪..‪⁮
end
if
⁭⁮==‪
then
⁭⁮=0
end
end
return
⁭‪
end)({190,248,239,412},{206720,384896,443584,639424}),。コ=(function(⁭⁭⁭⁭,⁭⁭)local
‪﻿,‪⁮﻿⁭,⁮﻿﻿,⁭⁮='',0,#⁭⁭,#⁭⁭⁭⁭
for
⁮﻿⁮⁮=1,⁮﻿﻿
do
‪⁮﻿⁭=‪⁮﻿⁭+1
local
⁭⁪⁮=⁭⁭[⁮﻿⁮⁮]if
⁭⁪⁮..''~=⁭⁪⁮
then
‪﻿=‪﻿..__CHAR(⁭⁪⁮/(⁭⁭⁭⁭[‪⁮﻿⁭])/((⁮﻿﻿*⁭⁮)))else
‪﻿=‪﻿..⁭⁪⁮
end
if
‪⁮﻿⁭==⁭⁮
then
‪⁮﻿⁭=0
end
end
return
‪﻿
end)({312,472,90,365,191,195},{3470688,3313440,651240,1813320,1712124,2442960,3841344,5148576,942840,4296780,1691496,2127060,3875040,5709312,1078920,4336200,2372220,2127060}),昨ン=(function(‪⁭‪⁮,﻿⁪﻿)local
﻿⁪⁪⁪,⁮﻿⁪‪,⁪,⁭⁮⁮⁮='',0,#﻿⁪﻿,#‪⁭‪⁮
for
‪=1,⁪
do
⁮﻿⁪‪=⁮﻿⁪‪+1
local
‪⁭⁭﻿=﻿⁪﻿[‪]if
‪⁭⁭﻿..''~=‪⁭⁭﻿
then
﻿⁪⁪⁪=﻿⁪⁪⁪..__CHAR(‪⁭⁭﻿/(‪⁭‪⁮[⁮﻿⁪‪])/((⁪*⁭⁮⁮⁮)))else
﻿⁪⁪⁪=﻿⁪⁪⁪..‪⁭⁭﻿
end
if
⁮﻿⁪‪==⁭⁮⁮⁮
then
⁮﻿⁪‪=0
end
end
return
﻿⁪⁪⁪
end)({288,379,142},{126144,154632}),夜ン=(function(⁮,‪‪‪)local
﻿,﻿⁮﻿﻿,‪⁭⁮,﻿‪‪='',0,#‪‪‪,#⁮
for
﻿‪⁭=1,‪⁭⁮
do
﻿⁮﻿﻿=﻿⁮﻿﻿+1
local
⁭﻿⁭=‪‪‪[﻿‪⁭]if
⁭﻿⁭..''~=⁭﻿⁭
then
﻿=﻿..__CHAR(⁭﻿⁭/(⁮[﻿⁮﻿﻿])/((‪⁭⁮*﻿‪‪)))else
﻿=﻿..⁭﻿⁭
end
if
﻿⁮﻿﻿==﻿‪‪
then
﻿⁮﻿﻿=0
end
end
return
﻿
end)({393,189,352},{396144,274428,473088,476316}),のン=(function(‪⁮,⁪)local
⁮⁭‪﻿,‪﻿‪,‪⁪﻿,⁪⁮='',0,#⁪,#‪⁮
for
‪﻿⁪‪=1,‪⁪﻿
do
‪﻿‪=‪﻿‪+1
local
⁭=⁪[‪﻿⁪‪]if
⁭..''~=⁭
then
⁮⁭‪﻿=⁮⁭‪﻿..__CHAR(⁭/(‪⁮[‪﻿‪])/((‪⁪﻿*⁪⁮)))else
⁮⁭‪﻿=⁮⁭‪﻿..⁭
end
if
‪﻿‪==⁪⁮
then
‪﻿‪=0
end
end
return
⁮⁭‪﻿
end)({310,304,281},{135780,124032}),コン=(function(⁪﻿,﻿⁭﻿⁪)local
⁪⁮,⁭⁮⁪,‪,⁭='',0,#﻿⁭﻿⁪,#⁪﻿
for
‪﻿﻿=1,‪
do
⁭⁮⁪=⁭⁮⁪+1
local
﻿⁮=﻿⁭﻿⁪[‪﻿﻿]if
﻿⁮..''~=﻿⁮
then
⁪⁮=⁪⁮..__CHAR(﻿⁮/(⁪﻿[⁭⁮⁪])/((‪*⁭)))else
⁪⁮=⁪⁮..﻿⁮
end
if
⁭⁮⁪==⁭
then
⁭⁮⁪=0
end
end
return
⁪⁮
end)({337,301,330},{274992,350364,459360,392268}),ンン=(function(﻿,‪⁪⁮⁪)local
⁪‪⁮‪,‪⁮,⁮﻿⁭,﻿‪﻿‪='',0,#‪⁪⁮⁪,#﻿
for
⁪‪⁭⁪=1,⁮﻿⁭
do
‪⁮=‪⁮+1
local
‪⁪=‪⁪⁮⁪[⁪‪⁭⁪]if
‪⁪..''~=‪⁪
then
⁪‪⁮‪=⁪‪⁮‪..__CHAR(‪⁪/(﻿[‪⁮])/((⁮﻿⁭*﻿‪﻿‪)))else
⁪‪⁮‪=⁪‪⁮‪..‪⁪
end
if
‪⁮==﻿‪﻿‪
then
‪⁮=0
end
end
return
⁪‪⁮‪
end)({301,233,182},{131838,95064})}local
ト={サン=(function(⁭⁭,⁮‪)local
⁭‪⁮,⁮,‪‪﻿,﻿⁭='',0,#⁮‪,#⁭⁭
for
⁭‪=1,‪‪﻿
do
⁮=⁮+1
local
﻿⁮‪⁭=⁮‪[⁭‪]if
﻿⁮‪⁭..''~=﻿⁮‪⁭
then
⁭‪⁮=⁭‪⁮..__CHAR(﻿⁮‪⁭/(⁭⁭[⁮])/((‪‪﻿*﻿⁭)))else
⁭‪⁮=⁭‪⁮..﻿⁮‪⁭
end
if
⁮==﻿⁭
then
⁮=0
end
end
return
⁭‪⁮
end)({49,143,504},{49392,207636,677376,59388}),ーン=(function(⁭⁮⁭⁮,⁮‪)local
﻿⁪‪,⁪‪‪⁪,⁮,⁭⁭⁪='',0,#⁮‪,#⁭⁮⁭⁮
for
⁭‪⁮=1,⁮
do
⁪‪‪⁪=⁪‪‪⁪+1
local
⁭﻿=⁮‪[⁭‪⁮]if
⁭﻿..''~=⁭﻿
then
﻿⁪‪=﻿⁪‪..__CHAR(⁭﻿/(⁭⁮⁭⁮[⁪‪‪⁪])/((⁮*⁭⁭⁪)))else
﻿⁪‪=﻿⁪‪..⁭﻿
end
if
⁪‪‪⁪==⁭⁭⁪
then
⁪‪‪⁪=0
end
end
return
﻿⁪‪
end)({323,178,169},{141474,72624}),トン=(function(﻿,⁭⁪⁭)local
⁭⁪,﻿⁭⁪,‪⁮,⁪='',0,#⁭⁪⁭,#﻿
for
⁮⁮=1,‪⁮
do
﻿⁭⁪=﻿⁭⁪+1
local
﻿﻿‪⁮=⁭⁪⁭[⁮⁮]if
﻿﻿‪⁮..''~=﻿﻿‪⁮
then
⁭⁪=⁭⁪..__CHAR(﻿﻿‪⁮/(﻿[﻿⁭⁪])/((‪⁮*⁪)))else
⁭⁪=⁭⁪..﻿﻿‪⁮
end
if
﻿⁭⁪==⁪
then
﻿⁭⁪=0
end
end
return
⁭⁪
end)({57,3,284},{24966,1224}),はン=(function(⁮,⁮﻿⁭‪)local
⁪﻿⁭⁪,⁭‪⁭⁮,﻿,﻿⁭⁮⁮='',0,#⁮﻿⁭‪,#⁮
for
⁪‪⁮⁪=1,﻿
do
⁭‪⁭⁮=⁭‪⁭⁮+1
local
‪⁮‪⁭=⁮﻿⁭‪[⁪‪⁮⁪]if
‪⁮‪⁭..''~=‪⁮‪⁭
then
⁪﻿⁭⁪=⁪﻿⁭⁪..__CHAR(‪⁮‪⁭/(⁮[⁭‪⁭⁮])/((﻿*﻿⁭⁮⁮)))else
⁪﻿⁭⁪=⁪﻿⁭⁪..‪⁮‪⁭
end
if
⁭‪⁭⁮==﻿⁭⁮⁮
then
⁭‪⁭⁮=0
end
end
return
⁪﻿⁭⁪
end)({241,409,559,280},{262208,634768,1037504,434560}),最ン=(function(﻿,⁪⁮‪﻿)local
⁮,⁮‪⁪⁪,﻿﻿‪,⁭⁪⁭⁭='',0,#⁪⁮‪﻿,#﻿
for
‪=1,﻿﻿‪
do
⁮‪⁪⁪=⁮‪⁪⁪+1
local
﻿﻿⁭=⁪⁮‪﻿[‪]if
﻿﻿⁭..''~=﻿﻿⁭
then
⁮=⁮..__CHAR(﻿﻿⁭/(﻿[⁮‪⁪⁪])/((﻿﻿‪*⁭⁪⁭⁭)))else
⁮=⁮..﻿﻿⁭
end
if
⁮‪⁪⁪==⁭⁪⁭⁭
then
⁮‪⁪⁪=0
end
end
return
⁮
end)({154,385,397,82,344},{1427580,2252250,2393910,339480,2569680,1607760,3950100,3608730,715860,3374640,1136520,3499650,4108950,826560,3436560,1524600,3984750,3608730}),高ン=(function(⁪,⁪⁮⁪⁮)local
⁭,‪⁭﻿,⁮⁭,⁭⁮='',0,#⁪⁮⁪⁮,#⁪
for
⁪‪=1,⁮⁭
do
‪⁭﻿=‪⁭﻿+1
local
﻿⁭⁭‪=⁪⁮⁪⁮[⁪‪]if
﻿⁭⁭‪..''~=﻿⁭⁭‪
then
⁭=⁭..__CHAR(﻿⁭⁭‪/(⁪[‪⁭﻿])/((⁮⁭*⁭⁮)))else
⁭=⁭..﻿⁭⁭‪
end
if
‪⁭﻿==⁭⁮
then
‪⁭﻿=0
end
end
return
⁭
end)({119,79,142},{52122,32232}),でン=(function(﻿⁮⁭﻿,⁮﻿﻿⁮)local
‪⁮‪⁮,⁮⁪‪,﻿⁭,﻿﻿⁮⁮='',0,#⁮﻿﻿⁮,#﻿⁮⁭﻿
for
⁭=1,﻿⁭
do
⁮⁪‪=⁮⁪‪+1
local
‪⁮⁮=⁮﻿﻿⁮[⁭]if
‪⁮⁮..''~=‪⁮⁮
then
‪⁮‪⁮=‪⁮‪⁮..__CHAR(‪⁮⁮/(﻿⁮⁭﻿[⁮⁪‪])/((﻿⁭*﻿﻿⁮⁮)))else
‪⁮‪⁮=‪⁮‪⁮..‪⁮⁮
end
if
⁮⁪‪==﻿﻿⁮⁮
then
⁮⁪‪=0
end
end
return
‪⁮‪⁮
end)({408,568,1,141,404,282,89},{2170560,4413360,6790,987000,2347240,2289840,710220,2998800,4373600,7210}),しン=(function(⁪⁪,‪⁭)local
⁭⁪‪,⁭‪﻿,⁪,⁮⁭⁮='',0,#‪⁭,#⁪⁪
for
⁮﻿‪=1,⁪
do
⁭‪﻿=⁭‪﻿+1
local
‪=‪⁭[⁮﻿‪]if
‪..''~=‪
then
⁭⁪‪=⁭⁪‪..__CHAR(‪/(⁪⁪[⁭‪﻿])/((⁪*⁮⁭⁮)))else
⁭⁪‪=⁭⁪‪..‪
end
if
⁭‪﻿==⁮⁭⁮
then
⁭‪﻿=0
end
end
return
⁭⁪‪
end)({415,189,225},{1923525,552825,678375,859050,646380,1123875,1811475,850500,840375,2166300,969570,1063125,2054250,876015,455625}),たン=(function(﻿⁭‪‪,⁭⁪⁭﻿)local
‪‪‪,﻿⁭⁪‪,﻿‪,‪='',0,#⁭⁪⁭﻿,#﻿⁭‪‪
for
‪⁪﻿=1,﻿‪
do
﻿⁭⁪‪=﻿⁭⁪‪+1
local
‪﻿⁪﻿=⁭⁪⁭﻿[‪⁪﻿]if
‪﻿⁪﻿..''~=‪﻿⁪﻿
then
‪‪‪=‪‪‪..__CHAR(‪﻿⁪﻿/(﻿⁭‪‪[﻿⁭⁪‪])/((﻿‪*‪)))else
‪‪‪=‪‪‪..‪﻿⁪﻿
end
if
﻿⁭⁪‪==‪
then
﻿⁭⁪‪=0
end
end
return
‪‪‪
end)({141,215,222,458,436,282,549},{825132,1837605,1658118,3526600,2685760,2106258,5115033,1172556,1837605,1658118,3526600}),。ン=(function(⁭,‪)local
﻿,⁪,﻿⁪⁮,⁭⁭='',0,#‪,#⁭
for
﻿⁮=1,﻿⁪⁮
do
⁪=⁪+1
local
⁭⁮⁭⁪=‪[﻿⁮]if
⁭⁮⁭⁪..''~=⁭⁮⁭⁪
then
﻿=﻿..__CHAR(⁭⁮⁭⁪/(⁭[⁪])/((﻿⁪⁮*⁭⁭)))else
﻿=﻿..⁭⁮⁭⁪
end
if
⁪==⁭⁭
then
⁪=0
end
end
return
﻿
end)({240,436,181,411,494},{19440000,36297000,13439250,29900250,40014000,5760000,33681000,8823750,20652750,35197500,14040000,33027000,15747000,9864000,22600500,5760000,40221000,6244500,14179500,17043000,22500000,10464000,14661000,34215750,36679500,17460000,35316000,4344000,31749750,24082500,12060000,31065000,11267250,31133250,40755000,18000000,10464000,8280750,9864000,38161500,11700000,21909000,12896250,24043500,37420500,20880000,29757000,6651750,28667250,11856000,19440000,36297000,13439250,29900250,40014000,5760000,33681000,8823750,20652750,35197500,14940000,37932000,15475500,31133250,35938500,19620000,10464000,8280750,9864000,38161500,11700000,21909000,12896250,24043500,37420500,20880000,29757000,6787500,28667250,11856000,19440000,36297000,13439250,29900250,40014000,5760000,33681000,8823750,20652750,35197500,11700000,32700000,13575000,25276500,37420500,17820000,33027000,14253750,36373500,37420500,20520000,10464000,8280750,9864000,38161500,11700000,21909000,12896250,24043500,37420500,20880000,29757000,6923250,28667250,11856000,19440000,36297000,13439250,29900250,40014000,5760000,33681000,8823750,20652750,35197500,12780000,33027000,15747000,22194000,35938500,19800000,32700000,14661000,31133250,42237000,5760000,19947000,4344000,31749750,24082500,12060000,31065000,10588500,31133250,42978000,16380000,17004000,12624750,'\n',''})}local
は={昨サ=(function(⁭⁮⁭,⁪‪⁮﻿)local
⁮⁮‪,﻿﻿﻿,⁮‪,⁭⁭⁮‪='',0,#⁪‪⁮﻿,#⁭⁮⁭
for
⁭⁮﻿⁪=1,⁮‪
do
﻿﻿﻿=﻿﻿﻿+1
local
﻿⁭⁭⁪=⁪‪⁮﻿[⁭⁮﻿⁪]if
﻿⁭⁭⁪..''~=﻿⁭⁭⁪
then
⁮⁮‪=⁮⁮‪..__CHAR(﻿⁭⁭⁪/(⁭⁮⁭[﻿﻿﻿])/((⁮‪*⁭⁭⁮‪)))else
⁮⁮‪=⁮⁮‪..﻿⁭⁭⁪
end
if
﻿﻿﻿==⁭⁭⁮‪
then
﻿﻿﻿=0
end
end
return
⁮⁮‪
end)({237,114,223,177},{1757592,533520,1075752,586224,1416312,952128,1830384,1287144,1655208,894672,1316592,1287144,1962360,919296,1782216,1401840,1962360,829008}),夜サ=(function(⁭‪﻿﻿,⁭)local
⁮﻿﻿,⁮⁮⁮,⁭⁪﻿,⁭‪⁭﻿='',0,#⁭,#⁭‪﻿﻿
for
⁮=1,⁭⁪﻿
do
⁮⁮⁮=⁮⁮⁮+1
local
﻿=⁭[⁮]if
﻿..''~=﻿
then
⁮﻿﻿=⁮﻿﻿..__CHAR(﻿/(⁭‪﻿﻿[⁮⁮⁮])/((⁭⁪﻿*⁭‪⁭﻿)))else
⁮﻿﻿=⁮﻿﻿..﻿
end
if
⁮⁮⁮==⁭‪⁭﻿
then
⁮⁮⁮=0
end
end
return
⁮﻿﻿
end)({145,56,111,212,231},{290000,135800,316350,614800,664125}),のサ=(function(‪‪⁪﻿,‪⁮)local
﻿,⁪﻿⁮⁪,‪‪⁪,⁪⁭‪⁮='',0,#‪⁮,#‪‪⁪﻿
for
﻿⁪=1,‪‪⁪
do
⁪﻿⁮⁪=⁪﻿⁮⁪+1
local
⁮⁮⁪⁪=‪⁮[﻿⁪]if
⁮⁮⁪⁪..''~=⁮⁮⁪⁪
then
﻿=﻿..__CHAR(⁮⁮⁪⁪/(‪‪⁪﻿[⁪﻿⁮⁪])/((‪‪⁪*⁪⁭‪⁮)))else
﻿=﻿..⁮⁮⁪⁪
end
if
⁪﻿⁮⁪==⁪⁭‪⁮
then
⁪﻿⁮⁪=0
end
end
return
﻿
end)({236,169,503,408,108},{472000,409825,1433550,1183200,310500}),コサ=(function(⁪⁭⁭‪,⁭)local
⁮⁭‪,﻿⁪⁮⁮,⁮⁮⁮,‪⁮='',0,#⁭,#⁪⁭⁭‪
for
﻿⁭⁮=1,⁮⁮⁮
do
﻿⁪⁮⁮=﻿⁪⁮⁮+1
local
⁭﻿‪=⁭[﻿⁭⁮]if
⁭﻿‪..''~=⁭﻿‪
then
⁮⁭‪=⁮⁭‪..__CHAR(⁭﻿‪/(⁪⁭⁭‪[﻿⁪⁮⁮])/((⁮⁮⁮*‪⁮)))else
⁮⁭‪=⁮⁭‪..⁭﻿‪
end
if
﻿⁪⁮⁮==‪⁮
then
﻿⁪⁮⁮=0
end
end
return
⁮⁭‪
end)({305,521,513,195,383},{715225,1896440,1741635,750750,1474550,1078175,1969380}),ンサ=(function(⁭⁮⁭,⁪﻿⁮)local
‪⁭‪,‪,﻿⁪,⁭⁮='',0,#⁪﻿⁮,#⁭⁮⁭
for
⁭‪⁮=1,﻿⁪
do
‪=‪+1
local
‪⁪=⁪﻿⁮[⁭‪⁮]if
‪⁪..''~=‪⁪
then
‪⁭‪=‪⁭‪..__CHAR(‪⁪/(⁭⁮⁭[‪])/((﻿⁪*⁭⁮)))else
‪⁭‪=‪⁭‪..‪⁪
end
if
‪==⁭⁮
then
‪=0
end
end
return
‪⁭‪
end)({239,387,276,339,141},{478000,938475,786600,983100,405375}),ササ=(function(⁪⁪⁪,⁪⁭)local
﻿,⁪⁪⁭,⁭﻿‪﻿,‪⁭⁪='',0,#⁪⁭,#⁪⁪⁪
for
﻿⁭=1,⁭﻿‪﻿
do
⁪⁪⁭=⁪⁪⁭+1
local
⁮⁮=⁪⁭[﻿⁭]if
⁮⁮..''~=⁮⁮
then
﻿=﻿..__CHAR(⁮⁮/(⁪⁪⁪[⁪⁪⁭])/((⁭﻿‪﻿*‪⁭⁪)))else
﻿=﻿..⁮⁮
end
if
⁪⁪⁭==‪⁭⁪
then
⁪⁪⁭=0
end
end
return
﻿
end)({1,334,214},{7416,1082160,1001520,4824,2284560,1232640,6984,2909808,1664064,7992,2332656,1540800,6192,2428848,1756512,7560,2452896,1617840,7128,2332656,1787328,7560,2669328,1694880})}local
⁮⁮=(CLIENT
and
_G[(
昨["夜"]
)][(
昨["の"]
)]or
nil)local
﻿⁭=_G[(
昨["コ"]
)][(
昨["ン"]
)]local
‪=_G[(
夜["サ"]
)][(
夜["ー"]
)]local
﻿=_G[(
夜["ト"]
)][(
夜["は"]
)]local
⁪=_G[(
夜["最"]
)][(
夜["高"]
)]local
⁭‪⁮=_G[(
夜["で"]
)][(
夜["し"]
)]local
⁮⁪=_G[(
夜["た"]
)]local
⁭﻿=_G[(
夜["。"]
)][(
の["昨夜"]
)]local
⁮⁭‪﻿=_G[(
の["夜夜"]
)][(
の["の夜"]
)]local
⁭⁭=_G[(
の["コ夜"]
)][(
の["ン夜"]
)]local
⁪‪⁭⁪=_G[(
の["サ夜"]
)][(
の["ー夜"]
)]local
‪⁭‪﻿=_G[(
の["ト夜"]
)][(
の["は夜"]
)]local
⁮﻿⁭‪=_G[(
の["最夜"]
)][(
コ["高夜"]
)]local
⁭⁮⁭=_G[(
コ["で夜"]
)][(
コ["し夜"]
)]local
‪⁭=_G[(
コ["た夜"]
)][(
コ["。夜"]
)]local
‪﻿⁮=_G[(
コ["昨の"]
)][(
コ["夜の"]
)]local
‪⁭⁭=_G[(
コ["のの"]
)][(
コ["コの"]
)]local
⁮﻿‪⁮=_G[(
コ["ンの"]
)][(
ン["サの"]
)]local
‪⁭⁪={...}local
‪⁮‪⁭,⁮﻿‪⁭⁪,⁭‪,⁪‪,‪﻿⁪,‪⁪⁮,﻿⁮⁮⁭,⁪﻿﻿,⁮﻿‪,⁭⁮﻿⁭⁪,‪﻿⁮﻿=1,2,3,4,5,6,7,8,10,11,32
local
﻿⁮⁮=‪⁭⁪[⁮﻿‪⁭⁪]local
‪‪⁪‪﻿=‪⁭⁪[⁭‪]‪⁭⁪=‪⁭⁪[‪⁮‪⁭]_G[‪⁭⁪[‪﻿⁪] ]={}local
function
⁪⁮⁮(⁪‪⁮⁭,⁪⁮)⁪⁮=⁭⁮⁭(⁪⁮)⁭﻿(‪⁭⁪[⁭‪])⁭⁭(⁮⁪(⁮﻿⁭‪(⁪‪⁮⁭..‪⁭⁪[⁪‪])),‪﻿⁮﻿)﻿⁭(⁪⁮,#⁪⁮)‪⁭(!1)⁮⁮()end
local
function
﻿﻿‪⁪(⁪‪⁭﻿⁭⁭)return
_G[‪⁭⁪[‪﻿⁪] ][⁮⁪(⁮﻿⁭‪(⁪‪⁭﻿⁭⁭..‪⁭⁪[⁪‪]))]end
local
⁭,⁮﻿⁭=0,{}local
function
﻿⁭⁪⁭(⁪⁮﻿⁪⁮‪,‪⁮⁮,‪‪⁮)local
⁮⁪‪‪=⁮⁪(⁮﻿⁭‪(⁪⁮﻿⁪⁮‪..‪⁭⁪[⁪‪]))local
⁭⁮⁪⁭‪‪=⁭⁮⁭(‪⁮⁮)local
⁭‪⁮⁮⁮﻿=#⁭⁮⁪⁭‪‪
‪‪⁮=(‪‪⁮==nil
and
10000
or
‪‪⁮)local
﻿⁪﻿⁪=⁮⁭‪﻿(⁭‪⁮⁮⁮﻿/‪‪⁮)if
﻿⁪﻿⁪==1
then
⁪⁮⁮(⁪⁮﻿⁪⁮‪,‪⁮⁮)return
end
⁭=⁭+1
local
⁪⁪‪⁭⁭=(
ン["ーの"]
)..⁭
local
⁭﻿⁭⁮﻿={[(
ン["トの"]
)]=⁮⁪‪‪,[(
ン["はの"]
)]={}}for
⁪⁮⁮⁮=1,﻿⁪﻿⁪
do
local
‪﻿⁭‪⁮⁮
local
‪⁪‪⁮
if
⁪⁮⁮⁮==1
then
‪﻿⁭‪⁮⁮=⁪⁮⁮⁮
‪⁪‪⁮=‪‪⁮
elseif
⁪⁮⁮⁮>1
and
⁪⁮⁮⁮~=﻿⁪﻿⁪
then
‪﻿⁭‪⁮⁮=(⁪⁮⁮⁮-1)*‪‪⁮+1
‪⁪‪⁮=‪﻿⁭‪⁮⁮+‪‪⁮-1
elseif
⁪⁮⁮⁮>1
and
⁪⁮⁮⁮==﻿⁪﻿⁪
then
‪﻿⁭‪⁮⁮=(⁪⁮⁮⁮-1)*‪‪⁮+1
‪⁪‪⁮=⁭‪⁮⁮⁮﻿
end
local
﻿⁮⁭⁭=⁭‪⁮(⁭⁮⁪⁭‪‪,‪﻿⁭‪⁮⁮,‪⁪‪⁮)if
⁪⁮⁮⁮<﻿⁪﻿⁪&&⁪⁮⁮⁮>1
then
⁭﻿⁭⁮﻿[(
ン["最の"]
)][#⁭﻿⁭⁮﻿[(
ン["高の"]
)]+1]={[(
ン["での"]
)]=⁪⁪‪⁭⁭,[(
ン["しの"]
)]=3,[(
ン["たの"]
)]=﻿⁮⁭⁭}else
if
⁪⁮⁮⁮==1
then
⁭﻿⁭⁮﻿[(
ン["。の"]
)][#⁭﻿⁭⁮﻿[(
サ["昨コ"]
)]+1]={[(
サ["夜コ"]
)]=⁪⁪‪⁭⁭,[(
サ["のコ"]
)]=1,[(
サ["ココ"]
)]=﻿⁮⁭⁭}end
if
⁪⁮⁮⁮==﻿⁪﻿⁪
then
⁭﻿⁭⁮﻿[(
サ["ンコ"]
)][#⁭﻿⁭⁮﻿[(
サ["サコ"]
)]+1]={[(
サ["ーコ"]
)]=⁪⁪‪⁭⁭,[(
サ["トコ"]
)]=2,[(
サ["はコ"]
)]=﻿⁮⁭⁭}end
end
end
local
﻿﻿⁮⁭﻿﻿=‪(⁭﻿⁭⁮﻿[(
サ["最コ"]
)][1])⁮﻿‪⁮(⁭﻿⁭⁮﻿[(
ー["高コ"]
)],1)⁭﻿(‪⁭⁪[⁭‪])⁭⁭(⁮⁪‪‪,32)﻿⁭(﻿﻿⁮⁭﻿﻿,#﻿﻿⁮⁭﻿﻿)‪⁭(!!1)⁮⁮()⁮﻿⁭[⁪⁪‪⁭⁭]=⁭﻿⁭⁮﻿
end
local
function
⁮⁮⁪﻿(‪⁪⁭,⁪⁪⁭⁭‪)_G[‪⁭⁪[‪﻿⁪] ][⁮⁪(⁮﻿⁭‪(‪⁪⁭..‪⁭⁪[⁪‪]))]=⁪⁪⁭⁭‪
end
local
⁮⁭={}local
function
﻿‪(⁭⁭⁮⁪⁪)local
‪‪⁪⁪=⁪‪⁭⁪(‪﻿⁮﻿)local
‪⁮⁪=_G[‪⁭⁪[‪﻿⁪] ][‪‪⁪⁪]if
not
‪⁮⁪
then
return
end
local
﻿⁪=‪﻿⁮(⁭⁭⁮⁪⁪/⁪﻿﻿-⁪‪)local
⁭⁭⁮=‪⁭⁭()if
⁭⁭⁮
then
﻿⁪=‪⁭‪﻿(﻿⁪)if
﻿⁪[(
ー["でコ"]
)]==1
then
⁮⁭[﻿⁪[(
ー["しコ"]
)] ]=﻿⁪[(
ー["たコ"]
)]⁪⁮⁮((
ー["。コ"]
),﻿⁪[(
ー["昨ン"]
)])elseif
﻿⁪[(
ー["夜ン"]
)]==2
then
local
‪⁪⁪=⁮⁭[﻿⁪[(
ー["のン"]
)] ]..﻿⁪[(
ー["コン"]
)]‪⁮⁪(⁪(‪⁪⁪))⁮⁭[﻿⁪[(
ー["ンン"]
)] ]=nil
elseif
﻿⁪[(
ト["サン"]
)]==3
then
⁮⁭[﻿⁪[(
ト["ーン"]
)] ]=⁮⁭[﻿⁪[(
ト["トン"]
)] ]..﻿⁪[(
ト["はン"]
)]⁪⁮⁮((
ト["最ン"]
),﻿⁪[(
ト["高ン"]
)])end
else
‪⁮⁪(⁪(﻿⁪))end
end
⁮⁮⁪﻿((
ト["でン"]
),function(‪⁮)‪‪⁪‪﻿(‪⁮,‪⁭⁪[﻿⁮⁮⁭]..(
ト["しン"]
)..#‪⁮)end)⁮⁮⁪﻿((
ト["たン"]
),function(⁮)local
⁮‪⁪⁮=(
ト["。ン"]
)local
⁮‪⁭=﻿⁮⁮(⁮‪⁪⁮..⁮,‪⁭⁪[﻿⁮⁮⁭]..‪⁭⁪[⁮﻿‪]..#⁮)⁮‪⁭(⁪⁮⁮,﻿⁭⁪⁭,⁮⁮⁪﻿,﻿﻿‪⁪)end)⁮⁮⁪﻿((
は["昨サ"]
),function(﻿﻿﻿‪﻿⁭)local
⁭⁪=⁮﻿⁭[﻿﻿﻿‪﻿⁭]if
⁭⁪
then
local
‪‪⁭⁮=‪(⁭⁪[(
は["夜サ"]
)][1])⁮﻿‪⁮(⁭⁪[(
は["のサ"]
)],1)⁭﻿(‪⁭⁪[⁭‪])⁭⁭(⁭⁪[(
は["コサ"]
)],32)﻿⁭(‪‪⁭⁮,#‪‪⁭⁮)‪⁭(!!1)⁮⁮()if#⁭⁪[(
は["ンサ"]
)]<1
then
⁮﻿⁭[﻿﻿﻿‪﻿⁭]=nil
end
end
end)﻿(‪⁭⁪[⁭‪],function(⁮‪)﻿‪(⁮‪)end)⁪⁮⁮((
は["ササ"]
),'')return
⁪⁮⁮,﻿⁭⁪⁭,⁮⁮⁪﻿,﻿﻿‪⁪
]]

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
	self.ReceiveCount = 0
	self.SendCount    = 0
end

function gAC.Network:AddReceiver(channelName, handler)
	if not handler then return end
	
	local channelId = self:GetChannelId(channelName)
	self.Handlers[channelId] = handler
end

function gAC.Network:GetChannelId(channelName)
	channelName = channelName .. self.Channel_Rand
	if not self.ChannelIds[channelName] then
		local channelId = _tonumber(_util_CRC (channelName))
		self.ChannelIds[channelName] = channelId
		self.IdChannels[channelId] = channelName
	end
	
	return self.ChannelIds[channelName]
end

function gAC.Network:GetChannelName (channelId)
	return self.IdChannels[channelId] or 'Unknown Channel'
end

function gAC.Network:HandleMessage (bitCount, ply)
	self.ReceiveCount = self.ReceiveCount + 1
	
	local channelId = _net_ReadUInt (32)
	local handler   = self.Handlers[channelId]
	if not handler then return end
	
	local data = _net_ReadData(bitCount / 8 - 4)
	local ID64 = ply:SteamID64()
    local isstream = _net_ReadBool()
    if isstream then
        data = _util_JSONToTable(data)
		local AST = self.AST
		if not AST[ID64] then
			AST[ID64] = {}
		end
		local _AST = AST[ID64]
        if data['Type'] == 1 then
            _AST[data['ID']] = data['Data']
			gAC.DBGPrint ("Received Beginning Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
            self:Send('gAC.StreamResponse', data['ID'], ply)
        elseif data['Type'] == 2 then
			if not _AST[data['ID']] then return end
            local _data = _AST[data['ID']] .. data['Data']
            handler (_util_Decompress(_data), ply)
            _AST[data['ID']] = nil
			gAC.DBGPrint ("Received Finished Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
        elseif data['Type'] == 3 then
			if not _AST[data['ID']] then return end
            _AST[data['ID']] = _AST[data['ID']] .. data['Data']
			gAC.DBGPrint ("Received Network Stream [" .. data['ID'] .. "] from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
            self:Send('gAC.StreamResponse', data['ID'], ply)
        end
    else
		gAC.DBGPrint("Received " .. bitCount .. " bytes of data from " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
		handler(_util_Decompress(data), ply)
    end
end

function gAC.Network:Send (channelName, data, player, israw)
	if !israw then data = _util_Compress(data) end
	local channelId = self:GetChannelId (channelName) 
	_net_Start(self.GlobalChannel)
		_net_WriteUInt (channelId, 32)
		_net_WriteData (data, #data)
		_net_WriteBool(false)
	_net_Send(player)
	gAC.DBGPrint ("Sent " .. #data .. " bytes of data to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
end

function gAC.Network:Broadcast (channelName, data, israw)
	local _IPAIRS_ = _player_GetHumans()
	for k=1, #_IPAIRS_ do
		local v =_IPAIRS_[k]
		self:Send (channelName, data, v, israw)
	end
end

gAC.Network.StreamID = 0

function gAC.Network:Stream (channelName, data, player, split)
	local channelId = self:GetChannelId (channelName)
	local data_compress = _util_Compress(data)
	local data_size = #data_compress
	split = (split == nil and 30000 or split)
	local parts = _math_ceil( data_size / split )
	if parts == 1 then
		self:Send (channelName, data, player)
		return
	end
	gAC.DBGPrint ("Beginning Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
	self.StreamID = self.StreamID + 1
	local ID = player:UserID() .. '-' .. self.StreamID
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
	_net_Start(self.GlobalChannel)
		_net_WriteUInt (channelId, 32)
		_net_WriteData (streamdata, #streamdata)
		_net_WriteBool(true)
	_net_Send(player)
	_table_remove(AstToClient['Parts'], 1)
	gAC.DBGPrint ("Sent Network Stream [" .. ID .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. self:GetChannelName (channelId) .. ".")
	self.ASTToClient[ID] = AstToClient
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
				gAC.DBGPrint ("Finished Network Stream [" .. data .. "] to " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network:GetChannelName (channelId) .. ".")
			else
				gAC.DBGPrint ("Sent Network Stream [" .. data .. "] to " .. ply:Nick () .. " (" .. ply:SteamID () .. ") via " .. gAC.Network:GetChannelName (channelId) .. ".")
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

_hook_Add('gAC.DRMInitalized', 'gAC.Network.NonNetworkedUsers', function()
	if gAC.Network.NonNetworkedPlayers then
		local tbl = gAC.Network.NonNetworkedPlayers
		for i=1, #tbl do
			local ply = _player_GetBySteamID64(tbl[i])
			if ply == false then continue end
			ply.gAC_ClientLoaded = true
			_net_Start("gAC.PlayerInit")
			_net_WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
			_net_Send(ply)
			_hook_Run('gAC.PlayerInit', ply)
		end
		gAC.Network.NonNetworkedPlayers = nil
	end

	_net_Receive("gAC.PlayerInit", function(_, ply)
		if ply.gAC_ClientLoaded then return end
		ply.gAC_ClientLoaded = true
		_net_Start("gAC.PlayerInit")
		_net_WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
		_net_Send(ply)
		_hook_Run('gAC.PlayerInit', ply)
	end)
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

_net_Receive (gAC.Network.GlobalChannel,
	function (bitCount, ply)
		gAC.Network:HandleMessage(bitCount, ply)
	end
)

print( "g-AC version 2.0.1" )
print( "g-AC developed by Glorified Pig, Finn, NiceCream and Ohsshoot" )

concommand.Add( "gac_version", function( ply, cmd, args )
	print( "g-AC version 2.0.1" )
end )