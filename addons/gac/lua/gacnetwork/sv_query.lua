local _SortedPairs = SortedPairs
local _file_Exists = file.Exists
local _file_Read = file.Read
local _hook_Add = hook.Add
local _hook_Run = hook.Run
local _pairs = pairs
local _string_Replace = string.Replace
local _string_match = string.match
local _util_Compress = util.Compress
local _util_JSONToTable = util.JSONToTable
local _http_Post = http.Post
local _gmod_GetGamemode = gmod.GetGamemode
local _debug_getinfo = debug.getinfo
local _debug_getupvalue = debug.getupvalue
local _require = require
local _string_sub = string.sub
local _string_gsub = string.gsub
local _print = print
local _tostring = tostring
local _xpcall = xpcall
local _debug_traceback = debug.traceback
local _string_byte = string.byte
local _GetHostName = GetHostName
local _util_AddNetworkString = (SERVER and util.AddNetworkString or nil)
local _net_Receive = net.Receive
local _net_Start = net.Start
local _net_WriteData = net.WriteData
local _tonumber = tonumber
local _net_Send = net.Send
local _hook_Run = hook.Run
local _timer_Simple = timer.Simple
local _string_Explode = string.Explode
local _hook_Remove = hook.Remove
local _math_Round = math.Round
local _string_char = string.char
local _math_random = math.random

gAC.FileQuery = gAC.FileQuery or {}
gAC.FileRelation = gAC.FileRelation or {}
gAC.NetworkReceivers = gAC.NetworkReceivers or {}

if !gAC.Network then -- Network didn't load in yet. so make sure to compensate
    gAC.Network = {}
    gAC.Encoder = {}

    function gAC.Network:AddReceiver(channelName, handler)
        gAC.NetworkReceivers[#gAC.NetworkReceivers + 1] = {channelName, handler}
    end

    function gAC.Encoder.stringrandom(length)
        local str = ""
        for i = 1, length do
            local typo =  _math_Round(_math_random(1, 4))
            if typo == 1 then
                str = str.. _string_char(_math_random(97, 122))
            elseif typo == 2 then
                str = str.. _string_char(_math_random(65, 90))
            elseif typo == 3 then
                str = str.. _string_char(_math_random(49, 57))
            end
        end
        return str
    end

    gAC.Network.NonNetworkedPlayers = {}

    _util_AddNetworkString ("gAC.PlayerInit")

    _net_Receive("gAC.PlayerInit", function(_, ply)
        if ply.gAC_ClientLoaded then return end
        if ply.gAC_NonNetClientLoaded then return end
        ply.gAC_NonNetClientLoaded = true
        gAC.Network.NonNetworkedPlayers[#gAC.Network.NonNetworkedPlayers + 1] = ply:SteamID64()
    end)
end

function gAC.AddQuery(filepath)
    local FileName = filepath
    if _string_match(_string_match( filepath, "^.+(%..+)$"), ".json") then return end
    filepath = _file_Read(filepath, "LUA")
    local index = #gAC.FileQuery + 1
	gAC.FileQuery[index] = filepath
    gAC.FileRelation[index] = FileName
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

local DecoderUnloaderIndex = -1

local function randomizedecoderfunc()
    local charforstrs = {
        "到",
        "说",
        "国",
        "和",
        "地",
        "也",
        "子",
        "时",
        "道",
        "出",
        "而",
        "要",
        "于",
        "就",
        "下",
        "得",
        "可",
        "你",
        "年",
        "生"
    }
    local function indexToVarName(index)
        local id = ''
        local d = index % #charforstrs
        index = (index - d) / #charforstrs
        id = id..charforstrs[d+1]
        while index > 0 do
            local d = index % #charforstrs
            index = (index - d) / #charforstrs
            id = id..charforstrs[d+1]
        end
        return id
    end
    local func = gAC.Encoder.Decoder_Func
    local vars = _string_Explode('_lvar', func)
    local lvars = {}
    for i=2, #vars-1 do
        local var = vars[i]
        local num = _tonumber(_string_sub(var, 1, 1))
        if num then
            local ignore = false
            for i=1, #lvars do
                if lvars[i] == num then
                    ignore = true
                end
            end
            if not ignore then
                lvars[#lvars + 1] = num
            end
        end
    end
    local rand = _math_Round(_math_random(2, 15))
    for i=1, #lvars do
        func = _string_Replace(func, '_lvar' .. lvars[i], indexToVarName(rand + i))
    end
    return func
end

local function string_ReplaceCount( str, tofind, toreplace )
	local tbl = _string_Explode( tofind, str )
	if ( tbl[ 1 ] ) then
        local _str = tbl[1]
        for i=1, #tbl-1 do
            _str = _str .. toreplace(i) .. tbl[i+1]
        end
        return _str
    end
	return str
end

_hook_Add("gAC.IncludesLoaded", "Decoder_Unloader", function()
    if DecoderUnloaderIndex > 0 then
        gAC.FileQuery[#gAC.FileQuery] = nil
        DecoderUnloaderIndex = 0
    end
    for k=1, #gAC.FileQuery do
        local data = gAC.FileQuery[k]
        local relation = gAC.FileRelation[k]
        local json_filepath = _string_match( relation, "^(.+)%..+$") .. '.json'
        if _file_Exists(json_filepath, "LUA") then
            local json = _util_JSONToTable(_file_Read(json_filepath, "LUA"))
            for k, v in _pairs(json) do
                data = _string_Replace(data, k, gAC.Encoder.Encode(v, gAC.Network.Global_Decoder))
            end
            data = _string_Replace(data, "__DECODER_STR__", "_G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Get .. "')")
            data = string_ReplaceCount(data, "__DECODER_FUNC__", randomizedecoderfunc)
            gAC.DBGPrint('Encoded local file "' .. relation .. '"')
        end
        gAC.FileQuery[k] = _util_Compress(data)
        gAC.DBGPrint('Added compressed file "' .. relation .. '" to file query')
    end

    if #gAC.FileQuery > 0 then
        gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress("_G" .. gAC.Network.Decoder_Var .. " = _G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Undo .. "')")
        DecoderUnloaderIndex = #gAC.FileQuery
    end

    for k=1, #gAC.NetworkReceivers do
        local v = gAC.NetworkReceivers[k]
        gAC.Network:AddReceiver(v[1], v[2])
    end

    gAC.NetworkReceivers = {}
end)

do
    local Module = 'gac'

    local function hookremove(Hook, Index)
        local tbl = hook.GetTable()
        if tbl[Hook] and tbl[Hook][Index] then
            _hook_Remove(Hook, Index)
            tbl[Hook][Index] = nil
        end
    end
    
    local CalledDRM, RunFunc = false, function() end
    local CheckDetours = function(func)
        if func == nil then return true end
        local funcdetails = _debug_getinfo( func )

        if (funcdetails.what == 'C'
        and funcdetails.source == '=[C]'
        and funcdetails.short_src == '[C]'
        and funcdetails.nups == 0
        and funcdetails.linedefined == -1
        and funcdetails.lastlinedefined == -1
        and funcdetails.currentline == -1
        and _debug_getupvalue( funcdetails.func, 1 ) == nil) then
            return true
        else
            return false
        end
    end

    local require_drm = function(name)
        _require(name)
        if CheckDetours(RunString) == true and CheckDetours(RunStringG) == true then
            local _RunStringG = RunStringG
            RunFunc = function( file, index )
                return _xpcall(_RunStringG, _debug_traceback, file, index)
            end
        end
        RunStringG = nil
    end

    local _ends = {
        '',
        '==',
        '='
    }

    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    local function InChunk( x) 
        local r, b = '', _string_byte(x)
        for i = 8, 1, -1 do
            r = r..(b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
        end
        return r
    end

    local function OutChunk( x)
        if (#x < 6) then
            return ''
        end
        local c = 0
        for i = 1, 6 do
            c = c + (_string_sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
        end
        return _string_sub(b, c + 1, c + 1)
    end

    local function Encode( data)
        return _string_gsub(
            _string_gsub(data, '.', InChunk) .. '0000',
            '%d%d%d?%d?%d?%d?',
            OutChunk
        ) .. _ends[#data % 3 + 1]
    end

    local LoadIndexRequested = {}

    for k, v in _pairs(gAC.DRM_LoadIndexes) do
        LoadIndexRequested[k] = 0
    end

    local function DRM_AllisLoaded()
        for k, v in _pairs(LoadIndexRequested) do
            if v ~= 0 and (v < 2 or v == 4) then return false end
        end
        return true
    end

    local CLFileData, SVFileData = {}, {}

    local function DRM_InitalizeEncoding()
        if DecoderUnloaderIndex > 0 then
            gAC.FileQuery[#gAC.FileQuery] = nil
            DecoderUnloaderIndex = 0
        end

        for i=1, #SVFileData do
            local v = SVFileData[i]
            local stat, err = RunFunc(v[1], v[2])
            if stat == false then
                _print("[GlorifiedDRM] Execution error for file '" .. v[2] .. "'")
                _print("[GlorifiedDRM] Recommend contacting the developers on this...\n" .. err)
                LoadIndexRequested[v[2]] = 5
            else
                LoadIndexRequested[v[2]] = 3
            end
            SVFileData[i] = nil
        end

        for k=1, #CLFileData do
            local v = CLFileData[k]
            local clcode = nil
            do
                gAC.DRMAddCLCode = function(code, json)
                    clcode = {code, _util_JSONToTable(json)}
                end
                local stat, err = RunFunc(v[1], v[2])
                gAC.DRMAddCLCode = nil
                if stat == false then
                    _print("[GlorifiedDRM] Execution error for file '" .. v[2] .. "'")
                    _print("[GlorifiedDRM] Recommend contacting the developers on this...\n" .. err)
                    LoadIndexRequested[v[2]] = 5
                    clcode = nil
                else
                    LoadIndexRequested[v[2]] = 3
                end
            end
            if clcode ~= nil then
                local data, json = clcode[1], clcode[2]
                if json ~= false then
                    for k, v in _pairs(json) do
                        data = _string_Replace(data, k, gAC.Encoder.Encode(v, gAC.Network.Global_Decoder))
                    end
                    data = _string_Replace(data, "__DECODER_STR__", "_G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Get .. "')")
                    data = string_ReplaceCount(data, "__DECODER_FUNC__", randomizedecoderfunc)
                end
                gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress(data)
                gAC.DBGPrint('Encoded DRM file "' .. v[2] .. '"')
            end
            CLFileData[k] = nil
        end

        if DRM_AllisLoaded() then
            if #gAC.FileQuery > 0 then
                gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress("_G" .. gAC.Network.Decoder_Var .. " = _G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Undo .. "')")
                DecoderUnloaderIndex = #gAC.FileQuery
            end
            for k=1, #gAC.NetworkReceivers do
                local v = gAC.NetworkReceivers[k]
                gAC.Network:AddReceiver(v[1], v[2])
            end
            gAC.NetworkReceivers = {}
            gAC.Print('DRM files has initialized!')
            _hook_Run('gAC.DRMInitalized', true)
        end
    end

    _hook_Add("gAC.IncludesLoaded", "gAC.DidDRMInitalized", function()
        if DRM_AllisLoaded() then
            _hook_Run('gAC.DRMInitalized', false)
        end
    end)

    concommand.Add('drm_filestatus', function()
        gAC.Print('GlorifiedDRM file status')
        for k, v in _pairs(LoadIndexRequested) do
            local response = ""
            if v == 0 then response = "Not Requested" end
            if v == 1 then response = "Not Received" end
            if v == 2 then response = "Finializing" end
            if v == 3 then response = "Executed" end
            if v == 4 then response = "Request Error" end
            if v == 5 then response = "Execution Error" end
            _print('[GlorifiedDRM] index "' .. k .. "' - " .. response)
        end
    end)
end

_hook_Add("gAC.ClientLoaded", "SendFiles", function(ply)
    if #gAC.FileQuery > 0 then
        for k, v in _SortedPairs(gAC.FileQuery) do
            if gAC.FileQuery[k] == nil then continue end
            gAC.Network:Send ("LoadPayload", gAC.FileQuery[k], ply, true)
        end
        _hook_Run("gAC.CLFilesLoaded", ply)
    end
end)

local Checkactivity = false

_hook_Add('PlayerInitialSpawn', 'DidGacLoad?', function(ply)
    if gAC.Network and gAC.Network.ReceiveCount then return end
    if Checkactivity then return end
    gAC.Print('WARNING, gAC networking did not initialize in time.')
    gAC.Print('Chances are that something is wrong with your license key.')
    gAC.Print('Please contact the developers of gAC to resolve this.')
    Checkactivity = true
end)