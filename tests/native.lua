local E = {}
assert(loadfile("Model.lua"))("EndCapper", E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile("Effects.lua"))("EndCapper", E)
assert(loadfile("NativeSmoke.lua"))("EndCapper", E)
local queue, scenes, mode, combat, scheduled = {}, {}, "ready", false, 0
function InCombatLockdown() return combat end
C_Timer = {After = function(_, fn) table.insert(queue, fn) end}
E.Schedule = function() scheduled = scheduled+1 end
local function tick()
    local callbacks = queue; queue = {}
    for _, fn in ipairs(callbacks) do fn() end
end
function CreateFrame(kind)
    assert(kind == "ModelScene")
    if mode == "unsupported" then error("unsupported scene") end
    local s = {}
    for _, key in ipairs({"SetCameraNearClip", "SetCameraFarClip", "SetCameraPosition", "SetCameraOrientationByAxisVectors",
        "SetCameraFieldOfView", "SetLightAmbientColor", "SetLightDiffuseColor", "SetDrawLayer", "EnableMouse", "SetFrameLevel", "SetDesaturation"}) do
        s[key] = function(self, ...) self[key .. "Value"] = {...} end
    end
    function s:Show() self.shown = true end
    function s:Hide() self.shown = false end
    function s:SetAlpha(v) self.alpha = v end
    function s:SetSize(w,h) self.width,self.height = w,h end
    function s:ClearAllPoints() self.point = nil end
    function s:SetPoint(...) self.point = {...} end
    function s:CreateActor(_, template)
        assert(template == "EndCapperSmokeActorTemplate")
        local a = {ready = mode == "ready"}
        function a:ClearModel() self.ready=false; self.fileID=nil end
        function a:SetModelByFileID(id)
            self.fileID=id; self.ready=mode=="ready" or mode=="sync"
            self.modelCalls=(self.modelCalls or 0)+1
            if mode=="sync" and self.endCapperOnModelLoaded then self.endCapperOnModelLoaded() end
            return mode~="reject"
        end
        function a:GetModelFileID() return self.fileID end
        function a:IsLoaded() return self.ready end
        function a:SetAnimation(...) self.animation = {...}; self.animationCalls=(self.animationCalls or 0)+1 end
        function a:SetScale(v) self.scale = v end
        function a:SetYaw(v) self.yaw = v end
        function a:SetPitch(v) self.pitch = v end
        function a:SetRoll(v) self.roll = v end
        function a:SetPosition(x,y,z) self.x,self.y,self.z = x,y,z end
        function a:Show() self.shown = true end
        self.actor = a; return a
    end
    table.insert(scenes,s); return s
end
local function entry()
    return {alpha = 0.8, effectsEnabled = true, nativeWanted = true,
        frame = {HookScript = function(self, event, fn) self[event]=fn end, IsVisible = function(self) return not self.hidden end, GetFrameLevel = function() return 10 end},
        art = {GetSize = function(self) return self.width or 150, self.height or self.width or 150 end}}
end
local left, right = entry(), entry()
assert(E.UpdateNativeSmoke(left,{flip=false}) and E.UpdateNativeSmoke(right,{flip=true}))
assert(#scenes == 2 and #left.nativeSmoke.slots==1 and #right.nativeSmoke.slots==1 and left.nativeSmoke.status == "ready")
local l,r = left.nativeSmoke.slots[1],right.nativeSmoke.slots[1]
assert(l.actor.fileID == 165995 and r.actor.fileID == 165995)
assert(math.abs(l.scene.alpha-0.64)<0.001, "native opacity follows cap")
local function projected(slot, px, pz)
    local axis = slot.scene.SetCameraOrientationByAxisVectorsValue
    local x,z = slot.actor.x+px,slot.actor.z+pz
    local density = slot.scene.width/6
    return slot.scene.point[4]+(x*axis[4]+z*axis[6])*density,
        slot.scene.point[5]+(x*axis[7]+z*axis[9])*density
end
-- Validate the measured emitter's projection, including both facings,
-- rotated views, cap scale, independent effect zoom and origin nudges.
for _, flip in ipairs({false,true}) do
    for _, angle in ipairs({-180,-90,0,14,90,180}) do
        for _, width in ipairs({75,150,300}) do
            left.art.width=width
            local c={flip=flip,trailAngle=angle,trailSize=175,trailX=7,trailY=-3}
            assert(E.UpdateNativeSmoke(left,c))
            for _, slot in ipairs(left.nativeSmoke.slots) do
                local x,y = projected(slot, -0.1388888955, 0)
                local ex,ey,dir = E.EyeAnchor(slot.eye,width,width,flip)
                local scale = width/150*slot.eye.scale
                assert(math.abs(x-ex-dir*7*scale)<0.001 and math.abs(y-ey+3*scale)<0.001,
                    "measured emitter stays on centre-relative origin through roll, mirror and zoom")
            end
        end
    end
end
left.art.width=150
E.UpdateNativeSmoke(left,{flip=false}); assert(#scenes == 2, "reuse existing scenes")
local cx,cy=projected(l,-0.1388888955,0)
assert(math.abs(cx-75)<0.001 and math.abs(cy+75)<0.001, "0/0 is the full skull centre")
local fov=l.scene.SetCameraFieldOfViewValue[1]
assert(math.abs(l.scene.width/(2*8*math.tan(fov/2))-48)<0.001, "expanded viewport preserves apparent model size")
assert(l.scene.width==288, "three times the render room")
left.art.width = 300; E.UpdateNativeSmoke(left,{flip=false}); assert(l.scene.width == 576)
E.StopNativeSmoke(left); assert(not l.scene.shown)
left.frame.hidden = true; E.PlayNativeSmoke(left); assert(not l.scene.shown)
left.frame.hidden = false; E.PlayNativeSmoke(left); assert(l.scene.shown)
left.nativeWanted = false; E.StopNativeSmoke(left); assert(not E.UpdateNativeSmoke(left,{flip=false}))
E.PlayNativeSmoke(left); assert(not l.scene.shown, "manual painted option stays selected")
left.nativeWanted=true
left.art.width=150
E.UpdateNativeSmoke(left,{nativeEffect="soulfrost"})
assert(#scenes==2 and l.actor.fileID==166026, "switch model without allocating more scenes")
local sx,sy=projected(l,0,0)
assert(math.abs(sx-75)<0.001 and math.abs(sy+75)<0.001)
mode = "pending"
local delayed = entry()
assert(not E.UpdateNativeSmoke(delayed,{flip=false}))
assert(delayed.nativeSmoke.status == "loading" and #queue == 1)
for _,slot in ipairs(delayed.nativeSmoke.slots) do slot.actor.ready=true end
tick(); assert(delayed.nativeSmoke.status == "ready" and scheduled == 1)
assert(E.UpdateNativeSmoke(delayed,{flip=true}), "async readiness enables native renderer")
local switched = entry(); E.UpdateNativeSmoke(switched,{})
E.UpdateNativeSmoke(switched,{nativeEffect="soulfrost"})
tick()
assert(switched.nativeSmoke.attempts==1, "stale callback cannot consume replacement load budget")
mode="ready"
E.UpdateNativeSmoke(switched,{nativeEffect="coldFlame"})
tick(); assert(switched.nativeSmoke.status=="ready")
mode="pending"
local timeout = entry(); E.UpdateNativeSmoke(timeout,{flip=false})
for i=1,16 do tick() end
assert(timeout.nativeSmoke.status == "unavailable" and #queue == 0, "bounded load timeout")
assert(not timeout.nativeSmoke.slots[1].scene.shown)
mode = "reject"
local rejected = entry(); assert(not E.UpdateNativeSmoke(rejected,{flip=false}))
assert(rejected.nativeSmoke.status == "unavailable" and not rejected.nativeSmoke.slots[1].scene.shown)
mode="ready"
assert(E.UpdateNativeSmoke(rejected,{nativeEffect="soulfrost"}), "another curated candidate recovers from rejection")
mode = "unsupported"
local unsupported = entry(); assert(not E.UpdateNativeSmoke(unsupported,{flip=false}))
assert(unsupported.nativeSmoke.status == "unavailable")
mode = "ready"; combat = true
local deferred = entry(); assert(not E.UpdateNativeSmoke(deferred,{flip=false}) and not deferred.nativeSmoke and E.pending)
combat = false
-- Exercise the renderer handoff through the real Effects.lua path.
local integrated = entry()
local config = E.NormalizeSide(nil,"left")
E.UpdateEffects(integrated,config)
assert(integrated.nativeActive and integrated.nativeSmoke.slots[1].scene.shown)
integrated.nativeSmoke.slots[1].actor.ready=false
for _,status in ipairs({'loading','unavailable'}) do
    integrated.nativeSmoke.status=status
    E.UpdateEffects(integrated,config)
    assert(not integrated.nativeActive and integrated.nativeSmoke.slots[1].scene.alpha==0)
end
config.nativeSmoke=false; E.UpdateEffects(integrated,config)
assert(not integrated.nativeActive and not integrated.nativeSmoke.slots[1].scene.shown)
config.effects=false; E.UpdateEffects(integrated,config)
assert(not integrated.effectsEnabled and not integrated.nativeSmoke.slots[1].scene.shown)
local old = E.Normalize({left={nativeSmoke=false},right={}})
assert(old.left.nativeSmoke == true and old.right.nativeSmoke == true, "baked effect replaces removed customization")
for _, flip in ipairs({false,true}) do
    local baked=E.NormalizeSide({flip=flip},"right")
    local probe=entry()
    assert(E.UpdateNativeSmoke(probe,baked))
    local slot=probe.nativeSmoke.slots[1]
    local x,y=projected(slot,-0.1388888955,0)
    assert(math.abs(x-(flip and 105 or 45))<0.001 and math.abs(y+76)<0.001)
    assert(math.abs(slot.scene.width-256.32)<0.001 and baked.trailAngle==107, "baked Undead amber calibration mirrors correctly")
end
print("PASS: curated cold flame/Soulfrost, measured emitter projection, mirrored camera, zoom/origin, opacity, pooling, async load/switch, timeout, recovery, unsupported API, combat, opt-out")
for _,art in ipairs({'skull','lordaeron'}) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=art},side)
        local probe=entry();probe.art.width=225;probe.art.height=150
        local count=#scenes
        E.UpdateEffects(probe,c)
        assert(probe.nativeActive and #scenes==count+2 and not probe.effects and probe.secondaryEffect.nativeActive)
        local slot=probe.nativeSmoke.slots[1]
        local fog=probe.secondaryEffect.nativeSmoke.slots[1]
        assert(slot.actor.fileID==166033 and slot.actor.animation[3]==1)
        assert(fog.actor.fileID==166280 and fog.actor.animation[1]==158 and fog.actor.scale==0.22)
        assert(slot.scene.SetFrameLevelValue[1]==13 and fog.scene.SetFrameLevelValue[1]==13)
        local x,y=projected(slot,-0.1388888955,0)
        assert(math.abs(x-(112.5+(c.flip and -1 or 1)*c.trailX*1.5))<0.001)
        assert(math.abs(y-(-75+c.trailY))<0.001)
        local fx,fy=projected(fog,0,0)
        assert(math.abs(fx-(112.5+(c.flip and -1 or 1)*(art=='skull' and -9 or 12)*1.5))<0.001)
        assert(math.abs(fy+(art=='skull' and 148 or 144))<0.001)
        assert(math.abs(fog.scene.alpha-0.8*0.8*0.03)<0.001)
        probe.frame.hidden=true;E.StopEffects(probe);E.PlayEffects(probe);assert(not slot.scene.shown and not fog.scene.shown)
        probe.frame.hidden=false;E.PlayEffects(probe);assert(slot.scene.shown and fog.scene.shown and not probe.effects)
        E.devMode=true; E.SelectEffect(c,'rotFog'); E.SetDevEffect(c,'trailOpacity',0)
        E.UpdateEffects(probe,E.GetEffectConfig(c))
        assert(#scenes==count+2 and slot.actor.fileID==166280 and slot.scene.alpha==0)
        assert(fog.actor.fileID==166033 and fog.scene.alpha>0 and not probe.effects)
        E.devMode=false
        probe.nativeSmoke.status='unavailable';slot.actor.ready=false
        E.UpdateEffects(probe,E.GetEffectConfig(c))
        assert(not probe.nativeActive and probe.secondaryEffect.nativeActive and fog.scene.shown and not slot.scene.shown)
        E.UpdateEffects(probe,E.NormalizeSide({art='default'},side))
        assert(not slot.scene.shown and not fog.scene.shown)
    end
end
print('PASS: baked Undead amber/fog pair, mirrored origins, independent layers/opacity/failure, radio pooling and hide/show without custom textures')
local wolf=entry(); wolf.art.width=200; wolf.art.height=100
local before=#scenes
for _, flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='wolf',flip=flip,devEffects={wolf={trailX=30,trailY=15}}},'left')
    E.UpdateEffects(wolf,c)
    assert(wolf.nativeActive and #scenes==before+2, 'wolf reuses separate trail and gloom actors')
    local slot=wolf.nativeSmoke.slots[1]
    local x,y=projected(slot,-0.1388888955,0)
    assert(math.abs(x-(flip and 60 or 140))<0.001 and math.abs(y+40)<0.001, 'wide wolf frame uses independent X/Y dimensions')
end
print('PASS: native wolf flame, non-square origin projection, mirror and scene reuse')
local slot=wolf.nativeSmoke.slots[1]
local cfg=E.NormalizeSide({art='wolf',devEffects={wolf={trailSpeed=200,trailOpacity=40}}},'left')
E.UpdateEffects(wolf,cfg)
assert(slot.actor.animation[3]==1 and math.abs(slot.scene.alpha-0.8*0.8*0.4)<0.001)
local calls=slot.actor.animationCalls
cfg.trailX=72; cfg.trailOpacity=0; E.UpdateEffects(wolf,cfg)
assert(slot.scene.alpha==0 and slot.actor.animationCalls==calls, 'origin/opacity edits do not restart actor animation')
cfg.trailSpeed=25; E.UpdateEffects(wolf,cfg)
assert(slot.actor.animation[3]==1 and slot.actor.animationCalls==calls, 'obsolete speed has no effect')
E.UpdateEffects(wolf,E.NormalizeSide({art='skull'},'left'))
assert(slot.actor.animation[3]==1 and slot.actor.fileID==166033 and math.abs(slot.scene.alpha-0.8*0.8*0.26)<0.001, 'switching to skull restores amber defaults')
print('PASS: native fixed speed, opacity including zero, stable animation across other edits, skull restoration')
for _, flip in ipairs({false,true}) do
    local approved=E.NormalizeSide({art='wolf',flip=flip},'left')
    E.UpdateEffects(wolf,approved)
    local x,y=projected(slot,-0.1388888955,0)
    assert(math.abs(x-(100+(flip and 1 or -1)*98*4/3))<0.001 and math.abs(y+50-28*2/3)<0.001)
    assert(slot.scene.width==384 and math.abs(slot.scene.alpha-0.8*0.8*0.64)<0.001)
    assert(slot.actor.animation[3]==1)
end
print('PASS: baked wolf origin, scale and opacity project correctly in both facings')
do
    local pair=entry();pair.art.width=200;pair.art.height=100
    local count=#scenes
    E.devMode=true
    for _,art in ipairs({'wolf','whiteWorgen'}) do
        local trailID=art=='wolf' and 'coldFlame' or 'amberFlow'
        for _,flip in ipairs({false,true}) do
            local c=E.NormalizeSide({art=art,flip=flip},'left')
            E.UpdateEffects(pair,c)
            assert(pair.nativeActive and pair.secondaryEffect.nativeActive and not pair.effects)
            local trail=pair.nativeSmoke.slots[1];local gloom=pair.secondaryEffect.nativeSmoke.slots[1]
            assert(trail.actor.fileID==(art=='wolf' and 165995 or 166033) and gloom.actor.fileID==165686)
            assert(gloom.actor.animation[1]==158 and gloom.actor.scale==0.22)
            local x,y=projected(gloom,-0.0377854258*0.22,0)
            local gx,gy=art=='wolf' and 10 or 2,art=='wolf' and -91 or -79
            assert(math.abs(x-(100+(flip and -1 or 1)*gx*4/3))<0.001 and math.abs(y-(-50+gy*2/3))<0.001)
            assert(math.abs(gloom.actor.y+0.0422529913*0.22)<0.000001)
            assert(gloom.scene.SetFrameLevelValue[1]==pair.frame:GetFrameLevel()+3 and trail.scene.SetFrameLevelValue[1]==pair.frame:GetFrameLevel()+3)
            local oldCalls=trail.actor.animationCalls
            for i=1,8 do E.UpdateEffects(pair,c) end
            assert(trail.scene.shown and gloom.scene.shown and trail.actor.animationCalls==oldCalls)
            E.SelectEffect(c,'worgenGloom');E.SetDevEffect(c,'trailOpacity',0)
            E.UpdateEffects(pair,E.GetEffectConfig(c))
            assert(pair.nativeSmoke.slots[1].scene.alpha==0 and pair.secondaryEffect.nativeSmoke.slots[1].scene.alpha>0)
            E.SelectEffect(c,trailID);E.UpdateEffects(pair,E.GetEffectConfig(c))
            assert(pair.nativeSmoke.slots[1].scene.alpha>0 and pair.secondaryEffect.nativeSmoke.slots[1].scene.alpha==0)
            assert(#scenes==count+2,'Worgen switches reuse two scenes')
        end
    end
    E.UpdateEffects(pair,E.NormalizeSide({art='default'},'left'))
    assert(not pair.nativeSmoke.slots[1].scene.shown and not pair.secondaryEffect.nativeSmoke.slots[1].scene.shown)
    E.devMode=false
end
print('PASS: both Worgen native pairs, Gloom emitter/depth compensation, looping Hold, layers/opacity isolation, repeated Apply, pooling and cleanup')
local moon=entry(); moon.art.width=225; moon.art.height=150
local moonScenes=#scenes
for _,id in ipairs({'moonbough','verdantRoot','lunarRelic'}) do
    for _,flip in ipairs({false,true}) do
        local c=E.NormalizeSide({art=id,flip=flip,devEffects={[id]={trailX=20,trailY=10,trailOpacity=50}}},'left')
        E.UpdateEffects(moon,c)
        local s=moon.nativeSmoke.slots[1]
        assert(moon.nativeActive and #scenes==moonScenes+1 and s.actor.fileID==166032)
        assert(s.scene.SetDesaturationValue[1]==0 and math.abs(s.scene.alpha-0.32)<0.001)
        local x,y=projected(s,0,0)
        assert(math.abs(x-(flip and 82.5 or 142.5))<0.001 and math.abs(y+65)<0.001)
    end
end
E.UpdateEffects(moon,E.NormalizeSide({art='wolf'},'left'))
assert(moon.nativeSmoke.slots[1].scene.SetDesaturationValue[1]==0 and moon.nativeSmoke.slots[1].actor.fileID==165995)
moon.nativeSmoke.slots[1].scene.SetDesaturation=nil
E.UpdateEffects(moon,E.NormalizeSide({art='moonbough'},'left'))
assert(moon.nativeActive and moon.nativeSmoke.status=='ready', 'native colours do not require desaturation support')
print('PASS: native-colour moonlight, per-art mirrored origins, reuse and no supporting pulse')
local beam=entry(); beam.art.width=225; beam.art.height=150
local count=#scenes
for _,id in ipairs({'verdantRoot'}) do
    for _,flip in ipairs({false,true}) do
        local c=E.NormalizeSide({art=id,flip=flip,devEffects={[id]={selectedEffect='faerieFire',faerieFire={trailX=20,trailY=10,trailOpacity=50}}}},'left')
        E.UpdateEffects(beam,c)
        local s=beam.nativeSmoke.slots[1]
        assert(beam.nativeActive and #scenes==count+1 and s.actor.fileID==166062 and s.actor.scale==1)
        assert(s.scene.SetDesaturationValue[1]==0 and math.abs(s.scene.alpha-0.32)<0.001)
        local p=E.NativeEffectProfiles.faerieFire
        local x,y=projected(s,p.emitterX,p.emitterZ)
        assert(math.abs(x-(flip and 82.5 or 142.5))<0.001 and math.abs(y+65)<0.001)
    end
end
E.UpdateEffects(beam,E.NormalizeSide({art='verdantRoot'},'left'))
assert(beam.nativeSmoke.slots[1].actor.fileID==166032 and beam.nativeSmoke.slots[1].actor.scale==1 and #scenes==count+1)
mode='pending'
local selected=E.NormalizeSide({art='verdantRoot',devEffects={verdantRoot={selectedEffect='faerieFire'}}},'left')
E.UpdateEffects(beam,selected)
assert(not beam.nativeActive and beam.nativeSmoke.slots[1].scene.alpha==0, 'loading effect stays invisible')
E.UpdateEffects(beam,E.NormalizeSide({art='verdantRoot'},'left')); tick()
assert(beam.nativeSmoke.attempts==1, 'rapid radio switch invalidates stale model polling')
mode='ready'; E.UpdateEffects(beam,selected)
assert(beam.nativeActive and beam.nativeSmoke.slots[1].scene.alpha>0)
print('PASS: Faerie Fire centre projection, native colours, exclusive playback, pooling and stale-load cancellation')
-- WhiteGlow's emitter is exactly 0/0/0 with no animated bone translation.
-- Its viewport centre must also be the artwork centre, without flame bias.
for _,id in ipairs({'moonlight','faerieFire'}) do
    local profile=E.NativeEffectProfiles[id]
    for _,flip in ipairs({false,true}) do
        for _,angle in ipairs({-180,-90,0,90,180}) do
            for _,size in ipairs({50,100,200}) do
                for _,width in ipairs({112.5,225,450}) do
                    beam.art.width=width; beam.art.height=width*2/3
                    local c=E.NormalizeSide({art='verdantRoot',flip=flip,devEffects={verdantRoot={
                        selectedEffect=id,trailX=0,trailY=0,trailSize=size,trailAngle=angle,
                        faerieFire={trailX=0,trailY=0,trailSize=size,trailAngle=angle}}}},'left')
                    E.UpdateEffects(beam,c)
                    local s=beam.nativeSmoke.slots[1]
                    local x,y=projected(s,profile.emitterX,profile.emitterZ)
                    assert(math.abs(x-width/2)<0.001 and math.abs(y+width/3)<0.001)
                    assert(s.scene.point[4]==width/2 and s.scene.point[5]==-width/3)
                    assert(math.abs(s.actor.y+(profile.emitterY or 0))<0.001)
                end
            end
        end
    end
end
mode='reject'
local noFallback=entry()
E.UpdateEffects(noFallback,E.NormalizeSide({art='moonbough'},'left'))
assert(not noFallback.nativeActive and not noFallback.effects)
assert(E.NativeSmokeStatus(noFallback):find('effect hidden:',1,true))
mode='pending'
local noOverlay=entry()
E.UpdateEffects(noOverlay,E.NormalizeSide({art='verdantRoot'},'left'))
assert(not noOverlay.effects and E.NativeSmokeStatus(noOverlay):find('no texture fallback',1,true))
for i=1,16 do tick() end
assert(noOverlay.nativeSmoke.status=='unavailable' and not noOverlay.effects)
assert(not E.NativeEffectProfiles.moonbeam)
print('PASS: centre 0/0 through rotation, mirror, art/effect scale; no pulse allocation on load, rejection or timeout')
mode='ready'
local totem=entry(); totem.art.width=225; totem.art.height=150
local total=#scenes
for _,flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='stormhornTotem',flip=flip},'left')
    E.UpdateEffects(totem,c)
    local slot=totem.nativeSmoke.slots[1]
    assert(totem.nativeActive and not totem.effects and #scenes==total+2)
    assert(slot.actor.fileID==165997 and slot.actor.scale==1 and slot.scene.SetDesaturationValue[1]==0)
    local x,y=projected(slot,0,0)
    assert(math.abs(x-(112.5+(flip and -1 or 1)*64.5))<0.001 and math.abs(y+66)<0.001)
    assert(slot.actor.y==0, 'anchor emitter centre instead of the moving emitter')
    assert(math.abs(slot.scene.alpha-0.8*0.8)<0.001)
    c.trailOpacity=0; E.UpdateEffects(totem,c); assert(slot.scene.alpha==0)
end
E.UpdateEffects(integrated,E.NormalizeSide({art='stormhornTotem'},'left'))
assert(integrated.nativeActive and integrated.nativeSmoke.slots[1].actor.fileID==165997)
E.UpdateEffects(integrated,E.NormalizeSide({art='wolf'},'left'))
assert(integrated.nativeActive and integrated.nativeSmoke.slots[1].actor.fileID==165995)
mode='pending'; local waiting=entry()
E.UpdateEffects(waiting,E.NormalizeSide({art='stormhornTotem'},'left'))
for i=1,16 do tick() end
assert(waiting.nativeSmoke.status=='unavailable' and not waiting.effects)
print('PASS: Blue Glow ID, emitter centre, mirror, opacity, pooling, no eye pulse, timeout and wolf restoration')
mode='ready'
local sparkScenes=#scenes
for _,flip in ipairs({false,true}) do
    for _,angle in ipairs({0,90,-113}) do
        local c=E.NormalizeSide({art='stormhornTotem',flip=flip,devEffects={stormhornTotem={selectedEffect='broadFlame',broadFlame={trailX=17,trailY=-4,trailAngle=angle,trailSize=150,trailOpacity=37}}}},'left')
        E.UpdateEffects(totem,c)
        local slot=totem.nativeSmoke.slots[1]
        assert(totem.nativeActive and slot.actor.fileID==165598 and #scenes==sparkScenes)
        assert(slot.scene.SetDesaturationValue[1]==0 and not totem.effects)
        local p=E.NativeEffectProfiles.broadFlame
        local x,y=projected(slot,p.emitterX,p.emitterZ)
        assert(math.abs(slot.actor.y+(p.emitterY or 0))<0.001)
        assert(math.abs(x-(112.5+(flip and -1 or 1)*25.5))<0.001 and math.abs(y+79)<0.001)
        assert(math.abs(slot.scene.alpha-0.8*0.8*0.37)<0.001)
        c.trailOpacity=0; E.UpdateEffects(totem,c); assert(slot.scene.alpha==0)
    end
end
mode='pending'
E.UpdateEffects(totem,E.NormalizeSide({art='stormhornTotem'},'left'))
local sparks=E.NormalizeSide({art='stormhornTotem',devEffects={stormhornTotem={selectedEffect='broadFlame'}}},'left')
E.UpdateEffects(totem,sparks); tick()
assert(totem.nativeSmoke.attempts==1 and not totem.effects, 'old glow polling is invalidated')
mode='ready'; totem.nativeSmoke.slots[1].actor.ready=true; E.UpdateEffects(totem,sparks)
assert(totem.nativeActive and #scenes==sparkScenes)
print('PASS: Broad Blue Flame emitter projection, colour, opacity, paired actor reuse and async selection')
assert(not E.NativeEffectProfiles.cloud and E.NativeEffectProfiles.broadFlame.modelScale==0.15)
for _,id in ipairs({'broadFlame','blueGlow'}) do
    for _,layer in ipairs({'front','back'}) do
        local c=E.NormalizeSide({art='stormhornTotem',devEffects={stormhornTotem={selectedEffect=id}},effectLayers={stormhornTotem={[id]=layer}}},'left')
        E.UpdateEffects(totem,c)
        local slot=totem.nativeSmoke.slots[1]
        assert(slot.scene.SetFrameLevelValue[1]==(layer=='back' and 11 or 13))
        assert(slot.actor.scale==(id=='broadFlame' and 0.15 or 1))
        assert(#scenes==sparkScenes and not totem.effects)
    end
end
print('PASS: broad flame scale, cloud removal, model layer ordering and scale reset without extra scenes')
mode='ready'
local pair=entry(); pair.art.width=225; pair.art.height=150
local before=#scenes
for _,flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='stormhornTotem',flip=flip},'right')
    E.UpdateEffects(pair,c)
    local glow=pair.nativeSmoke.slots[1]
    local flame=pair.secondaryEffect.nativeSmoke.slots[1]
    assert(#scenes==before+2 and glow.scene.shown and flame.scene.shown)
    assert(glow.actor.fileID==165997 and flame.actor.fileID==165598)
    assert(glow.scene.SetFrameLevelValue[1]==13 and flame.scene.SetFrameLevelValue[1]==11)
    assert(glow.scene.width==864 and math.abs(flame.scene.width-302.4)<0.001)
    local gx,gy=projected(glow,0,0); local fx,fy=projected(flame,0,0)
    assert(math.abs(gx-(112.5+(flip and -1 or 1)*64.5))<0.001 and gy==-66)
    assert(math.abs(fx-(112.5+(flip and -1 or 1)*66))<0.001 and fy==-21)
    pair.frame.hidden=true; pair.frame.OnHide()
    assert(not glow.scene.shown and not flame.scene.shown)
    pair.frame.hidden=false; pair.frame.OnShow()
    assert(glow.scene.shown and flame.scene.shown)
    E.devMode=true; E.SelectEffect(c,'broadFlame'); E.SetDevEffect(c,'trailOpacity',25)
    E.UpdateEffects(pair,E.GetEffectConfig(c))
    assert(pair.nativeSmoke.slots[1].actor.fileID==165598 and pair.secondaryEffect.nativeSmoke.slots[1].actor.fileID==165997)
    assert(math.abs(pair.nativeSmoke.slots[1].scene.alpha-0.16)<0.001 and math.abs(pair.secondaryEffect.nativeSmoke.slots[1].scene.alpha-0.64)<0.001)
    assert(E.NativeSmokeStatus(pair):find('Blue Glow loaded',1,true) and E.NativeSmokeStatus(pair):find('Broad Blue Flame loaded',1,true))
    E.UpdateEffects(pair,E.NormalizeSide({art='moonbough'},'left'))
    assert(not pair.secondaryEffect.nativeWanted and not flame.scene.shown)
    E.UpdateEffects(pair,E.NormalizeSide({art='hidden'},'left'))
    assert(not glow.scene.shown and not flame.scene.shown)
end
mode='pending'
local asyncPair=entry(); E.UpdateEffects(asyncPair,E.NormalizeSide({art='stormhornTotem'},'left'))
asyncPair.nativeSmoke.slots[1].actor.ready=true; tick()
E.UpdateEffects(asyncPair,E.NormalizeSide({art='stormhornTotem'},'left'))
assert(asyncPair.nativeActive and not asyncPair.secondaryEffect.nativeActive)
for i=1,16 do tick() end
assert(asyncPair.secondaryEffect.nativeSmoke.status=='unavailable' and asyncPair.nativeSmoke.status=='ready')
assert(asyncPair.nativeSmoke.slots[1].scene.shown and not asyncPair.secondaryEffect.nativeSmoke.slots[1].scene.shown)
E.UpdateEffects(asyncPair,E.NormalizeSide({art='hidden'},'left')); tick()
assert(not asyncPair.nativeSmoke.slots[1].scene.shown and not asyncPair.secondaryEffect.nativeSmoke.slots[1].scene.shown)
E.devMode=false
print('PASS: simultaneous Stormhorn scenes, baked mirrored placement/layers, independent opacity/loading/failure, bounded reuse and hide/art-switch cleanup')
mode='ready'
local wing=entry(); wing.art.width=225; wing.art.height=150
local initial=#scenes
for _,id in ipairs({'felGlow','felDrip'}) do
    for _,flip in ipairs({false,true}) do
        local c=E.NormalizeSide({art='felwing',flip=flip,devEffects={felwing={selectedEffect=id,trailX=0,trailY=0,felDrip={trailX=0,trailY=0}}}},'left')
        E.UpdateEffects(wing,c)
        local slot=wing.nativeSmoke.slots[1]
        assert(slot.actor.fileID==(id=='felGlow' and 166004 or 166007))
        assert(#scenes==initial+2 and not wing.effects and wing.secondaryEffect.nativeActive)
        local other=wing.secondaryEffect.nativeSmoke.slots[1]
        assert(other.actor.fileID==(id=='felGlow' and 166007 or 166004) and other.scene.shown and slot.scene.shown)
        local x,y=projected(slot,0,0); assert(x==112.5 and y==-75)
        assert(slot.scene.SetDesaturationValue[1]==0 and slot.actor.scale==1)
        c.effectLayer='back'; c.trailOpacity=20; E.UpdateEffects(wing,c)
        assert(slot.scene.SetFrameLevelValue[1]==11 and math.abs(slot.scene.alpha-0.128)<0.001)
    end
end
E.UpdateEffects(pair,E.NormalizeSide({art='stormhornTotem'},'left'))
E.UpdateEffects(pair,E.NormalizeSide({art='felwing'},'left'))
assert(pair.secondaryEffect.nativeWanted and pair.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166004)
assert(pair.nativeSmoke.slots[1].actor.fileID==166007)
E.UpdateEffects(pair,E.NormalizeSide({art='moonbough'},'left'))
assert(not pair.secondaryEffect.nativeWanted and not pair.secondaryEffect.nativeSmoke.slots[1].scene.shown)
mode='pending'; local pendingWing=entry(); E.UpdateEffects(pendingWing,E.NormalizeSide({art='felwing'},'left'))
for i=1,16 do tick() end
assert(pendingWing.nativeSmoke.status=='unavailable' and not pendingWing.effects)
mode='ready'
print('PASS: paired Felwing native IDs, centre/mirror, scene reuse, native colours, opacity/layers, no eye overlay and artwork-switch cleanup')
for _,flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='felwing',flip=flip},'right')
    for _,spec in ipairs({{'felDrip',67,-2,43,100},{'felGlow',60,16,20,175}}) do
        E.UpdateEffects(wing,E.GetEffectConfig(c,spec[1]))
        local slot=wing.nativeSmoke.slots[1];local x,y=projected(slot,0,0)
        assert(math.abs(x-(112.5+(flip and -1 or 1)*spec[2]*1.5))<0.001 and math.abs(y-(-75+spec[3]))<0.001)
        assert(math.abs(slot.scene.alpha-0.64*spec[4]/100)<0.001 and slot.scene.width==432*spec[5]/100)
    end
end
print('PASS: approved Felwing glow/drip origins, size and opacity project correctly in both facings')
-- Cold-cache recovery: one bounded extra window, without clearing the model.
mode='pending'
local slow=entry(); local slowConfig=E.NormalizeSide({art='felwing'},'left')
E.UpdateEffects(slow,slowConfig)
local slowSceneCount=#scenes
for i=1,8 do tick() end
assert(slow.nativeSmoke.status=='loading' and slow.nativeSmoke.retries==1 and slow.nativeSmoke.attempts==0)
slow.nativeSmoke.slots[1].actor.ready=true
tick(); E.UpdateEffects(slow,slowConfig)
assert(slow.nativeActive and slow.nativeSmoke.status=='ready' and #scenes==slowSceneCount)
assert(slow.nativeSmoke.slots[1].actor.animationCalls==1, 'retry must not restart the pending model')
for i=1,8 do tick() end
assert(slow.secondaryEffect.nativeSmoke.status=='unavailable' and slow.secondaryEffect.nativeSmoke.timedOut)
local late=slow.secondaryEffect
late.nativeSmoke.slots[1].actor.ready=true
local beforeSchedule=scheduled
combat=true; E.PlayNativeSmoke(late); assert(scheduled==beforeSchedule and E.pending)
combat=false; E.PlayNativeSmoke(late); assert(scheduled==beforeSchedule+1)
E.UpdateEffects(slow,slowConfig)
assert(late.nativeActive and late.nativeSmoke.status=='ready' and not late.nativeSmoke.timedOut)
assert(late.nativeSmoke.slots[1].scene.shown and slow.nativeSmoke.slots[1].scene.shown)
assert(#scenes==slowSceneCount and late.nativeSmoke.slots[1].actor.animationCalls==1)
local permanent=entry(); E.UpdateEffects(permanent,slowConfig)
for i=1,16 do tick() end
assert(permanent.nativeSmoke.status=='unavailable' and permanent.secondaryEffect.nativeSmoke.status=='unavailable')
local attempts=permanent.nativeSmoke.attempts
for i=1,20 do E.UpdateEffects(permanent,slowConfig); tick() end
assert(permanent.nativeSmoke.attempts==attempts and permanent.nativeSmoke.retries==1, 'Apply must not create an infinite retry loop')
permanent.nativeSmoke.slots[1].actor.ready=true
E.UpdateEffects(permanent,slowConfig)
assert(permanent.nativeActive and not permanent.secondaryEffect.nativeActive, 'late readiness recovers on Apply independently')
local paused=entry(); E.UpdateNativeSmoke(paused,{})
paused.frame.hidden=true;tick();assert(paused.nativeSmoke.attempts==0 and not paused.nativeSmoke.polling)
paused.frame.hidden=false;E.PlayNativeSmoke(paused);tick();assert(paused.nativeSmoke.attempts==1)
E.UpdateNativeSmoke(paused,{nativeEffect='soulfrost'})
assert(paused.nativeSmoke.retries==0 and paused.nativeSmoke.attempts==0)
mode='ready';paused.nativeSmoke.slots[1].actor.ready=true;tick();E.UpdateNativeSmoke(paused,{nativeEffect='soulfrost'})
assert(paused.nativeSmoke.status=='ready')
print('PASS: bounded slow-load retry, late same-model recovery on Apply/show, independent paired recovery, no reload/allocation loop, hidden/combat deferral and profile reset')
local arcane=entry();arcane.art.width=225;arcane.art.height=150
for _,flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='violetSpire',flip=flip},'left')
    E.UpdateEffects(arcane,c)
    local slot=arcane.nativeSmoke.slots[1]
    assert(arcane.nativeActive and slot.actor.fileID==166009 and not arcane.effects)
    local x,y=projected(slot,0,0)
    assert(math.abs(x-(112.5+(flip and 1 or -1)*34.5))<0.001 and math.abs(y+61)<0.001)
    assert(slot.scene.SetFrameLevelValue[1]==arcane.frame:GetFrameLevel()+4, 'front glow above crystal host at cap+3')
    assert(math.abs(slot.scene.alpha-0.64*0.61)<0.001)
end
local allocated=#scenes
E.UpdateEffects(arcane,E.NormalizeSide({art='violetSpire'},'left'))
assert(#scenes==allocated and arcane.nativeSmoke.slots[1].actor.animationCalls==1)
E.UpdateEffects(pair,E.NormalizeSide({art='violetSpire'},'left'))
assert(pair.nativeSmoke.slots[1].actor.fileID==166009 and not pair.secondaryEffect.nativeWanted)
assert(not pair.secondaryEffect.nativeSmoke.slots[1].scene.shown)
print('PASS: arcane native ID, emitter/mirror placement, front layer/opacity, pooling and paired-effect cleanup')
local molten=entry();molten.art.width=225;molten.art.height=150
for _,art in ipairs({'cinderforged','cindermaw'}) do
    for _,flip in ipairs({false,true}) do
        local c=E.NormalizeSide({art=art,flip=flip},'right')
        E.UpdateEffects(molten,c)
        assert(molten.nativeSmoke.slots[1].actor.fileID==166012 and molten.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166011)
        assert(molten.nativeActive and molten.secondaryEffect.nativeActive and not molten.effects)
        local slot=molten.secondaryEffect.nativeSmoke.slots[1]
        local x,y=projected(slot,-0.1388888955,0)
        local offset=art=='cinderforged' and 64.5 or 42
        assert(math.abs(x-(112.5+(flip and 1 or -1)*offset))<0.001 and math.abs(y+85)<0.001)
        E.devMode=true;E.SelectEffect(c,'fireFlame');E.SetEffectLayer(c,'back')
        E.UpdateEffects(molten,E.GetEffectConfig(c))
        assert(molten.nativeSmoke.slots[1].actor.fileID==166011 and molten.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166012)
        assert(molten.nativeSmoke.slots[1].scene.SetFrameLevelValue[1]==molten.frame:GetFrameLevel()+1)
    end
end
local n=#scenes;E.UpdateEffects(molten,E.NormalizeSide({art='cinderforged'},'right'));assert(#scenes==n)
E.UpdateEffects(molten,E.NormalizeSide({art='moonbough'},'left'))
assert(not molten.secondaryEffect.nativeWanted and not molten.secondaryEffect.nativeSmoke.slots[1].scene.shown)
print('PASS: paired molten native assets, emitter compensation in both facings, layer selection, reuse and cleanup')
mode='ready'
local frost=entry();frost.art.width=225;frost.art.height=150
for _,art in ipairs({'rimeforged','rimeguard'}) do
    for _,flip in ipairs({false,true}) do
        local c=E.NormalizeSide({art=art,flip=flip},'left')
        E.UpdateEffects(frost,c)
        assert(frost.nativeSmoke.slots[1].actor.fileID==165995 and frost.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166209)
        assert(frost.nativeActive and frost.secondaryEffect.nativeActive and not frost.effects)
        local x,y=projected(frost.nativeSmoke.slots[1],-0.1388888955,0)
        local trailOffset=art=='rimeforged' and 225 or 133.5
        local trailY=art=='rimeforged' and -80 or -60
        assert(math.abs(x-(112.5+(flip and 1 or -1)*trailOffset))<0.001 and math.abs(y-trailY)<0.001)
        local fx,fy=projected(frost.secondaryEffect.nativeSmoke.slots[1],0,-0.1641135812*0.45)
        assert(math.abs(frost.secondaryEffect.nativeSmoke.slots[1].actor.y+0.0116675766*0.45)<0.000001, 'Frost Form emitter is on the camera depth plane')
        local formOffset=art=='rimeforged' and 58.5 or 45
        local formY=art=='rimeforged' and -3 or -32
        assert(math.abs(fx-(112.5+(flip and 1 or -1)*formOffset))<0.001 and math.abs(fy-formY)<0.001)
        E.devMode=true;E.SelectEffect(c,'frostEnchant');E.SetEffectLayer(c,'back');E.SetDevEffect(c,'trailOpacity',0)
        E.UpdateEffects(frost,E.GetEffectConfig(c))
        assert(frost.nativeSmoke.slots[1].actor.fileID==166209 and frost.secondaryEffect.nativeSmoke.slots[1].actor.fileID==165995)
        assert(frost.nativeSmoke.slots[1].scene.SetFrameLevelValue[1]==frost.frame:GetFrameLevel()+1 and frost.nativeSmoke.slots[1].scene.alpha==0)
    end
end
local count=#scenes;E.UpdateEffects(frost,E.NormalizeSide({art='rimeguard'},'left'));assert(#scenes==count)
E.UpdateEffects(frost,E.NormalizeSide({art='violetSpire'},'left'));assert(not frost.secondaryEffect.nativeWanted and not frost.secondaryEffect.nativeSmoke.slots[1].scene.shown)
print('PASS: frost paired native IDs, mirrored emitter projections, opacity/layer isolation, scene reuse and cleanup')
local well=entry();mode='ready';combat=false
for _,flip in ipairs({false,true}) do
    for _,angle in ipairs({-180,-90,0,90,180}) do
        local wc=E.NormalizeSide({art='moonwell',flip=flip},'right')
        E.devMode=true;E.SelectEffect(wc,'waterRipple');E.SetDevEffect(wc,'trailAngle',angle)
        E.UpdateEffects(well,E.GetEffectConfig(wc))
        local slot=well.nativeSmoke.slots[1];local axis=slot.scene.SetCameraOrientationByAxisVectorsValue
        assert(slot.actor.fileID==657698 and slot.actor.scale==.04 and well.secondaryEffect.nativeSmoke.slots[1].actor.fileID==165998)
        for row=0,2 do local norm=0;for j=1,3 do norm=norm+axis[row*3+j]^2 end;assert(math.abs(norm-1)<.00001) end
        for row=0,1 do for other=row+1,2 do local dot=0;for j=1,3 do dot=dot+axis[row*3+j]*axis[other*3+j] end;assert(math.abs(dot)<.00001) end end
        assert(slot.scene.SetCameraPositionValue[3]>0 and slot.actor.x==0 and slot.actor.y==0 and slot.actor.z==0)
    end
end
E.UpdateEffects(well,E.NormalizeSide({art='wolf'},'left'));assert(well.secondaryEffect.nativeWanted and well.secondaryEffect.nativeSmoke.slots[1].actor.fileID==165686)
assert(well.nativeSmoke.slots[1].scene.SetCameraPositionValue[3]==0,'tilt must reset when leaving Moonwell')
print('PASS: Moonwell native pair, orthonormal tilted ripple camera on both facings/all angles, and camera reset')
local priest=entry();priest.art.width=225;priest.art.height=150
for _,spec in ipairs({
    {'seraph','holyGlow','sunRays',166034,610642,1.5,0.0232977532,0.0576375052,0.0206381083,-40,-51},
    {'sanctum','holyGlow','sunRays',166034,610642,1.5,0.0232977532,0.0576375052,0.0206381083,-40,-51},
    {'umbra','voidGlow','voidSmoke',166009,166907,0.18,-0.0003013768,-0.0055674450,0.1358658969,76,-128},
    {'eclipse','voidGlow','voidSmoke',166009,166907,0.18,-0.0003013768,-0.0055674450,0.1358658969,65,-70},
}) do
    for _,flip in ipairs({false,true}) do
        local art,glow,other,glowID,otherID,scale,ox,oy,oz,offsetX,y=unpack(spec)
        local c=E.NormalizeSide({art=art,flip=flip},'right')
        E.UpdateEffects(priest,c)
        assert(priest.nativeActive and priest.secondaryEffect.nativeActive and not priest.effects)
        assert(priest.nativeSmoke.slots[1].actor.fileID==glowID and priest.nativeSmoke.slots[1].actor.scale==2)
        local slot=priest.secondaryEffect.nativeSmoke.slots[1]
        assert(slot.actor.fileID==otherID and slot.actor.scale==scale)
        assert(slot.actor.animation[1]==(other=='sunRays' and 158 or 0),'Divine Radiance uses its looping hold; other models keep default animation')
        local x,py=projected(slot,ox*scale,oz*scale)
        assert(math.abs(x-(112.5+(flip and -1 or 1)*offsetX*1.5))<0.001 and math.abs(py-(-75+y))<0.001)
        assert(math.abs(slot.actor.y+oy*scale)<0.000001,'inspected origin must stay on camera depth plane')
        assert(slot.scene.SetFrameLevelValue[1]==13 and slot.scene.SetDesaturationValue[1]==0)
        local allocated=#scenes
        E.SelectEffect(c,other);E.SetDevEffect(c,'trailOpacity',0);E.SetEffectLayer(c,'front')
        E.UpdateEffects(priest,E.GetEffectConfig(c))
        assert(#scenes==allocated and priest.nativeSmoke.slots[1].actor.fileID==otherID)
        assert(priest.nativeSmoke.slots[1].scene.alpha==0 and priest.nativeSmoke.slots[1].scene.SetFrameLevelValue[1]==13)
        assert(priest.secondaryEffect.nativeSmoke.slots[1].actor.fileID==glowID and priest.secondaryEffect.nativeSmoke.slots[1].scene.alpha>0)
        E.StopEffects(priest);assert(not priest.nativeSmoke.slots[1].scene.shown and not priest.secondaryEffect.nativeSmoke.slots[1].scene.shown)
        E.PlayEffects(priest);assert(priest.secondaryEffect.nativeSmoke.slots[1].scene.shown)
        priest.nativeSmoke.status='unavailable';priest.nativeSmoke.timedOut=false
        E.UpdateEffects(priest,E.GetEffectConfig(c));assert(not priest.nativeActive and priest.secondaryEffect.nativeActive)
    end
end
E.UpdateEffects(priest,E.NormalizeSide({art='hidden'},'left'))
assert(not priest.nativeWanted and not priest.secondaryEffect.nativeWanted)
assert(not priest.nativeSmoke.slots[1].scene.shown and not priest.secondaryEffect.nativeSmoke.slots[1].scene.shown)
print('PASS: all four priest native pairs, measured origins on both facings, independent layers/opacity/failure, reuse and cleanup')

-- Reproduce the user's workaround: late secondary load stays invisible until
-- an unrelated Apply. Run a coalesced refresh queue, without clicking Apply.
queue={};combat=false;mode='pending'
local swapLeft,swapRight=entry(),entry()
swapLeft.art.width=225;swapLeft.art.height=150;swapRight.art.width=225;swapRight.art.height=150
local swapConfigs={left=E.NormalizeSide({art='seraph'},'left'),right=E.NormalizeSide({art='sanctum'},'right')}
local queuedRefresh,refreshes=false,0
local function preview()
    E.UpdateEffects(swapLeft,E.GetEffectConfig(swapConfigs.left))
    E.UpdateEffects(swapRight,E.GetEffectConfig(swapConfigs.right))
end
E.Schedule=function()
    if queuedRefresh then return end
    queuedRefresh=true
    C_Timer.After(0,function() queuedRefresh=false;refreshes=refreshes+1;preview() end)
end
preview()
swapLeft.nativeSmoke.slots[1].actor.ready=true;swapRight.nativeSmoke.slots[1].actor.ready=true
for i=1,40 do tick() end
local lateLeft=swapLeft.secondaryEffect.nativeSmoke.slots[1]
local lateRight=swapRight.secondaryEffect.nativeSmoke.slots[1]
assert(swapLeft.secondaryEffect.nativeSmoke.timedOut and not lateLeft.scene.shown)
assert(swapRight.secondaryEffect.nativeSmoke.timedOut and not lateRight.scene.shown)
lateLeft.actor.ready=true;lateRight.actor.ready=true
if lateLeft.actor.endCapperOnModelLoaded then lateLeft.actor.endCapperOnModelLoaded() end
if lateRight.actor.endCapperOnModelLoaded then lateRight.actor.endCapperOnModelLoaded() end
tick();tick()
assert(lateLeft.scene.shown and lateLeft.scene.alpha>0 and lateRight.scene.shown and lateRight.scene.alpha>0,
    'late secondary effects must recover automatically without Apply')
local count=#scenes;local refreshCount=refreshes
for i=1,10 do lateLeft.actor.endCapperOnModelLoaded();lateRight.actor.endCapperOnModelLoaded();tick() end
assert(refreshes==refreshCount and #scenes==count,'duplicate load notifications cannot refresh forever or allocate scenes')

-- Cached model reports ready before its load-complete notification. The later
-- notification must restore its projection/alpha with the current calibration.
mode='ready';swapConfigs.left=E.NormalizeSide({art='umbra'},'left');swapConfigs.right=E.NormalizeSide({art='eclipse'},'right');preview()
local cached=swapRight.secondaryEffect.nativeSmoke.slots[1]
local expectedX,expectedZ,expectedAlpha=cached.actor.x,cached.actor.z,cached.scene.alpha
cached.actor:SetPosition(0,0,0);cached.scene:SetAlpha(0)
cached.actor.endCapperOnModelLoaded();tick()
assert(cached.scene.alpha==expectedAlpha and cached.actor.x==expectedX and cached.actor.z==expectedZ)

-- Queue an old completion, switch both sides again, then deliver stale callbacks.
local staleLeft=swapLeft.secondaryEffect.nativeSmoke.slots[1].actor.endCapperOnModelLoaded
staleLeft()
swapConfigs.left=E.NormalizeSide({art='cindermaw'},'left');swapConfigs.right=E.NormalizeSide({art='rimeforged'},'right');preview()
local beforeRefresh=refreshes;staleLeft();tick();tick()
assert(swapLeft.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166011)
assert(swapRight.secondaryEffect.nativeSmoke.slots[1].actor.fileID==166209)
assert(refreshes==beforeRefresh+1 and #scenes==count,'queued refresh reads latest selection; stale generation does not add work')

-- Hidden/combat/disabled caps must not be resurrected by a load completion.
local second=swapLeft.secondaryEffect.nativeSmoke.slots[1]
swapLeft.frame.hidden=true;swapLeft.frame.OnHide();beforeRefresh=refreshes
second.actor.endCapperOnModelLoaded();tick()
assert(refreshes==beforeRefresh and not second.scene.shown)
swapLeft.frame.hidden=false;swapLeft.frame.OnShow();tick()
assert(second.scene.shown and swapLeft.secondaryEffect.nativeActive)
swapConfigs.right=E.NormalizeSide({art='moonwell'},'right');preview()
local ripple=swapRight.secondaryEffect.nativeSmoke.slots[1]
combat=true;E.pending=false;beforeRefresh=refreshes;ripple.actor.endCapperOnModelLoaded();tick()
assert(E.pending and refreshes==beforeRefresh)
combat=false;E.Schedule();tick();assert(ripple.scene.shown and ripple.scene.alpha>0)
swapConfigs.right.effects=false;preview();beforeRefresh=refreshes
ripple.actor.endCapperOnModelLoaded();tick();assert(not ripple.scene.shown and refreshes==beforeRefresh)

-- A synchronous cached callback cannot recursively load or restart a model.
mode='sync';swapConfigs.right=E.NormalizeSide({art='felwing'},'right');preview()
local drip=swapRight.nativeSmoke.slots[1]
local modelCalls=drip.actor.modelCalls
tick();tick();assert(drip.scene.shown and drip.actor.modelCalls==modelCalls and not queuedRefresh)
local animationCalls=drip.actor.animationCalls
preview();assert(drip.actor.animationCalls==animationCalls,'normal Apply must not restart the animation')
-- A ready actor that becomes unready re-enters bounded loading, even without a callback.
drip.actor.ready=false;preview();assert(swapRight.nativeSmoke.status=='loading' and drip.scene.alpha==0)
drip.actor.ready=true;tick();tick();assert(drip.scene.alpha>0 and swapRight.nativeActive)
-- Notification for a newly disabled effect (not a duplicate), then a new
-- zero-opacity profile: neither may be made visible by model completion.
mode='pending';swapConfigs.right=E.NormalizeSide({art='moonwell'},'right');preview()
local off=swapRight.secondaryEffect.nativeSmoke.slots[1]
swapConfigs.right.effects=false;preview();beforeRefresh=refreshes
off.actor.ready=true;off.actor.endCapperOnModelLoaded();tick()
assert(refreshes==beforeRefresh and not off.scene.shown)
swapConfigs.right=E.NormalizeSide({art='moonwell',devEffects={moonwell={waterRipple={trailOpacity=0}}}},'right')
preview();tick();assert(off.scene.alpha==0 and off.scene.shown)
-- Hard rejection and premature/wrong-model notifications cannot create loops.
mode='reject';swapConfigs.right=E.NormalizeSide({art='stormhornTotem'},'right');preview()
local bad=swapRight.secondaryEffect.nativeSmoke.slots[1];beforeRefresh=refreshes
bad.actor.ready=true;bad.actor.endCapperOnModelLoaded();tick();assert(refreshes==beforeRefresh)
mode='pending';swapConfigs.right=E.NormalizeSide({art='umbra'},'right');preview()
local fresh=swapRight.secondaryEffect.nativeSmoke.slots[1];beforeRefresh=refreshes
fresh.actor.endCapperOnModelLoaded();tick();assert(refreshes==beforeRefresh)
fresh.actor.ready=true;fresh.actor.fileID=166011;fresh.actor.endCapperOnModelLoaded()
assert(not queuedRefresh,'wrong model completion must be ignored')
fresh.actor.fileID=166907;fresh.actor.endCapperOnModelLoaded();tick();tick()
assert(fresh.scene.shown and fresh.scene.alpha>0)
print('PASS: asynchronous/cached secondary completion, automatic paired recovery without Apply, coalescing, stale selections, hidden/combat/disabled guards, synchronous callbacks and readiness loss')

mode='ready';E.devMode=true
local kirin=entry();kirin.art.width=225;kirin.art.height=150
for _,flip in ipairs({false,true}) do
    local c=E.NormalizeSide({art='kirinTor',flip=flip},'right')
    E.UpdateEffects(kirin,c)
    local glow=kirin.nativeSmoke.slots[1];local seal=kirin.secondaryEffect.nativeSmoke.slots[1]
    assert(glow.actor.fileID==166009 and seal.actor.fileID==243044 and not kirin.effects)
    assert(glow.scene.alpha>0 and seal.scene.alpha>0 and seal.actor.animation[1]==0)
    assert(seal.actor.scale==0.65 and seal.actor.x==0 and seal.actor.y==0 and seal.actor.z==0)
    local camera=seal.scene.SetCameraPositionValue;local axes=seal.scene.SetCameraOrientationByAxisVectorsValue
    assert(camera[1]==(flip and 8 or -8) and camera[2]==0 and axes[1]==(flip and -1 or 1))
    -- Camera basis remains orthonormal through every supported roll and mirror.
    for _,angle in ipairs({-180,-113,0,90,180}) do
        c=E.NormalizeSide({art='kirinTor',flip=flip,devEffects={kirinTor={selectedEffect='kirinSeal',kirinSeal={trailAngle=angle}}}},'right')
        E.UpdateEffects(kirin,c);axes=kirin.nativeSmoke.slots[1].scene.SetCameraOrientationByAxisVectorsValue
        local function dot(a,b) return axes[a]*axes[b]+axes[a+1]*axes[b+1]+axes[a+2]*axes[b+2] end
        assert(math.abs(dot(1,1)-1)<.00001 and math.abs(dot(4,4)-1)<.00001 and math.abs(dot(7,7)-1)<.00001)
        assert(math.abs(dot(1,4))<.00001 and math.abs(dot(1,7))<.00001 and math.abs(dot(4,7))<.00001)
    end
    local allocated=#scenes
    E.SetDevEffect(c,'trailOpacity',0);E.SetEffectLayer(c,'back');E.UpdateEffects(kirin,E.GetEffectConfig(c))
    assert(kirin.nativeSmoke.slots[1].scene.alpha==0 and kirin.nativeSmoke.slots[1].scene.SetFrameLevelValue[1]==11)
    assert(kirin.secondaryEffect.nativeSmoke.slots[1].scene.alpha>0 and #scenes==allocated)
    E.StopEffects(kirin);assert(not kirin.secondaryEffect.nativeSmoke.slots[1].scene.shown)
    E.PlayEffects(kirin);assert(kirin.secondaryEffect.nativeSmoke.slots[1].scene.shown)
end
E.UpdateEffects(kirin,E.NormalizeSide({art='violetSpire'},'left'))
assert(not kirin.secondaryEffect.nativeWanted and not kirin.secondaryEffect.nativeSmoke.slots[1].scene.shown)
assert(kirin.nativeSmoke.slots[1].scene.SetCameraPositionValue[1]==0,'pooled camera returns to the usual Y view')
print('PASS: Kirin Tor native eye/glow together, frontal mirrored camera/roll basis, independent opacity/layers, pooling/hide/resume and spire cleanup')

do
    local caps={entry(),entry()}
    local before=#scenes
    E.devMode=true
    for index,art in ipairs({'frostmourneHilt','frostmourneBlade'}) do
        local e=caps[index];e.art.width=300;e.art.height=120
        for _,flip in ipairs({false,true}) do
            local c=E.NormalizeSide({art=art,flip=flip},index==1 and 'left' or 'right')
            E.UpdateEffects(e,c)
            local glow=e.nativeSmoke.slots[1];local mist=e.secondaryEffect.nativeSmoke.slots[1]
            assert(glow.actor.fileID==165998 and mist.actor.fileID==165412 and mist.actor.scale==4)
            assert(glow.scene.alpha>0 and mist.scene.alpha>0 and not e.effects)
            assert(glow.scene.SetFrameLevelValue[1]==13 and mist.scene.SetFrameLevelValue[1]==13)
            local x,y=projected(mist,0,0)
            assert(math.abs(x-(150+(flip and -1 or 1)*(index==1 and 12 or -12)*2))<.001)
            assert(math.abs(y-(-60+(index==1 and -74 or -101)*.8))<.001)
            local eye
            if art=='frostmourneHilt' then
                local trail=e.hiltEyeTrail
                assert(trail.nativeActive and #trail.nativeSmoke.slots==1)
                eye=trail.nativeSmoke.slots[1]
                assert(eye.actor.fileID==165995 and eye.scene.alpha>0 and eye.scene.shown)
                assert(eye.scene.SetFrameLevelValue[1]==13)
                local eyeX,eyeY=projected(eye,-0.1388888955,0)
                assert(math.abs(eyeX-(flip and .387 or .613)*300+(flip and -1 or 1)*72)<.001)
                assert(math.abs(eyeY+.812*120-17*.8)<.001)
                assert(E.NativeSmokeStatus(e):find('eye trail: Cold flame loaded (165995',1,true))
            else
                assert(not e.hiltEyeTrail,'blade allocates no eye trail')
            end
            local calls=glow.actor.modelCalls;local animations=mist.actor.animationCalls
            local eyeCalls=eye and eye.actor.modelCalls
            for i=1,6 do E.UpdateEffects(e,c) end
            assert(glow.actor.modelCalls==calls and mist.actor.animationCalls==animations)
            E.SelectEffect(c,'frostMist');E.SetDevEffect(c,'trailOpacity',0)
            E.UpdateEffects(e,E.GetEffectConfig(c))
            if eye then
                assert(glow.actor.fileID==165998 and glow.scene.alpha>0 and mist.actor.fileID==165412 and mist.scene.alpha==0)
                assert(eye.actor.modelCalls==eyeCalls and eye.scene.shown and eye.scene.alpha>0)
                E.SelectEffect(c,'coldFlame');E.SetDevEffect(c,'trailX',17)
                E.SetDevEffect(c,'trailY',12);E.SetDevEffect(c,'trailOpacity',0)
                E.UpdateEffects(e,E.GetEffectConfig(c))
                assert(eye.scene.alpha==0 and eye.actor.modelCalls==eyeCalls)
                assert(glow.actor.modelCalls==calls and mist.actor.animationCalls==animations)
                assert(glow.scene.alpha>0 and mist.scene.alpha==0)
                local eyeX,eyeY=projected(eye,-0.1388888955,0)
                assert(math.abs(eyeX-(flip and .387 or .613)*300-(flip and -1 or 1)*34)<.001)
                assert(math.abs(eyeY+.812*120-12*.8)<.001)
            else
                assert(e.nativeSmoke.slots[1].actor.fileID==165412 and e.nativeSmoke.slots[1].scene.alpha==0)
                assert(e.secondaryEffect.nativeSmoke.slots[1].actor.fileID==165998 and e.secondaryEffect.nativeSmoke.slots[1].scene.alpha>0)
            end
        end
    end
    assert(#scenes==before+5,'three scenes for the hilt and two for the blade')
    local eye=caps[1].hiltEyeTrail.nativeSmoke.slots[1]
    E.StopEffects(caps[1]);assert(not eye.scene.shown)
    E.PlayEffects(caps[1]);assert(eye.scene.shown)
    E.UpdateEffects(caps[1],E.NormalizeSide({art='frostmourneBlade'},'left'))
    E.PlayEffects(caps[1]);assert(not eye.scene.shown and not caps[1].hiltEyeTrail.nativeWanted)
    E.UpdateEffects(caps[1],E.NormalizeSide({art='default'},'left'))
    assert(not caps[1].nativeSmoke.slots[1].scene.shown and not caps[1].secondaryEffect.nativeSmoke.slots[1].scene.shown)
    assert(caps[2].secondaryEffect.nativeSmoke.slots[1].scene.shown,'other cap remains active')
    E.StopEffects(caps[2]);assert(not caps[2].secondaryEffect.nativeSmoke.slots[1].scene.shown)
    E.PlayEffects(caps[2]);assert(caps[2].secondaryEffect.nativeSmoke.slots[1].scene.shown)
    E.devMode=false
end
print('PASS: Frostmourne mist/glow plus one hilt-only native eye trail, mirrored origins, opacity isolation, reuse and cleanup')

