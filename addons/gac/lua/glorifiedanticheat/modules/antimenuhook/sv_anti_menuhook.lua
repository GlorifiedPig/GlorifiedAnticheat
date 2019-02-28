if(!gAC.config.MENUHOOK_LUA_CHECKS) then return end


hook.Add('PlayerInitialSpawn', 'g-AC_menuhook', function(ply)
    timer.Simple(15, function()
        ply:SendLua("if file.Exists('_seqgmod', 'GAME') or file.Exists('menuhook', 'GAME') or file.Exists('lua/menu/menuhook.lua', 'GAME') or file.Exists('lua/menu/menuhook', 'GAME') then gAC.AddDetection( 'Menu Hook [Code 112]', true, 0 ) end")
    end)
end)
