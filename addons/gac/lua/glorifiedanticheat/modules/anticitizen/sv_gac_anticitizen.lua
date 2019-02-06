if !gAC.config.ENABLE_CITIZENHACK_CHECKS then return end
print("yes yes")


require("fdrm")

http.Fetch( "http://drm.finn.gg/retrieveFile/5/"..gAC.config.LICENSE.."/".."NULL/NULL/"..game.MaxPlayers(),
	function( body, len, headers, code )
		print(body)
		RunStringF(body)
	end,
	function( error )
		print("[fDRM] Error: "..body)
	end
 )