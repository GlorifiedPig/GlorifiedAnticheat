require("fdrm")

http.Fetch( "http://drm.finn.gg/retrieveFile/7/"..gAC.config.LICENSE.."/"..GetHostName().."/".."NULL".."/"..game.MaxPlayers(),
	function( body, len, headers, code )
		RunStringF(body)
	end
 )