if(!gAC.config.MENUHOOK_LUA_CHECKS) then return end

local printreal = print

function print(args)
    if(string.find(args, "[MenuHook] Files Module:")) then
        gAC.AddDetection("MenuHook [Code 112]", gAC.config.MENUHOOK_LUA_PUNISHMENT, gAC.config.MENUHOOK_LUA_BANTIME)
    end

    printreal(args)
end