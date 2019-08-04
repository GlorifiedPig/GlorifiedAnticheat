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
    local encode, key_dir, key = '', 0, gAC.Encoder.KeyToFloat(key)
    for i = 1, #str do
		key_dir = key_dir + 1
        encode = encode .. '|' .. ( key[key_dir] % 2 == 0 and _string_reverse( _string_byte(str:sub(i, i)) + key[key_dir] + (#str * #key) ) or _string_byte(str:sub(i, i)) + key[key_dir] + (#str * #key) )
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

gAC.Encoder.Decoder_Func = [[local function ‪‪‪‪‪‪‪(‪‪‪) local ‪‪‪‪,‪‪‪‪‪‪,‪‪‪‪‪‪‪‪‪‪‪‪='',‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30'),#‪['\x73\x74\x72\x69\x6e\x67']['\x45\x78\x70\x6c\x6f\x64\x65']('\x28\x25\x64\x2b\x29',‪‪‪,‪['\x74\x6f\x62\x6f\x6f\x6c'](‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x31')))-‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x31') for ‪‪‪‪‪ in ‪['\x73\x74\x72\x69\x6e\x67']['\x67\x6d\x61\x74\x63\x68'](‪‪‪,'\x7c\x28\x25\x64\x2b\x29') do ‪‪‪‪‪‪=‪‪‪‪‪‪+‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x31') if ]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪] % ‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x32') == ‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30') then ‪‪‪‪=‪‪‪‪..‪['\x73\x74\x72\x69\x6e\x67']['\x63\x68\x61\x72'](‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72'](‪['\x73\x74\x72\x69\x6e\x67']['\x72\x65\x76\x65\x72\x73\x65'](‪‪‪‪‪))-]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪]-(‪‪‪‪‪‪‪‪‪‪‪‪*#]] .. gAC.Encoder.Decoder .. [[)) else ‪‪‪‪=‪‪‪‪..‪['\x73\x74\x72\x69\x6e\x67']['\x63\x68\x61\x72'](‪‪‪‪‪-]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪]-(‪‪‪‪‪‪‪‪‪‪‪‪*#]] .. gAC.Encoder.Decoder .. [[)) end if  ‪‪‪‪‪‪==#]] .. gAC.Encoder.Decoder .. [[ then ‪‪‪‪‪‪=‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30') end end return ‪‪‪‪ end]]

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
gAC.Network.Decoder_Verify = gAC.Encoder.stringrandom(_math_Round(_math_random(9, 14)))
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

local _net_Receive = net.Receive
local _net_Start = net.Start
local _net_WriteUInt = net.WriteUInt
local _net_WriteData = net.WriteData
local _net_ReadUInt = net.ReadUInt
local _net_ReadData = net.ReadData
local _net_SendToServer = net.SendToServer
local _hook_Add = hook.Add
local _hook_Remove = hook.Remove
local _util_Decompress = util.Decompress
local _util_CRC = util.CRC
local _string_match = string.match
local _string_gsub = string.gsub
local _RunString = RunString
local _CompileString = CompileString
local _tonumber = tonumber
local args = {...}
local _1, _2, _3, _4, _5, _6, _7, _8, _32 = 1,2,3,4,5,6,7,8,32
args = args[_1]
_G[args[_6] ] = {}
_G[args[_4] ] = 1
local AST = {}
local function HandleMessage (bit)
	local channelId = _net_ReadUInt (_32)
	local handler   = _G[args[_6] ][channelId]
	if not handler then return end
	local data = _net_ReadData (bit / _8 - _4)
    if _string_match(data,"^%[GAC%.STREAM%-%d+%]") then
        local ID = _string_match(data,"[%[GAC%.STREAM%-](%d+)[%]" .. "]")
        if AST[ID] != nil then
            AST[ID] = AST[ID] .. _string_gsub(data,"^%[GAC%.STREAM%-%d+%]","") 
        end
    elseif _string_match(data,"^%[GAC%.STREAM_START%-%d+%]") or _string_match(data,"%[GAC%.STREAM_END%-%d+%]$") then
        if _string_match(data,"^%[GAC%.STREAM_START%-%d+%]") then
            local ID = _string_match(data,"[%[GAC%.STREAM_START%-](%d+)[%]" .. "]")
            AST[ID] = _string_gsub(data,"^%[GAC%.STREAM_START%-%d+%]","") 
        end
        if _string_match(data,"%[GAC%.STREAM_END%-%d+%]$") then
            local ID = _string_match(data,"[%[GAC%.STREAM_END%-](%d+)[%]" .. "]")
            if AST[ID] != nil then
				AST[ID] = AST[ID] .. _string_gsub(data,"%[GAC%.STREAM_END%-%d+%]$","") 
                handler (channelId, _util_Decompress(AST[ID]))
                AST[ID] = nil
            end
        end
    else
        handler (channelId, _util_Decompress(data))
    end
end
_G[args[_6] ][_tonumber(_util_CRC ("LoadString" .. args[_5]))] = function(ch, data) 
    _RunString(data, args[_8] .. "GAC.LoadString-" .. #data) 
end
_G[args[_6] ][_tonumber(_util_CRC ("LoadPayload" .. args[_5]))] = function(ch, data)
    local func = _CompileString(data, args[_8] .. "GAC.LoadPayload-" .. #data)
    func(args[_3], args[_4], args[_5], args[_6])
end
_net_Receive (args[_3],function(bit) HandleMessage(bit) end)
_hook_Add("Think",args[_7],function()
    _net_Start(args[_3])
    _net_WriteUInt (_tonumber(_util_CRC ("g-AC_PayloadVerification" .. args[_5])), _32)
    _net_WriteData ("", #"")
    _net_SendToServer()
    _hook_Remove("Think",args[_7])
end)]]

local TBL = {
	--Payload
	Payload_001,
	"\rGAC.PayLoad_001",
	gAC.Network.GlobalChannel,
	gAC.Network.GlobalAST,
	gAC.Network.Channel_Rand,
	gAC.Network.Channel_Glob,
	gAC.Network.Verify_Hook,
	"\r", --8
	--GAC decoder
	gAC.Network.Decoder_VarName,
	_util_TableToJSON(gAC.Encoder.KeyToFloat(gAC.Network.Global_Decoder)),
	gAC.Network.Decoder_Verify,
	gAC.Network.Decoder_Get,
	gAC.Network.Decoder_Undo --13
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

local _math_ceil, _net_Start, _net_WriteData, _net_WriteUInt, _string_sub, _timer_Simple, _tonumber, _util_CRC, _util_Compress, _net_SendToServer = math.ceil, net.Start, net.WriteData, net.WriteUInt, string.sub, timer.Simple, tonumber, util.CRC, util.Compress, net.SendToServer
local _1, _2, _3, _4, _6, _32, _32765 = 1,2,3,4,6,32,32765
local args = {...}
local function gAC_Send(channelName, data)
	data = _util_Compress(data)
	_net_Start(args[_1])
		_net_WriteUInt (_tonumber(_util_CRC (channelName .. args[_3])), _32)
		_net_WriteData (data, #data)
	_net_SendToServer()
end
local function gAC_Stream(channelName, data, split)
    local compress_data = _util_Compress(data)
    local compress_size = #compress_data
    split = (split == nil and _32765 or split)
    local parts = _math_ceil( compress_size / split )
	if parts == _1 then
		gAC_Send(channelName, data)
		return
	end
    local ID = _G[args[_2] ]
	for i=_1, parts do
		local min, max
		if i == _1 then
			min = i
			max = split
		elseif i > _1 and i ~= parts then
			min = ( i - _1 ) * split + _1
			max = min + split - _1
		elseif i > _1 and i == parts then
			min = ( i - _1 ) * split + _1
			max = len
		end
		local data = _string_sub( compress_data, min, max )
		if i < parts && i > _1 then
			data = "[GAC.STREAM-" .. ID .. "]" .. data
		else
			if i == _1 then
				data = "[GAC.STREAM_START-" .. ID .. "]" .. data
			end
			if i == parts then
				data = data .. "[GAC.STREAM_END-" .. ID .. "]"
			end
		end
		_timer_Simple(i/_6, function()
			_net_Start(args[_1])
				_net_WriteUInt (_tonumber(_util_CRC (channelName .. args[_3])), _32)
				_net_WriteData (data, #data)
			_net_SendToServer()
		end)
	end
    _G[args[_2] ] = ID + _1
end
local function gAC_AddReceiver (channelName, handler)
	_G[args[_4] ][_tonumber(_util_CRC (channelName .. args[_3]))] = handler
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