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
