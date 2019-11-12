--[[
    Hai, NiceCream here again.
    Just some recommendations i want to point out.
    I suggest keeping all 'EXTERNAL CHECKS' to kick only
    noticed some false bans before but that might be due to a de-syncroization for some people.
    
    Always keep meth detection on!
    These guys even with other detections enabled will always try to do anything to ruin shit!

    Also a warning to those with lua systems like GM-LUAI
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
        -- WARNING: AntiLua has been considered intensive on cpu resources.
        -- Only use this if your server has enough resources to spare.
        gAC.config.AntiLua_CHECK = false

        -- Ignores code that was initialized from the server.
        -- Things like code ran from autorun and etc, but still checks RunString and unauthorized execution.
        -- WARNING, Code ran from compilers will not be logged, therefore any code ran inside the compiler after boot will cause a detection!
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

--[[ SOURCE CRASHER SETTINGS ]]-- WARNING: Due to some addons spamming commands this will now likely be removed in the future!
    gAC.config.ENABLE_SOURCECRASHER_CHECKS = false -- Set to 'true' to enable sourcecrasher checks.

    gAC.config.SOURCECRASHER_PUNISHMENT = true -- Set to 'true' if you wish to punish players for using sourcecrasher.
    gAC.config.SOURCECRASHER_PUNSIHMENT_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ SOURCE CRASHER SETTINGS END ]]--
