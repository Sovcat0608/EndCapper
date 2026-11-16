local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
assert(E.artworkByID.timekeeper.name=='Timelost' and E.artworkByID.timelost.name=='Timekeeper')
local old={version=43,left={art='timekeeper',flip=true},right={art='timelost',flip=true},
    pair={linked=true,art='timekeeper',flip=true},positionProfiles={
        linked={left={art='timekeeper',flip=true},right={art='timelost',flip=true},pair={linked=true,art='timekeeper',flip=true}},
        other={left={art='wolf'},right={art='whiteWorgen'},pair={linked=true,art='wolf',flip=true}}}}
local migrated=E.Normalize(old)
assert(not migrated.pair.flip and migrated.left.flip and migrated.right.flip)
assert(not migrated.positionProfiles.linked.pair.flip and migrated.positionProfiles.other.pair.flip)
assert(equal(migrated,E.Normalize(migrated)) and old.pair.flip,'Migration is idempotent and leaves input intact')
E.RestorePosition(migrated,migrated.positionProfiles.linked)
assert(migrated.left.flip and migrated.right.flip,'Restoring an older layout preserves facing')
for _,side in ipairs({'left','right'}) do
    for _,art in ipairs({'timekeeper','timelost'}) do
        local c=E.NormalizeSide({art=art},side)
        assert(#E.GetAddedEffects(c)==4 and equal(E.GetAddedEffects(c),E.AddedEffectDefaults[art]))
        assert(c.flip==(side==(art=='timekeeper' and 'left' or 'right')))
        local rows=E.GetAddedEffects(c);rows[1].trailX=999
        assert(E.GetAddedEffects(c)[1].trailX~=999,'Fallback must not expose mutable defaults')
    end
end
E.devMode=true
EndCapperDB=E.Normalize({left={art='timekeeper',flip=false,size=121,x=17,y=29},right={art='timelost',flip=true}})
E.Begin();assert(not E.HasChanges())
E.EditAddedEffects(E.draft.left);assert(not E.HasChanges(),'Materializing defaults is not a change')
E.EditAddedEffects(E.draft.left)[1].trailY=99;assert(E.HasChanges())
E.Cancel();E.Begin();assert(E.GetAddedEffects(E.draft.left)[1].trailY==25)
assert(E.draft.left.size==121 and E.draft.left.x==17 and E.draft.left.y==29 and not E.draft.left.flip)
assert(E.AddLibraryEffect(E.draft.left,{fileID=166011,name='Extra'})==5)
assert(E.GetAddedEffects(E.draft.left)[1].fileID==1688083)
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin()
assert(#E.GetAddedEffects(E.draft.left)==5 and not E.HasChanges())
for i=5,1,-1 do E.RemoveLibraryEffect(E.draft.left,i) end
assert(E.HasChanges());E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin()
assert(#E.GetAddedEffects(E.draft.left)==0 and not E.HasChanges(),'Explicit empty survives reload')
E.SelectMode(E.draft,'corner');assert(#E.GetAddedEffects(E.draft.left)==4 and #E.GetAddedEffects(E.draft.right)==4)
E.SelectMode(E.draft,'end');assert(#E.GetAddedEffects(E.draft.left)==0)
local override=E.NormalizeSide({art='timelost',addedEffects={timelost={{fileID=166011,trailX=88}}}},'right')
assert(#E.GetAddedEffects(override)==1 and E.GetAddedEffects(override)[1].trailX==88)
print('Time pair bake PASS: names, facing, default isolation, editable defaults, Save/Cancel, removal and both modes')
