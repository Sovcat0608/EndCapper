local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(E.PairByArt.banshee==E.PairByArt.highGeneral)
assert(E.artworkByID.highGeneral.name=='High General')
assert(#E.SylvanasEffects.banshee==4 and #E.SylvanasEffects.highGeneral==5)
assert(E.CanSelectEffect('banshee','voidGlow') and not E.CanSelectEffect('banshee','rangerWind'))
assert(E.CanSelectEffect('highGeneral','rangerWind') and not E.CanSelectEffect('highGeneral','voidGlow'))
assert(E.GetEffectDefaults('banshee','voidGlow').trailSize==150)
assert(E.CanSelectEffect('highGeneral','sunRays') and not E.CanSelectEffect('banshee','sunRays'))
assert(E.GetEffectDefaults('highGeneral','sunRays').trailOpacity==1)
assert(not E.DefaultMirror('banshee','left') and E.DefaultMirror('banshee','right'))
assert(not E.DefaultMirror('highGeneral','right') and E.DefaultMirror('highGeneral','left'))
E.devMode=true
EndCapperDB=E.Normalize({left={art='banshee'},right={art='highGeneral'}})
E.Begin()
for _,side in ipairs({'left','right'}) do
    local c=E.draft[side]
    for i,id in ipairs(E.SylvanasEffects[c.art]) do
        assert(E.CanSelectEffect(c.art,id))
        E.SelectEffect(c,id)
        E.SetDevEffect(c,'trailX',i*7)
        E.SetDevEffect(c,'trailOpacity',i*11)
        E.SetEffectLayer(c,i%2==0 and 'back' or 'front')
    end
    assert(not E.CanSelectEffect(c.art,'amberEyeLeft'))
end
E.Commit()
EndCapperDB=E.Normalize(EndCapperDB)
for _,side in ipairs({'left','right'}) do
    local c=EndCapperDB[side]
    for i,id in ipairs(E.SylvanasEffects[c.art]) do
        local effect=E.GetEffectConfig(c,id)
        assert(effect.nativeEffect==id and effect.trailX==i*7 and effect.trailOpacity==i*11)
        assert(effect.effectLayer==(i%2==0 and 'back' or 'front'))
    end
end
E.Begin();E.SelectEffect(E.draft.left,'redEyeLeft');E.SetDevEffect(E.draft.left,'trailOpacity',0)
assert(E.GetEffectConfig(E.draft.left,'redEyeRight').trailOpacity==33)
E.Cancel();assert(E.GetEffectConfig(EndCapperDB.left,'redEyeLeft').trailOpacity==22)
print('PASS: Sylvanas pair, default mirroring, independently persisted tunings/layers, eye isolation and Cancel')
