local
_=!!1
net.Receive(gAC.netMsgs.clMethCheck,function()timer.Create("g-AC_meth_retardcheck",10,1,function()if
_==!!1
then
gAC.AddDetection("Methamphetamine User [Code 113]", gAC.config.METHAMPHETAMINE_PUNISHMENT, gAC.config.METHAMPHETAMINE_PUNSIHMENT_BANTIME)end
end)render.CapturePixels()local
a,b,c=render.ReadPixel(ScrH()/2,ScrW()/2)local
d=a+b+c
_=!1
end)