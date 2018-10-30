
--[[ MODULE CONFIGURATION ]]--
    --[[ ADMIN PERMISSION SETTINGS ]]--
    gAC.config.ADMIN_MESSAGE_USERGROUPS = { "admin", "superadmin" } -- Set all the usergroups who can see admin messages here.
    gAC.config.UNBAN_USERGROUPS = { "admin", "superadmin" } -- Set all the usergroups who can unban players here.

    --[[ CVAR MANIPULATION SETTINGS ]]
    gAC.config.ALLOWCSLUA_CHECKS = true -- Set to 'true' if you wish to check for sv_allowcslua being set to active.
    gAC.config.SVCHEATS_CHECKS = true -- Set to 'true' if you wish to check for sv_cheats being set to active.

    gAC.config.CVARMANIP_PUNISHMENT = true -- Set to 'true' if you want to punish the player for C-var manipulation.
    gAC.config.CVARMANIP_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    --[[ BACKOOR EXPLOITATION SETTINGS ]]--
    gAC.config.BACKDOOR_NET_EXPLOIT_CHECKS = true -- Whether or not to check for illegal net messages.

    gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT = true -- Set to 'true' if you want using net exploits to be punishable.
    gAC.config.BACKDOOR_EXPLOITATION_BANTIME = 0 -- Set to '0' for permban, '-1' for kick and anything above for ban time in minutes.

    --[[ GENERAL MODULE SETTINGS ]]--
    gAC.config.BHOP_CHECKS = true -- Set to 'true' if you wish for the anti-bhop module to be enabled.
    gAC.config.KEYBIND_CHECKS = true -- Set to 'true' if you wish for suspicious keybindings to be logged.
    gAC.config.DISABLE_BAD_COMMANDS = true -- Set to 'true' if you wish for sv_allowcslua and sv_cheats to be disabled on server startup.