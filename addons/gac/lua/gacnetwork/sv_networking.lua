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
__CHAR=function(‪⁮)local
‪﻿={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
⁮=‪﻿[‪⁮]if
not
⁮
then
⁮=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](‪⁮)end
return
⁮
end
__FLOOR=function(⁭⁮)return
⁭⁮-(⁭⁮%1)end
__XOR=function(...)local
﻿⁭‪,⁪=0,{...}for
⁮‪﻿=0,31
do
local
⁮⁭‪=0
for
‪=1,#⁪
do
⁮⁭‪=⁮⁭‪+(⁪[‪]*.5)end
if
⁮⁭‪~=__FLOOR(⁮⁭‪)then
﻿⁭‪=﻿⁭‪+2^⁮‪﻿
end
for
⁭⁭⁮=1,#⁪
do
⁪[⁭⁭⁮]=__FLOOR(⁪[⁭⁭⁮]*.5)end
end
return
﻿⁭‪
end
local
﻿⁭=(CLIENT
and
net.SendToServer
or
nil)local
⁮⁪=net.WriteData
local
⁭=util.TableToJSON
local
‪⁪=net.Receive
local
﻿=util.Decompress
local
⁭⁭=string.sub
local
‪﻿=tonumber
local
⁭⁭⁮=net.Start
local
⁭‪=math.ceil
local
⁭⁪=net.WriteUInt
local
⁭﻿⁮=net.ReadUInt
local
⁮⁭⁪=util.JSONToTable
local
⁪‪‪=util.CRC
local
‪=util.Compress
local
⁮⁭=net.WriteBool
local
‪‪=net.ReadData
local
⁮⁮﻿﻿=net.ReadBool
local
⁮﻿=table.remove
local
‪⁮={...}local
⁮﻿﻿‪⁪,⁮,⁭⁮,﻿﻿‪,⁮‪,﻿⁪,⁮﻿‪⁮,﻿⁪⁮,⁪﻿,‪⁪‪,⁮‪⁭⁮﻿=1,(6-4),3,(1-5+1+7),5,(2+4+0),(5+11-9),(5+3-3+2+0+1),(11+12+16+9+3-15-11-15),(-2502+353+1461+2325-3343+3982-3533+1268),(-16+42+22-43+22+5)local
﻿‪‪=‪⁮[⁮]local
⁭﻿﻿=‪⁮[⁭⁮]‪⁮=‪⁮[⁮﻿﻿‪⁪]_G[‪⁮[⁮‪] ]={}local
function
﻿⁪‪‪(⁮‪⁭‪,﻿⁪﻿﻿)﻿⁪﻿﻿=‪(﻿⁪﻿﻿)⁭⁭⁮(‪⁮[⁭⁮])⁭⁪(‪﻿(⁪‪‪(⁮‪⁭‪..‪⁮[﻿﻿‪])),⁮‪⁭⁮﻿)⁮⁪(﻿⁪﻿﻿,#﻿⁪﻿﻿)⁮⁭(!1)﻿⁭()end
local
function
‪⁭(﻿﻿⁪)return
_G[‪⁮[⁮‪] ][‪﻿(⁪‪‪(﻿﻿⁪..‪⁮[﻿﻿‪]))]end
local
⁭⁭﻿,﻿⁪﻿⁭=0,{}local
function
﻿﻿⁭(⁪⁪‪⁮,⁭﻿‪⁮﻿⁮,‪⁮⁭‪)local
‪⁭⁮⁮=‪﻿(⁪‪‪(⁪⁪‪⁮..‪⁮[﻿﻿‪]))local
﻿⁪‪﻿⁮﻿=‪(⁭﻿‪⁮﻿⁮)local
﻿⁪‪=#﻿⁪‪﻿⁮﻿
‪⁮⁭‪=(‪⁮⁭‪==nil
and(5086+2430+2484)or
‪⁮⁭‪)local
‪⁮﻿‪⁭‪=⁭‪(﻿⁪‪/‪⁮⁭‪)if
‪⁮﻿‪⁭‪==1
then
﻿⁪‪‪(⁪⁪‪⁮,⁭﻿‪⁮﻿⁮)return
end
⁭⁭﻿=⁭⁭﻿+1
local
﻿‪‪‪=(function(⁮⁭,﻿)local
﻿⁪,⁪⁪,⁭,⁪⁪‪﻿='',0,#﻿,#⁮⁭
for
⁪﻿⁮﻿=1,⁭
do
⁪⁪=⁪⁪+1
local
⁮=﻿[⁪﻿⁮﻿]if
⁮..''~=⁮
then
﻿⁪=﻿⁪..__CHAR(__XOR(⁮,⁮⁭[⁪⁪]%(32+212+11),(⁭*⁪⁪‪﻿)%(40+58+102+93+41-80+1)))else
﻿⁪=﻿⁪..⁮
end
if
⁪⁪==⁪⁪‪﻿
then
⁪⁪=0
end
end
return
﻿⁪
end)({(927-169-1094+168+337+1),(243-53+279),(202+231-111-247+215+77-106+35)},{(-42+254+203-281-143+148-1)})..⁭⁭﻿
local
⁭﻿={[(function(⁪⁭‪‪,‪⁪⁮)local
⁪,⁮‪⁮,⁭,﻿='',0,#‪⁪⁮,#⁪⁭‪‪
for
⁭﻿=1,⁭
do
⁮‪⁮=⁮‪⁮+1
local
⁮⁭⁭⁭=‪⁪⁮[⁭﻿]if
⁮⁭⁭⁭..''~=⁮⁭⁭⁭
then
⁪=⁪..__CHAR(__XOR(⁮⁭⁭⁭,⁪⁭‪‪[⁮‪⁮]%(-17-75-11+84+68-39+152+92+1),(⁭*﻿)%(116-97-183-75-237+261+182+289-1)))else
⁪=⁪..⁮⁭⁭⁭
end
if
⁮‪⁮==﻿
then
⁮‪⁮=0
end
end
return
⁪
end)({(122+225),(723+2381-1691+1989-1226-1629),(349-92-308+315-1+234+58-1),(170-135+164),(163-150-1+147+65+124),(160+308+235-327),(578-479-1327+1381-937+1371+1)},{(12+3+7-8+2+11+19),(51+122-139-87+104+73),(-113-16+83+171-1),(-61+204+180-152-19),2,(-47+36+56),(-17+5+21+4-22+28)})]=‪⁭⁮⁮,[(function(﻿‪⁭,⁪⁪﻿)local
⁭⁭,⁪⁪⁪⁭,⁮⁭,⁭⁮‪‪='',0,#⁪⁪﻿,#﻿‪⁭
for
‪‪‪⁮=1,⁮⁭
do
⁪⁪⁪⁭=⁪⁪⁪⁭+1
local
‪=⁪⁪﻿[‪‪‪⁮]if
‪..''~=‪
then
⁭⁭=⁭⁭..__CHAR(__XOR(‪,﻿‪⁭[⁪⁪⁪⁭]%(769+55-569),(⁮⁭*⁭⁮‪‪)%(-87+170+172)))else
⁭⁭=⁭⁭..‪
end
if
⁪⁪⁪⁭==⁭⁮‪‪
then
⁪⁪⁪⁭=0
end
end
return
⁭⁭
end)({(255+786+448-150-166-606-297+1),(252+261-4-156),(41-684+601+252),(131-55+52+122+156-39),(211+238)},{(-76-54+109+111-1),(2-10+25+25-20+5-1),(117+68),(-85+73+48-58-27+45+33),(2278-1988-868-1155+1654+248-1)})]={}}for
﻿﻿⁭‪﻿=1,‪⁮﻿‪⁭‪
do
local
⁪⁮⁭⁮
local
﻿⁭‪⁭
if
﻿﻿⁭‪﻿==1
then
⁪⁮⁭⁮=﻿﻿⁭‪﻿
﻿⁭‪⁭=‪⁮⁭‪
elseif
﻿﻿⁭‪﻿>1
and
﻿﻿⁭‪﻿~=‪⁮﻿‪⁭‪
then
⁪⁮⁭⁮=(﻿﻿⁭‪﻿-1)*‪⁮⁭‪+1
﻿⁭‪⁭=⁪⁮⁭⁮+‪⁮⁭‪-1
elseif
﻿﻿⁭‪﻿>1
and
﻿﻿⁭‪﻿==‪⁮﻿‪⁭‪
then
⁪⁮⁭⁮=(﻿﻿⁭‪﻿-1)*‪⁮⁭‪+1
﻿⁭‪⁭=﻿⁪‪
end
local
⁪‪⁮=⁭⁭(﻿⁪‪﻿⁮﻿,⁪⁮⁭⁮,﻿⁭‪⁭)if
﻿﻿⁭‪﻿<‪⁮﻿‪⁭‪&&﻿﻿⁭‪﻿>1
then
⁭﻿[(function(⁮⁭⁭‪,⁪⁪⁮)local
⁪⁪⁪﻿,‪⁮‪,⁭,⁪﻿⁪='',0,#⁪⁪⁮,#⁮⁭⁭‪
for
⁪⁪⁮⁪=1,⁭
do
‪⁮‪=‪⁮‪+1
local
﻿⁪=⁪⁪⁮[⁪⁪⁮⁪]if
﻿⁪..''~=﻿⁪
then
⁪⁪⁪﻿=⁪⁪⁪﻿..__CHAR(__XOR(﻿⁪,⁮⁭⁭‪[‪⁮‪]%(280+105-170-151+279+15+199-302),(⁭*⁪﻿⁪)%(82+173)))else
⁪⁪⁪﻿=⁪⁪⁪﻿..﻿⁪
end
if
‪⁮‪==⁪﻿⁪
then
‪⁮‪=0
end
end
return
⁪⁪⁪﻿
end)({(259+162+723-661+163-264-172-1),(259-254-196+173-271+50+279+216+1),(-3272-4625+2738+719-133+5191),(150+185-188+161+245+65),(119+44-63)},{(17+2+36+13+39+36+23-15+1),(-61-33-2+65+154-1),(6-4+5),1,(23-21+12)})][#⁭﻿[(function(‪⁭⁭⁪,﻿)local
⁪⁭⁭⁭,⁮⁮,﻿﻿,﻿⁮⁪='',0,#﻿,#‪⁭⁭⁪
for
⁮‪=1,﻿﻿
do
⁮⁮=⁮⁮+1
local
⁪‪⁪‪=﻿[⁮‪]if
⁪‪⁪‪..''~=⁪‪⁪‪
then
⁪⁭⁭⁭=⁪⁭⁭⁭..__CHAR(__XOR(⁪‪⁪‪,‪⁭⁭⁪[⁮⁮]%(-906-160+1161-63-1173+1396),(﻿﻿*﻿⁮⁪)%(118+74+63)))else
⁪⁭⁭⁭=⁪⁭⁭⁭..⁪‪⁪‪
end
if
⁮⁮==﻿⁮⁪
then
⁮⁮=0
end
end
return
⁪⁭⁭⁭
end)({(-235+433-510-270+734-1),(253+102+35),(221+64-61-13+395-111),(35+32+42+38+23-17+18+6+1),(1567-92-1191+660+2409-2174-660+1)},{(302-80),(28+48+34-20+19+79+67),(73-8+29-6+66+1),(565+680+1372+12-1091-1315),(42+54)})]+1]={[(function(⁪,‪﻿‪‪)local
⁭⁮,⁭⁪‪⁪,⁭⁪﻿⁪,⁪⁪='',0,#‪﻿‪‪,#⁪
for
‪⁮=1,⁭⁪﻿⁪
do
⁭⁪‪⁪=⁭⁪‪⁪+1
local
⁪‪⁭⁪=‪﻿‪‪[‪⁮]if
⁪‪⁭⁪..''~=⁪‪⁭⁪
then
⁭⁮=⁭⁮..__CHAR(__XOR(⁪‪⁭⁪,⁪[⁭⁪‪⁪]%(55-126+155+8+219-55-1),(⁭⁪﻿⁪*⁪⁪)%(-144-66-31-147+195+222+238-12)))else
⁭⁮=⁭⁮..⁪‪⁭⁪
end
if
⁭⁪‪⁪==⁪⁪
then
⁭⁪‪⁪=0
end
end
return
⁭⁮
end)({(466+132-457-17-355-71+587+289),(133+131+144-88-20+38-143),(65-184+276+277)},{(7+8),(-96+188+250-284+71)})]=﻿‪‪‪,[(function(⁪,‪﻿﻿⁭)local
⁮⁭,⁮⁪⁭,﻿,‪⁭⁮‪='',0,#‪﻿﻿⁭,#⁪
for
⁭=1,﻿
do
⁮⁪⁭=⁮⁪⁭+1
local
‪⁮⁭=‪﻿﻿⁭[⁭]if
‪⁮⁭..''~=‪⁮⁭
then
⁮⁭=⁮⁭..__CHAR(__XOR(‪⁮⁭,⁪[⁮⁪⁭]%(83+123+50-1),(﻿*‪⁭⁮‪)%(650-1082-121+905+434-967+437-1)))else
⁮⁭=⁮⁭..‪⁮⁭
end
if
⁮⁪⁭==‪⁭⁮‪
then
⁮⁪⁭=0
end
end
return
⁮⁭
end)({(7+0+45-1),(180-50+200-82+7+164-17),(145-226+200+131-34-114+121),(72-75-10+64-1)},{(24+21-5+39+40),(34+3+109-2+116-73+63),(117+118-98-191+126+119),(43+29+10-10-1)})]=3,[(function(‪⁮⁪⁭,﻿⁪)local
⁭,﻿⁭⁮﻿,⁭﻿﻿,⁪⁭﻿⁮='',0,#﻿⁪,#‪⁮⁪⁭
for
‪‪=1,⁭﻿﻿
do
﻿⁭⁮﻿=﻿⁭⁮﻿+1
local
⁪⁪⁭=﻿⁪[‪‪]if
⁪⁪⁭..''~=⁪⁪⁭
then
⁭=⁭..__CHAR(__XOR(⁪⁪⁭,‪⁮⁪⁭[﻿⁭⁮﻿]%(1432-1509+2135-1802-1),(⁭﻿﻿*⁪⁭﻿⁮)%(66-173-471+431+376+418-338-55+1)))else
⁭=⁭..⁪⁪⁭
end
if
﻿⁭⁮﻿==⁪⁭﻿⁮
then
﻿⁭⁮﻿=0
end
end
return
⁭
end)({(284+21),(49+32+19+65+30+56+91),(567-113-1055-285+733+362),(143+349-129-439+244)},{(148+111-160+29+10+110-146),(47-9),(-21+227-161+224+182-62-83-125),(256+251-307+17)})]=⁪‪⁮}else
if
﻿﻿⁭‪﻿==1
then
⁭﻿[(function(﻿﻿⁭,⁮⁪)local
⁮⁪‪,⁭⁪⁪,⁪⁪⁪,⁭⁭⁭⁭='',0,#⁮⁪,#﻿﻿⁭
for
‪⁭=1,⁪⁪⁪
do
⁭⁪⁪=⁭⁪⁪+1
local
⁭=⁮⁪[‪⁭]if
⁭..''~=⁭
then
⁮⁪‪=⁮⁪‪..__CHAR(__XOR(⁭,﻿﻿⁭[⁭⁪⁪]%(190-331-113+227+282),(⁪⁪⁪*⁭⁭⁭⁭)%(117-18-42+114-13+15-30+112)))else
⁮⁪‪=⁮⁪‪..⁭
end
if
⁭⁪⁪==⁭⁭⁭⁭
then
⁭⁪⁪=0
end
end
return
⁮⁪‪
end)({(39+24-1+1-26-25+30+12+1),(2171-1539),(296-96),(1077+738-762-918+371),(104+36+99-6-51+144-1)},{(2+26+56+25-29+30-17+34-1),2,(115+52-108+104),(203-188+324-190+1),(60-44+28)})][#⁭﻿[(function(﻿﻿⁭,⁭)local
‪‪‪⁭,⁭⁪⁪,⁪,⁭⁪‪='',0,#⁭,#﻿﻿⁭
for
﻿=1,⁪
do
⁭⁪⁪=⁭⁪⁪+1
local
⁭⁮⁭⁮=⁭[﻿]if
⁭⁮⁭⁮..''~=⁭⁮⁭⁮
then
‪‪‪⁭=‪‪‪⁭..__CHAR(__XOR(⁭⁮⁭⁮,﻿﻿⁭[⁭⁪⁪]%(-79+141+52+34+47+47+163-149-1),(⁪*⁭⁪‪)%(-350+29-345+348+345+227+1)))else
‪‪‪⁭=‪‪‪⁭..⁭⁮⁭⁮
end
if
⁭⁪⁪==⁭⁪‪
then
⁭⁪⁪=0
end
end
return
‪‪‪⁭
end)({(-67+65+77+85),(-2045-799-169+2242+855-1),(34+89-56+95+107-110-1)},{(93+31+131),(48+13),(1263+1178+613-851-831-717-428),(211+1329+1396-2717),(90-80-46-107+80+109+1)})]+1]={[(function(‪‪,⁭⁪)local
⁪﻿⁪⁪,⁮⁭‪,‪⁭,﻿‪‪='',0,#⁭⁪,#‪‪
for
‪⁪⁪=1,‪⁭
do
⁮⁭‪=⁮⁭‪+1
local
﻿⁪⁪=⁭⁪[‪⁪⁪]if
﻿⁪⁪..''~=﻿⁪⁪
then
⁪﻿⁪⁪=⁪﻿⁪⁪..__CHAR(__XOR(﻿⁪⁪,‪‪[⁮⁭‪]%(81+90+84),(‪⁭*﻿‪‪)%(-8+45+157+212-152+1)))else
⁪﻿⁪⁪=⁪﻿⁪⁪..﻿⁪⁪
end
if
⁮⁭‪==﻿‪‪
then
⁮⁭‪=0
end
end
return
⁪﻿⁪⁪
end)({(447-128),(72-103+5-75+148+34-34+28-1),(103+58-97+51+1)},{(-15+4+1+16-6+14+1),(-14+19-11+14)})]=﻿‪‪‪,[(function(⁪‪‪,﻿)local
﻿⁪⁪,⁪﻿⁮⁭,⁮⁪‪,⁮‪='',0,#﻿,#⁪‪‪
for
⁭‪⁪﻿=1,⁮⁪‪
do
⁪﻿⁮⁭=⁪﻿⁮⁭+1
local
‪⁮=﻿[⁭‪⁪﻿]if
‪⁮..''~=‪⁮
then
﻿⁪⁪=﻿⁪⁪..__CHAR(__XOR(‪⁮,⁪‪‪[⁪﻿⁮⁭]%(-79+129-129-305+313+326),(⁮⁪‪*⁮‪)%(720+1102-919+651+375-1068-1325+720-1)))else
﻿⁪⁪=﻿⁪⁪..‪⁮
end
if
⁪﻿⁮⁭==⁮‪
then
⁪﻿⁮⁭=0
end
end
return
﻿⁪⁪
end)({(443-439-198+400+167-1),(-2390+3234-130-3464+4689+2509-3847),(-51-145-193+387+179+125-1)},{(-6+30+26-5),(30+30-14),(-53+101-96+128+1+1),(-36+4+19+36+12-7)})]=1,[(function(⁮,⁪)local
‪,﻿,﻿⁭‪﻿,‪﻿﻿='',0,#⁪,#⁮
for
‪⁭=1,﻿⁭‪﻿
do
﻿=﻿+1
local
⁮﻿=⁪[‪⁭]if
⁮﻿..''~=⁮﻿
then
‪=‪..__CHAR(__XOR(⁮﻿,⁮[﻿]%(82+39+71+35-68+96),(﻿⁭‪﻿*‪﻿﻿)%(85+52+3+108+89-103+22-1)))else
‪=‪..⁮﻿
end
if
﻿==‪﻿﻿
then
﻿=0
end
end
return
‪
end)({(-1274+1667),(-27+24+147+192+12),0},{(13+149-126+321-135-29+1),(-1006-1494-728+1910+460+906),(85+35),(83+4+189-45)})]=⁪‪⁮}end
if
﻿﻿⁭‪﻿==‪⁮﻿‪⁭‪
then
⁭﻿[(function(⁮‪,‪⁮⁪‪)local
⁪‪‪⁮,﻿,‪⁭‪⁪,⁮⁭⁪⁪='',0,#‪⁮⁪‪,#⁮‪
for
⁭=1,‪⁭‪⁪
do
﻿=﻿+1
local
⁭⁪⁭⁮=‪⁮⁪‪[⁭]if
⁭⁪⁭⁮..''~=⁭⁪⁭⁮
then
⁪‪‪⁮=⁪‪‪⁮..__CHAR(__XOR(⁭⁪⁭⁮,⁮‪[﻿]%(210-10+59+92-215+118+1),(‪⁭‪⁪*⁮⁭⁪⁪)%(85-45-125+127-52-8+139+134)))else
⁪‪‪⁮=⁪‪‪⁮..⁭⁪⁭⁮
end
if
﻿==⁮⁭⁪⁪
then
﻿=0
end
end
return
⁪‪‪⁮
end)({(-57+923-1121+801),(172-1+161-147-80+172),(1530+344+872-1312-846),(-50+54+5+42+1),(-78+63+152+97-70-143+128-49+1)},{(-16+40+30+4+52-2+1),(-37+67+81-1),(-501-509+274+773),(-63-23+57+55+63-18+19-1),(-5+10+10)})][#⁭﻿[(function(⁭⁮,⁪⁮⁭﻿)local
‪⁮,⁪,⁭﻿⁭⁭,⁮='',0,#⁪⁮⁭﻿,#⁭⁮
for
⁭⁭=1,⁭﻿⁭⁭
do
⁪=⁪+1
local
⁮‪=⁪⁮⁭﻿[⁭⁭]if
⁮‪..''~=⁮‪
then
‪⁮=‪⁮..__CHAR(__XOR(⁮‪,⁭⁮[⁪]%(658-403),(⁭﻿⁭⁭*⁮)%(117-158-146+154-149+147+118+173-1)))else
‪⁮=‪⁮..⁮‪
end
if
⁪==⁮
then
⁪=0
end
end
return
‪⁮
end)({(464-413),(-19+12-84+85+35+67+71+1),(95+85+81+64-104-40+22+89+1),(216+287-706+2547-2255)},{(74+35+69-59),(-253+351+382-32-423+196),(19+45),(13+52+39-47),(13-25-3+19+63+16+1)})]+1]={[(function(⁪,⁭⁪)local
⁭⁭﻿,﻿﻿‪⁪,‪‪⁪,⁭='',0,#⁭⁪,#⁪
for
⁭﻿﻿﻿=1,‪‪⁪
do
﻿﻿‪⁪=﻿﻿‪⁪+1
local
⁮⁭⁮=⁭⁪[⁭﻿﻿﻿]if
⁮⁭⁮..''~=⁮⁭⁮
then
⁭⁭﻿=⁭⁭﻿..__CHAR(__XOR(⁮⁭⁮,⁪[﻿﻿‪⁪]%(163-76+29+105+245+133-195-149),(‪‪⁪*⁭)%(23+32+79+96+55-29-1)))else
⁭⁭﻿=⁭⁭﻿..⁮⁭⁮
end
if
﻿﻿‪⁪==⁭
then
﻿﻿‪⁪=0
end
end
return
⁭⁭﻿
end)({(368-237+262),(-28989-22841+17101+23667-23979+35386),(1096-1086-645-59+1176-1)},{(220+18+58-263-386+226+325-1),(0+1+2+6+10+5)})]=﻿‪‪‪,[(function(⁪﻿,‪⁪‪‪)local
⁮‪‪⁮,﻿⁮⁭,﻿﻿⁪,⁪⁮﻿⁭='',0,#‪⁪‪‪,#⁪﻿
for
⁮⁭⁭=1,﻿﻿⁪
do
﻿⁮⁭=﻿⁮⁭+1
local
⁪⁮=‪⁪‪‪[⁮⁭⁭]if
⁪⁮..''~=⁪⁮
then
⁮‪‪⁮=⁮‪‪⁮..__CHAR(__XOR(⁪⁮,⁪﻿[﻿⁮⁭]%(52-14+65+122-23+52+1),(﻿﻿⁪*⁪⁮﻿⁭)%(221-10-49+68-116+201+74-135+1)))else
⁮‪‪⁮=⁮‪‪⁮..⁪⁮
end
if
﻿⁮⁭==⁪⁮﻿⁭
then
﻿⁮⁭=0
end
end
return
⁮‪‪⁮
end)({(239+297+142-124-269),(-86+61+87+79+1),(41929-29121-422-30107+18061+1),(147+165-75+129+159-135)},{(130-40),(28+50-1+44+29+53+42-15+1),(114-95-91+51+91-43+26+1),(890-2769+690+1431)})]=2,[(function(﻿⁭,‪⁭)local
⁪﻿⁭,﻿,‪,⁮='',0,#‪⁭,#﻿⁭
for
⁪⁮⁪=1,‪
do
﻿=﻿+1
local
⁭=‪⁭[⁪⁮⁪]if
⁭..''~=⁭
then
⁪﻿⁭=⁪﻿⁭..__CHAR(__XOR(⁭,﻿⁭[﻿]%(-443+698),(‪*⁮)%(11+203+41)))else
⁪﻿⁭=⁪﻿⁭..⁭
end
if
﻿==⁮
then
﻿=0
end
end
return
⁪﻿⁭
end)({(-70+276+124+274-1),(63+75+192+56+182),(80-240+592-52),(25+54+43+72+19-74+1)},{(-2+11),(131+31-59+25-53),(-36+0+35+23+39-8-28),(-1243-1041+160-549+1157+1187-469+1051)})]=⁪‪⁮}end
end
end
local
﻿﻿⁭⁭=⁭(⁭﻿[(function(⁭﻿⁪⁮,‪﻿‪‪)local
‪⁭‪,‪‪﻿,⁭⁮⁮,‪﻿﻿='',0,#‪﻿‪‪,#⁭﻿⁪⁮
for
⁪=1,⁭⁮⁮
do
‪‪﻿=‪‪﻿+1
local
﻿﻿⁪=‪﻿‪‪[⁪]if
﻿﻿⁪..''~=﻿﻿⁪
then
‪⁭‪=‪⁭‪..__CHAR(__XOR(﻿﻿⁪,⁭﻿⁪⁮[‪‪﻿]%(85+38+108+24),(⁭⁮⁮*‪﻿﻿)%(-29+252+11+21)))else
‪⁭‪=‪⁭‪..﻿﻿⁪
end
if
‪‪﻿==‪﻿﻿
then
‪‪﻿=0
end
end
return
‪⁭‪
end)({(19+30+28-26-1),(-2+30+48-1+15-9+1),(514+294-119-245-589+547+26)},{(64-47-55+15+61+10-4+65),(45+24+0+40-67+17+1),(61+36+50+61),(63+5-23-96+125-1),(-23+33+53-7-10)})][1])⁮﻿(⁭﻿[(function(⁭﻿⁪﻿,⁪)local
⁪⁭⁪,⁭⁪‪⁪,⁪⁮,⁭⁪='',0,#⁪,#⁭﻿⁪﻿
for
﻿⁪﻿‪=1,⁪⁮
do
⁭⁪‪⁪=⁭⁪‪⁪+1
local
⁮﻿﻿=⁪[﻿⁪﻿‪]if
⁮﻿﻿..''~=⁮﻿﻿
then
⁪⁭⁪=⁪⁭⁪..__CHAR(__XOR(⁮﻿﻿,⁭﻿⁪﻿[⁭⁪‪⁪]%(-88+51-1-3+100+73+12+111),(⁪⁮*⁭⁪)%(15+72+155+57-98+54)))else
⁪⁭⁪=⁪⁭⁪..⁮﻿﻿
end
if
⁭⁪‪⁪==⁭⁪
then
⁭⁪‪⁪=0
end
end
return
⁪⁭⁪
end)({(100+6-309+243+164+2-1+74-1),(-187+223+264),(504+2090-1076-3391+1500+2774-2043+1)},{(-28+30+70),(-267+334),(-205+226),(-352+528+153+101-323+1),(31+16+34)})],1)⁭⁭⁮(‪⁮[⁭⁮])⁭⁪(‪⁭⁮⁮,(64+54-73-53+37-64+67))⁮⁪(﻿﻿⁭⁭,#﻿﻿⁭⁭)⁮⁭(!!1)﻿⁭()﻿⁪﻿⁭[﻿‪‪‪]=⁭﻿
end
local
function
‪⁮⁪⁪⁪﻿(﻿﻿⁭⁭⁮,⁪﻿⁮)_G[‪⁮[⁮‪] ][‪﻿(⁪‪‪(﻿﻿⁭⁭⁮..‪⁮[﻿﻿‪]))]=⁪﻿⁮
end
local
⁪⁭⁭⁭={}local
function
‪⁪⁮(⁪﻿⁮⁪)local
⁭⁮⁭=⁭﻿⁮(⁮‪⁭⁮﻿)local
‪‪⁭⁪⁪⁭=_G[‪⁮[⁮‪] ][⁭⁮⁭]if
not
‪‪⁭⁪⁪⁭
then
return
end
local
﻿﻿⁮⁭‪⁭=‪‪(⁪﻿⁮⁪/﻿⁪⁮-﻿﻿‪)local
﻿‪⁪⁮=⁮⁮﻿﻿()if
﻿‪⁪⁮
then
﻿﻿⁮⁭‪⁭=⁮⁭⁪(﻿﻿⁮⁭‪⁭)if
﻿﻿⁮⁭‪⁭[(function(⁭,⁮﻿)local
⁮⁮⁮,⁮﻿⁭,⁮‪⁭,‪‪='',0,#⁮﻿,#⁭
for
⁭⁪﻿=1,⁮‪⁭
do
⁮﻿⁭=⁮﻿⁭+1
local
﻿﻿=⁮﻿[⁭⁪﻿]if
﻿﻿..''~=﻿﻿
then
⁮⁮⁮=⁮⁮⁮..__CHAR(__XOR(﻿﻿,⁭[⁮﻿⁭]%(198+210-105-65+16+65-19-44-1),(⁮‪⁭*‪‪)%(224+31)))else
⁮⁮⁮=⁮⁮⁮..﻿﻿
end
if
⁮﻿⁭==‪‪
then
⁮﻿⁭=0
end
end
return
⁮⁮⁮
end)({(526+32589-32655),(10+75-86-23+64+64+69-57),(67+79),(1189+1854-2492)},{(194-56+188-189),(-11+23+18-1),(76-94+91+130+39),(13+36+35-14+13+9)})]==1
then
⁪⁭⁭⁭[﻿﻿⁮⁭‪⁭[(function(⁪,⁭⁮⁮﻿)local
⁭⁮‪⁮,﻿‪,⁪⁭⁭﻿,‪⁭⁪⁭='',0,#⁭⁮⁮﻿,#⁪
for
﻿⁮⁮=1,⁪⁭⁭﻿
do
﻿‪=﻿‪+1
local
⁪⁪‪=⁭⁮⁮﻿[﻿⁮⁮]if
⁪⁪‪..''~=⁪⁪‪
then
⁭⁮‪⁮=⁭⁮‪⁮..__CHAR(__XOR(⁪⁪‪,⁪[﻿‪]%(-387+355+287),(⁪⁭⁭﻿*‪⁭⁪⁭)%(51+18+86+28+35-7-11+57-2)))else
⁭⁮‪⁮=⁭⁮‪⁮..⁪⁪‪
end
if
﻿‪==‪⁭⁪⁭
then
﻿‪=0
end
end
return
⁭⁮‪⁮
end)({(-100+192+169+148+33+48-220-1),(25325-25003),(205-102+419-111+133+19)},{(39-6+32),1})] ]=﻿﻿⁮⁭‪⁭[(function(﻿⁪⁮‪,⁭‪‪)local
⁪⁮‪‪,⁪‪,﻿⁮‪,⁪﻿⁮='',0,#⁭‪‪,#﻿⁪⁮‪
for
﻿=1,﻿⁮‪
do
⁪‪=⁪‪+1
local
⁮⁭=⁭‪‪[﻿]if
⁮⁭..''~=⁮⁭
then
⁪⁮‪‪=⁪⁮‪‪..__CHAR(__XOR(⁮⁭,﻿⁪⁮‪[⁪‪]%(108+147),(﻿⁮‪*⁪﻿⁮)%(58+197)))else
⁪⁮‪‪=⁪⁮‪‪..⁮⁭
end
if
⁪‪==⁪﻿⁮
then
⁪‪=0
end
end
return
⁪⁮‪‪
end)({(147-153-243+152+310+311),0,(5297-2572-2027+1),(32+136)},{(437-358+1614-437-604-561-1),(249-14+256-378),(61+119+77+7-60-51+64),(-44-56+51+87+95-91+77+97+1)})]﻿⁪‪‪((function(‪⁭⁭﻿,‪﻿⁮⁪)local
⁪⁮,‪,⁪‪⁮,⁪='',0,#‪﻿⁮⁪,#‪⁭⁭﻿
for
﻿⁮⁮⁭=1,⁪‪⁮
do
‪=‪+1
local
‪‪⁭=‪﻿⁮⁪[﻿⁮⁮⁭]if
‪‪⁭..''~=‪‪⁭
then
⁪⁮=⁪⁮..__CHAR(__XOR(‪‪⁭,‪⁭⁭﻿[‪]%(20+21+13+73+68+61-1),(⁪‪⁮*⁪)%(-28-77+48+77+76+52+106+1)))else
⁪⁮=⁪⁮..‪‪⁭
end
if
‪==⁪
then
‪=0
end
end
return
⁪⁮
end)({(93+201+130+44-128+112),(1676+399+719-1704+740-1482),(105+49-10+32+77),(6+1+25+40),(39+26+34+36+4-2),(209+538-247-258+347-185)},{(207+245-2-160-188+104),(83+29),(88+122),(-16-301+149+178-1+1),(282-26+128-181-326+305),(-153+28+177-120+168+40+1),(15+204),(-7-6+33+26-26-8+31+40+1),(-451-160+306+313+332+8-108),(-914+207-993+1774-1),(-33+50-152+301+18-1),(83+73),(-7+17+132+67+9),(5+36+26-23+21),(71+75+64+33-24+33+2),(31+12-7+17+34-34+20+1),(-208+97+379-400+362+339-418-1),(251+98-10-252+70-1)}),﻿﻿⁮⁭‪⁭[(function(⁭⁮⁪,⁮﻿‪)local
⁭‪⁪⁪,⁮⁭,⁮⁪﻿,‪='',0,#⁮﻿‪,#⁭⁮⁪
for
⁪‪⁭⁮=1,⁮⁪﻿
do
⁮⁭=⁮⁭+1
local
‪⁪=⁮﻿‪[⁪‪⁭⁮]if
‪⁪..''~=‪⁪
then
⁭‪⁪⁪=⁭‪⁪⁪..__CHAR(__XOR(‪⁪,⁭⁮⁪[⁮⁭]%(94+1289-1251-1142+310+954+1),(⁮⁪﻿*‪)%(142+228-115)))else
⁭‪⁪⁪=⁭‪⁪⁪..‪⁪
end
if
⁮⁭==‪
then
⁮⁭=0
end
end
return
⁭‪⁪⁪
end)({(133-25+277+139-152),(347-148+16+286-106-38-1-1),(-2067+1495+1110)},{(43+15),(28-11+28+4-12+1)})])elseif
﻿﻿⁮⁭‪⁭[(function(⁪⁪,⁮‪‪)local
‪⁪⁪,‪﻿﻿﻿,﻿⁭⁭,‪⁪='',0,#⁮‪‪,#⁪⁪
for
‪=1,﻿⁭⁭
do
‪﻿﻿﻿=‪﻿﻿﻿+1
local
⁪⁪⁪=⁮‪‪[‪]if
⁪⁪⁪..''~=⁪⁪⁪
then
‪⁪⁪=‪⁪⁪..__CHAR(__XOR(⁪⁪⁪,⁪⁪[‪﻿﻿﻿]%(-77-423+570+185),(﻿⁭⁭*‪⁪)%(127+119+47-25-12-1)))else
‪⁪⁪=‪⁪⁪..⁪⁪⁪
end
if
‪﻿﻿﻿==‪⁪
then
‪﻿﻿﻿=0
end
end
return
‪⁪⁪
end)({(-119-197+593+377),(95-150+179+82+290-43+1),(-348-193+41-467+147+464+434+354-2)},{(184-96+63+202-107-45-1),(96-709-1002+166+754+873),(86+22+85+89-70-1),(-30+256+23)})]==2
then
local
﻿﻿‪‪=⁪⁭⁭⁭[﻿﻿⁮⁭‪⁭[(function(‪﻿⁮⁮,‪)local
⁭﻿⁪⁭,⁮⁮⁭,⁪‪,⁮⁭⁭‪='',0,#‪,#‪﻿⁮⁮
for
‪﻿⁪=1,⁪‪
do
⁮⁮⁭=⁮⁮⁭+1
local
⁪=‪[‪﻿⁪]if
⁪..''~=⁪
then
⁭﻿⁪⁭=⁭﻿⁪⁭..__CHAR(__XOR(⁪,‪﻿⁮⁮[⁮⁮⁭]%(13+70+27+75+31-12+51),(⁪‪*⁮⁭⁭‪)%(183+167+99-194)))else
⁭﻿⁪⁭=⁭﻿⁪⁭..⁪
end
if
⁮⁮⁭==⁮⁭⁭‪
then
⁮⁮⁭=0
end
end
return
⁭﻿⁪⁭
end)({(176+269-86),(-24+44+54+46+15+38),(2952-31+22580-18349-13325-18604+24848-1)},{(-59+25-71-55+38+45+47+69),(352+141-255-395+468+17-427+339-1)})] ]..﻿﻿⁮⁭‪⁭[(function(⁪‪⁪,‪)local
⁪,﻿⁮‪﻿,⁪⁮﻿‪,⁪⁭⁮='',0,#‪,#⁪‪⁪
for
﻿⁪=1,⁪⁮﻿‪
do
﻿⁮‪﻿=﻿⁮‪﻿+1
local
⁭=‪[﻿⁪]if
⁭..''~=⁭
then
⁪=⁪..__CHAR(__XOR(⁭,⁪‪⁪[﻿⁮‪﻿]%(-221-36+202-28+440+55-157),(⁪⁮﻿‪*⁪⁭⁮)%(2356-5424+7344-4021)))else
⁪=⁪..⁭
end
if
﻿⁮‪﻿==⁪⁭⁮
then
﻿⁮‪﻿=0
end
end
return
⁪
end)({(77+227+39),(13+44+44+13+52+4-18+1),(22+38+129-139+124+21-1),(184+463+427-1032+942-768)},{(7+25-24+3+1),(-114+149+197),(-284+705-255),(154+107-92)})]‪‪⁭⁪⁪⁭(﻿(﻿﻿‪‪))⁪⁭⁭⁭[﻿﻿⁮⁭‪⁭[(function(﻿,⁪﻿⁪)local
⁪⁪‪,⁮⁭⁮﻿,⁭﻿,⁪⁭﻿='',0,#⁪﻿⁪,#﻿
for
﻿⁪﻿=1,⁭﻿
do
⁮⁭⁮﻿=⁮⁭⁮﻿+1
local
‪﻿⁪=⁪﻿⁪[﻿⁪﻿]if
‪﻿⁪..''~=‪﻿⁪
then
⁪⁪‪=⁪⁪‪..__CHAR(__XOR(‪﻿⁪,﻿[⁮⁭⁮﻿]%(-70+325),(⁭﻿*⁪⁭﻿)%(-199+42+34+378)))else
⁪⁪‪=⁪⁪‪..‪﻿⁪
end
if
⁮⁭⁮﻿==⁪⁭﻿
then
⁮⁭⁮﻿=0
end
end
return
⁪⁪‪
end)({(73+41),(614-345),(-24-37+62+50+14-75+95+1)},{(32+33-9+5),(195-429+578-514+93+203-50)})] ]=nil
elseif
﻿﻿⁮⁭‪⁭[(function(⁪‪⁪⁭,⁭)local
‪,⁪‪,⁪‪⁪,﻿﻿﻿⁭='',0,#⁭,#⁪‪⁪⁭
for
⁮﻿=1,⁪‪⁪
do
⁪‪=⁪‪+1
local
‪‪⁪﻿=⁭[⁮﻿]if
‪‪⁪﻿..''~=‪‪⁪﻿
then
‪=‪..__CHAR(__XOR(‪‪⁪﻿,⁪‪⁪⁭[⁪‪]%(-90+48+46+87+60+1+97+5+1),(⁪‪⁪*﻿﻿﻿⁭)%(68+153-80-82+88+107+1)))else
‪=‪..‪‪⁪﻿
end
if
⁪‪==﻿﻿﻿⁭
then
⁪‪=0
end
end
return
‪
end)({(167+298-158-219-9+224+1),(140-154+205-32+94+124-23+1),(253-49),(-88+157+77+138+40-69)},{(29+43+48+6-38+28+1),(45+30+1+5-48+46-32-34),(276-60-44),(136+17+25+74-180+165+175-295)})]==3
then
⁪⁭⁭⁭[﻿﻿⁮⁭‪⁭[(function(⁭‪⁮,‪)local
﻿,⁭⁪,﻿⁮,﻿⁭='',0,#‪,#⁭‪⁮
for
‪⁭﻿=1,﻿⁮
do
⁭⁪=⁭⁪+1
local
‪⁭⁭=‪[‪⁭﻿]if
‪⁭⁭..''~=‪⁭⁭
then
﻿=﻿..__CHAR(__XOR(‪⁭⁭,⁭‪⁮[⁭⁪]%(-74+172-60+217),(﻿⁮*﻿⁭)%(151-48+136-234+249+1)))else
﻿=﻿..‪⁭⁭
end
if
⁭⁪==﻿⁭
then
⁭⁪=0
end
end
return
﻿
end)({(228+147),(224-4+5+90),(45+24)},{(26+9+30-10),(12+120+54-159+180-80-1)})] ]=⁪⁭⁭⁭[﻿﻿⁮⁭‪⁭[(function(⁪﻿﻿⁪,⁮﻿﻿‪)local
⁪,﻿,‪,⁮﻿⁮⁭='',0,#⁮﻿﻿‪,#⁪﻿﻿⁪
for
⁮=1,‪
do
﻿=﻿+1
local
⁪⁪=⁮﻿﻿‪[⁮]if
⁪⁪..''~=⁪⁪
then
⁪=⁪..__CHAR(__XOR(⁪⁪,⁪﻿﻿⁪[﻿]%(749+1612+1332-1909-1405-124),(‪*⁮﻿⁮⁭)%(303-1162+1044+71-1)))else
⁪=⁪..⁪⁪
end
if
﻿==⁮﻿⁮⁭
then
﻿=0
end
end
return
⁪
end)({(-13+55+248+141-62+224+350-568),(-302+565),(270-7+204+35-134-335+147-8)},{(31+13-26+29-27+3+31+1),(30+26+10+35-27)})] ]..﻿﻿⁮⁭‪⁭[(function(‪⁪,⁭﻿)local
⁮﻿,﻿⁮,﻿‪⁮,⁪='',0,#⁭﻿,#‪⁪
for
﻿⁪⁪‪=1,﻿‪⁮
do
﻿⁮=﻿⁮+1
local
⁭﻿⁪⁮=⁭﻿[﻿⁪⁪‪]if
⁭﻿⁪⁮..''~=⁭﻿⁪⁮
then
⁮﻿=⁮﻿..__CHAR(__XOR(⁭﻿⁪⁮,‪⁪[﻿⁮]%(87+60-16-44+73+95),(﻿‪⁮*⁪)%(-59+114+138+117+142-97-101+1)))else
⁮﻿=⁮﻿..⁭﻿⁪⁮
end
if
﻿⁮==⁪
then
﻿⁮=0
end
end
return
⁮﻿
end)({(208+148-98),(222-237-157+298+111-1),(1465-823),(-163+171+228+1)},{(13+37+37),(-24+463-397+438-322-1),(590-475+483+154+162-24-169-498+1),(49+31+76)})]﻿⁪‪‪((function(﻿,⁭⁭﻿﻿)local
‪⁭﻿,⁭⁭﻿,﻿﻿,‪⁪='',0,#⁭⁭﻿﻿,#﻿
for
⁭‪⁮=1,﻿﻿
do
⁭⁭﻿=⁭⁭﻿+1
local
﻿⁮⁭=⁭⁭﻿﻿[⁭‪⁮]if
﻿⁮⁭..''~=﻿⁮⁭
then
‪⁭﻿=‪⁭﻿..__CHAR(__XOR(﻿⁮⁭,﻿[⁭⁭﻿]%(69+70+74-6+49-1),(﻿﻿*‪⁪)%(57+64-24+157+1)))else
‪⁭﻿=‪⁭﻿..﻿⁮⁭
end
if
⁭⁭﻿==‪⁪
then
⁭⁭﻿=0
end
end
return
‪⁭﻿
end)({(0-85+156+176-74+147),(64+325),(233+28+90+10),(853-1532-372+1629)},{(-17-65-29+52+69+79+61-40),(-31-58-27+78+20+68+92+1),(55+42),(7+6+21),(-3+356+488-157-179-123-70-222),(146-143-26+114-113+163+45),(26+54),(-34-37+82+131-37),(260-550+393+1),(41-38+44+44+64-8+18-2),(48+52-62+87-93-39+15+104),(60-65+70+43-3),(486-3+176+258-443-351-1),(247+273-299-32+1),(4+11+10+19-6+17+14+8),(13-3+12+42+34),(-212+11-17+364-25+1),(-11+95+152-160-72+63+104)}),﻿﻿⁮⁭‪⁭[(function(⁪﻿﻿‪,⁭﻿)local
﻿﻿﻿‪,‪,﻿,⁭='',0,#⁭﻿,#⁪﻿﻿‪
for
⁮⁭‪=1,﻿
do
‪=‪+1
local
﻿⁪⁮=⁭﻿[⁮⁭‪]if
﻿⁪⁮..''~=﻿⁪⁮
then
﻿﻿﻿‪=﻿﻿﻿‪..__CHAR(__XOR(﻿⁪⁮,⁪﻿﻿‪[‪]%(327-1333+762-1849+1433-819+39+1695),(﻿*⁭)%(339-38-70-460+484)))else
﻿﻿﻿‪=﻿﻿﻿‪..﻿⁪⁮
end
if
‪==⁭
then
‪=0
end
end
return
﻿﻿﻿‪
end)({(23+57+87-23),(-61+180-189-49-90+123+287+110),(-1690+669-3521+365+2881-1216+2701)},{(86+137),(39+83)})])end
else
‪‪⁭⁪⁪⁭(﻿(﻿﻿⁮⁭‪⁭))end
end
‪⁮⁪⁪⁪﻿((function(﻿⁭⁭,﻿⁮⁪)local
⁪‪⁮,﻿⁭,⁮‪⁮,⁮='',0,#﻿⁮⁪,#﻿⁭⁭
for
⁮⁮=1,⁮‪⁮
do
﻿⁭=﻿⁭+1
local
⁪⁪=﻿⁮⁪[⁮⁮]if
⁪⁪..''~=⁪⁪
then
⁪‪⁮=⁪‪⁮..__CHAR(__XOR(⁪⁪,﻿⁭⁭[﻿⁭]%(147+130-272+116-100+119-51+166),(⁮‪⁮*⁮)%(81+67+8+78+22-1)))else
⁪‪⁮=⁪‪⁮..⁪⁪
end
if
﻿⁭==⁮
then
﻿⁭=0
end
end
return
⁪‪⁮
end)({(-218-340+600+592+7+64),(83+76+60),(388+146-507+644-244-179),(243+34+45-43-4-61+62),(-237+458+281)},{(27+174+69+194-275),(124-20+71+20+48-106-3),(-44+125+90),(-417+598+348-462),(425-573+385+638-565-466+306),(50+18+52-65+25+52+1),(-24+27+94-175+0+118+115),(-128+291),(28+18+25+2),(-1213+803+1144-1661+1265+1066-1659+416+1)}),function(﻿﻿)⁭﻿﻿(﻿﻿,‪⁮[⁮﻿‪⁮]..(function(⁪⁮﻿﻿,⁪)local
⁪⁪‪,⁮⁪,‪,⁪⁭⁭='',0,#⁪,#⁪⁮﻿﻿
for
﻿﻿⁮﻿=1,‪
do
⁮⁪=⁮⁪+1
local
⁭⁮=⁪[﻿﻿⁮﻿]if
⁭⁮..''~=⁭⁮
then
⁪⁪‪=⁪⁪‪..__CHAR(__XOR(⁭⁮,⁪⁮﻿﻿[⁮⁪]%(-2678+2690-483+1500-774),(‪*⁪⁭⁭)%(47+90+55+63)))else
⁪⁪‪=⁪⁪‪..⁭⁮
end
if
⁮⁪==⁪⁭⁭
then
⁮⁪=0
end
end
return
⁪⁪‪
end)({(-57+148+102-1),(1860-152-1516),(-578+764+214),(145+104),(174+262-2921-511+3357),(-43-74+74+118+66-78+116),(-232-377+152+392+22+416),(-102+245-84-224-204+269+212+154-1)},{(2267-2044),(155+282+16+73-278+1),(-79-30+29+35-3+41+41+136),(-37+92+124-5+1),(27+28+31+10-1-1),(-88+228+10+3-38+118-95+27-1),(24+87),(-4+12+14),(-582+337+464+16),(9+195),(-19+404-355+82+173+299-429),(199+2985+908-1949-1085-1385+559),(-65-119+129+96-142+67+159-1),(100+72),(-55+41+49)})..#﻿﻿)end)‪⁮⁪⁪⁪﻿((function(﻿⁮⁮‪,﻿﻿﻿)local
⁮⁮⁪,⁭‪⁪⁮,⁮‪⁭,⁭‪⁭='',0,#﻿﻿﻿,#﻿⁮⁮‪
for
﻿=1,⁮‪⁭
do
⁭‪⁪⁮=⁭‪⁪⁮+1
local
‪=﻿﻿﻿[﻿]if
‪..''~=‪
then
⁮⁮⁪=⁮⁮⁪..__CHAR(__XOR(‪,﻿⁮⁮‪[⁭‪⁪⁮]%(120-140+111+116+140-143+52-1),(⁮‪⁭*⁭‪⁭)%(108-138-161+117+162-84+166+86-1)))else
⁮⁮⁪=⁮⁮⁪..‪
end
if
⁭‪⁪⁮==⁭‪⁭
then
⁭‪⁪⁮=0
end
end
return
⁮⁮⁪
end)({(1524-1199),(133+145-33),(36+91+83+112+94-82-62+118),(8+263),(53+69+51-21+58+44)},{(17+5-17+19+18+11-8+16),(820-648+1),(-410+123+496),(-579+3128-3989+1506+1),(21+19+138+3-27-1),(4-4+6+1+9),(103+62+59+51-48-88+47+1),(-47+267),(215-143),(33+160-112+126+118-99-59+1),(0+1+11-11+13+9-2)}),function(⁪‪)local
⁭⁪⁮=(function(⁪⁭,‪‪⁪﻿)local
⁪⁪⁮,⁮⁪,⁭⁪⁮,﻿⁪⁪⁭='',0,#‪‪⁪﻿,#⁪⁭
for
⁪=1,⁭⁪⁮
do
⁮⁪=⁮⁪+1
local
﻿‪=‪‪⁪﻿[⁪]if
﻿‪..''~=﻿‪
then
⁪⁪⁮=⁪⁪⁮..__CHAR(__XOR(﻿‪,⁪⁭[⁮⁪]%(-160+49-28+103+167+124),(⁭⁪⁮*﻿⁪⁪⁭)%(-13+68-79+33+99+78+69)))else
⁪⁪⁮=⁪⁪⁮..﻿‪
end
if
⁮⁪==﻿⁪⁪⁭
then
⁮⁪=0
end
end
return
⁪⁪⁮
end)({(30+18+26+30+73+38+35+1),(116+119+137),(165+82+18-97-6),(1568+1960-632+1004-3265-250+1),(135+67+39+59+44),(-17+22+58+36+149+137-1)},{(-7-10+31+3-1),(116-69+110),(29+41),(72-71+224-52+89-26-57-79+1),(311+131-265+1),(29+25+29-13-23-9),(12+5+10),(-113+50+103+138+1),(52+53-14-64+19+57-1),(31+16+23+21),(2+72+64+6),(18+10+71),(4+1-4-1+2+4+3-1),(-74+24+252-249+125+105+26+1),(10+20+22-16-10-2),(1+12+14-6+9+20-14),(-19+157+104-160+78+87-83+1),(60+56-10-65-1),(33+22-27+37+34-2-15),(216-79-1395+866+757-1478+1333),(101-15+101-98-1),(36+11-1-22-16+20+46-38),(7-40+105-73+53+81+44+1),(43-68+26-12+55-29+67+23),(28+3),(46-109+68+150-8),(88-86+0+71),(224+25-114-87-12),(-46+231),(-26+20+28+54-51+46),(-11+26+28+21+13+0-13-1),(102-1+13+44+15),(110+122+7-121),(-206+324-172+35+50+81-15),(114+125-231+35-7+204-63-1),(1380-49-87-48-1098),(98-6),(105+102),5,(153-67+13),(-120+212-254+20+57+245-1),(6+6+26+4+7+21-1),(17-3-1+22+0),(226+158-197+1),(23+68+41-32-23+29-42),(-143-62-8-10+125+59+152-1),(59-49+370+6-253),(3-41+39+24-12+54+36-49+1),(13+5+15),(213-471+724-256),(48+40-15),(102-94+98+1),(49+18+122),(-14-5+32-19+3+41+65),(4+1+3+3+4+2+0-1),(7+92+73+39-1),(9+16+11+12+10+7+1),(-121+69+98-51+117-66+23),(-27+94+90),(2-3+4+36+30+4+16),(-58+31-38-45+54+51+53-1),(14+8+76+86+33-22-62+1),(193-906+1222-423+1),(22+81+20+3-38+9),(148-92+135),(-61+54+9+11+32+52+10),(186-94),(-66+161+113-1),(26-57+12-14+38),(29+70-82-135+38+179),(102-96+51-2+104),(19+26+20+7+16-29+11-1),(-2+7-4+3+10+5+15+1),(-26-213+207+142+185-107),(37-40+4+29+34),(-101+36+177),(50+83),(72-116+96),(8+9+1+6+8+1),(95+88+27),(-14+61-8+34),(-49+44-27+191+199-171+114-194),(5+72+3+50+75-16),(-347-134+176-170+81+269-61+288+1),(7+4+32-8+1-19-1),(169-131+172),(83+108-71-54),(81+43+4-84+40+64-80+1),(-143+214-23+175-66),(44+76-64+15+19-1),(700-570+695-24+67-807),(13+59+26+52+15-54+22+16+1),(-53+47+71),(25+13+47+1),(83+13+101+124-94+16+7-62-1),(-36+60+96-42-41+64),(13+48+18-38+41-38-18-1),(80-1-40+216-161+50+12-1),(42+152+402-270-243),(78+19),(-107-52+29+101-14+115+99+1),(15-31+33+18+9-5-1),(40+8-23-38+38+30+10),(259-49),(-40+30-23+50+15+1+32+1),(27+5-21-1+33+34-8),(152-24+113-55-29+92-42-49-1),(625+635-90-558-523),(-20+54+42-26),(-7+158),(-18+25+28+17+26+19-15-1),(-10+29+27+26-9+32),(202-97+133-1),(-71+87-108+27-99+111+37+107),(-81+80-67+81-32+79+17+15),(-3+4+48+71+67-29),(-27+36+51+14),(15-11+23+2+14+23+18+20-1),(126-132+197),(57+49),(100-8),(110+90+92-130-13),(-39+7+50+2+40+8+6+26),(22-15+11+20+18+15),(19+110),(30+32-16+15+35-31),(11+5+9),(-65+199),(-112+323-125+41-68+50),(289+159-168+96-274-1),(-345+280+343-96-6),(14-68-11+73+48+42),(-3+7+6-6+8+4),(317+62-228),(51-15+61+33+13-56),(136+133-215-17-1),(273-73-205+232),(17+14+29+10-9-23),(3+10+2+0+12),(-12+68+82-13-3+67-10),(-54+156),(46+45),(169-213+230-139+185-112+24),(269-170),(4-3+4+4-10+7-1+4-1),(450+412+598-555-736),(11-120+386+246-414+0-158+66),(6+83),'\n',''})local
⁪⁭⁭﻿⁮⁪=﻿‪‪(⁭⁪⁮..⁪‪,‪⁮[⁮﻿‪⁮]..‪⁮[⁪﻿]..#⁪‪)⁪⁭⁭﻿⁮⁪(﻿⁪‪‪,﻿﻿⁭,‪⁮⁪⁪⁪﻿,‪⁭)end)‪⁮⁪⁪⁪﻿((function(‪⁮⁪,⁭)local
⁮﻿,‪﻿⁮,⁪﻿⁪﻿,⁪‪='',0,#⁭,#‪⁮⁪
for
‪⁭⁭=1,⁪﻿⁪﻿
do
‪﻿⁮=‪﻿⁮+1
local
⁮⁭﻿﻿=⁭[‪⁭⁭]if
⁮⁭﻿﻿..''~=⁮⁭﻿﻿
then
⁮﻿=⁮﻿..__CHAR(__XOR(⁮⁭﻿﻿,‪⁮⁪[‪﻿⁮]%(29+263-158+550-429),(⁪﻿⁪﻿*⁪‪)%(-91+346)))else
⁮﻿=⁮﻿..⁮⁭﻿﻿
end
if
‪﻿⁮==⁪‪
then
‪﻿⁮=0
end
end
return
⁮﻿
end)({(-458+354+628),(34+6+18+19+27+1),(611-236),(-994-566+398+709+608),(-33-152+102+161+164+144-1)},{(78-27),(37+14+3+11+22+28-1),(40+57+22+25-28-18-1),(6+63-37+208-1),(-15+53-19+61+26+62-29),(30+9-14-8-28+18+25),(14+27+11+26+9-21-1),(-53+65+34-14+43+81-84-1),(-63+154+153-112+149-121),(-106+245+150-109+1),(-8+5+5+5-1),(200+121-235),(171-90),(122+55),(-441+246+725+678-183-606+102-337-1),(-43-34-15+78+61+2+45-36),(23+10+1+29+1),(-149+36+160+133-161+52)}),function(⁭‪⁮)local
﻿﻿⁪⁮=﻿⁪﻿⁭[⁭‪⁮]if
﻿﻿⁪⁮
then
local
‪⁪⁭=⁭(﻿﻿⁪⁮[(function(⁪⁪⁮﻿,⁭⁪)local
⁪,⁭⁪‪⁪,‪,⁮='',0,#⁭⁪,#⁪⁪⁮﻿
for
‪⁭=1,‪
do
⁭⁪‪⁪=⁭⁪‪⁪+1
local
⁪⁮⁪‪=⁭⁪[‪⁭]if
⁪⁮⁪‪..''~=⁪⁮⁪‪
then
⁪=⁪..__CHAR(__XOR(⁪⁮⁪‪,⁪⁪⁮﻿[⁭⁪‪⁪]%(-85-55+395),(‪*⁮)%(10-88+126+65+15+127)))else
⁪=⁪..⁪⁮⁪‪
end
if
⁭⁪‪⁪==⁮
then
⁭⁪‪⁪=0
end
end
return
⁪
end)({(433+12-469+448-71-1),(72+51+119),(-274+452-296+368),(30+16+29+75+73+73+45),(-293+375+58+22+198+1)},{(6+58+7-31+23-20-4+1),(-10-25+53-43+53+35+19+56),(25+31+88+1),(-464-161+705+513-235-540+241),0})][1])⁮﻿(﻿﻿⁪⁮[(function(⁪⁪⁮,⁮)local
﻿⁪,⁮⁭‪,⁮⁮⁪,⁮‪﻿='',0,#⁮,#⁪⁪⁮
for
⁭=1,⁮⁮⁪
do
⁮⁭‪=⁮⁭‪+1
local
‪﻿⁪=⁮[⁭]if
‪﻿⁪..''~=‪﻿⁪
then
﻿⁪=﻿⁪..__CHAR(__XOR(‪﻿⁪,⁪⁪⁮[⁮⁭‪]%(312-27-30),(⁮⁮⁪*⁮‪﻿)%(-847+1102)))else
﻿⁪=﻿⁪..‪﻿⁪
end
if
⁮⁭‪==⁮‪﻿
then
⁮⁭‪=0
end
end
return
﻿⁪
end)({(63+78+68+21+85+1),(154+147-145+78-183+166+152-1),(497+90),(-163+111+397+53+407-241+96-329-1)},{(551-338+591+51-724-325+100+214+1),4,(13-11-29+23+26+5-6+23-1),(31+12),(252-162)})],1)⁭⁭⁮(‪⁮[⁭⁮])⁭⁪(﻿﻿⁪⁮[(function(⁪,⁪‪﻿)local
⁮⁮⁮,⁮,‪⁪,⁭‪⁪='',0,#⁪‪﻿,#⁪
for
⁭﻿⁭=1,‪⁪
do
⁮=⁮+1
local
‪⁪‪=⁪‪﻿[⁭﻿⁭]if
‪⁪‪..''~=‪⁪‪
then
⁮⁮⁮=⁮⁮⁮..__CHAR(__XOR(‪⁪‪,⁪[⁮]%(-61+10+64+50+4+58+67+62+1),(‪⁪*⁭‪⁪)%(64+91-113+26+98+88+1)))else
⁮⁮⁮=⁮⁮⁮..‪⁪‪
end
if
⁮==⁭‪⁪
then
⁮=0
end
end
return
⁮⁮⁮
end)({(46+173+213),(-12107+20671+4205-12493),(29+156+79+1),(429+256+66-372-212+1)},{(35+8+83+28-45+84+32+12+1),(101-124+120),(60+18+40+1),(-18-156+160+54+35+144-1),(49+65+81),(-18-39-38+27+19+101+20+36),(264-132+70-81+1)})],(2+17-18+18-4+10+6+1))⁮⁪(‪⁪⁭,#‪⁪⁭)⁮⁭(!!1)﻿⁭()if#﻿﻿⁪⁮[(function(⁭⁪,‪⁮‪)local
⁮,‪,﻿﻿,⁮⁮⁭='',0,#‪⁮‪,#⁭⁪
for
﻿⁭﻿=1,﻿﻿
do
‪=‪+1
local
⁪⁭⁪=‪⁮‪[﻿⁭﻿]if
⁪⁭⁪..''~=⁪⁭⁪
then
⁮=⁮..__CHAR(__XOR(⁪⁭⁪,⁭⁪[‪]%(209-131+177),(﻿﻿*⁮⁮⁭)%(-262+2317-1800)))else
⁮=⁮..⁪⁭⁪
end
if
‪==⁮⁮⁭
then
‪=0
end
end
return
⁮
end)({(68+13+12+44+62+4+37+33+2),(-196+32+153+84+80),(74+182-75+1)},{(2+33+40),(46-436+589-330-182-283+479+364),(-276-52+269+251+433-301-390+269),(762+1656+1385-1569-441-1682),(43-235+108+314-1)})]<1
then
﻿⁪﻿⁭[⁭‪⁮]=nil
end
end
end)‪⁪(‪⁮[⁭⁮],function(﻿⁪⁭⁭‪)‪⁪⁮(﻿⁪⁭⁭‪)end)﻿⁪‪‪((function(⁭⁭⁭‪,⁪﻿⁮⁭)local
‪⁭⁪,‪⁭,﻿⁪‪,⁮='',0,#⁪﻿⁮⁭,#⁭⁭⁭‪
for
⁪⁪⁮⁭=1,﻿⁪‪
do
‪⁭=‪⁭+1
local
﻿=⁪﻿⁮⁭[⁪⁪⁮⁭]if
﻿..''~=﻿
then
‪⁭⁪=‪⁭⁪..__CHAR(__XOR(﻿,⁭⁭⁭‪[‪⁭]%(177+78),(﻿⁪‪*⁮)%(206-180-83+84+229-1)))else
‪⁭⁪=‪⁭⁪..﻿
end
if
‪⁭==⁮
then
‪⁭=0
end
end
return
‪⁭⁪
end)({(1270-820+1030+37+776-649-1099+1),(66+106-25+126+33-117-1),(-355+408-53+203),(-463+1203+408+1449-1374-341+230-528),(-128+720),(-263+149+260+1),(225+322+53-112+220-213-386-1)},{(52+25+79-160+77+83+79),(-154-846-89+840+753-326-121),(12+10+12),(102+117+38-126+59+81-98-11-1),(1612+695-2142),(9+8+63+56+29-33-25),(-129+155+90+49),(-154-207+89+107+212+71+128-1),(32+41+3+1+31+8-3+6+1),(-6+10+8),(3+16+64+48),(-693+4318-3466-1),(-400-290+799),(149-372+91-668+1400+902-1695+353+1),(226+28),(61+204-304+200-95+60-1),(11-12+6),(-14+78+48-46+72+1),(-30-209+443+360-263-209-13+74),(-50+56-38+33+46+42+1),(-37+46+70-7+88+17-1),(99+88+43-1),(-112-235+316-168+242+1+79),(-12+10+13+12-10)}),'')return
﻿⁪‪‪,﻿﻿⁭,‪⁮⁪⁪⁪﻿,‪⁭]]

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

_net_Receive (gAC.Network.GlobalChannel,
	function (bitCount, ply)
		gAC.Network:HandleMessage(bitCount, ply)
	end
)

print( "g-AC version 1.2.6" )
print( "g-AC developed by Glorified Pig, Finn, NiceCream and Ohsshoot" )