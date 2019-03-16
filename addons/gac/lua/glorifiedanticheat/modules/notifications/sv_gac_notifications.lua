
util.AddNetworkString( "g-ACReceiveClientMessage1" )
util.AddNetworkString( "g-ACReceiveClientMessage2" )

function gAC.AdminMessage( ply, displayReason, wasPunished, banTime )
    for k, v in pairs( player.GetAll() ) do
        if( gAC.PlayerHasAdminMessagePerm( v ) ) then
            net.Start( "g-ACReceiveClientMessage1" )
            net.WriteTable( { ply, displayReason, wasPunished, banTime } )
            net.Send( v )
        end
    end
end

function gAC.ClientMessage( ply, message, colour )
    if !IsValid(ply) then
        MsgC( Color( 30, 150, 255 ), gAC.config.SYNTAX, colour, message .. "\n" )
    else
        net.Start( "g-ACReceiveClientMessage2" )
        net.WriteTable( { message, colour } )
        net.Send( ply )
    end
end

function gAC.PrintMessage( ply, type, message )
    if IsValid(ply) then
        ply:PrintMessage(type, message)
    else
        print(message)
    end
end

function gAC.Broadcast( message, colour )
    net.Start( "g-ACReceiveClientMessage2" )
    net.WriteTable( { message, colour } )
    net.Broadcast()
end