local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Frost.lua'))('EndCapper',E)
assert(loadfile('Moonwell.lua'))('EndCapper',E)
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
    function t:SetScript(k,v) assert(k~='OnUpdate' or v==nil,'frost layers must use native animation');self.scripts[k]=v end
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
local e=entry();local c=E.NormalizeSide({art='rimeguard',flip=false},'right')
E.UpdateEffects(e,c);local s=e.frost
assert(s and #hosts==1 and #s.layers==6 and s.host.level==13 and s.host.alpha==0.6 and not s.host.mouse)
assert(not e.effects and s.host.shown and not s.host.scripts.OnUpdate)
assert(e.nativeConfig.nativeEffect=='coldFlame' and e.secondaryEffect.nativeConfig.nativeEffect=='frostEnchant')
local periods={Runes=4,Ice=6,Eyes=3}
for _,layer in ipairs(s.layers) do
    assert(layer.enabled and layer.group.playing and layer.texture.shown and layer.period==periods[layer.kind])
    assert(layer.texture.path:find('Rimeguard'..layer.suffix..'CAS.tga',1,true) and layer.texture.blend=='ADD')
    assert(layer.texture.width==225 and layer.texture.height==150 and layer.texture.uv[1]==0)
    local a,b=unpack(layer.group.animations)
    assert(a.kind=='Alpha' and b.kind=='Alpha' and a.duration+b.duration==layer.period)
    assert(a.from==b.to and a.to==b.from and a.smoothing=='IN_OUT' and b.smoothing=='IN_OUT')
end
local plays=s.layers[1].group.plays;E.PlayFrost(e);assert(s.layers[1].group.plays==plays)
now=7.5;E.devMode=true;E.SelectEffect(c,'frostEnchant');E.SetDevEffect(c,'trailX',120);E.SetDevEffect(c,'trailOpacity',0)
E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.elapsed==7.5 and s.host.point[2]==e.art and s.host.point[4]==0 and s.host.point[5]==0)
assert(e.nativeConfig.trailOpacity==0 and s.host.shown and e.secondaryEffect.nativeConfig.nativeEffect=='coldFlame')
for _,layer in ipairs(s.layers) do assert(math.abs(layer.group.offset-(7.5-layer.lag)%layer.period)<0.0001) end
c.flip=true;e.art.GetSize=function() return 450,300 end
E.UpdateEffects(e,E.GetEffectConfig(c))
for _,layer in ipairs(s.layers) do assert(layer.texture.uv[1]==1 and layer.texture.width==450 and layer.texture.height==300) end
now=8;e.frame.hidden=true;e.frame.scripts.OnHide()
assert(not s.host.shown and s.elapsed==8)
for _,layer in ipairs(s.layers) do assert(not layer.group.playing) end
now=100;E.StopFrost(e);assert(s.elapsed==8)
e.frame.scripts.OnShow();assert(not s.host.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(s.host.shown)
E.UpdateEffects(e,E.NormalizeSide({art='rimeforged'},'left'))
assert(#hosts==1)
for _,layer in ipairs(s.layers) do
    if layer.kind=='Eyes' then assert(not layer.enabled and not layer.texture.shown and not layer.group.playing)
    else assert(layer.group.playing and layer.texture.path:find('Rimeforged',1,true)) end
end
E.UpdateEffects(e,E.NormalizeSide({art='rimeguard'},'right'))
for _,layer in ipairs(s.layers) do assert(layer.enabled and layer.group.playing) end
E.UpdateEffects(e,E.NormalizeSide({art='hidden'},'left'))
assert(not s.enabled and not s.host.shown and not e.secondaryEffect.nativeWanted)
for _,layer in ipairs(s.layers) do assert(not layer.group.playing) end
local other=entry();E.UpdateEffects(other,c);assert(#hosts==2 and other.frost~=s)
c.effects=false;E.UpdateEffects(other,c);assert(not other.frost.host.shown)
print('PASS: frost independent rune/ice/eye cycles, native Alpha only, registration/mirror/resize, phase/resume, native tuning isolation and pooled eye/art cleanup')

local m=entry();local mc=E.NormalizeSide({art='moonwell',flip=false},'right')
now=0;E.UpdateEffects(m,mc);local ms=m.moonwell
assert(ms and #ms.layers==4 and ms.host.shown and not m.effects)
assert(m.nativeConfig.nativeEffect=='moonwellGlow' and m.secondaryEffect.nativeConfig.nativeEffect=='waterRipple')
local byKind={}
for _,layer in ipairs(ms.layers) do
    byKind[layer.kind]=layer
    assert(layer.texture.path:find('Moonwell'..layer.kind..'CAS.tga',1,true) and layer.texture.blend=='ADD')
    local a,b=unpack(layer.group.animations)
    assert(a.from==b.to and a.to==b.from and a.duration+b.duration==layer.period)
end
assert(byKind.Water.period==byKind.Bounce.period and byKind.Water.group.offset==byKind.Bounce.group.offset)
E.devMode=true;E.SelectEffect(mc,'waterRipple');E.SetDevEffect(mc,'trailX',110);E.SetDevEffect(mc,'trailOpacity',0)
now=7.25;E.UpdateEffects(m,E.GetEffectConfig(mc))
assert(m.nativeConfig.trailX==110 and m.nativeConfig.trailOpacity==0 and ms.host.shown)
assert(m.secondaryEffect.nativeConfig.nativeEffect=='moonwellGlow' and ms.host.point[2]==m.art)
assert(byKind.Water.group.offset==2.25 and byKind.Bounce.group.offset==2.25)
mc.flip=true;m.art.GetSize=function() return 450,300 end;E.UpdateEffects(m,E.GetEffectConfig(mc))
for _,layer in ipairs(ms.layers) do assert(layer.texture.uv[1]==1 and layer.texture.width==450) end
now=9;m.frame.hidden=true;m.frame.scripts.OnHide();assert(not ms.host.shown)
for _,layer in ipairs(ms.layers) do assert(not layer.group.playing) end
now=99;m.frame.hidden=false;m.frame.scripts.OnShow();assert(ms.elapsed==9 and ms.host.shown)
E.UpdateEffects(m,E.NormalizeSide({art='hidden'},'right'));assert(not ms.enabled and not ms.host.shown and not m.secondaryEffect.nativeWanted)
E.UpdateEffects(m,mc);assert(m.moonwell==ms and ms.host.shown)
print('PASS: Moonwell paired effects, four native pulse groups, water/bounce phase lock, mirror/resize, tuning isolation, pause/resume and cleanup')

local casDB=EndCapperDB
for _,enabled in ipairs({false,true}) do
    EndCapperDB={casSharpening=enabled}
    E.UpdateEffects(e,E.NormalizeSide({art='rimeguard'},'left'))
    for _,layer in ipairs(e.frost.layers) do
        assert(layer.texture.path:find('Rimeguard'..layer.suffix..'CAS'..'.tga',1,true))
    end
    E.UpdateEffects(m,mc)
    for _,layer in ipairs(m.moonwell.layers) do
        assert(layer.texture.path:find('Moonwell'..layer.kind..'CAS'..'.tga',1,true))
    end
end
EndCapperDB=casDB
