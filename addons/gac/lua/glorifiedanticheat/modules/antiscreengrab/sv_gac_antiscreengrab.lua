if not gAC.config.ANTISCREENGRAB_CHECKS then return end

gAC.Network:AddReceiver(
    "CRV",
    function(data, plr)
        gAC.AddDetection( plr, "Anti-Screengrab Detected [Code 130]", gAC.config.ANTISCREENGRAB_PUNSIHMENT, gAC.config.ANTISCREENGRAB_PUNSIHMENT_BANTIME )
        plr.gAC_AimbotDetected = true
    end
)

_hook_Add("gAC.CLFilesLoaded", "g-AC_AntiScreenGrab", function(ply)
    gAC.Network:Send("CRV", "", ply)
end)