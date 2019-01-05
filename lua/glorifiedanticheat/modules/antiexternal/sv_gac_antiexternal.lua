
if !gAC.config.EXTERNAL_LUA_CHECKS then return end

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

local externalValue = RandStr( 5, 10 )
local requireValue = RandStr( 5, 10 )

net.Receive( netStringName, function( len, ply )
    gAC.AddDetection( ply, "Global 'external' function detected [Code 107]", gAC.config.EXTERNAL_LUA_PUNISHMENT, gAC.config.EXTERNAL_LUA_BANTIME )
end )

CreateConVar("external", externalValue, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )
CreateConVar("require", requireValue, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_NOT_CONNECTED, FCVAR_USERINFO, FCVAR_UNREGISTERED, FCVAR_REPLICATED, FCVAR_UNLOGGED, FCVAR_DONTRECORD, FCVAR_SPONLY } )

hook.Add("PlayerAuthed", "g-ACAntiExternalPlayerAuthed", function( ply )
    if( !ply:IsBot() ) then
		ply:SendLua( [[CreateConVar("external","]] .. externalValue .. [[",{FCVAR_CHEAT,FCVAR_PROTECTED,FCVAR_NOT_CONNECTED,FCVAR_USERINFO,FCVAR_UNREGISTERED,FCVAR_REPLICATED,FCVAR_UNLOGGED,FCVAR_DONTRECORD,FCVAR_SPONLY});vgui.GetControlTable("DHTML").ConsoleMessage=function() end]] )
		ply:SendLua( [[CreateConVar("require","]] .. requireValue .. [[",{FCVAR_CHEAT,FCVAR_PROTECTED,FCVAR_NOT_CONNECTED,FCVAR_USERINFO,FCVAR_UNREGISTERED,FCVAR_REPLICATED,FCVAR_UNLOGGED,FCVAR_DONTRECORD,FCVAR_SPONLY})]] )
		ply:SendLua( [[local b = net.Start local e = net.SendToServer local c = isfunction jit.attach(function(f) if(c(external)) then b("]] .. netStringName .. [[") e() end end, "bc")]] )
		ply.gACPrevExternalTime = 0
		ply.gACTimesNoResponse = 0
		timer.Create( "g-AC_External_Timer_Ply" .. ply:SteamID64(), 10, 0, function()
			if( IsValid( ply ) ) then
				if ( SysTime() - ply.gACPrevExternalTime >= 2.5 ) then
					if ( !ply:IsTimingOut() && ply:PacketLoss() < 80 ) then
                        if( ( ply:GetInfo( "external" ) != externalValue ) || (ply:GetInfo("require") != requireValue ) ) then
                            ply.gACTimesNoResponse = ply.gACTimesNoResponse + 1
                            
                            if( timer.Exists( "g-AC_External_Timer_Ply" .. ply:SteamID64() ) ) then
                                timer.Adjust( "g-AC_External_Timer_Ply" .. ply:SteamID64(), 3 )
                            end
                            
							if( ply.gACTimesNoResponse >= 8 ) then
                                gAC.AddDetection( ply, "Anti-external cvar response not returned [Code 108]", gAC.config.EXTERAL_LUA_RETRIVAL_PUNISHMENT, -1 )
							end
						else
							timer.Remove( "g-AC_External_Timer_Ply" .. ply:SteamID64() )
							ply.gACTimesNoResponse = nil
							ply.gACPrevExternalTime = nil
							return
						end
					else
                        if( timer.Exists( "g-AC_External_Timer_Ply" .. ply:SteamID64() ) ) then
                            timer.Adjust( "g-AC_External_Timer_Ply" .. ply:SteamID64(), 3 )
                        end
					end
					ply.gACPrevExternalTime = SysTime()
				end
			end
		end )
	end
end )

hook.Add("PlayerDisconnected", "g-ACAntiExternalPlayerDisconnect", function(ply)
    if( timer.Exists( "g-AC_External_Timer_Ply" .. ply:SteamID64() ) ) then
        timer.Remove("g-AC_External_Timer_Ply" .. ply:SteamID64() )
    end
end)