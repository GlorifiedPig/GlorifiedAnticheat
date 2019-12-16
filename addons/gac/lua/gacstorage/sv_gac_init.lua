local _file_Exists = file.Exists
local _include = include
local _IsValid = IsValid
local _concommand_Add = concommand.Add


if gAC.storage.Type == "mysql" then
    if (system.IsWindows() and _file_Exists("lua/bin/gmsv_mysqloo_win32.dll", "MOD")) or (system.IsLinux() and file.Exists("lua/bin/gmsv_mysqloo_linux.dll", "MOD")) then
        _include("gac_mysqloo.lua")
        gAC.Print("Using mysqloo")
    elseif (system.IsWindows() and _file_Exists("lua/bin/gmsv_tmysql4_win32.dll", "MOD")) or (system.IsLinux() and file.Exists("lua/bin/gmsv_tmysql4_linux.dll", "MOD")) then
        _include("gac_tmysql.lua")
        gAC.Print("Using tmysql")
    else
        _include("gac_sqlite.lua")
        gAC.Print("modules tmysql/mysqloo not found, resorting to SQLite")
    end
elseif gAC.storage.Type == "sqlite" then
    _include("gac_sqlite.lua")
	gAC.Print("Established sqlite database")
else
    _include("gac_flatfile.lua")
	gAC.Print("Established flatfile system")
end