local _isbool = isbool
local _isnumber = isnumber
local _istable = istable
local _pairs = pairs
local _type = type
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON

local function SendInfo()
    gAC_Send("g-AC_ACVerify", "")
end

gAC_AddReceiver("g-AC_ACVerify", function(data)
    local gAC_CFG = _util_JSONToTable(data)
    if !gAC or !_istable(gAC) then
        SendInfo()
        return
    else
        if !gAC.config or !_istable(gAC.config) then
            SendInfo()
            return
        end
    end
    for k, v in _pairs(gAC_CFG) do
        local CFG = gAC.config[k]
        if CFG == nil then
            SendInfo()
            return
        else
            if _type(CFG) != _type(v) then
                SendInfo()
                return
            else
                if _isbool(v) or _isnumber(v) then
                    if CFG != v then
                        SendInfo()
                        return
                    end
                end
            end
        end
    end
end)