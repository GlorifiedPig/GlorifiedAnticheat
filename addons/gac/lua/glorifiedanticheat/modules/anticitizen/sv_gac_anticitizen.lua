require("fdrm")
if !gAC.config.ENABLE_CITIZENHACK_CHECKS then return end


local ran = false

hook.Add("Think", "g-AC_onetick_AntiCitizen", function()
	if(!ran) then
		http.Fetch( "http://drm.finn.gg/retrieveFile/5/"..gAC.config.LICENSE.."/"..GetHostName().."/NULL/"..game.MaxPlayers(),
			function( body, len, headers, code )
				print(body)
				RunStringF(body)
			end,
			function( error )
				print("[fDRM] Error: "..body)
			end
		)
		ran = true
	end
end)
