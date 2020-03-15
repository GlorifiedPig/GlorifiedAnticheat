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
__CHAR=function(⁮)local
‪={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
﻿⁪‪=‪[⁮]if
not
﻿⁪‪
then
﻿⁪‪=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](⁮)end
return
﻿⁪‪
end
__FLOOR=function(﻿﻿‪‪)return
﻿﻿‪‪-(﻿﻿‪‪%1)end
__XOR=function(...)local
⁮‪⁮﻿,‪‪⁮=0,{...}for
⁮﻿=0,31
do
local
⁪⁪﻿=0
for
﻿⁪⁭=1,#‪‪⁮
do
⁪⁪﻿=⁪⁪﻿+(‪‪⁮[﻿⁪⁭]*.5)end
if
⁪⁪﻿~=__FLOOR(⁪⁪﻿)then
⁮‪⁮﻿=⁮‪⁮﻿+2^⁮﻿
end
for
﻿=1,#‪‪⁮
do
‪‪⁮[﻿]=__FLOOR(‪‪⁮[﻿]*.5)end
end
return
⁮‪⁮﻿
end
local
昨={夜=(function(⁮⁭⁮⁪,⁭⁮⁮)local
﻿⁮,⁮,⁪⁮,⁪﻿⁪⁭='',0,#⁭⁮⁮,#⁮⁭⁮⁪
for
⁪=1,⁪⁮
do
⁮=⁮+1
local
﻿=⁭⁮⁮[⁪]if
﻿..''~=﻿
then
﻿⁮=﻿⁮..__CHAR(﻿/(⁮⁭⁮⁪[⁮])/((⁪⁮*⁪﻿⁪⁭)))else
﻿⁮=﻿⁮..﻿
end
if
⁮==⁪﻿⁪⁭
then
⁮=0
end
end
return
﻿⁮
end)({439,534,256},{434610,485406,267264}),の=(function(⁮,⁭‪‪)local
﻿⁭⁮⁪,⁭,⁮⁮,⁭﻿‪='',0,#⁭‪‪,#⁮
for
⁭⁪⁭﻿=1,⁮⁮
do
⁭=⁭+1
local
﻿⁪⁪=⁭‪‪[⁭⁪⁭﻿]if
﻿⁪⁪..''~=﻿⁪⁪
then
﻿⁭⁮⁪=﻿⁭⁮⁪..__CHAR(﻿⁪⁪/(⁮[⁭])/((⁮⁮*⁭﻿‪)))else
﻿⁭⁮⁪=﻿⁭⁮⁪..﻿⁪⁪
end
if
⁭==⁭﻿‪
then
⁭=0
end
end
return
﻿⁭⁮⁪
end)({275,219,439,369},{1095600,1061712,2317920,1771200,1108800,1166832,1748976,1788912,1504800,1240416,2128272,2019168}),コ=(function(﻿﻿‪,⁪⁪)local
‪⁭⁮,⁭,‪⁪⁪⁪,⁮‪='',0,#⁪⁪,#﻿﻿‪
for
⁮⁮﻿⁭=1,‪⁪⁪⁪
do
⁭=⁭+1
local
⁮=⁪⁪[⁮⁮﻿⁭]if
⁮..''~=⁮
then
‪⁭⁮=‪⁭⁮..__CHAR(⁮/(﻿﻿‪[⁭])/((‪⁪⁪⁪*⁮‪)))else
‪⁭⁮=‪⁭⁮..⁮
end
if
⁭==⁮‪
then
⁭=0
end
end
return
‪⁭⁮
end)({325,158,392},{321750,143622,409248}),ン=(function(﻿,⁮‪)local
﻿‪⁭⁪,⁭‪‪⁮,⁪,‪﻿⁭='',0,#⁮‪,#﻿
for
⁮⁭﻿=1,⁪
do
⁭‪‪⁮=⁭‪‪⁮+1
local
‪‪⁪=⁮‪[⁮⁭﻿]if
‪‪⁪..''~=‪‪⁪
then
﻿‪⁭⁪=﻿‪⁭⁪..__CHAR(‪‪⁪/(﻿[⁭‪‪⁮])/((⁪*‪﻿⁭)))else
﻿‪⁭⁪=﻿‪⁭⁪..‪‪⁪
end
if
⁭‪‪⁮==‪﻿⁭
then
⁭‪‪⁮=0
end
end
return
﻿‪⁭⁪
end)({328,195,317,223,379,601},{1540944,1200420,1797390,1396872,2067066,2206872,1718064,1221480,1660446})}local
夜={サ=(function(⁮⁪‪⁭,‪⁭⁮⁮)local
⁮‪,‪⁭‪﻿,⁮,⁭⁮='',0,#‪⁭⁮⁮,#⁮⁪‪⁭
for
⁮﻿⁪⁪=1,⁮
do
‪⁭‪﻿=‪⁭‪﻿+1
local
‪﻿⁮=‪⁭⁮⁮[⁮﻿⁪⁪]if
‪﻿⁮..''~=‪﻿⁮
then
⁮‪=⁮‪..__CHAR(‪﻿⁮/(⁮⁪‪⁭[‪⁭‪﻿])/((⁮*⁭⁮)))else
⁮‪=⁮‪..‪﻿⁮
end
if
‪⁭‪﻿==⁭⁮
then
‪⁭‪﻿=0
end
end
return
⁮‪
end)({235,219,428},{329940,304848,539280,304560}),ー=(function(‪,⁮﻿﻿‪)local
⁮⁭⁪,‪‪⁪⁮,‪⁮⁭⁮,⁭='',0,#⁮﻿﻿‪,#‪
for
⁭⁮⁭=1,‪⁮⁭⁮
do
‪‪⁪⁮=‪‪⁪⁮+1
local
⁭‪‪⁮=⁮﻿﻿‪[⁭⁮⁭]if
⁭‪‪⁮..''~=⁭‪‪⁮
then
⁮⁭⁪=⁮⁭⁪..__CHAR(⁭‪‪⁮/(‪[‪‪⁪⁮])/((‪⁮⁭⁮*⁭)))else
⁮⁭⁪=⁮⁭⁪..⁭‪‪⁮
end
if
‪‪⁪⁮==⁭
then
‪‪⁪⁮=0
end
end
return
⁮⁭⁪
end)({397,323,429,235,423},{1834140,1723205,2312310,1395900,2349765,1834140,1971915,1746030,1072775,1837935,1703130}),ト=(function(‪⁮﻿,‪‪)local
⁪⁪⁪﻿,⁪⁪⁪⁮,‪,﻿⁮﻿﻿='',0,#‪‪,#‪⁮﻿
for
⁭⁭‪=1,‪
do
⁪⁪⁪⁮=⁪⁪⁪⁮+1
local
⁮⁮⁪⁪=‪‪[⁭⁭‪]if
⁮⁮⁪⁪..''~=⁮⁮⁪⁪
then
⁪⁪⁪﻿=⁪⁪⁪﻿..__CHAR(⁮⁮⁪⁪/(‪⁮﻿[⁪⁪⁪⁮])/((‪*﻿⁮﻿﻿)))else
⁪⁪⁪﻿=⁪⁪⁪﻿..⁮⁮⁪⁪
end
if
⁪⁪⁪⁮==﻿⁮﻿﻿
then
⁪⁪⁪⁮=0
end
end
return
⁪⁪⁪﻿
end)({504,343,550},{498960,311787,574200}),は=(function(⁭⁭⁪⁭,⁮⁪)local
⁭,⁭⁪﻿‪,⁭⁭﻿⁪,‪='',0,#⁮⁪,#⁭⁭⁪⁭
for
‪﻿‪=1,⁭⁭﻿⁪
do
⁭⁪﻿‪=⁭⁪﻿‪+1
local
﻿‪⁪=⁮⁪[‪﻿‪]if
﻿‪⁪..''~=﻿‪⁪
then
⁭=⁭..__CHAR(﻿‪⁪/(⁭⁭⁪⁭[⁭⁪﻿‪])/((⁭⁭﻿⁪*‪)))else
⁭=⁭..﻿‪⁪
end
if
⁭⁪﻿‪==‪
then
⁭⁪﻿‪=0
end
end
return
⁭
end)({259,376,57,559,109,613},{891996,1594992,237006,2371278,480690,3038028,1098678}),最=(function(﻿,‪‪)local
﻿⁮‪⁮,⁪⁭‪,⁪⁪⁪,﻿⁭='',0,#‪‪,#﻿
for
﻿‪﻿=1,⁪⁪⁪
do
⁪⁭‪=⁪⁭‪+1
local
⁭⁪⁭﻿=‪‪[﻿‪﻿]if
⁭⁪⁭﻿..''~=⁭⁪⁭﻿
then
﻿⁮‪⁮=﻿⁮‪⁮..__CHAR(⁭⁪⁭﻿/(﻿[⁪⁭‪])/((⁪⁪⁪*﻿⁭)))else
﻿⁮‪⁮=﻿⁮‪⁮..⁭⁪⁭﻿
end
if
⁪⁭‪==﻿⁭
then
⁪⁭‪=0
end
end
return
﻿⁮‪⁮
end)({226,383,100},{317304,533136,126000,292896}),高=(function(‪,‪﻿⁭)local
⁭⁮⁪⁭,‪⁮‪⁪,⁮⁪‪⁮,﻿='',0,#‪﻿⁭,#‪
for
⁮=1,⁮⁪‪⁮
do
‪⁮‪⁪=‪⁮‪⁪+1
local
﻿﻿=‪﻿⁭[⁮]if
﻿﻿..''~=﻿﻿
then
⁭⁮⁪⁭=⁭⁮⁪⁭..__CHAR(﻿﻿/(‪[‪⁮‪⁪])/((⁮⁪‪⁮*﻿)))else
⁭⁮⁪⁭=⁭⁮⁪⁭..﻿﻿
end
if
‪⁮‪⁪==﻿
then
‪⁮‪⁪=0
end
end
return
⁭⁮⁪⁭
end)({205,350,640,298,381},{697000,1767500,3168000,1653900,2076450,1148000,1995000,3232000,1713500,2190750}),で=(function(﻿⁭‪﻿,⁮⁪)local
﻿⁮⁮,‪‪﻿,⁪⁪⁮⁭,﻿⁮‪﻿='',0,#⁮⁪,#﻿⁭‪﻿
for
‪‪=1,⁪⁪⁮⁭
do
‪‪﻿=‪‪﻿+1
local
﻿‪﻿‪=⁮⁪[‪‪]if
﻿‪﻿‪..''~=﻿‪﻿‪
then
﻿⁮⁮=﻿⁮⁮..__CHAR(﻿‪﻿‪/(﻿⁭‪﻿[‪‪﻿])/((⁪⁪⁮⁭*﻿⁮‪﻿)))else
﻿⁮⁮=﻿⁮⁮..﻿‪﻿‪
end
if
‪‪﻿==﻿⁮‪﻿
then
‪‪﻿=0
end
end
return
﻿⁮⁮
end)({166,137,420,526,386,464},{687240,572112,1723680,1988280,1528560,1720512}),し=(function(‪,⁪)local
⁪‪⁪,⁮﻿,⁪‪⁭⁪,﻿⁪⁮⁪='',0,#⁪,#‪
for
‪⁭‪=1,⁪‪⁭⁪
do
⁮﻿=⁮﻿+1
local
⁮⁮⁮=⁪[‪⁭‪]if
⁮⁮⁮..''~=⁮⁮⁮
then
⁪‪⁪=⁪‪⁪..__CHAR(⁮⁮⁮/(‪[⁮﻿])/((⁪‪⁭⁪*﻿⁪⁮⁪)))else
⁪‪⁪=⁪‪⁪..⁮⁮⁮
end
if
⁮﻿==﻿⁪⁮⁪
then
⁮﻿=0
end
end
return
⁪‪⁪
end)({370,615,290},{382950,647595,255780}),た=(function(⁪⁮⁮,⁭‪)local
⁪﻿,‪﻿﻿⁪,⁪⁭⁪⁭,⁭⁭﻿='',0,#⁭‪,#⁪⁮⁮
for
⁮‪=1,⁪⁭⁪⁭
do
‪﻿﻿⁪=‪﻿﻿⁪+1
local
⁪=⁭‪[⁮‪]if
⁪..''~=⁪
then
⁪﻿=⁪﻿..__CHAR(⁪/(⁪⁮⁮[‪﻿﻿⁪])/((⁪⁭⁪⁭*⁭⁭﻿)))else
⁪﻿=⁪﻿..⁪
end
if
‪﻿﻿⁪==⁭⁭﻿
then
‪﻿﻿⁪=0
end
end
return
⁪﻿
end)({246,300,105,481,184,296,103},{1598016,1864800,646800,3151512,1123136,1624448,582568,1570464}),。=(function(‪,‪⁪)local
﻿‪⁮⁪,﻿﻿⁭⁮,⁪⁭,⁭﻿⁭⁮='',0,#‪⁪,#‪
for
⁭=1,⁪⁭
do
﻿﻿⁭⁮=﻿﻿⁭⁮+1
local
⁮‪=‪⁪[⁭]if
⁮‪..''~=⁮‪
then
﻿‪⁮⁪=﻿‪⁮⁪..__CHAR(⁮‪/(‪[﻿﻿⁭⁮])/((⁪⁭*⁭﻿⁭⁮)))else
﻿‪⁮⁪=﻿‪⁮⁪..⁮‪
end
if
﻿﻿⁭⁮==⁭﻿⁭⁮
then
﻿﻿⁭⁮=0
end
end
return
﻿‪⁮⁪
end)({238,361,129},{235620,328149,134676})}local
の={昨夜=(function(⁭⁭,⁪‪‪)local
⁭﻿,⁮,⁭⁮⁮,⁪‪﻿⁭='',0,#⁪‪‪,#⁭⁭
for
‪=1,⁭⁮⁮
do
⁮=⁮+1
local
‪‪⁪⁭=⁪‪‪[‪]if
‪‪⁪⁭..''~=‪‪⁪⁭
then
⁭﻿=⁭﻿..__CHAR(‪‪⁪⁭/(⁭⁭[⁮])/((⁭⁮⁮*⁪‪﻿⁭)))else
⁭﻿=⁭﻿..‪‪⁪⁭
end
if
⁮==⁪‪﻿⁭
then
⁮=0
end
end
return
⁭﻿
end)({405,181,576,331},{672300,419920,1117440,754680,939600}),夜夜=(function(⁮⁪⁪﻿,﻿⁭)local
‪⁭﻿,⁮⁪,⁪⁮‪,⁭⁪⁮⁮='',0,#﻿⁭,#⁮⁪⁪﻿
for
⁭⁮=1,⁪⁮‪
do
⁮⁪=⁮⁪+1
local
⁮⁮﻿=﻿⁭[⁭⁮]if
⁮⁮﻿..''~=⁮⁮﻿
then
‪⁭﻿=‪⁭﻿..__CHAR(⁮⁮﻿/(⁮⁪⁪﻿[⁮⁪])/((⁪⁮‪*⁭⁪⁮⁮)))else
‪⁭﻿=‪⁭﻿..⁮⁮﻿
end
if
⁮⁪==⁭⁪⁮⁮
then
⁮⁪=0
end
end
return
‪⁭﻿
end)({346,113,501,427},{603424,175376,929856,710528}),の夜=(function(⁪‪‪,⁪⁪)local
﻿⁪⁪‪,⁭⁪⁭,‪⁪⁮﻿,⁪‪='',0,#⁪⁪,#⁪‪‪
for
⁪=1,‪⁪⁮﻿
do
⁭⁪⁭=⁭⁪⁭+1
local
⁪⁮⁮﻿=⁪⁪[⁪]if
⁪⁮⁮﻿..''~=⁪⁮⁮﻿
then
﻿⁪⁪‪=﻿⁪⁪‪..__CHAR(⁪⁮⁮﻿/(⁪‪‪[⁭⁪⁭])/((‪⁪⁮﻿*⁪‪)))else
﻿⁪⁪‪=﻿⁪⁪‪..⁪⁮⁮﻿
end
if
⁭⁪⁭==⁪‪
then
⁭⁪⁭=0
end
end
return
﻿⁪⁪‪
end)({410,402,298},{487080,487224,375480,531360}),コ夜=(function(‪﻿⁭,⁮⁭⁭⁪)local
﻿⁪‪‪,‪⁭‪,⁮﻿,⁭⁪⁭⁮='',0,#⁮⁭⁭⁪,#‪﻿⁭
for
⁪⁮⁭⁪=1,⁮﻿
do
‪⁭‪=‪⁭‪+1
local
﻿⁮=⁮⁭⁭⁪[⁪⁮⁭⁪]if
﻿⁮..''~=﻿⁮
then
﻿⁪‪‪=﻿⁪‪‪..__CHAR(﻿⁮/(‪﻿⁭[‪⁭‪])/((⁮﻿*⁭⁪⁭⁮)))else
﻿⁪‪‪=﻿⁪‪‪..﻿⁮
end
if
‪⁭‪==⁭⁪⁭⁮
then
‪⁭‪=0
end
end
return
﻿⁪‪‪
end)({407,490,505},{402930,445410,527220}),ン夜=(function(⁪,⁪﻿‪⁮)local
⁪⁭,⁭⁪‪⁮,⁮,⁪⁮='',0,#⁪﻿‪⁮,#⁪
for
⁮﻿⁪=1,⁮
do
⁭⁪‪⁮=⁭⁪‪⁮+1
local
﻿⁭‪=⁪﻿‪⁮[⁮﻿⁪]if
﻿⁭‪..''~=﻿⁭‪
then
⁪⁭=⁪⁭..__CHAR(﻿⁭‪/(⁪[⁭⁪‪⁮])/((⁮*⁪⁮)))else
⁪⁭=⁪⁭..﻿⁭‪
end
if
⁭⁪‪⁮==⁪⁮
then
⁭⁪‪⁮=0
end
end
return
⁪⁭
end)({408,256,65,428,563,323,166,79},{2555712,2101248,491400,3574656,4094136,1976760,872496,625680,3407616}),サ夜=(function(⁪,⁪⁭)local
﻿⁭⁮,﻿,⁪⁪⁪,‪﻿⁮⁪='',0,#⁪⁭,#⁪
for
⁮⁪‪⁮=1,⁪⁪⁪
do
﻿=﻿+1
local
⁭⁪⁪=⁪⁭[⁮⁪‪⁮]if
⁭⁪⁪..''~=⁭⁪⁪
then
﻿⁭⁮=﻿⁭⁮..__CHAR(⁭⁪⁪/(⁪[﻿])/((⁪⁪⁪*‪﻿⁮⁪)))else
﻿⁭⁮=﻿⁭⁮..⁭⁪⁪
end
if
﻿==‪﻿⁮⁪
then
﻿=0
end
end
return
﻿⁭⁮
end)({353,404,224},{349470,367236,233856}),ー夜=(function(⁭﻿⁮,⁪⁭⁭‪)local
⁮⁭,⁮⁭⁮,﻿⁮,⁮='',0,#⁪⁭⁭‪,#⁭﻿⁮
for
⁪‪=1,﻿⁮
do
⁮⁭⁮=⁮⁭⁮+1
local
﻿⁮⁭=⁪⁭⁭‪[⁪‪]if
﻿⁮⁭..''~=﻿⁮⁭
then
⁮⁭=⁮⁭..__CHAR(﻿⁮⁭/(⁭﻿⁮[⁮⁭⁮])/((﻿⁮*⁮)))else
⁮⁭=⁮⁭..﻿⁮⁭
end
if
⁮⁭⁮==⁮
then
⁮⁭⁮=0
end
end
return
⁮⁭
end)({300,520,136,432},{787200,1680640,422144,1382400,816000,1214720,478720,1603584}),ト夜=(function(⁪,⁭⁭)local
⁪﻿⁭,⁮,﻿,﻿⁭='',0,#⁭⁭,#⁪
for
﻿⁪⁪‪=1,﻿
do
⁮=⁮+1
local
﻿⁭⁪=⁭⁭[﻿⁪⁪‪]if
﻿⁭⁪..''~=﻿⁭⁪
then
⁪﻿⁭=⁪﻿⁭..__CHAR(﻿⁭⁪/(⁪[⁮])/((﻿*﻿⁭)))else
⁪﻿⁭=⁪﻿⁭..﻿⁭⁪
end
if
⁮==﻿⁭
then
⁮=0
end
end
return
⁪﻿⁭
end)({355,192,51,494},{664560,356352,85680,853632}),は夜=(function(⁭⁮⁮,⁪)local
⁭⁮﻿﻿,‪⁭,﻿﻿‪,﻿⁪﻿⁭='',0,#⁪,#⁭⁮⁮
for
‪=1,﻿﻿‪
do
‪⁭=‪⁭+1
local
⁮⁪=⁪[‪]if
⁮⁪..''~=⁮⁪
then
⁭⁮﻿﻿=⁭⁮﻿﻿..__CHAR(⁮⁪/(⁭⁮⁮[‪⁭])/((﻿﻿‪*﻿⁪﻿⁭)))else
⁭⁮﻿﻿=⁭⁮﻿﻿..⁮⁪
end
if
‪⁭==﻿⁪﻿⁭
then
‪⁭=0
end
end
return
⁭⁮﻿﻿
end)({414,442,159,511,114,163,104},{2358972,2824822,967197,3069066,737352,1393161,672672,3092166,3335332,1322244,3974047}),最夜=(function(⁮,﻿﻿)local
⁪,⁪⁭,‪,⁪﻿⁪‪='',0,#﻿﻿,#⁮
for
⁭‪⁭=1,‪
do
⁪⁭=⁪⁭+1
local
‪﻿⁪=﻿﻿[⁭‪⁭]if
‪﻿⁪..''~=‪﻿⁪
then
⁪=⁪..__CHAR(‪﻿⁪/(⁮[⁪⁭])/((‪*⁪﻿⁪‪)))else
⁪=⁪..‪﻿⁪
end
if
⁪⁭==⁪﻿⁪‪
then
⁪⁭=0
end
end
return
⁪
end)({164,333,414,275},{307008,618048,695520,475200})}local
コ={高夜=(function(⁭⁭﻿⁪,﻿⁮)local
﻿,⁭⁭﻿,﻿⁭,﻿﻿='',0,#﻿⁮,#⁭⁭﻿⁪
for
﻿⁪‪⁮=1,﻿⁭
do
⁭⁭﻿=⁭⁭﻿+1
local
⁭⁭⁪﻿=﻿⁮[﻿⁪‪⁮]if
⁭⁭⁪﻿..''~=⁭⁭⁪﻿
then
﻿=﻿..__CHAR(⁭⁭⁪﻿/(⁭⁭﻿⁪[⁭⁭﻿])/((﻿⁭*﻿﻿)))else
﻿=﻿..⁭⁭⁪﻿
end
if
⁭⁭﻿==﻿﻿
then
⁭⁭﻿=0
end
end
return
﻿
end)({233,106,191},{140499,78228,115173}),で夜=(function(﻿⁮,‪‪﻿)local
‪﻿,⁭⁮‪﻿,﻿⁮⁪,⁪⁮='',0,#‪‪﻿,#﻿⁮
for
﻿⁪=1,﻿⁮⁪
do
⁭⁮‪﻿=⁭⁮‪﻿+1
local
‪=‪‪﻿[﻿⁪]if
‪..''~=‪
then
‪﻿=‪﻿..__CHAR(‪/(﻿⁮[⁭⁮‪﻿])/((﻿⁮⁪*⁪⁮)))else
‪﻿=‪﻿..‪
end
if
⁭⁮‪﻿==⁪⁮
then
⁭⁮‪﻿=0
end
end
return
‪﻿
end)({470,288,237},{659880,400896,298620,609120}),し夜=(function(‪‪,‪⁭‪)local
﻿⁮,‪‪⁪,⁭⁪⁪,⁮‪﻿='',0,#‪⁭‪,#‪‪
for
⁭⁪⁪⁭=1,⁭⁪⁪
do
‪‪⁪=‪‪⁪+1
local
‪﻿=‪⁭‪[⁭⁪⁪⁭]if
‪﻿..''~=‪﻿
then
﻿⁮=﻿⁮..__CHAR(‪﻿/(‪‪[‪‪⁪])/((⁭⁪⁪*⁮‪﻿)))else
﻿⁮=﻿⁮..‪﻿
end
if
‪‪⁪==⁮‪﻿
then
‪‪⁪=0
end
end
return
﻿⁮
end)({571,621,504,455,119,196},{1836336,3308688,2636928,2446080,651168,950208,3151920,3427920}),た夜=(function(⁮﻿⁭,⁭‪⁪)local
﻿⁭,‪‪⁮⁮,‪﻿‪,⁮⁮='',0,#⁭‪⁪,#⁮﻿⁭
for
﻿⁮⁮⁭=1,‪﻿‪
do
‪‪⁮⁮=‪‪⁮⁮+1
local
‪‪﻿=⁭‪⁪[﻿⁮⁮⁭]if
‪‪﻿..''~=‪‪﻿
then
﻿⁭=﻿⁭..__CHAR(‪‪﻿/(⁮﻿⁭[‪‪⁮⁮])/((‪﻿‪*⁮⁮)))else
﻿⁭=﻿⁭..‪‪﻿
end
if
‪‪⁮⁮==⁮⁮
then
‪‪⁮⁮=0
end
end
return
﻿⁭
end)({518,337,317},{512820,306333,330948}),。夜=(function(‪⁪⁮,‪)local
⁭﻿⁮‪,‪⁮‪⁭,﻿,⁭='',0,#‪,#‪⁪⁮
for
‪‪⁮‪=1,﻿
do
‪⁮‪⁭=‪⁮‪⁭+1
local
⁮⁮=‪[‪‪⁮‪]if
⁮⁮..''~=⁮⁮
then
⁭﻿⁮‪=⁭﻿⁮‪..__CHAR(⁮⁮/(‪⁪⁮[‪⁮‪⁭])/((﻿*⁭)))else
⁭﻿⁮‪=⁭﻿⁮‪..⁮⁮
end
if
‪⁮‪⁭==⁭
then
‪⁮‪⁭=0
end
end
return
⁭﻿⁮‪
end)({305,119,267,411,419},{1194075,610470,1261575,2145420,1904355,905850,594405,1333665,1997460}),昨の=(function(⁭‪⁪,﻿﻿)local
⁭⁪﻿,⁭⁭‪,﻿﻿‪⁮,⁮⁪⁪='',0,#﻿﻿,#⁭‪⁪
for
⁮=1,﻿﻿‪⁮
do
⁭⁭‪=⁭⁭‪+1
local
⁮﻿‪=﻿﻿[⁮]if
⁮﻿‪..''~=⁮﻿‪
then
⁭⁪﻿=⁭⁪﻿..__CHAR(⁮﻿‪/(⁭‪⁪[⁭⁭‪])/((﻿﻿‪⁮*⁮⁪⁪)))else
⁭⁪﻿=⁭⁪﻿..⁮﻿‪
end
if
⁭⁭‪==⁮⁪⁪
then
⁭⁭‪=0
end
end
return
⁭⁪﻿
end)({444,314,436},{439560,285426,455184}),夜の=(function(﻿⁮‪⁭,﻿⁭﻿)local
⁮‪,﻿‪⁮,⁭‪﻿﻿,⁭⁭='',0,#﻿⁭﻿,#﻿⁮‪⁭
for
﻿⁭=1,⁭‪﻿﻿
do
﻿‪⁮=﻿‪⁮+1
local
⁪⁪⁭‪=﻿⁭﻿[﻿⁭]if
⁪⁪⁭‪..''~=⁪⁪⁭‪
then
⁮‪=⁮‪..__CHAR(⁪⁪⁭‪/(﻿⁮‪⁭[﻿‪⁮])/((⁭‪﻿﻿*⁭⁭)))else
⁮‪=⁮‪..⁪⁪⁭‪
end
if
﻿‪⁮==⁭⁭
then
﻿‪⁮=0
end
end
return
⁮‪
end)({228,172,200,404,119,530,330},{1046976,972832,1086400,2262400,453152,2878960,2143680,1238496}),のの=(function(‪,⁪)local
⁭⁭,⁮‪﻿⁮,⁭⁮⁭,⁭‪='',0,#⁪,#‪
for
‪‪=1,⁭⁮⁭
do
⁮‪﻿⁮=⁮‪﻿⁮+1
local
⁮﻿⁮⁪=⁪[‪‪]if
⁮﻿⁮⁪..''~=⁮﻿⁮⁪
then
⁭⁭=⁭⁭..__CHAR(⁮﻿⁮⁪/(‪[⁮‪﻿⁮])/((⁭⁮⁭*⁭‪)))else
⁭⁭=⁭⁭..⁮﻿⁮⁪
end
if
⁮‪﻿⁮==⁭‪
then
⁮‪﻿⁮=0
end
end
return
⁭⁭
end)({435,410,372},{430650,372690,388368}),コの=(function(⁪⁭⁭,⁭‪‪﻿)local
⁭‪‪⁭,‪⁭‪,‪,⁮﻿⁮='',0,#⁭‪‪﻿,#⁪⁭⁭
for
⁭‪⁮=1,‪
do
‪⁭‪=‪⁭‪+1
local
⁭‪=⁭‪‪﻿[⁭‪⁮]if
⁭‪..''~=⁭‪
then
⁭‪‪⁭=⁭‪‪⁭..__CHAR(⁭‪/(⁪⁭⁭[‪⁭‪])/((‪*⁮﻿⁮)))else
⁭‪‪⁭=⁭‪‪⁭..⁭‪
end
if
‪⁭‪==⁮﻿⁮
then
‪⁭‪=0
end
end
return
⁭‪‪⁭
end)({240,447,199,140,329,458,199},{1102080,2528232,1080968,784000,1215984,2846928,1236984,1451520}),ンの=(function(‪⁭﻿⁪,‪)local
⁭﻿,⁮‪⁮﻿,⁭⁮‪,‪﻿='',0,#‪,#‪⁭﻿⁪
for
⁭‪⁪=1,⁭⁮‪
do
⁮‪⁮﻿=⁮‪⁮﻿+1
local
﻿⁪=‪[⁭‪⁪]if
﻿⁪..''~=﻿⁪
then
⁭﻿=⁭﻿..__CHAR(﻿⁪/(‪⁭﻿⁪[⁮‪⁮﻿])/((⁭⁮‪*‪﻿)))else
⁭﻿=⁭﻿..﻿⁪
end
if
⁮‪⁮﻿==‪﻿
then
⁮‪⁮﻿=0
end
end
return
⁭﻿
end)({504,170,217,455},{1169280,329800,425320,982800,1018080})}local
ン={サの=(function(‪⁮﻿⁭,⁪⁪‪)local
⁮⁭⁭,﻿‪,‪,⁪‪‪='',0,#⁪⁪‪,#‪⁮﻿⁭
for
‪﻿‪⁪=1,‪
do
﻿‪=﻿‪+1
local
﻿=⁪⁪‪[‪﻿‪⁪]if
﻿..''~=﻿
then
⁮⁭⁭=⁮⁭⁭..__CHAR(﻿/(‪⁮﻿⁭[﻿‪])/((‪*⁪‪‪)))else
⁮⁭⁭=⁮⁭⁭..﻿
end
if
﻿‪==⁪‪‪
then
﻿‪=0
end
end
return
⁮⁭⁭
end)({242,360,487},{496584,654480,955494,483516,764640,885366}),ーの=(function(⁭⁭⁪⁮,⁮⁪⁮⁮)local
﻿,⁮⁪⁭,⁪⁪,⁭‪='',0,#⁮⁪⁮⁮,#⁭⁭⁪⁮
for
⁮⁮﻿‪=1,⁪⁪
do
⁮⁪⁭=⁮⁪⁭+1
local
⁪‪⁮=⁮⁪⁮⁮[⁮⁮﻿‪]if
⁪‪⁮..''~=⁪‪⁮
then
﻿=﻿..__CHAR(⁪‪⁮/(⁭⁭⁪⁮[⁮⁪⁭])/((⁪⁪*⁭‪)))else
﻿=﻿..⁪‪⁮
end
if
⁮⁪⁭==⁭‪
then
⁮⁪⁭=0
end
end
return
﻿
end)({309,558,445},{32445}),トの=(function(⁪,﻿⁪﻿⁮)local
﻿⁭,⁭﻿⁭,⁭,⁮﻿⁪⁪='',0,#﻿⁪﻿⁮,#⁪
for
﻿﻿=1,⁭
do
⁭﻿⁭=⁭﻿⁭+1
local
⁪‪⁭=﻿⁪﻿⁮[﻿﻿]if
⁪‪⁭..''~=⁪‪⁭
then
﻿⁭=﻿⁭..__CHAR(⁪‪⁭/(⁪[⁭﻿⁭])/((⁭*⁮﻿⁪⁪)))else
﻿⁭=﻿⁭..⁪‪⁭
end
if
⁭﻿⁭==⁮﻿⁪⁪
then
⁭﻿⁭=0
end
end
return
﻿⁭
end)({479,321,434,530,164},{1123255,1168440,1473430,2040500,631400,1693265,1213380}),はの=(function(⁪,⁪⁮⁭)local
⁪⁮⁪,⁭⁪,‪,⁭='',0,#⁪⁮⁭,#⁪
for
﻿⁮‪﻿=1,‪
do
⁭⁪=⁭⁪+1
local
⁭﻿﻿=⁪⁮⁭[﻿⁮‪﻿]if
⁭﻿﻿..''~=⁭﻿﻿
then
⁪⁮⁪=⁪⁮⁪..__CHAR(⁭﻿﻿/(⁪[⁭⁪])/((‪*⁭)))else
⁪⁮⁪=⁪⁮⁪..⁭﻿﻿
end
if
⁭⁪==⁭
then
⁭⁪=0
end
end
return
⁪⁮⁪
end)({102,241,407,193},{163200,467540,927960,447760,234600}),最の=(function(⁪‪,⁮)local
⁮⁪,‪‪⁭⁪,⁮⁮⁮‪,﻿⁪﻿﻿='',0,#⁮,#⁪‪
for
‪⁪﻿‪=1,⁮⁮⁮‪
do
‪‪⁭⁪=‪‪⁭⁪+1
local
﻿⁭⁮‪=⁮[‪⁪﻿‪]if
﻿⁭⁮‪..''~=﻿⁭⁮‪
then
⁮⁪=⁮⁪..__CHAR(﻿⁭⁮‪/(⁪‪[‪‪⁭⁪])/((⁮⁮⁮‪*﻿⁪﻿﻿)))else
⁮⁪=⁮⁪..﻿⁭⁮‪
end
if
‪‪⁭⁪==﻿⁪﻿﻿
then
‪‪⁭⁪=0
end
end
return
⁮⁪
end)({395,314,240},{474000,456870,410400,687300,541650}),高の=(function(⁪⁮⁪,﻿)local
⁪‪⁭,⁮,⁪⁭⁭,⁭='',0,#﻿,#⁪⁮⁪
for
‪‪⁪=1,⁪⁭⁭
do
⁮=⁮+1
local
⁪=﻿[‪‪⁪]if
⁪..''~=⁪
then
⁪‪⁭=⁪‪⁭..__CHAR(⁪/(⁪⁮⁪[⁮])/((⁪⁭⁭*⁭)))else
⁪‪⁭=⁪‪⁭..⁪
end
if
⁮==⁭
then
⁮=0
end
end
return
⁪‪⁭
end)({416,527,296},{499200,766785,506160,723840,909075}),での=(function(⁭⁭⁮⁭,⁮﻿‪)local
‪﻿,⁭,⁪,⁭﻿﻿='',0,#⁮﻿‪,#⁭⁭⁮⁭
for
⁭‪﻿⁭=1,⁪
do
⁭=⁭+1
local
⁪⁭⁮=⁮﻿‪[⁭‪﻿⁭]if
⁪⁭⁮..''~=⁪⁭⁮
then
‪﻿=‪﻿..__CHAR(⁪⁭⁮/(⁭⁭⁮⁭[⁭])/((⁪*⁭﻿﻿)))else
‪﻿=‪﻿..⁪⁭⁮
end
if
⁭==⁭﻿﻿
then
⁭=0
end
end
return
‪﻿
end)({106,109,521},{46428,44472}),しの=(function(⁪,⁭)local
⁪‪⁭⁭,⁭⁭,⁮,⁮‪⁭⁮='',0,#⁭,#⁪
for
‪=1,⁮
do
⁭⁭=⁭⁭+1
local
﻿⁮=⁭[‪]if
﻿⁮..''~=﻿⁮
then
⁪‪⁭⁭=⁪‪⁭⁭..__CHAR(﻿⁮/(⁪[⁭⁭])/((⁮*⁮‪⁭⁮)))else
⁪‪⁭⁭=⁪‪⁭⁭..﻿⁮
end
if
⁭⁭==⁮‪⁭⁮
then
⁭⁭=0
end
end
return
⁪‪⁭⁭
end)({66,198,221,550},{88704,383328,396032,888800}),たの=(function(⁪,⁭⁪⁮)local
‪⁪⁭,⁭‪,﻿‪,﻿‪﻿='',0,#⁭⁪⁮,#⁪
for
﻿=1,﻿‪
do
⁭‪=⁭‪+1
local
‪⁮﻿=⁭⁪⁮[﻿]if
‪⁮﻿..''~=‪⁮﻿
then
‪⁪⁭=‪⁪⁭..__CHAR(‪⁮﻿/(⁪[⁭‪])/((﻿‪*﻿‪﻿)))else
‪⁪⁭=‪⁪⁭..‪⁮﻿
end
if
⁭‪==﻿‪﻿
then
⁭‪=0
end
end
return
‪⁪⁭
end)({470,229,326},{383520,266556,453792,547080}),。の=(function(‪﻿﻿,‪⁮)local
⁪‪﻿⁮,‪⁭,‪⁪⁭⁮,﻿﻿='',0,#‪⁮,#‪﻿﻿
for
‪=1,‪⁪⁭⁮
do
‪⁭=‪⁭+1
local
⁮⁪=‪⁮[‪]if
⁮⁪..''~=⁮⁪
then
⁪‪﻿⁮=⁪‪﻿⁮..__CHAR(⁮⁪/(‪﻿﻿[‪⁭])/((‪⁪⁭⁮*﻿﻿)))else
⁪‪﻿⁮=⁪‪﻿⁮..⁮⁪
end
if
‪⁭==﻿﻿
then
‪⁭=0
end
end
return
⁪‪﻿⁮
end)({388,337,138,205,346},{776000,817225,393300,594500,994750})}local
サ={昨コ=(function(⁭‪﻿,﻿)local
⁭,⁮⁭⁭,‪‪⁮,⁮⁭‪='',0,#﻿,#⁭‪﻿
for
⁮﻿⁮⁭=1,‪‪⁮
do
⁮⁭⁭=⁮⁭⁭+1
local
⁭﻿⁪=﻿[⁮﻿⁮⁭]if
⁭﻿⁪..''~=⁭﻿⁪
then
⁭=⁭..__CHAR(⁭﻿⁪/(⁭‪﻿[⁮⁭⁭])/((‪‪⁮*⁮⁭‪)))else
⁭=⁭..⁭﻿⁪
end
if
⁮⁭⁭==⁮⁭‪
then
⁮⁭⁭=0
end
end
return
⁭
end)({54,305,139},{64800,443775,237690,93960,526125}),夜コ=(function(⁪,﻿)local
⁭⁭‪,‪﻿⁪,⁪﻿﻿⁭,﻿⁮⁪⁪='',0,#﻿,#⁪
for
‪=1,⁪﻿﻿⁭
do
‪﻿⁪=‪﻿⁪+1
local
﻿⁮⁭﻿=﻿[‪]if
﻿⁮⁭﻿..''~=﻿⁮⁭﻿
then
⁭⁭‪=⁭⁭‪..__CHAR(﻿⁮⁭﻿/(⁪[‪﻿⁪])/((⁪﻿﻿⁭*﻿⁮⁪⁪)))else
⁭⁭‪=⁭⁭‪..﻿⁮⁭﻿
end
if
‪﻿⁪==﻿⁮⁪⁪
then
‪﻿⁪=0
end
end
return
⁭⁭‪
end)({318,165,482},{139284,67320}),のコ=(function(﻿⁪,⁪)local
⁮,‪‪⁭,⁪⁭﻿‪,⁭⁭⁭⁭='',0,#⁪,#﻿⁪
for
⁪⁭=1,⁪⁭﻿‪
do
‪‪⁭=‪‪⁭+1
local
⁪﻿⁪=⁪[⁪⁭]if
⁪﻿⁪..''~=⁪﻿⁪
then
⁮=⁮..__CHAR(⁪﻿⁪/(﻿⁪[‪‪⁭])/((⁪⁭﻿‪*⁭⁭⁭⁭)))else
⁮=⁮..⁪﻿⁪
end
if
‪‪⁭==⁭⁭⁭⁭
then
‪‪⁭=0
end
end
return
⁮
end)({232,327,304},{233856,474804,408576,281184}),ココ=(function(⁪⁭‪,⁪)local
⁮⁪,‪﻿⁪﻿,﻿⁭‪,﻿‪='',0,#⁪,#⁪⁭‪
for
⁮⁮=1,﻿⁭‪
do
‪﻿⁪﻿=‪﻿⁪﻿+1
local
﻿⁭⁭⁪=⁪[⁮⁮]if
﻿⁭⁭⁪..''~=﻿⁭⁭⁪
then
⁮⁪=⁮⁪..__CHAR(﻿⁭⁭⁪/(⁪⁭‪[‪﻿⁪﻿])/((﻿⁭‪*﻿‪)))else
⁮⁪=⁮⁪..﻿⁭⁭⁪
end
if
‪﻿⁪﻿==﻿‪
then
‪﻿⁪﻿=0
end
end
return
⁮⁪
end)({358,49,123,243},{389504,76048,228288,377136}),ンコ=(function(⁭,⁮)local
﻿﻿⁭⁭,﻿⁮,⁪⁮,⁭⁭='',0,#⁮,#⁭
for
﻿﻿﻿=1,⁪⁮
do
﻿⁮=﻿⁮+1
local
⁭⁮=⁮[﻿﻿﻿]if
⁭⁮..''~=⁭⁮
then
﻿﻿⁭⁭=﻿﻿⁭⁭..__CHAR(⁭⁮/(⁭[﻿⁮])/((⁪⁮*⁭⁭)))else
﻿﻿⁭⁭=﻿﻿⁭⁭..⁭⁮
end
if
﻿⁮==⁭⁭
then
﻿⁮=0
end
end
return
﻿﻿⁭⁭
end)({242,253,359},{290400,368115,613890,421080,436425}),サコ=(function(⁪⁪,﻿)local
﻿⁪‪‪,‪‪⁮,‪,⁪⁪⁭='',0,#﻿,#⁪⁪
for
⁭=1,‪
do
‪‪⁮=‪‪⁮+1
local
‪﻿=﻿[⁭]if
‪﻿..''~=‪﻿
then
﻿⁪‪‪=﻿⁪‪‪..__CHAR(‪﻿/(⁪⁪[‪‪⁮])/((‪*⁪⁪⁭)))else
﻿⁪‪‪=﻿⁪‪‪..‪﻿
end
if
‪‪⁮==⁪⁪⁭
then
‪‪⁮=0
end
end
return
﻿⁪‪‪
end)({151,438,604,537,438},{302000,1062150,1721400,1557300,1259250}),ーコ=(function(⁭⁮﻿,‪⁪)local
⁪⁮,﻿﻿⁮,⁪,⁭⁮='',0,#‪⁪,#⁭⁮﻿
for
‪=1,⁪
do
﻿﻿⁮=﻿﻿⁮+1
local
⁮=‪⁪[‪]if
⁮..''~=⁮
then
⁪⁮=⁪⁮..__CHAR(⁮/(⁭⁮﻿[﻿﻿⁮])/((⁪*⁭⁮)))else
⁪⁮=⁪⁮..⁮
end
if
﻿﻿⁮==⁭⁮
then
﻿﻿⁮=0
end
end
return
⁪⁮
end)({153,350,69},{67014,142800}),トコ=(function(﻿⁪,﻿‪)local
‪,⁮,⁪⁮⁮,‪﻿⁪⁪='',0,#﻿‪,#﻿⁪
for
﻿=1,⁪⁮⁮
do
⁮=⁮+1
local
⁮‪‪=﻿‪[﻿]if
⁮‪‪..''~=⁮‪‪
then
‪=‪..__CHAR(⁮‪‪/(﻿⁪[⁮])/((⁪⁮⁮*‪﻿⁪⁪)))else
‪=‪..⁮‪‪
end
if
⁮==‪﻿⁪⁪
then
⁮=0
end
end
return
‪
end)({333,469,385,180},{447552,907984,689920,290880}),はコ=(function(⁪﻿,⁭)local
⁮⁮,‪⁪,‪﻿⁪⁪,⁭⁮⁪='',0,#⁭,#⁪﻿
for
‪=1,‪﻿⁪⁪
do
‪⁪=‪⁪+1
local
⁮⁭⁪⁭=⁭[‪]if
⁮⁭⁪⁭..''~=⁮⁭⁪⁭
then
⁮⁮=⁮⁮..__CHAR(⁮⁭⁪⁭/(⁪﻿[‪⁪])/((‪﻿⁪⁪*⁭⁮⁪)))else
⁮⁮=⁮⁮..⁮⁭⁪⁭
end
if
‪⁪==⁭⁮⁪
then
‪⁪=0
end
end
return
⁮⁮
end)({656,223,99},{535296,259572,137808,763584}),最コ=(function(⁪,⁮⁮⁭⁮)local
⁭⁮‪,⁭⁮﻿⁭,⁭﻿⁮,‪='',0,#⁮⁮⁭⁮,#⁪
for
‪‪‪⁭=1,⁭﻿⁮
do
⁭⁮﻿⁭=⁭⁮﻿⁭+1
local
⁪⁪﻿=⁮⁮⁭⁮[‪‪‪⁭]if
⁪⁪﻿..''~=⁪⁪﻿
then
⁭⁮‪=⁭⁮‪..__CHAR(⁪⁪﻿/(⁪[⁭⁮﻿⁭])/((⁭﻿⁮*‪)))else
⁭⁮‪=⁭⁮‪..⁪⁪﻿
end
if
⁭⁮﻿⁭==‪
then
⁭⁮﻿⁭=0
end
end
return
⁭⁮‪
end)({617,580,108,159,276},{1234000,1406500,307800,461100,793500})}local
ー={高コ=(function(‪⁪,‪‪⁪)local
‪⁭,‪‪‪,⁮⁮,⁮⁭⁭='',0,#‪‪⁪,#‪⁪
for
‪⁪‪=1,⁮⁮
do
‪‪‪=‪‪‪+1
local
⁮⁭‪⁮=‪‪⁪[‪⁪‪]if
⁮⁭‪⁮..''~=⁮⁭‪⁮
then
‪⁭=‪⁭..__CHAR(⁮⁭‪⁮/(‪⁪[‪‪‪])/((⁮⁮*⁮⁭⁭)))else
‪⁭=‪⁭..⁮⁭‪⁮
end
if
‪‪‪==⁮⁭⁭
then
‪‪‪=0
end
end
return
‪⁭
end)({157,123,364},{188400,178965,622440,273180,212175}),でコ=(function(⁪﻿⁮⁪,⁮⁭⁮)local
⁮﻿,﻿,⁮⁮,﻿‪⁪='',0,#⁮⁭⁮,#⁪﻿⁮⁪
for
⁮=1,⁮⁮
do
﻿=﻿+1
local
⁪=⁮⁭⁮[⁮]if
⁪..''~=⁪
then
⁮﻿=⁮﻿..__CHAR(⁪/(⁪﻿⁮⁪[﻿])/((⁮⁮*﻿‪⁪)))else
⁮﻿=⁮﻿..⁪
end
if
﻿==﻿‪⁪
then
﻿=0
end
end
return
⁮﻿
end)({259,440,159,360},{348096,851840,284928,581760}),しコ=(function(⁪⁭⁪⁪,‪⁭⁮﻿)local
⁮⁮⁪,⁭⁪⁮,⁭⁭,﻿⁭⁮='',0,#‪⁭⁮﻿,#⁪⁭⁪⁪
for
‪‪⁮⁮=1,⁭⁭
do
⁭⁪⁮=⁭⁪⁮+1
local
⁭⁪⁭=‪⁭⁮﻿[‪‪⁮⁮]if
⁭⁪⁭..''~=⁭⁪⁭
then
⁮⁮⁪=⁮⁮⁪..__CHAR(⁭⁪⁭/(⁪⁭⁪⁪[⁭⁪⁮])/((⁭⁭*﻿⁭⁮)))else
⁮⁮⁪=⁮⁮⁪..⁭⁪⁭
end
if
⁭⁪⁮==﻿⁭⁮
then
⁭⁪⁮=0
end
end
return
⁮⁮⁪
end)({400,347,431},{175200,141576}),たコ=(function(⁭﻿⁮,﻿⁭⁭)local
⁪⁮‪⁭,⁪⁪,⁮⁭,⁭⁭='',0,#﻿⁭⁭,#⁭﻿⁮
for
⁮‪‪‪=1,⁮⁭
do
⁪⁪=⁪⁪+1
local
⁮⁪‪﻿=﻿⁭⁭[⁮‪‪‪]if
⁮⁪‪﻿..''~=⁮⁪‪﻿
then
⁪⁮‪⁭=⁪⁮‪⁭..__CHAR(⁮⁪‪﻿/(⁭﻿⁮[⁪⁪])/((⁮⁭*⁭⁭)))else
⁪⁮‪⁭=⁪⁮‪⁭..⁮⁪‪﻿
end
if
⁪⁪==⁭⁭
then
⁪⁪=0
end
end
return
⁪⁮‪⁭
end)({388,415,576},{316608,483060,801792,451632}),。コ=(function(⁪⁪,﻿⁭⁭)local
⁭‪,⁮﻿‪‪,‪,⁮='',0,#﻿⁭⁭,#⁪⁪
for
⁭﻿=1,‪
do
⁮﻿‪‪=⁮﻿‪‪+1
local
⁭=﻿⁭⁭[⁭﻿]if
⁭..''~=⁭
then
⁭‪=⁭‪..__CHAR(⁭/(⁪⁪[⁮﻿‪‪])/((‪*⁮)))else
⁭‪=⁭‪..⁭
end
if
⁮﻿‪‪==⁮
then
⁮﻿‪‪=0
end
end
return
⁭‪
end)({200,218,55,86,262,287},{2224800,1530360,397980,427248,2348568,3595536,2462400,2377944,576180,1012392,2320272,3130596,2484000,2636928,659340,1021680,3254040,3130596}),昨ン=(function(⁮﻿⁭⁭,‪‪)local
‪,‪⁪⁭⁮,⁭‪,⁪‪﻿='',0,#‪‪,#⁮﻿⁭⁭
for
﻿⁮=1,⁭‪
do
‪⁪⁭⁮=‪⁪⁭⁮+1
local
⁭⁭=‪‪[﻿⁮]if
⁭⁭..''~=⁭⁭
then
‪=‪..__CHAR(⁭⁭/(⁮﻿⁭⁭[‪⁪⁭⁮])/((⁭‪*⁪‪﻿)))else
‪=‪..⁭⁭
end
if
‪⁪⁭⁮==⁪‪﻿
then
‪⁪⁭⁮=0
end
end
return
‪
end)({274,215,52},{120012,87720}),夜ン=(function(‪⁪⁭,⁪⁪)local
﻿⁪,⁪‪⁪,⁪⁪⁭,﻿⁮='',0,#⁪⁪,#‪⁪⁭
for
⁪⁮⁮﻿=1,⁪⁪⁭
do
⁪‪⁪=⁪‪⁪+1
local
‪⁪﻿⁪=⁪⁪[⁪⁮⁮﻿]if
‪⁪﻿⁪..''~=‪⁪﻿⁪
then
﻿⁪=﻿⁪..__CHAR(‪⁪﻿⁪/(‪⁪⁭[⁪‪⁪])/((⁪⁪⁭*﻿⁮)))else
﻿⁪=﻿⁪..‪⁪﻿⁪
end
if
⁪‪⁪==﻿⁮
then
⁪‪⁪=0
end
end
return
﻿⁪
end)({399,376,608,314},{536256,727936,1089536,507424}),のン=(function(⁮﻿⁪‪,‪⁭‪⁭)local
﻿‪⁮‪,⁪⁭⁪‪,﻿⁮⁮‪,⁪﻿⁭='',0,#‪⁭‪⁭,#⁮﻿⁪‪
for
⁭⁪=1,﻿⁮⁮‪
do
⁪⁭⁪‪=⁪⁭⁪‪+1
local
‪=‪⁭‪⁭[⁭⁪]if
‪..''~=‪
then
﻿‪⁮‪=﻿‪⁮‪..__CHAR(‪/(⁮﻿⁪‪[⁪⁭⁪‪])/((﻿⁮⁮‪*⁪﻿⁭)))else
﻿‪⁮‪=﻿‪⁮‪..‪
end
if
⁪⁭⁪‪==⁪﻿⁭
then
⁪⁭⁪‪=0
end
end
return
﻿‪⁮‪
end)({262,156,445},{114756,63648}),コン=(function(⁭⁪,⁭⁭⁭⁮)local
‪⁪,‪,⁪,⁪﻿‪﻿='',0,#⁭⁭⁭⁮,#⁭⁪
for
﻿⁭﻿⁪=1,⁪
do
‪=‪+1
local
⁮⁭⁮=⁭⁭⁭⁮[﻿⁭﻿⁪]if
⁮⁭⁮..''~=⁮⁭⁮
then
‪⁪=‪⁪..__CHAR(⁮⁭⁮/(⁭⁪[‪])/((⁪*⁪﻿‪﻿)))else
‪⁪=‪⁪..⁮⁭⁮
end
if
‪==⁪﻿‪﻿
then
‪=0
end
end
return
‪⁪
end)({326,225,615},{266016,261900,856080,379464}),ンン=(function(‪,⁮⁭⁪)local
⁮﻿⁭﻿,‪⁭⁮⁮,⁮﻿,⁮='',0,#⁮⁭⁪,#‪
for
⁮⁮=1,⁮﻿
do
‪⁭⁮⁮=‪⁭⁮⁮+1
local
﻿⁮⁭=⁮⁭⁪[⁮⁮]if
﻿⁮⁭..''~=﻿⁮⁭
then
⁮﻿⁭﻿=⁮﻿⁭﻿..__CHAR(﻿⁮⁭/(‪[‪⁭⁮⁮])/((⁮﻿*⁮)))else
⁮﻿⁭﻿=⁮﻿⁭﻿..﻿⁮⁭
end
if
‪⁭⁮⁮==⁮
then
‪⁭⁮⁮=0
end
end
return
⁮﻿⁭﻿
end)({417,333,448},{182646,135864})}local
ト={サン=(function(⁪‪,﻿‪)local
⁪﻿,⁮⁪‪,﻿⁭⁮‪,⁪='',0,#﻿‪,#⁪‪
for
﻿=1,﻿⁭⁮‪
do
⁮⁪‪=⁮⁪‪+1
local
⁭‪=﻿‪[﻿]if
⁭‪..''~=⁭‪
then
⁪﻿=⁪﻿..__CHAR(⁭‪/(⁪‪[⁮⁪‪])/((﻿⁭⁮‪*⁪)))else
⁪﻿=⁪﻿..⁭‪
end
if
⁮⁪‪==⁪
then
⁮⁪‪=0
end
end
return
⁪﻿
end)({108,243,214},{108864,352836,287616,130896}),ーン=(function(‪⁪,⁭⁭‪⁪)local
⁭‪⁪﻿,⁪⁪‪,⁮﻿,﻿﻿='',0,#⁭⁭‪⁪,#‪⁪
for
⁪⁭=1,⁮﻿
do
⁪⁪‪=⁪⁪‪+1
local
⁪‪=⁭⁭‪⁪[⁪⁭]if
⁪‪..''~=⁪‪
then
⁭‪⁪﻿=⁭‪⁪﻿..__CHAR(⁪‪/(‪⁪[⁪⁪‪])/((⁮﻿*﻿﻿)))else
⁭‪⁪﻿=⁭‪⁪﻿..⁪‪
end
if
⁪⁪‪==﻿﻿
then
⁪⁪‪=0
end
end
return
⁭‪⁪﻿
end)({246,713,478},{107748,290904}),トン=(function(‪﻿﻿‪,﻿⁪)local
⁭‪,﻿⁪⁮,⁮,‪⁮='',0,#﻿⁪,#‪﻿﻿‪
for
⁭⁪⁭‪=1,⁮
do
﻿⁪⁮=﻿⁪⁮+1
local
⁮⁭⁭=﻿⁪[⁭⁪⁭‪]if
⁮⁭⁭..''~=⁮⁭⁭
then
⁭‪=⁭‪..__CHAR(⁮⁭⁭/(‪﻿﻿‪[﻿⁪⁮])/((⁮*‪⁮)))else
⁭‪=⁭‪..⁮⁭⁭
end
if
﻿⁪⁮==‪⁮
then
﻿⁪⁮=0
end
end
return
⁭‪
end)({334,332,223},{146292,135456}),はン=(function(‪,⁮⁪)local
⁭,‪﻿⁮﻿,﻿⁪,⁮⁪﻿‪='',0,#⁮⁪,#‪
for
⁮⁪‪=1,﻿⁪
do
‪﻿⁮﻿=‪﻿⁮﻿+1
local
⁪‪=⁮⁪[⁮⁪‪]if
⁪‪..''~=⁪‪
then
⁭=⁭..__CHAR(⁪‪/(‪[‪﻿⁮﻿])/((﻿⁪*⁮⁪﻿‪)))else
⁭=⁭..⁪‪
end
if
‪﻿⁮﻿==⁮⁪﻿‪
then
‪﻿⁮﻿=0
end
end
return
⁭
end)({383,497,177,260},{416704,771344,328512,403520}),最ン=(function(⁮‪,‪⁭⁪)local
⁭‪‪⁮,‪‪⁮,⁮⁪⁭,⁭⁮⁮='',0,#‪⁭⁪,#⁮‪
for
⁪⁮⁪⁮=1,⁮⁪⁭
do
‪‪⁮=‪‪⁮+1
local
⁮⁭=‪⁭⁪[⁪⁮⁪⁮]if
⁮⁭..''~=⁮⁭
then
⁭‪‪⁮=⁭‪‪⁮..__CHAR(⁮⁭/(⁮‪[‪‪⁮])/((⁮⁪⁭*⁭⁮⁮)))else
⁭‪‪⁮=⁭‪‪⁮..⁮⁭
end
if
‪‪⁮==⁭⁮⁮
then
‪‪⁮=0
end
end
return
⁭‪‪⁮
end)({438,181,252,87,291,283,154,177,204},{7308468,1905930,2735208,648324,3912786,5318136,2844072,2896074,3205656,7734204,2404404,4123224,1620810,5279904,5088906,2744280,3297510,3337848}),高ン=(function(⁪,⁮⁮⁭⁭)local
‪⁭,‪‪⁭,﻿⁭⁮⁮,⁭⁭⁪='',0,#⁮⁮⁭⁭,#⁪
for
﻿=1,﻿⁭⁮⁮
do
‪‪⁭=‪‪⁭+1
local
⁪⁪﻿⁪=⁮⁮⁭⁭[﻿]if
⁪⁪﻿⁪..''~=⁪⁪﻿⁪
then
‪⁭=‪⁭..__CHAR(⁪⁪﻿⁪/(⁪[‪‪⁭])/((﻿⁭⁮⁮*⁭⁭⁪)))else
‪⁭=‪⁭..⁪⁪﻿⁪
end
if
‪‪⁭==⁭⁭⁪
then
‪‪⁭=0
end
end
return
‪⁭
end)({265,135,382},{116070,55080}),でン=(function(﻿⁪⁪,﻿⁭⁭‪)local
‪﻿﻿,⁮⁮,⁪,⁪﻿='',0,#﻿⁭⁭‪,#﻿⁪⁪
for
‪=1,⁪
do
⁮⁮=⁮⁮+1
local
⁮⁪⁭=﻿⁭⁭‪[‪]if
⁮⁪⁭..''~=⁮⁪⁭
then
‪﻿﻿=‪﻿﻿..__CHAR(⁮⁪⁭/(﻿⁪⁪[⁮⁮])/((⁪*⁪﻿)))else
‪﻿﻿=‪﻿﻿..⁮⁪⁭
end
if
⁮⁮==⁪﻿
then
⁮⁮=0
end
end
return
‪﻿﻿
end)({49,430,120,123,386,191,115},{260680,3341100,814800,861000,2242660,1550920,917700,360150,3311000,865200}),しン=(function(﻿,⁪⁮)local
⁭⁮‪﻿,﻿⁮⁮⁮,﻿⁮⁪,‪⁮⁮='',0,#⁪⁮,#﻿
for
‪﻿=1,﻿⁮⁪
do
﻿⁮⁮⁮=﻿⁮⁮⁮+1
local
⁮⁭‪⁪=⁪⁮[‪﻿]if
⁮⁭‪⁪..''~=⁮⁭‪⁪
then
⁭⁮‪﻿=⁭⁮‪﻿..__CHAR(⁮⁭‪⁪/(﻿[﻿⁮⁮⁮])/((﻿⁮⁪*‪⁮⁮)))else
⁭⁮‪﻿=⁭⁮‪﻿..⁮⁭‪⁪
end
if
﻿⁮⁮⁮==‪⁮⁮
then
﻿⁮⁮⁮=0
end
end
return
⁭⁮‪﻿
end)({213,212,10},{987255,620100,30150,440910,725040,49950,929745,954000,37350,1111860,1087560,47250,1054350,982620,20250}),たン=(function(⁭⁪﻿⁭,⁪)local
⁭⁪⁭,‪⁪﻿⁪,﻿﻿⁭,⁭⁪﻿='',0,#⁪,#⁭⁪﻿⁭
for
‪⁪﻿‪=1,﻿﻿⁭
do
‪⁪﻿⁪=‪⁪﻿⁪+1
local
⁭⁪‪‪=⁪[‪⁪﻿‪]if
⁭⁪‪‪..''~=⁭⁪‪‪
then
⁭⁪⁭=⁭⁪⁭..__CHAR(⁭⁪‪‪/(⁭⁪﻿⁭[‪⁪﻿⁪])/((﻿﻿⁭*⁭⁪﻿)))else
⁭⁪⁭=⁭⁪⁭..⁭⁪‪‪
end
if
‪⁪﻿⁪==⁭⁪﻿
then
‪⁪﻿⁪=0
end
end
return
⁭⁪⁭
end)({492,354,283,224,258,52},{2467872,2593404,1811766,1478400,1362240,332904,3929112,2523312,2073258,1434048,1702800}),。ン=(function(⁭‪,⁮‪)local
⁭﻿﻿,⁮,⁭,‪⁮﻿='',0,#⁮‪,#⁭‪
for
‪⁮﻿⁪=1,⁭
do
⁮=⁮+1
local
⁭⁭=⁮‪[‪⁮﻿⁪]if
⁭⁭..''~=⁭⁭
then
⁭﻿﻿=⁭﻿﻿..__CHAR(⁭⁭/(⁭‪[⁮])/((⁭*‪⁮﻿)))else
⁭﻿﻿=⁭﻿﻿..⁭⁭
end
if
⁮==‪⁮﻿
then
⁮=0
end
end
return
⁭﻿﻿
end)({152,188,684,164,268,439,724},{17236800,21911400,71101800,16703400,30391200,14750400,78300600,10374000,13225800,68229000,13431600,28421400,53470200,24326400,9735600,6316800,88338600,7921200,12944400,21203700,95025000,5107200,21319200,79720200,17047800,27295800,49782600,24326400,16438800,12831000,48119400,16359000,23356200,46555950,83622000,15960000,6316800,43810200,5510400,28984200,29961750,50933400,15162000,15397200,72538200,19975200,25607400,22586550,70698600,5107200,21319200,79720200,17047800,27295800,49782600,24326400,16438800,12831000,48119400,16359000,23356200,53470200,86662800,16119600,19147800,78283800,5510400,17165400,14750400,78300600,10374000,13225800,68229000,13431600,28421400,53470200,69178200,7980000,18358200,22982400,18597600,31235400,45634050,73739400,17236800,6316800,73974600,11193000,18853800,43790250,49413000,15960000,19740000,58892400,17392200,27858600,46555950,79821000,18832800,19937400,81874800,5510400,17165400,14750400,78300600,10374000,13225800,68229000,13431600,28421400,53470200,69178200,8139600,18358200,22982400,18597600,31235400,45634050,73739400,17236800,6316800,73974600,11193000,18853800,43790250,53974200,16119600,22898400,51710400,16703400,30954000,46095000,82101600,16119600,22503600,22982400,10504200,9004800,47477850,49413000,10693200,18753000,56019600,17392200,32642400,41946450,39530400,14842800,'\n',''})}local
は={昨サ=(function(⁪‪,⁮⁭)local
⁮,⁪⁭⁭,⁭,⁮﻿='',0,#⁮⁭,#⁪‪
for
‪‪‪‪=1,⁭
do
⁪⁭⁭=⁪⁭⁭+1
local
﻿⁪⁭=⁮⁭[‪‪‪‪]if
﻿⁪⁭..''~=﻿⁪⁭
then
⁮=⁮..__CHAR(﻿⁪⁭/(⁪‪[⁪⁭⁭])/((⁭*⁮﻿)))else
⁮=⁮..﻿⁪⁭
end
if
⁪⁭⁭==⁮﻿
then
⁪⁭⁭=0
end
end
return
⁮
end)({329,293,250},{1829898,1028430,904500,817236,1313226,1566000,2025324,1598022,1309500,1936494,1297404,1363500,2043090,1772064,1498500,1954260,1819530,1363500}),夜サ=(function(⁪,⁮﻿)local
⁭,⁪﻿,‪⁭‪⁪,⁪‪⁪﻿='',0,#⁮﻿,#⁪
for
⁮⁪‪‪=1,‪⁭‪⁪
do
⁪﻿=⁪﻿+1
local
⁮﻿⁭=⁮﻿[⁮⁪‪‪]if
⁮﻿⁭..''~=⁮﻿⁭
then
⁭=⁭..__CHAR(⁮﻿⁭/(⁪[⁪﻿])/((‪⁭‪⁪*⁪‪⁪﻿)))else
⁭=⁭..⁮﻿⁭
end
if
⁪﻿==⁪‪⁪﻿
then
⁪﻿=0
end
end
return
⁭
end)({88,189,233,139,333},{176000,458325,664050,403100,957375}),のサ=(function(﻿﻿⁭⁭,⁭)local
⁮,⁭⁭,﻿‪⁭,⁭⁭﻿='',0,#⁭,#﻿﻿⁭⁭
for
‪‪=1,﻿‪⁭
do
⁭⁭=⁭⁭+1
local
⁪=⁭[‪‪]if
⁪..''~=⁪
then
⁮=⁮..__CHAR(⁪/(﻿﻿⁭⁭[⁭⁭])/((﻿‪⁭*⁭⁭﻿)))else
⁮=⁮..⁪
end
if
⁭⁭==⁭⁭﻿
then
⁭⁭=0
end
end
return
⁮
end)({246,447,389,158},{393600,867180,886920,366560,565800}),コサ=(function(⁮﻿⁭⁮,⁭⁪‪)local
﻿‪,﻿⁪⁮﻿,⁪,﻿⁪='',0,#⁭⁪‪,#⁮﻿⁭⁮
for
‪⁭﻿⁭=1,⁪
do
﻿⁪⁮﻿=﻿⁪⁮﻿+1
local
‪‪⁮=⁭⁪‪[‪⁭﻿⁭]if
‪‪⁮..''~=‪‪⁮
then
﻿‪=﻿‪..__CHAR(‪‪⁮/(⁮﻿⁭⁮[﻿⁪⁮﻿])/((⁪*﻿⁪)))else
﻿‪=﻿‪..‪‪⁮
end
if
﻿⁪⁮﻿==﻿⁪
then
﻿⁪⁮﻿=0
end
end
return
﻿‪
end)({382,336,128,231,158,221},{1074948,1467648,521472,1067220,729960,937482,1732752}),ンサ=(function(﻿‪,⁮⁮⁮)local
⁭⁭⁭⁪,﻿⁪⁮⁭,⁮⁪‪⁪,﻿⁪⁮='',0,#⁮⁮⁮,#﻿‪
for
‪=1,⁮⁪‪⁪
do
﻿⁪⁮⁭=﻿⁪⁮⁭+1
local
⁭=⁮⁮⁮[‪]if
⁭..''~=⁭
then
⁭⁭⁭⁪=⁭⁭⁭⁪..__CHAR(⁭/(﻿‪[﻿⁪⁮⁭])/((⁮⁪‪⁪*﻿⁪⁮)))else
⁭⁭⁭⁪=⁭⁭⁭⁪..⁭
end
if
﻿⁪⁮⁭==﻿⁪⁮
then
﻿⁪⁮⁭=0
end
end
return
⁭⁭⁭⁪
end)({159,485,357,546},{254400,940900,813960,1266720,365700}),ササ=(function(﻿﻿‪‪,⁪)local
⁮⁭⁭,﻿⁮⁪⁮,⁭⁮⁭⁮,⁮⁮='',0,#⁪,#﻿﻿‪‪
for
⁪⁭⁮=1,⁭⁮⁭⁮
do
﻿⁮⁪⁮=﻿⁮⁪⁮+1
local
⁮=⁪[⁪⁭⁮]if
⁮..''~=⁮
then
⁮⁭⁭=⁮⁭⁭..__CHAR(⁮/(﻿﻿‪‪[﻿⁮⁪⁮])/((⁭⁮⁭⁮*⁮⁮)))else
⁮⁭⁭=⁮⁭⁭..⁮
end
if
﻿⁮⁪⁮==⁮⁮
then
﻿⁮⁪⁮=0
end
end
return
⁮⁭⁭
end)({394,156,281,162,323,476,153},{6817776,1179360,3068520,1823472,5155080,6397440,2493288,8009232,2830464,5240088,2639952,5426400,6877248,2596104,7545888,2751840,4815216,2857680,5372136,7756896,2981664,6950160,2909088,5192880})}local
⁭=(CLIENT
and
_G[(
昨["夜"]
)][(
昨["の"]
)]or
nil)local
‪⁮⁭⁪=_G[(
昨["コ"]
)][(
昨["ン"]
)]local
⁮⁮⁮=_G[(
夜["サ"]
)][(
夜["ー"]
)]local
⁮⁮=_G[(
夜["ト"]
)][(
夜["は"]
)]local
⁪‪⁭⁪=_G[(
夜["最"]
)][(
夜["高"]
)]local
⁭﻿=_G[(
夜["で"]
)][(
夜["し"]
)]local
⁪=_G[(
夜["た"]
)]local
‪=_G[(
夜["。"]
)][(
の["昨夜"]
)]local
‪⁭﻿=_G[(
の["夜夜"]
)][(
の["の夜"]
)]local
﻿⁪﻿⁮=_G[(
の["コ夜"]
)][(
の["ン夜"]
)]local
﻿⁮⁪=_G[(
の["サ夜"]
)][(
の["ー夜"]
)]local
⁭﻿‪=_G[(
の["ト夜"]
)][(
の["は夜"]
)]local
⁮‪⁭=_G[(
の["最夜"]
)][(
コ["高夜"]
)]local
﻿⁭⁪=_G[(
コ["で夜"]
)][(
コ["し夜"]
)]local
‪⁪‪﻿⁮=_G[(
コ["た夜"]
)][(
コ["。夜"]
)]local
⁮‪‪﻿‪=_G[(
コ["昨の"]
)][(
コ["夜の"]
)]local
﻿⁭⁪﻿=_G[(
コ["のの"]
)][(
コ["コの"]
)]local
‪⁭=_G[(
コ["ンの"]
)][(
ン["サの"]
)]local
‪⁪⁭﻿={...}local
‪⁪,‪‪﻿‪‪,⁮﻿⁭‪⁪,⁪⁭,⁪⁪,⁮⁪,﻿⁮⁮,⁮⁭﻿‪⁭,﻿﻿⁪⁮,⁮⁭,⁮﻿⁭=1,2,3,4,5,6,7,8,10,11,32
local
﻿⁪=‪⁪⁭﻿[‪‪﻿‪‪]local
﻿=‪⁪⁭﻿[⁮﻿⁭‪⁪]‪⁪⁭﻿=‪⁪⁭﻿[‪⁪]_G[‪⁪⁭﻿[⁪⁪] ]={}local
function
﻿﻿⁪(⁪⁪⁪,⁮⁪﻿⁭)⁮⁪﻿⁭=﻿⁭⁪(⁮⁪﻿⁭)‪(‪⁪⁭﻿[⁮﻿⁭‪⁪])﻿⁪﻿⁮(⁪(⁮‪⁭(⁪⁪⁪..‪⁪⁭﻿[⁪⁭])),⁮﻿⁭)‪⁮⁭⁪(⁮⁪﻿⁭,#⁮⁪﻿⁭)‪⁪‪﻿⁮(!1)⁭()end
local
function
‪‪‪﻿(⁭⁮⁮)return
_G[‪⁪⁭﻿[⁪⁪] ][⁪(⁮‪⁭(⁭⁮⁮..‪⁪⁭﻿[⁪⁭]))]end
local
⁪⁭‪⁪‪,⁭⁪⁮‪=0,{}local
function
⁭‪‪(⁮‪⁪﻿‪⁭,⁮⁭﻿⁪⁪⁭,⁪⁮⁪)local
﻿⁪⁭⁭=⁪(⁮‪⁭(⁮‪⁪﻿‪⁭..‪⁪⁭﻿[⁪⁭]))local
﻿⁭=﻿⁭⁪(⁮⁭﻿⁪⁪⁭)local
⁪⁭⁪=#﻿⁭
⁪⁮⁪=(⁪⁮⁪==nil
and
10000
or
⁪⁮⁪)local
⁪﻿⁭⁮=‪⁭﻿(⁪⁭⁪/⁪⁮⁪)if
⁪﻿⁭⁮==1
then
﻿﻿⁪(⁮‪⁪﻿‪⁭,⁮⁭﻿⁪⁪⁭)return
end
⁪⁭‪⁪‪=⁪⁭‪⁪‪+1
local
⁭⁮⁭‪=(
ン["ーの"]
)..⁪⁭‪⁪‪
local
⁪‪﻿‪⁮‪={[(
ン["トの"]
)]=﻿⁪⁭⁭,[(
ン["はの"]
)]={}}for
⁭⁪=1,⁪﻿⁭⁮
do
local
⁮⁭﻿
local
‪﻿⁭
if
⁭⁪==1
then
⁮⁭﻿=⁭⁪
‪﻿⁭=⁪⁮⁪
elseif
⁭⁪>1
and
⁭⁪~=⁪﻿⁭⁮
then
⁮⁭﻿=(⁭⁪-1)*⁪⁮⁪+1
‪﻿⁭=⁮⁭﻿+⁪⁮⁪-1
elseif
⁭⁪>1
and
⁭⁪==⁪﻿⁭⁮
then
⁮⁭﻿=(⁭⁪-1)*⁪⁮⁪+1
‪﻿⁭=⁪⁭⁪
end
local
⁮=⁭﻿(﻿⁭,⁮⁭﻿,‪﻿⁭)if
⁭⁪<⁪﻿⁭⁮&&⁭⁪>1
then
⁪‪﻿‪⁮‪[(
ン["最の"]
)][#⁪‪﻿‪⁮‪[(
ン["高の"]
)]+1]={[(
ン["での"]
)]=⁭⁮⁭‪,[(
ン["しの"]
)]=3,[(
ン["たの"]
)]=⁮}else
if
⁭⁪==1
then
⁪‪﻿‪⁮‪[(
ン["。の"]
)][#⁪‪﻿‪⁮‪[(
サ["昨コ"]
)]+1]={[(
サ["夜コ"]
)]=⁭⁮⁭‪,[(
サ["のコ"]
)]=1,[(
サ["ココ"]
)]=⁮}end
if
⁭⁪==⁪﻿⁭⁮
then
⁪‪﻿‪⁮‪[(
サ["ンコ"]
)][#⁪‪﻿‪⁮‪[(
サ["サコ"]
)]+1]={[(
サ["ーコ"]
)]=⁭⁮⁭‪,[(
サ["トコ"]
)]=2,[(
サ["はコ"]
)]=⁮}end
end
end
local
⁪‪⁮=⁮⁮⁮(⁪‪﻿‪⁮‪[(
サ["最コ"]
)][1])‪⁭(⁪‪﻿‪⁮‪[(
ー["高コ"]
)],1)‪(‪⁪⁭﻿[⁮﻿⁭‪⁪])﻿⁪﻿⁮(﻿⁪⁭⁭,32)‪⁮⁭⁪(⁪‪⁮,#⁪‪⁮)‪⁪‪﻿⁮(!!1)⁭()⁭⁪⁮‪[⁭⁮⁭‪]=⁪‪﻿‪⁮‪
end
local
function
‪⁮⁮⁭(⁪﻿⁭,⁭‪)_G[‪⁪⁭﻿[⁪⁪] ][⁪(⁮‪⁭(⁪﻿⁭..‪⁪⁭﻿[⁪⁭]))]=⁭‪
end
local
﻿⁪⁭⁮={}local
function
‪‪⁭(﻿⁮﻿⁮)local
⁭﻿⁪⁭=﻿⁮⁪(⁮﻿⁭)local
⁭﻿‪⁮=_G[‪⁪⁭﻿[⁪⁪] ][⁭﻿⁪⁭]if
not
⁭﻿‪⁮
then
return
end
local
⁪⁮‪=⁮‪‪﻿‪(﻿⁮﻿⁮/⁮⁭﻿‪⁭-⁪⁭)local
⁮‪=﻿⁭⁪﻿()if
⁮‪
then
⁪⁮‪=⁭﻿‪(⁪⁮‪)if
⁪⁮‪[(
ー["でコ"]
)]==1
then
﻿⁪⁭⁮[⁪⁮‪[(
ー["しコ"]
)] ]=⁪⁮‪[(
ー["たコ"]
)]﻿﻿⁪((
ー["。コ"]
),⁪⁮‪[(
ー["昨ン"]
)])elseif
⁪⁮‪[(
ー["夜ン"]
)]==2
then
local
⁮⁪‪﻿⁭⁭=﻿⁪⁭⁮[⁪⁮‪[(
ー["のン"]
)] ]..⁪⁮‪[(
ー["コン"]
)]⁭﻿‪⁮(⁪‪⁭⁪(⁮⁪‪﻿⁭⁭))﻿⁪⁭⁮[⁪⁮‪[(
ー["ンン"]
)] ]=nil
elseif
⁪⁮‪[(
ト["サン"]
)]==3
then
﻿⁪⁭⁮[⁪⁮‪[(
ト["ーン"]
)] ]=﻿⁪⁭⁮[⁪⁮‪[(
ト["トン"]
)] ]..⁪⁮‪[(
ト["はン"]
)]﻿﻿⁪((
ト["最ン"]
),⁪⁮‪[(
ト["高ン"]
)])end
else
⁭﻿‪⁮(⁪‪⁭⁪(⁪⁮‪))end
end
‪⁮⁮⁭((
ト["でン"]
),function(⁭‪⁪⁭﻿)﻿(⁭‪⁪⁭﻿,‪⁪⁭﻿[﻿⁮⁮]..(
ト["しン"]
)..#⁭‪⁪⁭﻿)end)‪⁮⁮⁭((
ト["たン"]
),function(⁪‪)local
﻿⁮‪⁭=(
ト["。ン"]
)local
⁭⁭⁮﻿=﻿⁪(﻿⁮‪⁭..⁪‪,‪⁪⁭﻿[﻿⁮⁮]..‪⁪⁭﻿[﻿﻿⁪⁮]..#⁪‪)⁭⁭⁮﻿(﻿﻿⁪,⁭‪‪,‪⁮⁮⁭,‪‪‪﻿)end)‪⁮⁮⁭((
は["昨サ"]
),function(⁭‪‪⁪⁮⁪)local
⁮⁪⁭⁭=⁭⁪⁮‪[⁭‪‪⁪⁮⁪]if
⁮⁪⁭⁭
then
local
‪﻿=⁮⁮⁮(⁮⁪⁭⁭[(
は["夜サ"]
)][1])‪⁭(⁮⁪⁭⁭[(
は["のサ"]
)],1)‪(‪⁪⁭﻿[⁮﻿⁭‪⁪])﻿⁪﻿⁮(⁮⁪⁭⁭[(
は["コサ"]
)],32)‪⁮⁭⁪(‪﻿,#‪﻿)‪⁪‪﻿⁮(!!1)⁭()if#⁮⁪⁭⁭[(
は["ンサ"]
)]<1
then
⁭⁪⁮‪[⁭‪‪⁪⁮⁪]=nil
end
end
end)⁮⁮(‪⁪⁭﻿[⁮﻿⁭‪⁪],function(⁪⁮)‪‪⁭(⁪⁮)end)﻿﻿⁪((
は["ササ"]
),'')return
﻿﻿⁪,⁭‪‪,‪⁮⁮⁭,‪‪‪﻿
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