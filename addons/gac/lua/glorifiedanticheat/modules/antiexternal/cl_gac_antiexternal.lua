gAC_AddReceiver("g-AC_antiexternal", function(_, data)
    CreateConVar("external",data,{
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
    vgui.GetControlTable("DHTML").ConsoleMessage=function() end
    CreateConVar("require",data,{
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
        if(isfunction(external)) then
            gAC_Send("g-AC_Detections", util.TableToJSON({
                "Global 'external' function detected [Code 107]", 
                gAC.config.EXTERNAL_LUA_PUNISHMENT,
                gAC.config.EXTERNAL_LUA_BANTIME
            }))
        end 
    end, "bc")
end)