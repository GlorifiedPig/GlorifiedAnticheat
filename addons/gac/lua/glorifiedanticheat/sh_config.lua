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
    gAC.config.BAN_MESSAGE_SYNTAX = "Cheating/Hacking" -- Syntax for ban messages.
--[[ ADMIN PERMISSION SETTINGS END ]]--

--[[ BAN SYSTEM SETTINGS ]]--
    --[[
        Just because some servers want their ban functions to be unique.
        Like they always say, uniqueness is key.
    ]]
    gAC.config.BAN_TYPE = "custom_func" -- Set to 'custom' for the custom banning system, set to 'ulx' to use ulx.
    gAC.config.BAN_FUNC = function(ply, displayReason, banTime)
        local unit = "minute"
        if banTime < 1 then
            unit = "perm"
        end
        --Note 'NameID' is part of D3A & not part of g-AC
        gAC.Print("Banned " .. ply:NameID() .. " for cheating.")
        gAC.Broadcast("Dropped " .. ply:NameID() .. " from the server, account is convicted of cheating.", Color(255,0,0))
        D3A.Bans.BanPlayer(ply:SteamID(), "g-AC", banTime, unit, gAC.config.BAN_MESSAGE_SYNTAX)
    end
    gAC.config.KICK_FUNC = function(ply, displayReason) --only to override the kick function!
        ply:Kick(gAC.config.BAN_MESSAGE_SYNTAX)
    end
--[[ BAN SYSTEM SETTINGS END ]]--

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

--[[ FAMILY SHARING CHECK ]]--
--[[ GUIDE FOR GETTING A STEAM API KEY:
    1. Go to https://steamcommunity.com/dev/apikey
    2. Name the key.
    3. Create the key and paste it below.

    Your key should look something like this: 1369GJ41970G26891B26AGGFAD526B49
]]--
    gAC.config.STEAM_API_KEY = "" -- Steam API key for the family sharing module.

    gAC.config.ENABLE_FAMILY_SHARE_CHECKS = false -- Whether or not to check if the player is using a family shared account.

    gAC.config.FAMILY_SHARE_PUNISHMENT = false -- Set to 'true' if you want using a family shared account to be punishable. 
    gAC.config.FAMILY_SHARE_BANTIME = -1 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ FAMILY SHARING CHECK END ]]--

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

--[[ SOURCE CRASHER SETTINGS ]]--
    gAC.config.ENABLE_SOURCECRASHER_CHECKS = true -- Set to 'true' to enable sourcecrasher checks.

    gAC.config.SOURCECRASHER_PUNISHMENT = true -- Set to 'true' if you wish to punish players for using sourcecrasher.
    gAC.config.SOURCECRASHER_PUNSIHMENT_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
--[[ GENERAL MODULE SETTINGS END ]]--

--[[ ANTI METH ]]--
    gAC.config.ANTI_METH = true
    gAC.config.METH_PUNISHMENT = true
    gAC.config.METH_BANTIME = 0
--[[ ANTI METH END ]]--