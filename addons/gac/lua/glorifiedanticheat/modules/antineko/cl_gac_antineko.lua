local _CreateConVar = CreateConVar
local _isfunction = isfunction
local _util_TableToJSON = util.TableToJSON

local _vgui_GetControlTable = (CLIENT and vgui.GetControlTable or NULL)

gAC_AddReceiver("g-AC_antineko", function(_, data)
    _CreateConVar("neko_exit",data,{
        FCVAR_CHEAT,
        FCVAR_PROTECTED,
        FCVAR_NOT_CONNECTED,
        FCVAR_USERINFO,
        FCVAR_UNREGISTERED,
        FCVAR_REPLICATED,
        FCVAR_UNLOGGED,
        FCVAR_DONTRECORD,
        FCVAR_SPONLY
    })
    _vgui_GetControlTable("DHTML").ConsoleMessage=function() end
    _CreateConVar("neko_list",data,{
        FCVAR_CHEAT,
        FCVAR_PROTECTED,
        FCVAR_NOT_CONNECTED,
        FCVAR_USERINFO,
        FCVAR_UNREGISTERED,
        FCVAR_REPLICATED,
        FCVAR_UNLOGGED,
        FCVAR_DONTRECORD,
        FCVAR_SPONLY
    })
	jit.attach(function(f) 
        if(_isfunction(neko)) then
            gAC_Send("g-AC_Detections", _util_TableToJSON({
                "Global 'neko' function detected [Code 112]", 
                gAC.config.NEKO_LUA_PUNISHMENT, 
                gAC.config.NEKO_LUA_BANTIME
            }))
        end 
    end, "bc")
end)