--[[
    Warning to those with lua systems like GM-LUAI
    DO NOT LIVE UPDATE THIS FILE, OR ELSE FILE VERIFICATION WILL FAIL!
]]

--[[ ADMIN PERMISSION SETTINGS ]]--
    gAC.config.ADMIN_MESSAGE_USERGROUPS = { "admin", "superadmin" } -- Set all the usergroups who can see admin messages here.
    gAC.config.ADMIN_MESSAGE_PING = "garrysmod/content_downloaded.wav"
    gAC.config.UNBAN_USERGROUPS = { "admin", "superadmin" } -- Set all the usergroups who can unban players here.
    gAC.config.SYNTAX = "[g-AC] " -- Syntax for messages.
--[[ ADMIN PERMISSION SETTINGS END ]]--

--[[Cheat specific detections]]
    --[[ ANTI METH SETTINGS ]]--
        gAC.config.ANTI_METH = true
        gAC.config.METH_PUNISHMENT = true
        gAC.config.METH_BANTIME = 0
    --[[ ANTI METH SETTINGS END ]]--
--[[end]]

--[[General cheating detections]]
    --[[ Lua Execution ]]
        -- This does something, yet, still in development.
        -- WARNING: AntiLua can be CPU intensive depending on how it is configured.
        -- I've tried my best to make this as minimal as possible to reserve resources for the server.
        -- Only use this if your server has enough resources to spare.
        gAC.config.AntiLua_CHECK = false

        -- Please read sv-config for more info on this config.
        gAC.config.AntiLua_IgnoreBoot = true
    --[[ Lua Execution End]]

    --[[ ANTI Engine Prediction SETTINGS ]]--
        gAC.config.ANTI_ENGINEPRED_CHECKS = true -- Set to 'true' if you want to check for engine predictions (used on aimbots).

        gAC.config.ANTI_ENGINEPRED_PUNISHMENT = true -- Set to 'true' if you want using engine predictions to be punishable.
        gAC.config.ANTI_ENGINEPRED_BANTIME = -1 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ ANTI Engine Prediction END ]]--

    --[[ ANTI No Recoil SETTINGS ]]--
        -- WARNING, This detection modules was not fully tested yet!
        gAC.config.ANTI_NORECOIL_CHECKS = false -- Set to 'true' if you want to check for no recoil (used on aimbots/etc).

        gAC.config.ANTI_NORECOIL_PUNISHMENT = true -- Set to 'true' if you want using no recoil to be punishable.
        gAC.config.ANTI_NORECOIL_BANTIME = -1 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ ANTI No Recoil END ]]--

    --[[ ILLEGAL CONCOMMAND SETTINGS ]]--
        gAC.config.ILLEGAL_CONCOMMAND_CHECKS = true -- Set to 'true' if you want to check for illegal console commands.

        gAC.config.ILLEGAL_CONCOMMAND_PUNISHMENT = true -- Set to 'true' if you want using illegal concommands to be punishable.
        gAC.config.ILLEGAL_CONCOMMAND_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ ILLEGAL CONCOMMAND SETTINGS END ]]--
--[[end]]