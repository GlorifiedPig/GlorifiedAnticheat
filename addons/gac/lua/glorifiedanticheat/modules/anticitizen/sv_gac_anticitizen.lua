require("fdrm")

if !gAC.config.ENABLE_CITIZENHACK_CHECKS then return end

local FirstTickRanACitizen = FirstTickRanACitizen or false

hook.Add("Think", "g-AC_FirstTick_AntiCitizen", function()
	if( !FirstTickRanACitizen ) then
		http.Fetch( "http://drm.finn.gg/retrieveFile/5/" .. gAC.config.LICENSE .. "/" .. "TlVMTA" .. "/NULL/" .. game.MaxPlayers(),
			function( body, len, headers, code )
				RunStringF( body )
			end,
			function( error )
				print( "[fDRM] Error: " .. body )
			end
		)
		FirstTickRanACitizen = true
	end
end )
