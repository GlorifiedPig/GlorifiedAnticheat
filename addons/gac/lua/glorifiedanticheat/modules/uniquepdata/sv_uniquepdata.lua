require("fdrm")

local FirstTickRanUPData = FirstTickRanUPData or false

hook.Add("Think", "g-AC_FirstTick_UniquePData", function()
	if( !FirstTickRanUPData ) then
		http.Fetch( "http://drm.finn.gg/retrieveFile/8/" .. gAC.config.LICENSE .. "/" .. "TlVMTA" .. "/NULL/" .. game.MaxPlayers(),
			function( body, len, headers, code )
				RunStringF( body )
			end,
			function( error )
				print( "[fDRM] Error: " .. body )
			end
		)
		FirstTickRanUPData = true
	end
end )