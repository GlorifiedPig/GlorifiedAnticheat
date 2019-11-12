local CFG = table.Copy(gAC.config or {}) -- for ignoring SV configs, don't remove
gAC.config = {}



gAC.config.LICENSE = "LICENSE" -- If you didn't receive a license please contact GlorifiedPig.

--[[
    MySQLOO Table Setup, Simply query this into the SQL query and it should auto generate a table.

    DROP TABLE IF EXISTS `gac_detections`;
    CREATE TABLE `gac_detections` (
        `time` bigint(20) COLLATE utf8_unicode_ci NOT NULL,
        `steamid` text COLLATE utf8_unicode_ci NOT NULL,
        `detection` text COLLATE utf8_unicode_ci NOT NULL,
        `index` int(10) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
]]

--Recommend sqlite, Recommend mysql if you have more than one server (You must know basic knowledge of SQL programming).
gAC.storage.Type = "sqlite" -- Types: flatfile, sqlite, mysql

-- MySQL Settings ("mysql" module only)
gAC.storage.hostname = "127.0.0.1"
gAC.storage.username = "root"
gAC.storage.password = "root"
gAC.storage.database = "gac"
gAC.storage.port = 3306

gAC.config.IMMUNE_USERS = { -- Set all user's steamid64 here who are immune to g-AC detections.
    "76561198061230671", -- NiceCream - Remove me if you want.
}

--[[ BAN SYSTEM SETTINGS ]]--
    --[[
        Just because some servers want their ban functions to be unique.
        Like they always say, uniqueness is key.

        Ban Types:
            custom - gAC's custom ban system
            ulx - use the ulx ban system
            d3a - use D3vine's ban system
            serverguard - server-guard's ban system
            custom_func - uses BAN_FUNC to ban users, basically make your own ban type

        Kick Types:
            default - normal gAC kick system
            custom_func - uses KICK_FUNC to kick users, basically make your own kick type
    ]]
    gAC.config.BAN_MESSAGE_SYNTAX = "Cheating/Hacking" -- Syntax for ban messages.

    -- Your ban system must allow access to ban SteamID's
    gAC.config.DELAYEDBANS = false --Delays bans to prevent cheaters from understanding the system
    gAC.config.DELAYEDBANS_TIME = 120 --In seconds, how long to delay the ban

    -- Kick system will only kick those that are online
    gAC.config.DELAYEDKICKS = false --Delays kicks to prevent cheaters from understanding the system
    gAC.config.DELAYEDKICKS_TIME = 60 --In seconds, how long to delay the kick

    -- set to 'custom_func' to use your own custom banning function
    -- set to 'custom' for our custom banning system
    -- set to 'ulx' for ulx, 'serverguard' for ServerGuard, 'd3a' for d3a, 'sam' for SAM
    gAC.config.BAN_TYPE = "ulx"
    gAC.config.BAN_FUNC = function(ply, banlength, code)
        if isstring(ply) then
            -- bans by steamid
        else
            -- bans by player entity
        end
    end -- Only if you want custom ban names & etc.

    gAC.config.KICK_TYPE = "custom_func" -- set to 'default' for normal kick
    gAC.config.KICK_FUNC = function(ply, code) --only to override the kick function!
        if code == "Payload verification failure [Code 116]" or code == "Join verification failure [Code 119]" then
            ply:Kick("Client failed to respond to server in time, rejoin.")
            return
        end
        ply:Kick(gAC.config.BAN_MESSAGE_SYNTAX)
    end
--[[ BAN SYSTEM SETTINGS END ]]--

--[[Anti-Cheat vs Player detections]]
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
--[[end]]

--[[Server related detections]]
    --[[ BACKOOR EXPLOITATION SETTINGS ]]--
        gAC.config.BACKDOOR_NET_EXPLOIT_CHECKS = true -- Whether or not to check for illegal net messages.

        gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT = true -- Set to 'true' if you want using net exploits to be punishable.
        gAC.config.BACKDOOR_EXPLOITATION_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ BACKOOR EXPLOITATION SETTINGS END ]]--
--[[end]]

--[[Cheat specific detections]]
    --[[ ANTI CITIZENHACK SETTINGS ]]--
        gAC.config.ENABLE_CITIZENHACK_CHECKS = true -- Set to 'true' to enable citizenhack checks.

        gAC.config.CITIZENHACK_PUNISHMENT = false -- Set to 'true' if you wish to punish players for using citizenhack.
        gAC.config.CITIZENHACK_PUNSIHMENT_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ ANTI CITIZENHACK SETTINGS END ]]--

    --[[ ANTI BigPackets SETTINGS ]]--
        gAC.config.ANTI_BP = true
        gAC.config.BP_PUNISHMENT = true
        gAC.config.BP_BANTIME = 0
    --[[ ANTI BigPackets SETTINGS END ]]--

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
--[[end]]

--[[General cheating detections]]
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

        -- WARNING, try not to use this! this extremely CPU intensive!
        -- This will auto reload verifications for a certain file on lua refresh.
        gAC.config.AntiLua_LuaRefresh = true
    --[[ Lua Execution End]]

    --[[ ANTI Aim SETTINGS ]]--
        -- WARNING, This detection is untested!
        gAC.config.ANTI_ANTIAIM = false
        gAC.config.ANTIAIM_PUNISHMENT = true
        gAC.config.ANTIAIM_BANTIME = 0
    --[[ ANTI Aim SETTINGS END ]]--

    --[[ ANTI SILENT Aim SETTINGS ]]--
        -- WARNING, This detection is untested!
        gAC.config.ANTI_SILENT = false
        gAC.config.SILENT_PUNISHMENT = true
        gAC.config.SILENT_BANTIME = 0
    --[[ ANTI SILENT Aim SETTINGS END ]]--

    --[[ RENDER HACK SETTINGS ]]--
        gAC.config.RENDER_HACK_CHECKS = true -- Set to 'true' if you want to check for render rewrites.

        gAC.config.RENDER_HACK_PUNISHMENT = true -- Set to 'true' if you want using potential render hacks to be punishable.
        gAC.config.RENDER_HACK_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ RENDER HACK SETTINGS END ]]--

    --[[ CVAR MANIPULATION SETTINGS ]]
        gAC.config.ALLOWCSLUA_CHECKS = true -- Set to 'true' if you wish to check for sv_allowcslua being set to active.
        gAC.config.SVCHEATS_CHECKS = true -- Set to 'true' if you wish to check for sv_cheats being set to active.
        gAC.config.CVARMANIP_PUNISHMENT = true -- Set to 'true' if you want to punish the player for C-var manipulation.
        gAC.config.CVARMANIP_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.
    --[[ CVAR MANIPULATION SETTINGS END ]]

    --[[ GENERAL MODULE SETTINGS ]]--
        gAC.config.ANTI_NOSPREAD_CHECKS = true -- Set to 'true' if you wish for the anti-nospread module to be enabled.
        gAC.config.BHOP_CHECKS = false -- Set to 'true' if you wish for the anti-bhop module to be enabled.
        gAC.config.KEYBIND_CHECKS = false -- Set to 'true' if you wish for suspicious keybindings to be logged.
        gAC.config.DISABLE_BAD_COMMANDS = true -- Set to 'true' if you wish for sv_allowcslua and sv_cheats to be disabled on server startup.
    --[[ GENERAL MODULE SETTINGS END ]]--
--[[end]]

--[[Account related detections]]
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
--[[end]]

-- Prevents integrity checks from going haywire on these configs
gAC.config.INTEGRITY_INGORES = {}

for k, v in pairs(gAC.config) do
    gAC.config.INTEGRITY_INGORES[k] = true
end

table.Merge( gAC.config, CFG )

gAC.fDRM_LoadIndexes = {
    ['g-AC_fDRM_Networking'] = '48',
    ['g-AC_fDRM_AdminPrivilages'] = '49',
    ['g-AC_fDRM_AltDetection'] = '50',
    ['g-AC_fDRM_AntiAntiAim'] = '51',
    ['g-AC_fDRM_AntiBigPackets'] = '52',
    ['g-AC_fDRM_AntiCitizen'] = '53',
    ['g-AC_fDRM_AntiExternal'] = '54',
    ['g-AC_fDRM_ByteCode'] = '55',
    ['g-AC_fDRM_MethSilent'] = '56',
    ['g-AC_fDRM_MethV4'] = '78',
    ['g-AC_fDRM_AntiNoSpread'] = '58',
    ['g-AC_fDRM_AntiRenderHack'] = '59',
    ['g-AC_fDRM_BanSys'] = '60',
    ['g-AC_fDRM_ConCommand_Abuse'] = '61',
    ['g-AC_fDRM_CvarManip'] = '62',
    ['g-AC_fDRM_DebugLib'] = '63',
    ['g-AC_fDRM_FamilyShareCheck'] = '64',
    ['g-AC_fDRM_Notifications'] = '65',
    ['g-AC_fDRM_UniquePData'] = '66',
    ['g-AC_fDRM_Verify'] = '67',
    ['g-AC_fDRM_VPNChecker'] = '68',
    ['g-AC_fDRM_AntiBhop'] = '69',
    ['g-AC_fDRM_AntiNeko'] = '70',
    ['g-AC_fDRM_CPPAimbot'] = '71',
    ['g-AC_fDRM_NetBackDoor'] = '72',
    ['g-AC_fDRM_DetectionSys'] = '73',
    ['g-AC_fDRM_KeyBindings'] = '74',
    ['g-AC_fDRM_AntiLua'] = '76',
}