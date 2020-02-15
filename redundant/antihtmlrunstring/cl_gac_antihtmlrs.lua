local _RunString = RunString
local _util_TableToJSON = util.TableToJSON

RunString = function( code, identifier, HandleError )
	local funcInfo = debug.getinfo(2)
	if( funcInfo.short_src == "lua/vgui/dhtml.lua" ) then
        gAC_Send("g-AC_Detections", _util_TableToJSON({
            "HTML RunString detected [Code 111]", 
            false, 
            0
        }))
		return
	end
	return _RunString( code, identifier, HandleError )
end