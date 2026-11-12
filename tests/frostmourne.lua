local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile('Clipping.lua'))('EndCapper',E)
assert(E.schemaVersion==43 and #E.artworks==32)
assert(E.PairByArt.frostmourneHilt==E.PairByArt.frostmourneBlade)
E.devMode=true
for _,side in ipairs({'left','right'}) do
    for _,art in ipairs({'frostmourneHilt','frostmourneBlade'}) do
        local c=E.NormalizeSide({art=art},side)
        assert(c.nativeEffect=='frostGlow' and E.EffectBaselines[art]==467/512)
        assert(c.flip==(side==(art=='frostmourneHilt' and 'right' or 'left')))
        assert(E.CanSelectEffect(art,'frostMist') and E.CanSelectEffect(art,'coldFlame')==(art=='frostmourneHilt'))
        E.SetDevEffect(c,'trailX',27);E.SetDevEffect(c,'trailOpacity',19)
        E.SelectEffect(c,'frostMist');E.SetDevEffect(c,'trailX',-32);E.SetDevEffect(c,'trailOpacity',0)
        E.SetEffectLayer(c,'back')
        local saved=E.NormalizeSide(c,side)
        assert(saved.nativeEffect=='frostMist' and saved.trailOpacity==0 and saved.trailX==-32 and saved.effectLayer=='back')
        local glow=E.GetEffectConfig(saved,'frostGlow')
        assert(glow.trailX==27 and glow.trailOpacity==19)
        E.ResetDevEffect(saved)
        assert(E.GetEffectConfig(saved).trailOpacity==1 and E.GetEffectConfig(saved).effectLayer=='front')
        assert(E.GetEffectConfig(saved,'frostGlow').trailOpacity==19)
        E.devMode=false;E.SelectEffect(saved,'frostGlow');assert(E.SelectedEffect(saved)=='frostMist');E.devMode=true
    end
end
local db=E.Normalize({version=33,left={art='frostmourneHilt'},right={art='wolf'},pair={separation=740,separationInitialized=true}})
E.LinkPair(db,'left',true)
assert(db.left.art=='frostmourneHilt' and db.right.art=='frostmourneBlade' and not db.left.flip and not db.right.flip)
assert(db.pair.separation==740)
db.pair.swapped=true;E.SyncPair(db)
assert(db.left.art=='frostmourneBlade' and db.right.art=='frostmourneHilt' and db.left.flip and db.right.flip)
local reloaded=E.Normalize(db)
assert(reloaded.pair.swapped and reloaded.pair.separation==740)
EndCapperDB=reloaded;E.Begin();E.draft.pair.size=155;E.SyncPair(E.draft);E.Cancel()
assert(EndCapperDB.left.size==100)
E.Begin();E.draft.pair.size=155;E.SyncPair(E.draft);E.Commit()
assert(EndCapperDB.left.size==155 and EndCapperDB.right.size==155)
E.devMode=false
print('PASS: Frostmourne pair defaults/facing, separate effect tuning/layers/zero opacity/reset, Swap, spacing, Save/Cancel/reload')
