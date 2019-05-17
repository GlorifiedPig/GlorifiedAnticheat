--[[
    Hey nice job looking into the autorun file,
    let's see if you can prove to me you are worthy of getting gAC unobfuscated.
    Innovation is key to improvement.

    Hello methamphetamine developers!
    If you are the devs for methamphetamine, can you stop boasting about your cheat.
    We already spanked your buyers twice, do you want me to make more detections?
    "Drug cheat is best" yea bud, sure, maybe double check your code first before bragging?

    Thumbs up to citizen for actually making detections challenging the first time unlike meth's autistic developers.
]]

gAC = gAC or {
    config = {},
    storage = {},

    IDENTIFIER = "g-AC",
    NICE_NAME = "g-AC",
    Debug = false
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

function gAC.Print(txt)
    print(gAC.NICE_NAME .. " > " .. txt)
end

function gAC.DBGPrint(txt)
    if !gAC.Debug then return end
    print(gAC.NICE_NAME .. " [DBG] > " .. txt)
end

-- Do not adjust the load order. You must first load the libraries, followed by the module and last the languages.
frile.includeFolder( "glorifiedanticheat/", false, true )
if SERVER then
    frile.includeFile( "gacstorage/sv_gac_init.lua", 0 )
end
frile.includeFolder( "gacnetwork/", false, true )
frile.includeFolder( "glorifiedanticheat/modules/detectionsys" )
if SERVER then
    function frile.includeFile( filename, state )
        if state == frile.STATE_SHARED or filename:find( "sh_" ) then
            gAC.AddQuery( filename )
            include( filename )
        elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
            include( filename )
        elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
            gAC.AddQuery( filename )
        end
    end
    frile.includeFolder( "glorifiedanticheat/modules/" )
    hook.Run("gAC.IncludesLoaded")
end