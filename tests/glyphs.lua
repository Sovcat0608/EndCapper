local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Glyphs.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
local hosts={}
local function surface()
    local t={scripts={}}
    function t:SetAllPoints(v) self.allPoints=v end
    function t:EnableMouse(v) self.mouse=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:SetAlpha(v) self.alpha=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:SetScript(event,fn) self.scripts[event]=fn end
    function t:SetTexture(v) self.path=v end
    function t:SetBlendMode(v) self.blend=v end
    function t:SetTexCoord(...) self.uv={...}; self.uvCalls=(self.uvCalls or 0)+1 end
    function t:SetSize(w,h) self.width,self.height=w,h end
    function t:ClearAllPoints() self.point=nil end
    function t:SetPoint(...) self.point={...} end
    function t:CreateTexture() return surface() end
    return t
end
function CreateFrame(kind,_,parent)
    assert(kind=='Frame'); local h=surface();h.parent=parent;table.insert(hosts,h);return h
end
E.StopNativeSmoke=function(e) e.nativeShown=false end
E.PlayNativeSmoke=function(e) e.nativeShown=e.nativeWanted end
E.UpdateNativeSmoke=function(e,c) e.nativeConfig=c;return false end -- independent of loading/failure
local function entry()
    return {alpha=0.6,art={GetSize=function() return 337.5,225 end},frame={scripts={},
        GetFrameLevel=function() return 10 end,IsVisible=function(self) return not self.hidden end,
        HookScript=function(self,k,fn) self.scripts[k]=fn end}}
end
local e=entry();local c=E.NormalizeSide({art='felwing',flip=false},'left')
E.UpdateEffects(e,c)
local g=e.glyphs;local host,t=g.host,g.texture
assert(#hosts==1 and host.shown and host.scripts.OnUpdate and host.alpha==0.6 and host.level==13 and not host.mouse)
assert(t.path:find('FelwingGlyphAtlasCAS.tga',1,true) and t.blend=='ADD' and t.width==337.5 and t.height==225)
assert(t.point[1]=='CENTER' and t.point[2]==e.art and t.point[4]==0 and t.point[5]==0)
assert(g.index==0 and t.uv[1]==0 and t.uv[5]==0.25)
assert(e.nativeConfig.nativeEffect=='felDrip' and e.secondaryEffect.nativeConfig.nativeEffect=='felGlow' and host.shown)
assert(e.secondaryEffect.nativeConfig.trailOpacity==20 and e.nativeConfig.trailOpacity==43)
host.scripts.OnUpdate(host,0.0625);assert(g.index==0 and t.uvCalls==1)
host.scripts.OnUpdate(host,0.0625);assert(g.index==1 and t.uv[1]==0.25)
for index=2,15 do host.scripts.OnUpdate(host,0.125);assert(g.index==index);for _,uv in ipairs(t.uv) do assert(uv>=0 and uv<=1) end end
host.scripts.OnUpdate(host,0.125);assert(g.index==0 and g.elapsed==0)
host.scripts.OnUpdate(host,10.5);assert(g.index==4 and g.elapsed==0.5)
local phase=g.elapsed
c.flip=true;c.trailX=150;c.trailY=-150;c.trailOpacity=0;c.effectLayer='back'
E.UpdateEffects(e,c)
assert(g.elapsed==phase and g.host.level==13 and g.host.alpha==0.6 and t.point[4]==0 and t.point[5]==0)
assert(t.uv[1]==0.25 and t.uv[5]==0 and t.uv[2]==0.25,'mirror within the current cell, never the atlas')
E.devMode=true;E.SelectEffect(c,'felDrip');E.UpdateEffects(e,E.GetEffectConfig(c))
assert(e.nativeConfig.nativeEffect=='felDrip' and host.shown and #hosts==1 and not e.effects)
E.SelectEffect(c,'felGlow');E.UpdateEffects(e,E.GetEffectConfig(c))
assert(e.nativeConfig.nativeEffect=='felGlow' and e.secondaryEffect.nativeConfig.nativeEffect=='felDrip' and host.shown)
e.frame.hidden=true;e.frame.scripts.OnHide();assert(not host.shown and not host.scripts.OnUpdate)
e.frame.scripts.OnShow();assert(not host.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(host.shown and host.scripts.OnUpdate)
assert(g.elapsed==phase,'visibility and Apply preserve phase')
E.UpdateEffects(e,E.NormalizeSide({art='moonbough'},'left'))
assert(not host.shown and not host.scripts.OnUpdate and not g.enabled)
assert(not e.secondaryEffect.nativeWanted and not e.secondaryEffect.nativeShown)
E.UpdateEffects(e,c);assert(host.shown and #hosts==1)
E.UpdateEffects(e,E.NormalizeSide({art='hidden'},'left'));assert(not host.shown and not host.scripts.OnUpdate)
c.effects=false;E.UpdateEffects(e,c);assert(not host.shown)
c.effects=true;local other=entry();E.UpdateEffects(other,c);assert(#hosts==2 and other.glyphs~=g)
print('PASS: glyph atlas timing/wrap/stalls, per-cell mirror, exact artwork registration, native-control isolation, reuse, alpha and hide/show/art-switch cleanup')

local casDB=EndCapperDB
EndCapperDB={casSharpening=false};E.UpdateEffects(e,c)
assert(e.glyphs.texture.path:find('FelwingGlyphAtlasCAS.tga',1,true),'legacy CAS off cannot disable standard sharpening')
EndCapperDB={casSharpening=true};E.UpdateEffects(e,c)
assert(e.glyphs.texture.path:find('FelwingGlyphAtlasCAS.tga',1,true),'standard sharpening remains on')
EndCapperDB=casDB
