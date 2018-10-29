
gAC = gAC or {
    config = {},

    IDENTIFIER = "gAC",
    NICE_NAME = "gAC"
}

local version = 1

if not frile or frile.VERSION < version then
    frile = {
        VERSION = version,

        STATE_SERVER = 0,
        STATE_CLIENT = 1,
        STATE_SHARED = 2
    }

    function frile.includeFile( filename, state )
        if state == frile.STATE_SHARED or filename:find( "sh_" ) then
            if SERVER then AddCSLuaFile( filename ) end
            include( filename )
        elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
            include( filename )
        elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
            if SERVER then AddCSLuaFile( filename )
            else include( filename ) end
        end
    end

    function frile.includeFolder( currentFolder, ignoreFilesInFolder, ignoreFoldersInFolder )
        if file.Exists( currentFolder .. "sh_frile.lua", "LUA" ) then
            frile.includeFile( currentFolder .. "sh_frile.lua" )

            return
        end

        local files, folders = file.Find( currentFolder .. "*", "LUA" )

        if not ignoreFilesInFolder then
            for _, File in ipairs( files ) do
                frile.includeFile( currentFolder .. File )
            end
        end

        if not ignoreFoldersInFolder then
            for _, folder in ipairs( folders ) do
                frile.includeFolder( currentFolder .. folder .. "/" )
            end
        end
    end
end

-- Do not adjust the load order. You must first load the libraries, followed by the module and last the languages.
frile.includeFolder( "glorifiedanticheat/", false, true )
frile.includeFolder( "glorifiedanticheat/modules/detectionsys" )
frile.includeFolder( "glorifiedanticheat/modules" )