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
				encode[#encode + 1] = bxor(_string_byte(data:sub(i, i)), key[key_dir] % 255, (data_len * key_len) % 255)
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
			decode = decode .. __CHAR( __XOR(v, key[key_dir] % 255, (data_len * key_len) % 255) )
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
gAC.Encoder.Decoder_Func = [[function(if⁪⁪‪﻿)local
while⁪⁪‪=__EXTK
local
﻿,‪⁪⁭local,⁮﻿⁪﻿in,do⁮⁭='',0,#if⁪⁪‪﻿,#while⁪⁪‪
for
for⁭=1,⁮﻿⁪﻿in
do
‪⁪⁭local=‪⁪⁭local+1
local
and⁭⁪⁭=if⁪⁪‪﻿[for⁭]if
and⁭⁪⁭..''~=and⁭⁪⁭
then
﻿=﻿..__CHAR(__XOR(and⁭⁪⁭,while⁪⁪‪[‪⁪⁭local]%255,(⁮﻿⁪﻿in*do⁮⁭)%255))else
﻿=﻿..and⁭⁪⁭
end
if
‪⁪⁭local==do⁮⁭
then
‪⁪⁭local=0
end
end
return
﻿
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
__CHAR=function(⁪⁭﻿)local
⁪‪⁮={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
﻿=⁪‪⁮[⁪⁭﻿]if
not
﻿
then
﻿=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](⁪⁭﻿)end
return
﻿
end
__FLOOR=function(﻿⁭⁪)return
﻿⁭⁪-(﻿⁭⁪%1)end
__XOR=function(...)local
⁮⁪⁪,⁪⁪⁭=0,{...}for
⁪‪=0,31
do
local
⁪‪﻿=0
for
⁭﻿⁪⁮=1,#⁪⁪⁭
do
⁪‪﻿=⁪‪﻿+(⁪⁪⁭[⁭﻿⁪⁮]*.5)end
if
⁪‪﻿~=__FLOOR(⁪‪﻿)then
⁮⁪⁪=⁮⁪⁪+2^⁪‪
end
for
‪‪=1,#⁪⁪⁭
do
⁪⁪⁭[‪‪]=__FLOOR(⁪⁪⁭[‪‪]*.5)end
end
return
⁮⁪⁪
end
local
⁭⁮⁭=(CLIENT
and
_G[(function(‪‪‪⁭,﻿‪‪)local
﻿⁪﻿‪,⁭‪‪⁮,⁪,⁭⁪⁭='',0,#﻿‪‪,#‪‪‪⁭
for
﻿﻿=1,⁪
do
⁭‪‪⁮=⁭‪‪⁮+1
local
‪⁪﻿=﻿‪‪[﻿﻿]if
‪⁪﻿..''~=‪⁪﻿
then
﻿⁪﻿‪=﻿⁪﻿‪..__CHAR(__XOR(‪⁪﻿,‪‪‪⁭[⁭‪‪⁮]%(62+164+12+17),(⁪*⁭⁪⁭)%(211+147+159-339+88-12+1)))else
﻿⁪﻿‪=﻿⁪﻿‪..‪⁪﻿
end
if
⁭‪‪⁮==⁭⁪⁭
then
⁭‪‪⁮=0
end
end
return
﻿⁪﻿‪
end)({(454+1181-1030),(-20+52+60-148+70+138+166-1),(102+181+327-274-1)},{(-27+28+16+29-10+37-17),(52-24+38+16),(30+15+0)})][(function(﻿⁭,﻿⁪)local
⁮﻿﻿‪,⁪⁭,⁭﻿⁪⁮,⁪‪='',0,#﻿⁪,#﻿⁭
for
‪=1,⁭﻿⁪⁮
do
⁪⁭=⁪⁭+1
local
﻿⁮⁪=﻿⁪[‪]if
﻿⁮⁪..''~=﻿⁮⁪
then
⁮﻿﻿‪=⁮﻿﻿‪..__CHAR(__XOR(﻿⁮⁪,﻿⁭[⁪⁭]%(-256+511),(⁭﻿⁪⁮*⁪‪)%(143+112)))else
⁮﻿﻿‪=⁮﻿﻿‪..﻿⁮⁪
end
if
⁪⁭==⁪‪
then
⁪⁭=0
end
end
return
⁮﻿﻿‪
end)({(54+221-70+151+88),(-45+198+83),(751+498-819-4),(-441+592+243+102+18),(88+302+492-330+248-494),(-26+9+9+19+38+44+32),(-128+402+633-560+337-199),(123+82+50-128+119-22-5-4-1),(97+107+63)},{(-244+80-31+164+162-1),(118-597+840-687+555),(72+97),(3+5-3+3+2+4-2),(-42+64-75-6+70),(-32+124+34),(-35-59+83+156+72),(367-388-602+663+135+48),(-7+45-29+53-3-51+10),(-449+297-128+568+358-533+54),(121-215+323),(-5+41+76+75+90-47-50+1)})]or
nil)local
⁭=_G[(function(﻿,﻿⁭﻿⁮)local
⁮,⁭⁪⁭,‪‪﻿,⁮⁮‪='',0,#﻿⁭﻿⁮,#﻿
for
⁪=1,‪‪﻿
do
⁭⁪⁭=⁭⁪⁭+1
local
⁪⁪=﻿⁭﻿⁮[⁪]if
⁪⁪..''~=⁪⁪
then
⁮=⁮..__CHAR(__XOR(⁪⁪,﻿[⁭⁪⁭]%(-77+69+140+101+20+2),(‪‪﻿*⁮⁮‪)%(-1105+1360)))else
⁮=⁮..⁪⁪
end
if
⁭⁪⁭==⁮⁮‪
then
⁭⁪⁭=0
end
end
return
⁮
end)({(29-338+851),(-412+4+489+84),(137+28+138+73+1)},{(18+30+23),(-119+320),(4+3)})][(function(⁭⁮,﻿)local
⁮﻿⁮,⁮⁪⁭,⁪,⁮='',0,#﻿,#⁭⁮
for
‪=1,⁪
do
⁮⁪⁭=⁮⁪⁭+1
local
⁭=﻿[‪]if
⁭..''~=⁭
then
⁮﻿⁮=⁮﻿⁮..__CHAR(__XOR(⁭,⁭⁮[⁮⁪⁭]%(-246-297+306+182+226+323+121-361+1),(⁪*⁮)%(78-25+199+3)))else
⁮﻿⁮=⁮﻿⁮..⁭
end
if
⁮⁪⁭==⁮
then
⁮⁪⁭=0
end
end
return
⁮﻿⁮
end)({(5+270-289+193+228),(-130+121+71+141-16+17),(-204-90+156+71+207+8),(110-162+635+1),(92-107+29+69+38-43+66+109),(140+29-19),(-332-1071+6464+4421+12034-6041-2828-12213-1)},{(-661+754+294-147),(-357+183+332-30+1),(122+72),1,(104+63),(29+21+16+50+5+36+28+53-1),(-1437+186+402-413+1124+590-5-211),(95+100+30-15+1),(-2+53+19+17-39+38+66-7+1)})]local
⁪=_G[(function(⁪⁮⁪⁭,‪﻿‪)local
‪,‪‪⁪﻿,‪⁮⁭,﻿‪⁮⁮='',0,#‪﻿‪,#⁪⁮⁪⁭
for
⁮‪⁭=1,‪⁮⁭
do
‪‪⁪﻿=‪‪⁪﻿+1
local
﻿﻿‪⁪=‪﻿‪[⁮‪⁭]if
﻿﻿‪⁪..''~=﻿﻿‪⁪
then
‪=‪..__CHAR(__XOR(﻿﻿‪⁪,⁪⁮⁪⁭[‪‪⁪﻿]%(109+40-30+64+63-64+73),(‪⁮⁭*﻿‪⁮⁮)%(5730+8845+5451-14695+13632+153-18861)))else
‪=‪..﻿﻿‪⁪
end
if
‪‪⁪﻿==﻿‪⁮⁮
then
‪‪⁪﻿=0
end
end
return
‪
end)({(-312+280-23-10+157+67-2),(64+30+44+38-15+42+1),(59-84+229+93-80+1),(29+8+31-3+1-13)},{(48+77+76+47),(11+94-39+102),(47+116),(-6+13+14+18+34)})][(function(⁮⁪‪﻿,﻿﻿)local
⁮,⁪,‪,⁪⁮⁭='',0,#﻿﻿,#⁮⁪‪﻿
for
‪⁮⁭=1,‪
do
⁪=⁪+1
local
⁭⁮⁭⁮=﻿﻿[‪⁮⁭]if
⁭⁮⁭⁮..''~=⁭⁮⁭⁮
then
⁮=⁮..__CHAR(__XOR(⁭⁮⁭⁮,⁮⁪‪﻿[⁪]%(77+18+2+154+4),(‪*⁪⁮⁭)%(39+22+54+24+27+88+1)))else
⁮=⁮..⁭⁮⁭⁮
end
if
⁪==⁪⁮⁭
then
⁪=0
end
end
return
⁮
end)({(26+50-36+68+79-1),(24+138+208-209),(-33-66+53+170+111+1),(0+397-397+109+124-1),(627-295)},{(80+89-102+41-44+100+33+19+1),(779+247+700-649-768-950+405+481+2),(-525+710),(50+73-7+70-7+0),(-5+15+9+12),(795+1366+1225-1352-818-255-745+1),(-172+204-164+288-55+235-87),(78+65-51-27+67+12+1),(2758-2618),(80-67-8+13-19+54),(381-141-233+383-195)})]local
⁮⁮⁮=_G[(function(⁪⁮⁭,﻿)local
⁮‪,⁮⁭⁮,⁮,‪‪='',0,#﻿,#⁪⁮⁭
for
‪=1,⁮
do
⁮⁭⁮=⁮⁭⁮+1
local
‪‪﻿﻿=﻿[‪]if
‪‪﻿﻿..''~=‪‪﻿﻿
then
⁮‪=⁮‪..__CHAR(__XOR(‪‪﻿﻿,⁪⁮⁭[⁮⁭⁮]%(581-326),(⁮*‪‪)%(217-156+193+1)))else
⁮‪=⁮‪..‪‪﻿﻿
end
if
⁮⁭⁮==‪‪
then
⁮⁭⁮=0
end
end
return
⁮‪
end)({(335-114+303),(73+99-62+1),(167-113+125+1)},{(-47+40+52+60),3,(70+107+53+196-204-21)})][(function(⁭⁭,‪⁭⁭⁭)local
﻿﻿,⁮﻿,‪⁮⁪,⁪⁪='',0,#‪⁭⁭⁭,#⁭⁭
for
﻿﻿⁪=1,‪⁮⁪
do
⁮﻿=⁮﻿+1
local
⁮⁭‪⁮=‪⁭⁭⁭[﻿﻿⁪]if
⁮⁭‪⁮..''~=⁮⁭‪⁮
then
﻿﻿=﻿﻿..__CHAR(__XOR(⁮⁭‪⁮,⁭⁭[⁮﻿]%(-532-368+783+372),(‪⁮⁪*⁪⁪)%(32+141+82)))else
﻿﻿=﻿﻿..⁮⁭‪⁮
end
if
⁮﻿==⁪⁪
then
⁮﻿=0
end
end
return
﻿﻿
end)({(77-4-87+71+5+48),(90+165-206-33+24+235),(-162+149+243+230-7-291+224+1),(188-85),(99+101),(170-343-306+450-160+356-11+350-1),(260-52-194+191+289)},{(-4+19-2),(-14+6+41+32-1),(111-13+142-26),(31-4+25-1),(29+64+51),(-13+89+86+35-8),(-2362-852+3354-306+353)})]local
⁭⁮‪=_G[(function(⁪⁭⁮⁭,‪﻿⁮)local
⁮⁮,⁪﻿,‪﻿﻿⁭,‪⁭⁭⁪='',0,#‪﻿⁮,#⁪⁭⁮⁭
for
⁭⁪﻿⁮=1,‪﻿﻿⁭
do
⁪﻿=⁪﻿+1
local
⁮⁪=‪﻿⁮[⁭⁪﻿⁮]if
⁮⁪..''~=⁮⁪
then
⁮⁮=⁮⁮..__CHAR(__XOR(⁮⁪,⁪⁭⁮⁭[⁪﻿]%(10+96+26+135-12),(‪﻿﻿⁭*‪⁭⁭⁪)%(-49-176+147+142+172+106-74-12-1)))else
⁮⁮=⁮⁮..⁮⁪
end
if
⁪﻿==‪⁭⁭⁪
then
⁪﻿=0
end
end
return
⁮⁮
end)({(-153+261+127-113),(38-101+134+136-67+23-13+46+2),(-92+47+151+58+108)},{3,(2+17+131+151-57+60-114),(-15+9+33+68-23+44),(-62+16-61+42-14+54+52-1)})][(function(‪⁮⁪⁮,⁮)local
⁪,﻿‪‪,⁮‪,‪‪‪⁮='',0,#⁮,#‪⁮⁪⁮
for
⁮⁪﻿⁮=1,⁮‪
do
﻿‪‪=﻿‪‪+1
local
﻿﻿⁮⁭=⁮[⁮⁪﻿⁮]if
﻿﻿⁮⁭..''~=﻿﻿⁮⁭
then
⁪=⁪..__CHAR(__XOR(﻿﻿⁮⁭,‪⁮⁪⁮[﻿‪‪]%(127+175-197+229-222+144-1),(⁮‪*‪‪‪⁮)%(95+160)))else
⁪=⁪..﻿﻿⁮⁭
end
if
﻿‪‪==‪‪‪⁮
then
﻿‪‪=0
end
end
return
⁪
end)({(27-10+13+9+40+1),(51-33+58+73),(131+113+152+16+71+23-82-102),(-1925+1732-2276+2970-1),(-926-658+1251+623),(-137-204-246+283+18+266+157-1),(262+183-69-113-228+254),(177+114-46+147)},{(93+30-87-42+107-68+58-22-1),(3459+616-2743-1895+1585-861-1),(54+13+45),(1570+3277+1977-5581+5908-4254-2694-1),(-458+363-118+69+173+1),(122+110-58-6),0,(-74+134+128),(9-72+121-91+148),(158+90+47+19-115-16-1)})]local
⁮⁮‪=_G[(function(⁪⁮﻿﻿,‪⁮﻿)local
⁪‪‪,⁪⁮⁭﻿,‪﻿﻿⁮,⁮⁭⁪⁮='',0,#‪⁮﻿,#⁪⁮﻿﻿
for
⁭⁪﻿‪=1,‪﻿﻿⁮
do
⁪⁮⁭﻿=⁪⁮⁭﻿+1
local
⁪﻿=‪⁮﻿[⁭⁪﻿‪]if
⁪﻿..''~=⁪﻿
then
⁪‪‪=⁪‪‪..__CHAR(__XOR(⁪﻿,⁪⁮﻿﻿[⁪⁮⁭﻿]%(146+119+57+105-155-134+117),(‪﻿﻿⁮*⁮⁭⁪⁮)%(201+92+265-263-229+180-24+34-1)))else
⁪‪‪=⁪‪‪..⁪﻿
end
if
⁪⁮⁭﻿==⁮⁭⁪⁮
then
⁪⁮⁭﻿=0
end
end
return
⁪‪‪
end)({(-490+783+26-1),(11+13+15+73+25+73),(97+141+21)},{(-14+7+71+20+44-34),(-61-343+238+332+14),(-58+11-17+73+73+18),(-90-93+201+50),(27-35-838+1020),(317+1901-1431+1667-1315+474-1483-17)})][(function(‪‪⁪,⁭⁮)local
⁭,‪‪,‪⁭,⁪⁭﻿='',0,#⁭⁮,#‪‪⁪
for
⁭‪=1,‪⁭
do
‪‪=‪‪+1
local
﻿⁭﻿‪=⁭⁮[⁭‪]if
﻿⁭﻿‪..''~=﻿⁭﻿‪
then
⁭=⁭..__CHAR(__XOR(﻿⁭﻿‪,‪‪⁪[‪‪]%(219+126-90),(‪⁭*⁪⁭﻿)%(811-838+19-787+408+643-1)))else
⁭=⁭..﻿⁭﻿‪
end
if
‪‪==⁪⁭﻿
then
‪‪=0
end
end
return
⁭
end)({(237+110+270-189+71-109+217-1),(-299+464),(-135+159-138+172+158+10+28+137)},{(0+12+14+4-6+2),(30-7+38+6+58+54+38),(58+54+17+17+81)})]local
⁪⁭‪=_G[(function(⁪,‪⁭)local
⁭,⁭⁮‪,⁪﻿,‪‪⁭='',0,#‪⁭,#⁪
for
⁮⁭‪=1,⁪﻿
do
⁭⁮‪=⁭⁮‪+1
local
﻿‪﻿⁭=‪⁭[⁮⁭‪]if
﻿‪﻿⁭..''~=﻿‪﻿⁭
then
⁭=⁭..__CHAR(__XOR(﻿‪﻿⁭,⁪[⁭⁮‪]%(78+104+63-14-35-108+13+153+1),(⁪﻿*‪‪⁭)%(-544+368+431)))else
⁭=⁭..﻿‪﻿⁭
end
if
⁭⁮‪==‪‪⁭
then
⁭⁮‪=0
end
end
return
⁭
end)({0,(79+113-117+82-146+28+0+144),(91-35+14+102-31),(391+49),(23+27+58+86+46-12+83-89-1),(31+34+12+37+30)},{(2-25+16+23+23+1+22+7-1),(-62+221-160-51+107+177),(-1036+302-678+1122+501),(132+57-248+311),(87+23+74-2-39-15),(58-80+51+2+59+48+55+1),(13+23+10+29-23+26+8-1),(-212+59+193-38+244-1)})]local
⁪﻿=_G[(function(⁪﻿⁮,‪⁪‪)local
⁭,⁮⁪⁮,‪‪‪,﻿='',0,#‪⁪‪,#⁪﻿⁮
for
⁭⁪⁪=1,‪‪‪
do
⁮⁪⁮=⁮⁪⁮+1
local
‪=‪⁪‪[⁭⁪⁪]if
‪..''~=‪
then
⁭=⁭..__CHAR(__XOR(‪,⁪﻿⁮[⁮⁪⁮]%(1096-25-844+28),(‪‪‪*﻿)%(96+33+172-142-32+128)))else
⁭=⁭..‪
end
if
⁮⁪⁮==﻿
then
⁮⁪⁮=0
end
end
return
⁭
end)({(448+497+40+166+597-624-781),(-113+475),(277+196)},{(24+11+9+19),(7+1+3+1+0-5),(-20+187)})][(function(﻿,⁭)local
‪﻿⁪,﻿⁮,‪﻿⁮,﻿⁭⁪='',0,#⁭,#﻿
for
﻿‪﻿=1,‪﻿⁮
do
﻿⁮=﻿⁮+1
local
⁭⁭⁪⁪=⁭[﻿‪﻿]if
⁭⁭⁪⁪..''~=⁭⁭⁪⁪
then
‪﻿⁪=‪﻿⁪..__CHAR(__XOR(⁭⁭⁪⁪,﻿[﻿⁮]%(-64+69+83-64+81+105+45),(‪﻿⁮*﻿⁭⁪)%(-498-481+648-120+615+90+1)))else
‪﻿⁪=‪﻿⁪..⁭⁭⁪⁪
end
if
﻿⁮==﻿⁭⁪
then
﻿⁮=0
end
end
return
‪﻿⁪
end)({(73+6-38+108+12-1),(-517+237+173-117+478+1),(74+220-226-129+336),(-1096+58-352-483+955+776-594+1078+2),(-17065-44613+46063-90046+58363+47590+1)},{(383-313+44+185-66+1),(37+225-11-330+213-25),(-344-13-438+425+218+260),(61-53+42),(2+81-8)})]local
⁪‪=_G[(function(‪⁭⁭,‪⁮)local
⁮⁪,‪‪‪,⁮⁪⁮,﻿⁪⁪='',0,#‪⁮,#‪⁭⁭
for
⁭﻿=1,⁮⁪⁮
do
‪‪‪=‪‪‪+1
local
‪⁪﻿‪=‪⁮[⁭﻿]if
‪⁪﻿‪..''~=‪⁪﻿‪
then
⁮⁪=⁮⁪..__CHAR(__XOR(‪⁪﻿‪,‪⁭⁭[‪‪‪]%(273-1646-322+1950),(⁮⁪⁮*﻿⁪⁪)%(2-155-188-209+159+95+295+257-1)))else
⁮⁪=⁮⁪..‪⁪﻿‪
end
if
‪‪‪==﻿⁪⁪
then
‪‪‪=0
end
end
return
⁮⁪
end)({(211-43),(24+44+14-14+13),(18+23-30+35+41+1+33),(32+28+18+37+21+40+18+35+1)},{(25+136+53-1),(21-7-32-1+6+32+13),(33-28-7+21-14-9+32+1),(-109-1282+1549)})][(function(⁮,⁭‪)local
﻿⁭⁪⁭,⁭‪⁮⁭,⁪‪﻿⁪,﻿='',0,#⁭‪,#⁮
for
‪﻿﻿=1,⁪‪﻿⁪
do
⁭‪⁮⁭=⁭‪⁮⁭+1
local
﻿⁪⁮‪=⁭‪[‪﻿﻿]if
﻿⁪⁮‪..''~=﻿⁪⁮‪
then
﻿⁭⁪⁭=﻿⁭⁪⁭..__CHAR(__XOR(﻿⁪⁮‪,⁮[⁭‪⁮⁭]%(175+155+13+32+15+3-83-56+1),(⁪‪﻿⁪*﻿)%(5+122+129+53+96-104-46)))else
﻿⁭⁪⁭=﻿⁭⁪⁭..﻿⁪⁮‪
end
if
⁭‪⁮⁭==﻿
then
⁭‪⁮⁭=0
end
end
return
﻿⁭⁪⁭
end)({(1179-934),(1833-2142+931-70),(0+9+70+48)},{(-11+85-73+13-104+135+108+1),(-107+107+67),(-3+21-19+14+1-20+32),(153+127-51-100-25+45)})]local
‪﻿=_G[(function(⁪,⁮)local
⁪‪⁮,﻿﻿⁪,⁪⁭,⁭⁪⁮='',0,#⁮,#⁪
for
﻿⁭⁮⁪=1,⁪⁭
do
﻿﻿⁪=﻿﻿⁪+1
local
⁭=⁮[﻿⁭⁮⁪]if
⁭..''~=⁭
then
⁪‪⁮=⁪‪⁮..__CHAR(__XOR(⁭,⁪[﻿﻿⁪]%(294-205+166),(⁪⁭*⁭⁪⁮)%(119+136)))else
⁪‪⁮=⁪‪⁮..⁭
end
if
﻿﻿⁪==⁭⁪⁮
then
﻿﻿⁪=0
end
end
return
⁪‪⁮
end)({(160+208),(1702+625-2004),(-138-4443+5052)},{(11+1+0-7-19-7+22+21),(43-63+14+47-1),(20+12-31+34+84+46)})][(function(⁮,⁭﻿)local
﻿,⁮﻿⁮,⁭⁭﻿,‪⁭='',0,#⁭﻿,#⁮
for
⁪﻿⁭=1,⁭⁭﻿
do
⁮﻿⁮=⁮﻿⁮+1
local
‪‪﻿﻿=⁭﻿[⁪﻿⁭]if
‪‪﻿﻿..''~=‪‪﻿﻿
then
﻿=﻿..__CHAR(__XOR(‪‪﻿﻿,⁮[⁮﻿⁮]%(162+93),(⁭⁭﻿*‪⁭)%(-8-21-79+41+46+129+68+79)))else
﻿=﻿..‪‪﻿﻿
end
if
⁮﻿⁮==‪⁭
then
⁮﻿⁮=0
end
end
return
﻿
end)({(177+36+194-221-24-32-52+204+1),(7+4+20+28-2+31+17+6-1),(171+203+136)},{(701-693+553-673-503+207+488),(4+5-2),(-48+13+36+62+51),(32-74+78+79),(7+9),(8+44+58-34+2),(7+9+38+28-27+33+26-36),(34+35-74+31+1),(277+279-241-204)})]local
⁭﻿⁭=_G[(function(⁪﻿,⁮‪⁭)local
⁮﻿﻿⁮,⁮,⁮﻿﻿⁪,⁪⁮⁪='',0,#⁮‪⁭,#⁪﻿
for
⁭‪=1,⁮﻿﻿⁪
do
⁮=⁮+1
local
⁭‪⁮﻿=⁮‪⁭[⁭‪]if
⁭‪⁮﻿..''~=⁭‪⁮﻿
then
⁮﻿﻿⁮=⁮﻿﻿⁮..__CHAR(__XOR(⁭‪⁮﻿,⁪﻿[⁮]%(34+47+53+45-4+15+20+45),(⁮﻿﻿⁪*⁪⁮⁪)%(252+127-226-185+287)))else
⁮﻿﻿⁮=⁮﻿﻿⁮..⁭‪⁮﻿
end
if
⁮==⁪⁮⁪
then
⁮=0
end
end
return
⁮﻿﻿⁮
end)({(53+5+4-96+56+99+1),(-2719+3663-594),(206+278+1-139-271+76+188+1)},{(15+16+2-20-4+20),(-20+31+40),(-43+83)})][(function(﻿⁭‪⁮,﻿‪⁭)local
⁭,⁪,⁪﻿⁮﻿,⁮='',0,#﻿‪⁭,#﻿⁭‪⁮
for
‪=1,⁪﻿⁮﻿
do
⁪=⁪+1
local
‪‪⁮=﻿‪⁭[‪]if
‪‪⁮..''~=‪‪⁮
then
⁭=⁭..__CHAR(__XOR(‪‪⁮,﻿⁭‪⁮[⁪]%(55+159+192-248-318+415),(⁪﻿⁮﻿*⁮)%(-106+361)))else
⁭=⁭..‪‪⁮
end
if
⁪==⁮
then
⁪=0
end
end
return
⁭
end)({(8-94+80+174-43-73+154+81),(93+96),(107+184),(5+23+72+11+53-46-5),(-71-32-64+47+39+153+159-2),(-485+356+1737-1164),(-355+356+312+296)},{(6+78-10),(-8659-4625+1430+2702+8768-2202+2809+1),(-189-90+404),(19+43-22+59-52-3+1),(72-623+624+69-68+62),(1261-1057),(25+23+5),(17569-3584+4664-20972-10149-8004+20584)})]local
⁪⁮=_G[(function(⁮‪‪,⁭⁭⁪﻿)local
⁪,⁮‪,‪﻿‪,⁪⁭﻿⁪='',0,#⁭⁭⁪﻿,#⁮‪‪
for
⁮‪﻿=1,‪﻿‪
do
⁮‪=⁮‪+1
local
⁪⁪‪=⁭⁭⁪﻿[⁮‪﻿]if
⁪⁪‪..''~=⁪⁪‪
then
⁪=⁪..__CHAR(__XOR(⁪⁪‪,⁮‪‪[⁮‪]%(-5538+5793),(‪﻿‪*⁪⁭﻿⁪)%(2+220+33)))else
⁪=⁪..⁪⁪‪
end
if
⁮‪==⁪⁭﻿⁪
then
⁮‪=0
end
end
return
⁪
end)({(-36+327-157),(961-1364-302+2261-919-1323+896),(253-67)},{(90+84-22+89-51+27+38),(97+80+98-36-80-29-18+57+1),(102-92+12+73+128),(249-73-56-85+195)})][(function(‪⁮⁪⁮,‪)local
⁭,⁪﻿⁪,﻿,﻿﻿='',0,#‪,#‪⁮⁪⁮
for
‪⁪=1,﻿
do
⁪﻿⁪=⁪﻿⁪+1
local
⁮=‪[‪⁪]if
⁮..''~=⁮
then
⁭=⁭..__CHAR(__XOR(⁮,‪⁮⁪⁮[⁪﻿⁪]%(84-69+34+57+69+77+4-1),(﻿*﻿﻿)%(292-278+255-27-329+342)))else
⁭=⁭..⁮
end
if
⁪﻿⁪==﻿﻿
then
⁪﻿⁪=0
end
end
return
⁭
end)({(67+73-177+150+152+85-21+1),(359+27),(294-665+226-176+639),(2115-1632),(-346+528+194-494+515-1)},{(14+40),(21+110+100),(22+14+13+15-20+13+14),(122-47+71-258+179+90),(-589+827),(-3+22),(623+702-705-396),(13+32-55+56+41+19-1),(-20-38+68+56+32+80-1),(246-400+311-170-344+224+346+1),(6+11+5+3)})]local
⁭⁪⁮‪=_G[(function(‪⁪⁮,⁮)local
﻿﻿⁮,⁪﻿,﻿⁪,⁮⁭⁮⁮='',0,#⁮,#‪⁪⁮
for
⁮‪=1,﻿⁪
do
⁪﻿=⁪﻿+1
local
⁮⁪=⁮[⁮‪]if
⁮⁪..''~=⁮⁪
then
﻿﻿⁮=﻿﻿⁮..__CHAR(__XOR(⁮⁪,‪⁪⁮[⁪﻿]%(76+91-2-123+220+63+34-105+1),(﻿⁪*⁮⁭⁮⁮)%(416+319-480)))else
﻿﻿⁮=﻿﻿⁮..⁮⁪
end
if
⁪﻿==⁮⁭⁮⁮
then
⁪﻿=0
end
end
return
﻿﻿⁮
end)({(-370+8+432+440-441+223-198+187-1),(2855-2267),(-11060+11322),(320+0-490+184+418-268+386)},{(8+116),(83-1-40),(47+221-142),(122+28-152+29+57)})][(function(﻿‪,⁮⁮⁮)local
⁭,⁪⁮⁮,‪⁮⁪⁭,‪⁮⁮='',0,#⁮⁮⁮,#﻿‪
for
⁪⁪⁭﻿=1,‪⁮⁪⁭
do
⁪⁮⁮=⁪⁮⁮+1
local
⁭⁭=⁮⁮⁮[⁪⁪⁭﻿]if
⁭⁭..''~=⁭⁭
then
⁭=⁭..__CHAR(__XOR(⁭⁭,﻿‪[⁪⁮⁮]%(-80+17+318),(‪⁮⁪⁭*‪⁮⁮)%(-87-13+174+13+79+90-1)))else
⁭=⁭..⁭⁭
end
if
⁪⁮⁮==‪⁮⁮
then
⁪⁮⁮=0
end
end
return
⁭
end)({(-654+1086),(-19-136-153+147+204+60+65),(-319+453)},{(97+123-115+122+6+89+6-76-1),(57-192+37+127+199+137-122),(68+94+64-23+1)})]local
﻿﻿⁪⁭⁭=_G[(function(⁪,‪⁪⁪⁭)local
⁮﻿,⁪‪‪,⁪﻿⁮⁪,⁮='',0,#‪⁪⁪⁭,#⁪
for
﻿⁭﻿﻿=1,⁪﻿⁮⁪
do
⁪‪‪=⁪‪‪+1
local
‪=‪⁪⁪⁭[﻿⁭﻿﻿]if
‪..''~=‪
then
⁮﻿=⁮﻿..__CHAR(__XOR(‪,⁪[⁪‪‪]%(327-72),(⁪﻿⁮⁪*⁮)%(50+86+123-8+4)))else
⁮﻿=⁮﻿..‪
end
if
⁪‪‪==⁮
then
⁪‪‪=0
end
end
return
⁮﻿
end)({(-209+8+118+37+193+111-5+1),(170+127+40-71+1),(-327+89+347-92+185+172),(28+34+17)},{(459+222-570+262-274-226+282),(-685+789),(-40-85-94+55+93+85),(-9-34+86-39+42+117-113+1)})][(function(﻿⁪‪,⁪⁪⁭)local
⁪‪⁭﻿,‪⁪⁪,⁪,⁪﻿﻿='',0,#⁪⁪⁭,#﻿⁪‪
for
⁮⁮﻿﻿=1,⁪
do
‪⁪⁪=‪⁪⁪+1
local
⁮﻿=⁪⁪⁭[⁮⁮﻿﻿]if
⁮﻿..''~=⁮﻿
then
⁪‪⁭﻿=⁪‪⁭﻿..__CHAR(__XOR(⁮﻿,﻿⁪‪[‪⁪⁪]%(-115+66+7+127+170),(⁪*⁪﻿﻿)%(-52+158+281-133+1)))else
⁪‪⁭﻿=⁪‪⁭﻿..⁮﻿
end
if
‪⁪⁪==⁪﻿﻿
then
‪⁪⁪=0
end
end
return
⁪‪⁭﻿
end)({0,(919-815),(-165+124+548-363-279+363-87+67+1),(85-218-148+276+232),(26+14+56+42+50+35+26+5),(276+287),(876-22-727),(53+21+31+41+32)},{(9-11+5),(93-94-35+108+16-13-5+1),(-66+56-41+101+81+48+72+1),(82-1546-463+645+1266+554-327),(212+586-142-453+1),(-29-16+13-3+43-27+37-2),(20+9+25-15+1+38-40+37+1),(37+79+57-43-1)})]local
﻿⁭⁮‪=_G[(function(⁪﻿⁪,‪)local
⁭,⁮⁪‪﻿,⁮⁪,⁪='',0,#‪,#⁪﻿⁪
for
﻿⁮﻿=1,⁮⁪
do
⁮⁪‪﻿=⁮⁪‪﻿+1
local
⁪⁮⁪=‪[﻿⁮﻿]if
⁪⁮⁪..''~=⁪⁮⁪
then
⁭=⁭..__CHAR(__XOR(⁪⁮⁪,⁪﻿⁪[⁮⁪‪﻿]%(39+73+181+64-102),(⁮⁪*⁪)%(80+101+88-69+55)))else
⁭=⁭..⁪⁮⁪
end
if
⁮⁪‪﻿==⁪
then
⁮⁪‪﻿=0
end
end
return
⁭
end)({(168+96+1-137+49-75+174+4-1),0,(-44+121-39+116+124+70)},{(-85+82+124+97-92+1),(43-3-320+337+50+1),(0+7+14+11)})][(function(⁮,﻿⁮)local
⁪,⁭⁭⁭‪,﻿⁭,⁭‪='',0,#﻿⁮,#⁮
for
⁭﻿⁭=1,﻿⁭
do
⁭⁭⁭‪=⁭⁭⁭‪+1
local
﻿﻿﻿⁮=﻿⁮[⁭﻿⁭]if
﻿﻿﻿⁮..''~=﻿﻿﻿⁮
then
⁪=⁪..__CHAR(__XOR(﻿﻿﻿⁮,⁮[⁭⁭⁭‪]%(-64+319),(﻿⁭*⁭‪)%(51+51-12-18+91+92)))else
⁪=⁪..﻿﻿﻿⁮
end
if
⁭⁭⁭‪==⁭‪
then
⁭⁭⁭‪=0
end
end
return
⁪
end)({(318-246+566+880-1053-1),(49-31+45+31+61+58+40-1),(-526+370+423+479-22-439),(86-32+136+231-171-157+156+1),(744-503+801-866+57),(148-16+144-84+77+20+43-1)},{(18-136+114+181-1),(14+58+40+145+47-119-1),(249-487+215+251-164+1),(-18+144+58),(12+57-10+57+56+10-2+7-1),(29+27),(-22+173-15),(336-171),(-6+12+30-2+35-1)})]local
⁭﻿⁪⁪=_G[(function(⁭﻿⁪,⁮)local
⁭⁭‪⁪,⁪,‪⁮⁮⁮,⁪﻿='',0,#⁮,#⁭﻿⁪
for
‪‪⁪‪=1,‪⁮⁮⁮
do
⁪=⁪+1
local
‪﻿⁮=⁮[‪‪⁪‪]if
‪﻿⁮..''~=‪﻿⁮
then
⁭⁭‪⁪=⁭⁭‪⁪..__CHAR(__XOR(‪﻿⁮,⁭﻿⁪[⁪]%(-91+201-15-163-159+142+199+141),(‪⁮⁮⁮*⁪﻿)%(1080+52-877)))else
⁭⁭‪⁪=⁭⁭‪⁪..‪﻿⁮
end
if
⁪==⁪﻿
then
⁪=0
end
end
return
⁭⁭‪⁪
end)({(220-303-244+286+253+142+78-1),(-625+950+927+501-649-18-715+1),(82+103)},{(-85-127-172+337+326-64),(12-1+9-10+10-5+8+3-1),(49+101+38-28+117-74-13+6)})][(function(⁪⁮⁭⁮,‪)local
⁮⁮﻿,﻿⁮,﻿⁪﻿,⁪﻿⁪﻿='',0,#‪,#⁪⁮⁭⁮
for
﻿⁮‪=1,﻿⁪﻿
do
﻿⁮=﻿⁮+1
local
⁮‪⁪=‪[﻿⁮‪]if
⁮‪⁪..''~=⁮‪⁪
then
⁮⁮﻿=⁮⁮﻿..__CHAR(__XOR(⁮‪⁪,⁪⁮⁭⁮[﻿⁮]%(707-727+274+1),(﻿⁪﻿*⁪﻿⁪﻿)%(209+43+112-29+77+113-29-242+1)))else
⁮⁮﻿=⁮⁮﻿..⁮‪⁪
end
if
﻿⁮==⁪﻿⁪﻿
then
﻿⁮=0
end
end
return
⁮⁮﻿
end)({(135-49),(366-63-40+321-22+1),(4+119-45+27-7+77+27+2)},{(14-6+14-11+17-5+1+3+1),(22+0+12+25-27+18+23-1),(47+34-33+53+30+50),(19+23),(-410+353+163-1),(-138+319),(38+20),(-23+10-7+49+46+1)})]local
‪⁭=_G[(function(⁮⁮⁮⁭,⁮⁮‪⁮)local
⁮,⁮⁮‪‪,⁪‪﻿‪,﻿⁭='',0,#⁮⁮‪⁮,#⁮⁮⁮⁭
for
⁪⁪⁪=1,⁪‪﻿‪
do
⁮⁮‪‪=⁮⁮‪‪+1
local
‪‪=⁮⁮‪⁮[⁪⁪⁪]if
‪‪..''~=‪‪
then
⁮=⁮..__CHAR(__XOR(‪‪,⁮⁮⁮⁭[⁮⁮‪‪]%(32+72+72+14+41+23+1),(⁪‪﻿‪*﻿⁭)%(-135-226+271+251+102-409+401)))else
⁮=⁮..‪‪
end
if
⁮⁮‪‪==﻿⁭
then
⁮⁮‪‪=0
end
end
return
⁮
end)({(274+843-959-581+833),(29+25),(66+11+27-36+25+50+1)},{(-136+388),(81+18+60-69),(-327+252+156+157-1)})][(function(﻿⁪‪‪,⁪⁮)local
﻿⁪⁭⁭,‪,⁮⁭⁮⁪,‪⁮='',0,#⁪⁮,#﻿⁪‪‪
for
⁭⁪⁪⁪=1,⁮⁭⁮⁪
do
‪=‪+1
local
⁪=⁪⁮[⁭⁪⁪⁪]if
⁪..''~=⁪
then
﻿⁪⁭⁭=﻿⁪⁭⁭..__CHAR(__XOR(⁪,﻿⁪‪‪[‪]%(69+464-423+393-50-199+1),(⁮⁭⁮⁪*‪⁮)%(2+97+239+42+8+187-59-261)))else
﻿⁪⁭⁭=﻿⁪⁭⁭..⁪
end
if
‪==‪⁮
then
‪=0
end
end
return
﻿⁪⁭⁭
end)({(1819+2965+226-2915-2899+1701+1298-2019),(-78+175-69+67+330+223-152),(-54+397),(51+123+117-60+1),(108-42+46),(41+117)},{(394-184),(58+60-48+40+55-2+1),(4-20-1+4-9+13+18),(1510-353-969),2,(-2871+946+2313+1434-1629),(69-90+60-97+83+149-191+255+1),(-21+58+328-59+71+95-210-90+1)})]local
‪‪=_G[(function(⁪﻿‪,⁪⁪)local
⁪,‪⁭﻿,‪⁮,⁪⁭='',0,#⁪⁪,#⁪﻿‪
for
⁪⁪﻿=1,‪⁮
do
‪⁭﻿=‪⁭﻿+1
local
﻿=⁪⁪[⁪⁪﻿]if
﻿..''~=﻿
then
⁪=⁪..__CHAR(__XOR(﻿,⁪﻿‪[‪⁭﻿]%(-27+154+141-7-5-1),(‪⁮*⁪⁭)%(-296+551)))else
⁪=⁪..﻿
end
if
‪⁭﻿==⁪⁭
then
‪⁭﻿=0
end
end
return
⁪
end)({(60+934-611),0,(76+29+131+22+60-107+124-156+2),(-72+67+9+23+48+66-47+51+1)},{(203-14+253+179-195-203+1),(-34+158-73+66+155-40-115),(37+110+9+39),(998-22-808+827-760-1),(-118-458+833+1132-1148)})][(function(⁭⁮⁮⁮,⁭﻿)local
‪,⁮⁪,⁭⁪⁪,﻿⁭⁭='',0,#⁭﻿,#⁭⁮⁮⁮
for
﻿‪⁪﻿=1,⁭⁪⁪
do
⁮⁪=⁮⁪+1
local
‪﻿‪=⁭﻿[﻿‪⁪﻿]if
‪﻿‪..''~=‪﻿‪
then
‪=‪..__CHAR(__XOR(‪﻿‪,⁭⁮⁮⁮[⁮⁪]%(244-169+114+66),(⁭⁪⁪*﻿⁭⁭)%(303-48)))else
‪=‪..‪﻿‪
end
if
⁮⁪==﻿⁭⁭
then
⁮⁪=0
end
end
return
‪
end)({(85-3+13+121+173+88+185-99-1),(317+186-221+185+51-25-149+90+1),(1919-1497-1749+123+1481),(700-364-382+237+219),(-2198+2507+1520-1484),(128-41+110+5+129+1)},{(19+62-81-25-9+14+92+24+2),(2673-1989-244-195),(-65-140+155+203-58),(-342+529+22-1),(-7+11-3+3+6-2),(34+33+41-96)})]local
‪⁪⁪⁭={...}local
⁮‪,⁭⁭﻿,⁪⁮﻿,⁭‪⁪,﻿‪﻿,⁭⁪⁭⁭,⁪⁮⁭⁭,‪⁪﻿⁭⁭,⁮,⁪⁭﻿‪,⁮﻿‪=1,2,3,4,5,(-32+53-42+13+55-41),7,(1+3+2+0+2),(169-159),(-2-5+10+4+1+3-1+1),(21+24+6-22+11-8-1+1)local
⁪⁭⁮⁭=‪⁪⁪⁭[⁭⁭﻿]local
‪‪⁮=‪⁪⁪⁭[⁪⁮﻿]‪⁪⁪⁭=‪⁪⁪⁭[⁮‪]_G[‪⁪⁪⁭[﻿‪﻿] ]={}local
function
‪⁭﻿(‪⁪⁪,⁮‪⁪﻿⁪⁭)⁮‪⁪﻿⁪⁭=﻿﻿⁪⁭⁭(⁮‪⁪﻿⁪⁭)⁪﻿(‪⁪⁪⁭[⁪⁮﻿])‪﻿(⁪⁭‪(⁭⁪⁮‪(‪⁪⁪..‪⁪⁪⁭[⁭‪⁪])),⁮﻿‪)⁭(⁮‪⁪﻿⁪⁭,#⁮‪⁪﻿⁪⁭)﻿⁭⁮‪(!1)⁭⁮⁭()end
local
function
⁮⁪⁮(⁮‪⁮)return
_G[‪⁪⁪⁭[﻿‪﻿] ][⁪⁭‪(⁭⁪⁮‪(⁮‪⁮..‪⁪⁪⁭[⁭‪⁪]))]end
local
﻿⁭⁪‪⁮,‪⁭⁭=0,{}local
function
‪(⁮﻿⁭⁭⁭⁭,‪﻿﻿,‪⁮⁪‪⁮‪)local
⁭﻿‪⁮⁮=⁪⁭‪(⁭⁪⁮‪(⁮﻿⁭⁭⁭⁭..‪⁪⁪⁭[⁭‪⁪]))local
⁮﻿=﻿﻿⁪⁭⁭(‪﻿﻿)local
⁪⁮⁪=#⁮﻿
‪⁮⁪‪⁮‪=(‪⁮⁪‪⁮‪==nil
and(1821+2185+5994)or
‪⁮⁪‪⁮‪)local
⁭﻿⁪﻿=⁪‪(⁪⁮⁪/‪⁮⁪‪⁮‪)if
⁭﻿⁪﻿==1
then
‪⁭﻿(⁮﻿⁭⁭⁭⁭,‪﻿﻿)return
end
﻿⁭⁪‪⁮=﻿⁭⁪‪⁮+1
local
⁮⁮⁭⁪=(function(﻿‪⁪,﻿⁪⁪⁪)local
‪⁪⁭,⁭,﻿⁭‪,﻿='',0,#﻿⁪⁪⁪,#﻿‪⁪
for
‪﻿=1,﻿⁭‪
do
⁭=⁭+1
local
⁪⁪=﻿⁪⁪⁪[‪﻿]if
⁪⁪..''~=⁪⁪
then
‪⁪⁭=‪⁪⁭..__CHAR(__XOR(⁪⁪,﻿‪⁪[⁭]%(278-23),(﻿⁭‪*﻿)%(-131+367-192+211)))else
‪⁪⁭=‪⁪⁭..⁪⁪
end
if
⁭==﻿
then
⁭=0
end
end
return
‪⁪⁭
end)({(-3346-506-834+2758+2705+2681-2873),(191+471+244-847+107+228+659-698),(-205+85-34+451+292)},{(-8+72+53-66+56)})..﻿⁭⁪‪⁮
local
⁮⁭⁮={[(function(‪,⁪⁪⁮)local
⁮,⁪‪,⁭,⁮‪⁪⁭='',0,#⁪⁪⁮,#‪
for
⁮⁪=1,⁭
do
⁪‪=⁪‪+1
local
﻿‪⁪⁭=⁪⁪⁮[⁮⁪]if
﻿‪⁪⁭..''~=﻿‪⁪⁭
then
⁮=⁮..__CHAR(__XOR(﻿‪⁪⁭,‪[⁪‪]%(844-324-265),(⁭*⁮‪⁪⁭)%(-227+61+34+192-42+238-1)))else
⁮=⁮..﻿‪⁪⁭
end
if
⁪‪==⁮‪⁪⁭
then
⁪‪=0
end
end
return
⁮
end)({(-53+27+112+17-46+118+1),(-154-41-117-486+638-362+696),(510+280-459),(502-619+277),(148+77-55+118+60+144-85+58),(64+307-71+235-214-1)},{(44+25+25+42+50+11+21-1),(346-354-88+87+244+1),7,(84+170-24+0-3+1),(88+61+5+16-30+11-1),(-21+22+13),(79+58+154-11-34)})]=⁭﻿‪⁮⁮,[(function(⁪,﻿‪)local
‪﻿,﻿⁭⁪⁮,‪⁭,﻿='',0,#﻿‪,#⁪
for
⁭⁪=1,‪⁭
do
﻿⁭⁪⁮=﻿⁭⁪⁮+1
local
⁮‪⁪‪=﻿‪[⁭⁪]if
⁮‪⁪‪..''~=⁮‪⁪‪
then
‪﻿=‪﻿..__CHAR(__XOR(⁮‪⁪‪,⁪[﻿⁭⁪⁮]%(-5-197+231+227-1),(‪⁭*﻿)%(53+52+64+34-24-4-2+83-1)))else
‪﻿=‪﻿..⁮‪⁪‪
end
if
﻿⁭⁪⁮==﻿
then
﻿⁭⁪⁮=0
end
end
return
‪﻿
end)({(-6+218+205-80+80-170-58+9-1),(131+96+36+23-127-71+107-41),(288-280+364)},{(125+115+149-15-69-66-20-65),(143+101),(4-1+3+2),(49+68+7+7+60-1),(36-30+55+59+47+64-1)})]={}}for
‪⁮﻿⁭⁭⁪=1,⁭﻿⁪﻿
do
local
⁪⁭
local
⁭‪⁮
if
‪⁮﻿⁭⁭⁪==1
then
⁪⁭=‪⁮﻿⁭⁭⁪
⁭‪⁮=‪⁮⁪‪⁮‪
elseif
‪⁮﻿⁭⁭⁪>1
and
‪⁮﻿⁭⁭⁪~=⁭﻿⁪﻿
then
⁪⁭=(‪⁮﻿⁭⁭⁪-1)*‪⁮⁪‪⁮‪+1
⁭‪⁮=⁪⁭+‪⁮⁪‪⁮‪-1
elseif
‪⁮﻿⁭⁭⁪>1
and
‪⁮﻿⁭⁭⁪==⁭﻿⁪﻿
then
⁪⁭=(‪⁮﻿⁭⁭⁪-1)*‪⁮⁪‪⁮‪+1
⁭‪⁮=⁪⁮⁪
end
local
⁪⁪⁪⁮=⁮⁮‪(⁮﻿,⁪⁭,⁭‪⁮)if
‪⁮﻿⁭⁭⁪<⁭﻿⁪﻿&&‪⁮﻿⁭⁭⁪>1
then
⁮⁭⁮[(function(⁭,⁭⁭⁭⁮)local
⁭⁭⁮,⁮‪﻿,⁭‪⁮⁮,⁮='',0,#⁭⁭⁭⁮,#⁭
for
﻿⁮=1,⁭‪⁮⁮
do
⁮‪﻿=⁮‪﻿+1
local
‪⁮⁭=⁭⁭⁭⁮[﻿⁮]if
‪⁮⁭..''~=‪⁮⁭
then
⁭⁭⁮=⁭⁭⁮..__CHAR(__XOR(‪⁮⁭,⁭[⁮‪﻿]%(8+101+9+137),(⁭‪⁮⁮*⁮)%(-109-380+299+52+156+237)))else
⁭⁭⁮=⁭⁭⁮..‪⁮⁭
end
if
⁮‪﻿==⁮
then
⁮‪﻿=0
end
end
return
⁭⁭⁮
end)({(29+268+270+220-174-250+78-1),(192+85-131+170+1),(-114+74+104+43),(267+261-355+220+152-97-1),(38+35+74-53+19)},{(114+84+27-132+17+129+1),(21-2+19+13+19+10-11+1),0,(-194-280+367+243-197+100+134),(-280+427-120)})][#⁮⁭⁮[(function(‪⁪,⁪⁪)local
﻿‪,⁭,⁮,⁮⁭='',0,#⁪⁪,#‪⁪
for
⁭⁮⁪=1,⁮
do
⁭=⁭+1
local
‪⁮=⁪⁪[⁭⁮⁪]if
‪⁮..''~=‪⁮
then
﻿‪=﻿‪..__CHAR(__XOR(‪⁮,‪⁪[⁭]%(998+1413+1756-433-2869+2201-2812+1),(⁮*⁮⁭)%(41-27+52+30+79-20+100)))else
﻿‪=﻿‪..‪⁮
end
if
⁭==⁮⁭
then
⁭=0
end
end
return
﻿‪
end)({(22+0+12+44+46-29+26-1),(636-2805-40+2568-1),(107+121+86+178+48),(4+16+11+11-3+10-5+11+1)},{(-145-7+221+238-248+1),(14+4),(62-12+26-38+73+9),(220-1364-848+1316+764),(22+24+21-22-6-7-1)})]+1]={[(function(﻿﻿⁪,⁮)local
⁪⁪⁮,⁭⁮⁭⁭,⁮⁮‪‪,⁭⁪='',0,#⁮,#﻿﻿⁪
for
‪‪⁪⁮=1,⁮⁮‪‪
do
⁭⁮⁭⁭=⁭⁮⁭⁭+1
local
‪=⁮[‪‪⁪⁮]if
‪..''~=‪
then
⁪⁪⁮=⁪⁪⁮..__CHAR(__XOR(‪,﻿﻿⁪[⁭⁮⁭⁭]%(-105+420+100+34+3-367-92+262),(⁮⁮‪‪*⁭⁪)%(80+85+90)))else
⁪⁪⁮=⁪⁪⁮..‪
end
if
⁭⁮⁭⁭==⁭⁪
then
⁭⁮⁭⁭=0
end
end
return
⁪⁪⁮
end)({(-356+7+12+483+377-323+142+1),(118+94+185-138-48),(-479+375-474+367+469-64+518-410)},{(6+7+10),(-147-173+234+119+3+110-212+211)})]=⁮⁮⁭⁪,[(function(⁭‪⁭⁪,⁪)local
﻿,‪﻿,⁪⁪⁭,⁭‪﻿⁮='',0,#⁪,#⁭‪⁭⁪
for
﻿⁭﻿=1,⁪⁪⁭
do
‪﻿=‪﻿+1
local
⁮‪=⁪[﻿⁭﻿]if
⁮‪..''~=⁮‪
then
﻿=﻿..__CHAR(__XOR(⁮‪,⁭‪⁭⁪[‪﻿]%(22+80+153),(⁪⁪⁭*⁭‪﻿⁮)%(136+311-192)))else
﻿=﻿..⁮‪
end
if
‪﻿==⁭‪﻿⁮
then
‪﻿=0
end
end
return
﻿
end)({(-22+50+55-62+28),(230-31-64+171+133+149-69-121+1),(1157-1993+2541+1916-293-2037-1028+1),(2331+248-1240-1131)},{(-102+179-228+268),(230-583+452+605-137-57-261),(-72+61-43+84+34+41),(-21+24+22+63+10+47-32+53-1)})]=(-5+8),[(function(⁮⁮⁭,⁮⁪⁮‪)local
⁪,﻿,﻿﻿⁭⁮,⁭⁭⁭='',0,#⁮⁪⁮‪,#⁮⁮⁭
for
﻿‪=1,﻿﻿⁭⁮
do
﻿=﻿+1
local
⁪‪=⁮⁪⁮‪[﻿‪]if
⁪‪..''~=⁪‪
then
⁪=⁪..__CHAR(__XOR(⁪‪,⁮⁮⁭[﻿]%(-550+41-710+1475-1),(﻿﻿⁭⁮*⁭⁭⁭)%(208+156-163+53+1)))else
⁪=⁪..⁪‪
end
if
﻿==⁭⁭⁭
then
﻿=0
end
end
return
⁪
end)({(97+160),(241-144-120+34+266+49+164+1),(58+22)},{(-8-87+309-140),(222+163-215-86+77-226+193+1),(8+47-23-10+18),(85-64+121-31)})]=⁪⁪⁪⁮}else
if
‪⁮﻿⁭⁭⁪==1
then
⁮⁭⁮[(function(⁭⁭,‪)local
‪﻿‪,⁪⁪,﻿⁪⁮,⁭⁭⁮='',0,#‪,#⁭⁭
for
⁭﻿‪=1,﻿⁪⁮
do
⁪⁪=⁪⁪+1
local
⁭⁭﻿⁪=‪[⁭﻿‪]if
⁭⁭﻿⁪..''~=⁭⁭﻿⁪
then
‪﻿‪=‪﻿‪..__CHAR(__XOR(⁭⁭﻿⁪,⁭⁭[⁪⁪]%(60+55+53+36+46-11+17-1),(﻿⁪⁮*⁭⁭⁮)%(-124+103-137+116+142+28+121+6)))else
‪﻿‪=‪﻿‪..⁭⁭﻿⁪
end
if
⁪⁪==⁭⁭⁮
then
⁪⁪=0
end
end
return
‪﻿‪
end)({(-1031+3784-2815-437+945),(-87-15-507+943+154-71-81+1),(-2202+2383)},{(-637+333+332+289+542-585-51+1),(42-9-13+40),(-768+425+226+580-263),(347+234-208-167-319+300-71+79+1),(-380-64-421+568+343)})][#⁮⁭⁮[(function(﻿‪⁮﻿,‪)local
⁪⁮‪‪,‪⁭,⁭,﻿⁭﻿‪='',0,#‪,#﻿‪⁮﻿
for
﻿﻿‪=1,⁭
do
‪⁭=‪⁭+1
local
⁮‪=‪[﻿﻿‪]if
⁮‪..''~=⁮‪
then
⁪⁮‪‪=⁪⁮‪‪..__CHAR(__XOR(⁮‪,﻿‪⁮﻿[‪⁭]%(-53-146+231-136+291+68),(⁭*﻿⁭﻿‪)%(-170+92+79+67+188-1)))else
⁪⁮‪‪=⁪⁮‪‪..⁮‪
end
if
‪⁭==﻿⁭﻿‪
then
‪⁭=0
end
end
return
⁪⁮‪‪
end)({(325-6),(-1342+1718+364-235),(94+91+85),(-1698+1925),(15+45-13+58+22+35+70+1)},{(-4-19+8+6+3+16-1),(6+40+4-10+41+48+1),(-45+20+27-18+63-44+62+35),(95+235+378-263-303),(-16+107+96+25+33-114)})]+1]={[(function(⁭﻿﻿,⁪‪⁪)local
﻿⁮﻿⁪,‪﻿⁮,⁪,⁭⁪='',0,#⁪‪⁪,#⁭﻿﻿
for
⁭=1,⁪
do
‪﻿⁮=‪﻿⁮+1
local
﻿⁪=⁪‪⁪[⁭]if
﻿⁪..''~=﻿⁪
then
﻿⁮﻿⁪=﻿⁮﻿⁪..__CHAR(__XOR(﻿⁪,⁭﻿﻿[‪﻿⁮]%(55-156+158-197+105+290),(⁪*⁭⁪)%(-258-75+324-90+353+1)))else
﻿⁮﻿⁪=﻿⁮﻿⁪..﻿⁪
end
if
‪﻿⁮==⁭⁪
then
‪﻿⁮=0
end
end
return
﻿⁮﻿⁪
end)({(103+34-57+10-144+164),(323-318-150-10+7+89+230),(166-180+257-1)},{(-54-26+126+83-96),(74+62+97)})]=⁮⁮⁭⁪,[(function(﻿⁪,﻿⁭‪)local
‪⁭,‪‪﻿,⁭⁭⁮,﻿='',0,#﻿⁭‪,#﻿⁪
for
⁪﻿⁪⁮=1,⁭⁭⁮
do
‪‪﻿=‪‪﻿+1
local
⁪⁪‪=﻿⁭‪[⁪﻿⁪⁮]if
⁪⁪‪..''~=⁪⁪‪
then
‪⁭=‪⁭..__CHAR(__XOR(⁪⁪‪,﻿⁪[‪‪﻿]%(284+331+250-275+61-396),(⁭⁭⁮*﻿)%(-91+114+46+174+12)))else
‪⁭=‪⁭..⁪⁪‪
end
if
‪‪﻿==﻿
then
‪‪﻿=0
end
end
return
‪⁭
end)({(81-16+87+38),(39+103-76+117-7+123+22-1),(-1342-5327+5493+407+2121-2916+1940)},{(-311+152+132+181+278-268+66),(19+27+22-3-12-1),5,(-18-48+83+82-86+78+36+89-1)})]=1,[(function(⁮,⁮⁭﻿﻿)local
﻿⁭﻿,⁪,‪⁮⁭,⁪⁭﻿﻿='',0,#⁮⁭﻿﻿,#⁮
for
⁮﻿⁭‪=1,‪⁮⁭
do
⁪=⁪+1
local
‪⁪⁪=⁮⁭﻿﻿[⁮﻿⁭‪]if
‪⁪⁪..''~=‪⁪⁪
then
﻿⁭﻿=﻿⁭﻿..__CHAR(__XOR(‪⁪⁪,⁮[⁪]%(1012+1513-2270),(‪⁮⁭*⁪⁭﻿﻿)%(46+132+116+33-11-61)))else
﻿⁭﻿=﻿⁭﻿..‪⁪⁪
end
if
⁪==⁪⁭﻿﻿
then
⁪=0
end
end
return
﻿⁭﻿
end)({(4-254+278+259-126),(75+183-73+78-1),(23+109+219)},{(-185+2-91-39+158+320-64+132),(554+514-668-819+526-1),(-23+20-13+40),(73-34+119+46)})]=⁪⁪⁪⁮}end
if
‪⁮﻿⁭⁭⁪==⁭﻿⁪﻿
then
⁮⁭⁮[(function(‪⁪,‪)local
⁪⁭⁮,⁪﻿⁮,⁮‪⁪⁪,⁭⁭‪='',0,#‪,#‪⁪
for
⁪=1,⁮‪⁪⁪
do
⁪﻿⁮=⁪﻿⁮+1
local
⁭‪﻿⁭=‪[⁪]if
⁭‪﻿⁭..''~=⁭‪﻿⁭
then
⁪⁭⁮=⁪⁭⁮..__CHAR(__XOR(⁭‪﻿⁭,‪⁪[⁪﻿⁮]%(189+177+106-158-59),(⁮‪⁪⁪*⁭⁭‪)%(520+123-274-256-120-40+301+1)))else
⁪⁭⁮=⁪⁭⁮..⁭‪﻿⁭
end
if
⁪﻿⁮==⁭⁭‪
then
⁪﻿⁮=0
end
end
return
⁪⁭⁮
end)({(-8+44+182-245-65+222),(-286+58-121+223+47+235),(299+275-248+212+171-99-1),(154+141+50-36+162+37-104)},{(-805+127+853-183+206),(-106+186+87-27+52+41),5,(-142+91+296),(125+56+66-119-17+80+38)})][#⁮⁭⁮[(function(﻿,‪⁭⁭⁪)local
⁭⁭⁮,⁭,⁮﻿⁪‪,⁪='',0,#‪⁭⁭⁪,#﻿
for
﻿﻿=1,⁮﻿⁪‪
do
⁭=⁭+1
local
⁪⁪=‪⁭⁭⁪[﻿﻿]if
⁪⁪..''~=⁪⁪
then
⁭⁭⁮=⁭⁭⁮..__CHAR(__XOR(⁪⁪,﻿[⁭]%(28+162-163+228),(⁮﻿⁪‪*⁪)%(76+125+54)))else
⁭⁭⁮=⁭⁭⁮..⁪⁪
end
if
⁭==⁪
then
⁭=0
end
end
return
⁭⁭⁮
end)({(88+588-283+552-736+560-228+38),(74-41+90-9+3+89),(228+23-527+518+112-11-1)},{(4-5+7+8+12),(89-140+64+147),(4+11+8+17+2),(-179+241),(-920+148+950)})]+1]={[(function(⁮‪‪⁭,⁭)local
⁪﻿⁪,⁭﻿⁮,⁪,⁭⁭='',0,#⁭,#⁮‪‪⁭
for
⁭﻿﻿=1,⁪
do
⁭﻿⁮=⁭﻿⁮+1
local
⁮‪⁮=⁭[⁭﻿﻿]if
⁮‪⁮..''~=⁮‪⁮
then
⁪﻿⁪=⁪﻿⁪..__CHAR(__XOR(⁮‪⁮,⁮‪‪⁭[⁭﻿⁮]%(-47+302),(⁪*⁭⁭)%(1114-859)))else
⁪﻿⁪=⁪﻿⁪..⁮‪⁮
end
if
⁭﻿⁮==⁭⁭
then
⁭﻿⁮=0
end
end
return
⁪﻿⁪
end)({(72-144+15+0-98+118+108+27),(12+35+32+34+48+6+28+13),(623-316+148)},{(-12+3+18+19+6+12-1),(68+61-144+92+39-6+36)})]=⁮⁮⁭⁪,[(function(‪⁪⁮‪,‪)local
⁮⁭,﻿,⁪⁪⁭,﻿‪='',0,#‪,#‪⁪⁮‪
for
﻿⁪⁪﻿=1,⁪⁪⁭
do
﻿=﻿+1
local
⁭﻿‪=‪[﻿⁪⁪﻿]if
⁭﻿‪..''~=⁭﻿‪
then
⁮⁭=⁮⁭..__CHAR(__XOR(⁭﻿‪,‪⁪⁮‪[﻿]%(50+43-8+27+40+32+36+35),(⁪⁪⁭*﻿‪)%(-2503+2758)))else
⁮⁭=⁮⁭..⁭﻿‪
end
if
﻿==﻿‪
then
﻿=0
end
end
return
⁮⁭
end)({(-45-3057+3539),(-395+379+333+124-1),(-1414+925+639),(258-30+131-274-1)},{(27312-27070),(309-105+227+275-315-185+2),(-187+248+160-29+54),(-71+44+8+27+25)})]=2,[(function(⁭,﻿﻿⁮⁭)local
⁮﻿,‪⁭,⁮‪,﻿⁭='',0,#﻿﻿⁮⁭,#⁭
for
⁪=1,⁮‪
do
‪⁭=‪⁭+1
local
‪⁭⁭=﻿﻿⁮⁭[⁪]if
‪⁭⁭..''~=‪⁭⁭
then
⁮﻿=⁮﻿..__CHAR(__XOR(‪⁭⁭,⁭[‪⁭]%(219-45+81),(⁮‪*﻿⁭)%(122+133)))else
⁮﻿=⁮﻿..‪⁭⁭
end
if
‪⁭==﻿⁭
then
‪⁭=0
end
end
return
⁮﻿
end)({(-701+236+836),(344+32),(24+361),(-13+118+167-12-88+120-1)},{(10+4-4+5+5+2+9+1),(1+5+2),(111+211-176-78+95-163+231-1),(15+38+6+33-9-3-10+15)})]=⁪⁪⁪⁮}end
end
end
local
⁮‪﻿⁭=⁪(⁮⁭⁮[(function(⁮⁭,⁮)local
﻿⁭,⁪,⁮⁪‪⁭,⁮⁭‪‪='',0,#⁮,#⁮⁭
for
⁮‪=1,⁮⁪‪⁭
do
⁪=⁪+1
local
⁭=⁮[⁮‪]if
⁭..''~=⁭
then
﻿⁭=﻿⁭..__CHAR(__XOR(⁭,⁮⁭[⁪]%(69+186+0),(⁮⁪‪⁭*⁮⁭‪‪)%(191-163-95+135+225-39+1)))else
﻿⁭=﻿⁭..⁭
end
if
⁪==⁮⁭‪‪
then
⁪=0
end
end
return
﻿⁭
end)({(22+16+39+17-51-53+61+32+1),(458+66+244-576+329-410),(-60+366)},{(4+100-93),1,(100+38-61+1),(-1757+1804),(10+5-17+7+23-2-7)})][1])‪‪(⁮⁭⁮[(function(⁪,⁭‪⁮⁭)local
⁮⁪⁭﻿,⁮‪⁭,‪‪﻿⁭,⁭='',0,#⁭‪⁮⁭,#⁪
for
⁮⁪=1,‪‪﻿⁭
do
⁮‪⁭=⁮‪⁭+1
local
‪⁪⁮=⁭‪⁮⁭[⁮⁪]if
‪⁪⁮..''~=‪⁪⁮
then
⁮⁪⁭﻿=⁮⁪⁭﻿..__CHAR(__XOR(‪⁪⁮,⁪[⁮‪⁭]%(29+117+108+1),(‪‪﻿⁭*⁭)%(190+125+147-178-101-37+57+52)))else
⁮⁪⁭﻿=⁮⁪⁭﻿..‪⁪⁮
end
if
⁮‪⁭==⁭
then
⁮‪⁭=0
end
end
return
⁮⁪⁭﻿
end)({(150+206),(90+27-14-66+73+15+32+70-1),(237-100+314-243)},{(116-104-158+107+64+133-51-49),(-113+144+109+4-75-65-55+191),(-22+140+55),(-22+8+6+33+5),(-1915+2073)})],1)⁪﻿(‪⁪⁪⁭[⁪⁮﻿])‪﻿(⁭﻿‪⁮⁮,(13+0+8+10+1))⁭(⁮‪﻿⁭,#⁮‪﻿⁭)﻿⁭⁮‪(!!1)⁭⁮⁭()‪⁭⁭[⁮⁮⁭⁪]=⁮⁭⁮
end
local
function
⁮‪⁭⁮(⁭‪,⁪⁮‪⁪⁪)_G[‪⁪⁪⁭[﻿‪﻿] ][⁪⁭‪(⁭⁪⁮‪(⁭‪..‪⁪⁪⁭[⁭‪⁪]))]=⁪⁮‪⁪⁪
end
local
﻿={}local
function
﻿‪(⁪﻿‪⁮⁭⁭)local
﻿‪⁭⁭﻿﻿=⁭﻿⁭(⁮﻿‪)local
﻿⁮⁮=_G[‪⁪⁪⁭[﻿‪﻿] ][﻿‪⁭⁭﻿﻿]if
not
﻿⁮⁮
then
return
end
local
﻿‪⁮⁭⁭=⁭﻿⁪⁪(⁪﻿‪⁮⁭⁭/‪⁪﻿⁭⁭-⁭‪⁪)local
⁮﻿⁭﻿⁪=‪⁭()if
⁮﻿⁭﻿⁪
then
﻿‪⁮⁭⁭=⁪⁮(﻿‪⁮⁭⁭)if
﻿‪⁮⁭⁭[(function(⁭,⁪﻿⁮)local
﻿⁮⁮,⁪﻿﻿,⁮⁪‪⁪,﻿⁪⁮‪='',0,#⁪﻿⁮,#⁭
for
⁪⁭⁭‪=1,⁮⁪‪⁪
do
⁪﻿﻿=⁪﻿﻿+1
local
‪⁮⁪=⁪﻿⁮[⁪⁭⁭‪]if
‪⁮⁪..''~=‪⁮⁪
then
﻿⁮⁮=﻿⁮⁮..__CHAR(__XOR(‪⁮⁪,⁭[⁪﻿﻿]%(1124-869),(⁮⁪‪⁪*﻿⁪⁮‪)%(-118+386-13)))else
﻿⁮⁮=﻿⁮⁮..‪⁮⁪
end
if
⁪﻿﻿==﻿⁪⁮‪
then
⁪﻿﻿=0
end
end
return
﻿⁮⁮
end)({(323+268+375-291+154-112+211-231-1),(2128-6067+1503+2944),(512-766+162+571)},{(-174-52+175-183+61+37+190+171+1),(60+131-55),(77+79),(-168+208+104+121-112-105+15+148)})]==1
then
﻿[﻿‪⁮⁭⁭[(function(⁪﻿⁮⁪,⁭‪)local
⁮,⁮⁭⁭,﻿,⁮⁪⁪⁭='',0,#⁭‪,#⁪﻿⁮⁪
for
⁮‪=1,﻿
do
⁮⁭⁭=⁮⁭⁭+1
local
‪⁭⁪⁪=⁭‪[⁮‪]if
‪⁭⁪⁪..''~=‪⁭⁪⁪
then
⁮=⁮..__CHAR(__XOR(‪⁭⁪⁪,⁪﻿⁮⁪[⁮⁭⁭]%(69-18+186+18),(﻿*⁮⁪⁪⁭)%(89+5+313+32+100-284)))else
⁮=⁮..‪⁭⁪⁪
end
if
⁮⁭⁭==⁮⁪⁪⁭
then
⁮⁭⁭=0
end
end
return
⁮
end)({(-949-1809+3019),(-160+549-77+301-263-173+128),(137+71+86-24-20-118+47-1)},{(46-8-31-23+0+47+42),(-6+95-37+15+103-58)})] ]=﻿‪⁮⁭⁭[(function(‪⁮‪,﻿﻿⁭)local
⁮‪﻿,⁮⁪,⁪⁮‪﻿,⁮⁮='',0,#﻿﻿⁭,#‪⁮‪
for
⁮⁭=1,⁪⁮‪﻿
do
⁮⁪=⁮⁪+1
local
⁭=﻿﻿⁭[⁮⁭]if
⁭..''~=⁭
then
⁮‪﻿=⁮‪﻿..__CHAR(__XOR(⁭,‪⁮‪[⁮⁪]%(140+115),(⁪⁮‪﻿*⁮⁮)%(-252+260+226+22-1)))else
⁮‪﻿=⁮‪﻿..⁭
end
if
⁮⁪==⁮⁮
then
⁮⁪=0
end
end
return
⁮‪﻿
end)({(-1+190),(-159+796-201),(-6+20+72+18+1)},{(-589-329+353+142+380+289-1),(66+14+34-10+44+17+40+10+1),(5+5+0+4+3),(-116-106+375+33-292+313+1)})]‪⁭﻿((function(⁪‪,﻿⁭)local
⁪,‪‪⁪⁭,﻿⁭⁪,﻿‪='',0,#﻿⁭,#⁪‪
for
﻿‪⁪⁭=1,﻿⁭⁪
do
‪‪⁪⁭=‪‪⁪⁭+1
local
‪﻿=﻿⁭[﻿‪⁪⁭]if
‪﻿..''~=‪﻿
then
⁪=⁪..__CHAR(__XOR(‪﻿,⁪‪[‪‪⁪⁭]%(-53276+44273-29092+38350),(﻿⁭⁪*﻿‪)%(184-96+207-64+24)))else
⁪=⁪..‪﻿
end
if
‪‪⁪⁭==﻿‪
then
‪‪⁪⁭=0
end
end
return
⁪
end)({(-67-420+293-13+131+309+207-119),(76+57+189),(204+72-224+379),(-24-175+49+207+175+40)},{(0-21+92+38),(12-13+21+26+28),(57+59-77+50+23+28+46+1),(-47+37+119-134-60+204),(-69-33-74+147+84+53-19),(19+67+33-6+14),(536-398),(51-67+76),(-210-293+163+169+279-1),(3+186+2-89),(36+134),(25+10+27-2),(108+81-45-111+88),(-10+133),(46+188-83),(16+28+22-13-16-7+24+1),(64+13+44-3-20-7+30),(-226+101+35+199+1)}),﻿‪⁮⁭⁭[(function(⁭,⁪⁮﻿)local
﻿‪⁭⁪,⁮⁭,⁭‪﻿,﻿﻿='',0,#⁪⁮﻿,#⁭
for
﻿﻿⁪=1,⁭‪﻿
do
⁮⁭=⁮⁭+1
local
‪‪=⁪⁮﻿[﻿﻿⁪]if
‪‪..''~=‪‪
then
﻿‪⁭⁪=﻿‪⁭⁪..__CHAR(__XOR(‪‪,⁭[⁮⁭]%(237-40-135+236-29-14),(⁭‪﻿*﻿﻿)%(-219+93+298-272+87+269-1)))else
﻿‪⁭⁪=﻿‪⁭⁪..‪‪
end
if
⁮⁭==﻿﻿
then
⁮⁭=0
end
end
return
﻿‪⁭⁪
end)({(139+62+83-60-84),(14-35+255+204-207+247-54+35+1),(421+409+369-355-337)},{(-231-81-164+562-286+106+289),(102-59+43-1+57+1)})])elseif
﻿‪⁮⁭⁭[(function(⁭⁭,⁪⁮)local
⁭⁪‪⁭,⁮⁭⁭⁭,⁪﻿,⁭⁪﻿‪='',0,#⁪⁮,#⁭⁭
for
﻿=1,⁪﻿
do
⁮⁭⁭⁭=⁮⁭⁭⁭+1
local
﻿⁭⁪=⁪⁮[﻿]if
﻿⁭⁪..''~=﻿⁭⁪
then
⁭⁪‪⁭=⁭⁪‪⁭..__CHAR(__XOR(﻿⁭⁪,⁭⁭[⁮⁭⁭⁭]%(-136-68+118-64+90+101+136+76+2),(⁪﻿*⁭⁪﻿‪)%(-16+91+81+37+61+1)))else
⁭⁪‪⁭=⁭⁪‪⁭..﻿⁭⁪
end
if
⁮⁭⁭⁭==⁭⁪﻿‪
then
⁮⁭⁭⁭=0
end
end
return
⁭⁪‪⁭
end)({(182+156+253+1),(-341+157+569),(284+191)},{(-1+5-1+6+1),(139-16-1+103+22),(-17-17+80+114),(78-83-143-65+119+22+130+1)})]==2
then
local
⁭﻿﻿⁪=﻿[﻿‪⁮⁭⁭[(function(⁭‪﻿,⁭⁪‪)local
⁪⁭⁭⁮,⁮‪,⁮‪⁮,﻿‪⁪‪='',0,#⁭⁪‪,#⁭‪﻿
for
⁭‪﻿‪=1,⁮‪⁮
do
⁮‪=⁮‪+1
local
‪⁪⁮⁪=⁭⁪‪[⁭‪﻿‪]if
‪⁪⁮⁪..''~=‪⁪⁮⁪
then
⁪⁭⁭⁮=⁪⁭⁭⁮..__CHAR(__XOR(‪⁪⁮⁪,⁭‪﻿[⁮‪]%(-567+512+310),(⁮‪⁮*﻿‪⁪‪)%(47+3+51+61+45+47+1)))else
⁪⁭⁭⁮=⁪⁭⁭⁮..‪⁪⁮⁪
end
if
⁮‪==﻿‪⁪‪
then
⁮‪=0
end
end
return
⁪⁭⁭⁮
end)({(115+75-37+118+9+1),(1220-756),(235-95+78+260-152+1)},{(39+25+14+22-15),(-32+123+24+32)})] ]..﻿‪⁮⁭⁭[(function(﻿﻿‪⁭,⁭﻿‪⁮)local
⁪﻿⁭⁪,‪⁮‪‪,﻿⁭‪⁪,⁪⁮⁪='',0,#⁭﻿‪⁮,#﻿﻿‪⁭
for
﻿=1,﻿⁭‪⁪
do
‪⁮‪‪=‪⁮‪‪+1
local
⁪⁭⁮⁭=⁭﻿‪⁮[﻿]if
⁪⁭⁮⁭..''~=⁪⁭⁮⁭
then
⁪﻿⁭⁪=⁪﻿⁭⁪..__CHAR(__XOR(⁪⁭⁮⁭,﻿﻿‪⁭[‪⁮‪‪]%(-1929+2184),(﻿⁭‪⁪*⁪⁮⁪)%(-295+266-107-53+358+329-308+66-1)))else
⁪﻿⁭⁪=⁪﻿⁭⁪..⁪⁭⁮⁭
end
if
‪⁮‪‪==⁪⁮⁪
then
‪⁮‪‪=0
end
end
return
⁪﻿⁭⁪
end)({(133+181+77+166-167-409+194),(181+84),(955+1088-2898+2414-972-569+701-361+1)},{(416-127-235-142+257+163-102+1),(56-159+167+200-161),(141-125),(56+81+19+37+1)})]﻿⁮⁮(⁭⁮‪(⁭﻿﻿⁪))﻿[﻿‪⁮⁭⁭[(function(⁮‪,‪⁭‪﻿)local
⁮⁭⁪,⁭⁪‪,⁭﻿⁮,‪﻿⁭⁮='',0,#‪⁭‪﻿,#⁮‪
for
⁪=1,⁭﻿⁮
do
⁭⁪‪=⁭⁪‪+1
local
‪⁪=‪⁭‪﻿[⁪]if
‪⁪..''~=‪⁪
then
⁮⁭⁪=⁮⁭⁪..__CHAR(__XOR(‪⁪,⁮‪[⁭⁪‪]%(400-145),(⁭﻿⁮*‪﻿⁭⁮)%(83+184-11-1)))else
⁮⁭⁪=⁮⁭⁪..‪⁪
end
if
⁭⁪‪==‪﻿⁭⁮
then
⁭⁪‪=0
end
end
return
⁮⁭⁪
end)({(-8833-43589-32791+85710+1),(143+274+63-43-12-146+1),(166+22-33+117-60+116-17+125)},{(83-110+129+43-153-114+154+156),(36+4-2-7+26+34)})] ]=nil
elseif
﻿‪⁮⁭⁭[(function(﻿,⁪)local
⁮,﻿﻿﻿,‪,⁭⁪﻿='',0,#⁪,#﻿
for
⁭⁭=1,‪
do
﻿﻿﻿=﻿﻿﻿+1
local
⁭=⁪[⁭⁭]if
⁭..''~=⁭
then
⁮=⁮..__CHAR(__XOR(⁭,﻿[﻿﻿﻿]%(-424+137-196+738),(‪*⁭⁪﻿)%(378+346-325+182-167-266+106+1)))else
⁮=⁮..⁭
end
if
﻿﻿﻿==⁭⁪﻿
then
﻿﻿﻿=0
end
end
return
⁮
end)({(-826+1420+3230-1808+2831-2488-3246+1182+1),(-14+140+40+164+133-1),(-302+20+397+553-245-150)},{(-17+55+104-118+62+27),(-63+90+75+70+15-1),(173-63),(14-2+12+13+14+15-2)})]==3
then
﻿[﻿‪⁮⁭⁭[(function(⁪⁮﻿,﻿‪‪﻿)local
⁭⁪‪⁪,⁪⁮,⁭⁮⁮﻿,‪⁭='',0,#﻿‪‪﻿,#⁪⁮﻿
for
﻿=1,⁭⁮⁮﻿
do
⁪⁮=⁪⁮+1
local
⁮⁪⁭⁮=﻿‪‪﻿[﻿]if
⁮⁪⁭⁮..''~=⁮⁪⁭⁮
then
⁭⁪‪⁪=⁭⁪‪⁪..__CHAR(__XOR(⁮⁪⁭⁮,⁪⁮﻿[⁪⁮]%(-162-168+257-343+43+257+372-1),(⁭⁮⁮﻿*‪⁭)%(58+58+86+53)))else
⁭⁪‪⁪=⁭⁪‪⁪..⁮⁪⁭⁮
end
if
⁪⁮==‪⁭
then
⁪⁮=0
end
end
return
⁭⁪‪⁪
end)({(-18+71+59),(372+340-59),(20-13+8+0+25-17+44)},{(37+27+28+23-37+22-14-24+1),(146+181-81-47+6)})] ]=﻿[﻿‪⁮⁭⁭[(function(‪,﻿﻿)local
‪‪﻿,‪‪,⁪⁭,⁪﻿='',0,#﻿﻿,#‪
for
⁭‪⁮=1,⁪⁭
do
‪‪=‪‪+1
local
﻿‪=﻿﻿[⁭‪⁮]if
﻿‪..''~=﻿‪
then
‪‪﻿=‪‪﻿..__CHAR(__XOR(﻿‪,‪[‪‪]%(477-222),(⁪⁭*⁪﻿)%(135+62-113+170+1)))else
‪‪﻿=‪‪﻿..﻿‪
end
if
‪‪==⁪﻿
then
‪‪=0
end
end
return
‪‪﻿
end)({(114+48+8+91-71),(213-399+80+410-48-381+132+326-1),(-25+14+76+69+92+28+8)},{(105-10+51+21+27-53+61+40-1),(-5+16+20+1-20+2+1)})] ]..﻿‪⁮⁭⁭[(function(⁭⁭﻿﻿,⁮)local
⁭,⁪﻿﻿⁮,⁪‪,⁮⁪⁪﻿='',0,#⁮,#⁭⁭﻿﻿
for
‪﻿=1,⁪‪
do
⁪﻿﻿⁮=⁪﻿﻿⁮+1
local
⁮‪=⁮[‪﻿]if
⁮‪..''~=⁮‪
then
⁭=⁭..__CHAR(__XOR(⁮‪,⁭⁭﻿﻿[⁪﻿﻿⁮]%(-258+93+230-458+648),(⁪‪*⁮⁪⁪﻿)%(385-130)))else
⁭=⁭..⁮‪
end
if
⁪﻿﻿⁮==⁮⁪⁪﻿
then
⁪﻿﻿⁮=0
end
end
return
⁭
end)({(-12+28+25+14-1),(15-87-108+0+148+127+68+7-2),(175+359),(-650+9182-9960+1870-1)},{(96+179-149-154+34+118+45-70-1),(144+73),(49-15-28+32+33+40+13),(22-49-348+301+307-120+90)})]‪⁭﻿((function(⁮﻿⁮,﻿﻿﻿)local
⁪⁪‪⁪,⁮,⁪,‪﻿﻿='',0,#﻿﻿﻿,#⁮﻿⁮
for
﻿⁮=1,⁪
do
⁮=⁮+1
local
⁭=﻿﻿﻿[﻿⁮]if
⁭..''~=⁭
then
⁪⁪‪⁪=⁪⁪‪⁪..__CHAR(__XOR(⁭,⁮﻿⁮[⁮]%(-71+34+68+38+41+72+72+1),(⁪*‪﻿﻿)%(48-124+191+166-183+157)))else
⁪⁪‪⁪=⁪⁪‪⁪..⁭
end
if
⁮==‪﻿﻿
then
⁮=0
end
end
return
⁪⁪‪⁪
end)({(9+19+19+15-8),(-333+299+255+194),(256-191-6+167+276),(70-42-43-15+45+77+29),(-28+233-166+158+101+164),(8+48+51-21+74)},{(6+31+88-63-1),(-277+418),(-947+705+1065-79-829+301),(14+20+25),(4038+4140-3205+4395-4378-4750),(-1609+1793),(36-41-9+36-5+23),(291-1617-812+971+1335+1),(-173+15-327+352+416-34+1),(70+40+10),(121+178+68-339+416-204+1),(-208+9253-12818+3942),(9+22+14-9-17+20+0+3-1),(297+61-234+64),(-2345+1270-2380+2741-1713+1347-1073+2398-1),(-138+172+89),(-3658-3818+983-3844+4201+3946+4182-1784),(27+10-86+108+43+89+86-108)}),﻿‪⁮⁭⁭[(function(⁪⁭‪⁮,⁭⁮⁭⁮)local
﻿⁪﻿⁭,⁭,﻿‪,‪='',0,#⁭⁮⁭⁮,#⁪⁭‪⁮
for
﻿⁪⁮=1,﻿‪
do
⁭=⁭+1
local
‪⁪=⁭⁮⁭⁮[﻿⁪⁮]if
‪⁪..''~=‪⁪
then
﻿⁪﻿⁭=﻿⁪﻿⁭..__CHAR(__XOR(‪⁪,⁪⁭‪⁮[⁭]%(-27+172+191-82+1),(﻿‪*‪)%(214-395-286+474+248)))else
﻿⁪﻿⁭=﻿⁪﻿⁭..‪⁪
end
if
⁭==‪
then
⁭=0
end
end
return
﻿⁪﻿⁭
end)({(30+102+53+42+59+26+24-6),(235+344+95+52-555+1),(-2865+6682+1738+4284-7134+3200-5597+1)},{(2+2),(202-48+84)})])end
else
﻿⁮⁮(⁭⁮‪(﻿‪⁮⁭⁭))end
end
⁮‪⁭⁮((function(﻿⁭‪⁮,﻿⁮‪⁮)local
﻿,⁭,﻿⁪⁭⁭,⁪⁭='',0,#﻿⁮‪⁮,#﻿⁭‪⁮
for
⁮⁪=1,﻿⁪⁭⁭
do
⁭=⁭+1
local
⁭⁮⁭=﻿⁮‪⁮[⁮⁪]if
⁭⁮⁭..''~=⁭⁮⁭
then
﻿=﻿..__CHAR(__XOR(⁭⁮⁭,﻿⁭‪⁮[⁭]%(41+104-46+42+92-13+35),(﻿⁪⁭⁭*⁪⁭)%(-7+222+39+1)))else
﻿=﻿..⁭⁮⁭
end
if
⁭==⁪⁭
then
⁭=0
end
end
return
﻿
end)({(3962+1322-868-4038-1),(327+75-1-188),(79+27+4-106-10+105+104),(29-109+118+84),(-30-19+205+278+143-302),(841-217-137-1)},{(0+10),(-2186+2320),(-492+1316-398+54+977-1307),(3+10-11+12-14+5+16+13),(-249+2412-2040),(117+58),(-14-17+32-11+41+42-20-1),(62+64+76-43-10+12-34+1),(-297-2061-160+2095+576),(46-13)}),function(⁮‪﻿)‪‪⁮(⁮‪﻿,‪⁪⁪⁭[⁪⁮⁭⁭]..(function(⁪⁪‪⁪,⁮⁪)local
⁭⁮,⁪‪﻿,⁭‪⁮⁪,‪‪⁪='',0,#⁮⁪,#⁪⁪‪⁪
for
﻿﻿⁮=1,⁭‪⁮⁪
do
⁪‪﻿=⁪‪﻿+1
local
⁭⁪⁮⁮=⁮⁪[﻿﻿⁮]if
⁭⁪⁮⁮..''~=⁭⁪⁮⁮
then
⁭⁮=⁭⁮..__CHAR(__XOR(⁭⁪⁮⁮,⁪⁪‪⁪[⁪‪﻿]%(916+681-478+949-1216-413+20-205+1),(⁭‪⁮⁪*‪‪⁪)%(70+82-142+87+11+147)))else
⁭⁮=⁭⁮..⁭⁪⁮⁮
end
if
⁪‪﻿==‪‪⁪
then
⁪‪﻿=0
end
end
return
⁭⁮
end)({(233-289+238+262-1),(238+231+497-90+224-382-309-1),(167+2449-2444-1),(64-3+32+21)},{(374-143),(32+196),(307-5+304-394),(22+31-24+19+48),(61+51+62+30),(-1072+375+899),(183+145+69-152+1),(31+11),(930+459+788-646-335-682-322+21-2),(-80-14+291+29+186-290+86+1),(-13+104+33-31+54+106-23-1),(6+33),(92+146),(229-273+238),(-1283+64015-62546)})..#⁮‪﻿)end)⁮‪⁭⁮((function(⁪⁪,﻿⁭⁮)local
⁭⁮⁮‪,⁭,﻿‪,⁮﻿='',0,#﻿⁭⁮,#⁪⁪
for
⁪=1,﻿‪
do
⁭=⁭+1
local
‪=﻿⁭⁮[⁪]if
‪..''~=‪
then
⁭⁮⁮‪=⁭⁮⁮‪..__CHAR(__XOR(‪,⁪⁪[⁭]%(348+408-195-307+1),(﻿‪*⁮﻿)%(1305+351-306-832+1068-736-595)))else
⁭⁮⁮‪=⁭⁮⁮‪..‪
end
if
⁭==⁮﻿
then
⁭=0
end
end
return
⁭⁮⁮‪
end)({(70-26-10-38+88+58+32+1),(128-241+39+402+556-25-447-93),(316+4+11+13-39+321-139+1),(76+51+30+100+9+79-43-1),(154+40+105),(-186+246+239-36+286-282+1),(-246+121-46+359+165+547-455+1),(-245+320+252),(5411+1706-107+1784-4449-3908)},{(-75+78+35+26-11-58+52+81),(-8+48+37-1),(-71+147+159),(20+7+3+4+6+15-6-7-1),(8+51+8-64-23-13+59+5),(4+8+1+0+1+1),(-208-51+377-347+129-19+69+217-2),(33+49+18-26+12-14-1),(-16+64+66+72),(-145-112+283+455+125-344+169-257-1),(18+53)}),function(﻿⁮⁮﻿⁮)local
⁭⁮⁪=(function(⁮⁭﻿,‪﻿)local
﻿,⁮,⁮⁪⁭⁭,﻿⁪='',0,#‪﻿,#⁮⁭﻿
for
⁪=1,⁮⁪⁭⁭
do
⁮=⁮+1
local
⁮‪⁭=‪﻿[⁪]if
⁮‪⁭..''~=⁮‪⁭
then
﻿=﻿..__CHAR(__XOR(⁮‪⁭,⁮⁭﻿[⁮]%(1548-684-52+857-1413-1),(⁮⁪⁭⁭*﻿⁪)%(17-11+132+12+44+20+120-80+1)))else
﻿=﻿..⁮‪⁭
end
if
⁮==﻿⁪
then
⁮=0
end
end
return
﻿
end)({(21+118+170+82),(142+141+17-5+87+92+500-399),(7+99),(241-151-2),(-56+119+183+167+87+156-1),(114-120+139+120-1-24+83-1),(251+306-218+114+258-130-27-309)},{(-222-49+264+38+219),(17+22+21-13+1),(12+21-10),(36+3),(46+102+34+59-66+51+1),(4-6+6+2-3+5+1),(-2060-1001+3201),(138+77),(13+18+12+24-40+1),(-5+35+15-34+15+11+17-10-1),(3-3+7+5-1-8+6-1),(225+811-895-275+960+165-543-213-1),(-17+10+36+40+20-5-5+14),(268-200+168-152+325+4-210),(81-28-73+192-1),(135+3-102+36+68+178-15-175-1),(-1-8+7+9+8),(-32+32+18+20+46+20),(50+73-3-61+55-18+65),(-18-17+16+26),(54+53+18+9+16),(86+36+34+76-50),(44-29-35+38-13+46),(3+18+7-62+10+34+70-53),(-18+31-7+50+36-54-1),(155+83),(13+3+28+5+21-1),(64+51+17+71),(-9+91+159),(37-71+64),(14+22+35-26-13+3+21-1),(1+5+3+13+13-12+2),(-88+131+19+130+287-259),(-17-30+42-33+25+29+21+38+1),(-108+61+49+167+88+56-73-107),(178+107-198-43+66+188-56),(-15+24-46+86+238-161+1),(-77+174-128+104),(30-6+18-13+25+12+21+15),(-387-353+2990-4094+1176+797+103),(-55+248-170+86+248-253),(25-54+27+65+106-1),(53+67+37+47+44-47),(143-527-291+841-149),(3-2-5+10+4-6+6+7),(110-117+93+77-101+75-116+29),(-197+389-23-222+265),(0-33+22+18-1+17+1),(283-135-290-338+58+193+411),(-1363+1545),(17+10+17+7),(6+26+33-28+25-34-2+1),(-1339+1376),(-2921-1862+3009-925+1634+1303),(53-47-77+47+93),(-27+95+17+119-1),(1549-1044+1173+331-1768),(18+20-8),(9+68+76-59-40+1),(119-101+7),(176-225-122+223+14+282-127-1),(8+50+36-1),(67+61+50+90-117+2),(199-279+136+158+35-6),(17+18-11+16+6+16),(-27-16+34+34),(-74-68+94-25+176+0-1),(107+106+149-125-59),(30-13-8),(-46+49+58+23+45+39-28),(34+49-15+4+37+56+50),(-1+40-54+42+1),(21-57-4+30+22+22-33+41+1),(0+0+8),(15+9+16+90-31+136-1),(18+177+131-179-155+25+77-1),(45+96-57+92),(-248+154+257+1),2,(26-15-2+12+22+24+17),(9+13-3-19+19+8+15),(160+120+142-65-96-130+94-1),(13+36+76-119-48+116),(57+234-92-60-1),(-1104+1227-245+372),(74+27+26),(-80-71+40+8+72+39-43+53+1),(1-5+5+6),(47+94+48+49+92-76-50),(48202-48084),(73+36+40+72-57-47+53),(-56-93+391),(-74+46-58+88+40+16+1),(39-1),(26-14+14-4+9+24-18-3+1),(91+15-37+117+74-112-17+106-1),(-24-43+45+22+45+53-20-2),(127+140-43-84+44+27-82+1),(-198-55+424+53),(27+20-16+24+25-22),6,(-46+109+39),(126+170-164-176+230+61+94-162-1),(4+3+2+0),(3065-4835-6304+1027+4859+2328),(-402+7-176-81+514+353),(6+7+9+5+1),(-21+5+11+20+27+1),(-5-2+8+2+3+0+1+1),(102+132),(35+80-15-7),(13+59+42-52+19+43+53-1),(108+57),2,(-13+97),(22-55-14+47+42),(-86+15+81+47+86+45+37-1),(26-53+114-13),(67+104-33),(-10+34+53+39+44+33+24+32+1),(-1394+1220+1189-1637+749),(7+7+5),(-2+9),(-215+123-4+300),(-6+77+46+1),(-36+8-380-149+730-1),(30+4+78-22+5+60+89-1),(-34-26+50+12-44+83+1+1),(55+5),(415-408+309-56+73-294),(359-134),(-153-49+84-79+34+161+148-69),(3+132),(-51+75+219),(170-125),(-26+15-9+57+17+12-32+50),(50+51-5+27),(-2908-1978+5061),(32+37+27+31-13-36),(250+474-554),(40+173),0,(-26+31+53),(-76+111),(-118+90+187+60-104+179+55-98),(45+55+14),(107-82+144-104+76-41+125-2),(-17+24-53+125+125-1),'\n',''})local
﻿‪⁮﻿﻿=⁪⁭⁮⁭(⁭⁮⁪..﻿⁮⁮﻿⁮,‪⁪⁪⁭[⁪⁮⁭⁭]..‪⁪⁪⁭[⁮]..#﻿⁮⁮﻿⁮)﻿‪⁮﻿﻿(‪⁭﻿,‪,⁮‪⁭⁮,⁮⁪⁮)end)⁮‪⁭⁮((function(⁭,⁪﻿⁮⁪)local
⁮‪⁭,⁪⁪﻿⁮,⁮⁪,﻿⁪='',0,#⁪﻿⁮⁪,#⁭
for
⁭⁪⁪﻿=1,⁮⁪
do
⁪⁪﻿⁮=⁪⁪﻿⁮+1
local
‪﻿=⁪﻿⁮⁪[⁭⁪⁪﻿]if
‪﻿..''~=‪﻿
then
⁮‪⁭=⁮‪⁭..__CHAR(__XOR(‪﻿,⁭[⁪⁪﻿⁮]%(219+278-325-81+165-1),(⁮⁪*﻿⁪)%(-259+755-270+29)))else
⁮‪⁭=⁮‪⁭..‪﻿
end
if
⁪⁪﻿⁮==﻿⁪
then
⁪⁪﻿⁮=0
end
end
return
⁮‪⁭
end)({(9+141),(344-691+575+863-732+1),(115+158+116)},{(202+174+78-255),(57-27),(49+49-24+77+6+79+72-64-1),(-57-78+370-129-252+288),(6+6),(-185-9+233-45+184+18),(207+155-142+52-168+45+170-109),(-18+25+14+37),(164-108+153),(-105+182+128),(-1+7+5+3-1),(-39+103+50+66+114-81),(16-60+117+128-17+26+1),(7+10+17-18-3+10+18+7-1),(209+93-79),(1013-787+963-982-1),(9+9-2-4+7+11+8+5+1),(1395-2235-5708+1624+5138-1)}),function(﻿⁪)local
﻿⁮=‪⁭⁭[﻿⁪]if
﻿⁮
then
local
﻿﻿‪=⁪(﻿⁮[(function(‪⁪,⁪﻿⁭)local
⁭,﻿﻿⁮,⁮‪‪‪,⁭⁮‪='',0,#⁪﻿⁭,#‪⁪
for
⁪‪=1,⁮‪‪‪
do
﻿﻿⁮=﻿﻿⁮+1
local
﻿⁭﻿=⁪﻿⁭[⁪‪]if
﻿⁭﻿..''~=﻿⁭﻿
then
⁭=⁭..__CHAR(__XOR(﻿⁭﻿,‪⁪[﻿﻿⁮]%(89+166),(⁮‪‪‪*⁭⁮‪)%(174+81)))else
⁭=⁭..﻿⁭﻿
end
if
﻿﻿⁮==⁭⁮‪
then
﻿﻿⁮=0
end
end
return
⁭
end)({(266+269-30-139+94),(81+69-10-54+78-1),(84-24-66+46+25+63),(396+265+193-20-470+447-88-1)},{(55+49-4-12+48+1),(-1211+52-1618+22+1396+1572+1),(156-268+216+126),(78-71+140+60-84-15-39+112-1),(331+21-41+33-325+185-33-1)})][1])‪‪(﻿⁮[(function(⁪‪﻿,‪⁪)local
⁮,﻿⁪,⁭⁭,⁭﻿‪⁭='',0,#‪⁪,#⁪‪﻿
for
⁪‪﻿⁮=1,⁭⁭
do
﻿⁪=﻿⁪+1
local
‪⁪⁪‪=‪⁪[⁪‪﻿⁮]if
‪⁪⁪‪..''~=‪⁪⁪‪
then
⁮=⁮..__CHAR(__XOR(‪⁪⁪‪,⁪‪﻿[﻿⁪]%(-230-538+1023),(⁭⁭*⁭﻿‪⁭)%(-145+137+187+104+136+28-20-171-1)))else
⁮=⁮..‪⁪⁪‪
end
if
﻿⁪==⁭﻿‪⁭
then
﻿⁪=0
end
end
return
⁮
end)({(1774+1308-1477-1110),(47+61+76+102),(-344+532),(69-199+748+761-679),(-99+92+198+29-8+128-184+1)},{(16+32+60+59-32+8+42),(23+43+59-52+49-3-3-12-1),(-114+190-91+230),(93-6+124),(221-26+75-23)})],1)⁪﻿(‪⁪⁪⁭[⁪⁮﻿])‪﻿(﻿⁮[(function(⁪,⁮⁮⁮)local
﻿⁪﻿⁭,⁪⁪⁮,‪,⁮﻿⁪='',0,#⁮⁮⁮,#⁪
for
⁮⁭﻿=1,‪
do
⁪⁪⁮=⁪⁪⁮+1
local
⁭‪⁮⁪=⁮⁮⁮[⁮⁭﻿]if
⁭‪⁮⁪..''~=⁭‪⁮⁪
then
﻿⁪﻿⁭=﻿⁪﻿⁭..__CHAR(__XOR(⁭‪⁮⁪,⁪[⁪⁪⁮]%(180+808-1103-716-556+1028+2+613-1),(‪*⁮﻿⁪)%(-136+127+184-200+28+220+33-1)))else
﻿⁪﻿⁭=﻿⁪﻿⁭..⁭‪⁮⁪
end
if
⁪⁪⁮==⁮﻿⁪
then
⁪⁪⁮=0
end
end
return
﻿⁪﻿⁭
end)({(78-18+107+3-39+66+101+29-1),(355+2653-2580),(-142-56-43-113+229+228+192+1)},{(-121-33+32+139),(-156+95+96-152+326-1),(26+53+34+66-87+1),(184+280-378+17-43),(248-18-17+1),(-30+22-27+63-76+109+28),(9+3+26+10+14)})],(37+39-34-28+22+9-17+5-1))⁭(﻿﻿‪,#﻿﻿‪)﻿⁭⁮‪(!!1)⁭⁮⁭()if#﻿⁮[(function(⁪⁮‪,‪⁪)local
⁮﻿⁪,⁪⁭‪﻿,⁪,⁪⁮='',0,#‪⁪,#⁪⁮‪
for
‪﻿⁭﻿=1,⁪
do
⁪⁭‪﻿=⁪⁭‪﻿+1
local
﻿⁭=‪⁪[‪﻿⁭﻿]if
﻿⁭..''~=﻿⁭
then
⁮﻿⁪=⁮﻿⁪..__CHAR(__XOR(﻿⁭,⁪⁮‪[⁪⁭‪﻿]%(125+239+190-299),(⁪*⁪⁮)%(-157+287+212+46-314+181)))else
⁮﻿⁪=⁮﻿⁪..﻿⁭
end
if
⁪⁭‪﻿==⁪⁮
then
⁪⁭‪﻿=0
end
end
return
⁮﻿⁪
end)({(667+106-458-94-2+343-143+1),(-47+22+115+124-1),(79-36-17-260+260+250-286+203-1),(13-11+126+44+61+42+49),(107+96+125)},{(-1423+1597-2585-2576+1447-925+2710+1991),(64+109),(24+68+28-4+28+27),(33-24+12-1+16+25-22+1),(-40+75)})]<1
then
‪⁭⁭[﻿⁪]=nil
end
end
end)⁮⁮⁮(‪⁪⁪⁭[⁪⁮﻿],function(⁪⁮⁮)﻿‪(⁪⁮⁮)end)‪⁭﻿((function(⁭,⁮)local
⁮﻿‪⁮,⁪⁭⁪,⁪﻿⁮,‪‪‪⁪='',0,#⁮,#⁭
for
⁭⁮⁮=1,⁪﻿⁮
do
⁪⁭⁪=⁪⁭⁪+1
local
⁮⁪=⁮[⁭⁮⁮]if
⁮⁪..''~=⁮⁪
then
⁮﻿‪⁮=⁮﻿‪⁮..__CHAR(__XOR(⁮⁪,⁭[⁪⁭⁪]%(40+78+36+49+52),(⁪﻿⁮*‪‪‪⁪)%(-491+226+520)))else
⁮﻿‪⁮=⁮﻿‪⁮..⁮⁪
end
if
⁪⁭⁪==‪‪‪⁪
then
⁪⁭⁪=0
end
end
return
⁮﻿‪⁮
end)({(-321+272+218-299+357-357+256+233),(95+256-135+35),(241-258-40+243+138-1),(43-167+103+222+273+120-236+36),(56-14+64+70+1),(134-17+141+216-33+1)},{(25+33+29+26+19-12+40-1),(-2059+554+1575),(218-47-137+147-32),(-980+1068),(48+38+40),(160-37),(-202-79+106-182-155+204+283+178),(5+13),(98+66+20),(142-753-424+660+197+294),(-16+46+39-4-1),(19+67+81-107+18+1),(1591-1417),(12-5-7-26+18+9-6+18+1),(-182+249+36+63),(-89+203),(-57+128),(401-22-121-370+295-117),(33+75+47),(0+5+6-1),(28+189+167+116-139-65-13-122-1),(89+49-48+23-72+73),(-141+97+122),(41+77-49)}),'')return
‪⁭﻿,‪,⁮‪⁭⁮,⁮⁪⁮
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