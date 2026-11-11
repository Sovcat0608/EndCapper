local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Halos.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
local hosts={}
local now=0
function GetTime() return now end
local function surface()
    local t={scripts={}}
    function t:EnableMouse(v) self.mouse=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:SetAlpha(v) self.alpha=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:SetScript(k,v) assert(k~='OnUpdate' or v==nil,'halo layers must use native animation');self.scripts[k]=v end
    function t:SetTexture(v,x,y,filter) self.path,self.wrapX,self.wrapY,self.filter=v,x,y,filter end
    function t:SetSnapToPixelGrid(v) self.snap=v end
    function t:SetTexelSnappingBias(v) self.bias=v end
    function t:SetBlendMode(v) self.blend=v end
    function t:SetTexCoord(...) self.uv={...} end
    function t:SetSize(w,h) self.width,self.height=w,h end
    function t:ClearAllPoints() self.point=nil end
    function t:SetPoint(...) self.point={...} end
    function t:CreateTexture() return surface() end
    function t:CreateAnimationGroup()
        local g={animations={},owner=self,plays=0}
        function g:SetLooping(v) self.loop=v end
        function g:Play(_,offset) self.playing=true;self.offset=offset;self.plays=self.plays+1 end
        function g:Stop() self.playing=false end
        function g:IsPlaying() return self.playing end
        function g:CreateAnimation(kind)
            assert(kind=='Rotation' or kind=='Translation' or kind=='Alpha');local a={kind=kind}
            function a:SetDuration(v) self.duration=v end
            function a:SetOrder(v) self.order=v end
            function a:SetSmoothing(v) self.smoothing=v end
            function a:SetOrigin(...) self.origin={...} end
            function a:SetDegrees(v) self.degrees=v end
            function a:SetTarget(v) self.target=v;return true end
            function a:SetOffset(x,y) self.x,self.y=x,y end
            function a:SetFromAlpha(v) self.from=v end
            function a:SetToAlpha(v) self.to=v end
            g.animations[#g.animations+1]=a
            return a
        end
        return g
    end
    return t
end
function CreateFrame(kind,_,parent)
    assert(kind=='Frame');local h=surface();h.parent=parent;hosts[#hosts+1]=h;return h
end
E.UpdateNativeSmoke=function(e,c) e.nativeConfig=c;return false end
local function entry()
    return {alpha=0.6,art={GetSize=function() return 225,150 end},frame={scripts={},
        GetFrameLevel=function() return 10 end,IsVisible=function(self) return not self.hidden end,
        HookScript=function(self,k,fn) self.scripts[k]=fn end}}
end
local e=entry();local c=E.NormalizeSide({art='seraph',flip=false},'right')
E.UpdateEffects(e,c);local s=e.halo
assert(s and #hosts==1 and s.host.level==11 and not s.host.mouse and s.host.alpha==0.6)
assert(s.texture.path:find('SeraphHalo.blp',1,true) and s.texture.blend=='BLEND')
assert(s.texture.wrapX=='CLAMP' and s.texture.wrapY=='CLAMP' and s.texture.filter=='TRILINEAR')
assert(s.texture.snap==false and s.texture.bias==0)
assert(s.rotation.duration==40 and s.rotation.degrees==-360 and s.group.playing and s.group.loop=='REPEAT')
assert(#s.group.animations==1 and e.nativeConfig.nativeEffect=='holyGlow' and not e.effects and e.nativeWanted)
assert(e.secondaryEffect.nativeConfig.nativeEffect=='sunRays' and not e.nativeActive and s.group.playing,'native failure must not stop the halo')
assert(s.host.point[2]==e.art and s.host.point[4]==-60 and s.host.point[5]==31)
assert(s.texture.width==116.25 and s.texture.height==116.25)
local plays=s.group.plays;E.PlayHalo(e);assert(s.group.plays==plays)
now=10;E.devMode=true;E.SetHalo(c,'period',80);E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.phase==0.25 and s.group.offset==20 and s.rotation.duration==80,'speed change preserves fractional phase')
E.SetHalo(c,'reverse',true);E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.phase==0.75 and s.rotation.degrees==360 and s.group.offset==60)
E.SetHalo(c,'opacity',25);E.SetHalo(c,'x',12);E.SetHalo(c,'y',-8);E.SetHalo(c,'size',150)
E.UpdateEffects(e,E.GetEffectConfig(c));assert(s.host.alpha==0.15 and s.host.point[4]==18 and s.host.point[5]==-8 and s.texture.width==139.5)
c.flip=true;E.UpdateEffects(e,E.GetEffectConfig(c));assert(s.host.point[4]==-18 and s.texture.uv[1]==1 and s.rotation.degrees==-360)
e.frame.hidden=true;e.frame.scripts.OnHide();local phase=s.phase
assert(not s.host.shown and not s.group.playing)
now=10000;E.StopHalo(e);e.frame.scripts.OnShow();assert(s.phase==phase and not s.host.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(s.group.playing and s.group.offset==phase*80)
E.SetHalo(c,'opacity',0);E.UpdateEffects(e,E.GetEffectConfig(c));assert(s.host.alpha==0 and e.nativeConfig.trailOpacity==11)
e.art.GetSize=function()return 450,300 end
E.UpdateEffects(e,E.GetEffectConfig(c));assert(s.texture.width==279 and s.host.point[4]==-36 and s.host.point[5]==-16)
for _,art in ipairs({'sanctum','eclipse','default','hidden'}) do
    E.UpdateEffects(e,E.NormalizeSide({art=art},'right'));assert(not s.enabled and not s.host.shown and not s.group.playing)
    if art=='sanctum' or art=='eclipse' then
        assert(e.nativeConfig.nativeEffect==(art=='sanctum' and 'holyGlow' or 'voidGlow'))
        assert(e.secondaryEffect.nativeConfig.nativeEffect==(art=='sanctum' and 'sunRays' or 'voidSmoke'))
        assert(e.nativeWanted and not e.effects,'sister effects run without halo or eye overlays')
    end
end
local sister=entry();E.UpdateEffects(sister,E.NormalizeSide({art='sanctum'},'right'))
assert(not sister.halo and #hosts==1,'a fresh non-hooded sister must not allocate a halo')
E.UpdateEffects(e,E.NormalizeSide({art='umbra'},'left'))
assert(e.halo==s and #hosts==1 and s.texture.path:find('UmbraHalo.blp',1,true) and s.phase==0)
assert(e.nativeConfig.nativeEffect=='voidGlow' and e.secondaryEffect.nativeConfig.nativeEffect=='voidSmoke' and not e.effects and e.nativeWanted)
local other=entry();E.UpdateEffects(other,c);assert(#hosts==2 and other.halo~=s)
c.effects=false;E.UpdateEffects(other,c);assert(not other.halo.enabled and not other.halo.group.playing)
-- Optional snapping methods must not prevent the halo from rendering.
s.texture.SetSnapToPixelGrid=nil;s.texture.SetTexelSnappingBias=nil
E.UpdateEffects(e,E.NormalizeSide({art='seraph'},'left'))
assert(s.group.playing and s.texture.filter=='TRILINEAR')
print('PASS: hood-only halo rotation, centre/mirror/size, phase/speed/direction, lifecycle and independence from paired native effects')
