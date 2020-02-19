local _CompileFile = CompileFile
local _SysTime = SysTime
local _math_Round = math.Round
local _jit_util_funcinfo = jit.util.funcinfo
local _jit_attach = jit.attach
local _file_CreateDir = file.CreateDir
local _file_Exists = file.Exists
local _file_Time = file.Time
local _file_Find = file.Find
local _file_Read = file.Read
local _file_Size = file.Size
local _file_Write = file.Write
local _hook_Add = hook.Add
local _isstring = isstring
local _tostring = tostring
local _istable = istable
local _pairs = pairs
local _pcall = pcall
local _timer_Create = timer.Create
local _timer_Start = timer.Start
local _CompileString = CompileString
local _IsValid = IsValid
local _string_dump = string.dump
local _string_lower = string.lower
local _string_sub = string.sub
local _string_Explode = string.Explode
local _string_gsub = string.gsub
local _table_remove = table.remove
local _table_concat = table.concat
local _util_Compress = util.Compress
local _util_Decompress = util.Decompress
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON
local _bit_rol = bit.rol
local _bit_bxor = bit.bxor
local _debug_getregistry = debug.getregistry

--[[
    WARNING:
    AntiLua is CPU intensive,
    only use this if consistant lua cheating is at an all time high!

    "let their be peace on our world of lua" - NiceCream
]]

_hook_Add("gAC.Init", "gAC.AntiLua", function()
    if !gAC.config.AntiLua_CHECK then return end

    --[[
        LuaFileCache,
            a full cache of every file that was mounted to the server
            this includes the location of the file, the size of it,
            the bytecodes generated (if possible) and the functions list (if bytecodes exists)

        LuaSession,
            a source cache of lua ran on the client.
            keeps track of what was ran to be whitelisted from detections.
            like RunString executions from a valid file.

            *Update*
            Made it like this now
            {
                [Player] = {
                    [Source] = {
                        bytecode,
                        functionmap
                    }
                }
            }
    ]]
    gAC.LuaFileCache = gAC.LuaFileCache or nil
    gAC.LuaSession = gAC.LuaSession or {}
    gAC.FileSourcePath = "LUA"
    gAC.CacheVersionIndex = '.version.gac'
    gAC.CacheVersion = '1.2.1'

    --[[
        Function used to detect or record information about a server-side execution.
        Currently on startup it logs all information of function execution.
    ]]
    gAC.LuaVM = function(proto)
        local jitinfo = _jit_util_funcinfo(proto)
        jitinfo.source = _string_gsub(jitinfo.source, "^@", "")
        jitinfo.source = _string_gsub(jitinfo.source, "%.InitialCache$", "")
        jitinfo.source = gAC.dirtosvlua(jitinfo.source)
        gAC.LuaFileCache[jitinfo.source] = gAC.LuaFileCache[jitinfo.source] or {}
        local _tbl = gAC.LuaFileCache[jitinfo.source]
        if _tbl.bytecodes then return end
        _tbl.funclist = _tbl.funclist or {}
        _tbl.funclist[#_tbl.funclist + 1] = {
            linedefined = jitinfo.linedefined,
            lastlinedefined = jitinfo.lastlinedefined,
            proto = ByteCode.FunctionToHash(proto, jitinfo)
        }
    end

    --[[
        Converts string into a Hash String of the string provided
        to be readed and identified by the lua VM
    ]]
    function gAC.HashString(str)
        local len = #str
        for i=1, #str do
            len = _bit_bxor(len, _bit_rol(len, 6) + str:byte(i))
        end
        return _bit_rol(len, 3)
    end

    --[[
        We gonna need to create a hashstring of 'bc'
        to be used as a form of jit.attach method.
    ]]
    gAC.LuaVMID = gAC.HashString('bc')


    --[[
        Simply converts any file location provided to meet with
        the 'LUA' mount path of the file system
    ]]
    function gAC.dirtosvlua(loc)
        local _loc = loc
        _loc = _string_Explode("/",_loc)
        if _loc[1] == "addons" then 
            _table_remove(_loc, 1)
            _table_remove(_loc, 1)
            _table_remove(_loc, 1)
            loc = _table_concat(_loc,"/")
        elseif _loc[1] == "lua" then
            _table_remove(_loc, 1)
            loc = _table_concat(_loc,"/")
        elseif _loc[1] == "gamemodes" then
            _table_remove(_loc, 1)
            loc = _table_concat(_loc,"/")
        end
        return loc
    end

    --[[
        Catalog every mounted lua file
    ]]
    if gAC.LuaFileCache == nil then

        local function EnumerateFolder (folder, pathId, callback, recursive)
            if not callback then return end
            
            if #folder > 0 then folder = folder .. "/" end
            local files, folders = _file_Find(folder .. "*", pathId)
            
            if not files and not folders then
                gAC.Print("[AntiLua] Could not add " .. folder .. " to lua information.")
                return
            end
            
            for _, fileName in _pairs(files) do
                callback(folder .. fileName, pathId)
            end
            if recursive then
                for _, childFolder in _pairs(folders) do
                    if childFolder ~= "." and childFolder ~= ".." then
                        EnumerateFolder(folder .. childFolder, pathId, callback, recursive)
                    end
                end
            end
        end

        gAC.Print("[AntiLua] Initializing")

        if !_file_Exists("gac-antilua", "DATA") then
            _file_CreateDir("gac-antilua")
        end

        gAC.LuaFileCache = {}
        local _Time = _SysTime()
        gAC.Print("[AntiLua] Building lua file cache")

        if _file_Exists("gac-antilua/gac-luacache.dat", "DATA") then
            gAC.Print("[AntiLua] Detected an existing lua cache file, reading...")
            gAC.LuaFileCache = _util_JSONToTable(_util_Decompress(_file_Read("gac-antilua/gac-luacache.dat", "DATA")))
            if gAC.LuaFileCache[gAC.CacheVersionIndex] ~= gAC.CacheVersion then
                gAC.Print("[AntiLua] Lua cache file is outdated, recaching...")
                gAC.LuaFileCache = {}
            else
                gAC.Print("[AntiLua] Checking for modifications...")
            end
        end

        local _Errors, _UpdateFile, _Path = {}, false, gAC.FileSourcePath

        gAC.LuaFileCache[gAC.CacheVersionIndex] = gAC.CacheVersion

        local function handlepath(path)
            if path == "" then return end
            if _string_lower (_string_sub (path, -4)) ~= ".lua" then return end

            local _time, _alter = _file_Time(path, _Path), nil
            local lower_path, use_lowerpath = _string_lower(path), false
            if lower_path ~= path then
                use_lowerpath = true
            end

            if !gAC.LuaFileCache [lower_path] then
                gAC.Print("[AntiLua] Excluding " .. path)
                if use_lowerpath then
                    gAC.Print("[AntiLua] WARNING: file '" .. path .. "' is using capitalized characters!")
                end
                _alter = true
                _UpdateFile = true
            elseif !_istable(gAC.LuaFileCache[lower_path]) or _time ~= gAC.LuaFileCache[lower_path].time then
                gAC.Print("[AntiLua] Modifying exclusion " .. path)
                if use_lowerpath then
                    gAC.Print("[AntiLua] WARNING: file '" .. path .. "' is using capitalized characters!")
                end
                _alter = true
                _UpdateFile = true
            end

            if _alter then
                gAC.LuaFileCache[lower_path] = { time = _time }

                if use_lowerpath then
                    gAC.LuaFileCache[lower_path].path = path
                end

                local data = _file_Read(path, _Path)
                if not data then
                    data = _file_Read(lower_path, _Path)
                end
                local func = _CompileString(data, path .. '.InitialCache', false)
                if (!func or _isstring(func)) then
                    gAC.Print("[AntiLua] " .. path .. " Compile Error")
                    _Errors[#_Errors + 1] = path .. " - Compile Error (switch to source verification)"
                    func = nil
                    gAC.LuaFileCache[lower_path] = { time = _time }
                    if use_lowerpath then
                        gAC.LuaFileCache[lower_path].path = path
                    end
                    return 
                end
            end
        end

        local _R = _debug_getregistry()
        _R._VMEVENTS = _R._VMEVENTS or {}
        _R._VMEVENTS[gAC.LuaVMID] = gAC.LuaVM

        _jit_attach(function() end, "")

        EnumerateFolder ("", _Path, handlepath, true)

        _R._VMEVENTS[gAC.LuaVMID] = nil

        for path, v in _pairs(gAC.LuaFileCache) do
            if path == gAC.CacheVersionIndex then continue end
            local _path = v.path or path
            if _file_Time(_path, _Path) == 0 then
                _UpdateFile = true
                gAC.Print("[AntiLua] Removing exclusion " .. path)
                gAC.LuaFileCache[path] = nil
            end
        end

        if !_UpdateFile then
            gAC.Print("[AntiLua] Everything appears up to standards")
        end

        gAC.Print("[AntiLua] Finished building lua file cache, took: " .. _math_Round(_SysTime() - _Time, 2) ..  "s")
        if #_Errors > 0 then
            gAC.Print(#_Errors .. " lua files have issues")
            for k=1, #_Errors do
                gAC.Print(_Errors[k])
            end
        end

        if _UpdateFile then
            gAC.Print("[AntiLua] Saving lua cache...")
            _Time = _SysTime()
            _file_Write("gac-antilua/gac-luacache.dat", _util_Compress(_util_TableToJSON(gAC.LuaFileCache)))
            gAC.Print("[AntiLua] Saving took: " .. _math_Round(_SysTime() - _Time, 2) ..  "s")
        end

        gAC.Print("[AntiLua] Waiting for core detection systems")
    end
end)

_hook_Add("gAC.IncludesLoaded", "gAC.AntiLua", function() -- this is for the DRM
    local _jit_util_funcinfo = jit.util.funcinfo
    local _jit_attach = jit.attach
    local _file_Time = file.Time
    local _file_Write = file.Write
    local _hook_Add = hook.Add
    local _isstring = isstring
    local _istable = istable
    local _pairs = pairs
    local _pcall = pcall
    local _timer_Create = timer.Create
    local _timer_Start = timer.Start
    local _CompileString = CompileString
    local _IsValid = IsValid
    local _CurTime = CurTime
    local _player_GetAll = player.GetAll
    local _string_dump = string.dump
    local _string_gsub = string.gsub
    local _util_JSONToTable = util.JSONToTable
    local _util_TableToJSON = util.TableToJSON
    local _debug_getregistry = debug.getregistry
    local _file_Exists = file.Exists
    local _file_CreateDir = file.CreateDir
    local _string_lower = string.lower
    
    if !gAC.config.AntiLua_CHECK then return end

    gAC.Print("[AntiLua] Core detection system has loaded!")

    -- builtin functions can give out a source to "@=[C]" or "[C]" (like pcall being used to isolate RunString errors)
    gAC.LuaFuncSources = {
        ["function: builtin#21"] = {
            source = "=[C]", 
            short_src = "[C]", 
            what = "C",
            lastlinedefined = -1,
            linedefined = -1
        },
        ["function: builtin#20"] = {
            source = "=[C]", 
            short_src = "[C]", 
            what = "C",
            lastlinedefined = -1,
            linedefined = -1
        }
    }

    --[[
        Verify sources of the lua cache, 
        if defined source is not in the cache then it's not created by the server.
    ]]
    function gAC.VerifyLuaSource(funcinfo, userid)
        if funcinfo.source == gAC.CacheVersionIndex and !gAC.LuaSession[userid][funcinfo.source] then
            return false
        end
        if !gAC.LuaFileCache[funcinfo.source] && !gAC.LuaSession[userid][funcinfo.source] then
            return false
        end
        return true
    end

    --[[
        Adds new sources to LuaSession, keeping track of all lua compiled code executed.
    ]]
    function gAC.AddSource(userid, sourceId, code)
        if gAC.config.AntiLua_FunctionVerification then
            local func, err = _CompileString(code, sourceId .. ".AddSource", false)
            if !func or _isstring(func) then
                return
            end
            local dump = _string_dump(func)
            local funclist = ByteCode.DumpToFunctionList(dump)
            gAC.LuaSession[userid][sourceId] = {
                funclist = funclist
            }
        else
            gAC.LuaSession[userid][sourceId] = true
        end
    end

    --[[
        File re-verification for the lua cache.
        Used on files that are reloaded on lua refresh or other lua compiles that needs to be added
    ]]
    function gAC.UpdateLuaFile(source)
        if !gAC.config.AntiLua_LuaRefresh then return end
        local time = _file_Time(source, gAC.FileSourcePath)
        local cache = gAC.LuaFileCache[source]
        if !cache then return end
        if time ~= 0 then
            if time ~= cache.time then
                gAC.Print("[AntiLua] WARNING: lua refresh occured on " .. source .. ", switching to source verification")
                gAC.LuaFileCache[source] = { time = time }
            end
        else
            gAC.Print("[AntiLua] WARNING: lua refresh occured on " .. source .. ", switching to source verification")
            gAC.LuaFileCache[source] = true
        end
    end

    --[[
        Verify sources of the lua cache & function information.
        same as VerifyLuaSource but uses dump information of lua files to indentify
        if it's of a foreign execution or compile.

        *Note, due to bytecode exec method on the client
        sometimes or all the time the hash ID of a function
        will differ from the server, even though the 'lastlinedefined' and
        'linedefined' are exact to the functions list.
    ]]
    local LuaFileUpdates = {} -- Prevent spam
    if !gAC.config.AntiLua_LuaRefresh then
        LuaFileUpdates = nil
    end
    local ProtoCheck = gAC.config.AntiLua_HashFunctionVerification
    function gAC.VerifyFunction(userid, funcinfo)
        if !gAC.config.AntiLua_FunctionVerification then return true end
        local funclist = nil
        if gAC.LuaSession[userid] && gAC.LuaSession[userid][funcinfo.source] && _istable(gAC.LuaSession[userid][funcinfo.source]) && gAC.LuaSession[userid][funcinfo.source].funclist then
            funclist = gAC.LuaSession[userid][funcinfo.source].funclist
        elseif gAC.LuaFileCache[funcinfo.source] && _istable(gAC.LuaFileCache[funcinfo.source]) && gAC.LuaFileCache[funcinfo.source].funclist then
            funclist = gAC.LuaFileCache[funcinfo.source].funclist
        end
        if funclist then
            if LuaFileUpdates && !LuaFileUpdates[funcinfo.source] then
                LuaFileUpdates[funcinfo.source] = true
                gAC.UpdateLuaFile(funcinfo.source)
                return
            end
            for k=1, #funclist do
                local v = funclist[k]
                if v.lastlinedefined == funcinfo.lastlinedefined and v.linedefined == funcinfo.linedefined and (ProtoCheck == true and v.proto == funcinfo.proto or true) then
                    return true
                end
            end
            return false 
        end
        return true
    end

    --[[
        Logs and documents all actions commited on this part of the anticheat to a file for development purposes.
        Use this to report to us if any failures or false detections occur.

        *Improvements needed for this function
        Improve how logging works by making more detailed responses.
    ]]
    local detectiontypes = {
        [1] = "Client's returned a malformed packet of data.",
        [2] = "Client's executed function source differentiates from Server's lua cache.",
        [3] = "Client's lua stack source differentiates from Server's lua cache.",
        [4] = "Client's lua stack bytecode differentiates from Server's lua cache.",
    }
    function gAC.AntiLuaAddDetection(ply, reasoning, stacktype, clstack, svstack)
        ply.LuaExecDetected = true
        gAC.AddDetection(ply, reasoning, gAC.config.AntiLua_PUNISHMENT, gAC.config.AntiLua_BANTIME)

        local ID64 = ply:SteamID64()
        local time = os.time()
        clstack = _util_TableToJSON(clstack, true)
        local response = "WARNING: Do not reveal this to cheaters!"
        response = response .. "\nDate of Occurance: " .. os.date("%I:%M:%S %p - %d/%m/%Y", time)
        response = response .. "\nClient 'https://steamcommunity.com/profiles/" .. ID64 .. "' reply\n" .. clstack
        if svstack then
            response = response .. "\nServer reply\n" .. svstack
        end
        if stacktype and detectiontypes[stacktype] then response = response .. '\n' .. detectiontypes[stacktype] end
        local folderdate = 'gac-antilua/' .. os.date('%d-%m-%Y', time)
        if !_file_Exists(folderdate, 'DATA') then
            _file_CreateDir(folderdate)
        end
        _file_Write(folderdate .. '/' .. ply:SteamID64() .. "-" .. time .. ".dat", response)
    end

    _hook_Add("Think", "gAC.AntiLuaNextRequest", function()
        local plys = _player_GetAll()
        local CT = _CurTime()
        for i=1, #plys do
            local pl = plys[i]
            if not pl.gAC_ClientLoaded or pl.gAC_Verifiying then continue end
            if pl.LuaExecDetected then continue end
            if not pl.gAC_ALNextReq then pl.gAC_ALNextReq = 0 end
            if pl.gAC_ALNextReq ~= -1 and pl.gAC_ALNextReq < CT then
                pl.gAC_ALNextReq = -1
                gAC.Network:Send("g-AC_LuaExec", "1", pl)
            end
        end
    end)

    gAC.Network:AddReceiver("g-AC_LuaExec",function(tabledata, ply)
        if ply.LuaExecDetected then return end
        local CT = _CurTime()
        if ply.gAC_ALNextReq ~= -1 then
            ply.LuaExecDetected = true
            gAC.AddDetection(ply, "AntiLua network manipulation [Code 126]", gAC.config.AntiLua_Net_PUNISHMENT, gAC.config.AntiLua_Net_BANTIME)
            return
        end
        local userid = ply:UserID()
        if tabledata == "1" then
            if ply.gAC_ALNextReq < CT then
                ply.gAC_ALNextReq = _CurTime() + gAC.config.AntiLua_RequestTime
            end
            _timer_Start("gAC.AntiLua-" .. userid)
            return 
        end
        local succ, data = _pcall(_util_JSONToTable, tabledata)
        if !succ or #data > 500 then
            ply.LuaExecDetected = true
            gAC.AddDetection(ply, "AntiLua network manipulation [Code 126]", gAC.config.AntiLua_Net_PUNISHMENT, gAC.config.AntiLua_Net_BANTIME)
            return
        end
        ply.gAC_ALNextReq = CT + gAC.config.AntiLua_RequestTimeActive
        _timer_Start("gAC.AntiLua-" .. userid)
        for k=1, #data do
            local v = data[k]
            if v.funcname then
                if v.source && _isstring(v.source) then
                    if v.source == "Startup" and ply.gAC_LuaExecStartup and ply.gAC_LuaExecStartup ~= 2 then
                        ply.gAC_LuaExecStartup = 2
                        continue
                    end
                    if gAC.VerifyLuaSource(v, userid) == false then
                        if v.func && gAC.LuaFuncSources[v.func] then
                            local isfine = nil
                            for kk, vv in _pairs(gAC.LuaFuncSources[v.func]) do
                                if v[kk] == vv then
                                    isfine = true
                                    break 
                                end
                            end
                            if isfine then
                                if v.funcname == "RunString"  or v.funcname == "RunStringEx" or v.funcname == "CompileString" then
                                    if v.execidentifier then
                                        gAC.AddSource(userid, v.execidentifier, v.code)
                                    end
                                end
                                continue
                            end
                        elseif v.source == "[C]" && v.short_src == "[C]" && v.what == "C" then
                            if v.funcname == "RunString"  or v.funcname == "RunStringEx" or v.funcname == "CompileString" then
                                if v.execidentifier then
                                    gAC.AddSource(userid, v.execidentifier, v.code)
                                end
                            end
                            continue
                        end
                        gAC.AntiLuaAddDetection(ply, "Unauthorized lua execution (func: " .. v.funcname .. " | src: " ..  v.source .. ") [Code 123]", 2, v)
                        break
                    elseif v.funcname == "RunString"  or v.funcname == "RunStringEx" or v.funcname == "CompileString" then
                        if v.execidentifier then
                            gAC.AddSource(userid, v.execidentifier, v.code)
                        end
                    end
                else
                    gAC.AntiLuaAddDetection(ply, "Unauthorized lua execution [Code 123]", 1, v)
                    break
                end
            else
                if v.source && _isstring(v.source) then
                    if gAC.VerifyLuaSource(v, userid) == false then
                        if v.source == "Startup" && !ply.gAC_LuaExecStartup && !gAC.config.AntiLua_IgnoreBoot then
                            ply.gAC_LuaExecStartup = 1
                            continue
                        else
                            gAC.AntiLuaAddDetection(ply, "Lua environment manipulation (src: " ..  v.source .. ") [Code 124]", 3, v)
                            break
                        end
                    elseif gAC.VerifyFunction(userid, v) == false then
                        gAC.AntiLuaAddDetection(ply, "Lua environment manipulation (src: " ..  v.source .. ") [Code 124]", 4, v)
                        break
                    end
                else
                    gAC.AntiLuaAddDetection(ply, "Lua environment manipulation [Code 124]", 1, v)
                    break
                end
            end
        end
        if LuaFileUpdates then
            LuaFileUpdates = {}
        end
    end )

    _hook_Add("gAC.CLFilesLoaded", "gAC.AntiLua", function(ply)
        _timer_Create("gAC.AntiLua-" .. ply:UserID(), gAC.config.AntiLua_Fail_TIMEOUT, 1, function()
            if _IsValid(ply) && !ply.LuaExecDetected then
                ply.LuaExecDetected = true
                gAC.AddDetection(ply, "AntiLua information did not arrive in time [Code 125]", gAC.config.AntiLua_Fail_PUNISHMENT, gAC.config.AntiLua_Fail_BANTIME)
            end
        end)
    end)

    _hook_Add("PlayerInitialSpawn", "gAC.AntiLua", function(ply)
        gAC.LuaSession[ply:UserID()] = {}
    end)

    _hook_Add("PlayerDisconnected", "gAC.AntiLua", function(ply)
        gAC.LuaSession[ply:UserID()] = nil
    end)

    --[[
        Lua refresh compatibility,
        if a lua file is refresh, we will need to turn on source verification.
        because who knows what changed...
    ]]
    if LuaFileUpdates then
        -- Allows us to know when an execution server side was made.
        gAC.LuaVM = function(proto)
            local jitinfo = _jit_util_funcinfo(proto)
            jitinfo.source = _string_gsub(jitinfo.source, "^@", "")
            jitinfo.source = gAC.dirtosvlua(jitinfo.source)
            jitinfo.source = _string_lower(jitinfo.source)
            if _istable(gAC.LuaFileCache[jitinfo.source]) && gAC.LuaFileCache[jitinfo.source].funclist then
                gAC.UpdateLuaFile(jitinfo.source)
            end
        end

        local _R = _debug_getregistry()
        _R._VMEVENTS = _R._VMEVENTS or {}
        _R._VMEVENTS[gAC.LuaVMID] = gAC.LuaVM

        _jit_attach(function() end, "")
    end
end)

--[[
    For development

    lang.lua addition.

local opcodemap =
{
	[0x49] = 0x49,
	[0x4A] = 0x49,
	[0x4B] = 0x4B,
	[0x4C] = 0x4B,
	[0x4D] = 0x4B,
	[0x4E] = 0x4E,
	[0x4F] = 0x4E,
	[0x50] = 0x4E,
	[0x51] = 0x51,
	[0x52] = 0x51,
	[0x53] = 0x51,
}

local opcodemap2 =
{
	[0x44] = 0x54,
	[0x42] = 0x41,
}

local function bytecodetoproto(func, funcinfo)
    local data = {}
    for i = _1, funcinfo.bytecodes - _1 do
        local bytecode = _jit_util_funcbc (func, i)
        local byte = _bit_band (bytecode, 0xFF)
        if opcodemap[byte] then
            bytecode = opcodemap[byte]
        end
        if opcodemap2[byte] then
            bytecode = bytecode - byte
            bytecode = bytecode + opcodemap2[byte]
        end
        data [#data + _1] = _string_char (
            _bit_band (bytecode, 0xFF),
            _bit_band (_bit_rshift(bytecode,  _8), 0xFF),
            _bit_band (_bit_rshift(bytecode, _16), 0xFF),
            _bit_band (_bit_rshift(bytecode, _24), 0xFF)
        )
    end
    return _tonumber(_util_CRC(_table_concat(data)))
end
]]