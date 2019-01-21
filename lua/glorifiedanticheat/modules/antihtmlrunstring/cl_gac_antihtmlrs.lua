
local oldRunString = RunString

function RunString( code, identifier, HandleError )
	local funcInfo = debug.getinfo(2)

	if( funcInfo.short_src == "lua/vgui/dhtml.lua" ) then
		gAC.AddDetection( "HTML RunString detected [Code 111]", false, 0 )
		return
	end

	return oldRunString( code, identifier, HandleError )
end