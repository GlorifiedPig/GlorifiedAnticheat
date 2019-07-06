gAC_AddReceiver("G-ACcVarManipCS1", function()
    local convars = {}
    if GetConVar( "sv_allowcslua" ) != nil then
        table.insert( convars, 0, GetConVar( "sv_allowcslua" ):GetInt() )
    else
        table.insert( convars, 0, 1 )
    end

    if GetConVar( "sv_cheats" ) != nil then
        table.insert( convars, 1, GetConVar( "sv_cheats" ):GetInt() )
    else
        table.insert( convars, 1, 1 )
    end

    gAC_Send("G-ACcVarManipSV1", util.TableToJSON(convars))
end )
