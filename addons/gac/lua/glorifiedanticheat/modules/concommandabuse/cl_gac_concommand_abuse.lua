local _concommand_Add = concommand.Add
local _pairs = pairs
local _util_JSONToTable = util.JSONToTable
local _concommand_GetTable = concommand.GetTable

if !gAC.config.ILLEGAL_CONCOMMAND_CHECKS then 
    return 
end 

local TBL = nil
local Logged = {}

local a = _concommand_GetTable()
for k, v in _pairs(a) do
    Logged[#Logged + 1] = k
end

concommand.Add = function(name, callback, autoComplete, helpText, flags, ...)
    if TBL == nil then
        Logged[#Logged + 1] = name
    else
        local notbad = true
        for d,f in _pairs(TBL)do 
            if(name==f)then 
                notbad = false 
            end 
        end 
        if !notbad then 
            gAC_Send("g-ACIllegalConCommand", "")
            return 
        end 
    end
    _concommand_Add(name, callback, autoComplete, helpText, flags, ...)
end

gAC_AddReceiver("g-ACReceiveExploitList", function(data)
    TBL = _util_JSONToTable(data)
    if Logged then
        local notbad = true
        for k=1, #Logged do
            local v = Logged[k]
            for d,f in _pairs(TBL)do
                if v == f then 
                    notbad = false 
                end
            end
        end
        if !notbad then 
            gAC_Send("g-ACIllegalConCommand", "")
        end 
        Logged = nil
    end
end)

gAC_Send("g-ACReceiveExploitListCS", "")