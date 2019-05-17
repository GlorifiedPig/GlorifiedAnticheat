--[[
	GM-LUAI Networking
	Preventing fucking nutheads from MPGH from stealing your shit.

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

gAC.Encoder.Decoder = string.rep(gAC.Encoder.Unicode_String,8)

--[[
	String Randomizer
	Generate randomize string including a Unicode character
]]

gAC.Encoder.Existing_String = {}
function gAC.Encoder.stringrandom(length, norm)
	local str = "‪"
	for i = 1, length do
		if norm then
			str = str .. string.char(math.Round(math.random(97, 122)))
		elseif math.Round(math.random(1, 2)) == 2 then
			str = str .. string.char(math.Round(math.random(97, 122)))
		else
			str = str .. gAC.Encoder.Unicode_String
		end
	end
	if gAC.Encoder.Existing_String[str] then
		return gAC.Encoder.stringrandom(length, norm)
	end
	gAC.Encoder.Existing_String[str] = true
	return str
end

--[[
	Key String to Key Float
	Converts a table key into a table of values for encoders/decoders
]]

function gAC.Encoder.KeyToFloat(s)
	local z = {}
	for i = 1, #s do
		local key = string.Explode("", s[i])
		z[i] = 0
		for v = 1, #key do 
			z[i] = z[i] + string.byte(key[v])
		end 
	end
    return z
end

--[[
	Encoder
	General purpose of encoding string into unreadable format.
	Just cause someone tried to look into my creations.
]]

function gAC.Encoder.Encode(str, key)
    local encode, byte, key_dir, key = '', '', 0, gAC.Encoder.KeyToFloat(key)
    for i = 1, #str do
		key_dir = key_dir + 1
        encode = encode .. '|' .. ( key[key_dir] % 2 == 0 and string.reverse( string.byte(str:sub(i, i)) + key[key_dir] ) or string.byte(str:sub(i, i)) + key[key_dir] )
		if key_dir == #key then
			key_dir = 0
		end
    end
    for i = 1, #encode do
        byte = byte .. '\\x' .. string.format('%02X', string.byte(encode:sub(i, i)))
    end
    return byte
end

--[[
	Decoder function
	Used on the client-side realm, simply decodes string into readable format for lua to use.
]]

gAC.Encoder.Decoder_Func = [[local function ‪‪‪‪‪‪‪(‪‪‪) local ‪‪‪‪,‪‪‪‪‪‪='',‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30') for ‪‪‪‪‪ in ‪['\x73\x74\x72\x69\x6e\x67']['\x67\x6d\x61\x74\x63\x68'](‪‪‪,'\x7c\x28\x25\x64\x2b\x29') do ‪‪‪‪‪‪=‪‪‪‪‪‪+‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x31') if ]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪] % ‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x32') == ‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30') then ‪‪‪‪=‪‪‪‪..‪['\x73\x74\x72\x69\x6e\x67']['\x63\x68\x61\x72'](‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72'](‪['\x73\x74\x72\x69\x6e\x67']['\x72\x65\x76\x65\x72\x73\x65'](‪‪‪‪‪))-]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪]) continue end ‪‪‪‪=‪‪‪‪..‪['\x73\x74\x72\x69\x6e\x67']['\x63\x68\x61\x72'](‪‪‪‪‪-]] .. gAC.Encoder.Decoder .. [[[‪‪‪‪‪‪]) if  ‪‪‪‪‪‪==‪['\x74\x61\x62\x6c\x65']['\x43\x6f\x75\x6e\x74'](]] .. gAC.Encoder.Decoder .. [[) then ‪‪‪‪‪‪=‪['\x74\x6f\x6e\x75\x6d\x62\x65\x72']('\x30') end end return ‪‪‪‪ end]]

if gAC.Network then return end --prevent lua refresh

gAC.Network = gAC.Network or {}
gAC.Network.ReceiveCount = 0
gAC.Network.SendCount    = 0

local ipairs	= ipairs
local type		= type
local net 		= net
local util		= util

--Added __ to prevent conflicts with GM-LUAI's main network < if you even have GM-LUAI >.>
gAC.Network.GlobalChannel = "__" .. gAC.Encoder.stringrandom(math.Round(math.random(10, 19))) .. "__"
gAC.Network.Channel_Rand = gAC.Encoder.stringrandom(math.Round(math.random(5, 9)))
gAC.Network.Channel_Handler = "__" .. gAC.Encoder.stringrandom(math.Round(math.random(9, 15)))
gAC.Network.Reply_Hook = "__" .. gAC.Encoder.stringrandom(math.Round(math.random(5, 10)))

--Global Decoder, NiceCream got pissed
gAC.Network.Global_Decoder = {}
for i=1, math.Round(math.random(6,8)) do
	gAC.Network.Global_Decoder[i] = gAC.Encoder.stringrandom(math.Round(math.random(4, 8)), true)
end
gAC.Network.Decoder_Var = gAC.Encoder.stringrandom(math.Round(math.random(8, 15)))
gAC.Network.Decoder_Verify = gAC.Encoder.stringrandom(math.Round(math.random(9, 14)))
gAC.Network.Table_Decoder = util.Compress(gAC.Network.Decoder_Var .. "%" .. util.TableToJSON(gAC.Encoder.KeyToFloat(gAC.Network.Global_Decoder)) .. "%" .. gAC.Network.Decoder_Verify)

--[[
	Payload 001
	Loads in as the boot payload for g-AC
	determines when to send files & handles network
]]
gAC.Network.Payload_001 = [[--]] .. gAC.Encoder.stringrandom(math.Round(math.random(15, 20))) .. [[

]] .. gAC.Network.Channel_Handler .. [[ = {}
local AST = {}
local _G = _G
local RunString, tonumber = _G["RunString"], _G["tonumber"]
local net = _G["net"]
local string  = _G["string"]
local util = _G["util"]
local function HandleMessage (bit)
	local channelId = net.ReadUInt (32)
	local handler   = ]] .. gAC.Network.Channel_Handler .. [[[channelId]
	if not handler then return end
	local data = net.ReadData (bit / 8 - 4)
    if string.match(data,"^%[GAC%.STREAM%-%d+%]") then
        local ID = string.match(data,"[%[GAC%.STREAM%-](%d+)[%]" .. "]")
        if AST[ID] != nil then
            AST[ID] = AST[ID] .. string.gsub(data,"^%[GAC%.STREAM%-%d+%]","") 
        end
    elseif string.match(data,"^%[GAC%.STREAM_START%-%d+%]") or string.match(data,"%[GAC%.STREAM_END%-%d+%]$") then
        if string.match(data,"^%[GAC%.STREAM_START%-%d+%]") then
            local ID = string.match(data,"[%[GAC%.STREAM_START%-](%d+)[%]" .. "]")
            AST[ID] = string.gsub(data,"^%[GAC%.STREAM_START%-%d+%]","") 
        end
        if string.match(data,"%[GAC%.STREAM_END%-%d+%]$") then
            local ID = string.match(data,"[%[GAC%.STREAM_END%-](%d+)[%]" .. "]")
            if AST[ID] != nil then
				AST[ID] = AST[ID] .. string.gsub(data,"%[GAC%.STREAM_END%-%d+%]$","") 
                handler (channelId, util.Decompress(AST[ID]))
                AST[ID] = nil
            end
        end
    else
        handler (channelId, util.Decompress(data))
    end
end
]] .. gAC.Network.Channel_Handler .. [[[tonumber(util.CRC ("LoadPayload" .. "]] .. gAC.Network.Channel_Rand .. [["))] = function(ch, data) RunString(data, "?]] .. gAC.Network.Decoder_Verify .. [[" .. #data) end
net.Receive ("]] .. gAC.Network.GlobalChannel .. [[",function (bit) HandleMessage (bit) end)
hook.Add("Think", "]] .. gAC.Network.Reply_Hook .. [[", function()
net.Start("]] .. gAC.Network.GlobalChannel .. [[")
net.WriteUInt (tonumber(util.CRC ("g-AC_PayloadVerification" .. "]] .. gAC.Network.Channel_Rand .. [[")), 32)
net.WriteData ("", #"")
net.SendToServer()
hook.Remove("Think", "]] .. gAC.Network.Reply_Hook .. [[")
end)
--]]

--[[
	Payload 002 - aka communication payload.
	allows g-AC scripts to securely contact the server without anyone attempting to detour functions.
]]
gAC.Network.Payload_002 = [[--]] .. gAC.Encoder.stringrandom(math.Round(math.random(15, 20))) .. [[

local _G = _G
local tonumber, type = _G["tonumber"], _G["type"]
local net = _G["net"]
local util = _G["util"]
local function gAC_Send(channelName, data)
	data = util.Compress(data)
	net.Start("]] .. gAC.Network.GlobalChannel .. [[")
		net.WriteUInt (tonumber(util.CRC (channelName .. "]] .. gAC.Network.Channel_Rand .. [[")), 32)
		net.WriteData (data, #data)
	net.SendToServer()
end
local function gAC_AddReceiver (channelName, handler) ]] .. gAC.Network.Channel_Handler .. [[[tonumber(util.CRC (channelName .. "]] .. gAC.Network.Channel_Rand .. [["))] = handler end
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
		local channelId = tonumber(util.CRC (channelName))
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
	
	local channelId = net.ReadUInt (32)
	local handler   = gAC.Network.Handlers[channelId]
	if not handler then return end
	
	local data = net.ReadData(bitCount / 8 - 4)
	handler(channelId, util.Decompress(data), ply)
end

function gAC.Network:Send (channelName, data, player, israw)
	if !israw then data = util.Compress(data) end
	local channelId = gAC.Network:GetChannelId (channelName) 
	net.Start(gAC.Network.GlobalChannel)
		net.WriteUInt (channelId, 32)
		net.WriteData (data, #data)
		gAC.DBGPrint("Sent data to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
	net.Send(player)
end

function gAC.Network:Stream (channelName, data, player, split, israw)
	local channelId = gAC.Network:GetChannelId (channelName)

	local data_size = (israw and data or #util.Compress(data))
	split = (split == nil and 20000 or split)
	local parts = math.ceil( data_size / split )

	if parts == 1 then
		gAC.Network:Send (channelName, data, player, israw)
		return
	end
	if !israw then data = util.Compress(data) end
	gAC.DBGPrint("Beginning Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
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
		local data = string.sub( data, min, max )
		if i < parts && i > 1 then
			data = "[GAC.STREAM-" .. data_size .. "]" .. data
		else
			if i == 1 then
				data = "[GAC.STREAM_START-" .. data_size .. "]" .. data
			end
			if i == parts then
				data = data .. "[GAC.STREAM_END-" .. data_size .. "]"
			end
		end
		--Let's not spam em k? give them time to read the next message.
		timer.Simple(i/8, function()
			net.Start(gAC.Network.GlobalChannel)
				net.WriteUInt (channelId, 32)
				net.WriteData (data, #data)
				gAC.DBGPrint("Sent Network Stream [" .. i .. "/" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
			net.Send(player)
			gAC.DBGPrint("Finished Network Stream [" .. parts .. "] to " .. player:Nick () .. " (" .. player:SteamID () .. ") via " .. gAC.Network.GlobalChannel .. ".")
		end)
	end
end

function gAC.Network:Broadcast (channelName, data, israw)
	for k, v in ipairs(player.GetHumans()) do
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

gAC.Network.Payload_001 = util.Compress(gAC.Network.Payload_001)

hook.Add("PlayerInitialSpawn", "gAC.PayLoad_001", function(ply)
	if ply:IsBot() then return end
	net.Start("g-AC_nonofurgoddamnbusiness")
	net.WriteUInt(#gAC.Network.Table_Decoder, 16)
	net.WriteData(gAC.Network.Table_Decoder, #gAC.Network.Table_Decoder)
	net.WriteUInt(#gAC.Network.Payload_001, 16)
	net.WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
	net.Send(ply)
	gAC.DBGPrint("Sent PayLoad_001 to " .. ply:Nick () .. " (" .. ply:SteamID () .. ")")
	ply.gAC_Verifiying = true
	timer.Simple(180, function()
		if IsValid(ply) && ply.gAC_Verifiying == true then
			gAC.AddDetection( ply, "Payload verification failure [Code 114]", true, -1 )
		end
	end)
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
		hook.Run("gAC.ClientLoaded", plr)
    end
)


gAC.DBGPrint("Network ID: " .. gAC.Network.GlobalChannel)
gAC.DBGPrint("CRC Channel Scrammbler ID: " .. gAC.Network.Channel_Rand)
gAC.DBGPrint("CRC Channel Handler ID: " .. gAC.Network.Channel_Handler)
