local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
local former={fileID=166009}
-- Explicitly authored bindings become aesthetic layers without discarding
-- their visual tuning or surrounding profiles on retained artwork.
former.behavior='bound';former.binding={kind='cast',spell='Arcane Blast',intro=true,duration=2}
former.animation=158;former.trailX=37;former.trailOpacity=42
local saved={version=45,left={art='timekeeper',x=21,size=133,addedEffects={timekeeper={former}}},right={art='timelost'}}
local db=E.Normalize(saved)
assert(db.version==49 and db.left.x==21 and db.left.size==133)
local row=E.GetAddedEffects(db.left)[1]
assert(not row.behavior and not row.binding and row.animation==158 and row.trailX==37 and row.trailOpacity==42)
assert(#E.GetAddedEffects(db.right)==4 and #E.GetAddedEffects(E.NormalizeSide({art='timekeeper'},'left'))==4)
assert(saved.left.addedEffects.timekeeper[1].binding.spell=='Arcane Blast','Normalization must not mutate its input')
EndCapperDB=db;E.Begin();assert(not E.HasChanges());E.Commit();assert(not E.GetAddedEffects(EndCapperDB.left)[1].binding)
assert(not E.ConfigureCastEffect and not E.ConfigureBoundEffect and not E.TestCastEffect)
print('PASS: former binding metadata removed, ambient layers/tuning and artwork placement preserved, schema-45 upgrade and clean persistence')
