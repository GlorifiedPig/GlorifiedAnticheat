local _AddCSLuaFile = AddCSLuaFile
local _file_Exists = file.Exists
local _file_Find = file.Find
local _hook_Add = hook.Add
local _hook_Run = hook.Run
local _include = include
local _print = print

--[[
    Hey nice job looking into the autorun file,
    hopefully it has enough to satisfy your eyes :)

    Hello methamphetamine developers,
    You know that thing you called methamphetamine for a good time?
    Well you know, you shouldn't have told Friendly to fix his
    file stealer. Because guess what, your shit got leaked due to the patch
    and not just g-AC's client files. So basically you played yourself,
    dumb fucks. Maybe stop using Odium's loader for your shit,
    i have never seen such brain dead people in my entire career at gAC.

    Hi FFF,
    i'd like to congratulate you on your creation of cobalt
    and the ass kicking you pulled on wolfie when he got salty.
    Looking forward to that revamp of cobalt, we will be waiting :)
]]


gAC = gAC or {
    config = {},
    storage = {},

    IDENTIFIER = "g-AC",
    NICE_NAME = "g-AC",
    Debug = true
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
            if SERVER then _AddCSLuaFile( filename ) end
            _include( filename )
        elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
            _include( filename )
        elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
            if SERVER then _AddCSLuaFile( filename )
            else _include( filename ) end
        end
    end

    function frile.includeFolder( currentFolder, ignoreFilesInFolder, ignoreFoldersInFolder )
        if _file_Exists( currentFolder .. "sh_frile.lua", "LUA" ) then
            frile.includeFile( currentFolder .. "sh_frile.lua" )

            return
        end

        local files, folders = _file_Find( currentFolder .. "*", "LUA" )

        if not ignoreFilesInFolder then
            for _=1, #files   do
            	local File = files[_]
                frile.includeFile( currentFolder .. File )
            end
        end

        if not ignoreFoldersInFolder then
            for _=1, #folders   do
            	local folder = folders[_]
                frile.includeFolder( currentFolder .. folder .. "/" )
            end
        end
    end
end

function gAC.Print(txt)
    _print(gAC.NICE_NAME .. " > " .. txt)
end

function gAC.DBGPrint(txt)
    if !gAC.Debug then return end
    _print(gAC.NICE_NAME .. " [DBG] > " .. txt)
end

-- Do not adjust the load order. You must first load the libraries, followed by the module and last the languages.
frile.includeFolder( "glorifiedanticheat/", false, true )

if SERVER then
    _hook_Add("gAC.Network.Loaded", "gAC.LoadFiles", function()
        frile.includeFile( "gacnetwork/sv_receivers.lua", frile.STATE_SERVER )
        function frile.includeFile( filename, state )
            if state == frile.STATE_SHARED or filename:find( "sh_" ) then
                gAC.AddQuery( filename )
                _include( filename )
            elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
                _include( filename )
            elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
                gAC.AddQuery( filename )
            end
        end
        frile.includeFolder( "glorifiedanticheat/modules/detectionsys" )
        _hook_Run("gAC.IncludesLoaded")
    end)
end

if SERVER then
    frile.includeFile( "gacstorage/sv_gac_init.lua", frile.STATE_SERVER )
    frile.includeFile( "gacnetwork/sv_query.lua", frile.STATE_SERVER )
    function frile.includeFile( filename, state )
        if state == frile.STATE_SHARED or filename:find( "sh_" ) then
            gAC.AddQuery( filename )
            _include( filename )
        elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
            _include( filename )
        elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
            gAC.AddQuery( filename )
        end
    end
    frile.includeFolder( "glorifiedanticheat/modules/" )
    function frile.includeFile( filename, state )
        if state == frile.STATE_SHARED or filename:find( "sh_" ) then
            if SERVER then _AddCSLuaFile( filename ) end
            _include( filename )
        elseif state == frile.STATE_SERVER or SERVER and filename:find( "sv_" ) then
            _include( filename )
        elseif state == frile.STATE_CLIENT or filename:find( "cl_" ) then
            if SERVER then _AddCSLuaFile( filename ) end
        end
    end
    _hook_Run("gAC.Init")
    frile.includeFile( "gacnetwork/sv_networking.lua", frile.STATE_SERVER )
end

concommand.Add( "gac_version", function( ply, cmd, args )
	print( "g-AC version 1.1.8" )
end )