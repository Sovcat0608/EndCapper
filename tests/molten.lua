local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Molten.lua'))('EndCapper',E)
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
    function t:SetScript(k,v) assert(k~='OnUpdate' or v==nil,'molten layers must use native animation');self.scripts[k]=v end
    function t:SetTexture(v) self.path=v end
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
            assert(kind=='Alpha');local a={kind=kind}
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
local e=entry();local c=E.NormalizeSide({art='cinderforged',flip=false},'right')
E.UpdateEffects(e,c)
local s=e.molten
assert(s and #hosts==1 and s.host.level==13 and s.host.alpha==0.6 and not s.host.mouse)
assert(s.host.shown and not s.host.scripts.OnUpdate and #s.layers==2 and not e.effects)
assert(e.nativeConfig.nativeEffect=='fireGlow' and e.secondaryEffect.nativeConfig.nativeEffect=='fireFlame')
for _,layer in ipairs(s.layers) do
    assert(layer.texture.path:find('Cinderforged'..layer.suffix..'.tga',1,true))
    assert(layer.texture.blend=='ADD' and layer.texture.width==225 and layer.texture.height==150)
    assert(layer.group.playing and layer.group.loop=='REPEAT' and #layer.group.animations==2)
    local a,b=unpack(layer.group.animations)
    assert(a.kind=='Alpha' and b.kind=='Alpha' and a.duration+b.duration==4)
    assert(a.from==b.to and a.to==b.from and a.smoothing=='IN_OUT' and b.smoothing=='IN_OUT')
end
assert(s.host.point[2]==e.art and s.host.point[4]==0 and s.host.point[5]==0)
local plays=s.layers[1].group.plays; E.PlayMolten(e);assert(s.layers[1].group.plays==plays)
now=5.5;E.devMode=true;E.SelectEffect(c,'fireFlame');E.SetDevEffect(c,'trailX',130);E.SetDevEffect(c,'trailOpacity',0)
E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.elapsed==1.5 and s.layers[2].group.offset==1.5 and s.layers[1].group.offset==1.2)
assert(s.host.shown and s.host.point[4]==0 and e.nativeConfig.trailOpacity==0 and e.nativeConfig.trailX==130)
assert(e.secondaryEffect.nativeConfig.nativeEffect=='fireGlow' and e.secondaryEffect.nativeConfig.trailOpacity==43)
c.flip=true;e.art.GetSize=function() return 450,300 end
E.UpdateEffects(e,E.GetEffectConfig(c));assert(#hosts==1 and s.host.width==450)
for _,layer in ipairs(s.layers) do assert(layer.texture.uv[1]==1 and layer.texture.width==450 and layer.texture.height==300) end
now=6;e.frame.hidden=true;e.frame.scripts.OnHide()
assert(not s.host.shown and s.elapsed==2 and not s.layers[1].group.playing)
now=100;E.StopMolten(e);assert(s.elapsed==2)
e.frame.scripts.OnShow();assert(not s.host.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(s.host.shown and s.layers[2].group.offset==2)
E.UpdateEffects(e,E.NormalizeSide({art='cindermaw'},'left'))
assert(#hosts==1 and s.layers[2].texture.path:find('CindermawEmission.tga',1,true))
E.UpdateEffects(e,E.NormalizeSide({art='hidden'},'left'))
assert(not s.enabled and not s.host.shown and not s.layers[1].group.playing and not e.secondaryEffect.nativeWanted)
local other=entry();E.UpdateEffects(other,c);assert(#hosts==2 and other.molten~=s)
c.effects=false;E.UpdateEffects(other,c);assert(not other.molten.host.shown)
print('PASS: molten native Alpha/core-bloom timing, registration, flip/resize, independent native calibration, hide/resume, pooled art swap and cleanup')
for art,name in pairs(E.WarlockArtworks) do
    local config=E.NormalizeSide({art=art,flip=true},'left')
    E.UpdateEffects(e,config)
    assert(e.molten==s and s.host.shown and s.layers[2].group.playing)
    assert(s.layers[2].texture.path:find(name..'Emission.tga',1,true))
    assert(s.layers[1].texture.path:find(name..'Bloom.tga',1,true))
    assert(s.layers[2].texture.uv[1]==1 and s.layers[2].texture.width==450)
end
print('PASS: both warlock green emissions use registered native core/bloom Alpha pulses')
