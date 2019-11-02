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

--[[ Payload Verification & Integrity Checks ]]

--Checks of gAC was altered by an external source.
gAC.config.INTEGRITY_CHECKS = true
gAC.config.INTEGRITY_CHECKS_PUNISHMENT = true
gAC.config.INTEGRITY_CHECKS_BANTIME = -1

--Checks if the player has successfuly loaded with gAC's payload loader.
--Verification failure means they did not receive the payload in required time.
gAC.config.PAYLOAD_VERIFY = true
gAC.config.PAYLOAD_VERIFY_PUNISHMENT = true
gAC.config.PAYLOAD_VERIFY_TIMELIMIT = 120 --120 seconds to verify or else do an action

--Checks if the player has successfuly loaded into garrysmod.
--Verification failure means they did not receive the payload in required time.
gAC.config.JOIN_VERIFY = true
gAC.config.JOIN_VERIFY_PUNISHMENT = true
gAC.config.JOIN_VERIFY_TIMELIMIT = 360 --360 seconds to verify or else do an action

--[[ Payload Verification & Integrity Checks End]]

--[[ Lua Execution ]]
    --Checks if certain functions in lua has been detoured by an external source or an external source added blacklisted functions.
    --WARNING, this detection modules is outdated and not working, stay disabled!
    gAC.config.DEBUGLIB_CHECK = false
    gAC.config.DEBUGLIB_PUNISHMENT = true
    gAC.config.DEBUGLIB_BANTIME = 0

    gAC.config.DEBUGLIB_FAIL_PUNISHMENT = true
    gAC.config.DEBUGLIB_FAIL_BANTIME = -1

    gAC.config.DEBUGLIB_RESPONSE_TIME = 120
    gAC.config.DEBUGLIB_RESPONSE_PUNISHMENT = true
    gAC.config.DEBUGLIB_RESPONSE_BANTIME = -1

    -- This does something, yet, still in development.
    -- WARNING: AntiLua has been considered intensive on cpu resources.
    -- Only use this if your server has enough resources to spare.
    gAC.config.AntiLua_CHECK = false
    gAC.config.AntiLua_PUNISHMENT = false
    gAC.config.AntiLua_BANTIME = -1

    -- If they try to manipulate the network of anti-lua
    gAC.config.AntiLua_Net_PUNISHMENT = true
    gAC.config.AntiLua_Net_BANTIME = -1

    -- If they did not respond to the server in required time
    gAC.config.AntiLua_Fail_PUNISHMENT = true
    gAC.config.AntiLua_Fail_BANTIME = -1

    -- Uses a stronger method of lua verification, using functions to verify an execution.
    -- However this works at a cost of some CPU usage server-side.
    gAC.config.AntiLua_FunctionVerification = true

    -- Ignores code that was initialized from the server.
    -- Things like code ran from autorun and etc, but still checks RunString and unauthorized execution.
    -- WARNING, Code ran from compilers will not be logged, therefore any code ran inside the compiler after boot will cause a detection!
    gAC.config.AntiLua_IgnoreBoot = true

    -- WARNING, try not to use this! this extremely CPU intensive!
    -- This will auto reload verifications for a certain file on lua refresh.
    gAC.config.AntiLua_LuaRefresh = true
--[[ Lua Execution End]]

--[[ CVAR MANIPULATION SETTINGS ]]
    gAC.config.ALLOWCSLUA_CHECKS = true -- Set to 'true' if you wish to check for sv_allowcslua being set to active.
    gAC.config.SVCHEATS_CHECKS = true -- Set to 'true' if you wish to check for sv_cheats being set to active.

    gAC.config.CVARMANIP_PUNISHMENT = true -- Set to 'true' if you want to punish the player for C-var manipulation.
    gAC.config.CVARMANIP_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    gAC.config.CVARMANIP_RETURN_PUNISHMENT = false -- Recommended for this to be false! It can have false detections. Set to 'true' if you wish to kick the player if the C-var manipulation results haven't returned.
    gAC.config.CVARMANIP_RETURN_JOINTIMER = 60 -- How long after joining to check if results don't return.
--[[ CVAR MANIPULATION SETTINGS END ]]

--[[ BACKOOR EXPLOITATION SETTINGS ]]--
    gAC.config.BACKDOOR_NET_EXPLOIT_CHECKS = true -- Whether or not to check for illegal net messages.

    gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT = true -- Set to 'true' if you want using net exploits to be punishable.
    gAC.config.BACKDOOR_EXPLOITATION_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ BACKOOR EXPLOITATION SETTINGS END ]]--

--[[ ANTI CITIZENHACK SETTINGS ]]--
    gAC.config.ENABLE_CITIZENHACK_CHECKS = true -- Set to 'true' to enable citizenhack checks.

    gAC.config.CITIZENHACK_PUNISHMENT = false -- Set to 'true' if you wish to punish players for using citizenhack.
    gAC.config.CITIZENHACK_PUNSIHMENT_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ ANTI CITIZENHACK SETTINGS END ]]--

--[[ ANTI METH SETTINGS ]]--
    gAC.config.ANTI_METH = true
    gAC.config.METH_PUNISHMENT = true
    gAC.config.METH_BANTIME = 0
--[[ ANTI METH SETTINGS END ]]--

--[[ ANTI BigPackets SETTINGS ]]--
    gAC.config.ANTI_BP = true
    gAC.config.BP_PUNISHMENT = true
    gAC.config.BP_BANTIME = 0
--[[ ANTI BigPackets SETTINGS END ]]--

--[[ ANTI Engine Prediction SETTINGS ]]--
    gAC.config.ANTI_ENGINEPRED_CHECKS = true -- Set to 'true' if you want to check for engine predictions (used on aimbots).

    gAC.config.ANTI_ENGINEPRED_PUNISHMENT = true -- Set to 'true' if you want using engine predictions to be punishable.
    gAC.config.ANTI_ENGINEPRED_BANTIME = -1 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ ANTI Engine Prediction END ]]--

--[[ ANTI Aim SETTINGS ]]--
    -- WARNING, This detection is untested!
    gAC.config.ANTI_ANTIAIM = false
    gAC.config.ANTIAIM_PUNISHMENT = true
    gAC.config.ANTIAIM_BANTIME = 0
--[[ ANTI Aim SETTINGS END ]]--

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

--[[ RENDER HACK SETTINGS ]]--
    gAC.config.RENDER_HACK_CHECKS = true -- Set to 'true' if you want to check for render rewrites.

    gAC.config.RENDER_HACK_PUNISHMENT = true -- Set to 'true' if you want using potential render hacks to be punishable.
    gAC.config.RENDER_HACK_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ RENDER HACK SETTINGS END ]]--

--[[ ALT DETECT SETTINGS ]]--
    gAC.config.ALT_DETECTION_CHECKS = false -- Set to 'true' if you want to check for alts.

    gAC.config.ALT_DETECTION_NOTIFY_ALTS = true -- Set to 'true' if you want to notify all admins about alts.
    gAC.config.ALT_DETECTION_PUNISHMENT = false -- Set to 'true' if you wish to punish players for having alts.
    gAC.config.ALT_DETECTION_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ ALT DETECT SETTINGS END ]]--

--[[ EXTERNAL CHECKS ]]--
    gAC.config.EXTERNAL_LUA_CHECKS = true -- Set to 'true' if you want to check for external checks.

    gAC.config.EXTERNAL_LUA_PUNISHMENT = true -- Set to 'true' if you want using external hacks to be punishable.
    gAC.config.EXTERNAL_LUA_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    gAC.config.EXTERAL_LUA_RETRIVAL_PUNISHMENT = true -- Set to 'true' if you want to enable the external lua cheats heartbeat.
    gAC.config.EXTERAL_LUA_RETRIVAL_BANTIME = -1
--[[ EXTERNAL CHECKS END ]]--

--[[ EXTERNAL CHECKS ]]--
    gAC.config.NEKO_LUA_CHECKS = true -- Set to 'true' if you want to check for neko checks.

    gAC.config.NEKO_LUA_PUNISHMENT = true -- Set to 'true' if you want using neko hacks to be punishable.
    gAC.config.NEKOL_LUA_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    gAC.config.NEKO_LUA_RETRIVAL_PUNISHMENT = true -- Set to 'true' if you want to enable the neko lua cheats heartbeat.
    gAC.config.NEKO_LUA_RETRIVAL_BANTIME = -1
--[[ EXTERNAL CHECKS END ]]--

--[[ GENERAL MODULE SETTINGS ]]--
    gAC.config.BHOP_CHECKS = false -- Set to 'true' if you wish for the anti-bhop module to be enabled.
    gAC.config.ANTI_NOSPREAD_CHECKS = true -- Set to 'true' if you wish for the anti-nospread module to be enabled.
    gAC.config.KEYBIND_CHECKS = false -- Set to 'true' if you wish for suspicious keybindings to be logged.
    gAC.config.DISABLE_BAD_COMMANDS = true -- Set to 'true' if you wish for sv_allowcslua and sv_cheats to be disabled on server startup.
--[[ GENERAL MODULE SETTINGS END ]]--

--[[ SOURCE CRASHER SETTINGS ]]-- WARNING: Due to some addons spamming commands this will now likely be removed in the future!
    gAC.config.ENABLE_SOURCECRASHER_CHECKS = false -- Set to 'true' to enable sourcecrasher checks.

    gAC.config.SOURCECRASHER_PUNISHMENT = true -- Set to 'true' if you wish to punish players for using sourcecrasher.
    gAC.config.SOURCECRASHER_PUNSIHMENT_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ SOURCE CRASHER SETTINGS END ]]--
