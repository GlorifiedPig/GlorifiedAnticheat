local a = {a='name',b='Meth_Detections',c='type',d='value',e='config'}local
b=hook.Add
local
c=ipairs
local
d=print
local
e=tonumber
if(!gAC[a.e].ANTI_METH)then
return
end
local
f={{name="cl_predict",value=0,type="int"},{name="lua_error_url",value="''",type="string"}}b("gAC.ClientLoaded","g-AC.GetMethInformation",function(g)g[a.b]=0
for
h,i
in
c(f)do
if(i[a.c]=="string")then
if(g:GetInfo(i[a.a])==i[a.d])then
d("detected "..i[a.a])g[a.b]=g[a.b]+1
end
end
if(i[a.c]=="int")then
if(e(g:GetInfo(i[a.a]))==i[a.d])then
d("detected "..i[a.a])g[a.b]=g[a.b]+1
end
end
end
if(g[a.b]==#f)then
gAC.AddDetection(g,"Methamphetamine User [Code 115]",gAC[a.e].METH_PUNISHMENT,gAC[a.e].METH_BANTIME)end
end)