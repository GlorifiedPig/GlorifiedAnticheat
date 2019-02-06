
if !gAC.config.KEYBIND_CHECKS then return end

hook.Add( "PlayerButtonDown", "g-ACPlayerButtonDownKeyBindCheck", function( ply, button )

    if( ( button == KEY_HOME || button == KEY_INSERT || button == KEY_END ) && ( ply.gAC_TimeSinceKeyCheck == nil || CurTime() >= ply.gAC_TimeSinceKeyCheck + 10 ) ) then
        ply.gAC_TimeSinceKeyCheck = CurTime()

        local buttonName = ""
        if( button == KEY_HOME ) then buttonName = "HOME" elseif( button == KEY_INSERT ) then buttonName = "INSERT" elseif( button == KEY_END ) then buttonName = "END" end

        gAC.AddDetection( ply, "Suspicious keybind (" .. buttonName .. ") pressed [Code 102]", false )
    end

end )