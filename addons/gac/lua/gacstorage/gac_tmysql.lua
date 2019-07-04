require "tmysql4"

gAC.DB = gAC.DB or {}

function gAC.DB.Connect()
	if (gAC.DB.Handler) then
		gAC.Print("Using pre-established MySQL link.")
		return
	end

	local db, err = tmysql.initialize(gAC.storage.hostname, gAC.storage.username, gAC.storage.password, gAC.storage.database, gAC.storage.port)

	if (db == false) or err then
		gAC.Print("MySQL connection failed: " .. tostring(err))
        gAC.Print("Resorting to SQLite")
        include("gacstorage/gac_sqlite.lua")
		return
	end
	
	gAC.Print("MySQL connection established at " .. os.date())

	gAC.DB.Handler = db
end

function gAC.EscapeStr(txt)
	return gAC.DB.Handler:Escape(tostring(txt or ""))
end

local retry_errors = {
	['Lost connection to MySQL server during query'] = true,
	[' MySQL server has gone away'] = true,
}

function gAC.DB.Query(query, callback, ret)
	if (!query) then
		print("No query given.")
		return
	end

	if ret then
		return gAC.DB.QueryRet(query, callback)
	end

	gAC.DB.Handler:Query(query, function(results)
		if (results[1].error ~= nil) then
			if retry_errors[results[1].error] then
				gAC.Print("MySQL connection lost during query. Reconnecting.")
				gAC.DB.Query(query, callback, ret)
			else
				gAC.Print("MySQL error: " .. results[1].error)
				gAC.Print("Query: " .. query)
			end
		elseif callback then
			callback(results[1].data)
		end
	end)
end

function gAC.DB.QueryRet(query, callback)
	local data
	local start = SysTime() + 0.3
	gAC.DB.Query(query, function(_data)
		data = _data
	end)
	while (not data) and (start >= SysTime()) do
		gAC.DB.Handler:Poll()
	end
	return callback and callback(data) or data
end

hook.Add("Initialize", "gAC.Connect", gAC.DB.Connect)

function gAC.LogEvent( plr, log )
    gAC.DB.Query("INSERT INTO `gac_detections` (`time`, `steamid`, `detection`) VALUES (" .. os.time() .. ", '" .. gAC.EscapeStr(plr:SteamID()) .. "', '" .. gAC.EscapeStr(log) .. "')")
end

function gAC.GetLog( id, cb )
    gAC.DB.Query("SELECT `time`, `detection` FROM `gac_detections` WHERE `steamid` = '" .. gAC.EscapeStr(id) .. "' ORDER BY `time` DESC", cb)
end