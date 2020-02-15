local _GM = GM or GAMEMODE

local GM_CreateMove = _GM.CreateMove
local GM_StartCommand = _GM.StartCommand

local __R = debug.getregistry()

local LP = LocalPlayer()

local _GetMouseX = __R['CUserCmd']['GetMouseX']
local _GetMouseY = __R['CUserCmd']['GetMouseY']

local threshold = 0
local mx, my
local function CreateMove(self, cmd)
    if threshold > -1 then 
        if mx ~= _GetMouseX(cmd) and my ~= _GetMouseY(cmd) then
            if threshold >= 5 then
                gAC_Send("gAC-CMV", "")
                threshold = -1
            else
                threshold = threshold + 1
            end
        elseif threshold > 0 then
            threshold = threshold - 1
        end
    end
    return GM_CreateMove(self, cmd)
end

_GM['CreateMove'] = CreateMove

local function StartCommand(self, ply, cmd)
    GM_StartCommand(self, ply, cmd)
    if ply ~= LP then return end
    mx = _GetMouseX(cmd)
    my = _GetMouseY(cmd)
end

_GM['StartCommand'] = StartCommand