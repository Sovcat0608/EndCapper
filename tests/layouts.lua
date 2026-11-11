local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile('Layouts.lua'))('EndCapper',E)
local oldAPI,oldEnum,oldGUID,oldPresets=C_EditMode,Enum,UnitGUID,EditModePresetLayoutManager
Enum={EditModeLayoutType={Preset=0,Account=1,Character=2}}
EditModePresetLayoutManager={presetLayoutInfo={
    {layoutName='Modern',layoutType=0,interfaceStyle=0},
    {layoutName='Classic',layoutType=0,interfaceStyle=0},
    {layoutName='Controller',layoutType=0,interfaceStyle=1}}}
local guid='Player-A'
UnitGUID=function() return guid end
-- GetLayouts excludes presets, but activeLayout includes their indices.
local info={activeLayout=4,layouts={{layoutName='Raid',layoutType=1},{layoutName='Solo',layoutType=1}}}
C_EditMode={GetLayouts=function() return info end}
EndCapperDB=E.Normalize({left={art='wolf',x=13,y=24,size=120},right={art='wolf'},
    pair={linked=true,art='wolf',size=120,centerX=700,separation=600,x=15,y=24}})
local allowed,changed=E.ReconcilePositionLayout();local raid=E.activePositionLayout
assert(allowed and changed and raid and EndCapperDB.pair.separation==600)
E.Begin();E.draft.pair.separation=800;E.draft.pair.y=17;E.SyncPair(E.draft);E.Commit()
assert(EndCapperDB.positionProfiles[raid].pair.separation==800)
E.Begin();E.draft.pair.separation=1900
info.activeLayout=5;allowed,changed=E.ReconcilePositionLayout();local solo=E.activePositionLayout
assert(allowed and changed and solo~=raid and not E.draft)
assert(EndCapperDB.positionProfiles[raid].pair.separation==800,'unapplied preview must not leak into outgoing profile')
assert(not EndCapperDB.pair.linked and not EndCapperDB.left.frameBottom and not EndCapperDB.left.frameX)
EndCapperDB.left.x=22;EndCapperDB.left.y=35;EndCapperDB.left.size=135;EndCapperDB.left.frameBottom=true;EndCapperDB.left.frameX=900
E.SavePositionProfile()
info.activeLayout=4;E.ReconcilePositionLayout()
assert(E.activePositionLayout==raid and EndCapperDB.pair.linked and EndCapperDB.pair.separation==800 and EndCapperDB.left.y==17)
info.layouts[2].layoutName='Solo renamed';allowed,changed=E.ReconcilePositionLayout()
assert(allowed and not changed and E.activePositionLayout==raid and not EndCapperDB.positionProfiles[solo])
info.activeLayout=5;E.ReconcilePositionLayout()
solo=E.activePositionLayout
assert(EndCapperDB.left.x==22 and EndCapperDB.left.y==35 and EndCapperDB.left.frameX==900 and EndCapperDB.left.size==135)
-- Reload: the root's most recent positions must not overwrite another profile.
EndCapperDB=E.Normalize(EndCapperDB);E.activePositionLayout=nil;E.positionLayoutKeys=nil
info.activeLayout=4;E.ReconcilePositionLayout();assert(EndCapperDB.pair.separation==800)
info.layouts[1].layoutName='Raid renamed';allowed,changed=E.ReconcilePositionLayout()
local renamed=E.activePositionLayout
assert(allowed and not changed and renamed~=raid and not EndCapperDB.positionProfiles[raid])
assert(EndCapperDB.positionProfiles[renamed].pair.separation==800)
table.remove(info.layouts,1);info.activeLayout=4;E.ReconcilePositionLayout()
assert(E.activePositionLayout==solo and EndCapperDB.left.x==22,'index changes after deletion must not mix layouts')
assert(not EndCapperDB.positionProfiles[renamed],'switching away from a deleted layout must not save it again')
-- New native copies inherit committed placement, then become independent.
table.insert(info.layouts,{layoutName='Raid renamed',layoutType=1});info.activeLayout=5;E.ReconcilePositionLayout()
assert(EndCapperDB.left.x==22 and EndCapperDB.left.frameX==900)
assert(not EndCapperDB.pair.linked,'reusing the deleted name inherits current placement')
info.activeLayout=4;E.ReconcilePositionLayout()
E.Begin();table.remove(info.layouts,2);E.ReconcilePositionLayout()
assert(not EndCapperDB.positionProfiles[renamed] and not E.draft.positionProfiles[renamed],
    'deleting an inactive layout removes its record from the open draft as well')
E.Commit()
table.insert(info.layouts,{layoutName='Solo copy',layoutType=1});info.activeLayout=5;E.ReconcilePositionLayout()
assert(EndCapperDB.left.x==22 and EndCapperDB.left.frameX==900)
table.insert(info.layouts,{layoutName='Character',layoutType=2});info.activeLayout=6;E.ReconcilePositionLayout()
EndCapperDB.left.x=42;E.SavePositionProfile();local characterA=E.activePositionLayout
guid='Player-B';E.ReconcilePositionLayout();local characterB=E.activePositionLayout
assert(characterA~=characterB and EndCapperDB.left.x==0 and EndCapperDB.positionProfiles[characterA])
guid='Player-A';E.ReconcilePositionLayout();assert(EndCapperDB.left.x==42)
info.layouts[3].interfaceStyle=1;E.ReconcilePositionLayout();assert(EndCapperDB.left.x==0)
local stable=E.activePositionLayout
C_EditMode.GetLayouts=function() error('not ready') end
E.Begin();E.draft.left.x=81
allowed=E.ReconcilePositionLayout();assert(allowed and E.activePositionLayout==stable and E.draft.left.x==81)
C_EditMode.GetLayouts=function() return {activeLayout=99,layouts=info.layouts} end
allowed=E.ReconcilePositionLayout();assert(allowed and E.activePositionLayout==stable and E.draft.left.x==81)
E.Cancel();C_EditMode.GetLayouts=function() return info end
info.activeLayout=1;E.ReconcilePositionLayout();local modern=E.activePositionLayout
assert(modern~=stable and modern:find('Modern',1,true))
EndCapperDB.left.x=55;EndCapperDB.otherMode.left.frameX=65;EndCapperDB.otherMode.enabled=true;E.SavePositionProfile()
info.activeLayout=2;E.ReconcilePositionLayout();assert(EndCapperDB.left.x==0 and not EndCapperDB.otherMode.left.frameX)
info.activeLayout=1;E.ReconcilePositionLayout();assert(EndCapperDB.left.x==55 and EndCapperDB.otherMode.left.frameX==65 and EndCapperDB.otherMode.enabled)
assert(#info.layouts==3 and #EditModePresetLayoutManager.presetLayoutInfo==3,'native layout tables stay unchanged')
-- Delayed first metadata must not throw away an already open preview.
E.activePositionLayout=nil;E.positionLayoutKeys=nil
E.Begin();E.draft.left.x=83;E.ReconcilePositionLayout()
assert(E.draft and E.draft.left.x==83 and E.activePositionLayout==modern)
E.Cancel()
-- Upgrade a placement-only record, then save distinct choices in both modes.
EndCapperDB=E.Normalize({version=41,left={art='kirinTor',flip=false},right={art='violetSpire'},
    pair={linked=true,art='violetSpire',swapped=true},
    positionProfiles={[modern]={left={x=19},pair={linked=true}}},
    otherMode={left={art='cryptgate'},right={art='plaguewell'}}})
assert(EndCapperDB.positionProfiles[modern].pair.art=='violetSpire' and EndCapperDB.positionProfiles[modern].pair.swapped)
E.activePositionLayout=nil;E.ReconcilePositionLayout()
assert(EndCapperDB.left.art=='kirinTor' and EndCapperDB.right.art=='violetSpire')
info.activeLayout=2;E.ReconcilePositionLayout()
E.Begin();E.SelectArtwork(E.draft.left,'wolf','left');E.draft.left.flip=false
E.SelectArtwork(E.draft.right,'hidden','right')
E.SelectMode(E.draft,'corner');E.LinkPair(E.draft,'left',true)
E.SelectPair(E.draft,'hexbound');E.draft.pair.swapped=true;E.draft.pair.flip=true;E.SyncPair(E.draft)
E.Commit()
info.activeLayout=1;E.ReconcilePositionLayout()
assert(EndCapperDB.left.art=='cryptgate' and EndCapperDB.right.art=='plaguewell')
assert(EndCapperDB.otherMode.left.art=='kirinTor' and EndCapperDB.otherMode.pair.swapped)
EndCapperDB=E.Normalize(EndCapperDB);E.activePositionLayout=nil;E.positionLayoutKeys=nil
info.activeLayout=2;E.ReconcilePositionLayout()
assert(EndCapperDB.left.art=='soulbound' and EndCapperDB.right.art=='hexbound' and EndCapperDB.pair.flip)
assert(EndCapperDB.otherMode.left.art=='wolf' and EndCapperDB.otherMode.left.flip==false and EndCapperDB.otherMode.right.art=='hidden')
C_EditMode=nil;allowed=E.ReconcilePositionLayout();assert(allowed)
local bad=E.Normalize({positionProfiles={valid={left={x=math.huge,size=999},pair={separation=9999}},invalid='bad'}})
assert(bad.positionProfiles.valid.left.x==200 and bad.positionProfiles.valid.left.size==200 and bad.positionProfiles.valid.pair.separation==2000)
assert(not bad.positionProfiles.invalid)
EndCapperDB=bad;E.Begin();E.draft.positionProfiles.valid.left.x=0;E.Cancel();assert(bad.positionProfiles.valid.left.x==200)
C_EditMode,Enum,UnitGUID,EditModePresetLayoutManager=oldAPI,oldEnum,oldGUID,oldPresets
print('PASS: native-layout placement isolation, migration, commit/reload, draft rollback, deletion/reindex, rename, copied layouts, character/interface scopes, capability failures and sanitized profile persistence')
