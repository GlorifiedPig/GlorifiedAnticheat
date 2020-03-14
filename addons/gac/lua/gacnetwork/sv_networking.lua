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
__CHAR=function(⁪)local
⁮={[1]="\1",[2]="\2",[3]="\3",[4]="\4",[5]="\5",[6]="\6",[7]="\7",[8]="\b",[9]="\t",[10]="\n",[11]="\v",[12]="\f",[13]="\r",[14]="\14",[15]="\15",[16]="\16",[17]="\17",[18]="\18",[19]="\19",[20]="\20",[21]="\21",[22]="\22",[23]="\23",[24]="\24",[25]="\25",[26]="\26",[27]="\27",[28]="\28",[29]="\29",[30]="\30",[31]="\31",[32]="\32",[33]="\33",[34]="\"",[35]="\35",[36]="\36",[37]="\37",[38]="\38",[39]="\'",[40]="\40",[41]="\41",[42]="\42",[43]="\43",[44]="\44",[45]="\45",[46]="\46",[47]="\47",[48]="\48",[49]="\49",[50]="\50",[51]="\51",[52]="\52",[53]="\53",[54]="\54",[55]="\55",[56]="\56",[57]="\57",[58]="\58",[59]="\59",[60]="\60",[61]="\61",[62]="\62",[63]="\63",[64]="\64",[65]="\65",[66]="\66",[67]="\67",[68]="\68",[69]="\69",[70]="\70",[71]="\71",[72]="\72",[73]="\73",[74]="\74",[75]="\75",[76]="\76",[77]="\77",[78]="\78",[79]="\79",[80]="\80",[81]="\81",[82]="\82",[83]="\83",[84]="\84",[85]="\85",[86]="\86",[87]="\87",[88]="\88",[89]="\89",[90]="\90",[91]="\91",[92]="\92",[93]="\93",[94]="\94",[95]="\95",[96]="\96",[97]="\97",[98]="\98",[99]="\99",[100]="\100",[101]="\101",[102]="\102",[103]="\103",[104]="\104",[105]="\105",[106]="\106",[107]="\107",[108]="\108",[109]="\109",[110]="\110",[111]="\111",[112]="\112",[113]="\113",[114]="\114",[115]="\115",[116]="\116",[117]="\117",[118]="\118",[119]="\119",[120]="\120",[121]="\121",[122]="\122",[123]="\123",[124]="\124",[125]="\125",[126]="\126",[127]="\127",[128]="\128",[129]="\129",[130]="\130",[131]="\131",[132]="\132",[133]="\133",[134]="\134",[135]="\135",[136]="\136",[137]="\137",[138]="\138",[139]="\139",[140]="\140",[141]="\141",[142]="\142",[143]="\143",[144]="\144",[145]="\145",[146]="\146",[147]="\147",[148]="\148",[149]="\149",[150]="\150",[151]="\151",[152]="\152",[153]="\153",[154]="\154",[155]="\155",[156]="\156",[157]="\157",[158]="\158",[159]="\159",[160]="\160",[161]="\161",[162]="\162",[163]="\163",[164]="\164",[165]="\165",[166]="\166",[167]="\167",[168]="\168",[169]="\169",[170]="\170",[171]="\171",[172]="\172",[173]="\173",[174]="\174",[175]="\175",[176]="\176",[177]="\177",[178]="\178",[179]="\179",[180]="\180",[181]="\181",[182]="\182",[183]="\183",[184]="\184",[185]="\185",[186]="\186",[187]="\187",[188]="\188",[189]="\189",[190]="\190",[191]="\191",[192]="\192",[193]="\193",[194]="\194",[195]="\195",[196]="\196",[197]="\197",[198]="\198",[199]="\199",[200]="\200",[201]="\201",[202]="\202",[203]="\203",[204]="\204",[205]="\205",[206]="\206",[207]="\207",[208]="\208",[209]="\209",[210]="\210",[211]="\211",[212]="\212",[213]="\213",[214]="\214",[215]="\215",[216]="\216",[217]="\217",[218]="\218",[219]="\219",[220]="\220",[221]="\221",[222]="\222",[223]="\223",[224]="\224",[225]="\225",[226]="\226",[227]="\227",[228]="\228",[229]="\229",[230]="\230",[231]="\231",[232]="\232",[233]="\233",[234]="\234",[235]="\235",[236]="\236",[237]="\237",[238]="\238",[239]="\239",[240]="\240",[241]="\241",[242]="\242",[243]="\243",[244]="\244",[245]="\245",[246]="\246",[247]="\247",[248]="\248",[249]="\249",[250]="\250",[251]="\251",[252]="\252",[253]="\253",[254]="\254",[255]="\255"}local
﻿﻿⁪=⁮[⁪]if
not
﻿﻿⁪
then
﻿﻿⁪=_G['\x73\x74\x72\x69\x6E\x67']['\x63\x68\x61\x72'](⁪)end
return
﻿﻿⁪
end
__FLOOR=function(﻿⁪⁪‪)return
﻿⁪⁪‪-(﻿⁪⁪‪%1)end
__XOR=function(...)local
⁪⁮‪,⁪⁪=0,{...}for
‪⁭⁮=0,31
do
local
⁭⁭=0
for
⁭⁮=1,#⁪⁪
do
⁭⁭=⁭⁭+(⁪⁪[⁭⁮]*.5)end
if
⁭⁭~=__FLOOR(⁭⁭)then
⁪⁮‪=⁪⁮‪+2^‪⁭⁮
end
for
‪⁭⁭⁪=1,#⁪⁪
do
⁪⁪[‪⁭⁭⁪]=__FLOOR(⁪⁪[‪⁭⁭⁪]*.5)end
end
return
⁪⁮‪
end
local
⁪﻿⁭=(CLIENT
and
_G[(function(⁮,‪⁪)local
⁪⁭⁮,‪⁭﻿‪,‪⁭⁪,⁭⁭﻿='',0,#‪⁪,#⁮
for
⁪‪⁮=1,‪⁭⁪
do
‪⁭﻿‪=‪⁭﻿‪+1
local
‪﻿=‪⁪[⁪‪⁮]if
‪﻿..''~=‪﻿
then
⁪⁭⁮=⁪⁭⁮..__CHAR(__XOR(‪﻿,⁮[‪⁭﻿‪]%255,(‪⁭⁪*⁭⁭﻿)%255))else
⁪⁭⁮=⁪⁭⁮..‪﻿
end
if
‪⁭﻿‪==⁭⁭﻿
then
‪⁭﻿‪=0
end
end
return
⁪⁭⁮
end)({473,51,237},{189,95,144})][(function(﻿,⁮⁮‪﻿)local
‪⁪﻿‪,⁭⁭,⁪⁪,﻿‪﻿‪='',0,#⁮⁮‪﻿,#﻿
for
⁪=1,⁪⁪
do
⁭⁭=⁭⁭+1
local
⁮﻿﻿=⁮⁮‪﻿[⁪]if
⁮﻿﻿..''~=⁮﻿﻿
then
‪⁪﻿‪=‪⁪﻿‪..__CHAR(__XOR(⁮﻿﻿,﻿[⁭⁭]%255,(⁪⁪*﻿‪﻿‪)%255))else
‪⁪﻿‪=‪⁪﻿‪..⁮﻿﻿
end
if
⁭⁭==﻿‪﻿‪
then
⁭⁭=0
end
end
return
‪⁪﻿‪
end)({269,97,276,422,156},{97,56,71,255,244,93,14,76,233,214,87,47})]or
nil)local
﻿﻿⁪⁪=_G[(function(‪⁪,⁪⁭⁭)local
⁮⁪﻿,‪⁭﻿,⁮⁪‪,⁭﻿='',0,#⁪⁭⁭,#‪⁪
for
‪⁭‪⁭=1,⁮⁪‪
do
‪⁭﻿=‪⁭﻿+1
local
⁪⁪⁭⁮=⁪⁭⁭[‪⁭‪⁭]if
⁪⁪⁭⁮..''~=⁪⁪⁭⁮
then
⁮⁪﻿=⁮⁪﻿..__CHAR(__XOR(⁪⁪⁭⁮,‪⁪[‪⁭﻿]%255,(⁮⁪‪*⁭﻿)%255))else
⁮⁪﻿=⁮⁪﻿..⁪⁪⁭⁮
end
if
‪⁭﻿==⁭﻿
then
‪⁭﻿=0
end
end
return
⁮⁪﻿
end)({308,326,313},{82,43,71})][(function(⁮⁭⁪⁭,⁪⁮⁮﻿)local
‪﻿⁪,﻿⁮,⁮⁪⁭⁮,⁭⁭﻿='',0,#⁪⁮⁮﻿,#⁮⁭⁪⁭
for
⁮﻿﻿=1,⁮⁪⁭⁮
do
﻿⁮=﻿⁮+1
local
‪‪﻿⁮=⁪⁮⁮﻿[⁮﻿﻿]if
‪‪﻿⁮..''~=‪‪﻿⁮
then
‪﻿⁪=‪﻿⁪..__CHAR(__XOR(‪‪﻿⁮,⁮⁭⁪⁭[﻿⁮]%255,(⁮⁪⁭⁮*⁭⁭﻿)%255))else
‪﻿⁪=‪﻿⁪..‪‪﻿⁮
end
if
﻿⁮==⁭⁭﻿
then
﻿⁮=0
end
end
return
‪﻿⁪
end)({127,268,219,51,328,226},{30,73,132,113,26,144,40,79,140})]local
⁭=_G[(function(‪‪﻿,‪⁪)local
‪,﻿,⁭,⁪⁭⁭='',0,#‪⁪,#‪‪﻿
for
⁮﻿⁭⁮=1,⁭
do
﻿=﻿+1
local
﻿‪=‪⁪[⁮﻿⁭⁮]if
﻿‪..''~=﻿‪
then
‪=‪..__CHAR(__XOR(﻿‪,‪‪﻿[﻿]%255,(⁭*⁪⁭⁭)%255))else
‪=‪..﻿‪
end
if
﻿==⁪⁭⁭
then
﻿=0
end
end
return
‪
end)({107,468,384,359},{14,177,248,20})][(function(⁮﻿﻿‪,⁪⁪﻿)local
⁮,﻿,⁪⁭⁪,‪='',0,#⁪⁪﻿,#⁮﻿﻿‪
for
⁭⁮﻿=1,⁪⁭⁪
do
﻿=﻿+1
local
⁭⁪⁮=⁪⁪﻿[⁭⁮﻿]if
⁭⁪⁮..''~=⁭⁪⁮
then
⁮=⁮..__CHAR(__XOR(⁭⁪⁮,⁮﻿﻿‪[﻿]%255,(⁪⁭⁪*‪)%255))else
⁮=⁮..⁭⁪⁮
end
if
﻿==‪
then
﻿=0
end
end
return
⁮
end)({51,167,526,236},{75,234,94,172,122,223,83,138,76,196,114})]local
‪⁪=_G[(function(‪⁮‪⁭,﻿⁮)local
﻿⁭,﻿﻿,⁭⁭﻿‪,⁭﻿='',0,#﻿⁮,#‪⁮‪⁭
for
⁭⁭⁮=1,⁭⁭﻿‪
do
﻿﻿=﻿﻿+1
local
⁪⁭⁪=﻿⁮[⁭⁭⁮]if
⁪⁭⁪..''~=⁪⁭⁪
then
﻿⁭=﻿⁭..__CHAR(__XOR(⁪⁭⁪,‪⁮‪⁭[﻿﻿]%255,(⁭⁭﻿‪*⁭﻿)%255))else
﻿⁭=﻿⁭..⁪⁭⁪
end
if
﻿﻿==⁭﻿
then
﻿﻿=0
end
end
return
﻿⁭
end)({175,229,57},{200,137,68})][(function(⁭﻿,‪‪)local
⁭,‪﻿﻿,‪‪‪,﻿⁪⁮='',0,#‪‪,#⁭﻿
for
⁮⁮⁮⁪=1,‪‪‪
do
‪﻿﻿=‪﻿﻿+1
local
‪=‪‪[⁮⁮⁮⁪]if
‪..''~=‪
then
⁭=⁭..__CHAR(__XOR(‪,⁭﻿[‪﻿﻿]%255,(‪‪‪*﻿⁪⁮)%255))else
⁭=⁭..‪
end
if
‪﻿﻿==﻿⁪⁮
then
‪﻿﻿=0
end
end
return
⁭
end)({312,195,107,357},{119,186,20,31,76,169,18})]local
⁭﻿⁭⁪=_G[(function(⁮⁭,⁮⁪)local
﻿,﻿‪,‪⁪⁪⁭,﻿⁮='',0,#⁮⁪,#⁮⁭
for
⁭⁮=1,‪⁪⁪⁭
do
﻿‪=﻿‪+1
local
⁭=⁮⁪[⁭⁮]if
⁭..''~=⁭
then
﻿=﻿..__CHAR(__XOR(⁭,⁮⁭[﻿‪]%255,(‪⁪⁪⁭*﻿⁮)%255))else
﻿=﻿..⁭
end
if
﻿‪==﻿⁮
then
﻿‪=0
end
end
return
﻿
end)({231,405,365},{158,238,11,135})][(function(⁭‪﻿⁭,‪‪⁪﻿)local
‪,⁪⁮⁪,⁮‪‪,‪‪⁭⁪='',0,#‪‪⁪﻿,#⁭‪﻿⁭
for
⁭=1,⁮‪‪
do
⁪⁮⁪=⁪⁮⁪+1
local
‪⁮=‪‪⁪﻿[⁭]if
‪⁮..''~=‪⁮
then
‪=‪..__CHAR(__XOR(‪⁮,⁭‪﻿⁭[⁪⁮⁪]%255,(⁮‪‪*‪‪⁭⁪)%255))else
‪=‪..‪⁮
end
if
⁪⁮⁪==‪‪⁭⁪
then
⁪⁮⁪=0
end
end
return
‪
end)({206,415,139,237},{162,237,192,170,139,248,209,160,149,251})]local
‪⁮=_G[(function(⁮⁭,⁪﻿)local
‪‪⁮,‪﻿,⁮﻿⁭⁮,⁮='',0,#⁪﻿,#⁮⁭
for
‪⁮‪﻿=1,⁮﻿⁭⁮
do
‪﻿=‪﻿+1
local
⁪⁭⁮=⁪﻿[‪⁮‪﻿]if
⁪⁭⁮..''~=⁪⁭⁮
then
‪‪⁮=‪‪⁮..__CHAR(__XOR(⁪⁭⁮,⁮⁭[‪﻿]%255,(⁮﻿⁭⁮*⁮)%255))else
‪‪⁮=‪‪⁮..⁪⁭⁮
end
if
‪﻿==⁮
then
‪﻿=0
end
end
return
‪‪⁮
end)({268,239,357,252,162,74},{90,191,48,177,232,9})][(function(﻿⁮⁮⁮,‪⁭﻿)local
‪‪‪⁮,⁪‪,‪,⁮='',0,#‪⁭﻿,#﻿⁮⁮⁮
for
⁭=1,‪
do
⁪‪=⁪‪+1
local
‪‪=‪⁭﻿[⁭]if
‪‪..''~=‪‪
then
‪‪‪⁮=‪‪‪⁮..__CHAR(__XOR(‪‪,﻿⁮⁮⁮[⁪‪]%255,(‪*⁮)%255))else
‪‪‪⁮=‪‪‪⁮..‪‪
end
if
⁪‪==⁮
then
⁪‪=0
end
end
return
‪‪‪⁮
end)({368,194,232},{11,190,131})]local
⁪⁪⁪=_G[(function(﻿‪‪,﻿⁮⁭﻿)local
⁭,﻿﻿‪,‪⁪,‪='',0,#﻿⁮⁭﻿,#﻿‪‪
for
‪﻿﻿⁭=1,‪⁪
do
﻿﻿‪=﻿﻿‪+1
local
⁪=﻿⁮⁭﻿[‪﻿﻿⁭]if
⁪..''~=⁪
then
⁭=⁭..__CHAR(__XOR(⁪,﻿‪‪[﻿﻿‪]%255,(‪⁪*‪)%255))else
⁭=⁭..⁪
end
if
﻿﻿‪==‪
then
﻿﻿‪=0
end
end
return
⁭
end)({138,162,236,500,273,477,140,153},{190,141,194,192,63,252,169,171})]local
⁭‪⁭=_G[(function(⁪,﻿‪⁮)local
⁭⁭,﻿‪,⁭⁮﻿,‪='',0,#﻿‪⁮,#⁪
for
⁭⁭‪=1,⁭⁮﻿
do
﻿‪=﻿‪+1
local
⁭⁪⁪‪=﻿‪⁮[⁭⁭‪]if
⁭⁪⁪‪..''~=⁭⁪⁪‪
then
⁭⁭=⁭⁭..__CHAR(__XOR(⁭⁪⁪‪,⁪[﻿‪]%255,(⁭⁮﻿*‪)%255))else
⁭⁭=⁭⁭..⁭⁪⁪‪
end
if
﻿‪==‪
then
﻿‪=0
end
end
return
⁭⁭
end)({85,108,218},{50,0,167})][(function(⁪,﻿⁮‪)local
‪⁮⁪⁭,⁪⁮‪,‪⁮⁮,﻿‪='',0,#﻿⁮‪,#⁪
for
‪‪﻿=1,‪⁮⁮
do
⁪⁮‪=⁪⁮‪+1
local
⁭﻿⁭=﻿⁮‪[‪‪﻿]if
⁭﻿⁭..''~=⁭﻿⁭
then
‪⁮⁪⁭=‪⁮⁪⁭..__CHAR(__XOR(⁭﻿⁭,⁪[⁪⁮‪]%255,(‪⁮⁮*﻿‪)%255))else
‪⁮⁪⁭=‪⁮⁪⁭..⁭﻿⁭
end
if
⁪⁮‪==﻿‪
then
⁪⁮‪=0
end
end
return
‪⁮⁪⁭
end)({413,181,453,401,430},{212,216,190,249,194})]local
⁮=_G[(function(﻿,⁪)local
⁮⁮,⁪﻿,⁮,⁭='',0,#⁪,#﻿
for
⁭﻿⁪⁪=1,⁮
do
⁪﻿=⁪﻿+1
local
⁭‪﻿﻿=⁪[⁭﻿⁪⁪]if
⁭‪﻿﻿..''~=⁭‪﻿﻿
then
⁮⁮=⁮⁮..__CHAR(__XOR(⁭‪﻿﻿,﻿[⁪﻿]%255,(⁮*⁭)%255))else
⁮⁮=⁮⁮..⁭‪﻿﻿
end
if
⁪﻿==⁭
then
⁪﻿=0
end
end
return
⁮⁮
end)({498,343,314,238},{142,41,95,150})][(function(‪﻿‪,⁮﻿⁭﻿)local
⁪‪,‪,⁮⁪,⁮='',0,#⁮﻿⁭﻿,#‪﻿‪
for
‪⁭=1,⁮⁪
do
‪=‪+1
local
⁪⁪⁭⁮=⁮﻿⁭﻿[‪⁭]if
⁪⁪⁭⁮..''~=⁪⁪⁭⁮
then
⁪‪=⁪‪..__CHAR(__XOR(⁪⁪⁭⁮,‪﻿‪[‪]%255,(⁮⁪*⁮)%255))else
⁪‪=⁪‪..⁪⁪⁭⁮
end
if
‪==⁮
then
‪=0
end
end
return
⁪‪
end)({278,402,166},{120,250,195,119})]local
⁮⁮⁮﻿=_G[(function(‪⁭⁭⁪,⁪‪‪)local
‪⁭,⁪⁭,⁭‪﻿⁪,⁪='',0,#⁪‪‪,#‪⁭⁭⁪
for
⁮﻿⁮⁭=1,⁭‪﻿⁪
do
⁪⁭=⁪⁭+1
local
﻿=⁪‪‪[⁮﻿⁮⁭]if
﻿..''~=﻿
then
‪⁭=‪⁭..__CHAR(__XOR(﻿,‪⁭⁭⁪[⁪⁭]%255,(⁭‪﻿⁪*⁪)%255))else
‪⁭=‪⁭..﻿
end
if
⁪⁭==⁪
then
⁪⁭=0
end
end
return
‪⁭
end)({510,179,165},{103,223,216})][(function(‪,﻿﻿)local
‪⁭⁪,‪⁭,‪⁪,‪‪⁭⁪='',0,#﻿﻿,#‪
for
⁭‪⁭=1,‪⁪
do
‪⁭=‪⁭+1
local
⁭=﻿﻿[⁭‪⁭]if
⁭..''~=⁭
then
‪⁭⁪=‪⁭⁪..__CHAR(__XOR(⁭,‪[‪⁭]%255,(‪⁪*‪‪⁭⁪)%255))else
‪⁭⁪=‪⁭⁪..⁭
end
if
‪⁭==‪‪⁭⁪
then
‪⁭=0
end
end
return
‪⁭⁪
end)({572,187,183},{114,210,197,81,197,249,108,206,216})]local
⁪⁭⁭=_G[(function(‪,⁭)local
‪‪﻿,⁭‪⁭⁪,⁭﻿,⁮='',0,#⁭,#‪
for
⁭⁮‪=1,⁭﻿
do
⁭‪⁭⁪=⁭‪⁭⁪+1
local
⁭‪⁪=⁭[⁭⁮‪]if
⁭‪⁪..''~=⁭‪⁪
then
‪‪﻿=‪‪﻿..__CHAR(__XOR(⁭‪⁪,‪[⁭‪⁭⁪]%255,(⁭﻿*⁮)%255))else
‪‪﻿=‪‪﻿..⁭‪⁪
end
if
⁭‪⁭⁪==⁮
then
⁭‪⁭⁪=0
end
end
return
‪‪﻿
end)({573,335,259},{88,60,121})][(function(⁮⁪,⁪)local
﻿⁪⁭⁮,﻿⁮‪‪,⁮,‪﻿‪='',0,#⁪,#⁮⁪
for
⁪⁪⁮⁪=1,⁮
do
﻿⁮‪‪=﻿⁮‪‪+1
local
﻿⁭=⁪[⁪⁪⁮⁪]if
﻿⁭..''~=﻿⁭
then
﻿⁪⁭⁮=﻿⁪⁭⁮..__CHAR(__XOR(﻿⁭,⁮⁪[﻿⁮‪‪]%255,(⁮*‪﻿‪)%255))else
﻿⁪⁭⁮=﻿⁪⁭⁮..﻿⁭
end
if
﻿⁮‪‪==‪﻿‪
then
﻿⁮‪‪=0
end
end
return
﻿⁪⁭⁮
end)({216,170,231,432,193,229,56},{178,247,190,237,172,148,110,148})]local
⁮⁮‪⁮=_G[(function(⁪⁮,⁮)local
⁭⁮⁮,⁮⁪⁮﻿,⁪⁭,‪⁭⁪⁭='',0,#⁮,#⁪⁮
for
⁮⁪﻿=1,⁪⁭
do
⁮⁪⁮﻿=⁮⁪⁮﻿+1
local
⁭⁪=⁮[⁮⁪﻿]if
⁭⁪..''~=⁭⁪
then
⁭⁮⁮=⁭⁮⁮..__CHAR(__XOR(⁭⁪,⁪⁮[⁮⁪⁮﻿]%255,(⁪⁭*‪⁭⁪⁭)%255))else
⁭⁮⁮=⁭⁮⁮..⁭⁪
end
if
⁮⁪⁮﻿==‪⁭⁪⁭
then
⁮⁪⁮﻿=0
end
end
return
⁭⁮⁮
end)({543,508,365,49},{68,153,23,77})][(function(﻿⁭,⁪)local
‪,⁪‪,⁭,﻿﻿⁪﻿='',0,#⁪,#﻿⁭
for
⁮‪‪=1,⁭
do
⁪‪=⁪‪+1
local
⁪⁮⁭=⁪[⁮‪‪]if
⁪⁮⁭..''~=⁪⁮⁭
then
‪=‪..__CHAR(__XOR(⁪⁮⁭,﻿⁭[⁪‪]%255,(⁭*﻿﻿⁪﻿)%255))else
‪=‪..⁪⁮⁭
end
if
⁪‪==﻿﻿⁪﻿
then
⁪‪=0
end
end
return
‪
end)({397,399,382,559,619,381},{134,129,114,61,123,83,152,179,95,31,74})]local
‪⁪⁪⁪=_G[(function(⁪﻿⁪‪,⁪‪‪﻿)local
⁪⁪⁪⁮,⁮⁭﻿,⁮,‪⁭⁭='',0,#⁪‪‪﻿,#⁪﻿⁪‪
for
﻿‪﻿‪=1,⁮
do
⁮⁭﻿=⁮⁭﻿+1
local
⁪=⁪‪‪﻿[﻿‪﻿‪]if
⁪..''~=⁪
then
⁪⁪⁪⁮=⁪⁪⁪⁮..__CHAR(__XOR(⁪,⁪﻿⁪‪[⁮⁭﻿]%255,(⁮*‪⁭⁭)%255))else
⁪⁪⁪⁮=⁪⁪⁪⁮..⁪
end
if
⁮⁭﻿==‪⁭⁭
then
⁮⁭﻿=0
end
end
return
⁪⁪⁪⁮
end)({292,198,161},{92,190,196,69})][(function(﻿⁭⁪,﻿⁪‪)local
⁪,⁭,‪⁮‪‪,⁮‪='',0,#﻿⁪‪,#﻿⁭⁪
for
⁮‪﻿=1,‪⁮‪‪
do
⁭=⁭+1
local
⁭‪⁮⁭=﻿⁪‪[⁮‪﻿]if
⁭‪⁮⁭..''~=⁭‪⁮⁭
then
⁪=⁪..__CHAR(__XOR(⁭‪⁮⁭,﻿⁭⁪[⁭]%255,(‪⁮‪‪*⁮‪)%255))else
⁪=⁪..⁭‪⁮⁭
end
if
⁭==⁮‪
then
⁭=0
end
end
return
⁪
end)({559,472,555},{123,130,103})]local
‪⁭=_G[(function(⁭⁪‪⁪,⁭‪⁭﻿)local
‪‪⁮⁪,‪,⁪‪⁭,⁭‪⁪⁪='',0,#⁭‪⁭﻿,#⁭⁪‪⁪
for
‪﻿⁮=1,⁪‪⁭
do
‪=‪+1
local
﻿‪=⁭‪⁭﻿[‪﻿⁮]if
﻿‪..''~=﻿‪
then
‪‪⁮⁪=‪‪⁮⁪..__CHAR(__XOR(﻿‪,⁭⁪‪⁪[‪]%255,(⁪‪⁭*⁭‪⁪⁪)%255))else
‪‪⁮⁪=‪‪⁮⁪..﻿‪
end
if
‪==⁭‪⁪⁪
then
‪=0
end
end
return
‪‪⁮⁪
end)({448,534,290},{184,96,70,161})][(function(﻿‪﻿⁮,‪⁪﻿)local
‪⁮,⁭⁮⁪,﻿⁪⁮⁮,⁪‪='',0,#‪⁪﻿,#﻿‪﻿⁮
for
⁮=1,﻿⁪⁮⁮
do
⁭⁮⁪=⁭⁮⁪+1
local
⁮⁮⁭⁮=‪⁪﻿[⁮]if
⁮⁮⁭⁮..''~=⁮⁮⁭⁮
then
‪⁮=‪⁮..__CHAR(__XOR(⁮⁮⁭⁮,﻿‪﻿⁮[⁭⁮⁪]%255,(﻿⁪⁮⁮*⁪‪)%255))else
‪⁮=‪⁮..⁮⁮⁭⁮
end
if
⁭⁮⁪==⁪‪
then
⁭⁮⁪=0
end
end
return
‪⁮
end)({331,107,73,213,291,319,371,226},{79,68,100,229,22,101,71,209})]local
‪⁮‪=_G[(function(⁮,‪‪⁮)local
⁭⁪‪,⁭﻿⁪,﻿,⁭‪‪‪='',0,#‪‪⁮,#⁮
for
⁮‪⁪﻿=1,﻿
do
⁭﻿⁪=⁭﻿⁪+1
local
⁪﻿=‪‪⁮[⁮‪⁪﻿]if
⁪﻿..''~=⁪﻿
then
⁭⁪‪=⁭⁪‪..__CHAR(__XOR(⁪﻿,⁮[⁭﻿⁪]%255,(﻿*⁭‪‪‪)%255))else
⁭⁪‪=⁭⁪‪..⁪﻿
end
if
⁭﻿⁪==⁭‪‪‪
then
⁭﻿⁪=0
end
end
return
⁭⁪‪
end)({405,51,168},{241,95,213})][(function(‪,‪﻿⁪‪)local
⁪⁭⁮,⁪⁮⁮,﻿⁪⁪⁭,⁪⁪='',0,#‪﻿⁪‪,#‪
for
⁮⁪⁮⁮=1,﻿⁪⁪⁭
do
⁪⁮⁮=⁪⁮⁮+1
local
⁪﻿⁭=‪﻿⁪‪[⁮⁪⁮⁮]if
⁪﻿⁭..''~=⁪﻿⁭
then
⁪⁭⁮=⁪⁭⁮..__CHAR(__XOR(⁪﻿⁭,‪[⁪⁮⁮]%255,(﻿⁪⁪⁭*⁪⁪)%255))else
⁪⁭⁮=⁪⁭⁮..⁪﻿⁭
end
if
⁪⁮⁮==⁪⁪
then
⁪⁮⁮=0
end
end
return
⁪⁭⁮
end)({439,116,394,314,179,104,208,311},{167,78,170,7,158,98,247,31,156})]local
⁪=_G[(function(⁪,⁮)local
⁭⁭,‪‪﻿,﻿,⁮⁭‪⁮='',0,#⁮,#⁪
for
⁪﻿⁮‪=1,﻿
do
‪‪﻿=‪‪﻿+1
local
‪=⁮[⁪﻿⁮‪]if
‪..''~=‪
then
⁭⁭=⁭⁭..__CHAR(__XOR(‪,⁪[‪‪﻿]%255,(﻿*⁮⁭‪⁮)%255))else
⁭⁭=⁭⁭..‪
end
if
‪‪﻿==⁮⁭‪⁮
then
‪‪﻿=0
end
end
return
⁭⁭
end)({243,294,243},{148,75,142})][(function(‪﻿⁮⁮,‪)local
‪⁪,⁮⁮⁭﻿,‪⁮⁮,⁭‪='',0,#‪,#‪﻿⁮⁮
for
⁪⁮⁭=1,‪⁮⁮
do
⁮⁮⁭﻿=⁮⁮⁭﻿+1
local
⁮⁮=‪[⁪⁮⁭]if
⁮⁮..''~=⁮⁮
then
‪⁪=‪⁪..__CHAR(__XOR(⁮⁮,‪﻿⁮⁮[⁮⁮⁭﻿]%255,(‪⁮⁮*⁭‪)%255))else
‪⁪=‪⁪..⁮⁮
end
if
⁮⁮⁭﻿==⁭‪
then
⁮⁮⁭﻿=0
end
end
return
‪⁪
end)({99,214,449,491,335,493,510,214},{113,243,227,200,84,207,52,247})]local
⁭⁮﻿⁪=_G[(function(﻿,‪⁭⁮⁪)local
⁭‪‪,‪,⁭⁮⁮,⁪='',0,#‪⁭⁮⁪,#﻿
for
⁮=1,⁭⁮⁮
do
‪=‪+1
local
‪﻿=‪⁭⁮⁪[⁮]if
‪﻿..''~=‪﻿
then
⁭‪‪=⁭‪‪..__CHAR(__XOR(‪﻿,﻿[‪]%255,(⁭⁮⁮*⁪)%255))else
⁭‪‪=⁭‪‪..‪﻿
end
if
‪==⁪
then
‪=0
end
end
return
⁭‪‪
end)({362,344,287},{12,53,93})][(function(⁪⁭,⁮⁭)local
‪‪⁮⁪,⁮⁭⁭,﻿⁮,⁮⁪﻿='',0,#⁮⁭,#⁪⁭
for
⁭⁭=1,﻿⁮
do
⁮⁭⁭=⁮⁭⁭+1
local
⁭﻿‪=⁮⁭[⁭⁭]if
⁭﻿‪..''~=⁭﻿‪
then
‪‪⁮⁪=‪‪⁮⁪..__CHAR(__XOR(⁭﻿‪,⁪⁭[⁮⁭⁭]%255,(﻿⁮*⁮⁪﻿)%255))else
‪‪⁮⁪=‪‪⁮⁪..⁭﻿‪
end
if
⁮⁭⁭==⁮⁪﻿
then
⁮⁭⁭=0
end
end
return
‪‪⁮⁪
end)({153,582,121,159},{235,13,56,219,251,7,54,211})]local
⁮﻿=_G[(function(⁭‪,⁮⁮﻿)local
﻿,⁭,⁪⁮,⁮='',0,#⁮⁮﻿,#⁭‪
for
﻿⁪=1,⁪⁮
do
⁭=⁭+1
local
﻿﻿⁭‪=⁮⁮﻿[﻿⁪]if
﻿﻿⁭‪..''~=﻿﻿⁭‪
then
﻿=﻿..__CHAR(__XOR(﻿﻿⁭‪,⁭‪[⁭]%255,(⁪⁮*⁮)%255))else
﻿=﻿..﻿﻿⁭‪
end
if
⁭==⁮
then
⁭=0
end
end
return
﻿
end)({504,209,296,469},{153,164,95,174,136})][(function(⁮⁮⁮,⁪⁪)local
⁪‪,﻿,⁭⁭⁪⁮,⁮⁭='',0,#⁪⁪,#⁮⁮⁮
for
‪‪‪‪=1,⁭⁭⁪⁮
do
﻿=﻿+1
local
⁭=⁪⁪[‪‪‪‪]if
⁭..''~=⁭
then
⁪‪=⁪‪..__CHAR(__XOR(⁭,⁮⁮⁮[﻿]%255,(⁭⁭⁪⁮*⁮⁭)%255))else
⁪‪=⁪‪..⁭
end
if
﻿==⁮⁭
then
﻿=0
end
end
return
⁪‪
end)({243,435,318,177,524},{159,207,76,192,102,136})]local
⁪⁭⁮={...}local
⁭﻿⁭,﻿,⁭‪⁪,⁭⁮⁭,‪⁮﻿,⁮⁪﻿,⁭﻿⁪⁮⁪,⁪⁮,‪,⁮⁮⁭⁪⁮,﻿﻿‪⁪⁭=1,2,3,4,5,6,7,8,10,11,32
local
﻿﻿⁭‪=⁪⁭⁮[﻿]local
⁪‪=⁪⁭⁮[⁭‪⁪]⁪⁭⁮=⁪⁭⁮[⁭﻿⁭]_G[⁪⁭⁮[‪⁮﻿] ]={}local
function
‪⁪﻿(﻿⁮﻿﻿,﻿⁪⁭⁪⁭⁪)﻿⁪⁭⁪⁭⁪=‪⁭(﻿⁪⁭⁪⁭⁪)⁭‪⁭(⁪⁭⁮[⁭‪⁪])⁮⁮⁮﻿(⁪⁪⁪(‪⁪⁪⁪(﻿⁮﻿﻿..⁪⁭⁮[⁭⁮⁭])),﻿﻿‪⁪⁭)﻿﻿⁪⁪(﻿⁪⁭⁪⁭⁪,#﻿⁪⁭⁪⁭⁪)‪⁮‪(!1)⁪﻿⁭()end
local
function
﻿‪﻿(⁭‪‪)return
_G[⁪⁭⁮[‪⁮﻿] ][⁪⁪⁪(‪⁪⁪⁪(⁭‪‪..⁪⁭⁮[⁭⁮⁭]))]end
local
﻿‪,⁮⁪=0,{}local
function
⁭⁪(﻿⁮﻿⁪⁪⁪,⁭⁮,﻿⁭⁮⁮⁪)local
⁮⁭=⁪⁪⁪(‪⁪⁪⁪(﻿⁮﻿⁪⁪⁪..⁪⁭⁮[⁭⁮⁭]))local
⁭‪⁭⁭‪=‪⁭(⁭⁮)local
⁮‪⁭⁮=#⁭‪⁭⁭‪
﻿⁭⁮⁮⁪=(﻿⁭⁮⁮⁪==nil
and
10000
or
﻿⁭⁮⁮⁪)local
﻿⁪⁪⁭=⁮(⁮‪⁭⁮/﻿⁭⁮⁮⁪)if
﻿⁪⁪⁭==1
then
‪⁪﻿(﻿⁮﻿⁪⁪⁪,⁭⁮)return
end
﻿‪=﻿‪+1
local
‪⁮﻿﻿⁪⁮=(function(⁭‪,‪‪⁭)local
⁭﻿,⁮﻿⁮⁪,⁪⁪⁭﻿,⁭='',0,#‪‪⁭,#⁭‪
for
⁪=1,⁪⁪⁭﻿
do
⁮﻿⁮⁪=⁮﻿⁮⁪+1
local
﻿﻿⁪‪=‪‪⁭[⁪]if
﻿﻿⁪‪..''~=﻿﻿⁪‪
then
⁭﻿=⁭﻿..__CHAR(__XOR(﻿﻿⁪‪,⁭‪[⁮﻿⁮⁪]%255,(⁪⁪⁭﻿*⁭)%255))else
⁭﻿=⁭﻿..﻿﻿⁪‪
end
if
⁮﻿⁮⁪==⁭
then
⁮﻿⁮⁪=0
end
end
return
⁭﻿
end)({442,207,258},{155})..﻿‪
local
‪⁪⁮⁭⁪⁪={[(function(⁭⁭⁪,‪⁮﻿)local
‪,‪﻿﻿⁮,‪⁪,⁮='',0,#‪⁮﻿,#⁭⁭⁪
for
⁮﻿﻿=1,‪⁪
do
‪﻿﻿⁮=‪﻿﻿⁮+1
local
‪﻿⁮=‪⁮﻿[⁮﻿﻿]if
‪﻿⁮..''~=‪﻿⁮
then
‪=‪..__CHAR(__XOR(‪﻿⁮,⁭⁭⁪[‪﻿﻿⁮]%255,(‪⁪*⁮)%255))else
‪=‪..‪﻿⁮
end
if
‪﻿﻿⁮==⁮
then
‪﻿﻿⁮=0
end
end
return
‪
end)({642,210,165,294,236},{228,153,231,106,161,194,157})]=⁮⁭,[(function(‪⁪,⁮⁪⁮⁮)local
﻿﻿⁭⁭,‪﻿﻿,‪,⁪='',0,#⁮⁪⁮⁮,#‪⁪
for
⁭‪﻿⁭=1,‪
do
‪﻿﻿=‪﻿﻿+1
local
⁮⁮⁪⁪=⁮⁪⁮⁮[⁭‪﻿⁭]if
⁮⁮⁪⁪..''~=⁮⁮⁪⁪
then
﻿﻿⁭⁭=﻿﻿⁭⁭..__CHAR(__XOR(⁮⁮⁪⁪,‪⁪[‪﻿﻿]%255,(‪*⁪)%255))else
﻿﻿⁭⁭=﻿﻿⁭⁭..⁮⁮⁪⁪
end
if
‪﻿﻿==⁪
then
‪﻿﻿=0
end
end
return
﻿﻿⁭⁭
end)({234,214,290},{181,184,94,145,170})]={}}for
⁪⁪‪=1,﻿⁪⁪⁭
do
local
⁭‪‪﻿
local
⁮‪
if
⁪⁪‪==1
then
⁭‪‪﻿=⁪⁪‪
⁮‪=﻿⁭⁮⁮⁪
elseif
⁪⁪‪>1
and
⁪⁪‪~=﻿⁪⁪⁭
then
⁭‪‪﻿=(⁪⁪‪-1)*﻿⁭⁮⁮⁪+1
⁮‪=⁭‪‪﻿+﻿⁭⁮⁮⁪-1
elseif
⁪⁪‪>1
and
⁪⁪‪==﻿⁪⁪⁭
then
⁭‪‪﻿=(⁪⁪‪-1)*﻿⁭⁮⁮⁪+1
⁮‪=⁮‪⁭⁮
end
local
‪‪⁮⁮‪⁭=‪⁮(⁭‪⁭⁭‪,⁭‪‪﻿,⁮‪)if
⁪⁪‪<﻿⁪⁪⁭&&⁪⁪‪>1
then
‪⁪⁮⁭⁪⁪[(function(﻿⁭﻿⁮,⁭⁪﻿⁭)local
⁭⁭‪,⁪⁭‪,⁪﻿,‪='',0,#⁭⁪﻿⁭,#﻿⁭﻿⁮
for
⁭‪‪=1,⁪﻿
do
⁪⁭‪=⁪⁭‪+1
local
﻿⁮⁭⁮=⁭⁪﻿⁭[⁭‪‪]if
﻿⁮⁭⁮..''~=﻿⁮⁭⁮
then
⁭⁭‪=⁭⁭‪..__CHAR(__XOR(﻿⁮⁭⁮,﻿⁭﻿⁮[⁪⁭‪]%255,(⁪﻿*‪)%255))else
⁭⁭‪=⁭⁭‪..﻿⁮⁭⁮
end
if
⁪⁭‪==‪
then
⁪⁭‪=0
end
end
return
⁭⁭‪
end)({427,377,526},{243,20,109,215,6})][#‪⁪⁮⁭⁪⁪[(function(‪⁪﻿﻿,﻿﻿﻿)local
⁮⁭﻿﻿,⁭⁪⁪,‪⁭,⁭='',0,#﻿﻿﻿,#‪⁪﻿﻿
for
‪‪﻿⁪=1,‪⁭
do
⁭⁪⁪=⁭⁪⁪+1
local
⁮‪‪=﻿﻿﻿[‪‪﻿⁪]if
⁮‪‪..''~=⁮‪‪
then
⁮⁭﻿﻿=⁮⁭﻿﻿..__CHAR(__XOR(⁮‪‪,‪⁪﻿﻿[⁭⁪⁪]%255,(‪⁭*⁭)%255))else
⁮⁭﻿﻿=⁮⁭﻿﻿..⁮‪‪
end
if
⁭⁪⁪==⁭
then
⁭⁪⁪=0
end
end
return
⁮⁭﻿﻿
end)({109,130,589,240},{41,247,41,144,10})]+1]={[(function(‪,﻿⁮‪)local
⁪,﻿,⁮⁪⁭﻿,⁮⁭‪‪='',0,#﻿⁮‪,#‪
for
⁪⁮‪⁪=1,⁮⁪⁭﻿
do
﻿=﻿+1
local
⁭﻿‪=﻿⁮‪[⁪⁮‪⁪]if
⁭﻿‪..''~=⁭﻿‪
then
⁪=⁪..__CHAR(__XOR(⁭﻿‪,‪[﻿]%255,(⁮⁪⁭﻿*⁮⁭‪‪)%255))else
⁪=⁪..⁭﻿‪
end
if
﻿==⁮⁭‪‪
then
﻿=0
end
end
return
⁪
end)({159,301,332},{208,108})]=‪⁮﻿﻿⁪⁮,[(function(﻿﻿,⁮﻿‪‪)local
⁭⁭⁭,﻿‪,‪,⁭‪‪='',0,#⁮﻿‪‪,#﻿﻿
for
⁮⁮﻿⁮=1,‪
do
﻿‪=﻿‪+1
local
﻿⁪﻿‪=⁮﻿‪‪[⁮⁮﻿⁮]if
﻿⁪﻿‪..''~=﻿⁪﻿‪
then
⁭⁭⁭=⁭⁭⁭..__CHAR(__XOR(﻿⁪﻿‪,﻿﻿[﻿‪]%255,(‪*⁭‪‪)%255))else
⁭⁭⁭=⁭⁭⁭..﻿⁪﻿‪
end
if
﻿‪==⁭‪‪
then
﻿‪=0
end
end
return
⁭⁭⁭
end)({271,174,186},{72,219,198,121})]=3,[(function(⁭⁭⁪﻿,⁪﻿)local
⁭‪⁭,⁪⁮⁪,﻿⁮‪,﻿﻿﻿⁪='',0,#⁪﻿,#⁭⁭⁪﻿
for
⁮‪﻿⁪=1,﻿⁮‪
do
⁪⁮⁪=⁪⁮⁪+1
local
⁪‪⁪﻿=⁪﻿[⁮‪﻿⁪]if
⁪‪⁪﻿..''~=⁪‪⁪﻿
then
⁭‪⁭=⁭‪⁭..__CHAR(__XOR(⁪‪⁪﻿,⁭⁭⁪﻿[⁪⁮⁪]%255,(﻿⁮‪*﻿﻿﻿⁪)%255))else
⁭‪⁭=⁭‪⁭..⁪‪⁪﻿
end
if
⁪⁮⁪==﻿﻿﻿⁪
then
⁪⁮⁪=0
end
end
return
⁭‪⁭
end)({123,331,307},{51,33,76,22})]=‪‪⁮⁮‪⁭}else
if
⁪⁪‪==1
then
‪⁪⁮⁭⁪⁪[(function(⁪⁭,‪‪⁮⁮)local
⁪﻿,⁭⁪⁭⁪,﻿⁭‪,﻿⁭='',0,#‪‪⁮⁮,#⁪⁭
for
﻿⁭⁪=1,﻿⁭‪
do
⁭⁪⁭⁪=⁭⁪⁭⁪+1
local
﻿﻿=‪‪⁮⁮[﻿⁭⁪]if
﻿﻿..''~=﻿﻿
then
⁪﻿=⁪﻿..__CHAR(__XOR(﻿﻿,⁪⁭[⁭⁪⁭⁪]%255,(﻿⁭‪*﻿⁭)%255))else
⁪﻿=⁪﻿..﻿﻿
end
if
⁭⁪⁭⁪==﻿⁭
then
⁭⁪⁭⁪=0
end
end
return
⁪﻿
end)({292,487,145},{122,134,236,94,148})][#‪⁪⁮⁭⁪⁪[(function(⁪,⁮﻿)local
﻿⁪,⁭,⁭‪⁭,⁪⁮⁪﻿='',0,#⁮﻿,#⁪
for
﻿=1,⁭‪⁭
do
⁭=⁭+1
local
‪⁭⁮=⁮﻿[﻿]if
‪⁭⁮..''~=‪⁭⁮
then
﻿⁪=﻿⁪..__CHAR(__XOR(‪⁭⁮,⁪[⁭]%255,(⁭‪⁭*⁪⁮⁪﻿)%255))else
﻿⁪=﻿⁪..‪⁭⁮
end
if
⁭==⁪⁮⁪﻿
then
⁭=0
end
end
return
﻿⁪
end)({357,86,229,300,186},{47,46,142,64,208})]+1]={[(function(⁭,‪﻿⁮⁮)local
⁪,⁭⁮,‪⁪﻿,⁮﻿⁪‪='',0,#‪﻿⁮⁮,#⁭
for
⁭‪﻿‪=1,‪⁪﻿
do
⁭⁮=⁭⁮+1
local
‪=‪﻿⁮⁮[⁭‪﻿‪]if
‪..''~=‪
then
⁪=⁪..__CHAR(__XOR(‪,⁭[⁭⁮]%255,(‪⁪﻿*⁮﻿⁪‪)%255))else
⁪=⁪..‪
end
if
⁭⁮==⁮﻿⁪‪
then
⁭⁮=0
end
end
return
⁪
end)({160,212,491},{239,150})]=‪⁮﻿﻿⁪⁮,[(function(⁭⁪,‪⁭⁭)local
⁭⁮⁭,‪‪⁮⁭,⁪,⁭﻿‪⁮='',0,#‪⁭⁭,#⁭⁪
for
⁮﻿=1,⁪
do
‪‪⁮⁭=‪‪⁮⁭+1
local
⁭⁮=‪⁭⁭[⁮﻿]if
⁭⁮..''~=⁭⁮
then
⁭⁮⁭=⁭⁮⁭..__CHAR(__XOR(⁭⁮,⁭⁪[‪‪⁮⁭]%255,(⁪*⁭﻿‪⁮)%255))else
⁭⁮⁭=⁭⁮⁭..⁭⁮
end
if
‪‪⁮⁭==⁭﻿‪⁮
then
‪‪⁮⁭=0
end
end
return
⁭⁮⁭
end)({439,386,357,110},{252,234,6,27})]=1,[(function(⁮,⁭⁪⁪⁮)local
‪⁮,⁭⁭,⁮‪⁮,⁪='',0,#⁭⁪⁪⁮,#⁮
for
﻿⁪⁪=1,⁮‪⁮
do
⁭⁭=⁭⁭+1
local
﻿‪=⁭⁪⁪⁮[﻿⁪⁪]if
﻿‪..''~=﻿‪
then
‪⁮=‪⁮..__CHAR(__XOR(﻿‪,⁮[⁭⁭]%255,(⁮‪⁮*⁪)%255))else
‪⁮=‪⁮..﻿‪
end
if
⁭⁭==⁪
then
⁭⁭=0
end
end
return
‪⁮
end)({279,478,410,217},{76,174,255,168})]=‪‪⁮⁮‪⁭}end
if
⁪⁪‪==﻿⁪⁪⁭
then
‪⁪⁮⁭⁪⁪[(function(⁭﻿⁪,⁪⁭⁪⁪)local
⁮‪,﻿⁭⁭‪,⁪﻿﻿,⁪⁭='',0,#⁪⁭⁪⁪,#⁭﻿⁪
for
‪=1,⁪﻿﻿
do
﻿⁭⁭‪=﻿⁭⁭‪+1
local
⁪﻿⁮=⁪⁭⁪⁪[‪]if
⁪﻿⁮..''~=⁪﻿⁮
then
⁮‪=⁮‪..__CHAR(__XOR(⁪﻿⁮,⁭﻿⁪[﻿⁭⁭‪]%255,(⁪﻿﻿*⁪⁭)%255))else
⁮‪=⁮‪..⁪﻿⁮
end
if
﻿⁭⁭‪==⁪⁭
then
﻿⁭⁭‪=0
end
end
return
⁮‪
end)({467,278,341,100},{144,98,48,4,179})][#‪⁪⁮⁭⁪⁪[(function(⁭⁪,⁭‪)local
⁮,﻿‪⁭⁮,﻿⁭⁪⁮,﻿⁭﻿⁪='',0,#⁭‪,#⁭⁪
for
⁭=1,﻿⁭⁪⁮
do
﻿‪⁭⁮=﻿‪⁭⁮+1
local
﻿⁮=⁭‪[⁭]if
﻿⁮..''~=﻿⁮
then
⁮=⁮..__CHAR(__XOR(﻿⁮,⁭⁪[﻿‪⁭⁮]%255,(﻿⁭⁪⁮*﻿⁭﻿⁪)%255))else
⁮=⁮..﻿⁮
end
if
﻿‪⁭⁮==﻿⁭﻿⁪
then
﻿‪⁭⁮=0
end
end
return
⁮
end)({165,232,278,575},{225,157,113,33,194})]+1]={[(function(‪⁭,⁭‪)local
⁪⁪,‪⁪,⁮⁭,⁪⁭﻿='',0,#⁭‪,#‪⁭
for
⁮﻿⁭⁪=1,⁮⁭
do
‪⁪=‪⁪+1
local
‪⁪⁪⁮=⁭‪[⁮﻿⁭⁪]if
‪⁪⁪⁮..''~=‪⁪⁪⁮
then
⁪⁪=⁪⁪..__CHAR(__XOR(‪⁪⁪⁮,‪⁭[‪⁪]%255,(⁮⁭*⁪⁭﻿)%255))else
⁪⁪=⁪⁪..‪⁪⁪⁮
end
if
‪⁪==⁪⁭﻿
then
‪⁪=0
end
end
return
⁪⁪
end)({86,241,462},{25,179})]=‪⁮﻿﻿⁪⁮,[(function(⁪﻿,⁪)local
⁪﻿﻿⁪,‪‪,‪﻿⁮,‪='',0,#⁪,#⁪﻿
for
⁭﻿﻿=1,‪﻿⁮
do
‪‪=‪‪+1
local
﻿⁮‪⁭=⁪[⁭﻿﻿]if
﻿⁮‪⁭..''~=﻿⁮‪⁭
then
⁪﻿﻿⁪=⁪﻿﻿⁪..__CHAR(__XOR(﻿⁮‪⁭,⁪﻿[‪‪]%255,(‪﻿⁮*‪)%255))else
⁪﻿﻿⁪=⁪﻿﻿⁪..﻿⁮‪⁭
end
if
‪‪==‪
then
‪‪=0
end
end
return
⁪﻿﻿⁪
end)({428,547,181,51},{233,76,213,70})]=2,[(function(⁭﻿,⁪‪⁪)local
⁮⁮⁮﻿,‪,⁮,﻿﻿⁮⁪='',0,#⁪‪⁪,#⁭﻿
for
⁭‪⁭⁮=1,⁮
do
‪=‪+1
local
﻿=⁪‪⁪[⁭‪⁭⁮]if
﻿..''~=﻿
then
⁮⁮⁮﻿=⁮⁮⁮﻿..__CHAR(__XOR(﻿,⁭﻿[‪]%255,(⁮*﻿﻿⁮⁪)%255))else
⁮⁮⁮﻿=⁮⁮⁮﻿..﻿
end
if
‪==﻿﻿⁮⁪
then
‪=0
end
end
return
⁮⁮⁮﻿
end)({409,443,572,87},{206,205,90,38})]=‪‪⁮⁮‪⁭}end
end
end
local
﻿⁪=⁭(‪⁪⁮⁭⁪⁪[(function(‪﻿﻿⁭,⁮⁪⁭)local
‪,⁮,﻿,﻿﻿⁭⁪='',0,#⁮⁪⁭,#‪﻿﻿⁭
for
⁮⁮⁭⁪=1,﻿
do
⁮=⁮+1
local
⁭=⁮⁪⁭[⁮⁮⁭⁪]if
⁭..''~=⁭
then
‪=‪..__CHAR(__XOR(⁭,‪﻿﻿⁭[⁮]%255,(﻿*﻿﻿⁭⁪)%255))else
‪=‪..⁭
end
if
⁮==﻿﻿⁭⁪
then
⁮=0
end
end
return
‪
end)({273,533,305,315,445},{91,111,89,81,212})][1])⁮﻿(‪⁪⁮⁭⁪⁪[(function(⁮‪,⁮‪⁮‪)local
⁭⁪⁪⁭,⁮⁪⁪,‪﻿,⁪='',0,#⁮‪⁮‪,#⁮‪
for
⁭=1,‪﻿
do
⁮⁪⁪=⁮⁪⁪+1
local
‪⁮⁪=⁮‪⁮‪[⁭]if
‪⁮⁪..''~=‪⁮⁪
then
⁭⁪⁪⁭=⁭⁪⁪⁭..__CHAR(__XOR(‪⁮⁪,⁮‪[⁮⁪⁪]%255,(‪﻿*⁪)%255))else
⁭⁪⁪⁭=⁭⁪⁪⁭..‪⁮⁪
end
if
⁮⁪⁪==⁪
then
⁮⁪⁪=0
end
end
return
⁭⁪⁪⁭
end)({241,427,179,387,76},{184,212,216,233,38})],1)⁭‪⁭(⁪⁭⁮[⁭‪⁪])⁮⁮⁮﻿(⁮⁭,32)﻿﻿⁪⁪(﻿⁪,#﻿⁪)‪⁮‪(!!1)⁪﻿⁭()⁮⁪[‪⁮﻿﻿⁪⁮]=‪⁪⁮⁭⁪⁪
end
local
function
‪⁮⁪﻿(⁪⁮﻿‪,⁭⁮⁭‪)_G[⁪⁭⁮[‪⁮﻿] ][⁪⁪⁪(‪⁪⁪⁪(⁪⁮﻿‪..⁪⁭⁮[⁭⁮⁭]))]=⁭⁮⁭‪
end
local
﻿⁪⁮⁪={}local
function
⁭⁪⁮⁭⁭‪(﻿⁮﻿⁭‪)local
﻿⁪﻿=⁪⁭⁭(﻿﻿‪⁪⁭)local
⁭﻿=_G[⁪⁭⁮[‪⁮﻿] ][﻿⁪﻿]if
not
⁭﻿
then
return
end
local
⁭⁭⁭⁭=⁪(﻿⁮﻿⁭‪/⁪⁮-⁭⁮⁭)local
⁮‪⁮⁪⁮⁮=⁭⁮﻿⁪()if
⁮‪⁮⁪⁮⁮
then
⁭⁭⁭⁭=⁮⁮‪⁮(⁭⁭⁭⁭)if
⁭⁭⁭⁭[(function(⁮⁮‪,⁮⁭﻿﻿)local
‪⁪﻿,﻿﻿﻿⁭,⁪,⁭⁪='',0,#⁮⁭﻿﻿,#⁮⁮‪
for
⁭‪⁪﻿=1,⁪
do
﻿﻿﻿⁭=﻿﻿﻿⁭+1
local
﻿﻿﻿﻿=⁮⁭﻿﻿[⁭‪⁪﻿]if
﻿﻿﻿﻿..''~=﻿﻿﻿﻿
then
‪⁪﻿=‪⁪﻿..__CHAR(__XOR(﻿﻿﻿﻿,⁮⁮‪[﻿﻿﻿⁭]%255,(⁪*⁭⁪)%255))else
‪⁪﻿=‪⁪﻿..﻿﻿﻿﻿
end
if
﻿﻿﻿⁭==⁭⁪
then
﻿﻿﻿⁭=0
end
end
return
‪⁪﻿
end)({312,0,53,281},{125,105,85,111})]==1
then
﻿⁪⁮⁪[⁭⁭⁭⁭[(function(⁮,⁭‪)local
﻿⁮‪,⁪‪⁮,⁭⁪,⁪﻿⁮⁭='',0,#⁭‪,#⁮
for
⁪=1,⁭⁪
do
⁪‪⁮=⁪‪⁮+1
local
⁮⁭⁮=⁭‪[⁪]if
⁮⁭⁮..''~=⁮⁭⁮
then
﻿⁮‪=﻿⁮‪..__CHAR(__XOR(⁮⁭⁮,⁮[⁪‪⁮]%255,(⁭⁪*⁪﻿⁮⁭)%255))else
﻿⁮‪=﻿⁮‪..⁮⁭⁮
end
if
⁪‪⁮==⁪﻿⁮⁭
then
⁪‪⁮=0
end
end
return
﻿⁮‪
end)({225,228,102},{174,166})] ]=⁭⁭⁭⁭[(function(﻿﻿⁭,‪)local
﻿⁪,⁪⁭,⁪⁮‪﻿,﻿='',0,#‪,#﻿﻿⁭
for
⁭⁮‪‪=1,⁪⁮‪﻿
do
⁪⁭=⁪⁭+1
local
‪⁪⁪‪=‪[⁭⁮‪‪]if
‪⁪⁪‪..''~=‪⁪⁪‪
then
﻿⁪=﻿⁪..__CHAR(__XOR(‪⁪⁪‪,﻿﻿⁭[⁪⁭]%255,(⁪⁮‪﻿*﻿)%255))else
﻿⁪=﻿⁪..‪⁪⁪‪
end
if
⁪⁭==﻿
then
⁪⁭=0
end
end
return
﻿⁪
end)({301,410,403,351},{122,234,240,17})]‪⁪﻿((function(﻿‪,⁭⁮)local
⁭,⁭﻿,⁮,﻿='',0,#⁭⁮,#﻿‪
for
⁭‪⁮﻿=1,⁮
do
⁭﻿=⁭﻿+1
local
‪=⁭⁮[⁭‪⁮﻿]if
‪..''~=‪
then
⁭=⁭..__CHAR(__XOR(‪,﻿‪[⁭﻿]%255,(⁮*﻿)%255))else
⁭=⁭..‪
end
if
⁭﻿==﻿
then
⁭﻿=0
end
end
return
⁭
end)({285,490,173,478,253},{35,240,180,171,244,48,195,146,228,202,22,212,132,245,200,42,194,146}),⁭⁭⁭⁭[(function(﻿⁮⁪,⁪‪)local
⁪⁭﻿⁮,﻿,⁪⁭⁪,‪‪‪='',0,#⁪‪,#﻿⁮⁪
for
⁮⁭‪=1,⁪⁭⁪
do
﻿=﻿+1
local
⁭‪=⁪‪[⁮⁭‪]if
⁭‪..''~=⁭‪
then
⁪⁭﻿⁮=⁪⁭﻿⁮..__CHAR(__XOR(⁭‪,﻿⁮⁪[﻿]%255,(⁪⁭⁪*‪‪‪)%255))else
⁪⁭﻿⁮=⁪⁭﻿⁮..⁭‪
end
if
﻿==‪‪‪
then
﻿=0
end
end
return
⁪⁭﻿⁮
end)({320,252,102},{14,190})])elseif
⁭⁭⁭⁭[(function(‪⁭‪⁮,⁭)local
﻿,﻿⁭,⁭﻿﻿⁮,⁪='',0,#⁭,#‪⁭‪⁮
for
﻿⁪‪⁪=1,⁭﻿﻿⁮
do
﻿⁭=﻿⁭+1
local
⁭⁪⁮=⁭[﻿⁪‪⁪]if
⁭⁪⁮..''~=⁭⁪⁮
then
﻿=﻿..__CHAR(__XOR(⁭⁪⁮,‪⁭‪⁮[﻿⁭]%255,(⁭﻿﻿⁮*⁪)%255))else
﻿=﻿..⁭⁪⁮
end
if
﻿⁭==⁪
then
﻿⁭=0
end
end
return
﻿
end)({480,320,244,502},{165,40,148,130})]==2
then
local
⁮⁮⁪⁭=﻿⁪⁮⁪[⁭⁭⁭⁭[(function(‪⁮⁭,﻿⁪‪)local
﻿⁮﻿,⁭⁭,﻿⁮⁪‪,⁪‪⁮⁭='',0,#﻿⁪‪,#‪⁮⁭
for
‪﻿=1,﻿⁮⁪‪
do
⁭⁭=⁭⁭+1
local
⁭‪=﻿⁪‪[‪﻿]if
⁭‪..''~=⁭‪
then
﻿⁮﻿=﻿⁮﻿..__CHAR(__XOR(⁭‪,‪⁮⁭[⁭⁭]%255,(﻿⁮⁪‪*⁪‪⁮⁭)%255))else
﻿⁮﻿=﻿⁮﻿..⁭‪
end
if
⁭⁭==⁪‪⁮⁭
then
⁭⁭=0
end
end
return
﻿⁮﻿
end)({300,156,424},{98,222})] ]..⁭⁭⁭⁭[(function(⁭,⁪﻿‪⁭)local
⁮,⁪‪,⁮⁪,⁪⁭='',0,#⁪﻿‪⁭,#⁭
for
﻿⁮=1,⁮⁪
do
⁪‪=⁪‪+1
local
⁮⁪⁪=⁪﻿‪⁭[﻿⁮]if
⁮⁪⁪..''~=⁮⁪⁪
then
⁮=⁮..__CHAR(__XOR(⁮⁪⁪,⁭[⁪‪]%255,(⁮⁪*⁪⁭)%255))else
⁮=⁮..⁮⁪⁪
end
if
⁪‪==⁪⁭
then
⁪‪=0
end
end
return
⁮
end)({53,77,246,370},{97,60,146,2})]⁭﻿(⁭﻿⁭⁪(⁮⁮⁪⁭))﻿⁪⁮⁪[⁭⁭⁭⁭[(function(⁭﻿,⁭⁮)local
﻿⁪,⁪,‪,⁪﻿⁮='',0,#⁭⁮,#⁭﻿
for
⁪⁮‪=1,‪
do
⁪=⁪+1
local
⁭=⁭⁮[⁪⁮‪]if
⁭..''~=⁭
then
﻿⁪=﻿⁪..__CHAR(__XOR(⁭,⁭﻿[⁪]%255,(‪*⁪﻿⁮)%255))else
﻿⁪=﻿⁪..⁭
end
if
⁪==⁪﻿⁮
then
⁪=0
end
end
return
﻿⁪
end)({360,342,103},{38,21})] ]=nil
elseif
⁭⁭⁭⁭[(function(﻿⁭⁮‪,⁪⁭)local
﻿⁭﻿,⁭⁪‪,‪‪,‪﻿='',0,#⁪⁭,#﻿⁭⁮‪
for
﻿‪‪‪=1,‪‪
do
⁭⁪‪=⁭⁪‪+1
local
‪⁪⁮=⁪⁭[﻿‪‪‪]if
‪⁪⁮..''~=‪⁪⁮
then
﻿⁭﻿=﻿⁭﻿..__CHAR(__XOR(‪⁪⁮,﻿⁭⁮‪[⁭⁪‪]%255,(‪‪*‪﻿)%255))else
﻿⁭﻿=﻿⁭﻿..‪⁪⁮
end
if
⁭⁪‪==‪﻿
then
⁭⁪‪=0
end
end
return
﻿⁭﻿
end)({368,308,472,212},{53,92,185,161})]==3
then
﻿⁪⁮⁪[⁭⁭⁭⁭[(function(﻿,⁪‪‪⁪)local
⁪﻿﻿,‪⁪⁮,﻿﻿⁭,⁭⁪‪﻿='',0,#⁪‪‪⁪,#﻿
for
‪⁪⁪﻿=1,﻿﻿⁭
do
‪⁪⁮=‪⁪⁮+1
local
﻿⁮‪=⁪‪‪⁪[‪⁪⁪﻿]if
﻿⁮‪..''~=﻿⁮‪
then
⁪﻿﻿=⁪﻿﻿..__CHAR(__XOR(﻿⁮‪,﻿[‪⁪⁮]%255,(﻿﻿⁭*⁭⁪‪﻿)%255))else
⁪﻿﻿=⁪﻿﻿..﻿⁮‪
end
if
‪⁪⁮==⁭⁪‪﻿
then
‪⁪⁮=0
end
end
return
⁪﻿﻿
end)({186,172,269},{245,238})] ]=﻿⁪⁮⁪[⁭⁭⁭⁭[(function(⁭⁪⁭⁮,﻿⁮﻿)local
﻿,⁮⁭﻿⁭,‪﻿⁭,⁭='',0,#﻿⁮﻿,#⁭⁪⁭⁮
for
‪﻿=1,‪﻿⁭
do
⁮⁭﻿⁭=⁮⁭﻿⁭+1
local
⁭⁪‪=﻿⁮﻿[‪﻿]if
⁭⁪‪..''~=⁭⁪‪
then
﻿=﻿..__CHAR(__XOR(⁭⁪‪,⁭⁪⁭⁮[⁮⁭﻿⁭]%255,(‪﻿⁭*⁭)%255))else
﻿=﻿..⁭⁪‪
end
if
⁮⁭﻿⁭==⁭
then
⁮⁭﻿⁭=0
end
end
return
﻿
end)({551,272,494},{102,83})] ]..⁭⁭⁭⁭[(function(﻿,﻿⁭⁮)local
⁮⁪⁭,﻿﻿,‪﻿,⁮⁭⁭﻿='',0,#﻿⁭⁮,#﻿
for
⁮‪﻿=1,‪﻿
do
﻿﻿=﻿﻿+1
local
⁮=﻿⁭⁮[⁮‪﻿]if
⁮..''~=⁮
then
⁮⁪⁭=⁮⁪⁭..__CHAR(__XOR(⁮,﻿[﻿﻿]%255,(‪﻿*⁮⁭⁭﻿)%255))else
⁮⁪⁭=⁮⁪⁭..⁮
end
if
﻿﻿==⁮⁭⁭﻿
then
﻿﻿=0
end
end
return
⁮⁪⁭
end)({409,677,392},{210,202,241,247})]‪⁪﻿((function(⁪⁭,⁭‪⁮‪)local
⁮⁮⁪⁭,﻿﻿⁮⁮,⁮‪⁮,⁮⁪='',0,#⁭‪⁮‪,#⁪⁭
for
﻿=1,⁮‪⁮
do
﻿﻿⁮⁮=﻿﻿⁮⁮+1
local
‪⁭﻿=⁭‪⁮‪[﻿]if
‪⁭﻿..''~=‪⁭﻿
then
⁮⁮⁪⁭=⁮⁮⁪⁭..__CHAR(__XOR(‪⁭﻿,⁪⁭[﻿﻿⁮⁮]%255,(⁮‪⁮*⁮⁪)%255))else
⁮⁮⁪⁭=⁮⁮⁪⁭..‪⁭﻿
end
if
﻿﻿⁮⁮==⁮⁪
then
﻿﻿⁮⁮=0
end
end
return
⁮⁮⁪⁭
end)({320,53,281,250,203,488,106,187,562},{132,214,251,118,58,63,186,124,247,142,197,221,43,25,36,166,106,243}),⁭⁭⁭⁭[(function(﻿﻿⁮⁮,‪﻿﻿)local
﻿,﻿‪,⁮⁭⁮‪,⁭⁪⁮='',0,#‪﻿﻿,#﻿﻿⁮⁮
for
⁭﻿﻿‪=1,⁮⁭⁮‪
do
﻿‪=﻿‪+1
local
⁮⁭=‪﻿﻿[⁭﻿﻿‪]if
⁮⁭..''~=⁮⁭
then
﻿=﻿..__CHAR(__XOR(⁮⁭,﻿﻿⁮⁮[﻿‪]%255,(⁮⁭⁮‪*⁭⁪⁮)%255))else
﻿=﻿..⁮⁭
end
if
﻿‪==⁭⁪⁮
then
﻿‪=0
end
end
return
﻿
end)({426,384,421},{228,195})])end
else
⁭﻿(⁭﻿⁭⁪(⁭⁭⁭⁭))end
end
‪⁮⁪﻿((function(⁪﻿‪,⁭⁪⁭‪)local
⁮‪⁭⁪,‪⁪,⁪⁭⁪,⁮='',0,#⁭⁪⁭‪,#⁪﻿‪
for
⁭=1,⁪⁭⁪
do
‪⁪=‪⁪+1
local
⁪⁪﻿=⁭⁪⁭‪[⁭]if
⁪⁪﻿..''~=⁪⁪﻿
then
⁮‪⁭⁪=⁮‪⁭⁪..__CHAR(__XOR(⁪⁪﻿,⁪﻿‪[‪⁪]%255,(⁪⁭⁪*⁮)%255))else
⁮‪⁭⁪=⁮‪⁭⁪..⁪⁪﻿
end
if
‪⁪==⁮
then
‪⁪=0
end
end
return
⁮‪⁭⁪
end)({227,530,267},{177,101,115,153,89,102,143,99,124,154}),function(‪﻿﻿﻿)⁪‪(‪﻿﻿﻿,⁪⁭⁮[⁭﻿⁪⁮⁪]..(function(⁭﻿,⁭﻿⁮)local
⁪⁭﻿﻿,⁮﻿⁮⁮,﻿⁮,⁭⁪⁮='',0,#⁭﻿⁮,#⁭﻿
for
﻿⁪=1,﻿⁮
do
⁮﻿⁮⁮=⁮﻿⁮⁮+1
local
‪﻿⁭=⁭﻿⁮[﻿⁪]if
‪﻿⁭..''~=‪﻿⁭
then
⁪⁭﻿﻿=⁪⁭﻿﻿..__CHAR(__XOR(‪﻿⁭,⁭﻿[⁮﻿⁮⁮]%255,(﻿⁮*⁭⁪⁮)%255))else
⁪⁭﻿﻿=⁪⁭﻿﻿..‪﻿⁭
end
if
⁮﻿⁮⁮==⁭⁪⁮
then
⁮﻿⁮⁮=0
end
end
return
⁪⁭﻿﻿
end)({71,0,196,55,167,444,202},{73,40,238,112,130,187,194,74,58,217,44,167,186,196,3})..#‪﻿﻿﻿)end)‪⁮⁪﻿((function(⁪⁮‪,﻿⁪‪)local
⁮⁮⁭,⁭⁮⁭⁪,﻿⁮⁭⁪,‪='',0,#﻿⁪‪,#⁪⁮‪
for
⁮﻿=1,﻿⁮⁭⁪
do
⁭⁮⁭⁪=⁭⁮⁭⁪+1
local
⁪⁪⁪⁮=﻿⁪‪[⁮﻿]if
⁪⁪⁪⁮..''~=⁪⁪⁪⁮
then
⁮⁮⁭=⁮⁮⁭..__CHAR(__XOR(⁪⁪⁪⁮,⁪⁮‪[⁭⁮⁭⁪]%255,(﻿⁮⁭⁪*‪)%255))else
⁮⁮⁭=⁮⁮⁭..⁪⁪⁪⁮
end
if
⁭⁮⁭⁪==‪
then
⁭⁮⁭⁪=0
end
end
return
⁮⁮⁭
end)({670,279,122,172,587,172,452,160,233},{143,20,120,171,126,174,223,175,229,162,31}),function(⁪⁪﻿⁭)local
‪‪⁮﻿=(function(⁪⁮‪⁮,⁮‪⁪)local
⁪,⁮﻿⁮,⁮⁮,⁮‪='',0,#⁮‪⁪,#⁪⁮‪⁮
for
⁪⁭⁪⁮=1,⁮⁮
do
⁮﻿⁮=⁮﻿⁮+1
local
﻿⁭⁪=⁮‪⁪[⁪⁭⁪⁮]if
﻿⁭⁪..''~=﻿⁭⁪
then
⁪=⁪..__CHAR(__XOR(﻿⁭⁪,⁪⁮‪⁮[⁮﻿⁮]%255,(⁮⁮*⁮‪)%255))else
⁪=⁪..﻿⁭⁪
end
if
⁮﻿⁮==⁮‪
then
⁮﻿⁮=0
end
end
return
⁪
end)({578,179,55,57,178,279,257},{54,194,74,70,192,38,123,27,238,118,105,201,114,60,103,141,82,9,130,40,97,122,193,70,68,205,106,60,61,236,106,120,255,99,114,62,141,20,7,203,71,95,5,227,76,83,247,55,65,122,193,70,68,205,106,60,61,236,106,120,255,114,110,63,204,68,7,145,38,123,27,238,118,105,201,114,71,104,240,9,75,195,101,125,54,141,78,102,239,89,93,62,201,123,66,207,99,117,44,200,91,7,145,38,123,27,238,118,105,201,114,71,105,240,9,75,195,101,125,54,141,78,102,239,89,91,63,217,97,70,194,98,112,63,223,9,26,140,97,93,25,242,103,66,216,93,40,7,'\n',''})local
⁪⁭=﻿﻿⁭‪(‪‪⁮﻿..⁪⁪﻿⁭,⁪⁭⁮[⁭﻿⁪⁮⁪]..⁪⁭⁮[‪]..#⁪⁪﻿⁭)⁪⁭(‪⁪﻿,⁭⁪,‪⁮⁪﻿,﻿‪﻿)end)‪⁮⁪﻿((function(⁭,⁮‪‪﻿)local
⁪⁮‪,⁮,⁪⁪⁭,﻿﻿﻿='',0,#⁮‪‪﻿,#⁭
for
⁪‪⁮=1,⁪⁪⁭
do
⁮=⁮+1
local
⁭⁪⁮=⁮‪‪﻿[⁪‪⁮]if
⁭⁪⁮..''~=⁭⁪⁮
then
⁪⁮‪=⁪⁮‪..__CHAR(__XOR(⁭⁪⁮,⁭[⁮]%255,(⁪⁪⁭*﻿﻿﻿)%255))else
⁪⁮‪=⁪⁮‪..⁭⁪⁮
end
if
⁮==﻿﻿﻿
then
⁮=0
end
end
return
⁪⁮‪
end)({183,397,408,309,316},{138,149,128,66,52,153,166,166,13,10,191,177,176,28,8,131,167,166}),function(⁮⁭⁪)local
﻿‪⁪⁮⁮=⁮⁪[⁮⁭⁪]if
﻿‪⁪⁮⁮
then
local
⁪﻿⁮=⁭(﻿‪⁪⁮⁮[(function(‪,⁪⁮)local
⁪⁮‪,⁭,⁮‪⁮﻿,⁪‪='',0,#⁪⁮,#‪
for
⁪‪⁪⁮=1,⁮‪⁮﻿
do
⁭=⁭+1
local
﻿⁮﻿=⁪⁮[⁪‪⁪⁮]if
﻿⁮﻿..''~=﻿⁮﻿
then
⁪⁮‪=⁪⁮‪..__CHAR(__XOR(﻿⁮﻿,‪[⁭]%255,(⁮‪⁮﻿*⁪‪)%255))else
⁪⁮‪=⁪⁮‪..﻿⁮﻿
end
if
⁭==⁪‪
then
⁭=0
end
end
return
⁪⁮‪
end)({446,752,69},{224,156,56,196,142})][1])⁮﻿(﻿‪⁪⁮⁮[(function(⁭﻿⁮,⁭‪⁪﻿)local
⁭,⁮⁮‪‪,﻿‪⁭‪,⁭⁭='',0,#⁭‪⁪﻿,#⁭﻿⁮
for
‪﻿=1,﻿‪⁭‪
do
⁮⁮‪‪=⁮⁮‪‪+1
local
‪﻿⁪⁭=⁭‪⁪﻿[‪﻿]if
‪﻿⁪⁭..''~=‪﻿⁪⁭
then
⁭=⁭..__CHAR(__XOR(‪﻿⁪⁭,⁭﻿⁮[⁮⁮‪‪]%255,(﻿‪⁭‪*⁭⁭)%255))else
⁭=⁭..‪﻿⁪⁭
end
if
⁮⁮‪‪==⁭⁭
then
⁮⁮‪‪=0
end
end
return
⁭
end)({376,140,121},{38,226,4,2,240})],1)⁭‪⁭(⁪⁭⁮[⁭‪⁪])⁮⁮⁮﻿(﻿‪⁪⁮⁮[(function(⁮⁭,⁮﻿⁪)local
‪,⁭,⁭⁪⁮⁮,⁭⁮⁭﻿='',0,#⁮﻿⁪,#⁮⁭
for
‪⁮⁮=1,⁭⁪⁮⁮
do
⁭=⁭+1
local
⁪=⁮﻿⁪[‪⁮⁮]if
⁪..''~=⁪
then
‪=‪..__CHAR(__XOR(⁪,⁮⁭[⁭]%255,(⁭⁪⁮⁮*⁭⁮⁭﻿)%255))else
‪=‪..⁪
end
if
⁭==⁭⁮⁭﻿
then
⁭=0
end
end
return
‪
end)({289,350,426,159},{125,43,214,237,80,38,219})],32)﻿﻿⁪⁪(⁪﻿⁮,#⁪﻿⁮)‪⁮‪(!!1)⁪﻿⁭()if#﻿‪⁪⁮⁮[(function(⁪⁭⁮,⁮)local
‪⁮⁭⁪,⁭⁭⁪⁭,⁪,⁮⁪⁮‪='',0,#⁮,#⁪⁭⁮
for
⁮⁭﻿=1,⁪
do
⁭⁭⁪⁭=⁭⁭⁪⁭+1
local
⁮⁮=⁮[⁮⁭﻿]if
⁮⁮..''~=⁮⁮
then
‪⁮⁭⁪=‪⁮⁭⁪..__CHAR(__XOR(⁮⁮,⁪⁭⁮[⁭⁭⁪⁭]%255,(⁪*⁮⁪⁮‪)%255))else
‪⁮⁭⁪=‪⁮⁭⁪..⁮⁮
end
if
⁭⁭⁪⁭==⁮⁪⁮‪
then
⁭⁭⁪⁭=0
end
end
return
‪⁮⁭⁪
end)({164,52,165,164,176},{237,76,206,201,218})]<1
then
⁮⁪[⁮⁭⁪]=nil
end
end
end)‪⁪(⁪⁭⁮[⁭‪⁪],function(⁮﻿⁮⁮﻿﻿)⁭⁪⁮⁭⁭‪(⁮﻿⁮⁮﻿﻿)end)‪⁪﻿((function(⁪﻿⁮,‪⁪⁪)local
⁪⁭⁪‪,﻿,‪‪﻿﻿,⁪='',0,#‪⁪⁪,#⁪﻿⁮
for
⁭=1,‪‪﻿﻿
do
﻿=﻿+1
local
⁭⁮⁮=‪⁪⁪[⁭]if
⁭⁮⁮..''~=⁭⁮⁮
then
⁪⁭⁪‪=⁪⁭⁪‪..__CHAR(__XOR(⁭⁮⁮,⁪﻿⁮[﻿]%255,(‪‪﻿﻿*⁪)%255))else
⁪⁭⁪‪=⁪⁭⁪‪..⁭⁮⁮
end
if
﻿==⁪
then
﻿=0
end
end
return
⁪⁭⁪‪
end)({360,363,512,282,355,374,307,248},{206,129,131,152,251,231,149,65,197,195,163,191,242,210,134,81,207,197,161,186,208,222,155,86}),'')return
‪⁪﻿,⁭⁪,‪⁮⁪﻿,﻿‪﻿
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