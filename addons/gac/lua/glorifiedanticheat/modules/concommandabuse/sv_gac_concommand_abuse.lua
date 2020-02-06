local _util_TableToJSON = util.TableToJSON

if !gAC.config.ILLEGAL_CONCOMMAND_CHECKS then return end
gAC.Network:AddReceiver("g-ACIllegalConCommand",function(data, ply)
    gAC.AddDetection( ply, "Illegal console command detected [Code 104]", gAC.config.ILLEGAL_CONCOMMAND_PUNISHMENT, gAC.config.ILLEGAL_CONCOMMAND_BANTIME )
end )

local badcommands = _util_TableToJSON(gAC.config.BAD_COMMANDS_LIST)

gAC.Network:AddReceiver("g-ACReceiveExploitListCS",function(data, ply)
    gAC.Network:Send("g-ACReceiveExploitList", badcommands, ply)
end )