gAC_AddReceiver("g-AC_RenderHack_Checks", function(_, data)
    data = util.JSONToTable(data)
    for k, v in ipairs(data) do
        RunConsoleCommand(unpack({v[tonumber(1)], v[tonumber(2)]}))
    end
    gAC_Send("g-AC_RenderHack_Checks", "")
end)