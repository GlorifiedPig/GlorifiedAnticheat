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

if gAC.Network then return end --prevent lua refresh

gAC.Network = gAC.Network or {}
gAC.Network.ReceiveCount = 0
gAC.Network.SendCount    = 0

local ipairs	= ipairs
local type		= type
local net 		= net
local util		= util

--makes a unique network string everytime the server starts.

local function stringrandom(length)
	local str = "‪"
	for i = 1, length do
		if math.Round(math.random(1, 2)) == 2 then
			str = str..string.char(math.random(97, 122))
		else
			str = str.."‪" --This is an invisible unicode character, useful in trolling cheaters :)
		end
	end
	return str
end

--Added __ to prevent conflicts with GM-LUAI's main network
gAC.Network.GlobalChannel = "__" .. stringrandom(math.Round(math.random(10, 19))) .. "__"
gAC.Network.Channel_Rand = stringrandom(math.Round(math.random(5, 9)))
gAC.Network.Channel_Handler = "__" .. stringrandom(math.Round(math.random(9, 15)))
gAC.Network.Reply_Hook = "__" .. stringrandom(math.Round(math.random(5, 10)))

--[[
--CL payload
local _G = _G
local RunString = _G["RunString"]
local Receive = _G["net"]["Receive"]
local ReadData = _G["net"]["ReadData"]

Receive("g-AC_nonofurgoddamnbusiness", function(len)
    RunString(ReadData(len), "eatmyassk?")
end)
]]

--AST = Active Streams
--[[
	Remind me to add random \n's to the code, just so that they cannot just detour runstring and read it's contents
	and then determine what the randomization code is.
]]
gAC.Network.Payload_001 = [[--]] .. stringrandom(math.Round(math.random(15, 20))) .. [[

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
]] .. gAC.Network.Channel_Handler .. [[[tonumber(util.CRC ("LoadPayload" .. "]] .. gAC.Network.Channel_Rand .. [["))] = function(ch, data)
	RunString(data, "?]] .. stringrandom(5) .. [[" .. #data)
end
net.Receive ("]] .. gAC.Network.GlobalChannel .. [[",function (bit)
	HandleMessage (bit)
end)
hook.Add("InitPostEntity", "]] .. gAC.Network.Reply_Hook .. [[", function()
	net.Start("]] .. gAC.Network.GlobalChannel .. [[")
	net.WriteUInt (tonumber(util.CRC ("g-AC_PayloadVerification" .. "]] .. gAC.Network.Channel_Rand .. [[")), 32)
	net.WriteData ("", #"")
	net.SendToServer()
	hook.Remove("InitPostEntity", "]] .. gAC.Network.Reply_Hook .. [[")
end)
--]]

gAC.Network.Payload_002 = [[--]] .. stringrandom(math.Round(math.random(15, 20))) .. [[

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
local function gAC_AddReceiver (channelName, handler)
	]] .. gAC.Network.Channel_Handler .. [[[tonumber(util.CRC (channelName .. "]] .. gAC.Network.Channel_Rand .. [["))] = handler
end
]]

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
	net.WriteData(gAC.Network.Payload_001, #gAC.Network.Payload_001)
	net.Send(ply)
	gAC.DBGPrint("Sent PayLoad_001 to " .. ply:Nick () .. " (" .. ply:SteamID () .. ")")
	ply.gAC_Verifiying = true
	timer.Simple(300, function()
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
		hook.Run("gAC.ClientLoaded", plr)
		gAC.DBGPrint(plr:Nick() .. " Payload Verified")
    end
)


gAC.DBGPrint("Network ID: " .. gAC.Network.GlobalChannel)
gAC.DBGPrint("CRC Channel Scrammbler ID: " .. gAC.Network.Channel_Rand)
gAC.DBGPrint("CRC Channel Handler ID: " .. gAC.Network.Channel_Handler)
