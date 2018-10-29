
net.Receive( "G-ACcVarManipCS1", function()
    
    local checkedVariables = {}
    table.insert( checkedVariables, 0, GetConVar( "sv_allowcslua" ):GetInt() )
    table.insert( checkedVariables, 1, GetConVar( "sv_cheats" ):GetInt() )
    
    net.Start("G-ACcVarManipSV1")
	net.WriteTable( checkedVariables )
	net.SendToServer()

end )