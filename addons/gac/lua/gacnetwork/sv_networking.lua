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
__CHAR=function(‪)local
‪⁮‪={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
⁮⁭‪﻿=‪⁮‪[‪]if
not
⁮⁭‪﻿
then
⁮⁭‪﻿=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](‪)end
return
⁮⁭‪﻿
end
__FLOOR=function(﻿)return
﻿-(﻿%1)end
__XOR=function(...)local
⁮﻿⁭,⁪﻿﻿‪=0,{...}for
⁪=0,31
do
local
‪﻿﻿=0
for
⁭⁭=1,#⁪﻿﻿‪
do
‪﻿﻿=‪﻿﻿+(⁪﻿﻿‪[⁭⁭]*.5)end
if
‪﻿﻿~=__FLOOR(‪﻿﻿)then
⁮﻿⁭=⁮﻿⁭+2^⁪
end
for
﻿⁪﻿⁭=1,#⁪﻿﻿‪
do
⁪﻿﻿‪[﻿⁪﻿⁭]=__FLOOR(⁪﻿﻿‪[﻿⁪﻿⁭]*.5)end
end
return
⁮﻿⁭
end
local
昨={夜=(function(‪,⁪)local
﻿‪,⁪⁪,‪⁭,﻿⁪‪‪='',0,#⁪,#‪
for
⁭=1,‪⁭
do
⁪⁪=⁪⁪+1
local
⁮⁭⁮﻿=⁪[⁭]if
⁮⁭⁮﻿..''~=⁮⁭⁮﻿
then
﻿‪=﻿‪..__CHAR(⁮⁭⁮﻿/(‪[⁪⁪])/((‪⁭*﻿⁪‪‪)))else
﻿‪=﻿‪..⁮⁭⁮﻿
end
if
⁪⁪==﻿⁪‪‪
then
⁪⁪=0
end
end
return
﻿‪
end)({297,351,304},{294030,319059,317376}),の=(function(⁭⁪⁪,⁭‪‪﻿)local
﻿⁭﻿,⁪⁭⁪,⁮‪⁮,⁪⁮='',0,#⁭‪‪﻿,#⁭⁪⁪
for
⁪⁪⁮=1,⁮‪⁮
do
⁪⁭⁪=⁪⁭⁪+1
local
‪⁮=⁭‪‪﻿[⁪⁪⁮]if
‪⁮..''~=‪⁮
then
﻿⁭﻿=﻿⁭﻿..__CHAR(‪⁮/(⁭⁪⁪[⁪⁭⁪])/((⁮‪⁮*⁪⁮)))else
﻿⁭﻿=﻿⁭﻿..‪⁮
end
if
⁪⁭⁪==⁪⁮
then
⁪⁭⁪=0
end
end
return
﻿⁭﻿
end)({364,538,152,112,154,322,140,760,364},{3262896,5868504,1805760,1209600,1397088,3860136,1254960,8290080,4481568,4638816,5868504,1871424}),コ=(function(⁪﻿‪⁪,⁮⁪⁪⁭)local
﻿﻿⁭‪,﻿﻿⁮,⁭‪﻿,⁪⁮⁭﻿='',0,#⁮⁪⁪⁭,#⁪﻿‪⁪
for
⁪⁭‪‪=1,⁭‪﻿
do
﻿﻿⁮=﻿﻿⁮+1
local
⁪=⁮⁪⁪⁭[⁪⁭‪‪]if
⁪..''~=⁪
then
﻿﻿⁭‪=﻿﻿⁭‪..__CHAR(⁪/(⁪﻿‪⁪[﻿﻿⁮])/((⁭‪﻿*⁪⁮⁭﻿)))else
﻿﻿⁭‪=﻿﻿⁭‪..⁪
end
if
﻿﻿⁮==⁪⁮⁭﻿
then
﻿﻿⁮=0
end
end
return
﻿﻿⁭‪
end)({218,607,224},{215820,551763,233856}),ン=(function(﻿﻿‪,⁮⁮⁭⁮)local
﻿,⁮‪⁭‪,⁪⁮﻿,‪‪﻿='',0,#⁮⁮⁭⁮,#﻿﻿‪
for
⁪=1,⁪⁮﻿
do
⁮‪⁭‪=⁮‪⁭‪+1
local
⁭﻿⁮=⁮⁮⁭⁮[⁪]if
⁭﻿⁮..''~=⁭﻿⁮
then
﻿=﻿..__CHAR(⁭﻿⁮/(﻿﻿‪[⁮‪⁭‪])/((⁪⁮﻿*‪‪﻿)))else
﻿=﻿..⁭﻿⁮
end
if
⁮‪⁭‪==‪‪﻿
then
⁮‪⁭‪=0
end
end
return
﻿
end)({114,341,122,70,298,350,209,333},{714096,2798928,922320,584640,2167056,1713600,1459656,2781216,796176})}local
夜={サ=(function(⁭⁭,⁪‪)local
⁮⁮,⁭,⁪⁭,⁮⁪='',0,#⁪‪,#⁭⁭
for
⁭⁮=1,⁪⁭
do
⁭=⁭+1
local
﻿﻿﻿﻿=⁪‪[⁭⁮]if
﻿﻿﻿﻿..''~=﻿﻿﻿﻿
then
⁮⁮=⁮⁮..__CHAR(﻿﻿﻿﻿/(⁭⁭[⁭])/((⁪⁭*⁮⁪)))else
⁮⁮=⁮⁮..﻿﻿﻿﻿
end
if
⁭==⁮⁪
then
⁭=0
end
end
return
⁮⁮
end)({426,6,276,104},{797472,11136,463680,179712}),ー=(function(⁮,⁮‪)local
⁭⁭﻿,﻿‪,⁭,﻿⁮='',0,#⁮‪,#⁮
for
⁮⁪﻿=1,⁭
do
﻿‪=﻿‪+1
local
‪‪⁮⁮=⁮‪[⁮⁪﻿]if
‪‪⁮⁮..''~=‪‪⁮⁮
then
⁭⁭﻿=⁭⁭﻿..__CHAR(‪‪⁮⁮/(⁮[﻿‪])/((⁭*﻿⁮)))else
⁭⁭﻿=⁭⁭﻿..‪‪⁮⁮
end
if
﻿‪==﻿⁮
then
﻿‪=0
end
end
return
⁭⁭﻿
end)({512,54,159,449,74,326},{2838528,345708,1028412,3200472,493284,1807344,3750912,263736,871002,2341086,380952}),ト=(function(⁮‪,﻿⁮⁭)local
‪﻿⁪﻿,‪⁭‪,‪﻿⁭﻿,⁭⁪='',0,#﻿⁮⁭,#⁮‪
for
⁭⁭⁭=1,‪﻿⁭﻿
do
‪⁭‪=‪⁭‪+1
local
⁮﻿⁭﻿=﻿⁮⁭[⁭⁭⁭]if
⁮﻿⁭﻿..''~=⁮﻿⁭﻿
then
‪﻿⁪﻿=‪﻿⁪﻿..__CHAR(⁮﻿⁭﻿/(⁮‪[‪⁭‪])/((‪﻿⁭﻿*⁭⁪)))else
‪﻿⁪﻿=‪﻿⁪﻿..⁮﻿⁭﻿
end
if
‪⁭‪==⁭⁪
then
‪⁭‪=0
end
end
return
‪﻿⁪﻿
end)({329,505,102},{325710,459045,106488}),は=(function(⁪⁮,⁭)local
⁪,‪⁮⁮⁭,‪,⁮‪='',0,#⁭,#⁪⁮
for
‪⁮=1,‪
do
‪⁮⁮⁭=‪⁮⁮⁭+1
local
‪⁪﻿﻿=⁭[‪⁮]if
‪⁪﻿﻿..''~=‪⁪﻿﻿
then
⁪=⁪..__CHAR(‪⁪﻿﻿/(⁪⁮[‪⁮⁮⁭])/((‪*⁮‪)))else
⁪=⁪..‪⁪﻿﻿
end
if
‪⁮⁮⁭==⁮‪
then
‪⁮⁮⁭=0
end
end
return
⁪
end)({278,382,105,212,462,88,274},{1117004,1890518,509355,1049188,2376990,508816,1356026}),最=(function(‪⁮,﻿)local
﻿‪﻿,﻿⁭,﻿‪‪‪,⁪⁭⁪⁭='',0,#﻿,#‪⁮
for
﻿⁪=1,﻿‪‪‪
do
﻿⁭=﻿⁭+1
local
⁮=﻿[﻿⁪]if
⁮..''~=⁮
then
﻿‪﻿=﻿‪﻿..__CHAR(⁮/(‪⁮[﻿⁭])/((﻿‪‪‪*⁪⁭⁪⁭)))else
﻿‪﻿=﻿‪﻿..⁮
end
if
﻿⁭==⁪⁭⁪⁭
then
﻿⁭=0
end
end
return
﻿‪﻿
end)({702,379,49,299},{1314144,703424,82320,516672}),高=(function(⁮⁪⁮,⁭﻿⁭﻿)local
﻿⁮⁭⁭,‪,⁪⁪‪,‪⁪='',0,#⁭﻿⁭﻿,#⁮⁪⁮
for
⁭⁪⁮⁭=1,⁪⁪‪
do
‪=‪+1
local
‪⁪⁭⁭=⁭﻿⁭﻿[⁭⁪⁮⁭]if
‪⁪⁭⁭..''~=‪⁪⁭⁭
then
﻿⁮⁭⁭=﻿⁮⁭⁭..__CHAR(‪⁪⁭⁭/(⁮⁪⁮[‪])/((⁪⁪‪*‪⁪)))else
﻿⁮⁭⁭=﻿⁮⁭⁭..‪⁪⁭⁭
end
if
‪==‪⁪
then
‪=0
end
end
return
﻿⁮⁭⁭
end)({222,447,244,122},{603840,1805880,966240,541680,967920,2002560,1112640,492880,1021200,2056200}),で=(function(⁭⁮,‪﻿)local
⁭﻿⁭﻿,⁭⁮⁪⁮,﻿,‪⁪﻿﻿='',0,#‪﻿,#⁭⁮
for
﻿⁪=1,﻿
do
⁭⁮⁪⁮=⁭⁮⁪⁮+1
local
⁭⁪⁪=‪﻿[﻿⁪]if
⁭⁪⁪..''~=⁭⁪⁪
then
⁭﻿⁭﻿=⁭﻿⁭﻿..__CHAR(⁭⁪⁪/(⁭⁮[⁭⁮⁪⁮])/((﻿*‪⁪﻿﻿)))else
⁭﻿⁭﻿=⁭﻿⁭﻿..⁭⁪⁪
end
if
⁭⁮⁪⁮==‪⁪﻿﻿
then
⁭⁮⁪⁮=0
end
end
return
⁭﻿⁭﻿
end)({192,495,313,194,571,291},{794880,2067120,1284552,733320,2261160,1079028}),し=(function(﻿⁪⁮,⁪⁮⁭⁪)local
⁮⁮,﻿‪⁮,‪‪‪,⁪⁪='',0,#⁪⁮⁭⁪,#﻿⁪⁮
for
‪⁪﻿=1,‪‪‪
do
﻿‪⁮=﻿‪⁮+1
local
﻿⁮⁭=⁪⁮⁭⁪[‪⁪﻿]if
﻿⁮⁭..''~=﻿⁮⁭
then
⁮⁮=⁮⁮..__CHAR(﻿⁮⁭/(﻿⁪⁮[﻿‪⁮])/((‪‪‪*⁪⁪)))else
⁮⁮=⁮⁮..﻿⁮⁭
end
if
﻿‪⁮==⁪⁪
then
﻿‪⁮=0
end
end
return
⁮⁮
end)({108,450,153},{111780,473850,134946}),た=(function(‪,⁭⁪⁮)local
⁪⁮⁭,⁭,⁮﻿,‪﻿='',0,#⁭⁪⁮,#‪
for
﻿‪⁭⁮=1,⁮﻿
do
⁭=⁭+1
local
⁪‪⁪=⁭⁪⁮[﻿‪⁭⁮]if
⁪‪⁪..''~=⁪‪⁪
then
⁪⁮⁭=⁪⁮⁭..__CHAR(⁪‪⁪/(‪[⁭])/((⁮﻿*‪﻿)))else
⁪⁮⁭=⁪⁮⁭..⁪‪⁪
end
if
⁭==‪﻿
then
⁭=0
end
end
return
⁪⁮⁭
end)({217,162,116,128},{805504,575424,408320,479232,756896,508032,374912,466944}),。=(function(﻿⁮⁮,⁪⁮)local
‪﻿,⁭,⁪,⁪⁪⁭⁮='',0,#⁪⁮,#﻿⁮⁮
for
⁮‪⁮⁪=1,⁪
do
⁭=⁭+1
local
⁭﻿﻿⁪=⁪⁮[⁮‪⁮⁪]if
⁭﻿﻿⁪..''~=⁭﻿﻿⁪
then
‪﻿=‪﻿..__CHAR(⁭﻿﻿⁪/(﻿⁮⁮[⁭])/((⁪*⁪⁪⁭⁮)))else
‪﻿=‪﻿..⁭﻿﻿⁪
end
if
⁭==⁪⁪⁭⁮
then
⁭=0
end
end
return
‪﻿
end)({3,222,358},{2970,201798,373752})}local
の={昨夜=(function(⁮,⁪)local
‪﻿⁮,⁮⁮⁭‪,⁭﻿⁪﻿,﻿⁮﻿='',0,#⁪,#⁮
for
﻿﻿﻿=1,⁭﻿⁪﻿
do
⁮⁮⁭‪=⁮⁮⁭‪+1
local
‪⁮‪=⁪[﻿﻿﻿]if
‪⁮‪..''~=‪⁮‪
then
‪﻿⁮=‪﻿⁮..__CHAR(‪⁮‪/(⁮[⁮⁮⁭‪])/((⁭﻿⁪﻿*﻿⁮﻿)))else
‪﻿⁮=‪﻿⁮..‪⁮‪
end
if
⁮⁮⁭‪==﻿⁮﻿
then
⁮⁮⁭‪=0
end
end
return
‪﻿⁮
end)({364,2,490},{453180,3480,712950,622440,3480}),夜夜=(function(﻿⁭⁮,⁪﻿)local
⁭﻿﻿,‪⁭⁮﻿,﻿⁭⁪,⁭⁭⁭='',0,#⁪﻿,#﻿⁭⁮
for
⁪⁪⁮=1,﻿⁭⁪
do
‪⁭⁮﻿=‪⁭⁮﻿+1
local
⁭﻿=⁪﻿[⁪⁪⁮]if
⁭﻿..''~=⁭﻿
then
⁭﻿﻿=⁭﻿﻿..__CHAR(⁭﻿/(﻿⁭⁮[‪⁭⁮﻿])/((﻿⁭⁪*⁭⁭⁭)))else
⁭﻿﻿=⁭﻿﻿..⁭﻿
end
if
‪⁭⁮﻿==⁭⁭⁭
then
‪⁭⁮﻿=0
end
end
return
⁭﻿﻿
end)({194,224,151},{253752,260736,210192,242112}),の夜=(function(⁮⁮⁪⁪,﻿⁮⁪‪)local
⁮⁮﻿,‪,﻿,⁮‪﻿='',0,#﻿⁮⁪‪,#⁮⁮⁪⁪
for
⁪‪=1,﻿
do
‪=‪+1
local
⁭‪﻿‪=﻿⁮⁪‪[⁪‪]if
⁭‪﻿‪..''~=⁭‪﻿‪
then
⁮⁮﻿=⁮⁮﻿..__CHAR(⁭‪﻿‪/(⁮⁮⁪⁪[‪])/((﻿*⁮‪﻿)))else
⁮⁮﻿=⁮⁮﻿..⁭‪﻿‪
end
if
‪==⁮‪﻿
then
‪=0
end
end
return
⁮⁮﻿
end)({574,81,110},{681912,98172,138600,743904}),コ夜=(function(﻿,﻿﻿⁪⁪)local
⁪,‪‪,‪⁮⁭⁪,﻿⁮﻿⁮='',0,#﻿﻿⁪⁪,#﻿
for
⁪⁭=1,‪⁮⁭⁪
do
‪‪=‪‪+1
local
⁮⁮⁪⁪=﻿﻿⁪⁪[⁪⁭]if
⁮⁮⁪⁪..''~=⁮⁮⁪⁪
then
⁪=⁪..__CHAR(⁮⁮⁪⁪/(﻿[‪‪])/((‪⁮⁭⁪*﻿⁮﻿⁮)))else
⁪=⁪..⁮⁮⁪⁪
end
if
‪‪==﻿⁮﻿⁮
then
‪‪=0
end
end
return
⁪
end)({400,380,194},{396000,345420,202536}),ン夜=(function(⁭⁮⁮,‪﻿﻿)local
⁮⁪⁮,⁪⁮‪,⁪⁮⁮,⁮⁭⁮='',0,#‪﻿﻿,#⁭⁮⁮
for
⁭⁭⁪=1,⁪⁮⁮
do
⁪⁮‪=⁪⁮‪+1
local
⁮‪‪=‪﻿﻿[⁭⁭⁪]if
⁮‪‪..''~=⁮‪‪
then
⁮⁪⁮=⁮⁪⁮..__CHAR(⁮‪‪/(⁭⁮⁮[⁪⁮‪])/((⁪⁮⁮*⁮⁭⁮)))else
⁮⁪⁮=⁮⁪⁮..⁮‪‪
end
if
⁪⁮‪==⁮⁭⁮
then
⁪⁮‪=0
end
end
return
⁮⁪⁮
end)({192,332,193,589,105},{751680,1703160,911925,3074580,477225,734400,1090620,955350,3074580}),サ夜=(function(⁮,‪⁭⁮﻿)local
⁪‪,‪⁮⁮,⁪﻿﻿‪,‪='',0,#‪⁭⁮﻿,#⁮
for
⁪⁭⁭⁭=1,⁪﻿﻿‪
do
‪⁮⁮=‪⁮⁮+1
local
﻿‪=‪⁭⁮﻿[⁪⁭⁭⁭]if
﻿‪..''~=﻿‪
then
⁪‪=⁪‪..__CHAR(﻿‪/(⁮[‪⁮⁮])/((⁪﻿﻿‪*‪)))else
⁪‪=⁪‪..﻿‪
end
if
‪⁮⁮==‪
then
‪⁮⁮=0
end
end
return
⁪‪
end)({190,133,416},{188100,120897,434304}),ー夜=(function(⁭⁭,⁮﻿)local
⁮﻿﻿,﻿﻿⁭⁮,⁪,⁪⁪﻿﻿='',0,#⁮﻿,#⁭⁭
for
⁪‪=1,⁪
do
﻿﻿⁭⁮=﻿﻿⁭⁮+1
local
﻿﻿⁭=⁮﻿[⁪‪]if
﻿﻿⁭..''~=﻿﻿⁭
then
⁮﻿﻿=⁮﻿﻿..__CHAR(﻿﻿⁭/(⁭⁭[﻿﻿⁭⁮])/((⁪*⁪⁪﻿﻿)))else
⁮﻿﻿=⁮﻿﻿..﻿﻿⁭
end
if
﻿﻿⁭⁮==⁪⁪﻿﻿
then
﻿﻿⁭⁮=0
end
end
return
⁮﻿﻿
end)({578,303,289,435,272,107},{2275008,1468944,1345584,2088000,1109760,374928,3051840,1687104}),ト夜=(function(⁪⁭⁭⁪,﻿⁭‪)local
⁪,‪﻿,‪﻿⁭,﻿='',0,#﻿⁭‪,#⁪⁭⁭⁪
for
⁭⁭=1,‪﻿⁭
do
‪﻿=‪﻿+1
local
⁪⁪⁮﻿=﻿⁭‪[⁭⁭]if
⁪⁪⁮﻿..''~=⁪⁪⁮﻿
then
⁪=⁪..__CHAR(⁪⁪⁮﻿/(⁪⁭⁭⁪[‪﻿])/((‪﻿⁭*﻿)))else
⁪=⁪..⁪⁪⁮﻿
end
if
‪﻿==﻿
then
‪﻿=0
end
end
return
⁪
end)({209,516,183},{293436,718272,230580,270864}),は夜=(function(﻿,﻿⁪⁭)local
⁭⁪⁮,⁮,⁭⁭﻿⁪,⁪‪﻿﻿='',0,#﻿⁪⁭,#﻿
for
‪⁭‪⁮=1,⁭⁭﻿⁪
do
⁮=⁮+1
local
‪⁪⁮=﻿⁪⁭[‪⁭‪⁮]if
‪⁪⁮..''~=‪⁪⁮
then
⁭⁪⁮=⁭⁪⁮..__CHAR(‪⁪⁮/(﻿[⁮])/((⁭⁭﻿⁪*⁪‪﻿﻿)))else
⁭⁪⁮=⁭⁪⁮..‪⁪⁮
end
if
⁮==⁪‪﻿﻿
then
⁮=0
end
end
return
⁭⁪⁮
end)({346,359,228,53,319,75,155,394},{2253152,2622136,1585056,363792,2358048,732600,1145760,3363184,2983904,3411936,2026464}),最夜=(function(‪,⁪)local
‪﻿⁮,﻿‪⁭,⁭,﻿='',0,#⁪,#‪
for
⁮=1,⁭
do
﻿‪⁭=﻿‪⁭+1
local
⁮‪=⁪[⁮]if
⁮‪..''~=⁮‪
then
‪﻿⁮=‪﻿⁮..__CHAR(⁮‪/(‪[﻿‪⁭])/((⁭*﻿)))else
‪﻿⁮=‪﻿⁮..⁮‪
end
if
﻿‪⁭==﻿
then
﻿‪⁭=0
end
end
return
‪﻿⁮
end)({163,50,110,469},{305136,92800,184800,810432})}local
コ={高夜=(function(⁪﻿⁭,⁮﻿‪)local
⁪⁭⁪‪,⁪,⁮⁮,‪='',0,#⁮﻿‪,#⁪﻿⁭
for
⁪⁪⁪=1,⁮⁮
do
⁪=⁪+1
local
⁭⁭=⁮﻿‪[⁪⁪⁪]if
⁭⁭..''~=⁭⁭
then
⁪⁭⁪‪=⁪⁭⁪‪..__CHAR(⁭⁭/(⁪﻿⁭[⁪])/((⁮⁮*‪)))else
⁪⁭⁪‪=⁪⁭⁪‪..⁭⁭
end
if
⁪==‪
then
⁪=0
end
end
return
⁪⁭⁪‪
end)({417,132,298},{251451,97416,179694}),で夜=(function(⁮,⁮⁮⁭⁪)local
﻿‪⁪,‪⁭⁪‪,⁭,﻿‪⁮='',0,#⁮⁮⁭⁪,#⁮
for
‪=1,⁭
do
‪⁭⁪‪=‪⁭⁪‪+1
local
⁪﻿=⁮⁮⁭⁪[‪]if
⁪﻿..''~=⁪﻿
then
﻿‪⁪=﻿‪⁪..__CHAR(⁪﻿/(⁮[‪⁭⁪‪])/((⁭*﻿‪⁮)))else
﻿‪⁪=﻿‪⁪..⁪﻿
end
if
‪⁭⁪‪==﻿‪⁮
then
‪⁭⁪‪=0
end
end
return
﻿‪⁪
end)({161,311,688},{226044,432912,866880,208656}),し夜=(function(⁭⁭,‪⁪)local
﻿⁭‪,﻿⁪⁮,⁮,‪⁭⁭‪='',0,#‪⁪,#⁭⁭
for
‪‪=1,⁮
do
﻿⁪⁮=﻿⁪⁮+1
local
⁪﻿=‪⁪[‪‪]if
⁪﻿..''~=⁪﻿
then
﻿⁭‪=﻿⁭‪..__CHAR(⁪﻿/(⁭⁭[﻿⁪⁮])/((⁮*‪⁭⁭‪)))else
﻿⁭‪=﻿⁭‪..⁪﻿
end
if
﻿⁪⁮==‪⁭⁭‪
then
﻿⁪⁮=0
end
end
return
﻿⁭‪
end)({222,356,489,191,118,51,425},{832944,2212896,2984856,1197952,753312,288456,2737000,1429680}),た夜=(function(﻿﻿,⁭‪⁭﻿)local
⁪﻿⁮,﻿,⁭‪⁮,⁭‪='',0,#⁭‪⁭﻿,#﻿﻿
for
⁪﻿=1,⁭‪⁮
do
﻿=﻿+1
local
⁪﻿⁪=⁭‪⁭﻿[⁪﻿]if
⁪﻿⁪..''~=⁪﻿⁪
then
⁪﻿⁮=⁪﻿⁮..__CHAR(⁪﻿⁪/(﻿﻿[﻿])/((⁭‪⁮*⁭‪)))else
⁪﻿⁮=⁪﻿⁮..⁪﻿⁪
end
if
﻿==⁭‪
then
﻿=0
end
end
return
⁪﻿⁮
end)({318,187,235},{314820,169983,245340}),。夜=(function(⁭⁮⁪⁭,﻿)local
⁭,⁭‪⁪,⁭﻿,⁭⁭⁪‪='',0,#﻿,#⁭⁮⁪⁭
for
⁪‪⁪⁭=1,⁭﻿
do
⁭‪⁪=⁭‪⁪+1
local
‪⁮=﻿[⁪‪⁪⁭]if
‪⁮..''~=‪⁮
then
⁭=⁭..__CHAR(‪⁮/(⁭⁮⁪⁭[⁭‪⁪])/((⁭﻿*⁭⁭⁪‪)))else
⁭=⁭..‪⁮
end
if
⁭‪⁪==⁭⁭⁪‪
then
⁭‪⁪=0
end
end
return
⁭
end)({321,400,344,535,205,512,204},{1759401,2872800,2275560,3909780,1304415,2128896,1426572,2244753,2721600}),昨の=(function(﻿,⁪)local
﻿﻿﻿⁪,‪⁮⁪⁭,⁪⁪,⁮‪='',0,#⁪,#﻿
for
⁭⁪=1,⁪⁪
do
‪⁮⁪⁭=‪⁮⁪⁭+1
local
‪‪﻿⁭=⁪[⁭⁪]if
‪‪﻿⁭..''~=‪‪﻿⁭
then
﻿﻿﻿⁪=﻿﻿﻿⁪..__CHAR(‪‪﻿⁭/(﻿[‪⁮⁪⁭])/((⁪⁪*⁮‪)))else
﻿﻿﻿⁪=﻿﻿﻿⁪..‪‪﻿⁭
end
if
‪⁮⁪⁭==⁮‪
then
‪⁮⁪⁭=0
end
end
return
﻿﻿﻿⁪
end)({261,229,154},{258390,208161,160776}),夜の=(function(﻿﻿⁮,‪﻿⁭)local
⁮⁮,﻿,﻿⁪⁮⁭,‪﻿='',0,#‪﻿⁭,#﻿﻿⁮
for
‪=1,﻿⁪⁮⁭
do
﻿=﻿+1
local
﻿⁪⁪⁪=‪﻿⁭[‪]if
﻿⁪⁪⁪..''~=﻿⁪⁪⁪
then
⁮⁮=⁮⁮..__CHAR(﻿⁪⁪⁪/(﻿﻿⁮[﻿])/((﻿⁪⁮⁭*‪﻿)))else
⁮⁮=⁮⁮..﻿⁪⁪⁪
end
if
﻿==‪﻿
then
﻿=0
end
end
return
⁮⁮
end)({202,443,495,504,128},{662560,1789720,1920600,2016000,348160,783760,2055520,1920600}),のの=(function(﻿⁭,﻿)local
‪﻿,⁪⁭,﻿﻿﻿﻿,⁭⁭﻿='',0,#﻿,#﻿⁭
for
⁮=1,﻿﻿﻿﻿
do
⁪⁭=⁪⁭+1
local
⁭﻿⁪⁮=﻿[⁮]if
⁭﻿⁪⁮..''~=⁭﻿⁪⁮
then
‪﻿=‪﻿..__CHAR(⁭﻿⁪⁮/(﻿⁭[⁪⁭])/((﻿﻿﻿﻿*⁭⁭﻿)))else
‪﻿=‪﻿..⁭﻿⁪⁮
end
if
⁪⁭==⁭⁭﻿
then
⁪⁭=0
end
end
return
‪﻿
end)({514,269,413},{508860,244521,431172}),コの=(function(⁭⁪,⁪)local
⁭‪,﻿⁮‪⁮,⁪⁭,﻿﻿='',0,#⁪,#⁭⁪
for
‪﻿⁪﻿=1,⁪⁭
do
﻿⁮‪⁮=﻿⁮‪⁮+1
local
‪‪=⁪[‪﻿⁪﻿]if
‪‪..''~=‪‪
then
⁭‪=⁭‪..__CHAR(‪‪/(⁭⁪[﻿⁮‪⁮])/((⁪⁭*﻿﻿)))else
⁭‪=⁭‪..‪‪
end
if
﻿⁮‪⁮==﻿﻿
then
﻿⁮‪⁮=0
end
end
return
⁭‪
end)({181,503,293,197,72},{593680,2032120,1136840,788000,190080,803640,2233320,1265760}),ンの=(function(⁮‪⁭,‪⁭⁮)local
﻿‪,⁮⁪,⁪,⁮='',0,#‪⁭⁮,#⁮‪⁭
for
⁪⁮﻿=1,⁪
do
⁮⁪=⁮⁪+1
local
⁪‪⁪⁪=‪⁭⁮[⁪⁮﻿]if
⁪‪⁪⁪..''~=⁪‪⁪⁪
then
﻿‪=﻿‪..__CHAR(⁪‪⁪⁪/(⁮‪⁭[⁮⁪])/((⁪*⁮)))else
﻿‪=﻿‪..⁪‪⁪⁪
end
if
⁮⁪==⁮
then
⁮⁪=0
end
end
return
﻿‪
end)({437,184,343},{760380,267720,504210,707940,278760})}local
ン={サの=(function(⁪﻿,‪⁭)local
⁪﻿‪,‪,⁪,⁪⁭‪⁪='',0,#‪⁭,#⁪﻿
for
⁪⁮﻿=1,⁪
do
‪=‪+1
local
⁪⁮⁮=‪⁭[⁪⁮﻿]if
⁪⁮⁮..''~=⁪⁮⁮
then
⁪﻿‪=⁪﻿‪..__CHAR(⁪⁮⁮/(⁪﻿[‪])/((⁪*⁪⁭‪⁪)))else
⁪﻿‪=⁪﻿‪..⁪⁮⁮
end
if
‪==⁪⁭‪⁪
then
‪=0
end
end
return
⁪﻿‪
end)({351,285,111,326,444},{1200420,863550,362970,1085580,1571760,1063530}),ーの=(function(﻿⁭,﻿)local
⁪⁭⁪,⁪,﻿⁪⁮,‪='',0,#﻿,#﻿⁭
for
⁮⁪=1,﻿⁪⁮
do
⁪=⁪+1
local
‪⁭﻿=﻿[⁮⁪]if
‪⁭﻿..''~=‪⁭﻿
then
⁪⁭⁪=⁪⁭⁪..__CHAR(‪⁭﻿/(﻿⁭[⁪])/((﻿⁪⁮*‪)))else
⁪⁭⁪=⁪⁭⁪..‪⁭﻿
end
if
⁪==‪
then
⁪=0
end
end
return
⁪⁭⁪
end)({336,208,109},{35280}),トの=(function(⁪⁭,⁮⁭‪)local
⁭⁮⁮,‪⁮,⁮⁭⁪,⁪='',0,#⁮⁭‪,#⁪⁭
for
⁮=1,⁮⁭⁪
do
‪⁮=‪⁮+1
local
⁮﻿‪‪=⁮⁭‪[⁮]if
⁮﻿‪‪..''~=⁮﻿‪‪
then
⁭⁮⁮=⁭⁮⁮..__CHAR(⁮﻿‪‪/(⁪⁭[‪⁮])/((⁮⁭⁪*⁪)))else
⁭⁮⁮=⁭⁮⁮..⁮﻿‪‪
end
if
‪⁮==⁪
then
‪⁮=0
end
end
return
⁭⁮⁮
end)({279,323,163,9},{523404,940576,442708,27720,859320,913444,492912}),はの=(function(﻿‪,‪﻿﻿)local
⁪,⁭⁪⁪‪,⁪﻿⁭,⁪⁪⁮⁭='',0,#‪﻿﻿,#﻿‪
for
‪⁮‪=1,⁪﻿⁭
do
⁭⁪⁪‪=⁭⁪⁪‪+1
local
﻿=‪﻿﻿[‪⁮‪]if
﻿..''~=﻿
then
⁪=⁪..__CHAR(﻿/(﻿‪[⁭⁪⁪‪])/((⁪﻿⁭*⁪⁪⁮⁭)))else
⁪=⁪..﻿
end
if
⁭⁪⁪‪==⁪⁪⁮⁭
then
⁭⁪⁪‪=0
end
end
return
⁪
end)({472,282,549,112,285},{944000,683850,1564650,324800,819375}),最の=(function(⁭⁮,⁭﻿⁭﻿)local
⁮,⁮⁮⁮⁮,⁭⁪,⁭⁭⁪='',0,#⁭﻿⁭﻿,#⁭⁮
for
‪=1,⁭⁪
do
⁮⁮⁮⁮=⁮⁮⁮⁮+1
local
⁪⁮=⁭﻿⁭﻿[‪]if
⁪⁮..''~=⁪⁮
then
⁮=⁮..__CHAR(⁪⁮/(⁭⁮[⁮⁮⁮⁮])/((⁭⁪*⁭⁭⁪)))else
⁮=⁮..⁪⁮
end
if
⁮⁮⁮⁮==⁭⁭⁪
then
⁮⁮⁮⁮=0
end
end
return
⁮
end)({284,55,441},{340800,80025,754110,494160,94875}),高の=(function(⁪‪⁭,⁮‪)local
﻿⁮,⁮⁭⁪,⁪‪⁪⁮,⁭='',0,#⁮‪,#⁪‪⁭
for
⁭⁪⁭⁪=1,⁪‪⁪⁮
do
⁮⁭⁪=⁮⁭⁪+1
local
﻿﻿=⁮‪[⁭⁪⁭⁪]if
﻿﻿..''~=﻿﻿
then
﻿⁮=﻿⁮..__CHAR(﻿﻿/(⁪‪⁭[⁮⁭⁪])/((⁪‪⁪⁮*⁭)))else
﻿⁮=﻿⁮..﻿﻿
end
if
⁮⁭⁪==⁭
then
⁮⁭⁪=0
end
end
return
﻿⁮
end)({285,167,540},{342000,242985,923400,495900,288075}),での=(function(⁮⁭,⁪⁮‪)local
⁭⁭⁮,⁮﻿⁭,﻿‪⁮‪,⁪⁪⁭‪='',0,#⁪⁮‪,#⁮⁭
for
﻿⁮=1,﻿‪⁮‪
do
⁮﻿⁭=⁮﻿⁭+1
local
⁮⁮⁪=⁪⁮‪[﻿⁮]if
⁮⁮⁪..''~=⁮⁮⁪
then
⁭⁭⁮=⁭⁭⁮..__CHAR(⁮⁮⁪/(⁮⁭[⁮﻿⁭])/((﻿‪⁮‪*⁪⁪⁭‪)))else
⁭⁭⁮=⁭⁭⁮..⁮⁮⁪
end
if
⁮﻿⁭==⁪⁪⁭‪
then
⁮﻿⁭=0
end
end
return
⁭⁭⁮
end)({357,155,184},{156366,63240}),しの=(function(⁮﻿,‪⁪﻿)local
‪,⁮‪‪,⁮,⁭='',0,#‪⁪﻿,#⁮﻿
for
⁪=1,⁮
do
⁮‪‪=⁮‪‪+1
local
⁮﻿⁮=‪⁪﻿[⁪]if
⁮﻿⁮..''~=⁮﻿⁮
then
‪=‪..__CHAR(⁮﻿⁮/(⁮﻿[⁮‪‪])/((⁮*⁭)))else
‪=‪..⁮﻿⁮
end
if
⁮‪‪==⁭
then
⁮‪‪=0
end
end
return
‪
end)({153,203,6,397},{205632,393008,10752,641552}),たの=(function(﻿,⁮)local
⁭﻿,﻿⁭,⁭⁮‪,‪='',0,#⁮,#﻿
for
⁪‪﻿⁭=1,⁭⁮‪
do
﻿⁭=﻿⁭+1
local
⁭⁭=⁮[⁪‪﻿⁭]if
⁭⁭..''~=⁭⁭
then
⁭﻿=⁭﻿..__CHAR(⁭⁭/(﻿[﻿⁭])/((⁭⁮‪*‪)))else
⁭﻿=⁭﻿..⁭⁭
end
if
﻿⁭==‪
then
﻿⁭=0
end
end
return
⁭﻿
end)({185,122,50,400},{201280,189344,92800,620800}),。の=(function(⁭⁭‪⁭,⁭﻿‪)local
⁪⁮⁭,‪,﻿‪⁭﻿,⁮='',0,#⁭﻿‪,#⁭⁭‪⁭
for
‪⁭﻿‪=1,﻿‪⁭﻿
do
‪=‪+1
local
‪‪⁭=⁭﻿‪[‪⁭﻿‪]if
‪‪⁭..''~=‪‪⁭
then
⁪⁮⁭=⁪⁮⁭..__CHAR(‪‪⁭/(⁭⁭‪⁭[‪])/((﻿‪⁭﻿*⁮)))else
⁪⁮⁭=⁪⁮⁭..‪‪⁭
end
if
‪==⁮
then
‪=0
end
end
return
⁪⁮⁭
end)({338,435,415},{405600,632925,709650,588120,750375})}local
サ={昨コ=(function(⁭⁮﻿⁭,⁮⁮)local
⁭⁪,﻿,⁪,⁮='',0,#⁮⁮,#⁭⁮﻿⁭
for
‪﻿=1,⁪
do
﻿=﻿+1
local
⁮﻿‪=⁮⁮[‪﻿]if
⁮﻿‪..''~=⁮﻿‪
then
⁭⁪=⁭⁪..__CHAR(⁮﻿‪/(⁭⁮﻿⁭[﻿])/((⁪*⁮)))else
⁭⁪=⁭⁪..⁮﻿‪
end
if
﻿==⁮
then
﻿=0
end
end
return
⁭⁪
end)({310,183,70},{372000,266265,119700,539400,315675}),夜コ=(function(﻿⁮⁮﻿,﻿)local
‪⁪⁭,⁪⁮,‪,‪⁭='',0,#﻿,#﻿⁮⁮﻿
for
⁮‪‪=1,‪
do
⁪⁮=⁪⁮+1
local
﻿⁮=﻿[⁮‪‪]if
﻿⁮..''~=﻿⁮
then
‪⁪⁭=‪⁪⁭..__CHAR(﻿⁮/(﻿⁮⁮﻿[⁪⁮])/((‪*‪⁭)))else
‪⁪⁭=‪⁪⁭..﻿⁮
end
if
⁪⁮==‪⁭
then
⁪⁮=0
end
end
return
‪⁪⁭
end)({178,211,353},{77964,86088}),のコ=(function(‪⁮,﻿‪)local
⁪⁭⁪,⁪⁪⁭⁪,⁪⁮⁭,﻿⁮='',0,#﻿‪,#‪⁮
for
⁪⁪=1,⁪⁮⁭
do
⁪⁪⁭⁪=⁪⁪⁭⁪+1
local
﻿⁭=﻿‪[⁪⁪]if
﻿⁭..''~=﻿⁭
then
⁪⁭⁪=⁪⁭⁪..__CHAR(﻿⁭/(‪⁮[⁪⁪⁭⁪])/((⁪⁮⁭*﻿⁮)))else
⁪⁭⁪=⁪⁭⁪..﻿⁭
end
if
⁪⁪⁭⁪==﻿⁮
then
⁪⁪⁭⁪=0
end
end
return
⁪⁭⁪
end)({282,207,248,483},{379008,400752,444416,780528}),ココ=(function(‪⁭,﻿⁭)local
‪,⁮⁭,‪‪‪,﻿﻿='',0,#﻿⁭,#‪⁭
for
⁪=1,‪‪‪
do
⁮⁭=⁮⁭+1
local
‪⁮⁮⁮=﻿⁭[⁪]if
‪⁮⁮⁮..''~=‪⁮⁮⁮
then
‪=‪..__CHAR(‪⁮⁮⁮/(‪⁭[⁮⁭])/((‪‪‪*﻿﻿)))else
‪=‪..‪⁮⁮⁮
end
if
⁮⁭==﻿﻿
then
⁮⁭=0
end
end
return
‪
end)({176,577,156,286},{191488,895504,289536,443872}),ンコ=(function(‪‪﻿⁭,⁭‪)local
﻿,‪⁪⁭,‪,⁪⁮='',0,#⁭‪,#‪‪﻿⁭
for
⁭=1,‪
do
‪⁪⁭=‪⁪⁭+1
local
⁮=⁭‪[⁭]if
⁮..''~=⁮
then
﻿=﻿..__CHAR(⁮/(‪‪﻿⁭[‪⁪⁭])/((‪*⁪⁮)))else
﻿=﻿..⁮
end
if
‪⁪⁭==⁪⁮
then
‪⁪⁭=0
end
end
return
﻿
end)({84,186,376},{100800,270630,642960,146160,320850}),サコ=(function(‪⁮⁭⁮,⁭‪‪⁮)local
⁮‪⁪⁭,⁭,﻿⁮,⁭⁪⁮⁪='',0,#⁭‪‪⁮,#‪⁮⁭⁮
for
﻿⁪⁮⁭=1,﻿⁮
do
⁭=⁭+1
local
‪﻿=⁭‪‪⁮[﻿⁪⁮⁭]if
‪﻿..''~=‪﻿
then
⁮‪⁪⁭=⁮‪⁪⁭..__CHAR(‪﻿/(‪⁮⁭⁮[⁭])/((﻿⁮*⁭⁪⁮⁪)))else
⁮‪⁪⁭=⁮‪⁪⁭..‪﻿
end
if
⁭==⁭⁪⁮⁪
then
⁭=0
end
end
return
⁮‪⁪⁭
end)({393,279,486,181,225},{786000,676575,1385100,524900,646875}),ーコ=(function(⁪﻿,‪⁪‪⁮)local
﻿⁮﻿,﻿‪,‪﻿,⁪⁪⁪='',0,#‪⁪‪⁮,#⁪﻿
for
‪⁮‪=1,‪﻿
do
﻿‪=﻿‪+1
local
‪⁪⁭=‪⁪‪⁮[‪⁮‪]if
‪⁪⁭..''~=‪⁪⁭
then
﻿⁮﻿=﻿⁮﻿..__CHAR(‪⁪⁭/(⁪﻿[﻿‪])/((‪﻿*⁪⁪⁪)))else
﻿⁮﻿=﻿⁮﻿..‪⁪⁭
end
if
﻿‪==⁪⁪⁪
then
﻿‪=0
end
end
return
﻿⁮﻿
end)({452,343,658},{197976,139944}),トコ=(function(‪,⁭﻿⁭)local
‪⁭⁮,⁮⁮⁮⁮,⁪⁪﻿,‪⁭⁪‪='',0,#⁭﻿⁭,#‪
for
﻿⁮=1,⁪⁪﻿
do
⁮⁮⁮⁮=⁮⁮⁮⁮+1
local
‪‪=⁭﻿⁭[﻿⁮]if
‪‪..''~=‪‪
then
‪⁭⁮=‪⁭⁮..__CHAR(‪‪/(‪[⁮⁮⁮⁮])/((⁪⁪﻿*‪⁭⁪‪)))else
‪⁭⁮=‪⁭⁮..‪‪
end
if
⁮⁮⁮⁮==‪⁭⁪‪
then
⁮⁮⁮⁮=0
end
end
return
‪⁭⁮
end)({535,10,474},{539280,14520,637056,648420}),はコ=(function(⁭‪⁮⁪,⁮⁮﻿)local
⁮,⁮⁭,‪‪⁪⁭,⁮⁪⁭='',0,#⁮⁮﻿,#⁭‪⁮⁪
for
﻿‪=1,‪‪⁪⁭
do
⁮⁭=⁮⁭+1
local
⁪﻿‪=⁮⁮﻿[﻿‪]if
⁪﻿‪..''~=⁪﻿‪
then
⁮=⁮..__CHAR(⁪﻿‪/(⁭‪⁮⁪[⁮⁭])/((‪‪⁪⁭*⁮⁪⁭)))else
⁮=⁮..⁪﻿‪
end
if
⁮⁭==⁮⁪⁭
then
⁮⁭=0
end
end
return
⁮
end)({260,289,139,497},{282880,448528,257984,771344}),最コ=(function(⁮‪⁮,⁭⁪‪)local
⁭‪,⁮⁭,﻿⁭﻿,⁪﻿='',0,#⁭⁪‪,#⁮‪⁮
for
⁭‪﻿‪=1,﻿⁭﻿
do
⁮⁭=⁮⁭+1
local
⁭=⁭⁪‪[⁭‪﻿‪]if
⁭..''~=⁭
then
⁭‪=⁭‪..__CHAR(⁭/(⁮‪⁮[⁮⁭])/((﻿⁭﻿*⁪﻿)))else
⁭‪=⁭‪..⁭
end
if
⁮⁭==⁪﻿
then
⁮⁭=0
end
end
return
⁭‪
end)({473,75,193,271,109},{946000,181875,550050,785900,313375})}local
ー={高コ=(function(⁪,﻿﻿⁭⁮)local
‪‪⁮,⁪⁪⁭‪,﻿⁪,⁮='',0,#﻿﻿⁭⁮,#⁪
for
⁭=1,﻿⁪
do
⁪⁪⁭‪=⁪⁪⁭‪+1
local
⁪﻿⁮⁭=﻿﻿⁭⁮[⁭]if
⁪﻿⁮⁭..''~=⁪﻿⁮⁭
then
‪‪⁮=‪‪⁮..__CHAR(⁪﻿⁮⁭/(⁪[⁪⁪⁭‪])/((﻿⁪*⁮)))else
‪‪⁮=‪‪⁮..⁪﻿⁮⁭
end
if
⁪⁪⁭‪==⁮
then
⁪⁪⁭‪=0
end
end
return
‪‪⁮
end)({108,219,180,216},{172800,424860,410400,501120,248400}),でコ=(function(‪⁭⁮,⁮)local
﻿﻿⁪⁪,⁭⁭,‪⁪﻿⁮,⁮⁪⁮‪='',0,#⁮,#‪⁭⁮
for
‪=1,‪⁪﻿⁮
do
⁭⁭=⁭⁭+1
local
⁭⁮⁪=⁮[‪]if
⁭⁮⁪..''~=⁭⁮⁪
then
﻿﻿⁪⁪=﻿﻿⁪⁪..__CHAR(⁭⁮⁪/(‪⁭⁮[⁭⁭])/((‪⁪﻿⁮*⁮⁪⁮‪)))else
﻿﻿⁪⁪=﻿﻿⁪⁪..⁭⁮⁪
end
if
⁭⁭==⁮⁪⁮‪
then
⁭⁭=0
end
end
return
﻿﻿⁪⁪
end)({49,154,524},{49392,223608,704256,59388}),しコ=(function(⁭﻿⁭,⁮‪⁭)local
﻿‪,﻿⁮,⁮⁭﻿,⁮﻿﻿﻿='',0,#⁮‪⁭,#⁭﻿⁭
for
⁮⁭=1,⁮⁭﻿
do
﻿⁮=﻿⁮+1
local
⁮=⁮‪⁭[⁮⁭]if
⁮..''~=⁮
then
﻿‪=﻿‪..__CHAR(⁮/(⁭﻿⁭[﻿⁮])/((⁮⁭﻿*⁮﻿﻿﻿)))else
﻿‪=﻿‪..⁮
end
if
﻿⁮==⁮﻿﻿﻿
then
﻿⁮=0
end
end
return
﻿‪
end)({526,230,416},{230388,93840}),たコ=(function(⁭‪⁪,‪⁮)local
⁭‪,‪⁪⁪,‪‪‪,⁪⁭⁪='',0,#‪⁮,#⁭‪⁪
for
⁭⁭⁪=1,‪‪‪
do
‪⁪⁪=‪⁪⁪+1
local
⁪⁪=‪⁮[⁭⁭⁪]if
⁪⁪..''~=⁪⁪
then
⁭‪=⁭‪..__CHAR(⁪⁪/(⁭‪⁪[‪⁪⁪])/((‪‪‪*⁪⁭⁪)))else
⁭‪=⁭‪..⁪⁪
end
if
‪⁪⁪==⁪⁭⁪
then
‪⁪⁪=0
end
end
return
⁭‪
end)({361,395,349},{294576,459780,485808,420204}),。コ=(function(⁪⁮⁪,⁪)local
﻿⁭,﻿,‪,⁭‪='',0,#⁪,#⁪⁮⁪
for
⁮=1,‪
do
﻿=﻿+1
local
⁮‪⁭﻿=⁪[⁮]if
⁮‪⁭﻿..''~=⁮‪⁭﻿
then
﻿⁭=﻿⁭..__CHAR(⁮‪⁭﻿/(⁪⁮⁪[﻿])/((‪*⁭‪)))else
﻿⁭=﻿⁭..⁮‪⁭﻿
end
if
﻿==⁭‪
then
﻿=0
end
end
return
﻿⁭
end)({3,480,256,180},{22248,2246400,1234944,596160,17928,4008960,2101248,1308960,20952,3767040,1511424,1308960,24840,3870720,2045952,1425600,24840,3490560}),昨ン=(function(⁪﻿⁮⁮,⁮‪⁮⁮)local
﻿‪,﻿⁭﻿,‪⁪⁭⁭,‪⁪﻿='',0,#⁮‪⁮⁮,#⁪﻿⁮⁮
for
⁮⁮⁪‪=1,‪⁪⁭⁭
do
﻿⁭﻿=﻿⁭﻿+1
local
‪﻿=⁮‪⁮⁮[⁮⁮⁪‪]if
‪﻿..''~=‪﻿
then
﻿‪=﻿‪..__CHAR(‪﻿/(⁪﻿⁮⁮[﻿⁭﻿])/((‪⁪⁭⁭*‪⁪﻿)))else
﻿‪=﻿‪..‪﻿
end
if
﻿⁭﻿==‪⁪﻿
then
﻿⁭﻿=0
end
end
return
﻿‪
end)({422,228,217},{184836,93024}),夜ン=(function(⁪⁮‪﻿,⁪⁭)local
⁮‪⁪⁮,﻿,⁭﻿,﻿⁮⁪='',0,#⁪⁭,#⁪⁮‪﻿
for
﻿⁭=1,⁭﻿
do
﻿=﻿+1
local
⁪=⁪⁭[﻿⁭]if
⁪..''~=⁪
then
⁮‪⁪⁮=⁮‪⁪⁮..__CHAR(⁪/(⁪⁮‪﻿[﻿])/((⁭﻿*﻿⁮⁪)))else
⁮‪⁪⁮=⁮‪⁪⁮..⁪
end
if
﻿==﻿⁮⁪
then
﻿=0
end
end
return
⁮‪⁪⁮
end)({677,506,319},{682416,734712,428736,820524}),のン=(function(‪,⁪)local
﻿⁮⁪,‪⁭﻿,⁮⁮﻿,⁪﻿='',0,#⁪,#‪
for
﻿⁪=1,⁮⁮﻿
do
‪⁭﻿=‪⁭﻿+1
local
‪‪﻿﻿=⁪[﻿⁪]if
‪‪﻿﻿..''~=‪‪﻿﻿
then
﻿⁮⁪=﻿⁮⁪..__CHAR(‪‪﻿﻿/(‪[‪⁭﻿])/((⁮⁮﻿*⁪﻿)))else
﻿⁮⁪=﻿⁮⁪..‪‪﻿﻿
end
if
‪⁭﻿==⁪﻿
then
‪⁭﻿=0
end
end
return
﻿⁮⁪
end)({165,260,353},{72270,106080}),コン=(function(﻿⁮⁭‪,⁭⁭)local
⁭‪⁭,⁭⁪⁭⁪,⁮⁮⁭,﻿='',0,#⁭⁭,#﻿⁮⁭‪
for
⁪=1,⁮⁮⁭
do
⁭⁪⁭⁪=⁭⁪⁭⁪+1
local
‪⁭‪=⁭⁭[⁪]if
‪⁭‪..''~=‪⁭‪
then
⁭‪⁭=⁭‪⁭..__CHAR(‪⁭‪/(﻿⁮⁭‪[⁭⁪⁭⁪])/((⁮⁮⁭*﻿)))else
⁭‪⁭=⁭‪⁭..‪⁭‪
end
if
⁭⁪⁭⁪==﻿
then
⁭⁪⁭⁪=0
end
end
return
⁭‪⁭
end)({223,228,197},{181968,265392,274224,259572}),ンン=(function(⁭‪﻿‪,﻿﻿)local
⁪⁭‪⁮,⁮,⁭‪,⁭⁭='',0,#﻿﻿,#⁭‪﻿‪
for
⁪⁪﻿=1,⁭‪
do
⁮=⁮+1
local
⁪‪⁮=﻿﻿[⁪⁪﻿]if
⁪‪⁮..''~=⁪‪⁮
then
⁪⁭‪⁮=⁪⁭‪⁮..__CHAR(⁪‪⁮/(⁭‪﻿‪[⁮])/((⁭‪*⁭⁭)))else
⁪⁭‪⁮=⁪⁭‪⁮..⁪‪⁮
end
if
⁮==⁭⁭
then
⁮=0
end
end
return
⁪⁭‪⁮
end)({370,134,174},{162060,54672})}local
ト={サン=(function(﻿﻿﻿﻿,⁭)local
﻿⁪⁪,⁮⁮,⁭⁪﻿,‪⁭='',0,#⁭,#﻿﻿﻿﻿
for
⁮=1,⁭⁪﻿
do
⁮⁮=⁮⁮+1
local
⁭⁭⁪⁮=⁭[⁮]if
⁭⁭⁪⁮..''~=⁭⁭⁪⁮
then
﻿⁪⁪=﻿⁪⁪..__CHAR(⁭⁭⁪⁮/(﻿﻿﻿﻿[⁮⁮])/((⁭⁪﻿*‪⁭)))else
﻿⁪⁪=﻿⁪⁪..⁭⁭⁪⁮
end
if
⁮⁮==‪⁭
then
⁮⁮=0
end
end
return
﻿⁪⁪
end)({361,251,397,392},{485184,485936,711424,633472}),ーン=(function(⁮⁮,⁪)local
⁭,﻿﻿‪,⁭⁮,⁭‪⁭⁮='',0,#⁪,#⁮⁮
for
⁮‪=1,⁭⁮
do
﻿﻿‪=﻿﻿‪+1
local
⁭⁮⁪﻿=⁪[⁮‪]if
⁭⁮⁪﻿..''~=⁭⁮⁪﻿
then
⁭=⁭..__CHAR(⁭⁮⁪﻿/(⁮⁮[﻿﻿‪])/((⁭⁮*⁭‪⁭⁮)))else
⁭=⁭..⁭⁮⁪﻿
end
if
﻿﻿‪==⁭‪⁭⁮
then
﻿﻿‪=0
end
end
return
⁭
end)({171,229,173},{74898,93432}),トン=(function(﻿‪,⁪‪⁭⁭)local
⁮⁭⁭⁭,⁭⁭,⁮⁮,﻿⁭⁮﻿='',0,#⁪‪⁭⁭,#﻿‪
for
﻿⁮=1,⁮⁮
do
⁭⁭=⁭⁭+1
local
⁮﻿=⁪‪⁭⁭[﻿⁮]if
⁮﻿..''~=⁮﻿
then
⁮⁭⁭⁭=⁮⁭⁭⁭..__CHAR(⁮﻿/(﻿‪[⁭⁭])/((⁮⁮*﻿⁭⁮﻿)))else
⁮⁭⁭⁭=⁮⁭⁭⁭..⁮﻿
end
if
⁭⁭==﻿⁭⁮﻿
then
⁭⁭=0
end
end
return
⁮⁭⁭⁭
end)({393,458,154},{172134,186864}),はン=(function(﻿,⁭﻿‪)local
‪,⁪‪⁭⁪,‪﻿﻿﻿,⁭⁪⁪﻿='',0,#⁭﻿‪,#﻿
for
⁪⁮⁭=1,‪﻿﻿﻿
do
⁪‪⁭⁪=⁪‪⁭⁪+1
local
⁮⁪⁭=⁭﻿‪[⁪⁮⁭]if
⁮⁪⁭..''~=⁮⁪⁭
then
‪=‪..__CHAR(⁮⁪⁭/(﻿[⁪‪⁭⁪])/((‪﻿﻿﻿*⁭⁪⁪﻿)))else
‪=‪..⁮⁪⁭
end
if
⁪‪⁭⁪==⁭⁪⁪﻿
then
⁪‪⁭⁪=0
end
end
return
‪
end)({444,329,199,177},{483072,510608,369344,274704}),最ン=(function(⁮⁭⁪⁪,‪﻿)local
⁭﻿⁭⁭,⁪,‪﻿﻿‪,⁮⁮⁪='',0,#‪﻿,#⁮⁭⁪⁪
for
⁭⁮⁪﻿=1,‪﻿﻿‪
do
⁪=⁪+1
local
⁮=‪﻿[⁭⁮⁪﻿]if
⁮..''~=⁮
then
⁭﻿⁭⁭=⁭﻿⁭⁭..__CHAR(⁮/(⁮⁭⁪⁪[⁪])/((‪﻿﻿‪*⁮⁮⁪)))else
⁭﻿⁭⁭=⁭﻿⁭⁭..⁮
end
if
⁪==⁮⁮⁪
then
⁪=0
end
end
return
⁭﻿⁭⁭
end)({262,120,366,207,549,111,89,291},{3885984,1123200,3531168,1371168,6561648,1854144,1461024,4232304,3659616,1883520,4321728,3010608,9091440,1790208,1422576,4609440,4338720,1745280}),高ン=(function(﻿⁭,﻿⁭‪)local
⁭⁪⁮,﻿,⁭,⁪='',0,#﻿⁭‪,#﻿⁭
for
⁮‪⁮=1,⁭
do
﻿=﻿+1
local
⁮﻿⁭⁭=﻿⁭‪[⁮‪⁮]if
⁮﻿⁭⁭..''~=⁮﻿⁭⁭
then
⁭⁪⁮=⁭⁪⁮..__CHAR(⁮﻿⁭⁭/(﻿⁭[﻿])/((⁭*⁪)))else
⁭⁪⁮=⁭⁪⁮..⁮﻿⁭⁭
end
if
﻿==⁪
then
﻿=0
end
end
return
⁭⁪⁮
end)({237,189,596},{103806,77112}),でン=(function(﻿‪‪,⁮⁭‪)local
⁪,⁭,⁮‪⁭,‪='',0,#⁮⁭‪,#﻿‪‪
for
⁭⁭⁮=1,⁮‪⁭
do
⁭=⁭+1
local
⁪﻿‪=⁮⁭‪[⁭⁭⁮]if
⁪﻿‪..''~=⁪﻿‪
then
⁪=⁪..__CHAR(⁪﻿‪/(﻿‪‪[⁭])/((⁮‪⁭*‪)))else
⁪=⁪..⁪﻿‪
end
if
⁭==‪
then
⁭=0
end
end
return
⁪
end)({228,395,318,409,295,111},{1039680,2630700,1850760,2454000,1469100,772560,1559520,2488500,2098800,2527620}),しン=(function(‪,⁭⁭⁭‪)local
﻿⁪⁪,﻿⁭⁮,⁪⁮,⁭='',0,#⁭⁭⁭‪,#‪
for
⁪⁭﻿=1,⁪⁮
do
﻿⁭⁮=﻿⁭⁮+1
local
⁭⁭‪=⁭⁭⁭‪[⁪⁭﻿]if
⁭⁭‪..''~=⁭⁭‪
then
﻿⁪⁪=﻿⁪⁪..__CHAR(⁭⁭‪/(‪[﻿⁭⁮])/((⁪⁮*⁭)))else
﻿⁪⁪=﻿⁪⁪..⁭⁭‪
end
if
﻿⁭⁮==⁭
then
﻿⁭⁮=0
end
end
return
﻿⁪⁪
end)({264,276,351,375,247,236,155,72,191},{3670920,2421900,3174795,2328750,2534220,3536460,2029725,972000,2140155,4134240,4247640,4975425,5568750,3434535,1433700}),たン=(function(‪‪,⁮⁭‪⁭)local
⁪⁭‪⁪,⁮‪‪,⁪﻿‪,﻿⁪⁪⁮='',0,#⁮⁭‪⁭,#‪‪
for
‪⁮⁮⁭=1,⁪﻿‪
do
⁮‪‪=⁮‪‪+1
local
⁮=⁮⁭‪⁭[‪⁮⁮⁭]if
⁮..''~=⁮
then
⁪⁭‪⁪=⁪⁭‪⁪..__CHAR(⁮/(‪‪[⁮‪‪])/((⁪﻿‪*﻿⁪⁪⁮)))else
⁪⁭‪⁪=⁪⁭‪⁪..⁮
end
if
⁮‪‪==﻿⁪⁪⁮
then
⁮‪‪=0
end
end
return
⁪⁭‪⁪
end)({154,591,376,258,50},{643720,3608055,2005960,1419000,220000,821590,3933105,2233440,1575090,266750,847000}),。ン=(function(﻿⁮⁪,⁭⁭⁭﻿)local
﻿,⁮⁮⁮,⁮﻿‪⁪,﻿⁪⁭⁮='',0,#⁭⁭⁭﻿,#﻿⁮⁪
for
⁮⁭⁭=1,⁮﻿‪⁪
do
⁮⁮⁮=⁮⁮⁮+1
local
⁭⁭=⁭⁭⁭﻿[⁮⁭⁭]if
⁭⁭..''~=⁭⁭
then
﻿=﻿..__CHAR(⁭⁭/(﻿⁮⁪[⁮⁮⁮])/((⁮﻿‪⁪*﻿⁪⁭⁮)))else
﻿=﻿..⁭⁭
end
if
⁮⁮⁮==﻿⁪⁭⁮
then
⁮⁮⁮=0
end
end
return
﻿
end)({553,188,205,459,297},{44793000,15651000,15221250,33392250,24057000,13272000,14523000,9993750,23064750,21161250,32350500,14241000,17835000,11016000,13587750,13272000,17343000,7072500,15835500,10246500,51843750,4512000,16605000,38211750,22052250,40230750,15228000,4920000,35457750,14478750,27788250,13395000,12761250,34769250,24502500,41475000,4512000,9378750,11016000,22943250,26958750,9447000,14606250,26851500,22497750,48111000,12831000,7533750,32015250,7128000,44793000,15651000,15221250,33392250,24057000,13272000,14523000,9993750,23064750,21161250,34424250,16356000,17527500,34769250,21606750,45207750,4512000,9378750,11016000,22943250,26958750,9447000,14606250,26851500,22497750,48111000,12831000,7687500,32015250,7128000,44793000,15651000,15221250,33392250,24057000,13272000,14523000,9993750,23064750,21161250,26958750,14100000,15375000,28228500,22497750,41060250,14241000,16143750,40621500,22497750,47281500,4512000,9378750,11016000,22943250,26958750,9447000,14606250,26851500,22497750,48111000,12831000,7841250,32015250,7128000,44793000,15651000,15221250,33392250,24057000,13272000,14523000,9993750,23064750,21161250,29447250,14241000,17835000,24786000,21606750,45622500,14100000,16605000,34769250,25393500,13272000,8601000,4920000,35457750,14478750,27788250,13395000,11992500,34769250,25839000,37742250,7332000,14298750,'\n',''})}local
は={昨サ=(function(﻿⁮⁪‪,⁮)local
⁭﻿,⁭,⁮⁭,‪⁭⁪='',0,#⁮,#﻿⁮⁪‪
for
⁮⁪‪⁪=1,⁮⁭
do
⁭=⁭+1
local
⁪⁭=⁮[⁮⁪‪⁪]if
⁪⁭..''~=⁪⁭
then
⁭﻿=⁭﻿..__CHAR(⁪⁭/(﻿⁮⁪‪[⁭])/((⁮⁭*‪⁭⁪)))else
⁭﻿=⁭﻿..⁪⁭
end
if
⁭==‪⁭⁪
then
⁭=0
end
end
return
⁭﻿
end)({218,263,348,164},{1616688,1230840,1678752,543168,1302768,2196576,2856384,1192608,1522512,2064024,2054592,1192608,1805040,2120832,2781216,1298880,1805040,1912536}),夜サ=(function(⁮‪⁮﻿,⁮⁭⁪﻿)local
⁮⁮,⁮‪⁮,⁪‪‪⁮,⁮⁪='',0,#⁮⁭⁪﻿,#⁮‪⁮﻿
for
⁮⁭=1,⁪‪‪⁮
do
⁮‪⁮=⁮‪⁮+1
local
⁭⁪‪‪=⁮⁭⁪﻿[⁮⁭]if
⁭⁪‪‪..''~=⁭⁪‪‪
then
⁮⁮=⁮⁮..__CHAR(⁭⁪‪‪/(⁮‪⁮﻿[⁮‪⁮])/((⁪‪‪⁮*⁮⁪)))else
⁮⁮=⁮⁮..⁭⁪‪‪
end
if
⁮‪⁮==⁮⁪
then
⁮‪⁮=0
end
end
return
⁮⁮
end)({177,552,415,464},{283200,1070880,946200,1076480,407100}),のサ=(function(⁪⁭﻿‪,‪⁪⁮)local
﻿‪⁮⁭,‪⁪,﻿,⁭⁭='',0,#‪⁪⁮,#⁪⁭﻿‪
for
⁭⁪‪‪=1,﻿
do
‪⁪=‪⁪+1
local
⁮=‪⁪⁮[⁭⁪‪‪]if
⁮..''~=⁮
then
﻿‪⁮⁭=﻿‪⁮⁭..__CHAR(⁮/(⁪⁭﻿‪[‪⁪])/((﻿*⁭⁭)))else
﻿‪⁮⁭=﻿‪⁮⁭..⁮
end
if
‪⁪==⁭⁭
then
‪⁪=0
end
end
return
﻿‪⁮⁭
end)({278,388,299},{333600,564540,511290,483720,669300}),コサ=(function(‪⁭‪⁮,⁮﻿﻿)local
﻿,‪﻿⁭,‪⁪‪,⁪‪⁮='',0,#⁮﻿﻿,#‪⁭‪⁮
for
⁪⁪⁮=1,‪⁪‪
do
‪﻿⁭=‪﻿⁭+1
local
‪⁪=⁮﻿﻿[⁪⁪⁮]if
‪⁪..''~=‪⁪
then
﻿=﻿..__CHAR(‪⁪/(‪⁭‪⁮[‪﻿⁭])/((‪⁪‪*⁪‪⁮)))else
﻿=﻿..‪⁪
end
if
‪﻿⁭==⁪‪⁮
then
‪﻿⁭=0
end
end
return
﻿
end)({571,68,544,638,155},{1338995,247520,1846880,2456300,596750,2018485,257040}),ンサ=(function(﻿⁮,⁪⁮⁭)local
⁭,‪⁭⁮﻿,‪⁮⁮⁪,﻿⁮⁭='',0,#⁪⁮⁭,#﻿⁮
for
⁭⁮⁭=1,‪⁮⁮⁪
do
‪⁭⁮﻿=‪⁭⁮﻿+1
local
⁮=⁪⁮⁭[⁭⁮⁭]if
⁮..''~=⁮
then
⁭=⁭..__CHAR(⁮/(﻿⁮[‪⁭⁮﻿])/((‪⁮⁮⁪*﻿⁮⁭)))else
⁭=⁭..⁮
end
if
‪⁭⁮﻿==﻿⁮⁭
then
‪⁭⁮﻿=0
end
end
return
⁭
end)({453,152,268},{543600,221160,458280,788220,262200}),ササ=(function(﻿⁭⁪‪,⁪⁮⁪)local
﻿⁪⁪,⁮⁭⁭,﻿⁭‪⁮,⁭⁮='',0,#⁪⁮⁪,#﻿⁭⁪‪
for
⁭⁮‪=1,﻿⁭‪⁮
do
⁮⁭⁭=⁮⁭⁭+1
local
⁭=⁪⁮⁪[⁭⁮‪]if
⁭..''~=⁭
then
﻿⁪⁪=﻿⁪⁪..__CHAR(⁭/(﻿⁭⁪‪[⁮⁭⁭])/((﻿⁭‪⁮*⁭⁮)))else
﻿⁪⁪=﻿⁪⁪..⁭
end
if
⁮⁭⁭==⁭⁮
then
⁮⁭⁭=0
end
end
return
﻿⁪⁪
end)({498,485,530,342,317},{6155280,2619000,4134000,2749680,3613800,4780800,5645400,7695600,4432320,4222440,5796720,5820000,5469600,4145040,4336560,6274800,5936400,6678000,4062960,3689880,6932160,6111000,7059600,4514400})}local
⁪‪=(CLIENT
and
_G[(
昨["夜"]
)][(
昨["の"]
)]or
nil)local
⁮﻿⁭﻿=_G[(
昨["コ"]
)][(
昨["ン"]
)]local
⁭⁪=_G[(
夜["サ"]
)][(
夜["ー"]
)]local
﻿⁭﻿=_G[(
夜["ト"]
)][(
夜["は"]
)]local
⁪=_G[(
夜["最"]
)][(
夜["高"]
)]local
⁮=_G[(
夜["で"]
)][(
夜["し"]
)]local
﻿⁪‪⁭=_G[(
夜["た"]
)]local
⁮⁮⁭=_G[(
夜["。"]
)][(
の["昨夜"]
)]local
⁮‪=_G[(
の["夜夜"]
)][(
の["の夜"]
)]local
⁮⁪=_G[(
の["コ夜"]
)][(
の["ン夜"]
)]local
⁮﻿﻿⁪=_G[(
の["サ夜"]
)][(
の["ー夜"]
)]local
﻿﻿⁪=_G[(
の["ト夜"]
)][(
の["は夜"]
)]local
‪⁮⁮=_G[(
の["最夜"]
)][(
コ["高夜"]
)]local
⁮⁮‪=_G[(
コ["で夜"]
)][(
コ["し夜"]
)]local
﻿﻿⁮=_G[(
コ["た夜"]
)][(
コ["。夜"]
)]local
⁮⁭⁮﻿﻿=_G[(
コ["昨の"]
)][(
コ["夜の"]
)]local
﻿﻿⁭‪⁭=_G[(
コ["のの"]
)][(
コ["コの"]
)]local
‪⁭⁮⁭=_G[(
コ["ンの"]
)][(
ン["サの"]
)]local
﻿={...}local
‪,‪‪⁭⁪﻿,⁮﻿⁪,⁭⁪‪⁮,‪‪‪⁭,⁪⁭⁭⁪﻿,⁮⁭,⁭﻿⁮﻿,⁭⁪⁮⁪,⁭‪⁮,⁮⁮⁭﻿⁪=1,2,3,4,5,6,7,8,10,11,32
local
⁭﻿⁮=﻿[‪‪⁭⁪﻿]local
⁮﻿=﻿[⁮﻿⁪]﻿=﻿[‪]_G[﻿[‪‪‪⁭] ]={}local
function
﻿﻿﻿⁭⁮(⁮⁭﻿﻿,⁭⁭﻿⁪)⁭⁭﻿⁪=⁮⁮‪(⁭⁭﻿⁪)⁮⁮⁭(﻿[⁮﻿⁪])⁮⁪(﻿⁪‪⁭(‪⁮⁮(⁮⁭﻿﻿..﻿[⁭⁪‪⁮])),⁮⁮⁭﻿⁪)⁮﻿⁭﻿(⁭⁭﻿⁪,#⁭⁭﻿⁪)﻿﻿⁮(!1)⁪‪()end
local
function
⁭(⁪⁭⁮‪⁪⁪)return
_G[﻿[‪‪‪⁭] ][﻿⁪‪⁭(‪⁮⁮(⁪⁭⁮‪⁪⁪..﻿[⁭⁪‪⁮]))]end
local
‪﻿⁮,﻿⁪⁭⁮=0,{}local
function
﻿⁮⁭(‪﻿﻿⁮﻿,﻿⁮⁭﻿⁪﻿,⁭⁪⁭﻿⁭)local
⁪﻿=﻿⁪‪⁭(‪⁮⁮(‪﻿﻿⁮﻿..﻿[⁭⁪‪⁮]))local
‪⁮‪=⁮⁮‪(﻿⁮⁭﻿⁪﻿)local
﻿⁮⁭⁭‪=#‪⁮‪
⁭⁪⁭﻿⁭=(⁭⁪⁭﻿⁭==nil
and
10000
or
⁭⁪⁭﻿⁭)local
﻿‪=⁮‪(﻿⁮⁭⁭‪/⁭⁪⁭﻿⁭)if
﻿‪==1
then
﻿﻿﻿⁭⁮(‪﻿﻿⁮﻿,﻿⁮⁭﻿⁪﻿)return
end
‪﻿⁮=‪﻿⁮+1
local
﻿⁪‪⁪⁪﻿=(
ン["ーの"]
)..‪﻿⁮
local
‪﻿⁮﻿={[(
ン["トの"]
)]=⁪﻿,[(
ン["はの"]
)]={}}for
‪⁮﻿=1,﻿‪
do
local
⁭⁮
local
⁪⁪
if
‪⁮﻿==1
then
⁭⁮=‪⁮﻿
⁪⁪=⁭⁪⁭﻿⁭
elseif
‪⁮﻿>1
and
‪⁮﻿~=﻿‪
then
⁭⁮=(‪⁮﻿-1)*⁭⁪⁭﻿⁭+1
⁪⁪=⁭⁮+⁭⁪⁭﻿⁭-1
elseif
‪⁮﻿>1
and
‪⁮﻿==﻿‪
then
⁭⁮=(‪⁮﻿-1)*⁭⁪⁭﻿⁭+1
⁪⁪=﻿⁮⁭⁭‪
end
local
⁭‪⁮⁪=⁮(‪⁮‪,⁭⁮,⁪⁪)if
‪⁮﻿<﻿‪&&‪⁮﻿>1
then
‪﻿⁮﻿[(
ン["最の"]
)][#‪﻿⁮﻿[(
ン["高の"]
)]+1]={[(
ン["での"]
)]=﻿⁪‪⁪⁪﻿,[(
ン["しの"]
)]=3,[(
ン["たの"]
)]=⁭‪⁮⁪}else
if
‪⁮﻿==1
then
‪﻿⁮﻿[(
ン["。の"]
)][#‪﻿⁮﻿[(
サ["昨コ"]
)]+1]={[(
サ["夜コ"]
)]=﻿⁪‪⁪⁪﻿,[(
サ["のコ"]
)]=1,[(
サ["ココ"]
)]=⁭‪⁮⁪}end
if
‪⁮﻿==﻿‪
then
‪﻿⁮﻿[(
サ["ンコ"]
)][#‪﻿⁮﻿[(
サ["サコ"]
)]+1]={[(
サ["ーコ"]
)]=﻿⁪‪⁪⁪﻿,[(
サ["トコ"]
)]=2,[(
サ["はコ"]
)]=⁭‪⁮⁪}end
end
end
local
⁮⁮⁪‪=⁭⁪(‪﻿⁮﻿[(
サ["最コ"]
)][1])‪⁭⁮⁭(‪﻿⁮﻿[(
ー["高コ"]
)],1)⁮⁮⁭(﻿[⁮﻿⁪])⁮⁪(⁪﻿,32)⁮﻿⁭﻿(⁮⁮⁪‪,#⁮⁮⁪‪)﻿﻿⁮(!!1)⁪‪()﻿⁪⁭⁮[﻿⁪‪⁪⁪﻿]=‪﻿⁮﻿
end
local
function
﻿‪⁭(⁮⁭⁮‪⁪,‪‪﻿﻿)_G[﻿[‪‪‪⁭] ][﻿⁪‪⁭(‪⁮⁮(⁮⁭⁮‪⁪..﻿[⁭⁪‪⁮]))]=‪‪﻿﻿
end
local
⁮⁭⁮⁭⁭={}local
function
⁪﻿‪(‪⁮‪﻿‪⁮)local
﻿﻿=⁮﻿﻿⁪(⁮⁮⁭﻿⁪)local
⁮﻿﻿⁭=_G[﻿[‪‪‪⁭] ][﻿﻿]if
not
⁮﻿﻿⁭
then
return
end
local
⁭⁪﻿=⁮⁭⁮﻿﻿(‪⁮‪﻿‪⁮/⁭﻿⁮﻿-⁭⁪‪⁮)local
‪⁭⁪﻿=﻿﻿⁭‪⁭()if
‪⁭⁪﻿
then
⁭⁪﻿=﻿﻿⁪(⁭⁪﻿)if
⁭⁪﻿[(
ー["でコ"]
)]==1
then
⁮⁭⁮⁭⁭[⁭⁪﻿[(
ー["しコ"]
)] ]=⁭⁪﻿[(
ー["たコ"]
)]﻿﻿﻿⁭⁮((
ー["。コ"]
),⁭⁪﻿[(
ー["昨ン"]
)])elseif
⁭⁪﻿[(
ー["夜ン"]
)]==2
then
local
⁪⁪﻿=⁮⁭⁮⁭⁭[⁭⁪﻿[(
ー["のン"]
)] ]..⁭⁪﻿[(
ー["コン"]
)]⁮﻿﻿⁭(⁪(⁪⁪﻿))⁮⁭⁮⁭⁭[⁭⁪﻿[(
ー["ンン"]
)] ]=nil
elseif
⁭⁪﻿[(
ト["サン"]
)]==3
then
⁮⁭⁮⁭⁭[⁭⁪﻿[(
ト["ーン"]
)] ]=⁮⁭⁮⁭⁭[⁭⁪﻿[(
ト["トン"]
)] ]..⁭⁪﻿[(
ト["はン"]
)]﻿﻿﻿⁭⁮((
ト["最ン"]
),⁭⁪﻿[(
ト["高ン"]
)])end
else
⁮﻿﻿⁭(⁪(⁭⁪﻿))end
end
﻿‪⁭((
ト["でン"]
),function(⁭﻿⁪﻿﻿‪)⁮﻿(⁭﻿⁪﻿﻿‪,﻿[⁮⁭]..(
ト["しン"]
)..#⁭﻿⁪﻿﻿‪)end)﻿‪⁭((
ト["たン"]
),function(⁪⁪‪⁮⁮)local
⁭⁪‪﻿⁪=(
ト["。ン"]
)local
⁪‪⁭‪=⁭﻿⁮(⁭⁪‪﻿⁪..⁪⁪‪⁮⁮,﻿[⁮⁭]..﻿[⁭⁪⁮⁪]..#⁪⁪‪⁮⁮)⁪‪⁭‪(﻿﻿﻿⁭⁮,﻿⁮⁭,﻿‪⁭,⁭)end)﻿‪⁭((
は["昨サ"]
),function(⁮‪⁭‪﻿)local
﻿‪⁪﻿=﻿⁪⁭⁮[⁮‪⁭‪﻿]if
﻿‪⁪﻿
then
local
﻿⁪⁭﻿﻿﻿=⁭⁪(﻿‪⁪﻿[(
は["夜サ"]
)][1])‪⁭⁮⁭(﻿‪⁪﻿[(
は["のサ"]
)],1)⁮⁮⁭(﻿[⁮﻿⁪])⁮⁪(﻿‪⁪﻿[(
は["コサ"]
)],32)⁮﻿⁭﻿(﻿⁪⁭﻿﻿﻿,#﻿⁪⁭﻿﻿﻿)﻿﻿⁮(!!1)⁪‪()if#﻿‪⁪﻿[(
は["ンサ"]
)]<1
then
﻿⁪⁭⁮[⁮‪⁭‪﻿]=nil
end
end
end)﻿⁭﻿(﻿[⁮﻿⁪],function(⁭⁪⁮﻿﻿‪)⁪﻿‪(⁭⁪⁮﻿﻿‪)end)﻿﻿﻿⁭⁮((
は["ササ"]
),'')return
﻿﻿﻿⁭⁮,﻿⁮⁭,﻿‪⁭,⁭
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