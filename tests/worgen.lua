local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(E.schemaVersion==43 and #E.artworks==32)
assert(E.PairByArt.wolf==E.PairByArt.whiteWorgen)
for _,side in ipairs({'left','right'}) do
    local db=E.Normalize({version=31,[side]={art='wolf',size=133,x=17,y=23,flip=true,
        devEffects={wolf={trailX=-92,trailY=-7,trailOpacity=51}},effectLayers={wolf={coldFlame='back'}}}})
    local c=db[side]
    assert(c.art=='wolf' and c.size==133 and c.x==17 and c.y==23 and c.flip)
    assert(c.trailX==-92 and c.trailOpacity==51 and c.effectLayer=='back')
    assert(E.GetEffectConfig(c,'worgenGloom').effectLayer=='front')
    E.devMode=true
    E.SelectEffect(c,'worgenGloom');E.SetDevEffect(c,'trailX',43);E.SetDevEffect(c,'trailOpacity',27)
    E.SetEffectLayer(c,'front')
    E.SelectEffect(c,'coldFlame');assert(E.GetEffectConfig(c).trailX==-92 and E.GetEffectConfig(c).trailOpacity==51)
    E.SelectArtwork(c,'whiteWorgen',side)
    E.SelectEffect(c,'worgenGloom');assert(E.GetEffectConfig(c).trailX==2)
    E.SetDevEffect(c,'trailX',-41);E.SetDevEffect(c,'trailOpacity',0)
    E.SetEffectLayer(c,'back')
    local saved=E.NormalizeSide(c,side)
    assert(saved.art=='whiteWorgen' and saved.nativeEffect=='worgenGloom' and saved.trailOpacity==0)
    assert(E.GetEffectConfig(saved,'amberFlow').trailX==34)
    E.ResetDevEffect(saved);assert(E.GetEffectConfig(saved).trailOpacity==100)
    E.SelectArtwork(saved,'wolf',side);E.SelectEffect(saved,'worgenGloom')
    assert(E.GetEffectConfig(saved).trailX==43 and E.GetEffectConfig(saved).trailOpacity==27 and E.GetEffectConfig(saved).effectLayer=='front')
    E.devMode=false
    E.SelectEffect(saved,'coldFlame');assert(E.SelectedEffect(saved)=='worgenGloom','selection remains dev-only')
    assert(not E.CanSelectEffect('wolf','voidSmoke') and not E.CanSelectEffect('skull','worgenGloom'))
end
local old=E.Normalize({version=31,left={art='wolf'},right={art='wolf'},pair={linked=true,art='wolf',swapped=true,separation=750,size=134,x=16,y=19}})
assert(old.left.art=='wolf' and old.right.art=='whiteWorgen' and not old.pair.swapped)
assert(old.pair.separation==750 and old.left.size==134 and old.right.y==19)
old.pair.swapped=true;E.SyncPair(old)
old=E.Normalize(old);assert(old.left.art=='whiteWorgen' and old.right.art=='wolf' and old.pair.swapped)
assert(E.DefaultMirror('wolf','right') and E.DefaultMirror('whiteWorgen','left'))
assert(not E.DefaultMirror('wolf','left') and not E.DefaultMirror('whiteWorgen','right'))
print('PASS: new Worgen sisters, old trail/placement preservation, paired clone upgrade, swap, per-art/effect tuning/layers/opacity/reset and dev guard')

for _,side in ipairs({'left','right'}) do
    for _,selected in ipairs({'coldFlame','worgenGloom'}) do
        local source={version=32,[side]={art='whiteWorgen',size=137,x=12,y=-9,flip=true,
            devEffects={whiteWorgen={selectedEffect=selected,trailSize=173,trailAngle=-75,trailX=51,trailY=-23,trailOpacity=0,
                worgenGloom={trailSize=167,trailAngle=24,trailX=-37,trailY=41,trailOpacity=29}}},
            effectLayers={whiteWorgen={coldFlame='back',worgenGloom='front'}}}}
        local db=E.Normalize(source);local c=db[side]
        local amber=E.GetEffectConfig(c,'amberFlow');local gloom=E.GetEffectConfig(c,'worgenGloom')
        assert(c.nativeEffect==(selected=='coldFlame' and 'amberFlow' or 'worgenGloom'))
        assert(amber.nativeEffect=='amberFlow' and amber.trailSize==173 and amber.trailAngle==-75 and amber.trailX==51 and amber.trailY==-23 and amber.trailOpacity==0 and amber.effectLayer=='back')
        assert(gloom.trailSize==167 and gloom.trailAngle==24 and gloom.trailX==-37 and gloom.trailY==41 and gloom.trailOpacity==29 and gloom.effectLayer=='front')
        assert(c.size==137 and c.x==12 and c.y==-9 and c.flip and not c.effectLayers.whiteWorgen.coldFlame)
        assert(source[side].effectLayers.whiteWorgen.coldFlame=='back' and not source[side].effectLayers.whiteWorgen.amberFlow,'do not mutate saved inputs')
        local roundtrip=E.Normalize(db)
        assert(E.GetEffectConfig(roundtrip[side],'amberFlow').effectLayer=='back')
        assert(not E.CanSelectEffect('whiteWorgen','coldFlame') and not E.CanSelectEffect('wolf','amberFlow'))
    end
end
local explicit=E.NormalizeSide({art='whiteWorgen',effectLayers={whiteWorgen={coldFlame='back',amberFlow='front'}}},'left')
assert(explicit.effectLayer=='front','explicit amber layer wins over legacy layer')
local black=E.NormalizeSide({art='wolf',effectLayers={wolf={coldFlame='back'}}},'left')
assert(black.nativeEffect=='coldFlame' and black.effectLayer=='back')
print('PASS: Whitefang amber migration retains all numeric tuning/Gloom/zero/layers/selection/placement, idempotence and input immutability; Blackfang remains blue')

-- Approved 2026-11-10 21:07:49 UTC save: left Shadowfang/right Snowfang.
local approved={wolf={coldFlame={100,-113,-98,28,64},worgenGloom={90,-91,10,-91,100}},
    whiteWorgen={amberFlow={100,113,34,17,27},worgenGloom={91,-91,2,-79,100}}}
local fields={'trailSize','trailAngle','trailX','trailY','trailOpacity'}
E.devMode=true
for art,effects in pairs(approved) do
    for _,side in ipairs({'left','right'}) do
        local c=E.NormalizeSide({art=art},side)
        for effect,values in pairs(effects) do
            local resolved=E.GetEffectConfig(c,effect)
            for i,key in ipairs(fields) do assert(resolved[key]==values[i],art..' baked '..key) end
            assert(resolved.effectLayer=='front')
            E.SelectEffect(c,effect);E.SetDevEffect(c,'trailX',77);E.SetDevEffect(c,'trailOpacity',0)
            E.SetEffectLayer(c,'back');E.ResetDevEffect(c)
            resolved=E.GetEffectConfig(E.NormalizeSide(c,side),effect)
            for i,key in ipairs(fields) do assert(resolved[key]==values[i],art..' Reset '..key) end
            assert(resolved.effectLayer=='front')
        end
    end
end
E.devMode=false
print('PASS: all four approved Worgen effect defaults/Reset on either cap, front layers and no personal artwork placement in defaults')
