local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(not E.artworkByID.arcaneTome and not E.artworkByID.arcaneScroll)
assert(not E.PairByArt.arcaneTome and not E.PairByArt.arcaneScroll and #E.artworks==36)
assert(not E.ArcaneArtworks and not E.GetEmissionConfig and not E.SetEmission)
local function side(art)
    return {art=art,size=127,x=19,y=-12,frameX=345,frameY=76,flip=true,
        books={arcaneTome={size=120},frostbound={size=115}},
        sigils={arcaneScroll={size=200},emberbound={size=75}},
        emissions={arcaneTome={opacity=88}},
        addedEffects={arcaneTome={{fileID=166009}},arcaneScroll={{fileID=166009}},timekeeper={{fileID=166033,trailOpacity=23}}}}
end
local source={version=46,mode='end',left=side('arcaneTome'),right=side('arcaneScroll'),
    pair={art='arcaneTome',linked=true,size=127,separation=680,x=17,y=8},
    positionProfiles={retired={left=side('arcaneTome'),right=side('arcaneScroll'),pair={art='arcaneScroll',linked=true,separation=720}},
        mixed={left=side('arcaneScroll'),right=side('frostbound'),pair={linked=false}}},
    otherMode={left=side('arcaneScroll'),right=side('emberbound'),pair={linked=false}}}
local db=E.Normalize(source)
assert(db.version==47 and db.left.art=='hidden' and db.right.art=='hidden' and db.pair.art=='hidden')
assert(db.pair.separation==680 and db.pair.x==17 and db.pair.size==127)
assert(db.otherMode.left.art=='hidden' and db.otherMode.right.art=='emberbound')
assert(db.otherMode.left.x==19 and db.otherMode.left.y==-12 and db.otherMode.left.frameX==345)
assert(db.left.books.arcaneTome==nil and db.left.books.frostbound.size==115)
assert(db.left.sigils.arcaneScroll==nil and db.left.sigils.emberbound.size==75 and db.left.emissions==nil)
assert(db.left.addedEffects.arcaneTome==nil and db.left.addedEffects.arcaneScroll==nil)
assert(db.left.addedEffects.timekeeper[1].trailOpacity==23)
local p=db.positionProfiles.retired
assert(p.left.art=='hidden' and p.right.art=='hidden' and p.pair.art=='hidden' and p.pair.separation==720)
E.RestorePosition(db,p);assert(db.left.art=='hidden' and db.right.art=='hidden')
E.RestorePosition(db,db.positionProfiles.mixed);assert(db.left.art=='hidden' and db.right.art=='frostbound')
assert(source.left.art=='arcaneTome' and source.left.emissions.arcaneTome.opacity==88,'Input is not mutated')
EndCapperDB=E.Normalize(db);E.Begin();assert(not E.HasChanges());E.Commit()
assert(EndCapperDB.left.art=='hidden' and EndCapperDB.right.art=='frostbound')
print('PASS: removed pair absent; active/other modes and linked/unlinked layout profiles migrate to Hidden; retired tuning pruned, other art and placement preserved')
