
if !gAC.config.NEKO_LUA_CHECKS then return end

local function RandStr( l, u )
	local randomString = tostring( string.char( math.random( 97, 122 ) ) )
    local randomLength = math.random( l, u )
    
	for i = 1, randomLength, 1 do
		local i2 = math.random(0, 2)
		
        if( i2 == 0 ) then
            randomString = randomString .. tostring( string.char( math.random( 48, 57 ) ) )
        elseif( i2 == 1 ) then
            randomString = randomString .. tostring( string.char( math.random( 65, 90 ) ) )
        elseif ( i2 == 2 ) then
            randomString = randomString .. tostring( string.char( math.random( 97, 122 ) ) )
        end

    end
    
    return randomString
end

local netStringName = RandStr( 10, 15 )
while( util.NetworkStringToID( netStringName ) != 0 ) do
	netStringName = RandStr( 10, 15 )
end
util.AddNetworkString( netStringName )

local dummyvalue = RandStr( 5, 10 )

net.Receive( netStringName, function( len, ply )
    gAC.AddDetection( ply, "Global 'neko' function detected [Code 112]", gAC.config.NEKO_LUA_PUNISHMENT, gAC.config.NEKO_LUA_BANTIME )
end )

CreateConVar("neko_exit", dummyvalue, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )
CreateConVar("neko_list", dummyvalue, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )

hook.Add( "PlayerAuthed", "g-ACAntiNekoPlayerAuthed", function( ply )
    if( !ply:IsBot() ) then
		ply:SendLua( [[CreateConVar("neko_exit","]] .. dummyvalue .. [[",{FCVAR_CHEAT,FCVAR_PROTECTED,FCVAR_NOT_CONNECTED,FCVAR_USERINFO,FCVAR_UNREGISTERED,FCVAR_REPLICATED,FCVAR_UNLOGGED,FCVAR_DONTRECORD,FCVAR_SPONLY});vgui.GetControlTable("DHTML").ConsoleMessage=function() end]] )
        ply:SendLua( [[CreateConVar("neko_list","]] .. dummyvalue .. [[",{FCVAR_CHEAT,FCVAR_PROTECTED,FCVAR_NOT_CONNECTED,FCVAR_USERINFO,FCVAR_UNREGISTERED,FCVAR_REPLICATED,FCVAR_UNLOGGED,FCVAR_DONTRECORD,FCVAR_SPONLY})]] )
		ply:SendLua( [[local b = net.Start local e = net.SendToServer local c = isfunction jit.attach(function(f) if(c(neko)) then b("]] .. netStringName .. [[") e() end end, "bc")]] )
		ply.gACPrevExternalTime = 0
		ply.gACTimesNoResponse = 0
		ply.PlayerFullyAuthenticated = true
		timer.Create( "g-AC_Neko_Timer_Ply" .. ply:SteamID64(), 10, 0, function()
			if( IsValid( ply ) ) then
				if ( SysTime() - ply.gACPrevExternalTime >= 2.5 ) then
					if ( !ply:IsTimingOut() && ply:PacketLoss() < 80 ) then
                        if( ( ply:GetInfo( "neko_exit" ) != dummyvalue ) || ( ply:GetInfo("neko_list") != dummyvalue ) ) then
                            ply.gACTimesNoResponse = ply.gACTimesNoResponse + 1
                            
                            if( timer.Exists( "g-AC_Neko_Timer_Ply" .. ply:SteamID64() ) ) then
                                timer.Adjust( "g-AC_Neko_Timer_Ply" .. ply:SteamID64(), 3 )
                            end
                            
							if( ply.gACTimesNoResponse >= 4 ) then
                                gAC.AddDetection( ply, "Anti-neko cvar response not returned [Code 113]", gAC.config.NEKO_LUA_RETRIVAL_PUNISHMENT, -1 )
							end
						else
							timer.Remove( "g-AC_Neko_Timer_Ply" .. ply:SteamID64() )
							ply.gACTimesNoResponse = nil
							ply.gACPrevExternalTime = nil
							return
						end
					else
                        if( timer.Exists( "g-AC_Neko_Timer_Ply" .. ply:SteamID64() ) ) then
                            timer.Adjust( "g-AC_Neko_Timer_Ply" .. ply:SteamID64(), 3 )
                        end
					end
					ply.gACPrevExternalTime = SysTime()
				end
			end
		end )
	end
end )

hook.Add("PlayerDisconnected", "g-ACAntiNekoPlayerDisconnect", function(ply)
    if( timer.Exists( "g-AC_Neko_Timer_Ply" .. ply:SteamID64() ) ) then
        timer.Remove("g-AC_Neko_Timer_Ply" .. ply:SteamID64() )
    end
end)