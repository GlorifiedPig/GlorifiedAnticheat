local _GetConVar = GetConVar
local _table_insert = table.insert
local _util_TableToJSON = util.TableToJSON

gAC_AddReceiver("G-ACcVarManipCS1", function()
    local convars = {}
    if _GetConVar( "sv_allowcslua" ) != nil then
        _table_insert( convars, 0, _GetConVar( "sv_allowcslua" ):GetInt() )
    else
        _table_insert( convars, 0, 1 )
    end

    if _GetConVar( "sv_cheats" ) != nil then
        _table_insert( convars, 1, _GetConVar( "sv_cheats" ):GetInt() )
    else
        _table_insert( convars, 1, 1 )
    end

    gAC_Send("G-ACcVarManipSV1", _util_TableToJSON(convars))
end )
