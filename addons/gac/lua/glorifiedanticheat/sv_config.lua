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

--Only for mysql
gAC.storage.hostname = "127.0.0.1"
gAC.storage.username = "root"
gAC.storage.password = "root"
gAC.storage.database = "gac"
gAC.storage.port = 3306

gAC.fDRM_LoadIndexes = {
    ['g-AC_fDRM_Networking'] = '-1',
    ['g-AC_fDRM_AdminPrivilages'] = '-1',
    ['g-AC_fDRM_AltDetection'] = '-1',
    ['g-AC_fDRM_AntiAntiAim'] = '-1',
    ['g-AC_fDRM_AntiBigPackets'] = '-1',
    ['g-AC_fDRM_AntiCitizen'] = '-1',
    ['g-AC_fDRM_AntiExternal'] = '-1',
    ['g-AC_fDRM_ByteCode'] = '-1',
    ['g-AC_fDRM_MethSilent'] = '-1',
    ['g-AC_fDRM_MethV4'] = '-1',
    ['g-AC_fDRM_AntiNoSpread'] = '-1',
    ['g-AC_fDRM_AntiRenderHack'] = '-1',
    ['g-AC_fDRM_BanSys'] = '-1',
    ['g-AC_fDRM_ConCommand_Abuse'] = '-1',
    ['g-AC_fDRM_CvarManip'] = '-1',
    ['g-AC_fDRM_DebugLib'] = '-1',
    ['g-AC_fDRM_DetectionSys'] = '-1',
    ['g-AC_fDRM_FamilyShareCheck'] = '-1',
    ['g-AC_fDRM_KeyBindings'] = '-1',
    ['g-AC_fDRM_Notifications'] = '-1',
    ['g-AC_fDRM_Verify'] = '-1',
    ['g-AC_fDRM_VPNChecker'] = '-1'
}