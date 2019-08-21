local _IsValid = IsValid
local _hook_Add = hook.Add
local _hook_Run = hook.Run
local _math_Round = math.Round
local _math_ceil = math.ceil
local _math_random = math.random
local _net_BytesWritten = net.BytesWritten
local _net_ReadData = net.ReadData
local _net_ReadUInt = net.ReadUInt
local _net_Receive = net.Receive
local _net_Start = net.Start
local _net_WriteData = net.WriteData
local _net_WriteUInt = net.WriteUInt
local _player_GetHumans = player.GetHumans
local _string_Explode = string.Explode
local _string_byte = string.byte
local _string_char = string.char
local _string_gsub = string.gsub
local _string_match = string.match
local _string_rep = string.rep
local _string_reverse = string.reverse
local _string_sub = string.sub
local _timer_Simple = timer.Simple
local _tonumber = tonumber
local _util_CRC = util.CRC
local _util_Compress = util.Compress
local _util_Decompress = util.Decompress
local _util_TableToJSON = util.TableToJSON

local _net_Send = (SERVER and net.Send or NULL)

--[[
	GM-LUAI Networking
	Preventing fucking nutheads from CHM from stealing our shit.

	self:ResetCounters() --Resets network counters

	self:AddReceiver(
		channelName		--Targeted channel
		handler(
			channelID	--Used in debugging
			data		--Data received
			player		--Player received from
		)
	)

	self:GetChannelId(
		channelName	--Targeted channel
	) --Get's the CRC ID of a channel

	self:HandleMessage(
		bitCount
		ply
	) --Note, this is a manditory functions when dealing with messages!

	self:Send(
		channelName	--Targeted channel
		data		--Any data type to be written
		player		--Targeted player
	)

	self:Stream(
		channelName	--Targeted channel
		data		--Any data type to be written
		player		--Targeted player
		split		--Split ratio (Note, default is 20000 bytes per split)
	) --Note, this will allow you to send over 20 MB of data w/o any issues
	anything larger than 20 MB may result in desyncronization in data messages

	self:Broadcast(
		channelName	--Targeted channel
		data		--Any data type to be written
	) --Unlike SEND, this allows you to send data to all players (not bots dummy)

	self:SendPayload(
		data	--Any data type to be written
		player	--Targeted player
	) --Unlike SEND this will send LUAI's networking payload with your code
	*You cannot chose a channel as it's set on "LoadPayload"

	self:BroadcastPayload(
		data	--Any data type to be written
	) --Unlike BROADCAST this will send LUAI's networking payload with your code
	*You cannot chose a channel as it's set on "LoadPayload"

	self:StreamPayload (
		data	--Any data type to be written
		player	--Targeted player
		split	--Split ratio (Note, default is 20000 bytes per split)
	)
	*You cannot chose a channel as it's set on "LoadPayload"

	Client functions
	gAC_Send (channelName, data)
	gAC_Stream (channelName, data, split)
	gAC_AddReceiver (channelName, handler)

	For an explenation on how this works.
	There is a normal net message on the client that would receive a custom payload known as
	Payload_001, this payload is the main handler of all network traffic coming from GM-LUAI.
	ALL networking (except for the boot payload) is kept on one single randomly generated network string
	this makes it a hell of a lot harder to intercept network traffic.

	The second payload (Payload_002) allows your code or other things to have access to send messages back
	to the server via GM-LUAI's randomly generated and custom networking.

	98% of all GM-LUAI's core functions are kept on the server.
	this includes client interfaces and other things required to run GM-LUAI.
	2% being the small network string made to load the first payload.
]]

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

gAC.Encoder.Existing_String = {}
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

if gAC.Network then return end --prevent lua refresh

gAC.Network = gAC.Network or {}
gAC.Network.ReceiveCount = 0
gAC.Network.SendCount    = 0

--Added __ to prevent conflicts with GM-LUAI's main network < if you even have GM-LUAI >.>
gAC.Network.GlobalChannel = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "GAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))
gAC.Network.GlobalAST = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "ASTGAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))
gAC.Network.Channel_Rand = gAC.Encoder.stringrandom(_math_Round(_math_random(4, 22)))
gAC.Network.Channel_Glob = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "GAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))
gAC.Network.Verify_Hook = gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12))) .. "GAC" .. gAC.Encoder.stringrandom(_math_Round(_math_random(6, 12)))

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

--[[
	Payload 001
	Loads in as the boot payload for g-AC
	determines when to send files & handles network
]]
local Payload_001 = [[--]] .. gAC.Encoder.stringrandom(_math_Round(_math_random(15, 20))) .. [[

local
_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z=net.Receive,net.Start,net.WriteUInt,net.WriteData,net.ReadUInt,net.ReadData,net.SendToServer,hook.Add,hook.Remove,util.Decompress,util.CRC,string.match,string.gsub,RunString,CompileString,tonumber,{...},1,2,3,4,5,6,7,8,11,32
p=p[q]_G[p[v] ]={}_G[p[t] ]=1
local
q={}local
function
r(_)local
a=d(z)local
b=_G[p[v] ][a]if!b
then
return
end
local
c=e(_/x-t)if
k(c,"^%[GAC%.STREAM%-%d+%]")then
local
_=k(c,"[%[GAC%.STREAM%-](%d+)[%]".."]")if
q[_]~=nil
then
q[_]=q[_]..l(c,"^%[GAC%.STREAM%-%d+%]","")end
elseif
k(c,"^%[GAC%.STREAM_START%-%d+%]")||k(c,"%[GAC%.STREAM_END%-%d+%]$")then
if
k(c,"^%[GAC%.STREAM_START%-%d+%]")then
local
_=k(c,"[%[GAC%.STREAM_START%-](%d+)[%]".."]")q[_]=l(c,"^%[GAC%.STREAM_START%-%d+%]","")end
if
k(c,"%[GAC%.STREAM_END%-%d+%]$")then
local
_=k(c,"[%[GAC%.STREAM_END%-](%d+)[%]".."]")if
q[_]~=nil
then
q[_]=q[_]..l(c,"%[GAC%.STREAM_END%-%d+%]$","")b(a,i(q[_]))q[_]=nil
end
end
else
b(a,i(c))end
end
_G[p[v] ][o(j("LoadString"..p[u]))]=function(_,a)m(a,p[x].."GAC.LoadString-"..#a)end
_G[p[v] ][o(j("LoadPayload"..p[u]))]=function(_,a)local
_=n(a,p[x]..p[y]..#a)_(p[s],p[t],p[u],p[v])end
_(p[s],function(_)r(_)end)g("Think",p[w],function()a(p[s])b(o(j("g-AC_PayloadVerification"..p[u])),z)c("",#"")f()h("Think",p[w])end)]]

local TBL = {
	--Payload
	Payload_001,
	"GAC.PayLoad_001",
	gAC.Network.GlobalChannel,
	gAC.Network.GlobalAST,
	gAC.Network.Channel_Rand,
	gAC.Network.Channel_Glob,
	gAC.Network.Verify_Hook,
	"", --8
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


--[[
	Payload 002 - aka communication payload.
	allows g-AC scripts to securely contact the server without anyone attempting to detour functions.
]]
gAC.Network.Payload_002 = [[--]] .. gAC.Encoder.stringrandom(_math_Round(_math_random(15, 20))) .. [[

local
_,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q=math.ceil,net.Start,net.WriteData,net.WriteUInt,string.sub,timer.Simple,tonumber,util.CRC,util.Compress,net.SendToServer,1,2,3,4,6,32,32765,{...}local
function
gAC_Send(_,d)d=h(d)a(q[j])c(f(g(_..q[l])),o)b(d,#d)i()end
local
function
gAC_Stream(m,s,t)local
u=h(s)local
v=#u
t=t==nil&&p||t
local
w=_(v/t)if
w==j
then
gAC_Send(m,s)return
end
local
s=_G[q[k] ]for
v=j,w
do
local
x,y
if
v==j
then
x=v
y=t
elseif
v>j&&v~=w
then
x=(v-j)*t+j
y=x+t-j
elseif
v>j&&v==w
then
x=(v-j)*t+j
y=len
end
local
z=d(u,x,y)if
v<w&&v>j
then
z="[GAC.STREAM-"..s.."]"..z
else
if
v==j
then
z="[GAC.STREAM_START-"..s.."]"..z
end
if
v==w
then
z=z.."[GAC.STREAM_END-"..s.."]"end
end
e(v/n,function()a(q[j])c(f(g(m..q[l])),o)b(z,#z)i()end)end
_G[q[k] ]=s+j
end
local
function
gAC_AddReceiver(_,a)_G[q[m] ][f(g(_..q[l]))]=a
end
]]

--Rest here is stated at the 1st line of this code.

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
	gAC.DBGPrint("Added network channel " .. channelName .. " - " .. channelId)
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

gAC.Network.AST = {}

function gAC.Network:HandleMessage (bitCount, ply)
	gAC.Network.ReceiveCount = gAC.Network.ReceiveCount + 1
	
	local channelId = _net_ReadUInt (32)
	local handler   = gAC.Network.Handlers[channelId]
	if not handler then return end
	
	local data = _net_ReadData(bitCount / 8 - 4)
	local ID64 = ply:SteamID64()

    if _string_match(data,"^%[GAC%.STREAM%-%d+%]") then
        local ID = _string_match(data,"[%[GAC%.STREAM%-](%d+)[%]]")
		local AST = gAC.Network.AST
        if AST[ID64] ~= nil && AST[ID64][ID] ~= nil then
            AST[ID64][ID] = AST[ID64][ID] .. _string_gsub(data,"^%[GAC%.STREAM%-%d+%]","") 
        end
    elseif _string_match(data,"^%[GAC%.STREAM_START%-%d+%]") or string.match(data,"%[GAC%.STREAM_END%-%d+%]$") then
        if _string_match(data,"^%[GAC%.STREAM_START%-%d+%]") then
            local ID = _string_match(data,"[%[GAC%.STREAM_START%-](%d+)[%]]")
			local AST = gAC.Network.AST
			if !AST[ID64] then
				AST[ID64] = {}
			end
            AST[ID64][ID] = _string_gsub(data,"^%[GAC%.STREAM_START%-%d+%]","") 
        end
        if _string_match(data,"%[GAC%.STREAM_END%-%d+%]$") then
            local ID = _string_match(data,"[%[GAC%.STREAM_END%-](%d+)[%]]")
			local AST = gAC.Network.AST
            if AST[ID64] ~= nil && AST[ID64][ID] ~= nil then
				AST[ID64][ID] = AST[ID64][ID] .. _string_gsub(data,"%[GAC%.STREAM_END%-%d+%]$","") 
                handler(channelId, _util_Decompress(AST[ID64][ID]), ply)
                AST[ID64][ID] = nil
            end
        end
    else
		handler(channelId, _util_Decompress(data), ply)
    end
end
function gAC.Network:Send (channelName, data, player, israw)
	if !israw then data = _util_Compress(data) end
	local channelId = gAC.Network:GetChannelId (channelName) 
	_net_Start(gAC.Network.GlobalChannel)
		_net_WriteUInt (channelId, 32)
		_net_WriteData (data, #data)
		gAC.DBGPrint("Sent data to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
	_net_Send(player)
end

gAC.Network.STREAMID = 1
function gAC.Network:Stream (channelName, data, player, split)
	local channelId = gAC.Network:GetChannelId (channelName)
	local data_size = #_util_Compress(data)
	split = (split == nil and 32765 or split)
	local parts = _math_ceil( data_size / split )

	if parts == 1 then
		gAC.Network:Send (channelName, data, player)
		return
	end
	data = _util_Compress(data)
	gAC:DBGPrint ("Beginning Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
	local Debug_DATA = 0

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
			max = len
		end
		local data = _string_sub( data, min, max )
		if i < parts && i > 1 then
			data = "[GAC.STREAM-" .. gAC.Network.STREAMID .. "]" .. data
		else
			if i == 1 then
				data = "[GAC.STREAM_START-" .. gAC.Network.STREAMID .. "]" .. data
			end
			if i == parts then
				data = data .. "[GAC.STREAM_END-" .. gAC.Network.STREAMID .. "]"
			end
		end

		_timer_Simple(i/6, function()
			if !_IsValid(player) then return end
			_net_Start(gAC.Network.GlobalChannel)
				_net_WriteUInt (channelId, 32)
				_net_WriteData (data, #data)
				if gAC.Debug then
					Debug_DATA = Debug_DATA + _net_BytesWritten()
				end
			_net_Send(player)
			if gAC.Debug && i == parts then
				gAC:DBGPrint ("Finished Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
			end
		end)
	end
	gAC.Network.STREAMID = gAC.Network.STREAMID + 1
end

function gAC.Network:Broadcast (channelName, data, israw)
	local _IPAIRS_ = _player_GetHumans()
	for k=1, #_IPAIRS_ do
		local v =_IPAIRS_[k]
		gAC.Network:Send (channelName, data, v, israw)
	end
end

function gAC.Network:SendPayload (data, player)
	data = gAC.Network.Payload_002 .. data
	gAC.Network:Send ("LoadPayload", data, player)
end

function gAC.Network:BroadcastPayload (data)
	data = gAC.Network.Payload_002 .. data
	gAC.Network:Broadcast ("LoadPayload", data)
end

function gAC.Network:StreamPayload (data, player, split)
	data = gAC.Network.Payload_002 .. data
	gAC.Network:Stream ("LoadPayload", data, player, split)
end

_hook_Add("PlayerInitialSpawn", "gAC.PayLoad_001", function(ply)
	if ply:IsBot() then return end
	gAC.DBGPrint(ply:Nick () .. " (" .. ply:SteamID () .. ") has spawned")
	if gAC.config.JOIN_VERIFY then
		_timer_Simple(gAC.config.JOIN_VERIFY_TIMELIMIT, function()
			if _IsValid(ply) && ply.gAC_ClientLoaded ~= true && gAC.config.JOIN_VERIFY then
				gAC.AddDetection( ply, "Join verification failure [Code 119]", gAC.config.JOIN_VERIFY_PUNISHMENT, -1 )
			end
		end)
	end
end)

_hook_Add("PlayerDisconnected", "gAC.UnloadPlayer", function(ply)
	gAC.Network.AST[ply:SteamID64()] = nil
end)

_net_Receive("g-AC_nonofurgoddamnbusiness", function(_, ply)
	if ply.gAC_ClientLoaded then return end
	ply.gAC_ClientLoaded = true
	_net_Start("g-AC_nonofurgoddamnbusiness")
	_net_WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
	_net_Send(ply)
	gAC.DBGPrint("Sent PayLoad_001 to " .. ply:Nick () .. " (" .. ply:SteamID () .. ")")
	ply.gAC_Verifiying = true
	if gAC.config.PAYLOAD_VERIFY then
		_timer_Simple(gAC.config.PAYLOAD_VERIFY_TIMELIMIT, function()
			if _IsValid(ply) && ply.gAC_Verifiying == true && gAC.config.PAYLOAD_VERIFY then
				gAC.AddDetection( ply, "Payload verification failure [Code 116]", gAC.config.PAYLOAD_VERIFY_PUNISHMENT, -1 )
			end
		end)
	end
end)

--[[
	Sometimes i feel like the whole community just needs a push in the right direction.
	Meth tried too... my god, block the network name... these so called 'meth developers' make me want to puke.
	Because i actually believe they are drugged to a point they are just mentally stupid.
]]
gAC.Network:AddReceiver(
    "g-AC_PayloadVerification",
    function(_, data, plr)
        plr.gAC_Verifiying = nil
		gAC.DBGPrint(plr:Nick() .. " Payload Verified")
		_hook_Run("gAC.ClientLoaded", plr)
    end
)


gAC.DBGPrint("Network ID: " .. gAC.Network.GlobalChannel)
gAC.DBGPrint("CRC Channel Scrammbler ID: " .. gAC.Network.Channel_Rand)
gAC.DBGPrint("CRC Channel Handler ID: " .. gAC.Network.Channel_Glob)
_hook_Run("gAC.Network.Loaded")