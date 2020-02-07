local _hook_Remove = hook.Remove
local _concommand_Add = concommand.Add
local _string_lower = string.lower
local _file_Write = file.Write
local _math_random = math.random
local _util_NetworkStringToID = util.NetworkStringToID
local _timer_Simple = timer.Simple
local _pairs = pairs
local _isfunction = isfunction
local _concommand_GetTable = concommand.GetTable
local _concommand_Add = concommand.Add
local _hook_Add = hook.Add
local _IsValid = IsValid
if !gAC.config.BACKDOOR_NET_EXPLOIT_CHECKS then return end

local exploitnets = gAC.config.EXPLOIT_NETS
local backdoornets = gAC.config.BACKDOOR_NETS
local exploitcmds = gAC.config.EXPLOIT_COMMANDS_LIST
local backdoorcmds = gAC.config.BACKDOOR_COMMANDS_LIST
local oldnetmessages = {}
local replacenetfunction = {}
local replacecmdfunction = {}

function gAC.CheckExploitables()
    local date = os.date("%I:%M:%S %p - %d/%m/%Y", os.time())

    do
        local badcmds = nil
        local cmdtable = gAC_ConCmdTable
        for k, v in _pairs(cmdtable) do
            if v == replacecmdfunction[k] then continue end
            for i=1, #backdoorcmds do
                if backdoorcmds[i] == k then
                    if not badcmds then 
                        badcmds = {}
                    end
                    local jitinfo = jit.util.funcinfo(v)
                    badcmds[#badcmds + 1] = 'Command: "' .. k .. '"\nSource: ' .. jitinfo.source .. '\nLine #' .. jitinfo.linedefined .. '-' .. jitinfo.lastlinedefined
                    replacecmdfunction[k] = function(plr)
                        if _IsValid(plr) then
                            gAC.AddDetection( plr, "Backdoor console command called (" .. k .. ") [Code 103]", gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT, gAC.config.BACKDOOR_EXPLOITATION_BANTIME )
                        end
                    end
                    _concommand_Add(k, replacecmdfunction[k])
                    break
                end
            end
        end

        if badcmds then
            gAC.Print('[Anti-NetBackDoor] WARNING - Found ' .. #badcmds .. ' backdoor console commands, recommend removing them immediately!')
            gAC.Print('[Anti-NetBackDoor] List of backdoor commands have been put into gac_backdoorcmds.dat in the data folder')
            local str = 'List of backdoor cmds as of ' .. date .. '\n\n'
            for i = 1, #badcmds do
                str = str .. badcmds[i] .. '\n'
                str = str .. "-------------------------------------" .. '\n'
            end
            _file_Write('gac_backdoorcmds.dat', str)
            gAC.Print('[Anti-NetBackDoor] Due to this detection, backdoor console commands have been re-written to detect users attempting to use them.')
        end
    end

    do
        local badcmds = nil
        local cmdtable = gAC_ConCmdTable
        for k, v in _pairs(cmdtable) do
            if v == replacecmdfunction then continue end
            for i=1, #backdoorcmds do
                if backdoorcmds[i] == k then
                    if not badcmds then 
                        badcmds = {}
                    end
                    local jitinfo = jit.util.funcinfo(v)
                    badcmds[#badcmds + 1] = 'Command: "' .. k .. '"\nSource: ' .. jitinfo.source .. '\nLine #' .. jitinfo.linedefined .. '-' .. jitinfo.lastlinedefined
                    break
                end
            end
        end

        if badcmds then
            gAC.Print('[Anti-NetBackDoor] WARNING - Found ' .. #badcmds .. ' exploitable console commands, remember to keep commands up to date!')
            gAC.Print('[Anti-NetBackDoor] List of exploitable commands have been put into gac_exploitablecmds.dat in the data folder')
            local str = 'List of exploitable cmds as of ' .. date .. '\n\n'
            for i = 1, #badcmds do
                str = str .. badcmds[i] .. '\n'
                str = str .. "-------------------------------------" .. '\n'
            end
            _file_Write('gac_exploitablecmds.dat', str)
        end
    end

    do
        local badnets = nil
        for i=1, #exploitnets do
            local v = exploitnets[i]
            local _net = net.Receivers[v]
            if not _net then
                v = _string_lower(v)
                _net = net.Receivers[v]
            end

            local checknet
            if _net and _util_NetworkStringToID(v) == 0 then
                checknet = 2
            elseif _net and _util_NetworkStringToID(v) ~= 0 then
                checknet = 1
            end

            if checknet then
                if not badnets then 
                    badnets = {}
                end
                local jitinfo = jit.util.funcinfo(_net)
                badnets[#badnets + 1] = 'Net Message: "' .. v .. '"\nSource: ' .. jitinfo.source .. '\nLine #' .. jitinfo.linedefined .. '-' .. jitinfo.lastlinedefined
            end
        end
        if badnets then
            gAC.Print('[Anti-NetBackDoor] WARNING - Found ' .. #badnets .. ' exploitable nets, remember to keep network messages up to date!')
            gAC.Print('[Anti-NetBackDoor] List of exploitable nets have been put into gac_exploitablenets.dat in the data folder')
            local str = 'List of exploitable nets as of ' .. date .. '\n\n'
            for i = 1, #badnets do
                str = str .. badnets[i] .. '\n'
                str = str .. "-------------------------------------" .. '\n'
            end
            _file_Write('gac_exploitablenets.dat', str)
        end
    end

    do
        local badnets = nil
        for i=1, #backdoornets do
            local v = backdoornets[i]
            local _net = net.Receivers[v]
            if not _net then
                v = _string_lower(v)
                _net = net.Receivers[v]
            end
            
            if oldnetmessages[v] then
                if _isfunction(replacenetfunction[v]) and _net == replacenetfunction[v] then
                    _net = oldnetmessages[v]
                else
                    oldnetmessages[v] = true
                end
            end

            local checknet
            if _net and _util_NetworkStringToID(v) == 0 then
                checknet = 2
            elseif _net and _util_NetworkStringToID(v) ~= 0 then
                checknet = 1
            end

            if checknet then
                if not badnets then 
                    badnets = {}
                end
                local jitinfo = jit.util.funcinfo(_net)
                local id = #badnets + 1
                badnets[id] = 'Net Message: "' .. v .. '"\nSource: ' .. jitinfo.source .. '\nLine #' .. jitinfo.linedefined .. '-' .. jitinfo.lastlinedefined
                if oldnetmessages[v] == true then
                    badnets[id] = badnets[id] .. '\n' .. 'WARNING: this net message was regenerated!'
                    oldnetmessages[v] = _net
                    net.Receivers[v] = replacenetfunction[v]
                elseif not oldnetmessages[v] then
                    oldnetmessages[v] = _net
                    replacenetfunction[v] = function(len, plr)
                        gAC.AddDetection( plr, "Backdoor net message called (" .. v .. ") [Code 103]", gAC.config.BACKDOOR_EXPLOITATION_PUNISHMENT, gAC.config.BACKDOOR_EXPLOITATION_BANTIME )
                    end
                    net.Receivers[v] = replacenetfunction[v]
                end
            end
        end
        if badnets then
            gAC.Print('[Anti-NetBackDoor] WARNING - Found ' .. #badnets .. ' backdoor nets, recommend removing them immediately!')
            gAC.Print('[Anti-NetBackDoor] List of backdoor nets have been put into gac_backdoornets.dat in the data folder')
            local str = 'List of backdoors as of ' .. date .. '\n\n'
            for i = 1, #badnets do
                str = str .. badnets[i] .. '\n'
                str = str .. "-------------------------------------" .. '\n'
            end
            _file_Write('gac_backdoornets.dat', str)
            gAC.Print('[Anti-NetBackDoor] Due to this detection, backdoor nets have been re-written to detect users attempting to use them.')
        end
    end
end

local index = '__' .. gAC.Encoder.stringrandom(_math_random(8,15))
_hook_Add('Think', index, function()
    _timer_Simple(5, function()
        gAC.CheckExploitables()
    end)
    _hook_Remove('Think', index)
end)

_concommand_Add('gac_checkbackdoors', function(plr)
    if _IsValid(plr) then return end
    gAC.CheckExploitables()
end)