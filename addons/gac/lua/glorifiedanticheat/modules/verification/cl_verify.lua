local function SendInfo()
    gAC_Send("g-AC_Detections", util.TableToJSON({
        "Integrity check failure [Code 117]", 
        gAC.config.INTEGRITY_CHECKS_PUNISHMENT, 
        gAC.config.INTEGRITY_CHECKS_BANTIME
    }))
end

gAC_AddReceiver("g-AC_ACVerify", function(_, data)
    local gAC_CFG = util.JSONToTable(data)
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