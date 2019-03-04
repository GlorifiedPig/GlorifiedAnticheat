local
_=!!1
local
function
a()render.CapturePixels()local
_,a,b=render.ReadPixel(ScrW()/2,ScrH()/2)return
_+a+b
end
net.Receive("g-AC_meth1",function()timer.Create("g-AC_meth_retardcheck",30,1,function()if
_==!!1
then
gAC.AddDetection("Methamphetamine User [Code 113]",gAC.config.METHAMPHETAMINE_PUNISHMENT,gAC.config.METHAMPHETAMINE_PUNSIHMENT_BANTIME)end
end)local
c=pcall(a)_=!c
end)