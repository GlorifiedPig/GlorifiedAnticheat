
if gAC.storage.Type == "mysql" then
    if (system.IsWindows() and file.Exists("lua/bin/gmsv_mysqloo_win32.dll", "MOD")) or (system.IsLinux() and file.Exists("lua/bin/gmsv_mysqloo_linux.dll", "MOD")) then
        include("gac_mysqloo.lua")
        gAC.Print("Using mysqloo")
    elseif (system.IsWindows() and file.Exists("lua/bin/gmsv_tmysql4_win32.dll", "MOD")) or (system.IsLinux() and file.Exists("lua/bin/gmsv_tmysql4_linux.dll", "MOD")) then
        include("gac_tmysql.lua")
        gAC.Print("Using tmysql")
    else
        include("gac_sqlite.lua")
        gAC.Print("modules tmysql/mysqloo not found, resorting to SQLite")
    end
elseif gAC.storage.Type == "sqlite" then
    include("gac_sqlite.lua")
	gAC.Print("Established sqlite database")
else
    include("gac_flatfile.lua")
	gAC.Print("Established flatfile system")
end