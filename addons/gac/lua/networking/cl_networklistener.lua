local _G = _G
local Receive = _G["net"]["Receive"]
local RunString = _G["RunString"]
local ReadData = _G["net"]["ReadData"]
local ReadString = _G["net"]["ReadString"]

Receive(gAC.netMsgs.clReceivePayload, function(len, ply)
    RunString(ReadString(), ReadString())
end)