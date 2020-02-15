local _print = print
local _string_find = string.find
local _util_TableToJSON = util.TableToJSON

if(!gAC.config.MENUHOOK_LUA_CHECKS) then return end
print = function(args, ...)
    if(_string_find(args, "[MenuHook] Files Module:")) then
        gAC_Send("g-AC_Detections", _util_TableToJSON({
            "MenuHook [Code 112]", 
            gAC.config.MENUHOOK_LUA_PUNISHMENT,
            gAC.config.MENUHOOK_LUA_BANTIME
        }))
    end
    _print(args, ...)
end