local
_,a,b,c,d={_="BP_Detections"},hook.Add,print,tonumber,util.TableToJSON
if!gAC.config.ANTI_BP
then
return
end
local
e,f={{name="cl_interp",value=0,correct_value=0.1},{name="cl_interp_ratio",value=1,correct_value=2}},{}for
a=1,#e
do
local
b=e[a]f[#f+1]={b.name,b.correct_value}end
f=d(f)a("gAC.CLFilesLoaded","g-AC_GetBPInformation",function(a)a[_._]=0
gAC.Network:Send("g-AC_RenderHack_Checks",f,a)end)gAC.Network:AddReceiver("g-AC_RenderHack_Checks",function(a,b,d)for
a=1,#e
do
local
b=e[a]if(c(d:GetInfo(b.name))==b.value)then
d[_._]=d[_._]+1
end
end
if(d[_._]==#e)then
gAC.AddDetection(d,"Bigpackets User [Code 118]",gAC.config.BP_PUNISHMENT,gAC.config.BP_BANTIME)end
end)b"[g-AC] Loaded BigPackets"