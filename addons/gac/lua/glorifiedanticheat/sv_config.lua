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

-- Prevents integrity checks from going haywire on these configs
gAC.config.INTEGRITY_INGORES = {
    ['STEAM_API_KEY'] = true,
    ['ENABLE_FAMILY_SHARE_CHECKS'] = true,
    ['FAMILY_SHARE_PUNISHMENT'] = true,
    ['FAMILY_SHARE_BANTIME'] = true,
    ['DELAYEDBANS'] = true,
    ['DELAYEDBANS_TIME'] = true,
    ['DELAYEDKICKS'] = true,
    ['DELAYEDKICKS_TIME'] = true,
    ['BAN_TYPE'] = true,
    ['BAN_FUNC'] = true,
    ['BAN_TYPE'] = true,
    ['KICK_FUNC'] = true,
}