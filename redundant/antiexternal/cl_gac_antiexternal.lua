local _CreateConVar = CreateConVar
local _isfunction = isfunction
local _util_TableToJSON = util.TableToJSON

local _vgui_GetControlTable = (CLIENT and vgui.GetControlTable or NULL)

gAC_AddReceiver("g-AC_antiexternal", function(data)
    _CreateConVar("external",data,{
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
    _CreateConVar("require",data,{
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
        if(_isfunction(external)) then
            gAC_Send("g-AC_External2", '')
        end 
    end, "bc")
end)