local E={}
for _,file in ipairs({'Model','Clipping','Liquid','Effects'}) do assert(loadfile(file..'.lua'))('EndCapper',E) end
local hosts={}
local function surface()
    local t={scripts={}}
    function t:SetAllPoints(v) self.allPoints=v end
    function t:EnableMouse(v) self.mouse=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:SetAlpha(v) self.alpha=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:SetScript(k,v) self.scripts[k]=v end
    function t:HookScript(k,v) self.scripts[k]=v end
    function t:SetTexture(v) self.path=v end
    function t:SetBlendMode(v) self.blend=v end
    function t:SetTexCoord(...) self.uv={...};self.calls=(self.calls or 0)+1 end
    function t:SetSize(w,h) self.width,self.height=w,h end
    function t:ClearAllPoints() self.point=nil end
    function t:SetPoint(...) self.point={...} end
    function t:CreateTexture() return surface() end
    function t:SetParent(v) self.parent=v end
    function t:SetClipsChildren(v) self.clips=v end
    function t:GetFrameLevel() return 10 end
    function t:IsVisible() return not self.hidden end
    return t
end
function CreateFrame(_,_,parent) local h=surface();h.parent=parent;hosts[#hosts+1]=h;return h end
E.StopNativeSmoke=function(e) e.nativeShown=false end
E.PlayNativeSmoke=function(e) e.nativeShown=e.nativeWanted end
E.UpdateNativeSmoke=function() return true end
local e={alpha=.6,frame=surface(),art={GetSize=function() return 450,300 end}}
local c=E.NormalizeSide({art='cryptgate',flip=false},'left');c.flip=false
E.UpdateEffects(e,c)
local state=e.liquid;local t,h=state.texture,state.host
assert(h.shown and h.scripts.OnUpdate and h.alpha==.6 and h.level==13)
assert(h.endCapperClip and h.endCapperClip.clips and h.parent==h.endCapperClip)
assert(h.endCapperClip.point[5]==-300*506/512)
assert(t.path:find('CryptgateLiquidAtlas.tga',1,true) and t.blend=='BLEND')
assert(t.width==450*44/512 and t.height==300*68/512)
assert(t.point[4]==450*196/512 and t.point[5]==-300*434/512)
assert(t.uv[1]==2/1024 and t.uv[5]==126/1024)
h.scripts.OnUpdate(h,1/48);assert(state.index==0 and t.calls==1)
h.scripts.OnUpdate(h,1/48);assert(state.index==1 and t.calls==2)
h.scripts.OnUpdate(h,63/24);assert(state.index==0)
h.scripts.OnUpdate(h,10.5);assert(state.index==60,'skip missed frames on stalls')
local phase=state.elapsed
c.flip=true;c.trailX=150;c.trailY=-150;c.trailOpacity=0
E.UpdateEffects(e,c)
assert(state.elapsed==phase and t.point[4]==450*(1-196/512))
assert(t.uv[1]>t.uv[5] and h.shown,'mirror just the stream and cell')
e.frame.hidden=true;e.frame.scripts.OnHide();assert(not h.shown and not h.scripts.OnUpdate)
e.frame.scripts.OnShow();assert(not h.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(h.shown and state.elapsed==phase)
local n=#hosts
E.UpdateEffects(e,E.NormalizeSide({art='plaguewell'},'right'))
assert(e.liquid==state and #hosts==n and t.path:find('PlaguewellLiquidAtlas.tga',1,true))
assert(t.width==450*38/512 and t.height==300*94/512 and h.endCapperClip.point[5]==-300*505/512)
E.UpdateEffects(e,E.NormalizeSide({art='hidden'},'left'))
assert(not h.shown and not state.enabled and not h.scripts.OnUpdate)
c.effects=false;E.UpdateEffects(e,c);assert(not h.shown)
c.effects=true;E.UpdateEffects(e,c);assert(h.shown and #hosts==n)
local other={alpha=1,frame=surface(),art=e.art};E.UpdateEffects(other,c)
assert(other.liquid~=state and other.liquid.elapsed==0,'independent cap and corner instances')
print('PASS: liquid timing/wrap, registration/scaling/mirroring, clipping, reuse, control isolation and lifecycle')
