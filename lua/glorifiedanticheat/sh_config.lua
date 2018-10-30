
--[[ MODULE CONFIGURATION ]]--
    --[[ ADMIN PERMISSION SETTINGS ]]--
    gAC.config.ADMIN_MESSAGE_USERGROUPS = { "admin", "superadmin" }
    gAC.config.UNBAN_USERGROUPS = { "admin", "superadmin" }

    --[[ CVAR MANIPULATION SETTINGS ]]
    gAC.config.ALLOWCSLUA_CHECKS = true

    gAC.config.SVCHEATS_CHECKS = true

    gAC.config.CVARMANIP_PUNISHMENT = true
    gAC.config.CVARMANIP_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    --[[ GENERAL MODULE SETTINGS ]]--
    gAC.config.BHOP_CHECKS = true
    gAC.config.SPEEDHACK_CHECKS = true