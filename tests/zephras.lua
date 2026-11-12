local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile('NativeSmoke.lua'))('EndCapper',E)
assert(loadfile('Clipping.lua'))('EndCapper',E)
assert(E.PairByArt.zephyr==E.PairByArt.skycutter)
assert(E.DefaultMirror('zephyr','left') and not E.DefaultMirror('zephyr','right'))
assert(E.DefaultMirror('skycutter','right') and not E.DefaultMirror('skycutter','left'))
assert(not E.NativeEffectProfiles.skyCloud)
assert(not E.CanSelectEffect('zephyr','skyCloud') and not E.CanSelectEffect('skycutter','skyCloud'))
assert(E.NativeEffectProfiles.rangerWind.fileID==445680)
assert(E.NativeEffectProfiles.skyWind.fileID==460839 and E.NativeEffectProfiles.skyWind.naturalEdges)
assert(E.NativeEffectProfiles.eerieGroundFog.fileID==165743)
assert(E.EffectBaselines.zephyr==984/1024 and E.EffectBaselines.skycutter==999/1024)
E.devMode=true
assert(E.GetEffectConfig(E.NormalizeSide({art='skycutter'},'right'),'skyWind').trailOpacity==1)
EndCapperDB=E.Normalize({left={art='zephyr'},right={art='skycutter'}})
E.Begin()
for _,side in ipairs({'left','right'}) do
    local c=E.draft[side]
    for i,id in ipairs(E.ZephrasEffects[c.art]) do
        assert(E.CanSelectEffect(c.art,id))
        E.SelectEffect(c,id)
        E.SetDevEffect(c,'trailX',i*7)
        E.SetDevEffect(c,'trailOpacity',i*11)
        E.SetEffectLayer(c,i==2 and 'back' or 'front')
    end
    assert(not E.CanSelectEffect(c.art,'blueEyeLeft'))
end
E.Commit();EndCapperDB=E.Normalize(EndCapperDB)
for _,side in ipairs({'left','right'}) do
    local c=EndCapperDB[side]
    for i,id in ipairs(E.ZephrasEffects[c.art]) do
        local fx=E.GetEffectConfig(c,id)
        assert(fx.nativeEffect==id and fx.trailX==i*7 and fx.trailOpacity==i*11)
        assert(fx.effectLayer==(i==2 and 'back' or 'front'))
    end
end
E.Begin();E.SelectEffect(E.draft.left,'rangerWind');E.SetDevEffect(E.draft.left,'trailOpacity',0)
assert(E.GetEffectConfig(E.draft.left,'eerieGroundFog').trailOpacity==22)
assert(E.GetEffectConfig(E.draft.right,'rangerWind').trailOpacity==11)
E.Cancel();assert(E.GetEffectConfig(EndCapperDB.left,'rangerWind').trailOpacity==11)
-- Removed primary cloud fields must not leak into the promoted wind record.
local legacy={art='zephyr',devEffects={zephyr={selectedEffect='skyCloud',trailX=149,
    rangerWind={trailX=37,trailOpacity=9},skyWind={trailX=-22,trailOpacity=4}}},effectLayers={zephyr={skyCloud='back',rangerWind='front'}}}
local upgraded=E.NormalizeSide(legacy,'left')
assert(E.SelectedEffect(upgraded)=='rangerWind')
assert(E.GetEffectConfig(upgraded,'rangerWind').trailX==37 and E.GetEffectConfig(upgraded,'rangerWind').trailOpacity==9)
assert(E.GetEffectConfig(upgraded,'skyWind').trailX==-22)
assert(not upgraded.effectLayers.zephyr.skyCloud and not upgraded.devEffects.zephyr.rangerWind)
assert(legacy.devEffects.zephyr.trailX==149 and legacy.devEffects.zephyr.rangerWind.trailX==37)
local again=E.NormalizeSide(upgraded,'left')
assert(E.GetEffectConfig(again,'rangerWind').trailX==37)
legacy.devEffects.zephyr.rangerWind=nil
assert(E.GetEffectConfig(E.NormalizeSide(legacy,'left'),'rangerWind').trailX==-46)
print('PASS: Zephras reversed facing, cloud retirement/primary migration, three independent tunings/layers, Save/reload, opacity isolation and Cancel')
