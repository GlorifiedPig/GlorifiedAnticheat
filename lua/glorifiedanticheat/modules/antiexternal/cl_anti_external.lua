
local function zcvklzjcvlkjzcv( f )
    local zxvlkj, eelkea = pcall( function() jit.util.funck( f, -1 ) end )
    if( !zxvlkj ) then return true end

    if( debug.getinfo( f ).short_src == "external" ) then return false end

    local zlkcjvz = debug.getinfo( 2 ).short_src or ""

    return ( debug.getinfo( f ).short_src && zlkcjvz == debug.getinfo( f ).short_src )
end

timer.Create( "g-ACAntiExternalTimer", 5, 0, function()
    for k, v in pairs( gAC.adfkjlk1238123adjfl ) do
        if( !zcvklzjcvlkjzcv( v ) ) then
            print('FAKLFJHAKJLDGFHAJKQGKJH')
        end
    end
end )