local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Arcane.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
local hosts={}
local now=0
local supportsSnapping=true
function GetTime() return now end
local function surface()
    local t={scripts={}}
    function t:EnableMouse(v) self.mouse=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:SetAlpha(v) self.alpha=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:SetScript(k,v) assert(k~='OnUpdate' or v==nil,'arcane layers must use native animation');self.scripts[k]=v end
    function t:SetTexture(v,x,y,filter) self.path,self.wrapX,self.wrapY,self.filter=v,x,y,filter end
    if supportsSnapping then
        function t:SetSnapToPixelGrid(v) self.snap=v end
        function t:SetTexelSnappingBias(v) self.bias=v end
    end
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
E.StopNativeSmoke=function(e) e.nativeStopped=true end
local function entry()
    return {alpha=0.6,art={GetSize=function() return 225,150 end},frame={scripts={},
        GetFrameLevel=function() return 10 end,IsVisible=function(self) return not self.hidden end,
        HookScript=function(self,k,fn) self.scripts[k]=fn end}}
end
local e=entry();local c=E.NormalizeSide({art='violetSpire',flip=false},'right')
E.UpdateEffects(e,c)
local s=e.arcane
assert(s and #hosts==2 and s.host.level==13 and not s.host.mouse and s.host.alpha==0.6)
assert(s.host.shown and s.rotationGroup.playing and s.motionGroup.playing and s.pulseGroup.playing and not s.host.scripts.OnUpdate)
assert(not e.effects and e.nativeConfig.nativeEffect=='arcaneGlow', 'no eye fallback; custom layers survive native failure')
assert(s.crystal.path:find('ArcaneCrystal.blp',1,true) and s.crystal.blend=='BLEND')
assert(s.emission.path==s.crystal.path and s.sigil.path:find('ArcaneSigil.blp',1,true))
for _,texture in ipairs({s.crystal,s.emission,s.sigil}) do
    assert(texture.wrapX=='CLAMP' and texture.wrapY=='CLAMP' and texture.filter=='TRILINEAR')
    assert(texture.snap==false and texture.bias==0)
end
assert(s.emission.blend=='ADD' and s.sigil.blend=='ADD' and s.sigil.width==s.sigil.height)
assert(s.crystal.width==60 and s.rotation.duration==24 and s.rotation.degrees==-360)
local centreX,centreY=s.host.point[4],s.host.point[5]
assert(s.host.point[5]==centreY and s.sigil.point[2]==s.host and s.sigil.point[5]==0, 'seal centre stays fixed')
assert(math.abs(s.crystal.point[5]+1.8)<0.001 and s.emission.point[5]==s.crystal.point[5])
assert(#s.motionGroup.animations==4 and #s.pulseGroup.animations==2)
for _,target in ipairs({s.crystal,s.emission}) do
    local total,duration=0,0
    for _,a in ipairs(s.motionGroup.animations) do
        if a.target==target then
            assert(a.kind=='Translation' and a.duration==3 and a.smoothing=='IN_OUT' and a.x==0)
            assert(math.abs(a.y-(a.order==1 and 3.6 or -3.6))<0.001)
            total=total+a.y;duration=duration+a.duration
        end
    end
    assert(total==0 and duration==6,'both targets share a closed six-second path')
end
assert(s.pulseGroup.owner==s.emission and s.crystal.alpha==nil)
for i,a in ipairs(s.pulseGroup.animations) do
    assert(a.kind=='Alpha' and a.order==i and a.duration==2 and a.smoothing=='IN_OUT')
    assert(a.from==(i==1 and 0.08 or 0.38) and a.to==(i==1 and 0.38 or 0.08))
end
assert(#s.rotationGroup.animations==1 and s.rotationGroup.owner==s.sigil,'seal receives only rotation')
local plays=s.motionGroup.plays;E.PlayArcane(e);assert(s.motionGroup.plays==plays,'redundant show must not restart')
now=8.5;local phase=8.5
local crystalWidth=s.crystal.width
E.devMode=true;E.SetSealSize(c,200);E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.sigil.width==157.5 and s.crystal.width==crystalWidth and s.host.point[4]==centreX and s.host.point[5]==centreY)
assert(s.elapsed==phase and s.rotationGroup.offset==phase and e.nativeConfig.trailSize==150)
assert(s.motionGroup.offset==2.5 and s.pulseGroup.offset==0.5,'native groups resume at their own cycle offsets')
E.SetSealSize(c,100)
E.devMode=true;E.SetDevEffect(c,'trailX',100);E.SetDevEffect(c,'trailOpacity',0)
E.UpdateEffects(e,E.GetEffectConfig(c))
assert(s.elapsed==phase and s.rotationGroup.offset==phase and s.host.point[4]==centreX)
assert(s.host.shown and e.nativeConfig.trailOpacity==0, 'native controls do not mute crystal/sigil')
c.flip=true;E.UpdateEffects(e,E.GetEffectConfig(c))
assert(math.abs(s.host.point[4]+centreX-225)<0.001 and s.crystal.uv[1]==1 and s.sigil.uv[1]==1)
assert(s.rotation.degrees==360 and s.elapsed==phase and #hosts==2)
e.frame.hidden=true;e.frame.scripts.OnHide()
assert(not s.host.shown and not s.host.scripts.OnUpdate and not s.rotationGroup.playing and not s.motionGroup.playing and not s.pulseGroup.playing)
now=now+100;E.StopArcane(e);assert(s.elapsed==phase,'hidden/repeated stop must not advance phase')
e.frame.scripts.OnShow();assert(not s.host.shown)
e.frame.hidden=false;e.frame.scripts.OnShow();assert(s.host.shown and s.rotationGroup.offset==phase)
E.UpdateEffects(e,E.NormalizeSide({art='hidden'},'left'))
assert(not s.enabled and not s.host.scripts.OnUpdate and not s.rotationGroup.playing)
e.art.GetSize=function() return 450,300 end
E.UpdateEffects(e,E.GetEffectConfig(c));assert(#hosts==2 and s.crystal.width==120 and s.sigil.width==157.5)
assert(math.abs(s.host.point[4]-(450-2*centreX))<0.001)
for _,t in ipairs(s.translations) do assert(math.abs(t.animation.y-t.direction*7.2)<0.001) end
local other=entry();E.UpdateEffects(other,c);assert(#hosts==4 and other.arcane~=s)
now=now+48;E.StopArcane(e);assert(s.elapsed==phase,'transition clock wraps to a bounded phase')
E.PlayArcane(e);assert(s.rotationGroup.offset==phase and s.motionGroup.offset==phase%6)
assert(s.sigil.point[5]==0 and not s.host.scripts.OnUpdate and not s.tick)
c.effects=false;E.UpdateEffects(e,c);assert(not s.rotationGroup.playing and not s.motionGroup.playing and not s.pulseGroup.playing)
supportsSnapping=false
local optional=entry();E.UpdateEffects(optional,E.NormalizeSide({art='violetSpire'},'left'))
assert(optional.arcane.motionGroup.playing and optional.arcane.rotationGroup.playing)
assert(optional.arcane.emission.filter=='TRILINEAR')
print('PASS: native arcane Translation/Alpha/Rotation, shared shard-emission motion, fixed seal, no OnUpdate, phase/resume, pooling and tuning isolation')

-- The same pooled host changes to a separate hovering soul shard, with no seal.
local soul=E.NormalizeSide({art='soulbound',flip=false},'right')
E.UpdateEffects(e,soul)
assert(e.arcane==s and s.host.shown and s.motionGroup.playing and s.pulseGroup.playing)
assert(not s.rotationGroup.playing and not s.sigil.shown)
assert(s.crystal.path:find('SoulboundCrystal.blp',1,true))
assert(s.emission.path:find('SoulboundCrystalEmission.blp',1,true))
assert(s.crystal.point[5]==s.emission.point[5] and s.crystal.height==s.emission.height)
assert(s.host.point[4]==450*0.30 and s.host.point[5]==-300*0.175)
assert(s.crystal.width==300*0.44 and s.crystal.height==300*0.32)
E.devMode=true
E.SelectEffect(soul,'shadowGlow');E.SetDevEffect(soul,'trailY',140)
E.UpdateEffects(e,E.GetEffectConfig(soul))
assert(s.host.point[5]==-300*0.175,'native effect tuning must not move the shard')
soul.flip=true;E.UpdateEffects(e,E.GetEffectConfig(soul))
assert(s.host.point[4]==450*0.70 and s.crystal.uv[1]==1)
E.UpdateEffects(e,E.NormalizeSide({art='violetSpire'},'right'))
assert(s.sigil.shown and s.rotationGroup.playing and s.crystal.path:find('ArcaneCrystal.blp',1,true))
E.UpdateEffects(e,E.NormalizeSide({art='hexbound'},'left'))
assert(not s.host.shown and not s.motionGroup.playing and not s.pulseGroup.playing)
print('PASS: Soulbound shard uses shared native hover and emission motion, mirrored registration, independent tuning and clean art transitions')

