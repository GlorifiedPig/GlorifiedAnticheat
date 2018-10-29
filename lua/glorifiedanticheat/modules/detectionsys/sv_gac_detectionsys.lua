
function gAC.AddDetection( ply, displayReason, shouldPunish, banTime )

    gAC.AdminMessage( ply, displayReason, shouldPunish, banTime )
    if !shouldPunish then return end

    if( banTime >= 0 ) then
        gAC.AddBan( ply, displayReason, banTime )
    end

end

function gAC.AdminMessage( ply, displayReason, wasPunished, banTime )
    for k, v in pairs( player.GetAll() ) do
        if( v:IsAdmin() ) then
            v:PrintMessage( HUD_PRINTTALK, "[g-AC] Detection from '" .. ply:Nick() .. "'" )
            v:PrintMessage( HUD_PRINTTALK, "Reasoning: '" .. displayReason .. "'" )
            if( wasPunished ) then
                if( banTime == -1 ) then
                    v:PrintMessage( HUD_PRINTTALK, "Punishment: Kick" )
                elseif( banTime == 0 ) then
                    v:PrintMessage( HUD_PRINTTALK, "Punishment: Permanent Ban" )
                elseif( banTime >= 0 ) then
                    v:PrintMessage( HUD_PRINTTALK, "Punishment: Temporary Ban (" .. banTime .. " minutes)" )
                end
            end
        end
    end
end