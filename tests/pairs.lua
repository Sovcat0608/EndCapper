local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
local db=E.Normalize({version=23,left={art='seraph',size=120,x=17,y=-9,flip=false,
    devEffects={seraph={trailOpacity=37}},halos={seraph={size=180}}},right={art='wolf',size=90}})
assert(not db.pair.linked and db.left.art=='seraph' and db.right.art=='wolf')
E.LinkPair(db,'left',true)
assert(db.pair.linked and db.left.art=='seraph' and db.right.art=='sanctum')
assert(db.left.size==120 and db.right.size==120 and db.left.x==0 and db.right.x==0 and db.pair.x==17)
assert(E.FlipChecked(db.left,'left') and E.FlipChecked(db.right,'right'))
assert(db.left.devEffects.seraph.trailOpacity==37 and E.GetHaloConfig(db.left).size==180)
db.pair.centerX=500;db.pair.separation=80;E.SyncPair(db)
assert(db.left.x==0 and db.right.x==0 and db.left.frameX==342 and db.right.frameX==692 and db.left.y==-9 and db.right.y==-9)
db.pair.swapped=true;E.SyncPair(db)
assert(db.left.art=='sanctum' and db.right.art=='seraph' and db.left.frameX==342)
local saved=E.Normalize(db)
assert(saved.pair.linked and saved.pair.swapped and saved.pair.separation==80)
assert(saved.left.art=='sanctum' and saved.right.art=='seraph' and saved.right.size==120)
E.LinkPair(saved,'right',false)
assert(not saved.pair.linked and saved.left.frameX==342 and saved.right.frameX==692)
saved.left.size=75;saved=E.Normalize(saved);assert(saved.right.size==120)
for _,row in ipairs(E.ArtworkPairs) do
    for _,side in ipairs({'left','right'}) do
        for _,art in ipairs(row) do
            local c=E.Normalize({[side]={art=art}})
            E.LinkPair(c,side,true)
            assert(c[side].art==art,'linking keeps selected art on its original side')
            if not row[2] then assert(c.left.art==c.right.art and c.left.flip~=c.right.flip) end
            c.pair.flip=true;E.SyncPair(c)
            if not row[2] then assert(c.left.flip~=c.right.flip) end
        end
    end
end
local bad=E.Normalize({pair={linked=true,art='external',size=0/0,separation=9999,x=999,y=-999}})
assert(bad.pair.art=='skull' and bad.pair.size==100 and bad.pair.separation==2000)
assert(bad.left.x==0 and bad.right.x==0 and bad.pair.x==200 and bad.left.y==-200)
EndCapperDB=db;E.Begin();E.draft.pair.size=77;E.SyncPair(E.draft);E.Cancel()
assert(EndCapperDB.pair.size==120 and EndCapperDB.left.size==120)
E.Begin();E.draft.pair.size=130;E.SyncPair(E.draft);E.Commit()
assert(EndCapperDB.left.size==130 and EndCapperDB.right.size==130)
print('PASS: linked pairs migration, selection orientation, clone mirroring, shared controls, separation, swap, unlink continuity, tuning retention and Apply/Cancel/reload')

for _,art in ipairs({'moonbough','lunarRelic'}) do
 local c=E.Normalize({version=25,left={art=art},right={art=art},pair={linked=true,art=art,swapped=true,size=123,x=17,y=9,separation=40}})
 assert(c.left.art==art and c.right.art==(art=='moonbough' and 'lunarRelic' or 'moonbough'))
 assert(c.left.size==123 and c.left.x==0 and c.right.x==0 and c.pair.x==17 and c.left.y==9)
 local again=E.Normalize(c);assert(again.left.art==c.left.art and again.right.art==c.right.art)
end
assert(E.PairByArt.verdantRoot==E.PairByArt.moonwell)
print('PASS: Moonbough/Lunar legacy linked-clone upgrade preserves left artwork and shared settings; Verdant/Moonwell pairing retained')

local nativeGap=714
E.GetDefaultPairSeparation=function() return nativeGap end
local fresh=E.Normalize({pair={separation=0,linked=false}})
assert(not fresh.pair.separationInitialized)
E.LinkPair(fresh,'left',true);assert(fresh.pair.separation==714 and fresh.pair.separationInitialized)
fresh.pair.separation=932;E.LinkPair(fresh,'left',false)
fresh=E.Normalize(fresh);E.LinkPair(fresh,'left',true);assert(fresh.pair.separation==932)
E.LinkPair(fresh,'left',false);fresh.pair.separation=0;fresh=E.Normalize(fresh)
E.LinkPair(fresh,'right',true);assert(fresh.pair.separation==0)
local position=E.CapturePosition(fresh);assert(position.pair.separationInitialized)
local other=E.Normalize(nil);E.RestorePosition(other,position)
assert(other.pair.separationInitialized and other.pair.separation==0)
nativeGap=856;E.ResetPairSeparation(other);assert(other.pair.separation==856)
local old=E.Normalize({version=27,pair={linked=false,separation=400}})
E.LinkPair(old,'left',true);assert(old.pair.separation==400,'keep earlier saved nonzero gap')
local zero=E.Normalize({version=27,pair={linked=true,separation=0}})
E.LinkPair(zero,'left',false);E.LinkPair(zero,'left',true);assert(zero.pair.separation==0,'keep existing linked zero setting')
print('PASS: initial native gap, custom/zero retention across unlink/relink/normalization, profile round-trip, Reset and schema27 migration')
