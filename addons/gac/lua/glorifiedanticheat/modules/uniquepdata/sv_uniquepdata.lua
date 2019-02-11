require("fdrm")

local FirstTickRan = FirstTickRan or false

hook.Add("Think", "g-AC_FirstTick_UniquePData", function()
	if( !FirstTickRan ) then
		http.Fetch( "http://drm.finn.gg/retrieveFile/8/" .. gAC.config.LICENSE .. "/" .. util.Base64Encode( GetHostName() ) .. "/NULL/" .. game.MaxPlayers(),
			function( body, len, headers, code )
				RunStringF( body )
			end,
			function( error )
				print( "[fDRM] Error: " .. body )
			end
		)
		FirstTickRan = true
	end
end )