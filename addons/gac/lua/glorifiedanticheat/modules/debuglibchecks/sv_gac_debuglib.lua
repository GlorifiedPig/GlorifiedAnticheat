if !gAC.config.DEBUGLIB_CHECK then return end

gAC.FuncstoCheck = {
    [1] = {
        ["func"] = "debug.setlocal",
        ["exists"] = false,
    },
    [2] = {
        ["func"] = "debug.setupvalue",
        ["exists"] = false,
    },
    [3] = {
        ["func"] = "debug.getinfo",
        ["detour"] = 65474,
        ["functype"] = "function: builtin#",
        ["isbytecode"] = false,
    },
    [4] = {
        ["func"] = "jit.util.funcinfo",
        ["detour"] = 65474,
        ["functype"] = "function: builtin#",
        ["isbytecode"] = false,
    },
    [5] = {
        ["func"] = "string.dump",
        ["functype"] = "function: builtin#",
    },
    [6] = {
        ["func"] = "jit.attach",
        ["functype"] = "function: builtin#",
        ["isbytecode"] = false,
    },
}

gAC.FuncstoSend = {} 

local id
for k, v in ipairs(gAC.FuncstoCheck) do
    id = #gAC.FuncstoSend + 1
    gAC.FuncstoSend[id] = {}
    if v["func"] then
        gAC.FuncstoSend[id]["type"] = v["func"]
        if v["exists"] ~= nil then
            gAC.FuncstoSend[id]["check_01"] = true
        end
        if v["detour"] ~= nil then
            gAC.FuncstoSend[id]["check_02"] = true
        end
        if v["detour_func"] ~= nil then
            gAC.FuncstoSend[id]["check_02_ext"] = true
        end
        if v["functype"] ~= nil then
            gAC.FuncstoSend[id]["check_03"] = true
        end
        if v["isbytecode"] ~= nil then
            gAC.FuncstoSend[id]["check_04"] = true
        end
    end
end

gAC.FuncstoSend = util.TableToJSON(gAC.FuncstoSend)

gAC.Network:AddReceiver(
    "g-ACDebugLibResponse",
    function(_, data, plr)
        plr.gAC_DebugLib = nil
        if data == "1" then
            gAC.AddDetection( plr, 
                "Debug Library Check Failed [Code 121:2]", -- Debug check failed (ERRORED)
                gAC.config.DEBUGLIB_FAIL_PUNISHMENT, 
                gAC.config.DEBUGLIB_FAIL_BANTIME 
            )
            return
        end
        local _ = nil
        _, data = pcall(util.JSONToTable, data)
        if !istable(data) then
            gAC.AddDetection( plr, 
                "Debug Library Check Failed [Code 121:3]", -- if it's not a table then wtf?
                gAC.config.DEBUGLIB_FAIL_PUNISHMENT, 
                gAC.config.DEBUGLIB_FAIL_BANTIME 
            )
            return
        end

        if #gAC.FuncstoCheck ~= #data then
            gAC.AddDetection( plr, 
                "Debug Library Anomaly [Code 120]",
                gAC.config.DEBUGLIB_PUNISHMENT, 
                gAC.config.DEBUGLIB_BANTIME 
            )
            return
        end

        for k, v in ipairs(gAC.FuncstoCheck) do
            local check = data[k]
            if !check then
                gAC.AddDetection( plr, 
                    "Debug Library Anomaly [Code 120:00]",
                    gAC.config.DEBUGLIB_PUNISHMENT, 
                    gAC.config.DEBUGLIB_BANTIME 
                )
                return
            end
            if v["exists"] ~= nil then
                if check["check_01"] ~= v["exists"] then
                    gAC.AddDetection( plr, 
                        "Debug Library Anomaly [Code 120:" .. k .. 1 .. "]",
                        gAC.config.DEBUGLIB_PUNISHMENT, 
                        gAC.config.DEBUGLIB_BANTIME 
                    )
                    return
                end
            end
            if v["detour"] ~= nil then
                if check["check_02"] ~= v["detour"] then
                    gAC.AddDetection( plr, 
                        "Debug Library Anomaly [Code 120:" .. k .. 2 .. "]",
                        gAC.config.DEBUGLIB_PUNISHMENT, 
                        gAC.config.DEBUGLIB_BANTIME 
                    )
                    return
                end
            end
            if v["functype"] ~= nil then
                if !isstring(check["check_03"]) or !isstring(check["check_03_ext"]) then
                    gAC.AddDetection( plr, 
                        "Debug Library Anomaly [Code 120:" .. k .. 3 .. "]",
                        gAC.config.DEBUGLIB_PUNISHMENT, 
                        gAC.config.DEBUGLIB_BANTIME 
                    )
                    return
                elseif string.sub( check["check_03"], 1, string.len(v["functype"]) ) ~= v["functype"] or string.sub( check["check_03_ext"], 1, string.len(v["functype"]) ) ~= v["functype"] then
                    gAC.AddDetection( plr, 
                        "Debug Library Anomaly [Code 120:" .. k .. 3 .. "]",
                        gAC.config.DEBUGLIB_PUNISHMENT, 
                        gAC.config.DEBUGLIB_BANTIME 
                    )
                    return
                end
            end
            if v["isbytecode"] ~= nil then
                if check["check_04"] ~= v["isbytecode"] then
                    gAC.AddDetection( plr, 
                        "Debug Library Anomaly [Code 120:" .. k .. 4 .. "]",
                        gAC.config.DEBUGLIB_PUNISHMENT, 
                        gAC.config.DEBUGLIB_BANTIME 
                    )
                    return
                end
            end
        end
    end
)

hook.Add("gAC.CLFilesLoaded", "g-AC_verify_debuglib", function(ply)
    timer.Simple(20, function()
        if !IsValid(ply) then return end
        gAC.Network:Send("g-ACDebugLibResponse", gAC.FuncstoSend, ply)
        ply.gAC_DebugLib = true
        timer.Simple(gAC.config.DEBUGLIB_RESPONSE_TIME, function()
            if !IsValid(ply) then return end
            if !ply.gAC_DebugLib then return end
            gAC.AddDetection( ply, 
                "Debug Library Check Failed [Code 121:1]",
                gAC.config.DEBUGLIB_RESPONSE_PUNISHMENT, 
                gAC.config.DEBUGLIB_RESPONSE_BANTIME 
            )
        end)
    end)
end)