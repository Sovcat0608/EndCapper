local E = {}
assert(loadfile('Model.lua'))('EndCapper', E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
local defaults = E.Normalize(nil)
assert(defaults.left.art == 'skull' and defaults.left.flip == true)
assert(defaults.right.flip == false)
assert(defaults.left.nativeEffect == 'amberFlow' and defaults.left.trailAngle == 107)
assert(defaults.left.trailSize==89 and defaults.left.trailX==-30 and defaults.left.trailY==-1)
local effects = E.NormalizeSide({nativeEffect='external.m2',trailSize=999,trailAngle=-999,trailX=0/0,trailY=-999},'left')
assert(effects.nativeEffect=='amberFlow' and effects.trailSize==89 and effects.trailAngle==107)
assert(effects.trailX==-30 and effects.trailY==-1, 'top-level legacy tuning cannot override artwork defaults')
local migrated = E.Normalize({version=1,left={trailX=9,trailY=-4,nativeEffect='soulfrost',trailSize=75,x=8},right={trailX=10}})
assert(migrated.version==43 and migrated.left.trailX==-30 and migrated.left.trailY==-1 and migrated.right.trailX==-30)
assert(migrated.left.nativeEffect=='amberFlow' and migrated.left.trailSize==89 and migrated.left.x==8)
migrated.left.trailX=17; migrated.left.trailY=31
local again=E.Normalize(migrated)
assert(again.left.trailX==-30 and again.left.trailY==-1, 'profile is reapplied on normalization')
local old=E.Normalize({version=2,right={flip=false,size=130,x=17,y=-55,effects=false,nativeSmoke=false}})
assert(old.right.flip==false and old.right.size==130 and old.right.x==17 and old.right.y==-55)
assert(old.right.effects and old.right.nativeSmoke and old.right.trailSize==89)
local bad = E.Normalize({left={art='external-path',size=0/0,x=999,y=-999,flip='yes'}})
assert(bad.left.art == 'skull' and bad.left.size == 100)
assert(bad.left.x == 200 and bad.left.y == -200 and bad.left.flip == true)
EndCapperDB = defaults
E.Begin(); E.draft.left.x = 40
E.draft.left.nativeEffect='soulfrost'; E.draft.left.trailX=5
assert(EndCapperDB.left.x == 0)
E.Cancel(); assert(E.Config().left.x == 0)
assert(E.Config().left.nativeEffect=='amberFlow' and E.Config().left.trailX==-30)
E.Begin(); E.draft.right.flip = false; E.Commit()
assert(EndCapperDB.right.flip == false and EndCapperDB.left.flip == true)
local coords = {0.1,0.2,0.1,0.8,0.7,0.2,0.7,0.8}
local mirrored = {E.UV(coords,true)}
assert(mirrored[1] == 0.7 and mirrored[5] == 0.1)
local restored = {E.UV(mirrored,true)}
for i=1,8 do assert(coords[i] == restored[i]) end
print('PASS: defaults, invalid settings, independent sides, preview/cancel/apply, atlas UV mirroring')
-- Rebuilt pair retains the stable skull ID and all personal settings on upgrade.
for _,side in ipairs({'left','right'}) do
    local db=E.Normalize({version=21,[side]={art='skull',size=137,x=23,y=-31,flip=true,effectLayers={skull={coldFlame='back'}}}})
    local c=db[side]
    assert(c.art=='skull' and c.size==137 and c.x==23 and c.y==-31 and c.flip and c.effectLayer=='front')
    assert(c.nativeSmoke and c.nativeEffect=='amberFlow' and not c.effectLayers.skull.coldFlame)
    E.devMode=true
    E.SetDevEffect(c,'trailX',-42);E.SetDevEffect(c,'trailOpacity',37)
    E.SelectArtwork(c,'lordaeron',side)
    assert(E.GetEffectConfig(c).trailX==34 and E.GetEffectConfig(c).trailOpacity==6)
    E.SetDevEffect(c,'trailX',44);E.SetDevEffect(c,'trailOpacity',28)
    c=E.NormalizeSide(c,side)
    assert(c.trailX==44 and c.trailOpacity==28)
    E.ResetDevEffect(c);assert(E.GetEffectConfig(c).trailX==34)
    E.SelectArtwork(c,'skull',side)
    assert(E.GetEffectConfig(c).trailX==-42 and E.GetEffectConfig(c).trailOpacity==37)
    E.devMode=false
end
assert(E.DefaultMirror('skull','left') and E.DefaultMirror('lordaeron','right'))
assert(not E.DefaultMirror('skull','right') and not E.DefaultMirror('lordaeron','left'))
print('PASS: Undead/Lordaeron upgrade, reversed default silhouettes, native-only profiles and isolated trail tuning')
do
    for _,art in ipairs({'skull','lordaeron'}) do
        local input={version=22,left={art=art,size=136,x=29,y=-17,flip=true,
            devEffects={skull={trailX=-127,trailY=36,trailOpacity=7},lordaeron={selectedEffect='coldFlame',trailX=99,trailOpacity=8},wolf={trailX=42,trailOpacity=51}},
            effectLayers={skull={coldFlame='back'},lordaeron={coldFlame='back'},wolf={coldFlame='back'}}},right={art='wolf'}}
        local db=E.Normalize(input); local c=db.left
        assert(c.nativeEffect=='amberFlow' and c.trailX==(art=='skull' and -30 or 34) and c.trailY==(art=='skull' and -1 or -29) and c.trailOpacity==(art=='skull' and 26 or 6))
        assert(c.size==136 and c.x==29 and c.y==-17 and c.flip)
        assert(c.devEffects.skull.trailX==-30 and c.devEffects.lordaeron.trailX==34)
        assert(c.devEffects.wolf.trailX==42 and c.devEffects.wolf.trailOpacity==51 and c.effectLayers.wolf.coldFlame=='back')
        assert(input.left.devEffects.skull.trailX==-127 and input.left.effectLayers.skull.coldFlame=='back', 'migration does not mutate saved input')
        assert(not E.CanSelectEffect(art,'coldFlame') and not E.CanSelectEffect('wolf','rotFog'))
        E.devMode=true
        E.SetDevEffect(c,'trailX',-40);E.SetDevEffect(c,'trailOpacity',59);E.SetEffectLayer(c,'back')
        E.SelectEffect(c,'rotFog');E.SetDevEffect(c,'trailX',23);E.SetDevEffect(c,'trailOpacity',0);E.SetEffectLayer(c,'front')
        db=E.Normalize(db);c=db.left
        assert(c.nativeEffect=='rotFog' and c.trailX==23 and c.trailOpacity==0 and c.effectLayer=='front')
        local amber=E.GetEffectConfig(c,'amberFlow')
        assert(amber.trailX==-40 and amber.trailOpacity==59 and amber.effectLayer=='back')
        E.ResetDevEffect(c)
        assert(E.GetEffectConfig(c).trailX==(art=='skull' and -9 or 12) and E.GetEffectConfig(c).trailOpacity==3 and E.GetEffectConfig(c).effectLayer=='front')
        assert(E.GetEffectConfig(c,'amberFlow').trailX==-40)
        EndCapperDB=db;E.Begin();E.SelectEffect(E.draft.left,'amberFlow');E.SetDevEffect(E.draft.left,'trailX',3);E.Cancel()
        assert(E.GetEffectConfig(EndCapperDB.left,'amberFlow').trailX==-40)
        E.Begin();E.SetDevEffect(E.draft.left,'trailX',31);E.Commit();E.devMode=false
        assert(E.Normalize(EndCapperDB).left.trailX==31 and EndCapperDB.right.nativeEffect=='coldFlame')
    end
end
print('PASS: retired blue calibration migration, dormant art records, independent amber/fog persistence/reset, Apply/Cancel and unchanged wolf')
local wolf=E.NormalizeSide({art='wolf',devEffects={wolf={trailX=999,trailY=0/0,trailAngle=-999,trailSize=2,nativeEffect='external'}}},'right')
assert(wolf.art=='wolf' and wolf.trailX==150 and wolf.trailY==E.WolfEffect.trailY)
assert(wolf.trailSize==50 and wolf.trailAngle==-180 and wolf.nativeEffect=='coldFlame')
EndCapperDB=E.Normalize({version=3,left={art='wolf'},right={art='skull',x=33,flip=false}})
E.Begin(); E.SetDevEffect(E.draft.left,'trailX',42)
assert(E.GetEffectConfig(E.draft.left).trailX==E.WolfEffect.trailX, 'developer edits require session opt-in')
E.devMode=true; E.SetDevEffect(E.draft.left,'trailX',42)
assert(E.GetEffectConfig(E.draft.left).trailX==42 and not EndCapperDB.left.devEffects.wolf)
E.Cancel(); assert(E.GetEffectConfig(E.Config().left).trailX==E.WolfEffect.trailX)
E.Begin(); E.SetDevEffect(E.draft.left,'trailX',42); E.SetDevEffect(E.draft.right,'trailX',42)
E.SetDevEffect(E.draft.left,'nativeEffect','external'); E.Commit(); E.devMode=false
assert(EndCapperDB.left.trailX==42 and EndCapperDB.right.trailX==42 and EndCapperDB.right.x==33, 'rebuilt skull supports independent opt-in trail tuning')
local reloaded=E.Normalize(EndCapperDB)
assert(reloaded.left.trailX==42 and reloaded.left.nativeEffect=='coldFlame', 'saved calibration works with developer UI off')
E.devMode=true; E.Begin(); E.SetDevEffect(E.draft.left,'trailX',15)
assert(EndCapperDB.left.devEffects.wolf.trailX==42, 'nested draft tuning is isolated')
E.draft.left.art='skull'
assert(E.GetEffectConfig(E.draft.left).trailX==-30, 'wolf calibration never affects skull')
E.draft.left.art='wolf'; assert(E.GetEffectConfig(E.draft.left).trailX==15)
E.Cancel(); E.devMode=false
print('PASS: wolf migration, calibration bounds, dev guard, draft isolation, Apply/Cancel/reload, skull preservation')
local previous=E.Normalize({version=4,left={art='wolf',devEffects={wolf={trailX=44,trailY=-37}}}})
assert(previous.left.trailX==44 and previous.left.trailY==-37 and previous.left.trailSpeed==nil and previous.left.trailOpacity==E.WolfEffect.trailOpacity)
local bounded=E.NormalizeSide({art='wolf',devEffects={wolf={trailSpeed=0,trailOpacity=999}}},'left')
assert(bounded.trailSpeed==nil and bounded.devEffects.wolf.trailSpeed==nil and bounded.trailOpacity==100)
EndCapperDB=previous; E.devMode=true; E.Begin()
E.SetDevEffect(E.draft.left,'trailSpeed',200); E.SetDevEffect(E.draft.left,'trailOpacity',0); E.Commit()
assert(E.Normalize(EndCapperDB).left.trailSpeed==nil and E.Normalize(EndCapperDB).left.trailOpacity==0)
E.Begin(); E.SetDevEffect(E.draft.left,'trailSpeed',50); E.SetDevEffect(E.draft.left,'trailOpacity',70); E.Cancel()
assert(E.Config().left.trailSpeed==nil and E.Config().left.trailOpacity==0 and E.Config().right.trailOpacity==26)
E.devMode=false
assert(#E.devEffectFields==5)
for _, spec in ipairs(E.devEffectFields) do assert(spec[1]~='trailSpeed') end
print('PASS: obsolete speed removed, origin preserved, opacity bounds/zero, Apply/Cancel and reload')
local baked=E.NormalizeSide({art='wolf'},'left')
assert(baked.flip==false and baked.trailSize==100 and baked.trailAngle==-113)
assert(baked.trailX==-98 and baked.trailY==28 and baked.trailOpacity==64 and baked.trailSpeed==nil)
local mirror=E.NormalizeSide({art='wolf'},'right')
assert(mirror.flip and mirror.trailX==-98 and mirror.trailY==28 and mirror.trailOpacity==64)
local saved=E.NormalizeSide({art='wolf',size=130,devEffects={wolf={trailSize=100,trailAngle=-113,trailX=-87,trailY=-15,trailOpacity=64,trailSpeed=83}}},'left')
assert(saved.size==130 and saved.trailX==-87 and saved.trailOpacity==64 and saved.devEffects.wolf.trailSpeed==nil)
saved.devEffects.wolf=nil
local reset=E.GetEffectConfig(saved)
assert(reset.trailSize==100 and reset.trailX==-98 and reset.trailY==28 and reset.trailOpacity==64)
assert(baked.nativeEffect=='coldFlame' and mirror.nativeEffect=='coldFlame' and not E.WolfGlow)
print('PASS: approved Shadowfang defaults, mirrored facing, saved trail calibration/reset and no obsolete pupil profile')
EndCapperDB=E.Normalize({version=4,left={art='wolf',devEffects={wolf={trailX=-87,trailOpacity=64}}}})
E.devMode=true; E.Begin()
for i,id in ipairs({'moonbough','verdantRoot','lunarRelic'}) do
    E.draft.left.art=id
    E.SetDevEffect(E.draft.left,'trailX',i*10); E.SetDevEffect(E.draft.left,'trailOpacity',i*20)
    local c=E.GetEffectConfig(E.draft.left)
    assert(c.nativeEffect=='moonlight' and c.moonlight and c.trailX==i*10)
    assert(E.artworkByID[id].width==225 and E.artworkByID[id].height==150)
end
E.Commit(); E.devMode=false
local restored=E.Normalize(EndCapperDB)
for i,id in ipairs({'moonbough','verdantRoot','lunarRelic'}) do
    restored.left.art=id
    assert(E.GetEffectConfig(restored.left).trailOpacity==i*20)
    assert(not restored.right.devEffects[id], 'each cap owns its calibration')
end
assert(restored.left.devEffects.wolf.trailX==-87)
E.devMode=true; E.Begin(); E.SetDevEffect(E.draft.left,'trailOpacity',0); E.Cancel()
assert(EndCapperDB.left.devEffects.lunarRelic.trailOpacity==60)
local unsafe=E.NormalizeSide({art='moonbough',nativeEffect='external',devEffects={external={trailX=1},moonbough={trailX=999,trailOpacity=-5,nativeEffect='coldFlame',moonlight=false}}},'left')
assert(unsafe.nativeEffect=='moonlight' and unsafe.moonlight and unsafe.trailX==150 and unsafe.trailOpacity==0 and not unsafe.devEffects.external)
E.devMode=false
print('PASS: schema-4 upgrade, three isolated moonlight profiles, cross-art/cap persistence, Cancel and whitelist')
EndCapperDB=E.Normalize({version=5,left={art='verdantRoot',devEffects={verdantRoot={trailX=41,trailOpacity=39}}}})
assert(E.GetEffectConfig(EndCapperDB.left).nativeEffect=='moonlight' and EndCapperDB.left.trailX==41)
E.Begin(); E.SelectEffect(E.draft.left,'faerieFire'); assert(E.SelectedEffect(E.draft.left)=='moonlight', 'selection needs dev mode')
E.devMode=true
for _,id in ipairs({'verdantRoot'}) do
    E.draft.left.art=id
    E.SetDevEffect(E.draft.left,'trailOpacity',39)
    E.SelectEffect(E.draft.left,'faerieFire'); E.SetDevEffect(E.draft.left,'trailOpacity',22)
    assert(E.GetEffectConfig(E.draft.left).nativeEffect=='faerieFire' and E.GetEffectConfig(E.draft.left).trailOpacity==22)
    E.SelectEffect(E.draft.left,'moonlight'); assert(E.GetEffectConfig(E.draft.left).trailOpacity==39)
    E.SelectEffect(E.draft.left,'faerieFire'); assert(E.GetEffectConfig(E.draft.left).trailOpacity==22)
end
E.Commit(); E.devMode=false
assert(E.Normalize(EndCapperDB).left.nativeEffect=='faerieFire' and EndCapperDB.right.nativeEffect=='amberFlow')
E.devMode=true; E.Begin(); E.ResetDevEffect(E.draft.left)
assert(E.GetEffectConfig(E.draft.left).trailOpacity==65 and E.GetEffectConfig(E.draft.left).nativeEffect=='faerieFire')
E.SelectEffect(E.draft.left,'moonlight'); assert(E.GetEffectConfig(E.draft.left).trailOpacity==39)
E.Cancel(); assert(E.Config().left.nativeEffect=='faerieFire' and E.Config().left.trailOpacity==22)
local forged=E.NormalizeSide({art='verdantRoot',devEffects={verdantRoot={selectedEffect='external',faerieFire={trailOpacity=900,trailX=0/0}}}},'left')
assert(forged.nativeEffect=='moonlight' and forged.devEffects.verdantRoot.faerieFire.trailOpacity==100)
local fixed=E.NormalizeSide({art='wolf',devEffects={wolf={selectedEffect='faerieFire'}}},'left')
E.SelectEffect(fixed,'faerieFire'); assert(E.GetEffectConfig(fixed).nativeEffect=='coldFlame')
E.devMode=false
print('PASS: radio selection whitelist, schema-5 migration, per-effect/per-art tuning, Apply/reload, Reset selected only and Cancel')
local retired=E.Normalize({version=6,left={art='verdantRoot',x=17,y=-9,devEffects={verdantRoot={
    selectedEffect='moonbeam',trailX=41,trailY=-12,trailOpacity=39,
    moonbeam={trailX=150,trailY=150,trailSize=200,trailOpacity=1}}}}})
assert(retired.version==43 and retired.left.nativeEffect=='faerieFire')
assert(retired.left.trailX==0 and retired.left.trailY==0 and retired.left.trailOpacity==65)
assert(not retired.left.devEffects.verdantRoot.moonbeam and retired.left.x==17 and retired.left.y==-9)
E.devMode=true; E.SelectEffect(retired.left,'moonlight')
assert(E.GetEffectConfig(retired.left).trailX==41 and E.GetEffectConfig(retired.left).trailY==-12)
E.SelectEffect(retired.left,'moonbeam'); assert(E.SelectedEffect(retired.left)=='moonlight')
E.ResetDevEffect(retired.left)
assert(E.GetEffectConfig(retired.left).trailX==-42 and E.GetEffectConfig(retired.left).trailY==-17)
for id,values in pairs({moonbough={200,-48,-15,40},verdantRoot={182,-42,-17,65},lunarRelic={186,-44,-7,39}}) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=id},side)
        assert(c.nativeEffect=='moonlight' and c.trailSize==values[1] and c.trailAngle==0)
        assert(c.trailX==values[2] and c.trailY==values[3] and c.trailOpacity==values[4])
        E.SetDevEffect(c,'trailX',9); E.ResetDevEffect(c)
        assert(E.GetEffectConfig(c).trailX==values[2])
        local fairy=E.GetEffectDefaults(id,'faerieFire')
        if id=='verdantRoot' then assert(fairy.trailX==0 and fairy.trailY==0 and fairy.trailOpacity==65) else assert(not E.CanSelectEffect(id,'faerieFire')) end
    end
end
E.devMode=false
print('PASS: schema-6 Moonbeam retirement, saved offsets, baked right/unflipped druid defaults and Reset on both caps')
local totem=E.Normalize({version=7,left={art='stormhornTotem'},right={art='lunarRelic',devEffects={lunarRelic={trailX=-29}}}})
assert(totem.version==43 and totem.left.nativeEffect=='blueGlow' and not totem.left.moonlight)
assert(totem.left.trailX==43 and totem.left.trailY==9 and totem.left.trailAngle==90)
assert(not E.CanSelectEffect('stormhornTotem','faerieFire'))
EndCapperDB=totem; E.Begin(); E.devMode=true
E.SetDevEffect(E.draft.left,'trailX',21); E.SetDevEffect(E.draft.left,'trailOpacity',39)
E.SelectEffect(E.draft.left,'moonlight'); assert(E.SelectedEffect(E.draft.left)=='blueGlow')
E.Commit(); E.devMode=false
assert(E.Normalize(EndCapperDB).left.trailX==21 and EndCapperDB.left.trailOpacity==39)
assert(EndCapperDB.right.trailX==-29 and not EndCapperDB.right.devEffects.stormhornTotem)
E.Begin(); E.devMode=true; E.ResetDevEffect(E.draft.left)
assert(E.GetEffectConfig(E.draft.left).trailX==43 and E.GetEffectConfig(E.draft.left).trailOpacity==100)
E.Cancel(); E.devMode=false; assert(EndCapperDB.left.trailX==21)
print('PASS: schema-7 totem upgrade, native-only whitelist, isolated tuning, Apply/reload/Reset/Cancel')
EndCapperDB=E.Normalize({version=10,left={art='stormhornTotem',devEffects={stormhornTotem={selectedEffect='blueGlow',trailX=28,trailOpacity=47}}},right={art='wolf'}})
assert(EndCapperDB.left.nativeEffect=='blueGlow' and EndCapperDB.left.trailX==28)
E.devMode=true; E.Begin(); E.SelectEffect(E.draft.left,'broadFlame')
assert(E.GetEffectConfig(E.draft.left).trailX==44)
E.SetDevEffect(E.draft.left,'trailX',12); E.SetDevEffect(E.draft.left,'trailOpacity',31)
E.SelectEffect(E.draft.left,'blueGlow'); assert(E.GetEffectConfig(E.draft.left).trailX==28 and E.GetEffectConfig(E.draft.left).trailOpacity==47)
E.SelectEffect(E.draft.left,'broadFlame'); E.Commit()
assert(E.Normalize(EndCapperDB).left.nativeEffect=='broadFlame' and EndCapperDB.left.trailX==12)
E.Begin(); E.ResetDevEffect(E.draft.left); assert(E.GetEffectConfig(E.draft.left).trailOpacity==100)
E.SelectEffect(E.draft.left,'blueGlow'); assert(E.GetEffectConfig(E.draft.left).trailOpacity==47)
E.Cancel(); assert(EndCapperDB.left.trailOpacity==31 and EndCapperDB.right.nativeEffect=='coldFlame')
assert(not E.CanSelectEffect('moonbough','broadFlame') and not E.CanSelectEffect('stormhornTotem','faerieFire'))
E.devMode=false
print('PASS: independent blue/broadFlame calibration, selection/save/reset/Cancel and artwork whitelist')
for _,oldID in ipairs({'shamanWind','radiantSparks'}) do
    local migrated=E.Normalize({version=9,left={art='stormhornTotem',size=130,x=14,y=-5,flip=false,devEffects={stormhornTotem={
        selectedEffect=oldID,trailX=-90,trailOpacity=12,radiantSparks={trailSize=200,trailOpacity=1}}}},right={art='lunarRelic'}})
    assert(migrated.version==43 and migrated.left.nativeEffect=='blueGlow')
    assert(migrated.left.trailX==43 and migrated.left.trailOpacity==100 and not migrated.left.devEffects.stormhornTotem.radiantSparks)
    assert(migrated.left.size==130 and migrated.left.x==14 and migrated.left.y==-5 and not migrated.left.flip)
    assert(migrated.right.nativeEffect=='moonlight' and migrated.right.trailX==-44)
    assert(not E.CanSelectEffect('stormhornTotem',oldID))
end
print('PASS: retired Wind/Sparks migrate to fresh Blue Glow defaults without changing cap/art placement')
local cloudSave=E.Normalize({version=10,left={art='stormhornTotem',devEffects={stormhornTotem={selectedEffect='cloud',trailX=29,trailOpacity=44,cloud={trailX=-100,trailOpacity=1}}}}})
assert(cloudSave.left.nativeEffect=='broadFlame' and cloudSave.left.trailX==44 and cloudSave.left.trailOpacity==100)
assert(cloudSave.left.devEffects.stormhornTotem.trailX==29 and not cloudSave.left.devEffects.stormhornTotem.cloud)
EndCapperDB=cloudSave; E.Begin()
E.SetEffectLayer(E.draft.left,'back'); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
E.devMode=true; E.SelectEffect(E.draft.left,'blueGlow'); assert(E.GetEffectConfig(E.draft.left).effectLayer=='front')
E.SelectEffect(E.draft.left,'broadFlame'); E.Commit()
assert(E.Normalize(EndCapperDB).left.effectLayer=='back' and EndCapperDB.right.effectLayer=='front')
E.Begin(); E.ResetDevEffect(E.draft.left); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
E.Cancel(); assert(EndCapperDB.left.effectLayer=='back')
local skull=E.NormalizeSide({art='skull'},'left'); E.devMode=false; E.SetEffectLayer(skull,'back')
assert(E.GetEffectConfig(skull).effectLayer=='back' and E.GetEffectConfig(skull).trailX==-30)
local badLayers=E.NormalizeSide({art='skull',effectLayers={skull={coldFlame='evil',cloud='back'},external={foo='back'}}},'left')
assert(badLayers.effectLayer=='front' and not badLayers.effectLayers.external and not badLayers.effectLayers.skull.cloud)
print('PASS: cloud retirement preserves Blue Glow; per-effect/side layers, Reset/Cancel/reload, fixed skull and layer whitelist')
for _,side in ipairs({'left','right'}) do
    local c=E.NormalizeSide({art='stormhornTotem'},side)
    local glow=E.GetEffectConfig(c,'blueGlow')
    local flame=E.GetEffectConfig(c,'broadFlame')
    assert(glow.trailSize==200 and glow.trailAngle==90 and glow.trailX==43 and glow.trailY==9 and glow.trailOpacity==100 and glow.effectLayer=='front')
    assert(flame.trailSize==70 and flame.trailAngle==90 and flame.trailX==44 and flame.trailY==54 and flame.trailOpacity==100 and flame.effectLayer=='back')
    assert(c.size==100 and c.x==0 and c.y==0 and c.flip==(side=='right'))
    E.devMode=true; E.SelectEffect(c,'broadFlame'); E.SetEffectLayer(c,'front')
    c=E.NormalizeSide(c,side); assert(c.effectLayer=='front', 'explicit front overrides baked back')
    E.ResetDevEffect(c); assert(E.GetEffectConfig(c).effectLayer=='back')
end
E.devMode=false
print('PASS: both baked Stormhorn profiles, per-effect default layers, explicit overrides and Reset on either side')
EndCapperDB=E.Normalize({version=11,left={art='felwing'},right={art='stormhornTotem',devEffects={stormhornTotem={selectedEffect='blueGlow',trailX=43}}}})
assert(EndCapperDB.version==43 and EndCapperDB.left.nativeEffect=='felDrip')
assert(EndCapperDB.left.trailX==67 and EndCapperDB.left.trailY==-2 and EndCapperDB.left.trailAngle==90)
assert(E.artworkByID.felwing.width==225 and E.artworkByID.felwing.height==150)
E.Begin(); E.devMode=true
E.SelectEffect(E.draft.left,'felGlow'); E.SetDevEffect(E.draft.left,'trailOpacity',42); E.SelectEffect(E.draft.left,'felDrip')
E.SetDevEffect(E.draft.left,'trailX',21); E.SetDevEffect(E.draft.left,'trailOpacity',73); E.SetEffectLayer(E.draft.left,'back')
E.Commit(); EndCapperDB=E.Normalize(EndCapperDB); E.Begin()
assert(E.draft.left.nativeEffect=='felDrip' and E.draft.left.trailX==21 and E.draft.left.trailOpacity==73 and E.draft.left.effectLayer=='back')
E.SelectEffect(E.draft.left,'felGlow'); assert(E.GetEffectConfig(E.draft.left).trailOpacity==42 and E.GetEffectConfig(E.draft.left).effectLayer=='front')
E.SelectEffect(E.draft.left,'broadFlame'); assert(E.SelectedEffect(E.draft.left)=='felGlow')
E.SelectEffect(E.draft.left,'felDrip'); E.ResetDevEffect(E.draft.left)
assert(E.GetEffectConfig(E.draft.left).trailX==67 and E.GetEffectConfig(E.draft.left).effectLayer=='front')
E.Cancel(); assert(EndCapperDB.left.trailX==21 and EndCapperDB.right.trailX==43)
assert(not E.CanSelectEffect('stormhornTotem','felGlow') and not E.CanSelectEffect('wolf','felDrip'))
E.devMode=false
print('PASS: Felwing schema/defaults, independent glow/drip tuning and layers, Apply/reload/Cancel/Reset and artwork whitelist')
for _,side in ipairs({'left','right'}) do
    local c=E.NormalizeSide({art='felwing'},side)
    assert(c.nativeEffect=='felDrip' and c.trailSize==100 and c.trailX==67 and c.trailY==-2 and c.trailOpacity==43 and c.effectLayer=='front')
    E.devMode=true; E.SelectEffect(c,'felGlow')
    local glow=E.GetEffectConfig(E.NormalizeSide(c,side))
    assert(glow.nativeEffect=='felGlow' and glow.trailSize==175 and glow.trailX==60 and glow.trailY==16 and glow.trailOpacity==20)
    E.SetDevEffect(c,'trailX',9); E.ResetDevEffect(c); assert(E.GetEffectConfig(c).trailX==60)
    assert(c.size==100 and c.x==0 and c.y==0 and c.flip==(side=='right'))
end
local oldWing=E.NormalizeSide({art='felwing',devEffects={felwing={selectedEffect='felGlow',trailX=12,trailOpacity=7,felDrip={trailX=3,trailOpacity=8}}}},'left')
assert(oldWing.nativeEffect=='felGlow' and oldWing.trailX==12 and oldWing.trailOpacity==7)
assert(E.GetEffectConfig(oldWing,'felDrip').trailX==3 and E.GetEffectConfig(oldWing,'felDrip').trailOpacity==8)
E.devMode=false
print('PASS: baked Felwing defaults/reset on both caps, explicit Glow selection and numeric overrides preserved, personal artwork placement excluded')
local arcaneUpgrade=E.Normalize({version=13,left={art='violetSpire',x=12,flip=false,
    effectLayers={violetSpire={arcaneGlow='back'},stormhornTotem={broadFlame='back'}},
    devEffects={violetSpire={trailX=31,trailOpacity=29}}}})
assert(arcaneUpgrade.left.effectLayer=='front' and arcaneUpgrade.left.x==12 and not arcaneUpgrade.left.flip)
assert(arcaneUpgrade.left.trailX==31 and arcaneUpgrade.left.trailOpacity==29)
assert(arcaneUpgrade.left.effectLayers.stormhornTotem.broadFlame=='back')
E.SetEffectLayer(arcaneUpgrade.left,'back')
assert(E.Normalize(arcaneUpgrade).left.effectLayer=='back', 'front migration runs only once; dev layer remains editable')
print('PASS: one-time arcane front-layer upgrade preserves numeric tuning, artwork placement and other effect layers')
for _,side in ipairs({'left','right'}) do
    local c=E.NormalizeSide({art='violetSpire'},side)
    assert(c.sealSize==153 and c.trailSize==150 and c.trailAngle==90 and c.trailX==-23 and c.trailY==14)
    assert(c.trailOpacity==61 and c.effectLayer=='front' and c.size==100 and c.x==0 and c.y==0)
    local saved=E.NormalizeSide({art='violetSpire',devEffects={violetSpire={sealSize=100,trailOpacity=20}}},side)
    assert(saved.sealSize==100 and saved.trailOpacity==20,'explicit existing calibration remains intact')
    E.devMode=true;E.ResetDevEffect(saved)
    assert(E.GetEffectConfig(saved).sealSize==153 and E.GetEffectConfig(saved).trailOpacity==61)
end
E.devMode=false
print('PASS: approved arcane seal/glow defaults and Reset on both caps, explicit overrides preserved, personal artwork placement excluded')
for _,art in ipairs({'cinderforged','cindermaw'}) do
    local c=E.NormalizeSide({art=art},'left')
    assert(c.flip and not c.moonlight and c.nativeEffect=='fireGlow')
    assert(E.CanSelectEffect(art,'fireGlow') and E.CanSelectEffect(art,'fireFlame') and not E.CanSelectEffect(art,'felDrip'))
    E.devMode=true;E.SetDevEffect(c,'trailX',25);E.SelectEffect(c,'fireFlame');E.SetDevEffect(c,'trailX',-80);E.SetEffectLayer(c,'back')
    EndCapperDB=E.Normalize({version=15,left=c,right={art='wolf',x=12}})
    E.Begin();E.SetDevEffect(E.draft.left,'trailOpacity',12);E.Cancel()
    assert(E.GetEffectConfig(EndCapperDB.left).trailOpacity==(art=='cinderforged' and 30 or 35))
    E.Begin();E.SetDevEffect(E.draft.left,'trailOpacity',51);E.Commit()
    local saved=E.Normalize(EndCapperDB)
    assert(saved.version==43 and saved.left.trailX==-80 and saved.left.trailOpacity==51 and saved.left.effectLayer=='back')
    assert(saved.right.art=='wolf' and saved.right.x==12 and E.GetEffectConfig(saved.left,'fireGlow').trailX==25)
    E.ResetDevEffect(saved.left)
    assert(E.GetEffectConfig(saved.left).trailX==(art=='cinderforged' and -43 or -28) and E.GetEffectConfig(saved.left,'fireGlow').trailX==25)
end
assert(not E.CanSelectEffect('violetSpire','fireFlame'))
print('PASS: molten defaults, effect whitelist, independent calibration/layer, Save/reload/Cancel/Reset and preservation of existing art')
local approved={
    cinderforged={fireGlow={164,90,-37,-21,43},fireFlame={156,172,-43,-10,30}},
    cindermaw={fireGlow={124,90,3,-45,32},fireFlame={150,180,-28,-10,35}},
}
for art,effects in pairs(approved) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=art},side)
        assert(c.size==100 and c.x==0 and c.y==0 and c.flip==(side=='left'))
        for id,expected in pairs(effects) do
            local function check(config)
                local resolved=E.GetEffectConfig(config,id)
                for i,key in ipairs({'trailSize','trailAngle','trailX','trailY','trailOpacity'}) do assert(resolved[key]==expected[i],art..' '..id..' '..key) end
                assert(resolved.effectLayer=='front')
            end
            check(c)
            E.devMode=true;E.SelectEffect(c,id);E.SetDevEffect(c,'trailOpacity',8);E.SetEffectLayer(c,'back')
            local saved=E.NormalizeSide(c,side)
            assert(E.GetEffectConfig(saved,id).trailOpacity==8 and E.GetEffectConfig(saved,id).effectLayer=='back')
            E.ResetDevEffect(saved);check(saved)
        end
    end
end
print('PASS: approved molten defaults/reset on both caps, explicit tuning retained, personal artwork placement excluded')
for _,art in ipairs({'rimeforged','rimeguard'}) do
    local c=E.NormalizeSide({art=art},'left')
    assert(c.flip and not c.moonlight and c.nativeEffect=='coldFlame')
    assert(E.CanSelectEffect(art,'frostEnchant') and not E.CanSelectEffect(art,'fireFlame'))
    E.devMode=true;E.SetDevEffect(c,'trailX',27);E.SelectEffect(c,'frostEnchant');E.SetDevEffect(c,'trailX',-90);E.SetEffectLayer(c,'back')
    EndCapperDB=E.Normalize({version=16,left=c,right={art='cindermaw',size=115,x=16}})
    E.Begin();E.SetDevEffect(E.draft.left,'trailOpacity',12);E.Cancel()
    assert(E.GetEffectConfig(EndCapperDB.left).trailOpacity==(art=='rimeforged' and 5 or 8))
    E.Begin();E.SetDevEffect(E.draft.left,'trailOpacity',51);E.Commit()
    local saved=E.Normalize(EndCapperDB)
    assert(saved.version==43 and saved.left.trailX==-90 and saved.left.trailOpacity==51 and saved.left.effectLayer=='back')
    assert(saved.right.art=='cindermaw' and saved.right.x==16 and saved.right.size==115 and E.GetEffectConfig(saved.left,'coldFlame').trailX==27)
    E.ResetDevEffect(saved.left)
    assert(E.GetEffectConfig(saved.left).trailX==(art=='rimeforged' and -39 or -30) and E.GetEffectConfig(saved.left,'coldFlame').trailX==27)
end
assert(not E.CanSelectEffect('skull','frostEnchant'))
print('PASS: frost schema17 defaults, effect whitelist, separate calibration/layers, Apply/reload/Cancel/Reset and prior artwork preservation')
local approvedFrost={
    rimeforged={coldFlame={176,171,-150,-5,26},frostEnchant={200,-91,-39,72,5}},
    rimeguard={coldFlame={93,129,-89,15,65},frostEnchant={180,-87,-30,43,8}},
}
for art,effects in pairs(approvedFrost) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=art},side)
        assert(c.effects and c.nativeSmoke and c.size==100 and c.x==0 and c.y==0 and c.flip==(side=='left'))
        for id,expected in pairs(effects) do
            local function check(config)
                local resolved=E.GetEffectConfig(config,id)
                for i,key in ipairs({'trailSize','trailAngle','trailX','trailY','trailOpacity'}) do assert(resolved[key]==expected[i],art..' '..id..' '..key) end
                assert(resolved.effectLayer=='front' and resolved.trailOpacity>0)
            end
            check(c)
            E.devMode=true;E.SelectEffect(c,id);E.SetDevEffect(c,'trailOpacity',19);E.SetEffectLayer(c,'back')
            local saved=E.NormalizeSide(c,side)
            assert(E.GetEffectConfig(saved,id).trailOpacity==19 and E.GetEffectConfig(saved,id).effectLayer=='back')
            E.ResetDevEffect(saved);check(saved)
        end
    end
end
print('PASS: approved frost defaults/reset on both caps, all native effects enabled, overrides retained, personal placement excluded')
local well=E.Normalize({version=17,left={art='verdantRoot',x=37},right={art='moonwell'}})
assert(well.version==43 and well.left.art=='verdantRoot' and well.left.x==37 and well.right.art=='moonwell')
assert(E.DefaultMirror('moonwell','left') and not E.DefaultMirror('moonwell','right'))
E.devMode=true;E.SelectEffect(well.right,'waterRipple');E.SetDevEffect(well.right,'trailX',45);E.SetEffectLayer(well.right,'back')
local saved=E.Normalize(well)
assert(saved.right.nativeEffect=='waterRipple' and saved.right.trailX==45 and saved.right.effectLayer=='back')
assert(E.GetEffectConfig(saved.right,'moonwellGlow').trailX==-16)
print('PASS: Moonwell schema migration, default facing and independent persisted native tuning')
local approvedWell={moonwellGlow={200,90,-16,5,67},waterRipple={59,90,-14,-20,45}}
for _,side in ipairs({'left','right'}) do
    local c=E.NormalizeSide({art='moonwell'},side)
    assert(c.size==100 and c.x==0 and c.y==0 and c.flip==(side=='left'))
    for id,expected in pairs(approvedWell) do
        local function check(config)
            local resolved=E.GetEffectConfig(config,id)
            for i,key in ipairs({'trailSize','trailAngle','trailX','trailY','trailOpacity'}) do assert(resolved[key]==expected[i],id..' '..key) end
            assert(resolved.effectLayer=='front')
        end
        check(c)
        E.devMode=true;E.SelectEffect(c,id);E.SetDevEffect(c,'trailOpacity',23);E.SetEffectLayer(c,'back')
        c.size=115;c.x=21;c.y=-19
        local saved=E.NormalizeSide(c,side)
        assert(E.GetEffectConfig(saved,id).trailOpacity==23 and E.GetEffectConfig(saved,id).effectLayer=='back')
        E.ResetDevEffect(saved);check(saved)
        assert(saved.size==115 and saved.x==21 and saved.y==-19)
    end
end
print('PASS: baked Moonwell defaults and Reset on both caps, saved overrides and personal placement retained')
local priest=E.Normalize({version=18,left={art='seraph',size=115,x=21,y=-19},right={art='umbra'}})
assert(priest.version==43 and priest.left.flip and not priest.right.flip and priest.left.nativeEffect=='holyGlow')
E.devMode=false;E.SetHalo(priest.left,'size',175);assert(E.GetHaloConfig(priest.left).size==125)
E.devMode=true;E.SetHalo(priest.left,'size',175);E.SetHalo(priest.left,'period',64);E.SetHalo(priest.left,'reverse',true)
E.SetHalo(priest.right,'x',43)
EndCapperDB=E.Normalize(priest);E.Begin();E.SetHalo(E.draft.left,'size',25);E.Cancel()
assert(E.GetHaloConfig(EndCapperDB.left).size==175 and E.GetHaloConfig(EndCapperDB.right).x==43)
E.Begin();E.SetHalo(E.draft.left,'opacity',37);E.Commit()
local saved=E.Normalize(EndCapperDB)
assert(E.GetHaloConfig(saved.left).opacity==37 and E.GetHaloConfig(saved.left).reverse)
E.SelectArtwork(saved.left,'umbra','left');assert(E.GetHaloConfig(saved.left).size==132)
E.SetHalo(saved.left,'size',900);E.SetHalo(saved.left,'period',0)
assert(E.GetHaloConfig(saved.left).size==250 and E.GetHaloConfig(saved.left).period==8)
E.SelectArtwork(saved.left,'seraph','left');assert(E.GetHaloConfig(saved.left).size==175)
E.ResetHalo(saved.left);assert(E.GetHaloConfig(saved.left).period==40 and not E.GetHaloConfig(saved.left).reverse)
assert(saved.left.size==115 and saved.left.x==21 and saved.left.y==-19)
for _,art in ipairs({'sanctum','eclipse'}) do
    local c=E.NormalizeSide({art=art},'left');assert(not E.GetHaloConfig(c) and c.flip and c.nativeSmoke)
    assert(c.nativeEffect==(art=='sanctum' and 'holyGlow' or 'voidGlow'))
    E.SetHalo(c,'size',150);assert(not c.halos[art])
end
local bad=E.NormalizeSide({art='seraph',halos={seraph={size=0/0,period=math.huge,opacity=-1,reverse='true'},umbra='bad'}},'left')
assert(E.GetHaloConfig(bad).size==125 and E.GetHaloConfig(bad).period==120 and E.GetHaloConfig(bad).opacity==0 and not E.GetHaloConfig(bad).reverse)
print('PASS: priest schema21, per-side/per-art halo persistence, Apply/Cancel, bounds, dev guard and Reset isolation')
for _,spec in ipairs({{'seraph','holyGlow','sunRays'},{'umbra','voidGlow','voidSmoke'}}) do
    for _,side in ipairs({'left','right'}) do
        local art,glow,other=unpack(spec)
        local prior={version=19,[side]={art=art,size=115,x=21,y=-19,halos={[art]={size=172,x=15,y=-7,opacity=47,period=63,reverse=true}}}}
        local db=E.Normalize(prior);local c=db[side]
        assert(db.version==43 and c.nativeEffect==glow and c.nativeSmoke)
        assert(E.GetHaloConfig(c).period==63 and E.GetHaloConfig(c).reverse and c.size==115 and c.x==21)
        E.devMode=false;E.SelectEffect(c,other);E.SetDevEffect(c,'trailOpacity',0)
        assert(E.SelectedEffect(c)==glow and E.GetEffectConfig(c,glow).trailOpacity==(art=='seraph' and 11 or 30))
        E.devMode=true;E.SetDevEffect(c,'trailOpacity',24);E.SelectEffect(c,other)
        E.SetDevEffect(c,'trailX',19);E.SetDevEffect(c,'trailOpacity',0);E.SetEffectLayer(c,'front')
        EndCapperDB=E.Normalize(db);E.Begin();E.SetDevEffect(E.draft[side],'trailX',81);E.Cancel()
        assert(E.GetEffectConfig(EndCapperDB[side],other).trailX==19)
        E.Begin();E.SetDevEffect(E.draft[side],'trailY',28);E.Commit();local saved=E.Normalize(EndCapperDB)[side]
        assert(E.GetEffectConfig(saved,other).trailY==28 and E.GetEffectConfig(saved,other).trailOpacity==0)
        assert(E.GetEffectConfig(saved,other).effectLayer=='front' and E.GetEffectConfig(saved,glow).trailOpacity==24)
        assert(E.GetHaloConfig(saved).size==172 and E.GetHaloConfig(saved).x==15 and saved.x==21 and saved.y==-19)
        E.SelectEffect(saved,art=='seraph' and 'voidSmoke' or 'sunRays');assert(E.SelectedEffect(saved)==other)
        E.ResetDevEffect(saved);assert(E.GetEffectConfig(saved,other).effectLayer=='front' and E.GetEffectConfig(saved,glow).trailOpacity==24)
        assert(E.GetHaloConfig(saved).period==63)
    end
end
print('PASS: schema19 priest upgrade retains halo/placement, isolated native pair tuning, dev guard, whitelist, zero opacity, Apply/Cancel/reload and Reset')
-- Latest applied Seraph radiance is from 00:45:34; other priest bakes from 00:32:55.
-- Each artwork must use its bake on either cap, without baking personal placement.
local approvedPriests={
    seraph={halo={125,-40,31,100,40},holyGlow={171,90,-33,30,11,'back'},sunRays={150,-66,-40,-51,4,'front'}},
    umbra={halo={132,-41,30,100,40},voidGlow={150,90,-39,39,30,'back'},voidSmoke={200,39,76,-128,20,'front'}},
}
local effectKeys={'trailSize','trailAngle','trailX','trailY','trailOpacity','effectLayer'}
local haloKeys={'size','x','y','opacity','period'}
for art,expected in pairs(approvedPriests) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=art},side)
        assert(c.flip==(side=='left') and not E.FlipChecked(c,side))
        assert(c.size==100 and c.x==0 and c.y==0,'personal artwork placement is not a default')
        local function checkEffect(id)
            local cfg=E.GetEffectConfig(c,id)
            for i,key in ipairs(effectKeys) do assert(cfg[key]==expected[id][i],art..' '..side..' '..id..' '..key) end
        end
        local function checkHalo()
            local cfg=E.GetHaloConfig(c)
            for i,key in ipairs(haloKeys) do assert(cfg[key]==expected.halo[i],art..' '..side..' halo '..key) end
            assert(not cfg.reverse)
        end
        checkHalo()
        E.devMode=true;c.size=120;c.x=21;c.y=-19
        for _,id in ipairs(E.PriestEffectPairs[art]) do
            checkEffect(id)
            E.SelectEffect(c,id)
            local custom={121,-23,11,-17,0}
            for i=1,5 do E.SetDevEffect(c,effectKeys[i],custom[i]) end
            local layer=expected[id][6]=='front' and 'back' or 'front'
            E.SetEffectLayer(c,layer);c=E.NormalizeSide(c,side)
            local cfg=E.GetEffectConfig(c,id)
            for i=1,5 do assert(cfg[effectKeys[i]]==custom[i]) end
            assert(cfg.effectLayer==layer and E.SelectedEffect(c)==id)
            E.ResetDevEffect(c);checkEffect(id);checkHalo()
        end
        local customHalo={100,0,0,0,75}
        for i,key in ipairs(haloKeys) do E.SetHalo(c,key,customHalo[i]) end
        E.SetHalo(c,'reverse',true);c=E.NormalizeSide(c,side)
        local halo=E.GetHaloConfig(c)
        for i,key in ipairs(haloKeys) do assert(halo[key]==customHalo[i]) end
        assert(halo.reverse,'explicit halo tuning survives normalization')
        E.ResetHalo(c);checkHalo()
        for _,id in ipairs(E.PriestEffectPairs[art]) do checkEffect(id) end
        assert(c.size==120 and c.x==21 and c.y==-19)
    end
end
print('PASS: approved priest native/halo defaults on both sides, per-art Reset, explicit overrides including zero opacity, and personal placement isolation')
-- Reproduce the reported pair: tuned left edits Radiance; fresh right edits Glow.
-- Both must render the same calibration even though different edit radios are selected.
local seraphPair=E.Normalize({version=20,
    left={art='seraph',flip=true,devEffects={seraph={selectedEffect='sunRays',
        sunRays={trailSize=150,trailAngle=-66,trailX=-40,trailY=-51,trailOpacity=4}}}},
    right={art='seraph',flip=false},
})
assert(E.SelectedEffect(seraphPair.left)=='sunRays' and E.SelectedEffect(seraphPair.right)=='holyGlow')
for _,id in ipairs({'holyGlow','sunRays'}) do
    local left=E.GetEffectConfig(seraphPair.left,id)
    local right=E.GetEffectConfig(seraphPair.right,id)
    for _,key in ipairs(effectKeys) do assert(left[key]==right[key],'saved-left/fresh-right Seraph mismatch: '..key) end
end
assert(seraphPair.left.flip and not seraphPair.right.flip)
print('PASS: tuned left and fresh right Seraph resolve matching paired effects across different edit selections')
-- Approved Sanctum/Eclipse RIGHT calibration from the 01:15:29 save.
local approvedSisters={
    sanctum={holyGlow={149,90,-41,-7,6,'back'},sunRays={150,-66,-40,-51,1,'front'}},
    eclipse={voidGlow={104,90,-45,27,30,'front'},voidSmoke={200,18,65,-70,18,'front'}},
}
for _,pair in ipairs({{'seraph','sanctum','holyGlow','sunRays'},{'umbra','eclipse','voidGlow','voidSmoke'}}) do
    local source,sister,glow,other=unpack(pair)
    for _,side in ipairs({'left','right'}) do
        -- Upgrade the old static sister record, including its resolved disabled flag.
        local db=E.Normalize({version=20,[side]={art=sister,nativeSmoke=false,nativeOnly=true,size=120,x=21,y=-19}})
        local c=db[side];local original=E.NormalizeSide({art=source},side)
        assert(db.version==43 and c.nativeSmoke and c.nativeEffect==glow)
        assert(c.flip==(side=='left') and not E.GetHaloConfig(c))
        local function checkBake(id)
            local actual=E.GetEffectConfig(c,id);local expected=approvedSisters[sister][id]
            for i,key in ipairs(effectKeys) do assert(actual[key]==expected[i],sister..' '..side..' baked '..id..' '..key) end
        end
        checkBake(glow);checkBake(other)
        E.devMode=true
        E.SetDevEffect(original,'trailOpacity',49)
        E.SetDevEffect(c,'trailOpacity',23);E.SelectEffect(c,other)
        E.SetDevEffect(c,'trailOpacity',0);E.SetDevEffect(c,'trailX',12);E.SetEffectLayer(c,'back')
        EndCapperDB=E.Normalize(db);E.Begin();E.SetDevEffect(E.draft[side],'trailX',70);E.Cancel()
        assert(E.GetEffectConfig(EndCapperDB[side],other).trailX==12)
        E.Begin();E.SetDevEffect(E.draft[side],'trailY',-31);E.Commit()
        c=E.Normalize(EndCapperDB)[side]
        assert(E.GetEffectConfig(c,glow).trailOpacity==23 and E.GetEffectConfig(original,glow).trailOpacity==49)
        assert(E.GetEffectConfig(c,other).trailOpacity==0 and E.GetEffectConfig(c,other).effectLayer=='back')
        assert(E.GetEffectConfig(c,other).trailY==-31 and not c.devEffects[source])
        E.SelectArtwork(c,source,side);assert(E.GetEffectConfig(c,other).trailX~=12)
        E.SelectArtwork(c,sister,side);assert(E.GetEffectConfig(c,other).trailX==12)
        E.ResetDevEffect(c)
        checkBake(other)
        assert(E.GetEffectConfig(c,other).effectLayer=='front' and E.GetEffectConfig(c,glow).trailOpacity==23)
        E.SelectEffect(c,glow);E.ResetDevEffect(c);checkBake(glow);checkBake(other)
        assert(not E.GetHaloConfig(c) and c.size==120 and c.x==21 and c.y==-19)
    end
end
print('PASS: schema20 sister upgrade, approved RIGHT defaults on both caps, independent tuning/layers, Apply/Cancel/reload/Reset and no added halos')

-- Removed alternatives must not survive older applied saves.
for _,art in ipairs({'moonbough','lunarRelic'}) do
 for _,side in ipairs({'left','right'}) do
  local c=E.NormalizeSide({art=art,devEffects={[art]={selectedEffect='faerieFire',trailX=17,faerieFire={trailOpacity=0}}},effectLayers={[art]={faerieFire='back'}}},side)
  assert(c.nativeEffect=='moonlight' and c.trailX==17 and not E.CanSelectEffect(art,'faerieFire'))
  assert(not c.devEffects[art].faerieFire and not c.effectLayers[art].faerieFire)
 end
end
assert(E.CanSelectEffect('verdantRoot','faerieFire'))
print('PASS: retired Moonbough/Lunar Faerie Fire saves recover Moonlight; Verdant alternative remains')

for _,side in ipairs({'left','right'}) do
    local c=E.NormalizeSide({art='kirinTor'},side)
    assert(c.nativeEffect=='arcaneGlow' and not c.sealSize)
    assert(c.flip==(side=='left') and E.PairByArt.kirinTor==E.PairByArt.violetSpire)
    local glow=E.GetEffectConfig(c,'arcaneGlow');local original=E.EffectProfiles.violetSpire
    for _,spec in ipairs(E.devEffectFields) do assert(glow[spec[1]]==original[spec[1]]) end
    assert(E.GetEffectConfig(c,'kirinSeal').nativeEffect=='kirinSeal')
    E.devMode=true;E.SelectEffect(c,'kirinSeal');E.SetDevEffect(c,'trailOpacity',27);E.SetEffectLayer(c,'back')
    E.SelectEffect(c,'arcaneGlow');E.SetDevEffect(c,'trailX',11)
    c=E.NormalizeSide(c,side)
    assert(E.GetEffectConfig(c,'kirinSeal').trailOpacity==27 and E.GetEffectConfig(c,'kirinSeal').effectLayer=='back')
    assert(E.GetEffectConfig(c,'arcaneGlow').trailX==11 and original.trailX==-23)
    E.SelectEffect(c,'kirinSeal');E.ResetDevEffect(c)
    assert(E.GetEffectConfig(c,'kirinSeal').trailOpacity==75 and E.GetEffectConfig(c,'arcaneGlow').trailX==11)
end
local oldArcane=E.Normalize({version=28,left={art='violetSpire',size=117,devEffects={violetSpire={sealSize=184,trailX=9}}},
    right={art='violetSpire'},pair={linked=true,art='violetSpire',swapped=true,separation=600}})
assert(oldArcane.left.art=='violetSpire' and oldArcane.right.art=='kirinTor' and oldArcane.pair.separation==600)
assert(oldArcane.left.devEffects.violetSpire.sealSize==184 and oldArcane.left.devEffects.violetSpire.trailX==9)
print('PASS: Kirin Tor sister/default glow, independent native pair tuning/layers/Reset, no spire seal controls, legacy linked clone and preserved spire tuning')

for _,oldChoice in ipairs({false,true}) do
    local restored=E.Normalize({version=30,left={art='violetSpire',size=117,x=12,y=9,
        devEffects={violetSpire={originalCrystal=oldChoice,sealSize=183,trailX=42,trailOpacity=37}}},
        right={art='kirinTor'},pair={linked=false,separation=640}})
    assert(restored.version==43 and restored.left.size==117 and restored.left.x==12 and restored.left.y==9)
    assert(restored.left.devEffects.violetSpire.originalCrystal==nil and restored.left.sealSize==183)
    assert(restored.left.trailX==42 and restored.left.trailOpacity==37 and restored.pair.separation==640)
end
print('PASS: retired native crystal setting removed on schema30 upgrade, custom renderer restored with seal/glow/personal placement retained')

-- Schema 40 changes only Soulbound's layer preference, once, in both modes.
local layerSave={version=39,mode='end',left={art='soulbound',x=17,
    effectLayers={soulbound={felFlame='back',felMagic='back',shadowGlow='back'}}},right={art='hexbound'}}
local raised=E.Normalize(layerSave)
for _,id in ipairs({'felFlame','felMagic','shadowGlow'}) do
    assert(E.GetEffectConfig(raised.left,id).effectLayer==E.GetEffectDefaults('soulbound',id).effectLayer)
    assert(E.GetEffectConfig(raised.otherMode.left,id).effectLayer==E.GetEffectDefaults('soulbound',id).effectLayer)
end
assert(raised.left.x==17 and E.GetEffectConfig(raised.right,'shadowGlow').effectLayer=='front')
E.SelectEffect(raised.left,'shadowGlow');E.SetEffectLayer(raised.left,'back')
local kept=E.Normalize(raised)
assert(E.GetEffectConfig(kept.left,'shadowGlow').effectLayer=='back','Later dev overrides must persist')
print('PASS: Soulbound front-layer upgrade preserves placement, Hexbound layers and later developer choices')
