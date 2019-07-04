COMMAND.Name = "Cheatlog"

COMMAND.Flag = "T"
COMMAND.AdminMode = false
COMMAND.CheckRankWeight = false

COMMAND.Args = {{"player", "Name/SteamID"}}

COMMAND.CheckArgs = function(pl, cmd, args)
	local margs = cmd.Args
	local err
	local supp = {}

	if (pl:IsPlayer() and !pl:HasAccess(cmd.Flag)) then
		err = "'" .. cmd.Flag .. "' access required!"
	end

	if (pl:IsPlayer() and cmd.AdminMode and !pl:GetDataVar("adminmode")) then
		err = "Adminmode required!"
	end

	if (!err) then
		for k, v in pairs(margs) do
			if (!args[k]) then
				err = "_"
				break
			end

			if (v[1] == "number") then
				if (tostring(tonumber(args[k])) != args[k]) then
					err = "_"
					break
				else
					table.insert(supp, tonumber(args[k]))
				end
			elseif (v[1] == "player") then
				if args[k] == "@" then
					local targ = D3A.Commands.getPicker( pl )
					if targ then
						table.insert(supp, targ)
					else err = "Couldn't find anyone." end
				elseif  args[k] == "^" then
					table.insert(supp, pl)
				else
					local targ = D3A.FindPlayer(args[k])
					if (targ) then
						table.insert(supp, targ)
					elseif (!targ and string.sub(args[k], 1, 8) == "STEAM_0:") then
						table.insert(supp, args[k])
					else
						err = "Unknown player/steamid " .. args[k] .. "." 
						break 
					end

				end
			elseif (v[1] == "string") then
				args[k] = tostring(args[k])
			end
		end
	end

	if (err) then
		if (err == "_") then
			err = "Usage: " .. cmd.Name .. " "
			for k, v in pairs(margs) do
				err = err .. v[1] .. ":" .. v[2] .. " "
			end
		end
		D3A.Chat.SendToPlayer(pl, err, "ERR")
		return false
	end
	return supp
end

COMMAND.Run = function(pl, args, supp)

    local targstid, nameid

	if (isstring(supp[1])) then
		targstid = supp[1]
		nameid = targstid
	else
		targstid = supp[1]:SteamID()
		nameid = supp[1]:NameID()
	end

    gAC.GetLog( targstid, function(data)
        if isstring(data) then
            gAC.ClientMessage( pl, data, Color( 225, 150, 25 ) )
        else
            if data == {} or data == nil then
                gAC.ClientMessage( pl, nameid .. " has no detections.", Color( 0, 255, 0 ) )
            else
            	gAC.PrintMessage(pl, HUD_PRINTCONSOLE, "\n\n")
                gAC.PrintMessage(pl, HUD_PRINTCONSOLE, "Detection Log for " .. nameid .. "\n")
                for k, v in pairs(data) do
                    gAC.PrintMessage(pl, HUD_PRINTCONSOLE, os.date( "[%H:%M:%S %p - %d/%m/%Y]", v["time"] ) .. " - " .. v["detection"] .. "\n")
                end
                gAC.ClientMessage( pl, "Look in console.", Color( 0, 255, 0 ) )
            end
        end
    end)
end