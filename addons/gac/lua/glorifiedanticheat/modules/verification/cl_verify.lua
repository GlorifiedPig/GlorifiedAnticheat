local function SendInfo()
    gAC_Send("g-AC_Detections", util.TableToJSON({
        "Integrity check failure [Code 115]", 
        true, 
        -1
    }))
end

gAC_AddReceiver("g-AC_ACVerify", function(_, gAC_CFG)
    local gAC_CFG = util.JSONToTable(gAC_CFG)
    if !gAC or !istable(gAC) then
        SendInfo()
        return
    else
        if !gAC.config or !istable(gAC.config) then
            SendInfo()
            return
        end
    end
    for k, v in pairs(gAC_CFG) do
        local CFG = gAC.config[k]
        if CFG == nil then
            SendInfo()
            return
        else
            if type(CFG) != type(v) then
                SendInfo()
                return
            else
                if isbool(v) or isnumber(v) then
                    if CFG != v then
                        SendInfo()
                        return
                    end
                end
            end
        end
    end
end)