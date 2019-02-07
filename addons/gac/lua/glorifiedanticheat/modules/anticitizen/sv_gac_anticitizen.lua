if !gAC.config.ENABLE_CITIZENHACK_CHECKS then return end

require("fdrm")

http.Fetch( "http://drm.finn.gg/retrieveFile/5/"..gAC.config.LICENSE.."/".."NULL/NULL/"..game.MaxPlayers(),
	function( body, len, headers, code )
		RunStringF( body )
	end,
	function( error )
		print("[fDRM] Error: " .. body)
	end
 )