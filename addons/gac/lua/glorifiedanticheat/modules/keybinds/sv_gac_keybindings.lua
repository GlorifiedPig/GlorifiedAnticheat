
if !gAC.config.KEYBIND_CHECKS then return end

hook.Add( "PlayerButtonDown", "g-ACPlayerButtonDownKeyBindCheck", function( ply, button )

    if( ( button == KEY_HOME || button == KEY_INSERT || button == KEY_END || button == KEY_DELETE ) && ( ply.gAC_TimeSinceKeyCheck == nil || CurTime() >= ply.gAC_TimeSinceKeyCheck + 60 ) ) then
        ply.gAC_TimeSinceKeyCheck = CurTime()

        local buttonName = ""
        if( button == KEY_HOME ) then buttonName = "HOME" elseif( button == KEY_INSERT ) then buttonName = "INSERT" elseif( button == KEY_END ) then buttonName = "END" elseif( button == KEY_DELETE ) then buttonName = "DEL" end

        gAC.AddDetection( ply, "Suspicious keybind (" .. buttonName .. ") pressed [Code 102]", false )
    end

end )