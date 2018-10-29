
function gAC.AddDetection( displayReason, shouldPunish, banTime )

    gAC.AdminMessage( displayReason, shouldPunish, banTime )
    if !shouldPunish then return end
    local banString = "_____________[ g-AC DETECTION ]_____________\n\nReason: '" .. displayReason .. "'\n\n"

    if( banTime == -1 ) then
        banString = banString .. "Type: Kick"
    elseif( banTime >= 0 ) then
            if( banTime == 0 ) then
                banString = banString .. "Type: Permanent Ban\n\nPlease appeal if you believe this is false."
            else
                banString = banString .. "Type: Temporary Ban\n\nPlease appeal if you believe this is false."
            end
            ply:Ban( banTime, false )
        end
    end

    ply:Kick( banString )

end

function gAC.AdminMessage( ply, displayReason, wasPunished, banTime ) then
    for k, v in pairs( player.GetAll() ) do
        if( v:IsAdmin() ) then
            v:PrintMessage( HUD_PRINTTALK, "[g-AC] Detection from '" .. ply:Nick() .. "'" )
            v:PrintMessage( HUD_PRINTTALK, "Reasoning: '" .. displayReason .. "'" )
            if( wasPunished ) then
                v:PrintMessage( HUD_PRINTTALK, "Punishment: None" )
            else
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