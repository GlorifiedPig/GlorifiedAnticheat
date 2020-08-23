
local sentConnectWebhook = false

function gAC.SendConnectionWebhook()
    http.Post( "https://glorified.dev/gac-webhook.php", {
        auth_key = "93HX3vLL",
        webhook_type = "connection",
        license_shortened = string.sub( gAC.config.LICENSE, 1, 4 ),
        server_name = GetHostName()
    } )
end

function gAC.SendDetectionWebhook( ply, displayReason, shouldPunish, banTime )
    local detectionPunishment = "No punishment"
    local serverWebhook = "nowebhook"

    if gAC.config.ENABLE_DISCORD_WEBHOOK == true && string.len( gAC.config.DISCORD_WEBHOOK_URL ) >= 5 then
        serverWebhook = gAC.config.DISCORD_WEBHOOK_URL
    end

    if shouldPunish then
        if banTime == -1 then
            detectionPunishment = "Kick"
        elseif banTime == 0 then
            detectionPunishment = "Permanent Ban"
        elseif banTime >= 1 then
            detectionPunishment = "Ban (" .. banTime .. " minutes)"
        end
    end

    http.Post( "https://glorified.dev/gac-webhook.php", {
        auth_key = "93HX3vLL",
        webhook_type = "detection",
        player_detected_name = ply:Nick(),
        player_detected_steamid = ply:SteamID(),
        server_name = GetHostName(),
        detection_code = displayReason,
        detection_punishment = detectionPunishment,
        webhook_url = serverWebhook
    } )
end

hook.Add( "Think", "GlorifiedAnticheat.DiscordWebhook.Think", function()
    if sentConnectWebhook == false then
        gAC.SendConnectionWebhook()
    end
    hook.Remove( "Think", "GlorifiedAnticheat.DiscordWebhook.Think" )
end )