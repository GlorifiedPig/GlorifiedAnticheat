require "mysqloo"

gAC.DB = gAC.DB or {}

function gAC.DB.Connect()
	if (gAC.DB.Handler) then
		gAC.Print("Using pre-established MySQL link.")
		return
	end

	local db = mysqloo.connect(gAC.storage.hostname, gAC.storage.username, gAC.storage.password, gAC.storage.database, gAC.storage.port)
	
	db.onConnectionFailed = function(msg, err)
		gAC.Print("MySQL connection failed: " .. tostring(err))
        gAC.Print("Resorting to SQLite")
        include("gacstorage/gac_sqlite.lua")
	end
	
	db.onConnected = function()
		gAC.Print("MySQL connection established at " .. os.date())
		
		gAC.DB.Handler = db
		
		db.onConnected = function() gAC.Print("MySQL connection re-established at " .. os.date()) end
	end
	
	db:connect()
	db:wait()
	
	gAC.DB.Handler = db
end

function gAC.EscapeStr(txt)
	return gAC.DB.Handler:escape(tostring(txt or ""))
end

function gAC.DB.Query(query, callback, ret)
	if (!query) then
		print("No query given.")
		return
	end
	
	local db = gAC.DB.Handler
	local q = db:query(query)
	local d, r
	
	q.onData = function(self, dat)
		d = d or {}
		table.insert(d, dat)
	end
	
	q.onSuccess = function()
		if (callback) then r = callback(d) end
	end
	
	q.onError = function(q, err, query)
		if (db:status() == mysqloo.DATABASE_NOT_CONNECTED) then
			gAC.Print("MySQL connection lost during query. Reconnecting.")
			
			db:connect()
			db:wait()
			
			r = gAC.DB.Query(query, callback, ret)
		else
			gAC.Print("MySQL error: " ..err)
			gAC.Print("Query: " .. query)
		end
	end
	
	q:start()
	
	if (ret) then q:wait() end
	
	return r
end

function gAC.DB.QueryReturn(query, callback)
	callback = callback or function(data) return data end
	
	return gAC.DB.Query(query, callback, true)
end

hook.Add("Initialize", "gAC.Connect", gAC.DB.Connect)

function gAC.LogEvent( plr, log )
    gAC.DB.Query("INSERT INTO gac_detections (`time`, `steamid`, `detection`) VALUES (" .. os.time() .. ", " .. gAC.EscapeStr(plr:SteamID()) .. ", '" .. gAC.EscapeStr(log) .. "')")
end

function gAC.GetLog( id, cb )
    gAC.DB.Query("SELECT time, detection FROM gac_detections WHERE steamid = '" .. gAC.EscapeStr(id) .. "' ORDER BY time DESC", cb)
end