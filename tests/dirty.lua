local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
EndCapperDB=E.Normalize({left={art='wolf'},right={art='seraph'}})
assert(not E.HasChanges());E.Begin();assert(not E.HasChanges())
for _,key in ipairs({'size','x','y'}) do
    local original=E.draft.left[key];E.draft.left[key]=original+1;assert(E.HasChanges())
    E.draft.left[key]=original;assert(not E.HasChanges())
end
E.draft.left.flip=not E.draft.left.flip;assert(E.HasChanges())
E.draft.left.flip=not E.draft.left.flip;assert(not E.HasChanges())
E.devMode=true
local original=E.GetEffectConfig(E.draft.left).trailX
E.SetDevEffect(E.draft.left,'trailX',original+1);assert(E.HasChanges())
E.SetDevEffect(E.draft.left,'trailX',original);assert(not E.HasChanges(),'explicit original defaults are not a change')
E.SetEffectLayer(E.draft.left,'back');assert(E.HasChanges())
E.SetEffectLayer(E.draft.left,'front');assert(not E.HasChanges())
local halo=E.GetHaloConfig(E.draft.right)
E.SetHalo(E.draft.right,'size',halo.size+1);assert(E.HasChanges())
E.SetHalo(E.draft.right,'size',halo.size);assert(not E.HasChanges())
E.SelectEffect(E.draft.right,'sunRays');assert(E.HasChanges())
E.SelectEffect(E.draft.right,'holyGlow');assert(not E.HasChanges())
E.SetDevEffect(E.draft.left,'trailOpacity',25);E.Commit();E.Begin();assert(not E.HasChanges())
E.SetDevEffect(E.draft.left,'trailOpacity',26);assert(E.HasChanges());E.Cancel();E.Begin();assert(not E.HasChanges())
EndCapperDB=E.Normalize({left={art='seraph'},right={art='sanctum'},pair={linked=true,art='seraph',centerX=1000}})
E.Cancel();E.Begin();assert(not E.HasChanges())
E.draft.pair.centerX=1100;E.SyncPair(E.draft);assert(E.HasChanges(),'a linked drag changes the saved centre')
E.draft.pair.centerX=1000;E.SyncPair(E.draft);assert(not E.HasChanges())
E.draft.left.frameX=0;assert(not E.HasChanges(),'derived linked side X stays outside the dirty check')
E.draft.left.frameBottom=false;E.draft.left.frameY=200;assert(E.HasChanges())
E.draft.left.frameBottom=true;E.draft.left.frameY=nil
E.draft.pair.swapped=true;E.SyncPair(E.draft);assert(E.HasChanges())
E.draft.pair.swapped=false;E.SyncPair(E.draft);assert(not E.HasChanges())
E.draft.pair.separation=200;E.SyncPair(E.draft);assert(E.HasChanges())
E.draft.pair.separation=0;E.SyncPair(E.draft);assert(not E.HasChanges())
E.Cancel()
print('PASS: semantic unsaved changes, restoring original values/defaults, native/halo tuning, radio/layers, commit/cancel and ignored runtime positioning caches')

