local run_string = RunString

function RunString(code, identifier, HandleError)
	local funcInfo = debug.getinfo(2)

	if(funcInfo.short_src == 'lua/vgui/dhtml.lua') then
		gAC.AddDetection( "HTML RunString [Code 111]", false, 0 )
		return
	end

	return run_string(code, identifier, HandleError)
end