gAC_AddReceiver("g-AC_antineko", function(_, data)
    CreateConVar("neko_exit",data,{
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
    CreateConVar("neko_list",data,{
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
        if(isfunction(neko)) then
            gAC_Send("g-AC_Detections", util.TableToJSON({
                "Global 'neko' function detected [Code 112]", 
                gAC.config.NEKO_LUA_PUNISHMENT, 
                gAC.config.NEKO_LUA_BANTIME
            }))
        end 
    end, "bc")
end)