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
    ['g-AC_fDRM_Networking'] = '48',
    ['g-AC_fDRM_AdminPrivilages'] = '49',
    ['g-AC_fDRM_AltDetection'] = '50',
    ['g-AC_fDRM_AntiAntiAim'] = '51',
    ['g-AC_fDRM_AntiBigPackets'] = '52',
    ['g-AC_fDRM_AntiCitizen'] = '53',
    ['g-AC_fDRM_AntiExternal'] = '54',
    ['g-AC_fDRM_ByteCode'] = '55',
    ['g-AC_fDRM_MethSilent'] = '56',
    ['g-AC_fDRM_MethV4'] = '57',
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
}