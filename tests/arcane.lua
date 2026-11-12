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
    function t:SetScript(k,v) self.scripts[k]=v end
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
        function g:Play(_,offset)
            if not self.paused or offset~=nil then self.offset=offset end
            self.playing=true;self.paused=false;self.plays=self.plays+1
        end
        function g:Pause() self.playing=false;self.paused=true end
        function g:Stop() self.playing=false;self.paused=false end
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
E.PlayNativeSmoke=function(e) e.nativePlayed=true end
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
assert(s.crystal.path:find('ArcaneCrystalCASSize256.tga',1,true) and s.crystal.blend=='BLEND')
assert(s.emission.path==s.crystal.path and s.sigil.path:find('ArcaneSigilCASSize256.tga',1,true))
for _,texture in ipairs({s.crystal,s.emission,s.sigil}) do
    assert(texture.wrapX==nil and texture.wrapY==nil and texture.filter==nil)
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
assert(optional.arcane.emission.filter==nil)
print('PASS: native arcane Translation/Alpha/Rotation, shared shard-emission motion, fixed seal, no OnUpdate, phase/resume, pooling and tuning isolation')

-- The same pooled host changes to a separate hovering soul shard, with no seal.
local soul=E.NormalizeSide({art='soulbound',flip=false},'right')
E.UpdateEffects(e,soul)
assert(e.arcane==s and s.host.shown and s.motionGroup.playing and s.pulseGroup.playing)
assert(not s.rotationGroup.playing and not s.sigil.shown)
assert(s.crystal.path:find('SoulboundCrystalCASSize256.tga',1,true))
assert(s.emission.path:find('SoulboundCrystalEmissionCASSize256.tga',1,true))
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
assert(s.sigil.shown and s.rotationGroup.playing and s.crystal.path:find('ArcaneCrystalCASSize256.tga',1,true))
E.UpdateEffects(e,E.NormalizeSide({art='hexbound'},'left'))
assert(not s.host.shown and not s.motionGroup.playing and not s.pulseGroup.playing)
print('PASS: Soulbound shard uses shared native hover and emission motion, mirrored registration, independent tuning and clean art transitions')

-- Native Translation moves the dedicated boat frame, preserving texture rendering.
assert(loadfile('Skycutter.lua'))('EndCapper',E)
supportsSnapping=true
local priorPhysicalScreenSize=GetPhysicalScreenSize
local screenHeight=768
GetPhysicalScreenSize=function() return 1366,screenHeight end
local ship=entry();ship.artLayer=surface();ship.mode='end';ship.side='right'
ship.frame.GetEffectiveScale=function()return 1 end
E.devMode=true
local createFrameBeforeSkycutter=CreateFrame
function CreateFrame(kind,name,parent)
    local host=createFrameBeforeSkycutter(kind,name,parent)
    function host:CreateTexture(_,layer,_,sublevel)
        local t=surface();t.layer=layer;t.sublevel=sublevel;t.parent=self
        function t:SetTexture(path, ...) assert(select('#',...)==0,'Restore sharp baseline texture defaults');self.path=path end
        function t:SetBlendMode() error('Leave blend mode at baseline default') end
        if supportsSnapping then function t:SetSnapToPixelGrid(v) assert(v==false,'Disable only pixel-grid snapping');self.snap=v end end
        if supportsSnapping then function t:SetTexelSnappingBias(v) assert(v==0,'Disable texel snapping only');self.bias=v end end

        return t
    end
    return host
end
local hostCount=#hosts
local shipConfig=E.NormalizeSide({art='skycutter',flip=false},'right')
E.UpdateEffects(ship,shipConfig)
local boat=ship.skycutter
assert(#hosts==hostCount+1 and not boat.host.scripts.OnUpdate and not boat.driver and not boat.tick and not boat.boat.scripts.OnUpdate)
assert(boat.motion.owner==boat.host and boat.motion.loop=='REPEAT' and boat.motion.playing)
assert(boat.boat.layer=='ARTWORK' and boat.boat.sublevel==0 and boat.boat.parent==boat.host and boat.boat.blend==nil)
assert(boat.boat.path:find('SkycutterBoatCASSize288.tga',1,true) and boat.boat.filter==nil)
assert(boat.boat.snap==false and boat.boat.bias==0 and boat.boat.alpha==.6 and boat.boat.shown)
local function registered(w,h,animated)
    assert(boat.boat.width==w and boat.boat.height==h)
    assert(boat.host.width==w and boat.host.height==h and boat.host.parent==ship.frame)
    assert(boat.host.level==12 and ship.artLayer.level==13 and boat.host.mouse==false)
    assert(boat.boat.point[2]==boat.host and boat.boat.point[4]==0 and boat.boat.point[5]==0)
    local point=boat.host.point
    assert(point[1]=='CENTER' and point[2]==ship.art and point[3]=='CENTER' and point[4]==0)
    local amplitude=animated and h*.012 or 0
    assert(math.abs(point[5]+amplitude)<.000001)
    assert(#boat.motion.animations==2)
    local total=0
    for i,a in ipairs(boat.motion.animations) do
        assert(a.kind=='Translation' and a.order==i and a.duration==3 and a.smoothing=='IN_OUT' and a.x==0)
        assert(math.abs(a.y-(i==1 and 2 or -2)*amplitude)<.000001)
        total=total+a.y
    end
    assert(total==0,'Native return leg must close the six-second loop')
end
registered(225,150,true)
assert(boat.rock.owner==boat.boat and boat.rock.loop=='REPEAT' and boat.rock.playing)
local rockDuration,rockDegrees=0,0
for i,a in ipairs(boat.rock.animations) do
    assert(a.kind=='Rotation' and a.order==i and a.origin[1]=='CENTER')
    assert(a.duration==({1.75,3.5,1.75})[i] and a.smoothing==({'OUT','IN_OUT','IN'})[i])
    assert(a.degrees==({3,-6,3})[i])
    rockDuration=rockDuration+a.duration;rockDegrees=rockDegrees+a.degrees
end
assert(rockDuration==7 and rockDegrees==0,'Independent seven-second closed rocking cycle')
assert(boat.starts==1 and boat.updates==1)
assert(E.SkycutterHoverStatus(ship):find('restarts=0, updates=1, current run=0.0s',1,true))
now=now+12
local beforeStatus=boat.motion.plays
assert(E.SkycutterHoverStatus(ship):find('current run=12.0s',1,true))
assert(boat.starts==1 and boat.updates==1 and boat.motion.plays==beforeStatus,'Reading counters and native loops must not restart motion')
local plays=boat.motion.plays;E.PlaySkycutter(ship);assert(boat.motion.plays==plays,'Repeated show must not restart hover')
now=now+7;E.UpdateEffects(ship,shipConfig);registered(225,150,true)
assert(boat.elapsed==19 and boat.motion.offset==1 and boat.rock.offset==5,'Apply preserves both independent cycle phases')
assert(boat.starts==2 and boat.updates==2 and E.SkycutterHoverStatus(ship):find('restarts=1',1,true))
ship.art.GetSize=function()return 400.5,267 end
E.UpdateEffects(ship,shipConfig);registered(400.5,267,true)
assert(boat.motion.offset==1)
shipConfig.flip=true;ship.art.GetSize=function()return 450,300 end
E.UpdateEffects(ship,shipConfig);registered(450,300,true);assert(boat.boat.uv[1]==480/512)
assert(boat.rock.animations[1].degrees==-3 and boat.rock.animations[2].degrees==6,'Mirrored rocking direction')
shipConfig.nativeSmoke=false;E.UpdateEffects(ship,shipConfig)
assert(boat.motion.playing,'Native effect toggle does not stop artwork hover')
ship.frame.hidden=true;ship.frame.scripts.OnHide()
assert(not boat.boat.shown and not boat.host.shown and not boat.motion.playing and boat.elapsed==19 and not boat.startedAt)
assert(not boat.rock.playing)
local phase=boat.elapsed;local stoppedStarts=boat.starts;now=now+20;E.StopSkycutter(ship);assert(boat.elapsed==phase)
assert(boat.starts==stoppedStarts and E.SkycutterHoverStatus(ship):find('current run=stopped',1,true))
ship.frame.scripts.OnShow();assert(not boat.boat.shown and not boat.host.shown and not boat.motion.playing)
ship.frame.hidden=false;ship.frame.scripts.OnShow()
assert(boat.boat.shown and boat.host.shown and boat.motion.playing and boat.motion.offset==1)
assert(boat.rock.playing and boat.rock.offset==5,'Show resumes independent rocking phase')
now=now+2;shipConfig.effects=false;E.UpdateEffects(ship,shipConfig)
assert(boat.boat.shown and boat.host.shown and not boat.motion.playing and not boat.startedAt and boat.elapsed==21)
assert(not boat.rock.playing,'Effects off returns both native transforms to static art')
registered(450,300,false)
now=now+20;E.UpdateEffects(ship,shipConfig);registered(450,300,false);assert(boat.elapsed==21)
shipConfig.effects=true;E.UpdateEffects(ship,shipConfig);registered(450,300,true)
assert(boat.motion.playing and boat.motion.offset==3)
assert(boat.rock.playing and boat.rock.offset==0)
local opposite=entry();opposite.artLayer=surface();opposite.mode='end';opposite.side='left'
E.UpdateEffects(opposite,shipConfig)
local corner=entry();corner.artLayer=surface();corner.mode='corner';corner.side='right'
E.UpdateEffects(corner,shipConfig)
assert(opposite.skycutter.motion~=boat.motion and corner.skycutter.motion~=boat.motion)
assert(opposite.skycutter.rock~=boat.rock and corner.skycutter.rock~=boat.rock)
assert(opposite.skycutter.starts==1 and corner.skycutter.starts==1 and boat.starts>1)
E.UpdateEffects(ship,E.NormalizeSide({art='zephyr'},'right'))
assert(not boat.enabled and not boat.boat.shown and not boat.host.shown and not boat.motion.playing)
assert(not boat.rock.playing and opposite.skycutter.rock.playing and corner.skycutter.rock.playing)
assert(opposite.skycutter.boat.shown and opposite.skycutter.motion.playing and corner.skycutter.motion.playing)
E.UpdateEffects(ship,shipConfig);assert(ship.skycutter==boat and boat.boat.shown and boat.host.shown and boat.motion.playing)
registered(450,300,true);assert(#hosts==hostCount+3 and boat.motion.offset==3)
assert(not E.SetSkycutterComparison and not E.GetSkycutterComparison and not E.RefreshSkycutterComparisons)
E.devMode=false;E.UpdateEffects(ship,shipConfig)
assert(boat.boat.filter==nil and corner.skycutter.boat.filter==nil and opposite.skycutter.boat.filter==nil)
print('PASS: Skycutter eased native six-second parent-frame Translation, sharp sampler with size-specific TGA trial, no OnUpdate/driver, scaled closed loop, Apply/hide phase, effects-off static art, pooling and side/mode isolation')

-- Optional snapping API absence must not prevent artwork/animation loading.
supportsSnapping=false
local fallback=entry();fallback.artLayer=surface()
E.UpdateEffects(fallback,shipConfig)
assert(fallback.skycutter.motion.playing and fallback.skycutter.boat.filter==nil and fallback.skycutter.boat.bias==nil)
print('PASS: Skycutter pixel and texel snapping disabled, baseline sampler retained, absent-API fallback and read-only per-instance restart counters')

-- Physical display size, per-frame effective scale, crop UVs and safe fallback.
for _,w in ipairs({192,288,384,480,576,768,960}) do
    ship.art.GetSize=function()return w,w*2/3 end
    E.UpdateEffects(ship,shipConfig)
    assert(boat.boat.path:find('SkycutterBoatCASSize'..w..'.tga',1,true))
    assert(boat.textureSize==string.format('%dx%d CAS',w,w*2/3))
    local tw=2^math.ceil(math.log(w)/math.log(2))
    local th=2^math.ceil(math.log(w*2/3)/math.log(2))
    assert(math.abs(boat.boat.uv[1]-w/tw)<.000001 and math.abs(boat.boat.uv[4]-(w*2/3)/th)<.000001)
end
ship.art.GetSize=function()return 225,150 end
screenHeight=2160;ship.frame.GetEffectiveScale=function()return .8 end
E.UpdateEffects(ship,shipConfig);assert(boat.textureSize=='576x384 CAS')
ship.frame.GetEffectiveScale=function()return .5 end
E.UpdateEffects(ship,shipConfig);assert(boat.textureSize=='384x256 CAS')
screenHeight=0;E.UpdateEffects(ship,shipConfig);assert(boat.textureSize=='baseline' and boat.boat.uv[1]==1)
GetPhysicalScreenSize=nil;E.UpdateEffects(ship,shipConfig);assert(boat.textureSize=='baseline')
GetPhysicalScreenSize=function()return 3840,2160 end
ship.art.GetSize=function()return 3000,2000 end
E.UpdateEffects(ship,shipConfig);assert(boat.textureSize=='baseline')
assert(E.SkycutterHoverStatus(ship):find('texture=baseline',1,true))
GetPhysicalScreenSize=priorPhysicalScreenSize
print('PASS: size-specific TGA physical-pixel selection, all UV ranges, resolution/effective-scale changes and baseline fallbacks')
CreateFrame=createFrameBeforeSkycutter
-- CAS layers follow their own displayed sizes, including padded UVs and mirroring.
local savedPhysical=GetPhysicalScreenSize
GetPhysicalScreenSize=function()return 1366,768 end
supportsSnapping=true
local sharpEntry=entry();sharpEntry.frame.GetEffectiveScale=function()return 1 end
for _,size in ipairs({64,96,128,192,256}) do
    sharpEntry.art.GetSize=function()return size*3.75,size*2.5 end
    for _,flip in ipairs({false,true}) do
        E.UpdateEffects(sharpEntry,E.NormalizeSide({art='violetSpire',flip=flip,sealSize=100},'right'))
        local a=sharpEntry.arcane
        local backing=2^math.ceil(math.log(size)/math.log(2));local u=size/backing
        assert(a.crystal.path:find('ArcaneCrystalCASSize'..size..'.tga',1,true))
        assert(a.crystal.path==a.emission.path and a.crystal.filter==nil and a.sigil.filter==nil)
        assert(a.crystal.uv[1]==(flip and u or 0) and a.crystal.uv[4]==u)
        assert(a.emission.uv[1]==a.crystal.uv[1] and a.emission.uv[4]==u)
        assert(a.crystal.snap==false and a.crystal.bias==0 and a.sigil.bias==0)
        assert(a.sigil.point[5]==0 and a.rotationGroup.playing)
    end
end
sharpEntry.art.GetSize=function()return 225,150 end
E.UpdateEffects(sharpEntry,E.NormalizeSide({art='soulbound',flip=false},'right'))
assert(sharpEntry.arcane.crystal.path:find('SoulboundCrystalCASSize96.tga',1,true))
assert(sharpEntry.arcane.emission.path:find('SoulboundCrystalEmissionCASSize96.tga',1,true))
assert(sharpEntry.arcane.crystal.uv[4]==.75 and not sharpEntry.arcane.sigil.shown)
GetPhysicalScreenSize=function()return 3840,2160 end
E.UpdateEffects(sharpEntry,E.NormalizeSide({art='soulbound'},'right'))
assert(sharpEntry.arcane.crystal.path:find('CASSize192.tga',1,true))
sharpEntry.frame.GetEffectiveScale=function()return .5 end
E.UpdateEffects(sharpEntry,E.NormalizeSide({art='soulbound'},'right'))
assert(sharpEntry.arcane.crystal.path:find('CASSize96.tga',1,true))
GetPhysicalScreenSize=nil
E.UpdateEffects(sharpEntry,E.NormalizeSide({art='soulbound'},'right'))
assert(sharpEntry.arcane.crystal.path:find('CASSize256.tga',1,true))
GetPhysicalScreenSize=savedPhysical
print('PASS: independent rocking timeline and CAS crystal/emission/seal sizes, UVs, mirroring, scale and fallback')

local casDB=EndCapperDB
local beforePhase=(ship.skycutter.elapsed+now-ship.skycutter.startedAt)%42
for _,enabled in ipairs({false,true}) do
    EndCapperDB={casSharpening=enabled}
    local suffix='CASSize'
    GetPhysicalScreenSize=function()return 1366,768 end
    sharpEntry.frame.GetEffectiveScale=function()return 1 end
    E.UpdateEffects(sharpEntry,E.NormalizeSide({art='soulbound'},'right'))
    assert(sharpEntry.arcane.crystal.path:find('SoulboundCrystal'..suffix..'96.tga',1,true))
    assert(sharpEntry.arcane.emission.path:find('SoulboundCrystalEmission'..suffix..'96.tga',1,true))
    assert(sharpEntry.arcane.crystal.uv[4]==.75 and sharpEntry.arcane.crystal.bias==0)
    E.UpdateEffects(sharpEntry,E.NormalizeSide({art='violetSpire'},'right'))
    assert(sharpEntry.arcane.sigil.path:find('ArcaneSigil'..suffix,1,true))
    E.UpdateEffects(ship,shipConfig)
    assert(ship.skycutter.boat.path:find('CAS',1,true))
    assert(ship.skycutter.boat.bias==0 and ship.skycutter.elapsed==beforePhase and ship.skycutter.motion.offset==beforePhase%6 and ship.skycutter.rock.offset==beforePhase%7,'CAS preserves boat animation phase')
end
GetPhysicalScreenSize=savedPhysical;EndCapperDB=casDB
print('PASS: standard CAS ignores legacy flags and preserves size, UV, texel settings and boat motion')
