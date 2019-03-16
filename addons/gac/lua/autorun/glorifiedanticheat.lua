--[[
    So lately there was some sketchy people joining our servers
    and you know what, turns out they where all file stealing cunts.
    So consider this your consequence.

    Also did i forget to mention all files are now server-side, now can you fuck off
    and stop trying to steal my shit, honestly stop being spoon feed with code.
    - directed to CH & Meth

    Note to gAC dev's & contributors, remember to obfausticate the following,
    !DO NOT USE RUNSTRING AS A DECODER IN OBFAUSTICATIONS!
    cl_receivers.lua
    cl_gac_anti_meth.lua
    cl_verify.lua
    cl_gac_antirenderhack.lua
    cl_gac_concommand_abuse.lua
    if not i can obc them with my obfausticator.
    
    Also fDRM,
    sv_uniquepdata.lua
    sv_gac_anticitizen.lua

    And lastly be sure to study every line of change i did.
    Use this to further enhance the anti-cheat without me.
    - NiceCream, your friendly neighborhood developer
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