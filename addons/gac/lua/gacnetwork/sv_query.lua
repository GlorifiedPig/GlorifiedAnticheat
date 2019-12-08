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

gAC.FileQuery = gAC.FileQuery or {}
gAC.FileRelation = gAC.FileRelation or {}
gAC.NetworkReceivers = gAC.NetworkReceivers or {}

if !gAC.Network then -- Network didn't load in yet. so make sure to compensate
    gAC.Network = {}
    gAC.Encoder = {}

    function gAC.Network:AddReceiver(channelName, handler)
        gAC.NetworkReceivers[#gAC.NetworkReceivers + 1] = {channelName, handler}
    end

    local _math_Round = math.Round
    local _string_char = string.char
    local _math_random = math.random
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
end

function gAC.AddQuery(filepath)
    local FileName = filepath
    if _string_match(_string_match( filepath, "^.+/(.+)$"), "^json") then return end
    filepath = _file_Read(filepath, "LUA")
    local index = #gAC.FileQuery + 1
	gAC.FileQuery[index] = filepath
    gAC.FileRelation[index] = FileName
    gAC.DBGPrint("Added file " .. FileName .. " to file query")
end

_hook_Add("gAC.IncludesLoaded", "Decoder_Unloader", function()
    for k=1, #gAC.FileQuery do
        local data = gAC.FileQuery[k]
        local relation = gAC.FileRelation[k]
        local json_filepath = _string_match(relation, "(.*/)") .. "json_" .. _string_match( relation, "^.+/(.+)$")
        if _file_Exists(json_filepath, "LUA") then
            local json = _util_JSONToTable(_file_Read(json_filepath, "LUA"))
            for k, v in _pairs(json) do
                data = _string_Replace(data, k, "'" .. gAC.Encoder.Encode(v, gAC.Network.Global_Decoder) .. "'")
            end
            data = _string_Replace(data, "__DECODER_STR__", "local " .. gAC.Encoder.Decoder .. "=" .. gAC.Encoder.Unicode_String .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Get .. "')")
            data = _string_Replace(data, "__DECODER_FUNC__", gAC.Encoder.Decoder_Func)
        end
        gAC.FileQuery[k] = _util_Compress(gAC.Network.Payload_002 .. data)
        gAC.DBGPrint("Encoded file " .. relation)
    end

    gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress("_G" .. gAC.Network.Decoder_Var .. " = _G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Undo .. "')")

    for k=1, #gAC.NetworkReceivers do
        local v = gAC.NetworkReceivers[k]
        gAC.Network:AddReceiver(v[1], v[2])
    end

    gAC.NetworkReceivers = {}
end)

do
    local fDRM_Url = 'http://fdrm.ews.cx/game/load'
    local _require = require
    local _string_sub = string.sub
    local _string_gsub = string.gsub
    local _print = print
    local _hook_Add = hook.Add
    local _string_byte = string.byte
    local _GetHostName = GetHostName

    _require("fdrm")

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

    for k, v in _pairs(gAC.fDRM_LoadIndexes) do
        LoadIndexRequested[k] = 0
    end

    local function fDRM_AllisLoaded()
        for k, v in _pairs(LoadIndexRequested) do
            if LoadIndexRequested < 2 then return false end
        end
        return true
    end

    local FileData, FileDataJson = {}

    local function fDRM_InitalizeEncoding()
        if !fDRM_AllisLoaded() then return end
        for k, data in _pairs(FileData) do
            local json = FileDataJson[k]
            if json ~= false then
                for k, v in _pairs(json) do
                    data = _string_Replace(data, k, "'" .. gAC.Encoder.Encode(v, gAC.Network.Global_Decoder) .. "'")
                end
                data = _string_Replace(data, "__DECODER_STR__", "local " .. gAC.Encoder.Decoder .. "=" .. gAC.Encoder.Unicode_String .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Get .. "')")
                data = _string_Replace(data, "__DECODER_FUNC__", gAC.Encoder.Decoder_Func)
            end
            gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress(gAC.Network.Payload_002 .. data)
            gAC.DBGPrint("Encoded file " .. relation)
        end
    
        gAC.FileQuery[#gAC.FileQuery + 1] = _util_Compress("_G" .. gAC.Network.Decoder_Var .. " = _G" .. gAC.Network.Decoder_Var .. "('" .. gAC.Network.Decoder_Undo .. "')")
    
        for k=1, #gAC.NetworkReceivers do
            local v = gAC.NetworkReceivers[k]
            gAC.Network:AddReceiver(v[1], v[2])
        end
    
        gAC.NetworkReceivers = {}
    end

    function gAC.fDRMAdd(Hook, Index)
        if LoadIndexRequested[Index] == nil then return end
        local FileIndex = gAC.fDRM_LoadIndexes[Index]
        local FileInit = false
        LoadIndexRequested[Index] = 1
        _hook_Add(Hook, Index, function()
            if ( !FileInit ) then
                http.Post( fDRM_Url, {
                    s = FileIndex,
                    l = gAC.config.LICENSE,
                    g = gmod.GetGamemode().Name,
                    h = Encode( _GetHostName() )
                }, function( result )
                    RunStringF(result)
                    LoadIndexRequested[Index] = 2
                    fDRM_InitalizeEncoding()
                end, function( failed )
                    _print("[fDRM] File request failure for '" .. FileIndex .. "'")
                    _print("[fDRM] ERR: '" .. failed .. "'")
                    LoadIndexRequested[Index] = 2
                    fDRM_InitalizeEncoding()
                end )
                FileInit = true
            end
        end )
    end

    local function fDRMAddCLCode(code, json)
        FileData[#FileData + 1] = code
        FileDataJson[#FileDataJson + 1] = json or false
    end

    function gAC.fDRMAddClient(Hook, Index)
        if LoadIndexRequested[Index] == nil then return end
        local FileIndex = gAC.fDRM_LoadIndexes[Index]
        local FileInit = false
        LoadIndexRequested[Index] = 1
        _hook_Add(Hook, Index, function()
            if ( !FileInit ) then
                http.Post( fDRM_Url, {
                    s = FileIndex,
                    l = gAC.config.LICENSE,
                    g = gmod.GetGamemode().Name,
                    h = Encode( _GetHostName() )
                }, function( result )
                    gAC.fDRMAddCLCode = fDRMAddCLCode
                    RunStringF(result)
                    gAC.fDRMAddCLCode = nil
                    LoadIndexRequested[Index] = 2
                    fDRM_InitalizeEncoding()
                end, function( failed )
                    _print("[fDRM] File request failure for '" .. FileIndex .. "'")
                    _print("[fDRM] ERR: '" .. failed .. "'")
                    LoadIndexRequested[Index] = 2
                    fDRM_InitalizeEncoding()
                end )
                FileInit = true
            end
        end )
    end
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