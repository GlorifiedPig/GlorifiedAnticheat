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
__CHAR=function(⁮⁭‪)local
﻿⁮={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
‪⁪‪=﻿⁮[⁮⁭‪]if
not
‪⁪‪
then
‪⁪‪=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](⁮⁭‪)end
return
‪⁪‪
end
__FLOOR=function(⁪)return
⁪-(⁪%1)end
__XOR=function(...)local
⁭,‪=0,{...}for
⁭⁪=0,31
do
local
⁮⁭⁪=0
for
⁮⁪=1,#‪
do
⁮⁭⁪=⁮⁭⁪+(‪[⁮⁪]*.5)end
if
⁮⁭⁪~=__FLOOR(⁮⁭⁪)then
⁭=⁭+2^⁭⁪
end
for
‪⁪=1,#‪
do
‪[‪⁪]=__FLOOR(‪[‪⁪]*.5)end
end
return
⁭
end
local
昨={夜=(function(﻿‪⁭,⁮‪)local
‪‪⁮,﻿⁭,⁮⁪‪‪,⁭⁭⁭⁪='',0,#⁮‪,#﻿‪⁭
for
﻿⁪=1,⁮⁪‪‪
do
﻿⁭=﻿⁭+1
local
⁮‪⁮‪=⁮‪[﻿⁪]if
⁮‪⁮‪..''~=⁮‪⁮‪
then
‪‪⁮=‪‪⁮..__CHAR(⁮‪⁮‪/(﻿‪⁭[﻿⁭])/((⁮⁪‪‪*⁭⁭⁭⁪)))else
‪‪⁮=‪‪⁮..⁮‪⁮‪
end
if
﻿⁭==⁭⁭⁭⁪
then
﻿⁭=0
end
end
return
‪‪⁮
end)({160,221,431},{158400,200889,449964}),の=(function(⁭﻿,⁭⁮⁮‪)local
⁭⁪,﻿⁮⁭﻿,⁪⁪⁮,‪‪='',0,#⁭⁮⁮‪,#⁭﻿
for
⁭﻿⁭=1,⁪⁪⁮
do
﻿⁮⁭﻿=﻿⁮⁭﻿+1
local
﻿=⁭⁮⁮‪[⁭﻿⁭]if
﻿..''~=﻿
then
⁭⁪=⁭⁪..__CHAR(﻿/(⁭﻿[﻿⁮⁭﻿])/((⁪⁪⁮*‪‪)))else
⁭⁪=⁭⁪..﻿
end
if
﻿⁮⁭﻿==‪‪
then
﻿⁮⁭﻿=0
end
end
return
⁭⁪
end)({611,390,394,479,386,322},{3651336,2836080,3120480,3448800,2334528,2573424,3651336,2836080,3233952,4069584,2806992,2642976}),コ=(function(⁭,⁭‪)local
﻿⁮,‪‪⁭,⁮‪⁮,⁮⁮⁮⁮='',0,#⁭‪,#⁭
for
⁮‪⁮⁭=1,⁮‪⁮
do
‪‪⁭=‪‪⁭+1
local
⁪⁭⁮=⁭‪[⁮‪⁮⁭]if
⁪⁭⁮..''~=⁪⁭⁮
then
﻿⁮=﻿⁮..__CHAR(⁪⁭⁮/(⁭[‪‪⁭])/((⁮‪⁮*⁮⁮⁮⁮)))else
﻿⁮=﻿⁮..⁪⁭⁮
end
if
‪‪⁭==⁮⁮⁮⁮
then
‪‪⁭=0
end
end
return
﻿⁮
end)({336,130,82},{332640,118170,85608}),ン=(function(‪‪﻿,﻿⁮⁭⁭)local
⁮,⁮﻿‪‪,⁭,﻿⁮='',0,#﻿⁮⁭⁭,#‪‪﻿
for
﻿⁪⁭⁮=1,⁭
do
⁮﻿‪‪=⁮﻿‪‪+1
local
﻿=﻿⁮⁭⁭[﻿⁪⁭⁮]if
﻿..''~=﻿
then
⁮=⁮..__CHAR(﻿/(‪‪﻿[⁮﻿‪‪])/((⁭*﻿⁮)))else
⁮=⁮..﻿
end
if
⁮﻿‪‪==﻿⁮
then
⁮﻿‪‪=0
end
end
return
⁮
end)({140,202,106,492,337,594},{657720,1243512,601020,3081888,1837998,2181168,733320,1265328,555228})}local
夜={サ=(function(⁭⁭,﻿⁪⁪⁮)local
⁮﻿﻿,⁪⁪⁮,⁮⁭⁪⁪,‪‪⁮='',0,#﻿⁪⁪⁮,#⁭⁭
for
﻿⁮﻿=1,⁮⁭⁪⁪
do
⁪⁪⁮=⁪⁪⁮+1
local
⁪‪﻿⁮=﻿⁪⁪⁮[﻿⁮﻿]if
⁪‪﻿⁮..''~=⁪‪﻿⁮
then
⁮﻿﻿=⁮﻿﻿..__CHAR(⁪‪﻿⁮/(⁭⁭[⁪⁪⁮])/((⁮⁭⁪⁪*‪‪⁮)))else
⁮﻿﻿=⁮﻿﻿..⁪‪﻿⁮
end
if
⁪⁪⁮==‪‪⁮
then
⁪⁪⁮=0
end
end
return
⁮﻿﻿
end)({320,256,305},{449280,356352,384300,414720}),ー=(function(⁮⁭⁮,⁪)local
⁪‪,⁮,‪,⁮﻿='',0,#⁪,#⁮⁭⁮
for
⁮⁮=1,‪
do
⁮=⁮+1
local
⁭‪=⁪[⁮⁮]if
⁭‪..''~=⁭‪
then
⁪‪=⁪‪..__CHAR(⁭‪/(⁮⁭⁮[⁮])/((‪*⁮﻿)))else
⁪‪=⁪‪..⁭‪
end
if
⁮==⁮﻿
then
⁮=0
end
end
return
⁪‪
end)({57,333,561},{158004,1065933,1814274,203148,1109889,1555092,208791,813186,1536579,148599,857142}),ト=(function(⁮﻿﻿⁭,⁮⁭)local
‪,⁮⁪⁭﻿,⁪⁭⁮,⁪='',0,#⁮⁭,#⁮﻿﻿⁭
for
⁭‪‪﻿=1,⁪⁭⁮
do
⁮⁪⁭﻿=⁮⁪⁭﻿+1
local
‪⁪=⁮⁭[⁭‪‪﻿]if
‪⁪..''~=‪⁪
then
‪=‪..__CHAR(‪⁪/(⁮﻿﻿⁭[⁮⁪⁭﻿])/((⁪⁭⁮*⁪)))else
‪=‪..‪⁪
end
if
⁮⁪⁭﻿==⁪
then
⁮⁪⁭﻿=0
end
end
return
‪
end)({296,376,99},{293040,341784,103356}),は=(function(⁮﻿,‪⁮⁭⁭)local
﻿﻿,﻿⁮⁭‪,⁪,⁪⁮⁮⁭='',0,#‪⁮⁭⁭,#⁮﻿
for
⁮=1,⁪
do
﻿⁮⁭‪=﻿⁮⁭‪+1
local
⁪⁭=‪⁮⁭⁭[⁮]if
⁪⁭..''~=⁪⁭
then
﻿﻿=﻿﻿..__CHAR(⁪⁭/(⁮﻿[﻿⁮⁭‪])/((⁪*⁪⁮⁮⁭)))else
﻿﻿=﻿﻿..⁪⁭
end
if
﻿⁮⁭‪==⁪⁮⁮⁭
then
﻿⁮⁭‪=0
end
end
return
﻿﻿
end)({366,338,337},{630252,716898,700623,776286,745290,835086,776286}),最=(function(⁮﻿,⁪⁪‪)local
⁮⁪‪,‪⁭,⁮⁪⁪‪,⁪⁪⁭='',0,#⁪⁪‪,#⁮﻿
for
⁭=1,⁮⁪⁪‪
do
‪⁭=‪⁭+1
local
‪﻿‪=⁪⁪‪[⁭]if
‪﻿‪..''~=‪﻿‪
then
⁮⁪‪=⁮⁪‪..__CHAR(‪﻿‪/(⁮﻿[‪⁭])/((⁮⁪⁪‪*⁪⁪⁭)))else
⁮⁪‪=⁮⁪‪..‪﻿‪
end
if
‪⁭==⁪⁪⁭
then
‪⁭=0
end
end
return
⁮⁪‪
end)({290,218,673,148},{542880,404608,1130640,255744}),高=(function(‪﻿⁪‪,⁮⁪⁮⁪)local
‪﻿⁪﻿,⁪⁮,‪﻿,⁮⁮⁭='',0,#⁮⁪⁮⁪,#‪﻿⁪‪
for
⁮⁪⁭⁮=1,‪﻿
do
⁪⁮=⁪⁮+1
local
⁪⁪﻿⁭=⁮⁪⁮⁪[⁮⁪⁭⁮]if
⁪⁪﻿⁭..''~=⁪⁪﻿⁭
then
‪﻿⁪﻿=‪﻿⁪﻿..__CHAR(⁪⁪﻿⁭/(‪﻿⁪‪[⁪⁮])/((‪﻿*⁮⁮⁭)))else
‪﻿⁪﻿=‪﻿⁪﻿..⁪⁪﻿⁭
end
if
⁪⁮==⁮⁮⁭
then
⁪⁮=0
end
end
return
‪﻿⁪﻿
end)({379,300,387,80,250,138,424,270,335},{2319480,2727000,3448170,799200,2452500,1391040,4350240,2454300,3467250,3922650}),で=(function(⁮⁮‪,⁮)local
⁪﻿,﻿⁭⁪,﻿,⁪‪﻿⁪='',0,#⁮,#⁮⁮‪
for
⁮⁭⁮﻿=1,﻿
do
﻿⁭⁪=﻿⁭⁪+1
local
‪=⁮[⁮⁭⁮﻿]if
‪..''~=‪
then
⁪﻿=⁪﻿..__CHAR(‪/(⁮⁮‪[﻿⁭⁪])/((﻿*⁪‪﻿⁪)))else
⁪﻿=⁪﻿..‪
end
if
﻿⁭⁪==⁪‪﻿⁪
then
﻿⁭⁪=0
end
end
return
⁪﻿
end)({496,349,296,169,228,69},{2053440,1457424,1214784,638820,902880,255852}),し=(function(‪⁭,‪⁮)local
⁮﻿,⁮‪﻿﻿,‪,⁪='',0,#‪⁮,#‪⁭
for
⁮⁮=1,‪
do
⁮‪﻿﻿=⁮‪﻿﻿+1
local
⁭﻿⁪=‪⁮[⁮⁮]if
⁭﻿⁪..''~=⁭﻿⁪
then
⁮﻿=⁮﻿..__CHAR(⁭﻿⁪/(‪⁭[⁮‪﻿﻿])/((‪*⁪)))else
⁮﻿=⁮﻿..⁭﻿⁪
end
if
⁮‪﻿﻿==⁪
then
⁮‪﻿﻿=0
end
end
return
⁮﻿
end)({492,424,468},{509220,446472,412776}),た=(function(﻿⁪,⁭)local
‪⁮⁭‪,⁭‪﻿⁭,⁮⁮⁭⁪,﻿='',0,#⁭,#﻿⁪
for
⁪⁪=1,⁮⁮⁭⁪
do
⁭‪﻿⁭=⁭‪﻿⁭+1
local
⁭‪⁭‪=⁭[⁪⁪]if
⁭‪⁭‪..''~=⁭‪⁭‪
then
‪⁮⁭‪=‪⁮⁭‪..__CHAR(⁭‪⁭‪/(﻿⁪[⁭‪﻿⁭])/((⁮⁮⁭⁪*﻿)))else
‪⁮⁭‪=‪⁮⁭‪..⁭‪⁭‪
end
if
⁭‪﻿⁭==﻿
then
⁭‪﻿⁭=0
end
end
return
‪⁮⁭‪
end)({279,134,407,502},{1035648,475968,1432640,1879488,973152,420224,1315424,1831296}),。=(function(﻿⁪,﻿‪)local
⁮⁮,⁪,﻿,‪⁪‪='',0,#﻿‪,#﻿⁪
for
‪⁭﻿=1,﻿
do
⁪=⁪+1
local
‪⁭⁪⁪=﻿‪[‪⁭﻿]if
‪⁭⁪⁪..''~=‪⁭⁪⁪
then
⁮⁮=⁮⁮..__CHAR(‪⁭⁪⁪/(﻿⁪[⁪])/((﻿*‪⁪‪)))else
⁮⁮=⁮⁮..‪⁭⁪⁪
end
if
⁪==‪⁪‪
then
⁪=0
end
end
return
⁮⁮
end)({229,104,202},{226710,94536,210888})}local
の={昨夜=(function(⁮,﻿)local
⁭,⁮﻿⁭,⁭⁭⁭⁪,‪⁭‪='',0,#﻿,#⁮
for
⁮⁮=1,⁭⁭⁭⁪
do
⁮﻿⁭=⁮﻿⁭+1
local
⁮⁪⁭=﻿[⁮⁮]if
⁮⁪⁭..''~=⁮⁪⁭
then
⁭=⁭..__CHAR(⁮⁪⁭/(⁮[⁮﻿⁭])/((⁭⁭⁭⁪*‪⁭‪)))else
⁭=⁭..⁮⁪⁭
end
if
⁮﻿⁭==‪⁭‪
then
⁮﻿⁭=0
end
end
return
⁭
end)({433,289,73,122,238},{898475,838100,177025,347700,690200}),夜夜=(function(⁮⁮⁭⁭,‪﻿‪)local
⁭,﻿‪,﻿⁮⁭,‪='',0,#‪﻿‪,#⁮⁮⁭⁭
for
⁪=1,﻿⁮⁭
do
﻿‪=﻿‪+1
local
﻿⁪⁪⁪=‪﻿‪[⁪]if
﻿⁪⁪⁪..''~=﻿⁪⁪⁪
then
⁭=⁭..__CHAR(﻿⁪⁪⁪/(⁮⁮⁭⁭[﻿‪])/((﻿⁮⁭*‪)))else
⁭=⁭..﻿⁪⁪⁪
end
if
﻿‪==‪
then
﻿‪=0
end
end
return
⁭
end)({524,381,560,273},{913856,591312,1039360,454272}),の夜=(function(﻿﻿,﻿⁮⁭﻿)local
‪,⁮‪⁭,⁪⁪﻿⁮,⁮﻿⁮⁭='',0,#﻿⁮⁭﻿,#﻿﻿
for
⁭⁮⁪=1,⁪⁪﻿⁮
do
⁮‪⁭=⁮‪⁭+1
local
⁪=﻿⁮⁭﻿[⁭⁮⁪]if
⁪..''~=⁪
then
‪=‪..__CHAR(⁪/(﻿﻿[⁮‪⁭])/((⁪⁪﻿⁮*⁮﻿⁮⁭)))else
‪=‪..⁪
end
if
⁮‪⁭==⁮﻿⁮⁭
then
⁮‪⁭=0
end
end
return
‪
end)({232,331,345,108},{367488,534896,579600,186624}),コ夜=(function(‪,⁭)local
⁪,⁭‪,⁪⁮‪,⁮‪='',0,#⁭,#‪
for
⁪⁪⁭⁪=1,⁪⁮‪
do
⁭‪=⁭‪+1
local
﻿‪⁮⁭=⁭[⁪⁪⁭⁪]if
﻿‪⁮⁭..''~=﻿‪⁮⁭
then
⁪=⁪..__CHAR(﻿‪⁮⁭/(‪[⁭‪])/((⁪⁮‪*⁮‪)))else
⁪=⁪..﻿‪⁮⁭
end
if
⁭‪==⁮‪
then
⁭‪=0
end
end
return
⁪
end)({660,188,147},{653400,170892,153468}),ン夜=(function(⁭,⁮)local
⁭⁭‪,⁭﻿,‪,﻿‪='',0,#⁮,#⁭
for
﻿⁭=1,‪
do
⁭﻿=⁭﻿+1
local
‪﻿=⁮[﻿⁭]if
‪﻿..''~=‪﻿
then
⁭⁭‪=⁭⁭‪..__CHAR(‪﻿/(⁭[⁭﻿])/((‪*﻿‪)))else
⁭⁭‪=⁭⁭‪..‪﻿
end
if
⁭﻿==﻿‪
then
⁭﻿=0
end
end
return
⁭⁭‪
end)({459,173,627,207,193,165},{2156382,1064988,3555090,1296648,1052622,757350,1809378,1027620,3927528}),サ夜=(function(﻿,‪﻿⁭⁪)local
‪‪,⁭⁪⁪⁭,﻿﻿﻿⁪,⁭='',0,#‪﻿⁭⁪,#﻿
for
⁮﻿⁮⁭=1,﻿﻿﻿⁪
do
⁭⁪⁪⁭=⁭⁪⁪⁭+1
local
⁮⁮⁪﻿=‪﻿⁭⁪[⁮﻿⁮⁭]if
⁮⁮⁪﻿..''~=⁮⁮⁪﻿
then
‪‪=‪‪..__CHAR(⁮⁮⁪﻿/(﻿[⁭⁪⁪⁭])/((﻿﻿﻿⁪*⁭)))else
‪‪=‪‪..⁮⁮⁪﻿
end
if
⁭⁪⁪⁭==⁭
then
⁭⁪⁪⁭=0
end
end
return
‪‪
end)({308,333,471},{304920,302697,491724}),ー夜=(function(‪⁮﻿⁮,﻿‪﻿⁮)local
﻿⁭‪⁭,⁭⁭⁭,⁪,⁮﻿‪='',0,#﻿‪﻿⁮,#‪⁮﻿⁮
for
﻿‪⁪⁪=1,⁪
do
⁭⁭⁭=⁭⁭⁭+1
local
⁭⁭‪⁮=﻿‪﻿⁮[﻿‪⁪⁪]if
⁭⁭‪⁮..''~=⁭⁭‪⁮
then
﻿⁭‪⁭=﻿⁭‪⁭..__CHAR(⁭⁭‪⁮/(‪⁮﻿⁮[⁭⁭⁭])/((⁪*⁮﻿‪)))else
﻿⁭‪⁭=﻿⁭‪⁭..⁭⁭‪⁮
end
if
⁭⁭⁭==⁮﻿‪
then
⁭⁭⁭=0
end
end
return
﻿⁭‪⁭
end)({250,507,276,245},{656000,1638624,856704,784000,680000,1184352,971520,909440}),ト夜=(function(⁪⁪⁭⁭,﻿⁭‪‪)local
⁮﻿‪,⁮⁮‪⁭,﻿⁮⁭⁪,⁪﻿='',0,#﻿⁭‪‪,#⁪⁪⁭⁭
for
⁪⁭‪=1,﻿⁮⁭⁪
do
⁮⁮‪⁭=⁮⁮‪⁭+1
local
⁪⁮=﻿⁭‪‪[⁪⁭‪]if
⁪⁮..''~=⁪⁮
then
⁮﻿‪=⁮﻿‪..__CHAR(⁪⁮/(⁪⁪⁭⁭[⁮⁮‪⁭])/((﻿⁮⁭⁪*⁪﻿)))else
⁮﻿‪=⁮﻿‪..⁪⁮
end
if
⁮⁮‪⁭==⁪﻿
then
⁮⁮‪⁭=0
end
end
return
⁮﻿‪
end)({600,436,418,332},{1123200,809216,702240,573696}),は夜=(function(⁪,⁪⁭⁪⁮)local
⁭⁪⁮⁭,⁭⁭,‪‪‪,⁭﻿='',0,#⁪⁭⁪⁮,#⁪
for
⁮‪⁭=1,‪‪‪
do
⁭⁭=⁭⁭+1
local
﻿⁮﻿﻿=⁪⁭⁪⁮[⁮‪⁭]if
﻿⁮﻿﻿..''~=﻿⁮﻿﻿
then
⁭⁪⁮⁭=⁭⁪⁮⁭..__CHAR(﻿⁮﻿﻿/(⁪[⁭⁭])/((‪‪‪*⁭﻿)))else
⁭⁪⁮⁭=⁭⁪⁮⁭..﻿⁮﻿﻿
end
if
⁭⁭==⁭﻿
then
⁭⁭=0
end
end
return
⁭⁪⁮⁭
end)({345,334,337,339,546,152,177},{1965810,2134594,2049971,2036034,3531528,1299144,1144836,2576805,2520364,2802492,2636403}),最夜=(function(⁮﻿⁮,⁭⁪)local
⁪,⁭,‪‪⁭﻿,﻿='',0,#⁭⁪,#⁮﻿⁮
for
⁪﻿‪‪=1,‪‪⁭﻿
do
⁭=⁭+1
local
‪﻿‪=⁭⁪[⁪﻿‪‪]if
‪﻿‪..''~=‪﻿‪
then
⁪=⁪..__CHAR(‪﻿‪/(⁮﻿⁮[⁭])/((‪‪⁭﻿*﻿)))else
⁪=⁪..‪﻿‪
end
if
⁭==﻿
then
⁭=0
end
end
return
⁪
end)({307,380,321,164},{574704,705280,539280,283392})}local
コ={高夜=(function(⁭‪‪,﻿)local
⁪⁮⁪,⁮⁭,﻿﻿,⁪‪⁪⁮='',0,#﻿,#⁭‪‪
for
﻿﻿⁭=1,﻿﻿
do
⁮⁭=⁮⁭+1
local
﻿⁭=﻿[﻿﻿⁭]if
﻿⁭..''~=﻿⁭
then
⁪⁮⁪=⁪⁮⁪..__CHAR(﻿⁭/(⁭‪‪[⁮⁭])/((﻿﻿*⁪‪⁪⁮)))else
⁪⁮⁪=⁪⁮⁪..﻿⁭
end
if
⁮⁭==⁪‪⁪⁮
then
⁮⁭=0
end
end
return
⁪⁮⁪
end)({588,108,168},{354564,79704,101304}),で夜=(function(﻿⁪,⁭⁪)local
⁮⁭‪⁭,﻿,‪⁭,﻿⁭⁭='',0,#⁭⁪,#﻿⁪
for
⁪‪﻿=1,‪⁭
do
﻿=﻿+1
local
‪⁭‪⁮=⁭⁪[⁪‪﻿]if
‪⁭‪⁮..''~=‪⁭‪⁮
then
⁮⁭‪⁭=⁮⁭‪⁭..__CHAR(‪⁭‪⁮/(﻿⁪[﻿])/((‪⁭*﻿⁭⁭)))else
⁮⁭‪⁭=⁮⁭‪⁭..‪⁭‪⁮
end
if
﻿==﻿⁭⁭
then
﻿=0
end
end
return
⁮⁭‪⁭
end)({724,284,135},{1016496,395328,170100,938304}),し夜=(function(⁭,⁪)local
‪﻿,‪‪,‪⁭﻿﻿,⁮‪⁪⁮='',0,#⁪,#⁭
for
﻿⁭⁪⁮=1,‪⁭﻿﻿
do
‪‪=‪‪+1
local
‪⁭⁮=⁪[﻿⁭⁪⁮]if
‪⁭⁮..''~=‪⁭⁮
then
‪﻿=‪﻿..__CHAR(‪⁭⁮/(⁭[‪‪])/((‪⁭﻿﻿*⁮‪⁪⁮)))else
‪﻿=‪﻿..‪⁭⁮
end
if
‪‪==⁮‪⁪⁮
then
‪‪=0
end
end
return
‪﻿
end)({499,107,257},{802392,285048,672312,1341312,292752,622968,1377240,295320}),た夜=(function(‪⁪,⁪)local
﻿,⁮⁮,‪,﻿⁪='',0,#⁪,#‪⁪
for
⁪⁭=1,‪
do
⁮⁮=⁮⁮+1
local
‪⁪⁪⁪=⁪[⁪⁭]if
‪⁪⁪⁪..''~=‪⁪⁪⁪
then
﻿=﻿..__CHAR(‪⁪⁪⁪/(‪⁪[⁮⁮])/((‪*﻿⁪)))else
﻿=﻿..‪⁪⁪⁪
end
if
⁮⁮==﻿⁪
then
⁮⁮=0
end
end
return
﻿
end)({508,406,510},{502920,369054,532440}),。夜=(function(‪⁪‪,⁮)local
⁭,⁪⁮⁪﻿,⁪,﻿⁪‪='',0,#⁮,#‪⁪‪
for
‪⁪=1,⁪
do
⁪⁮⁪﻿=⁪⁮⁪﻿+1
local
‪=⁮[‪⁪]if
‪..''~=‪
then
⁭=⁭..__CHAR(‪/(‪⁪‪[⁪⁮⁪﻿])/((⁪*﻿⁪‪)))else
⁭=⁭..‪
end
if
⁪⁮⁪﻿==﻿⁪‪
then
⁪⁮⁪﻿=0
end
end
return
⁭
end)({105,277,228},{246645,852606,646380,328860,755379,406296,314685,830169,664848}),昨の=(function(⁪‪,‪⁭⁪⁪)local
⁪﻿,﻿⁭﻿‪,﻿﻿,⁮﻿='',0,#‪⁭⁪⁪,#⁪‪
for
﻿⁮=1,﻿﻿
do
﻿⁭﻿‪=﻿⁭﻿‪+1
local
⁮⁭=‪⁭⁪⁪[﻿⁮]if
⁮⁭..''~=⁮⁭
then
⁪﻿=⁪﻿..__CHAR(⁮⁭/(⁪‪[﻿⁭﻿‪])/((﻿﻿*⁮﻿)))else
⁪﻿=⁪﻿..⁮⁭
end
if
﻿⁭﻿‪==⁮﻿
then
﻿⁭﻿‪=0
end
end
return
⁪﻿
end)({172,444,222},{170280,403596,231768}),夜の=(function(‪﻿,⁪)local
⁪⁪‪,⁭⁮﻿⁮,⁪⁭⁪,⁪⁭﻿='',0,#⁪,#‪﻿
for
⁭⁭=1,⁪⁭⁪
do
⁭⁮﻿⁮=⁭⁮﻿⁮+1
local
﻿=⁪[⁭⁭]if
﻿..''~=﻿
then
⁪⁪‪=⁪⁪‪..__CHAR(﻿/(‪﻿[⁭⁮﻿⁮])/((⁪⁭⁪*⁪⁭﻿)))else
⁪⁪‪=⁪⁪‪..﻿
end
if
⁭⁮﻿⁮==⁪⁭﻿
then
⁭⁮﻿⁮=0
end
end
return
⁪⁪‪
end)({201,235,379,176,289},{659280,949400,1470520,704000,786080,779880,1090400,1470520}),のの=(function(⁪,‪⁪﻿⁭)local
⁭⁭,﻿﻿⁪,⁭⁮﻿,‪⁭⁮='',0,#‪⁪﻿⁭,#⁪
for
‪⁭=1,⁭⁮﻿
do
﻿﻿⁪=﻿﻿⁪+1
local
⁪﻿⁭⁪=‪⁪﻿⁭[‪⁭]if
⁪﻿⁭⁪..''~=⁪﻿⁭⁪
then
⁭⁭=⁭⁭..__CHAR(⁪﻿⁭⁪/(⁪[﻿﻿⁪])/((⁭⁮﻿*‪⁭⁮)))else
⁭⁭=⁭⁭..⁪﻿⁭⁪
end
if
﻿﻿⁪==‪⁭⁮
then
﻿﻿⁪=0
end
end
return
⁭⁭
end)({311,462,261},{307890,419958,272484}),コの=(function(⁪⁭‪⁮,﻿⁭)local
⁪⁮⁮,⁪,⁭﻿‪,⁭⁪='',0,#﻿⁭,#⁪⁭‪⁮
for
⁪⁭=1,⁭﻿‪
do
⁪=⁪+1
local
‪⁮⁭=﻿⁭[⁪⁭]if
‪⁮⁭..''~=‪⁮⁭
then
⁪⁮⁮=⁪⁮⁮..__CHAR(‪⁮⁭/(⁪⁭‪⁮[⁪])/((⁭﻿‪*⁭⁪)))else
⁪⁮⁮=⁪⁮⁮..‪⁮⁭
end
if
⁪==⁭⁪
then
⁪=0
end
end
return
⁪⁮⁮
end)({102,52,367},{200736,126048,854376,244800,82368,977688,271728,134784}),ンの=(function(⁮‪‪,⁪‪)local
‪﻿,⁪‪‪,⁪⁭⁪﻿,‪⁪‪⁮='',0,#⁪‪,#⁮‪‪
for
﻿⁮﻿=1,⁪⁭⁪﻿
do
⁪‪‪=⁪‪‪+1
local
⁭⁭=⁪‪[﻿⁮﻿]if
⁭⁭..''~=⁭⁭
then
‪﻿=‪﻿..__CHAR(⁭⁭/(⁮‪‪[⁪‪‪])/((⁪⁭⁪﻿*‪⁪‪⁮)))else
‪﻿=‪﻿..⁭⁭
end
if
⁪‪‪==‪⁪‪⁮
then
⁪‪‪=0
end
end
return
‪﻿
end)({178,450,232},{309720,654750,341040,288360,681750})}local
ン={サの=(function(⁭,⁪‪)local
‪,﻿﻿﻿,⁭﻿‪,﻿﻿⁪='',0,#⁪‪,#⁭
for
⁮⁮=1,⁭﻿‪
do
﻿﻿﻿=﻿﻿﻿+1
local
‪⁮=⁪‪[⁮⁮]if
‪⁮..''~=‪⁮
then
‪=‪..__CHAR(‪⁮/(⁭[﻿﻿﻿])/((⁭﻿‪*﻿﻿⁪)))else
‪=‪..‪⁮
end
if
﻿﻿﻿==﻿﻿⁪
then
﻿﻿﻿=0
end
end
return
‪
end)({346,580,472,298},{946656,1405920,1234752,793872,979872,1405920}),ーの=(function(⁮⁪,⁮)local
‪⁮,⁭⁮⁭⁭,⁭⁭⁭⁭,⁪﻿﻿‪='',0,#⁮,#⁮⁪
for
‪﻿﻿=1,⁭⁭⁭⁭
do
⁭⁮⁭⁭=⁭⁮⁭⁭+1
local
‪⁪﻿⁪=⁮[‪﻿﻿]if
‪⁪﻿⁪..''~=‪⁪﻿⁪
then
‪⁮=‪⁮..__CHAR(‪⁪﻿⁪/(⁮⁪[⁭⁮⁭⁭])/((⁭⁭⁭⁭*⁪﻿﻿‪)))else
‪⁮=‪⁮..‪⁪﻿⁪
end
if
⁭⁮⁭⁭==⁪﻿﻿‪
then
⁭⁮⁭⁭=0
end
end
return
‪⁮
end)({190,343,97},{19950}),トの=(function(⁭,⁪)local
⁭⁪⁪,﻿⁪﻿⁭,⁭⁭,‪⁭='',0,#⁪,#⁭
for
﻿=1,⁭⁭
do
﻿⁪﻿⁭=﻿⁪﻿⁭+1
local
⁭⁭﻿⁭=⁪[﻿]if
⁭⁭﻿⁭..''~=⁭⁭﻿⁭
then
⁭⁪⁪=⁭⁪⁪..__CHAR(⁭⁭﻿⁭/(⁭[﻿⁪﻿⁭])/((⁭⁭*‪⁭)))else
⁭⁪⁪=⁭⁪⁪..⁭⁭﻿⁭
end
if
﻿⁪﻿⁭==‪⁭
then
﻿⁪﻿⁭=0
end
end
return
⁭⁪⁪
end)({283,196,5,56,126,494,153},{929089,998816,23765,301840,679140,2444806,809676}),はの=(function(⁪,‪⁮⁪)local
⁮⁭⁭,‪⁭,﻿﻿,⁪‪='',0,#‪⁮⁪,#⁪
for
‪⁮﻿=1,﻿﻿
do
‪⁭=‪⁭+1
local
‪⁪⁭=‪⁮⁪[‪⁮﻿]if
‪⁪⁭..''~=‪⁪⁭
then
⁮⁭⁭=⁮⁭⁭..__CHAR(‪⁪⁭/(⁪[‪⁭])/((﻿﻿*⁪‪)))else
⁮⁭⁭=⁮⁭⁭..‪⁪⁭
end
if
‪⁭==⁪‪
then
‪⁭=0
end
end
return
⁮⁭⁭
end)({186,104,311,156},{297600,201760,709080,361920,427800}),最の=(function(‪‪,⁭)local
⁮⁮⁪‪,⁪⁮⁪⁮,⁪,⁭⁮='',0,#⁭,#‪‪
for
⁮⁮﻿⁪=1,⁪
do
⁪⁮⁪⁮=⁪⁮⁪⁮+1
local
⁭﻿‪⁪=⁭[⁮⁮﻿⁪]if
⁭﻿‪⁪..''~=⁭﻿‪⁪
then
⁮⁮⁪‪=⁮⁮⁪‪..__CHAR(⁭﻿‪⁪/(‪‪[⁪⁮⁪⁮])/((⁪*⁭⁮)))else
⁮⁮⁪‪=⁮⁮⁪‪..⁭﻿‪⁪
end
if
⁪⁮⁪⁮==⁭⁮
then
⁪⁮⁪⁮=0
end
end
return
⁮⁮⁪‪
end)({207,105,295,411},{331200,203700,672600,953520,476100}),高の=(function(‪⁪⁮,‪⁭)local
‪⁪﻿⁮,⁮⁭⁪,‪⁭‪,⁮﻿⁪='',0,#‪⁭,#‪⁪⁮
for
‪⁪=1,‪⁭‪
do
⁮⁭⁪=⁮⁭⁪+1
local
‪‪﻿=‪⁭[‪⁪]if
‪‪﻿..''~=‪‪﻿
then
‪⁪﻿⁮=‪⁪﻿⁮..__CHAR(‪‪﻿/(‪⁪⁮[⁮⁭⁪])/((‪⁭‪*⁮﻿⁪)))else
‪⁪﻿⁮=‪⁪﻿⁮..‪‪﻿
end
if
⁮⁭⁪==⁮﻿⁪
then
⁮⁭⁪=0
end
end
return
‪⁪﻿⁮
end)({359,112,552,373,395},{718000,271600,1573200,1081700,1135625}),での=(function(﻿⁭,⁭⁪⁪)local
‪⁭⁭‪,⁪⁪⁮⁮,﻿,⁮⁮='',0,#⁭⁪⁪,#﻿⁭
for
‪⁮﻿=1,﻿
do
⁪⁪⁮⁮=⁪⁪⁮⁮+1
local
⁪⁮⁭⁭=⁭⁪⁪[‪⁮﻿]if
⁪⁮⁭⁭..''~=⁪⁮⁭⁭
then
‪⁭⁭‪=‪⁭⁭‪..__CHAR(⁪⁮⁭⁭/(﻿⁭[⁪⁪⁮⁮])/((﻿*⁮⁮)))else
‪⁭⁭‪=‪⁭⁭‪..⁪⁮⁭⁭
end
if
⁪⁪⁮⁮==⁮⁮
then
⁪⁪⁮⁮=0
end
end
return
‪⁭⁭‪
end)({360,331,345},{157680,135048}),しの=(function(‪⁭‪,⁪‪⁭⁮)local
⁮‪⁮,⁭⁮,﻿⁮⁭⁭,⁪='',0,#⁪‪⁭⁮,#‪⁭‪
for
﻿⁪⁭=1,﻿⁮⁭⁭
do
⁭⁮=⁭⁮+1
local
⁭⁭﻿=⁪‪⁭⁮[﻿⁪⁭]if
⁭⁭﻿..''~=⁭⁭﻿
then
⁮‪⁮=⁮‪⁮..__CHAR(⁭⁭﻿/(‪⁭‪[⁭⁮])/((﻿⁮⁭⁭*⁪)))else
⁮‪⁮=⁮‪⁮..⁭⁭﻿
end
if
⁭⁮==⁪
then
⁭⁮=0
end
end
return
⁮‪⁮
end)({194,486,245,222},{260736,940896,439040,358752}),たの=(function(⁭⁭⁪,﻿‪)local
⁭⁭,⁮⁭,‪﻿‪,⁪⁮='',0,#﻿‪,#⁭⁭⁪
for
⁮‪=1,‪﻿‪
do
⁮⁭=⁮⁭+1
local
‪⁭⁭=﻿‪[⁮‪]if
‪⁭⁭..''~=‪⁭⁭
then
⁭⁭=⁭⁭..__CHAR(‪⁭⁭/(⁭⁭⁪[⁮⁭])/((‪﻿‪*⁪⁮)))else
⁭⁭=⁭⁭..‪⁭⁭
end
if
⁮⁭==⁪⁮
then
⁮⁭=0
end
end
return
⁭⁭
end)({338,169,365,119},{367744,262288,677440,184688}),。の=(function(⁮‪,‪)local
﻿﻿⁮,⁪‪⁪,⁪,⁪﻿⁭﻿='',0,#‪,#⁮‪
for
⁭‪‪⁮=1,⁪
do
⁪‪⁪=⁪‪⁪+1
local
﻿⁭=‪[⁭‪‪⁮]if
﻿⁭..''~=﻿⁭
then
﻿﻿⁮=﻿﻿⁮..__CHAR(﻿⁭/(⁮‪[⁪‪⁪])/((⁪*⁪﻿⁭﻿)))else
﻿﻿⁮=﻿﻿⁮..﻿⁭
end
if
⁪‪⁪==⁪﻿⁭﻿
then
⁪‪⁪=0
end
end
return
﻿﻿⁮
end)({403,315,391,325},{644800,611100,891480,754000,926900})}local
サ={昨コ=(function(‪⁪⁪‪,⁭)local
⁭﻿﻿⁪,⁭⁭,⁮⁭‪﻿,‪='',0,#⁭,#‪⁪⁪‪
for
⁪‪=1,⁮⁭‪﻿
do
⁭⁭=⁭⁭+1
local
‪⁭⁪=⁭[⁪‪]if
‪⁭⁪..''~=‪⁭⁪
then
⁭﻿﻿⁪=⁭﻿﻿⁪..__CHAR(‪⁭⁪/(‪⁪⁪‪[⁭⁭])/((⁮⁭‪﻿*‪)))else
⁭﻿﻿⁪=⁭﻿﻿⁪..‪⁭⁪
end
if
⁭⁭==‪
then
⁭⁭=0
end
end
return
⁭﻿﻿⁪
end)({422,347,507},{506400,504885,866970,734280,598575}),夜コ=(function(⁪‪⁪,⁭⁭⁪)local
⁭⁭‪,⁮⁮﻿⁮,﻿⁮⁭‪,‪⁭='',0,#⁭⁭⁪,#⁪‪⁪
for
﻿‪=1,﻿⁮⁭‪
do
⁮⁮﻿⁮=⁮⁮﻿⁮+1
local
⁮⁭=⁭⁭⁪[﻿‪]if
⁮⁭..''~=⁮⁭
then
⁭⁭‪=⁭⁭‪..__CHAR(⁮⁭/(⁪‪⁪[⁮⁮﻿⁮])/((﻿⁮⁭‪*‪⁭)))else
⁭⁭‪=⁭⁭‪..⁮⁭
end
if
⁮⁮﻿⁮==‪⁭
then
⁮⁮﻿⁮=0
end
end
return
⁭⁭‪
end)({471,466,674},{206298,190128}),のコ=(function(﻿⁮,⁭)local
⁭‪⁪‪,﻿,﻿⁭⁪,⁪‪‪='',0,#⁭,#﻿⁮
for
⁮‪⁪⁪=1,﻿⁭⁪
do
﻿=﻿+1
local
⁪=⁭[⁮‪⁪⁪]if
⁪..''~=⁪
then
⁭‪⁪‪=⁭‪⁪‪..__CHAR(⁪/(﻿⁮[﻿])/((﻿⁭⁪*⁪‪‪)))else
⁭‪⁪‪=⁭‪⁪‪..⁪
end
if
﻿==⁪‪‪
then
﻿=0
end
end
return
⁭‪⁪‪
end)({498,473,218,250},{669312,915728,390656,404000}),ココ=(function(﻿,⁪⁪⁪)local
⁭,‪⁪⁭⁪,⁭⁮,⁭⁪﻿⁪='',0,#⁪⁪⁪,#﻿
for
﻿‪⁪=1,⁭⁮
do
‪⁪⁭⁪=‪⁪⁭⁪+1
local
⁪⁪‪=⁪⁪⁪[﻿‪⁪]if
⁪⁪‪..''~=⁪⁪‪
then
⁭=⁭..__CHAR(⁪⁪‪/(﻿[‪⁪⁭⁪])/((⁭⁮*⁭⁪﻿⁪)))else
⁭=⁭..⁪⁪‪
end
if
‪⁪⁭⁪==⁭⁪﻿⁪
then
‪⁪⁭⁪=0
end
end
return
⁭
end)({186,289,460,268},{202368,448528,853760,415936}),ンコ=(function(‪⁭﻿,⁮﻿﻿‪)local
⁭‪⁮,⁪,⁭‪,‪='',0,#⁮﻿﻿‪,#‪⁭﻿
for
﻿⁮=1,⁭‪
do
⁪=⁪+1
local
⁮=⁮﻿﻿‪[﻿⁮]if
⁮..''~=⁮
then
⁭‪⁮=⁭‪⁮..__CHAR(⁮/(‪⁭﻿[⁪])/((⁭‪*‪)))else
⁭‪⁮=⁭‪⁮..⁮
end
if
⁪==‪
then
⁪=0
end
end
return
⁭‪⁮
end)({121,87,406},{145200,126585,694260,210540,150075}),サコ=(function(⁭‪⁮⁮,⁮﻿)local
⁮‪,﻿⁪⁭﻿,⁭,⁭⁭﻿='',0,#⁮﻿,#⁭‪⁮⁮
for
‪‪=1,⁭
do
﻿⁪⁭﻿=﻿⁪⁭﻿+1
local
⁪⁪⁮=⁮﻿[‪‪]if
⁪⁪⁮..''~=⁪⁪⁮
then
⁮‪=⁮‪..__CHAR(⁪⁪⁮/(⁭‪⁮⁮[﻿⁪⁭﻿])/((⁭*⁭⁭﻿)))else
⁮‪=⁮‪..⁪⁪⁮
end
if
﻿⁪⁭﻿==⁭⁭﻿
then
﻿⁪⁭﻿=0
end
end
return
⁮‪
end)({312,151,415},{374400,219705,709650,542880,260475}),ーコ=(function(⁭⁮‪⁮,﻿⁭‪﻿)local
⁪,﻿,⁪‪‪,﻿⁪='',0,#﻿⁭‪﻿,#⁭⁮‪⁮
for
⁭⁪=1,⁪‪‪
do
﻿=﻿+1
local
⁭=﻿⁭‪﻿[⁭⁪]if
⁭..''~=⁭
then
⁪=⁪..__CHAR(⁭/(⁭⁮‪⁮[﻿])/((⁪‪‪*﻿⁪)))else
⁪=⁪..⁭
end
if
﻿==﻿⁪
then
﻿=0
end
end
return
⁪
end)({106,228,207},{46428,93024}),トコ=(function(‪⁮,⁭)local
⁭‪‪,⁪‪‪﻿,⁪,‪‪='',0,#⁭,#‪⁮
for
‪‪⁪﻿=1,⁪
do
⁪‪‪﻿=⁪‪‪﻿+1
local
﻿⁪=⁭[‪‪⁪﻿]if
﻿⁪..''~=﻿⁪
then
⁭‪‪=⁭‪‪..__CHAR(﻿⁪/(‪⁮[⁪‪‪﻿])/((⁪*‪‪)))else
⁭‪‪=⁭‪‪..﻿⁪
end
if
⁪‪‪﻿==‪‪
then
⁪‪‪﻿=0
end
end
return
⁭‪‪
end)({225,272,53,318},{302400,526592,94976,513888}),はコ=(function(⁪‪,⁪‪⁮⁮)local
‪⁮,⁪⁭⁮⁪,‪⁪‪⁪,⁮⁪⁮='',0,#⁪‪⁮⁮,#⁪‪
for
⁪=1,‪⁪‪⁪
do
⁪⁭⁮⁪=⁪⁭⁮⁪+1
local
⁪‪⁮=⁪‪⁮⁮[⁪]if
⁪‪⁮..''~=⁪‪⁮
then
‪⁮=‪⁮..__CHAR(⁪‪⁮/(⁪‪[⁪⁭⁮⁪])/((‪⁪‪⁪*⁮⁪⁮)))else
‪⁮=‪⁮..⁪‪⁮
end
if
⁪⁭⁮⁪==⁮⁪⁮
then
⁪⁭⁮⁪=0
end
end
return
‪⁮
end)({157,367,213},{128112,427188,296496,182748}),最コ=(function(﻿⁮‪⁮,﻿⁪⁮)local
⁮⁭,⁪,⁮﻿⁭,⁪﻿⁭='',0,#﻿⁪⁮,#﻿⁮‪⁮
for
⁪‪⁮=1,⁮﻿⁭
do
⁪=⁪+1
local
⁭﻿=﻿⁪⁮[⁪‪⁮]if
⁭﻿..''~=⁭﻿
then
⁮⁭=⁮⁭..__CHAR(⁭﻿/(﻿⁮‪⁮[⁪])/((⁮﻿⁭*⁪﻿⁭)))else
⁮⁭=⁮⁭..⁭﻿
end
if
⁪==⁪﻿⁭
then
⁪=0
end
end
return
⁮⁭
end)({129,408,450,2,233},{258000,989400,1282500,5800,669875})}local
ー={高コ=(function(⁮⁭﻿⁮,⁭⁮)local
﻿⁪,⁭⁮⁭⁭,⁪⁮,⁭‪='',0,#⁭⁮,#⁮⁭﻿⁮
for
﻿⁭‪=1,⁪⁮
do
⁭⁮⁭⁭=⁭⁮⁭⁭+1
local
⁪=⁭⁮[﻿⁭‪]if
⁪..''~=⁪
then
﻿⁪=﻿⁪..__CHAR(⁪/(⁮⁭﻿⁮[⁭⁮⁭⁭])/((⁪⁮*⁭‪)))else
﻿⁪=﻿⁪..⁪
end
if
⁭⁮⁭⁭==⁭‪
then
⁭⁮⁭⁭=0
end
end
return
﻿⁪
end)({352,537,374},{422400,781335,639540,612480,926325}),でコ=(function(⁪⁮⁪,‪⁭﻿⁪)local
⁭,⁪‪⁪,﻿﻿﻿,﻿﻿⁭‪='',0,#‪⁭﻿⁪,#⁪⁮⁪
for
⁭⁪=1,﻿﻿﻿
do
⁪‪⁪=⁪‪⁪+1
local
‪⁪⁮=‪⁭﻿⁪[⁭⁪]if
‪⁪⁮..''~=‪⁪⁮
then
⁭=⁭..__CHAR(‪⁪⁮/(⁪⁮⁪[⁪‪⁪])/((﻿﻿﻿*﻿﻿⁭‪)))else
⁭=⁭..‪⁪⁮
end
if
⁪‪⁪==﻿﻿⁭‪
then
⁪‪⁪=0
end
end
return
⁭
end)({303,406,335,200},{407232,786016,600320,323200}),しコ=(function(‪⁭⁮,﻿‪‪)local
‪⁮⁪⁪,‪﻿‪,⁪,⁮⁪⁪='',0,#﻿‪‪,#‪⁭⁮
for
⁭=1,⁪
do
‪﻿‪=‪﻿‪+1
local
⁮⁪=﻿‪‪[⁭]if
⁮⁪..''~=⁮⁪
then
‪⁮⁪⁪=‪⁮⁪⁪..__CHAR(⁮⁪/(‪⁭⁮[‪﻿‪])/((⁪*⁮⁪⁪)))else
‪⁮⁪⁪=‪⁮⁪⁪..⁮⁪
end
if
‪﻿‪==⁮⁪⁪
then
‪﻿‪=0
end
end
return
‪⁮⁪⁪
end)({499,199,256},{218562,81192}),たコ=(function(⁪﻿‪,⁮⁪⁭)local
‪⁪⁪,⁪⁮‪⁪,⁮⁮,﻿⁮‪﻿='',0,#⁮⁪⁭,#⁪﻿‪
for
⁮⁪=1,⁮⁮
do
⁪⁮‪⁪=⁪⁮‪⁪+1
local
⁪⁭‪⁪=⁮⁪⁭[⁮⁪]if
⁪⁭‪⁪..''~=⁪⁭‪⁪
then
‪⁪⁪=‪⁪⁪..__CHAR(⁪⁭‪⁪/(⁪﻿‪[⁪⁮‪⁪])/((⁮⁮*﻿⁮‪﻿)))else
‪⁪⁪=‪⁪⁪..⁪⁭‪⁪
end
if
⁪⁮‪⁪==﻿⁮‪﻿
then
⁪⁮‪⁪=0
end
end
return
‪⁪⁪
end)({191,239,258,386},{207808,370928,478848,599072}),。コ=(function(‪⁮⁪,‪⁮)local
‪⁮‪,﻿⁪,‪,⁭⁪⁮='',0,#‪⁮,#‪⁮⁪
for
⁮⁪=1,‪
do
﻿⁪=﻿⁪+1
local
⁭﻿=‪⁮[⁮⁪]if
⁭﻿..''~=⁭﻿
then
‪⁮‪=‪⁮‪..__CHAR(⁭﻿/(‪⁮⁪[﻿⁪])/((‪*⁭⁪⁮)))else
‪⁮‪=‪⁮‪..⁭﻿
end
if
﻿⁪==⁭⁪⁮
then
﻿⁪=0
end
end
return
‪⁮‪
end)({179,49,182,316,193,428,670,180},{2654928,458640,1755936,2093184,2306736,7149312,10998720,2617920,2500272,769104,2149056,4595904,3196080,6902784,10709280,2851200,2964240,712656}),昨ン=(function(﻿,⁭⁪)local
⁪⁭,‪⁭⁭,⁭⁮‪﻿,⁮﻿⁪⁭='',0,#⁭⁪,#﻿
for
﻿⁭⁭=1,⁭⁮‪﻿
do
‪⁭⁭=‪⁭⁭+1
local
‪⁮⁪⁪=⁭⁪[﻿⁭⁭]if
‪⁮⁪⁪..''~=‪⁮⁪⁪
then
⁪⁭=⁪⁭..__CHAR(‪⁮⁪⁪/(﻿[‪⁭⁭])/((⁭⁮‪﻿*⁮﻿⁪⁭)))else
⁪⁭=⁪⁭..‪⁮⁪⁪
end
if
‪⁭⁭==⁮﻿⁪⁭
then
‪⁭⁭=0
end
end
return
⁪⁭
end)({413,138,428},{180894,56304}),夜ン=(function(﻿⁪⁮⁪,⁪⁮⁮⁭)local
﻿‪﻿⁪,﻿⁪,⁮⁪⁭,‪⁮='',0,#⁪⁮⁮⁭,#﻿⁪⁮⁪
for
⁮‪⁮⁪=1,⁮⁪⁭
do
﻿⁪=﻿⁪+1
local
⁮⁭‪‪=⁪⁮⁮⁭[⁮‪⁮⁪]if
⁮⁭‪‪..''~=⁮⁭‪‪
then
﻿‪﻿⁪=﻿‪﻿⁪..__CHAR(⁮⁭‪‪/(﻿⁪⁮⁪[﻿⁪])/((⁮⁪⁭*‪⁮)))else
﻿‪﻿⁪=﻿‪﻿⁪..⁮⁭‪‪
end
if
﻿⁪==‪⁮
then
﻿⁪=0
end
end
return
﻿‪﻿⁪
end)({445,203,169},{448560,294756,227136,539340}),のン=(function(﻿⁮⁭,﻿⁪)local
‪﻿,⁪⁭⁮‪,‪⁪‪‪,﻿⁭‪='',0,#﻿⁪,#﻿⁮⁭
for
﻿=1,‪⁪‪‪
do
⁪⁭⁮‪=⁪⁭⁮‪+1
local
⁭⁪‪﻿=﻿⁪[﻿]if
⁭⁪‪﻿..''~=⁭⁪‪﻿
then
‪﻿=‪﻿..__CHAR(⁭⁪‪﻿/(﻿⁮⁭[⁪⁭⁮‪])/((‪⁪‪‪*﻿⁭‪)))else
‪﻿=‪﻿..⁭⁪‪﻿
end
if
⁪⁭⁮‪==﻿⁭‪
then
⁪⁭⁮‪=0
end
end
return
‪﻿
end)({199,459,273},{87162,187272}),コン=(function(⁭‪,‪﻿‪)local
﻿⁭⁪,﻿⁮﻿,⁪﻿‪⁭,⁮⁭='',0,#‪﻿‪,#⁭‪
for
⁮⁮=1,⁪﻿‪⁭
do
﻿⁮﻿=﻿⁮﻿+1
local
⁪=‪﻿‪[⁮⁮]if
⁪..''~=⁪
then
﻿⁭⁪=﻿⁭⁪..__CHAR(⁪/(⁭‪[﻿⁮﻿])/((⁪﻿‪⁭*⁮⁭)))else
﻿⁭⁪=﻿⁭⁪..⁪
end
if
﻿⁮﻿==⁮⁭
then
﻿⁮﻿=0
end
end
return
﻿⁭⁪
end)({136,172,175,560},{147968,266944,324800,869120}),ンン=(function(⁮﻿⁮﻿,﻿﻿﻿⁮)local
⁭⁪,⁭,﻿⁮,﻿⁪﻿='',0,#﻿﻿﻿⁮,#⁮﻿⁮﻿
for
﻿⁪⁭⁭=1,﻿⁮
do
⁭=⁭+1
local
‪﻿⁭⁮=﻿﻿﻿⁮[﻿⁪⁭⁭]if
‪﻿⁭⁮..''~=‪﻿⁭⁮
then
⁭⁪=⁭⁪..__CHAR(‪﻿⁭⁮/(⁮﻿⁮﻿[⁭])/((﻿⁮*﻿⁪﻿)))else
⁭⁪=⁭⁪..‪﻿⁭⁮
end
if
⁭==﻿⁪﻿
then
⁭=0
end
end
return
⁭⁪
end)({168,51,342},{73584,20808})}local
ト={サン=(function(⁭‪,⁭)local
⁮⁪⁮,‪‪⁭,﻿⁮﻿⁮,⁭⁭‪='',0,#⁭,#⁭‪
for
‪⁭⁪=1,﻿⁮﻿⁮
do
‪‪⁭=‪‪⁭+1
local
⁮=⁭[‪⁭⁪]if
⁮..''~=⁮
then
⁮⁪⁮=⁮⁪⁮..__CHAR(⁮/(⁭‪[‪‪⁭])/((﻿⁮﻿⁮*⁭⁭‪)))else
⁮⁪⁮=⁮⁪⁮..⁮
end
if
‪‪⁭==⁭⁭‪
then
‪‪⁭=0
end
end
return
⁮⁪⁮
end)({220,224,56},{221760,325248,75264,266640}),ーン=(function(⁭⁮‪⁪,﻿⁮‪⁪)local
﻿⁮⁪,﻿,⁮⁭,⁭='',0,#﻿⁮‪⁪,#⁭⁮‪⁪
for
⁮⁪‪=1,⁮⁭
do
﻿=﻿+1
local
﻿‪⁭=﻿⁮‪⁪[⁮⁪‪]if
﻿‪⁭..''~=﻿‪⁭
then
﻿⁮⁪=﻿⁮⁪..__CHAR(﻿‪⁭/(⁭⁮‪⁪[﻿])/((⁮⁭*⁭)))else
﻿⁮⁪=﻿⁮⁪..﻿‪⁭
end
if
﻿==⁭
then
﻿=0
end
end
return
﻿⁮⁪
end)({196,305,110},{85848,124440}),トン=(function(﻿⁭,﻿⁪⁪⁪)local
⁪⁮﻿,⁮‪,⁮⁪⁮,﻿⁪⁮⁭='',0,#﻿⁪⁪⁪,#﻿⁭
for
⁪﻿⁮=1,⁮⁪⁮
do
⁮‪=⁮‪+1
local
‪﻿﻿=﻿⁪⁪⁪[⁪﻿⁮]if
‪﻿﻿..''~=‪﻿﻿
then
⁪⁮﻿=⁪⁮﻿..__CHAR(‪﻿﻿/(﻿⁭[⁮‪])/((⁮⁪⁮*﻿⁪⁮⁭)))else
⁪⁮﻿=⁪⁮﻿..‪﻿﻿
end
if
⁮‪==﻿⁪⁮⁭
then
⁮‪=0
end
end
return
⁪⁮﻿
end)({49,471,281},{21462,192168}),はン=(function(⁪⁮⁪,⁭⁮)local
⁭‪,⁮⁮,‪‪﻿⁮,‪⁮﻿='',0,#⁭⁮,#⁪⁮⁪
for
⁪=1,‪‪﻿⁮
do
⁮⁮=⁮⁮+1
local
⁭=⁭⁮[⁪]if
⁭..''~=⁭
then
⁭‪=⁭‪..__CHAR(⁭/(⁪⁮⁪[⁮⁮])/((‪‪﻿⁮*‪⁮﻿)))else
⁭‪=⁭‪..⁭
end
if
⁮⁮==‪⁮﻿
then
⁮⁮=0
end
end
return
⁭‪
end)({358,632,446,360},{389504,980864,827776,558720}),最ン=(function(⁮⁭‪⁪,⁭‪)local
⁭﻿⁮,﻿﻿⁪,⁪⁭,⁮‪⁪='',0,#⁭‪,#⁮⁭‪⁪
for
‪⁭⁮‪=1,⁪⁭
do
﻿﻿⁪=﻿﻿⁪+1
local
﻿﻿‪⁪=⁭‪[‪⁭⁮‪]if
﻿﻿‪⁪..''~=﻿﻿‪⁪
then
⁭﻿⁮=⁭﻿⁮..__CHAR(﻿﻿‪⁪/(⁮⁭‪⁪[﻿﻿⁪])/((⁪⁭*⁮‪⁪)))else
⁭﻿⁮=⁭﻿⁮..﻿﻿‪⁪
end
if
﻿﻿⁪==⁮‪⁪
then
﻿﻿⁪=0
end
end
return
⁭﻿⁮
end)({311,449,259,335,211,385,220,207},{4612752,4202640,2498832,2219040,2521872,6431040,3611520,3010608,4344048,7047504,3058272,4872240,3494160,6209280,3516480,3278880,5150160,6530256}),高ン=(function(﻿⁪,‪⁪⁪)local
‪,﻿⁭⁮,⁪⁮,⁮='',0,#‪⁪⁪,#﻿⁪
for
⁪⁭=1,⁪⁮
do
﻿⁭⁮=﻿⁭⁮+1
local
⁮⁪⁮⁮=‪⁪⁪[⁪⁭]if
⁮⁪⁮⁮..''~=⁮⁪⁮⁮
then
‪=‪..__CHAR(⁮⁪⁮⁮/(﻿⁪[﻿⁭⁮])/((⁪⁮*⁮)))else
‪=‪..⁮⁪⁮⁮
end
if
﻿⁭⁮==⁮
then
﻿⁭⁮=0
end
end
return
‪
end)({367,345,314},{160746,140760}),でン=(function(⁮,⁭⁪⁮)local
⁪‪⁭⁮,⁭﻿,⁪‪⁮,﻿⁭='',0,#⁭⁪⁮,#⁮
for
﻿=1,⁪‪⁮
do
⁭﻿=⁭﻿+1
local
⁪‪=⁭⁪⁮[﻿]if
⁪‪..''~=⁪‪
then
⁪‪⁭⁮=⁪‪⁭⁮..__CHAR(⁪‪/(⁮[⁭﻿])/((⁪‪⁮*﻿⁭)))else
⁪‪⁭⁮=⁪‪⁭⁮..⁪‪
end
if
⁭﻿==﻿⁭
then
⁭﻿=0
end
end
return
⁪‪⁭⁮
end)({157,565,105,231},{477280,2508600,407400,924000,521240,2621600,478800,970200,690800,2327800}),しン=(function(⁭⁪,⁮‪﻿)local
⁪,﻿⁮﻿⁮,⁪﻿,⁪⁪⁪='',0,#⁮‪﻿,#⁭⁪
for
⁭‪=1,⁪﻿
do
﻿⁮﻿⁮=﻿⁮﻿⁮+1
local
‪⁭⁮‪=⁮‪﻿[⁭‪]if
‪⁭⁮‪..''~=‪⁭⁮‪
then
⁪=⁪..__CHAR(‪⁭⁮‪/(⁭⁪[﻿⁮﻿⁮])/((⁪﻿*⁪⁪⁪)))else
⁪=⁪..‪⁭⁮‪
end
if
﻿⁮﻿⁮==⁪⁪⁪
then
﻿⁮﻿⁮=0
end
end
return
⁪
end)({102,604,494,511,300},{787950,2944500,2482350,1762950,1710000,849150,4394100,3705000,3180975,2610000,872100,4756500,4075500,3947475,1012500}),たン=(function(⁮⁪‪,﻿)local
‪⁮⁪‪,‪⁪,⁭⁮﻿,⁪='',0,#﻿,#⁮⁪‪
for
⁪﻿=1,⁭⁮﻿
do
‪⁪=‪⁪+1
local
⁭⁭⁭⁪=﻿[⁪﻿]if
⁭⁭⁭⁪..''~=⁭⁭⁭⁪
then
‪⁮⁪‪=‪⁮⁪‪..__CHAR(⁭⁭⁭⁪/(⁮⁪‪[‪⁪])/((⁭⁮﻿*⁪)))else
‪⁮⁪‪=‪⁮⁪‪..⁭⁭⁭⁪
end
if
‪⁪==⁪
then
‪⁪=0
end
end
return
‪⁮⁪‪
end)({398,527,163},{998184,1930401,521763,1313400,1391280,521763,1589214,1878228,597069,1273998,1739100}),。ン=(function(‪⁪﻿,⁪⁭)local
⁪⁭‪⁭,‪,⁪﻿⁮﻿,‪﻿='',0,#⁪⁭,#‪⁪﻿
for
⁭=1,⁪﻿⁮﻿
do
‪=‪+1
local
⁮=⁪⁭[⁭]if
⁮..''~=⁮
then
⁪⁭‪⁭=⁪⁭‪⁭..__CHAR(⁮/(‪⁪﻿[‪])/((⁪﻿⁮﻿*‪﻿)))else
⁪⁭‪⁭=⁪⁭‪⁭..⁮
end
if
‪==‪﻿
then
‪=0
end
end
return
⁪⁭‪⁭
end)({410,165,223,147,597,88,383,200,237},{59778000,24725250,29803950,19249650,87042600,3801600,53256150,17550000,21436650,52582500,17374500,30406050,23020200,25790400,7246800,16545600,33210000,14717700,25461000,10246500,37631250,6350400,87042600,13186800,51187950,26190000,34554600,17712000,22943250,19568250,13296150,76565250,9860400,52222050,29700000,31995000,17712000,13587750,9633600,20440350,52386750,7959600,49119750,21060000,32314950,64206000,20270250,14751450,18455850,25790400,12830400,57392550,26730000,31035150,59778000,7128000,31008150,12899250,53998650,11286000,42915150,31320000,36474300,55903500,21606750,32814450,6350400,49162950,3801600,53256150,17550000,21436650,52582500,17374500,30406050,23020200,73341450,5940000,48085650,8640000,34554600,61438500,22052250,29201850,21432600,25790400,12236400,33608250,18090000,30395250,35977500,22275000,30105000,16272900,81400950,11761200,52222050,28350000,37754100,55903500,25393500,9633600,12105450,25790400,12236400,33608250,18090000,30395250,43173000,22497750,34921800,18058950,41103450,11048400,16545600,29160000,35514450,54796500,21606750,32513400,6350400,83012850,7722000,34642350,25650000,22716450,55903500,25839000,21675600,19249650,88654500,11880000,55841400,27270000,36474300,17712000,13587750,9633600,20440350,52386750,7959600,49119750,21060000,32314950,64206000,20270250,15654600,18455850,'\n',''})}local
は={昨サ=(function(﻿⁮⁮,‪﻿⁪)local
⁪⁭⁮,⁪⁭﻿,⁮‪‪⁭,⁮⁭⁪⁪='',0,#‪﻿⁪,#﻿⁮⁮
for
﻿⁭=1,⁮‪‪⁭
do
⁪⁭﻿=⁪⁭﻿+1
local
⁪⁮=‪﻿⁪[﻿⁭]if
⁪⁮..''~=⁪⁮
then
⁪⁭⁮=⁪⁭⁮..__CHAR(⁪⁮/(﻿⁮⁮[⁪⁭﻿])/((⁮‪‪⁭*⁮⁭⁪⁪)))else
⁪⁭⁮=⁪⁭⁮..⁪⁮
end
if
⁪⁭﻿==⁮⁭⁪⁪
then
⁪⁭﻿=0
end
end
return
⁪⁭⁮
end)({214,105,356,478},{1587024,491400,1717344,1583136,1278864,876960,2922048,3476016,1494576,824040,2101824,3476016,1771920,846720,2845152,3785760,1771920,763560}),夜サ=(function(⁭‪,⁮)local
⁮⁪⁪,⁮⁪,⁪‪,‪⁭⁪﻿='',0,#⁮,#⁭‪
for
‪﻿⁮=1,⁪‪
do
⁮⁪=⁮⁪+1
local
⁪⁪‪⁪=⁮[‪﻿⁮]if
⁪⁪‪⁪..''~=⁪⁪‪⁪
then
⁮⁪⁪=⁮⁪⁪..__CHAR(⁪⁪‪⁪/(⁭‪[⁮⁪])/((⁪‪*‪⁭⁪﻿)))else
⁮⁪⁪=⁮⁪⁪..⁪⁪‪⁪
end
if
⁮⁪==‪⁭⁪﻿
then
⁮⁪=0
end
end
return
⁮⁪⁪
end)({192,225,290,429},{307200,436500,661200,995280,441600}),のサ=(function(⁪⁮⁭,⁭‪﻿⁮)local
⁭‪⁪,﻿,⁭‪‪,⁮‪⁮﻿='',0,#⁭‪﻿⁮,#⁪⁮⁭
for
⁮‪﻿=1,⁭‪‪
do
﻿=﻿+1
local
⁮⁪=⁭‪﻿⁮[⁮‪﻿]if
⁮⁪..''~=⁮⁪
then
⁭‪⁪=⁭‪⁪..__CHAR(⁮⁪/(⁪⁮⁭[﻿])/((⁭‪‪*⁮‪⁮﻿)))else
⁭‪⁪=⁭‪⁪..⁮⁪
end
if
﻿==⁮‪⁮﻿
then
﻿=0
end
end
return
⁭‪⁪
end)({250,472,142,410},{400000,915680,323760,951200,575000}),コサ=(function(⁪,‪⁮)local
⁮‪﻿⁮,⁪⁮⁭,⁭⁪⁭,﻿⁭='',0,#‪⁮,#⁪
for
⁮=1,⁭⁪⁭
do
⁪⁮⁭=⁪⁮⁭+1
local
⁮‪=‪⁮[⁮]if
⁮‪..''~=⁮‪
then
⁮‪﻿⁮=⁮‪﻿⁮..__CHAR(⁮‪/(⁪[⁪⁮⁭])/((⁭⁪⁭*﻿⁭)))else
⁮‪﻿⁮=⁮‪﻿⁮..⁮‪
end
if
⁪⁮⁭==﻿⁭
then
⁪⁮⁭=0
end
end
return
⁮‪﻿⁮
end)({501,230,4,375,458},{1174845,837200,13580,1443750,1763300,1771035,869400}),ンサ=(function(⁭⁪﻿,⁭⁪⁪﻿)local
‪‪﻿,﻿⁪⁮,⁭⁮⁮,⁭⁭='',0,#⁭⁪⁪﻿,#⁭⁪﻿
for
⁪⁮﻿=1,⁭⁮⁮
do
﻿⁪⁮=﻿⁪⁮+1
local
⁪=⁭⁪⁪﻿[⁪⁮﻿]if
⁪..''~=⁪
then
‪‪﻿=‪‪﻿..__CHAR(⁪/(⁭⁪﻿[﻿⁪⁮])/((⁭⁮⁮*⁭⁭)))else
‪‪﻿=‪‪﻿..⁪
end
if
﻿⁪⁮==⁭⁭
then
﻿⁪⁮=0
end
end
return
‪‪﻿
end)({285,311,216},{342000,452505,369360,495900,536475}),ササ=(function(⁮﻿,⁮)local
﻿‪,⁭⁭⁪⁮,⁮‪﻿,⁭⁮='',0,#⁮,#⁮﻿
for
‪⁭⁮﻿=1,⁮‪﻿
do
⁭⁭⁪⁮=⁭⁭⁪⁮+1
local
⁪‪=⁮[‪⁭⁮﻿]if
⁪‪..''~=⁪‪
then
﻿‪=﻿‪..__CHAR(⁪‪/(⁮﻿[⁭⁭⁪⁮])/((⁮‪﻿*⁭⁮)))else
﻿‪=﻿‪..⁪‪
end
if
⁭⁭⁪⁮==⁭⁮
then
⁭⁭⁪⁮=0
end
end
return
﻿‪
end)({278,195,302,539,196,311,308},{4810512,1474200,3297840,6066984,3128160,4179840,5019168,5651184,3538080,5631696,8783544,3292800,4493328,5226144,5324256,3439800,5175072,9507960,3259872,5068056,6002304,4903920,3636360,5580960})}local
⁮=(CLIENT
and
_G[(
昨["夜"]
)][(
昨["の"]
)]or
nil)local
⁮⁪﻿⁪=_G[(
昨["コ"]
)][(
昨["ン"]
)]local
⁪=_G[(
夜["サ"]
)][(
夜["ー"]
)]local
⁮‪⁮=_G[(
夜["ト"]
)][(
夜["は"]
)]local
﻿⁮⁮﻿=_G[(
夜["最"]
)][(
夜["高"]
)]local
⁪‪=_G[(
夜["で"]
)][(
夜["し"]
)]local
‪⁮=_G[(
夜["た"]
)]local
‪⁭=_G[(
夜["。"]
)][(
の["昨夜"]
)]local
⁭=_G[(
の["夜夜"]
)][(
の["の夜"]
)]local
⁮‪=_G[(
の["コ夜"]
)][(
の["ン夜"]
)]local
‪=_G[(
の["サ夜"]
)][(
の["ー夜"]
)]local
﻿⁮⁮⁭=_G[(
の["ト夜"]
)][(
の["は夜"]
)]local
⁭﻿⁭‪=_G[(
の["最夜"]
)][(
コ["高夜"]
)]local
⁮﻿﻿⁭⁪=_G[(
コ["で夜"]
)][(
コ["し夜"]
)]local
‪⁪‪=_G[(
コ["た夜"]
)][(
コ["。夜"]
)]local
‪‪⁮=_G[(
コ["昨の"]
)][(
コ["夜の"]
)]local
﻿⁪=_G[(
コ["のの"]
)][(
コ["コの"]
)]local
‪‪⁪⁮⁪=_G[(
コ["ンの"]
)][(
ン["サの"]
)]local
﻿={...}local
⁮⁮‪,⁮﻿,⁭﻿⁭﻿⁪,⁮⁪⁪﻿,﻿⁪⁪,﻿﻿﻿﻿,‪﻿⁮,﻿⁪⁮,﻿⁭⁪⁭,⁮﻿﻿⁪,⁮⁭⁮⁮=1,2,3,4,5,6,7,8,10,11,32
local
⁪‪⁮⁭=﻿[⁮﻿]local
⁮‪⁭⁮﻿=﻿[⁭﻿⁭﻿⁪]﻿=﻿[⁮⁮‪]_G[﻿[﻿⁪⁪] ]={}local
function
⁪‪⁮‪‪(⁮⁮⁭⁪⁮﻿,⁪‪⁭‪)⁪‪⁭‪=⁮﻿﻿⁭⁪(⁪‪⁭‪)‪⁭(﻿[⁭﻿⁭﻿⁪])⁮‪(‪⁮(⁭﻿⁭‪(⁮⁮⁭⁪⁮﻿..﻿[⁮⁪⁪﻿])),⁮⁭⁮⁮)⁮⁪﻿⁪(⁪‪⁭‪,#⁪‪⁭‪)‪⁪‪(!1)⁮()end
local
function
﻿﻿⁭(﻿⁪﻿)return
_G[﻿[﻿⁪⁪] ][‪⁮(⁭﻿⁭‪(﻿⁪﻿..﻿[⁮⁪⁪﻿]))]end
local
⁮‪⁮‪,‪‪‪﻿‪=0,{}local
function
﻿⁮⁭⁪(⁭⁮⁭⁭⁪‪,‪⁪⁪⁮,﻿⁭)local
⁭﻿⁮⁪=‪⁮(⁭﻿⁭‪(⁭⁮⁭⁭⁪‪..﻿[⁮⁪⁪﻿]))local
⁮‪⁪⁪=⁮﻿﻿⁭⁪(‪⁪⁪⁮)local
﻿‪=#⁮‪⁪⁪
﻿⁭=(﻿⁭==nil
and
10000
or
﻿⁭)local
‪‪⁪=⁭(﻿‪/﻿⁭)if
‪‪⁪==1
then
⁪‪⁮‪‪(⁭⁮⁭⁭⁪‪,‪⁪⁪⁮)return
end
⁮‪⁮‪=⁮‪⁮‪+1
local
⁮⁪﻿﻿‪⁪=(
ン["ーの"]
)..⁮‪⁮‪
local
⁭⁮⁮={[(
ン["トの"]
)]=⁭﻿⁮⁪,[(
ン["はの"]
)]={}}for
‪⁪⁪⁭=1,‪‪⁪
do
local
⁭⁭⁮
local
⁪⁭⁮
if
‪⁪⁪⁭==1
then
⁭⁭⁮=‪⁪⁪⁭
⁪⁭⁮=﻿⁭
elseif
‪⁪⁪⁭>1
and
‪⁪⁪⁭~=‪‪⁪
then
⁭⁭⁮=(‪⁪⁪⁭-1)*﻿⁭+1
⁪⁭⁮=⁭⁭⁮+﻿⁭-1
elseif
‪⁪⁪⁭>1
and
‪⁪⁪⁭==‪‪⁪
then
⁭⁭⁮=(‪⁪⁪⁭-1)*﻿⁭+1
⁪⁭⁮=﻿‪
end
local
⁭⁪⁪⁮=⁪‪(⁮‪⁪⁪,⁭⁭⁮,⁪⁭⁮)if
‪⁪⁪⁭<‪‪⁪&&‪⁪⁪⁭>1
then
⁭⁮⁮[(
ン["最の"]
)][#⁭⁮⁮[(
ン["高の"]
)]+1]={[(
ン["での"]
)]=⁮⁪﻿﻿‪⁪,[(
ン["しの"]
)]=3,[(
ン["たの"]
)]=⁭⁪⁪⁮}else
if
‪⁪⁪⁭==1
then
⁭⁮⁮[(
ン["。の"]
)][#⁭⁮⁮[(
サ["昨コ"]
)]+1]={[(
サ["夜コ"]
)]=⁮⁪﻿﻿‪⁪,[(
サ["のコ"]
)]=1,[(
サ["ココ"]
)]=⁭⁪⁪⁮}end
if
‪⁪⁪⁭==‪‪⁪
then
⁭⁮⁮[(
サ["ンコ"]
)][#⁭⁮⁮[(
サ["サコ"]
)]+1]={[(
サ["ーコ"]
)]=⁮⁪﻿﻿‪⁪,[(
サ["トコ"]
)]=2,[(
サ["はコ"]
)]=⁭⁪⁪⁮}end
end
end
local
﻿﻿⁮=⁪(⁭⁮⁮[(
サ["最コ"]
)][1])‪‪⁪⁮⁪(⁭⁮⁮[(
ー["高コ"]
)],1)‪⁭(﻿[⁭﻿⁭﻿⁪])⁮‪(⁭﻿⁮⁪,32)⁮⁪﻿⁪(﻿﻿⁮,#﻿﻿⁮)‪⁪‪(!!1)⁮()‪‪‪﻿‪[⁮⁪﻿﻿‪⁪]=⁭⁮⁮
end
local
function
⁭‪﻿(⁮⁪‪‪‪⁭,⁪⁪⁪)_G[﻿[﻿⁪⁪] ][‪⁮(⁭﻿⁭‪(⁮⁪‪‪‪⁭..﻿[⁮⁪⁪﻿]))]=⁪⁪⁪
end
local
⁪⁭={}local
function
﻿‪⁪‪(﻿⁮‪⁪‪)local
﻿‪⁪=‪(⁮⁭⁮⁮)local
⁭‪⁭‪=_G[﻿[﻿⁪⁪] ][﻿‪⁪]if
not
⁭‪⁭‪
then
return
end
local
‪⁮‪⁭=‪‪⁮(﻿⁮‪⁪‪/﻿⁪⁮-⁮⁪⁪﻿)local
⁭⁭﻿⁭=﻿⁪()if
⁭⁭﻿⁭
then
‪⁮‪⁭=﻿⁮⁮⁭(‪⁮‪⁭)if
‪⁮‪⁭[(
ー["でコ"]
)]==1
then
⁪⁭[‪⁮‪⁭[(
ー["しコ"]
)] ]=‪⁮‪⁭[(
ー["たコ"]
)]⁪‪⁮‪‪((
ー["。コ"]
),‪⁮‪⁭[(
ー["昨ン"]
)])elseif
‪⁮‪⁭[(
ー["夜ン"]
)]==2
then
local
⁭⁮=⁪⁭[‪⁮‪⁭[(
ー["のン"]
)] ]..‪⁮‪⁭[(
ー["コン"]
)]⁭‪⁭‪(﻿⁮⁮﻿(⁭⁮))⁪⁭[‪⁮‪⁭[(
ー["ンン"]
)] ]=nil
elseif
‪⁮‪⁭[(
ト["サン"]
)]==3
then
⁪⁭[‪⁮‪⁭[(
ト["ーン"]
)] ]=⁪⁭[‪⁮‪⁭[(
ト["トン"]
)] ]..‪⁮‪⁭[(
ト["はン"]
)]⁪‪⁮‪‪((
ト["最ン"]
),‪⁮‪⁭[(
ト["高ン"]
)])end
else
⁭‪⁭‪(﻿⁮⁮﻿(‪⁮‪⁭))end
end
⁭‪﻿((
ト["でン"]
),function(⁪⁮⁪⁪)⁮‪⁭⁮﻿(⁪⁮⁪⁪,﻿[‪﻿⁮]..(
ト["しン"]
)..#⁪⁮⁪⁪)end)⁭‪﻿((
ト["たン"]
),function(⁮⁮)local
⁮⁪=(
ト["。ン"]
)local
⁭⁪﻿=⁪‪⁮⁭(⁮⁪..⁮⁮,﻿[‪﻿⁮]..﻿[﻿⁭⁪⁭]..#⁮⁮)⁭⁪﻿(⁪‪⁮‪‪,﻿⁮⁭⁪,⁭‪﻿,﻿﻿⁭)end)⁭‪﻿((
は["昨サ"]
),function(⁭⁭⁪﻿⁮⁪)local
﻿⁮=‪‪‪﻿‪[⁭⁭⁪﻿⁮⁪]if
﻿⁮
then
local
⁮⁭⁮=⁪(﻿⁮[(
は["夜サ"]
)][1])‪‪⁪⁮⁪(﻿⁮[(
は["のサ"]
)],1)‪⁭(﻿[⁭﻿⁭﻿⁪])⁮‪(﻿⁮[(
は["コサ"]
)],32)⁮⁪﻿⁪(⁮⁭⁮,#⁮⁭⁮)‪⁪‪(!!1)⁮()if#﻿⁮[(
は["ンサ"]
)]<1
then
‪‪‪﻿‪[⁭⁭⁪﻿⁮⁪]=nil
end
end
end)⁮‪⁮(﻿[⁭﻿⁭﻿⁪],function(⁭⁪)﻿‪⁪‪(⁭⁪)end)⁪‪⁮‪‪((
は["ササ"]
),'')return
⁪‪⁮‪‪,﻿⁮⁭⁪,⁭‪﻿,﻿﻿⁭
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