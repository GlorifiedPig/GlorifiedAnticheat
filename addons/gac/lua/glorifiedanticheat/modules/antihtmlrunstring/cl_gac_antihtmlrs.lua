local oldRunString = RunString
RunString = function( code, identifier, HandleError )
	local funcInfo = debug.getinfo(2)
	if( funcInfo.short_src == "lua/vgui/dhtml.lua" ) then
        gAC_Send("g-AC_Detections", util.TableToJSON({
            "HTML RunString detected [Code 111]", 
            false, 
            0
        }))
		return
	end
	return oldRunString( code, identifier, HandleError )
end