-- Small WoW surface mock: verifies our behavior, not Blizzard's runtime.
local E = {}
local combat, queue, eventFrame = false, {}, nil
local function animationGroup()
    local g = {animations = {}}
    function g:SetLooping(v) self.looping = v end
    function g:Play(reverse, offset) self.playing = true; self.offset = offset end
    function g:Stop() self.playing = false end
    function g:CreateAnimation(kind)
        local a = {kind = kind}
        function a:SetFromAlpha(v) self.from = v end
        function a:SetToAlpha(v) self.to = v end
        function a:SetDuration(v) self.duration = v end
        function a:SetOrder(v) self.order = v end
        function a:SetSmoothing(v) self.smoothing = v end
        function a:SetOffset(x,y) self.x, self.y = x,y end
        table.insert(self.animations, a)
        return a
    end
    return g
end
local function texture()
    local t = {alpha = 1, width = 154, height = 95, uv = {0,0,0,1,1,0,1,1}, atlas = "gryphon"}
    function t:SetAlpha(a) self.alpha = a end
    function t:GetAlpha() return self.alpha end
    function t:SetAtlas(a) self.atlas = a end
    function t:GetAtlas() return self.atlas end
    function t:SetTexture(a) self.path = a; self.atlas = nil end
    function t:GetTexture() return self.path end
    function t:SetTexCoord(...) self.uv = {...} end
    function t:GetTexCoord() return unpack(self.uv) end
    function t:GetSize() return self.width, self.height end
    function t:SetSize(w,h) self.width, self.height = w,h end
    function t:ClearAllPoints() self.point = nil end
    function t:SetPoint(...) self.point = {...} end
    function t:Hide() self.shown = false end
    function t:Show() self.shown = true end
    function t:SetBlendMode(v) self.blend = v end
    function t:SetDesaturated(v) self.desaturated = v end
    function t:CreateAnimationGroup() return animationGroup() end
    return t
end
local function cap()
    local c = {Texture = texture(), CreateTexture = function() return texture() end,
        GetFrameLevel=function(self) return self.level or 10 end,
        GetSize = function() return 154,95 end,
        scripts = {}, HookScript = function(self, name, fn) self.scripts[name] = fn end,
        IsVisible = function(self) return not self.hidden end}
    local s = {width=154, height=95, points={}, scripts={}}
    function s:GetFrameLevel() return self.level or 11 end
    function s:SetFrameLevel(v) self.level=v end
    function s:GetWidth() return self.width end
    function s:GetHeight() return self.height end
    function s:GetNumPoints() return #self.points end
    function s:GetPoint(i) return unpack(self.points[i]) end
    function s:ClearAllPoints() self.points={} end
    function s:SetPoint(...) table.insert(self.points,{...}) end
    function s:SetSize(w,h) self.width,self.height=w,h end
    function s:HookScript(event,fn) self.scripts[event]=fn end
    s:SetPoint("TOPLEFT",c,"TOPLEFT",0,0); s:SetPoint("BOTTOMRIGHT",c,"BOTTOMRIGHT",0,0)
    c.Selection=s
    c.points={{"BOTTOM","original","BOTTOMLEFT",300,120}};c.bottom=120;c.cx=300
    function c:GetNumPoints() return #self.points end
    function c:GetPoint(i) return unpack(self.points[i]) end
    function c:ClearAllPoints() self.points={} end
    function c:SetPoint(...) self.points={{...}};self.cx=self.points[1][4];self.bottom=self.points[1][5] end
    function c:OnDragStart() self.isDragging=true end
    function c:OnSystemPositionChange() end
    function c:UpdateClampOffsets()
        local a,b=self.Selection.points[1],self.Selection.points[2]
        self.clampOffsets={a[4],b[4],a[5],b[5]}
    end
    return c
end
function CreateFrame(_,_,parent)
    if parent then
        local layer={parent=parent}
        function layer:SetAllPoints(v) self.allPoints=v end
        function layer:EnableMouse(v) self.mouse=v end
        function layer:SetFrameLevel(v) self.level=v end
        function layer:GetFrameLevel() return self.level end
        function layer:CreateTexture() local t=texture(); t.parent=self; return t end
        return layer
    end
    eventFrame = {RegisterEvent = function() end, SetScript = function(self, _, fn) self.event = fn end}
    return eventFrame
end
function InCombatLockdown() return combat end
function hooksecurefunc(target, name, callback)
    local original = target[name]
    target[name] = function(...) original(...); callback(...) end
end
C_Timer = {After = function(_, fn) queue[#queue + 1] = fn end}
SlashCmdList = {}
MainActionBar = nil
EndCapperDB = nil
assert(loadfile("Model.lua"))("EndCapper", E)
assert(loadfile("Layouts.lua"))("EndCapper", E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile("Effects.lua"))("EndCapper", E)
assert(loadfile("Core.lua"))("EndCapper", E)
eventFrame:event("ADDON_LOADED", "EndCapper")
assert(E.ready and not E.caps.left, "SavedVariables may load before native frames")
MainActionBar = {EndCaps = {LeftEndCap = cap()}}
eventFrame:event("PLAYER_LOGIN")
assert(E.caps.left and not E.caps.right)
MainActionBar.EndCaps.RightEndCap=cap()
eventFrame:event("ADDON_LOADED","LateNativeFrames")
local left, right = E.caps.left, E.caps.right
local apply=E.Apply
E.Apply=function() error("unrelated addon load must not refresh attached caps") end
local optionsAttachments=0
E.AttachOptions=function()
    optionsAttachments=optionsAttachments+1
    E.dialogHooked=true
    E.registryHooked=true
end
eventFrame:event("ADDON_LOADED","LateEditMode")
eventFrame:event("ADDON_LOADED","UnrelatedAddon")
assert(optionsAttachments==1,"late options hooks still attach exactly once")
E.Apply=apply
E.AttachOptions=nil
assert(left.native.alpha == 0 and left.art.shown and right.art.shown)
assert(left.art.uv[1] == 1 and right.art.uv[1] == 0, "reversed Undead default facing")
assert(not left.effects and not right.effects, "rebuilt Undead allocates no custom eye glow or trail")
local selection=left.frame.Selection
assert(selection.width==225 and selection.height==150 and #selection.points==2)
local function assertCentredSelection(c)
    local first,last=c.frame.Selection.points[1],c.frame.Selection.points[2]
    assert(first[1]=="TOPLEFT" and last[1]=="BOTTOMRIGHT")
    assert(first[2]==c.frame and last[2]==c.frame and first[3]=="TOPLEFT" and last[3]=="BOTTOMRIGHT")
    assert(first[4]+last[4]==0 and first[5]+last[5]==0, "selection centre stays on cap centre")
    local w,h=c.frame:GetSize()
    assert(w+last[4]-first[4]==c.art.width and h+first[5]-last[5]==c.art.height)
end
assertCentredSelection(left); assertCentredSelection(right)
assert(left.frame.clampOffsets[1]==-35.5 and left.frame.clampOffsets[3]==27.5, "native clamp bounds refreshed after selection resize")
-- Native snapping contract (EditModeSystemMixin Get*Offset): the second
-- corner MUST exist. OnDragStop performs this work before saving the anchor.
local function snapOffsets(c)
    return select(4,c.frame.Selection:GetPoint(1))-2,
        select(4,c.frame.Selection:GetPoint(2))+2,
        select(5,c.frame.Selection:GetPoint(1))+2,
        select(5,c.frame.Selection:GetPoint(2))-2
end
local function dragSaveExit(c)
    local original={x=10,y=20}
    local saved={x=original.x,y=original.y}
    local live={x=240,y=130} -- drag finishes at this position
    snapOffsets(c) -- failure here interrupts native position-change notification
    local pending={x=live.x,y=live.y}
    saved={x=pending.x,y=pending.y} -- native SaveLayoutChanges
    live={x=saved.x,y=saved.y} -- ExitEditMode reapplies saved layout
    assert(live.x==240 and live.y==130, "dragged position survives Save then exit")
end
for _, c in ipairs({left,right}) do
    local corners=c.frame.Selection.points
    c.frame.Selection.points={{"CENTER",c.frame,"CENTER",0,0}}
    assert(not pcall(dragSaveExit,c), "reproduce 0.6 single-anchor snapping failure")
    c.frame.Selection.points=corners
    dragSaveExit(c)
end
assert(left.art.point[1]=="CENTER" and left.art.point[3]=="CENTER" and left.art.point[4]==0 and left.art.point[5]==0,
    "zero offsets centre the artwork on the cap")
E.Begin(); E.draft.left.trailX=12; E.draft.left.trailY=8; E.Apply()
assert(not left.effects and E.GetEffectConfig(E.draft.left).trailX==-30, "stale flat tuning cannot recreate removed effects")
E.Cancel(); E.Apply()
local x1, y1 = E.EyeAnchor({u=0.2,v=0.3}, 150,150,false)
local x2, y2 = E.EyeAnchor({u=0.2,v=0.3}, 150,150,true)
assert(x1+x2 == 150 and y1 == y2, "eye anchoring mirrors around artwork centre")
left.frame.hidden = true; left.frame.scripts.OnHide()
left.frame.hidden = false; left.frame.scripts.OnShow()
assert(not left.effects, "show cannot recreate old Undead custom effects")
E.Begin(); E.draft.left.effects = false; E.Apply()
assert(not left.effectsEnabled and right.effectsEnabled)
E.Cancel(); E.Apply(); assert(left.effectsEnabled)
E.Begin(); E.draft.left.art = "hidden"; E.Apply()
assert(selection.width==154 and selection.height==95 and #selection.points==2, "restore native selection for hidden art")
assert(not left.art.shown and right.art.shown)
assert(not left.effectsEnabled, "hidden artwork must stop its effects")
E.Cancel(); E.Apply(); assert(left.art.shown)
E.Begin(); E.draft.left.x = 25; E.draft.left.size = 120; E.Commit(); E.Apply()
assert(left.art.width == 270 and left.art.point[4] == 25)
assert(selection.width==270 and selection.height==180)
assertCentredSelection(left); dragSaveExit(left)
E.Begin(); E.draft.left.size=200; E.draft.left.y=30; E.Apply()
assert(selection.width==450 and left.art.point[5]==30)
assertCentredSelection(left); dragSaveExit(left)
E.Cancel(); E.Apply(); assert(selection.width==270, "cancel restores selection geometry")
assertCentredSelection(left)
E.Begin()
for _, side in ipairs({"left","right"}) do
    E.draft[side].x=-200; E.draft[side].y=200
end
E.Apply()
for _, side in ipairs({"left","right"}) do
    local c=E.caps[side]
    assertCentredSelection(c); dragSaveExit(c)
    assert(c.art.point[2]==c.frame and c.art.point[4]==-200 and c.art.point[5]==200)
    assert(not c.effects, "offsets cannot allocate removed custom effects")
end
E.Cancel(); E.Apply()
assert(left.art.point[4]==25 and left.art.point[5]==0 and right.art.point[4]==0, "cancel restores artwork offsets")
combat = true
E.Begin(); E.draft.left.art = "hidden"; E.Apply()
assert(E.pending and left.art.shown, "no texture mutation during combat")
assert(selection.width==270 and #selection.points==2, "selection also defers in combat")
E.Cancel(); combat = false; eventFrame:event("PLAYER_REGEN_ENABLED")
assert(not E.pending and left.art.shown, "restores committed state after combat")
local function flush()
    local scheduled = queue; queue = {}
    for _, fn in ipairs(scheduled) do fn() end
    assert(#queue == 0, "own alpha updates must not schedule a loop")
end
left.native:SetAlpha(0.4); flush()
assert(left.native.alpha == 0 and left.art.alpha == 0.4)
E.Begin(); E.draft.left = {art="default", flip=false, size=100, x=0, y=0}; E.Commit(); E.Apply()
assert(left.native.alpha == 0.4 and not left.art.shown, "restore original art and alpha")
assert(selection.width==154 and selection.height==95 and #selection.points==2, "native selection anchors restored exactly")
for _, inset in ipairs(left.frame.clampOffsets) do assert(inset==0, "native clamp bounds restored") end
assert(not left.effects, "native artwork has no skull effects")
E.Begin(); E.draft.left.flip = true; E.Apply()
assert(left.art.atlas == "gryphon" and left.art.uv[1] == 1)
left.native:SetAtlas("chimera"); flush()
assert(left.art.atlas == "chimera", "follow native artwork changes")
E.Cancel(); E.Begin(); E.devMode=true
E.draft.left.art='wolf'; E.draft.left.size=100; E.draft.left.flip=false
E.SetDevEffect(E.draft.left,'trailX',30); E.SetDevEffect(E.draft.left,'trailY',15); E.Apply()
assert(left.art.width==200 and left.art.height==100 and left.art.path:find('WorgenBlack.tga',1,true))
assertCentredSelection(left); dragSaveExit(left)
assert(not left.effects, 'rebuilt Worgen never allocates the old pupil or texture trails')
for _,art in ipairs({'wolf','whiteWorgen'}) do
    E.draft.left.art=art
    for _,flip in ipairs({false,true}) do
        E.draft.left.flip=flip
        for _,effect in ipairs({E.EffectProfiles[art].nativeEffect,'worgenGloom'}) do
            E.SelectEffect(E.draft.left,effect)
            E.SetDevEffect(E.draft.left,'trailX',42);E.SetDevEffect(E.draft.left,'trailOpacity',0)
            E.Apply();assert(not left.effects and left.art.shown)
            assertCentredSelection(left)
        end
        E.draft.left.size=200;E.draft.left.x=42;E.draft.left.y=-18;E.Apply()
        assert(left.art.width==400 and left.art.height==200 and left.art.point[4]==42 and left.art.point[5]==-18)
        assert(not left.effects)
        E.draft.left.size=100
    end
end
E.draft.left.art='wolf';E.draft.left.flip=true;E.Commit()
E.Begin();E.SelectArtwork(E.draft.left,'whiteWorgen','left');E.Cancel();E.Apply()
assert(left.art.path:find('WorgenBlack.tga',1,true) and not left.effects)
print('PASS: both Worgen art frames/facings, dev effects without custom fallback, size/offsets/selection and Cancel')
-- Foreground ice is registered artwork, independent of native effect calibration.
E.Begin()
for _,side in ipairs({'left','right'}) do
    local e=E.caps[side]
    for _,art in ipairs({'frostmourneHilt','frostmourneBlade'}) do
        E.SelectArtwork(E.draft[side],art,side)
        for _,flip in ipairs({false,true}) do
            E.draft[side].flip=flip;E.draft[side].size=145
            E.draft[side].x=17;E.draft[side].y=22
            E.Apply(side)
            local overlay=e.artOverlay
            assert(overlay and overlay.shown and overlay.path==E.artworkByID[art].overlay)
            assert(overlay.width==e.art.width and overlay.height==e.art.height)
            assert(overlay.point[2]==e.art and overlay.point[4]==0 and overlay.point[5]==0)
            assert(overlay.alpha==e.art.alpha and overlay.blend=='BLEND')
            for i,v in ipairs(e.art.uv) do assert(overlay.uv[i]==v) end
            E.SelectEffect(E.draft[side],'frostMist');E.SetDevEffect(E.draft[side],'trailX',-170)
            E.SetDevEffect(E.draft[side],'trailOpacity',0);E.Apply(side)
            assert(e.artOverlay==overlay and overlay.shown and overlay.point[2]==e.art)
            combat=true;E.SelectArtwork(E.draft[side],'hidden',side);E.Apply(side)
            assert(overlay.shown,'art overlay mutations defer with combat')
            combat=false;E.Apply(side);assert(not overlay.shown)
            E.SelectArtwork(E.draft[side],art,side)
        end
    end
    E.SelectArtwork(E.draft[side],'default',side);E.Apply(side);assert(not e.artOverlay.shown)
end
E.Cancel();E.Apply();assert(not left.artOverlay.shown and not right.artOverlay.shown)
print('PASS: separate ice artwork follows base registration/UV/alpha/size, survives native tuning, reuses texture, defers combat and clears on art switch/Cancel')
E.devMode=false
E.Begin(); E.devMode=true
for _,id in ipairs({'skull','lordaeron','moonbough','verdantRoot','lunarRelic','stormhornTotem','felwing'}) do
    E.draft.left.art=id; E.draft.left.size=100; E.draft.left.flip=false
    E.SetDevEffect(E.draft.left,'trailX',20); E.SetDevEffect(E.draft.left,'trailY',10)
    E.SetDevEffect(E.draft.left,'trailOpacity',50); E.SetDevEffect(E.draft.left,'trailSize',150); E.Apply()
    assert(left.art.width==225 and left.art.height==150)
    assertCentredSelection(left); dragSaveExit(left)
end
E.Cancel(); E.Apply(); E.devMode=false
print('PASS: seven 3:2 artworks retain art and selection geometry')
assert(left.art.parent==left.artLayer and not left.artLayer.mouse and left.frame:GetFrameLevel()==10)
left.frame.level=20; E.Apply()
assert(left.artLayer.level==22 and left.frame.Selection:GetFrameLevel()>=24)
left.frame.level=10; E.Apply()
E.Begin(); E.draft.left=E.NormalizeSide({art='default',flip=false},'left'); E.Apply()
assert(left.frame.Selection:GetFrameLevel()==11 and not left.art.shown)
E.Cancel(); E.Apply()
print('PASS: noninteractive artwork layer, selection above art, and native selection restoration')
E.UpdateSelection(left,{art='violetSpire'})
assert(left.frame.Selection:GetFrameLevel()>=left.frame:GetFrameLevel()+5, 'selection stays above front arcane glow')
assertCentredSelection(left)
E.UpdateSelection(left,E.Config().left)
E.Cancel();EndCapperDB=E.Normalize({left={art='wolf'},right={art='wolf'}});E.Begin()
E.LinkPair(E.draft,'left',true);E.draft.pair.separation=100;E.draft.pair.x=20;E.SyncPair(E.draft);E.Apply()
assert(left.art.point[4]==0 and right.art.point[4]==0)
assertCentredSelection(left);assertCentredSelection(right)
E.LinkPair(E.draft,'left',false);E.Apply();assert(left.art.point[4]==0 and right.art.point[4]==0)
E.Cancel();E.Apply()
print('PASS: linked separation moves artwork while both native drag boxes retain centred two-corner anchors')
-- Supply screen geometry only for the bottom-alignment integration checks.
UIParent={GetEffectiveScale=function() return 0.8 end,GetBottom=function() return 0 end,GetLeft=function() return 0 end}
for _,entry in ipairs({left,right}) do
    function entry.frame:GetCenter() return self.cx,self.bottom+47.5 end
    function entry.frame:GetBottom() return self.bottom end
    function entry.frame:GetEffectiveScale() return 0.8 end
end
EndCapperDB=E.Normalize({left={art='wolf'},right={art='lordaeron'}});E.Begin();E.SnapToBottom(E.draft,'left');E.Apply()
local function floorCheck(entry,c)
    local _,h=entry.art:GetSize();local _,fh=entry.frame:GetSize()
    assert(math.abs(entry.frame:GetBottom()+(fh-h)/2)<0.00001,'drag box bottom at screen floor')
    local baseline=E.EffectBaselines[c.art] or 1
    local crop=entry.frame:GetBottom()+fh/2+entry.art.point[5]+h*(0.5-baseline)
    assert(math.abs(crop-c.y)<0.00001,'crop line is Y zero')
end
for _,art in ipairs(E.artworks) do
    if art.path then
        for _,size in ipairs({50,100,200}) do
            E.draft.left.art=art.id;E.draft.left.size=size;E.SnapToBottom(E.draft,'left');E.Apply('left');floorCheck(left,E.draft.left)
            assert(left.frame.cx==300);assertCentredSelection(left)
        end
    end
end
E.draft.left.y=15;E.Apply('left');floorCheck(left,E.draft.left)
E.LinkPair(E.draft,'left',true);E.SnapToBottom(E.draft,'left');E.Apply();floorCheck(left,E.draft.left);floorCheck(right,E.draft.right)
combat=true;local oldBottom=left.frame.bottom;E.draft.pair.size=200;E.SyncPair(E.draft);E.Apply();assert(left.frame.bottom==oldBottom and E.pending)
combat=false;E.Apply();floorCheck(left,E.draft.left)
E.Commit();E.Begin();E.Apply();floorCheck(left,E.draft.left)
left.frame:OnDragStart();left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',300,150);left.frame:OnSystemPositionChange();E.Apply('left')
assert(not EndCapperDB.left.frameBottom and left.frame.bottom==150)
E.SnapToBottom(E.draft,'left');E.Apply();floorCheck(left,E.draft.left)
E.Cancel();E.Apply();assert(left.frame.bottom==150,'Cancel restores unsnapped native anchors')
print('PASS: all artwork crop lines/sizes at floor, drag boxes, linked snapping, nonzero Y, combat, persistence, native dragging and Cancel anchor restoration')
if left.frame.scripts.OnDragStop then left.frame.scripts.OnDragStop() end
E.Cancel();EndCapperDB=E.Normalize({left={art='seraph'},right={art='sanctum'}});E.Apply()
left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',600,27.5)
right.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',1400,27.5)
E.Begin();E.LinkPair(E.draft,'left',true);E.Apply()
assert(E.draft.pair.separation==576 and math.abs(left.frame.cx-600)<=1 and math.abs(right.frame.cx-1400)<=1,'first link preserves current native frame spacing within slider rounding')
E.draft.pair.separation=0;E.Apply()
assert(left.frame.cx==887.5 and right.frame.cx==1112.5,'zero separation touches the drag box edges')
assert(left.art.point[4]==0 and right.art.point[4]==0,'separation never moves art inside its frame')
E.draft.pair.separation=1200;E.SyncPair(E.draft);E.Apply()
assert(left.frame.cx==287.5 and right.frame.cx==1712.5,'1200 is the gap between drag box edges')
assertCentredSelection(left);assertCentredSelection(right)
E.Cancel();E.Apply();assert(left.frame.cx==600 and right.frame.cx==1400,'Cancel restores original horizontal frame anchors')
E.Begin();E.LinkPair(E.draft,'left',true);E.draft.pair.separation=1200;E.draft.pair.x=30;E.SyncPair(E.draft);E.Apply()
assert(left.frame.cx==317.5 and right.frame.cx==1742.5)
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.Apply()
assert(left.frame.cx==317.5 and right.frame.cx==1742.5 and E.draft.pair.centerX==1000)
E.LinkPair(E.draft,'left',false);E.Apply();assert(left.frame.cx==317.5 and right.frame.cx==1742.5)
E.LinkPair(E.draft,'left',true);E.Apply()
assert(E.draft.pair.separation==1200,'relink retains the adjusted separation')
E.LinkPair(E.draft,'left',false);E.Apply()
left.frame:OnDragStart();left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',700,150)
left.frame.scripts.OnDragStop();E.Apply('left');assert(left.frame.cx==700 and not E.draft.left.frameX)
-- Linked drag updates the common centre while preserving absolute spacing.
E.LinkPair(E.draft,'left',true);E.draft.pair.separation=1200;E.SyncPair(E.draft);E.Apply()
left.frame:OnDragStart();left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',500,150)
left.frame.scripts.OnDragStop();E.Apply()
assert(left.frame.cx==500 and right.frame.cx==1925)
E.draft.pair.separation=200;E.draft.pair.x=150;E.draft.pair.size=150
E.SyncPair(E.draft);E.Apply()
left.frame:OnDragStart();left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',500,150)
left.frame.scripts.OnDragStop();E.Apply()
assert(left.frame.cx==500 and right.frame.cx==1037.5)
E.Cancel();E.Apply()
assert(left.frame.cx==500 and right.frame.cx==1925,'Cancel restores saved geometry around the dragged cap')
assert(EndCapperDB.pair.separation==1200 and EndCapperDB.pair.x==30 and EndCapperDB.pair.size==100)
E.Begin();E.LinkPair(E.draft,'right',false);E.Apply()
right.frame:OnDragStart();right.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',1800,150)
right.frame.scripts.OnDragStop()
E.Cancel();E.Apply()
assert(left.frame.cx==375 and right.frame.cx==1800,'Cancel after preview unlink preserves the dragged position')
E.Begin();E.Apply()
-- Root UI units remain consistent when the cap frames use different scales.
function right.frame:GetEffectiveScale() return 1.6 end
E.Apply();assert(math.abs(right.frame.cx*2-left.frame.cx-337.5-1200)<0.00001)
combat=true;local oldX=left.frame.cx;E.draft.pair.separation=800;E.SyncPair(E.draft);E.Apply();assert(left.frame.cx==oldX and E.pending)
combat=false;E.Apply();assert(math.abs(right.frame.cx*2-left.frame.cx-337.5-800)<0.00001)
-- Changing size/artwork must keep the requested edge gap at unequal scales.
for _,row in ipairs(E.ArtworkPairs) do
 for _,size in ipairs({50,100,200}) do
  E.SelectPair(E.draft,row[1]);E.draft.pair.size=size;E.draft.pair.separation=0;E.SyncPair(E.draft);E.Apply()
  local function half(entry,c)
   local art=E.artworkByID[c.art]
   local width=art and art.width or 154
   if c.art~='hidden' then width=width*c.size/100 end
   return width/2*entry.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  end
  local gap=right.frame.cx*2-half(right,E.draft.right)-left.frame.cx-half(left,E.draft.left)
  assert(math.abs(gap)<0.00001,'zero gap follows frame widths/scales for '..row[1])
 end
end
print('PASS: edge-to-edge native-frame separation 0/1200, stationary artwork offsets, X translation, Cancel, reload/unlink, dragging, mixed scales and combat deferral')
-- Reset uses the native baseline, rather than the adjusted linked spacing.
E.nativePairSpan=1000
E.SelectPair(E.draft,'seraph');E.draft.pair.size=100;E.SyncPair(E.draft);E.ResetPairSeparation(E.draft)
local expected=1000-225/2-225
assert(math.abs(E.draft.pair.separation-expected)<=1,'native default accounts for different effective frame scales')
E.draft.pair.separation=0;E.draft.pair.separationInitialized=true
E.LinkPair(E.draft,'left',false);E.LinkPair(E.draft,'left',true)
assert(E.draft.pair.separation==0,'explicit zero remains available and survives relinking')
print('PASS: native-based initial/default gap, rounded frame-centre preservation, mixed scales, custom gap retention and deliberate zero')
-- Native layout application precedes the deferred addon reconciliation.
local priorAPI,priorEnum,priorPresets=C_EditMode,Enum,EditModePresetLayoutManager
Enum={EditModeLayoutType={Preset=0,Account=1,Character=2}}
EditModePresetLayoutManager={presetLayoutInfo={{layoutName='Modern',layoutType=0},{layoutName='Classic',layoutType=0},{layoutName='Controller',layoutType=0}}}
local layouts={activeLayout=4,layouts={{layoutName='Wide',layoutType=1},{layoutName='Narrow',layoutType=1}}}
C_EditMode={GetLayouts=function() return layouts end}
E.Cancel();EndCapperDB=E.Normalize({left={art='seraph'},right={art='sanctum'},pair={linked=true,art='seraph',centerX=1000,separation=900}})
E.Apply();local wide=E.activePositionLayout
assert(wide and EndCapperDB.pair.separation==900)
E.Begin();E.draft.pair.separation=1900;E.SyncPair(E.draft);E.Apply()
layouts.activeLayout=5
left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',200,130);right.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',800,160)
eventFrame:event('EDIT_MODE_LAYOUTS_UPDATED',layouts)
assert(E.activePositionLayout==wide,'native event must defer before changing layouts')
E.Apply();assert(not E.draft and not EndCapperDB.pair.linked)
assert(left.frame.cx==200 and left.frame.bottom==130 and right.frame.cx==800,'unused layout keeps native anchors')
E.Begin();E.draft.left.x=33;E.draft.left.y=27;E.draft.left.size=125;E.Commit();E.Apply()
local narrow=E.activePositionLayout
layouts.activeLayout=4
left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',450,27.5);right.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',1550,27.5)
combat=true;E.Apply();assert(E.activePositionLayout==narrow and E.pending)
combat=false;E.Apply();assert(E.activePositionLayout==wide and EndCapperDB.pair.separation==900)
assert(EndCapperDB.positionProfiles[wide].pair.separation==900,'draft must not replace committed layout placement')
assert(left.frame.cx~=200 and EndCapperDB.left.frameBottom)
layouts.activeLayout=5
left.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',200,130);right.frame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',800,160)
E.Apply();assert(EndCapperDB.left.x==33 and EndCapperDB.left.y==27 and EndCapperDB.left.size==125)
assert(left.frame.cx==200 and left.frame.bottom==130 and not left.bottomOriginal and not left.frameXOriginal,'old layout rollback anchors must be cleared')
eventFrame:event('PLAYER_LOGOUT');assert(EndCapperDB.positionProfiles[narrow].left.x==33)
-- Failed metadata must not block real rendering, even with existing profiles.
E.Begin();C_EditMode.GetLayouts=function() error('temporarily unavailable') end
E.SelectArtwork(E.draft.left,'wolf','left');E.draft.left.size=140;E.Apply('left')
assert(left.art.path==E.artworkByID.wolf.path and left.art.width==280,'art/size preview survives profile lookup failure')
E.Commit();E.Apply()
assert(EndCapperDB.left.art=='wolf' and EndCapperDB.left.size==140)
assert(EndCapperDB.positionProfiles[narrow].left.size==125,'unknown layout must not overwrite the last known placement record')
C_EditMode.GetLayouts=function() return layouts end;E.Apply()
assert(EndCapperDB.left.size==140 and E.activePositionLayout==narrow)
C_EditMode,Enum,EditModePresetLayoutManager=priorAPI,priorEnum,priorPresets
print('PASS: real renderer/native layout events, deferred profile switch, native anchors, saved linked spacing, draft discard, independent offsets, combat and logout persistence')
local future = {version=99, custom="preserve"}
EndCapperDB = future
local newer = {}
assert(loadfile("Model.lua"))("EndCapper", newer)
assert(loadfile("Core.lua"))("EndCapper", newer)
eventFrame:event("ADDON_LOADED", "EndCapper")
assert(EndCapperDB == future and not newer.ready, "preserve future schemas")
print("PASS: late frames, native restoration, independent art, combat deferral, alpha hooks, future schema")
print("PASS: eye anchoring, scaling/opacity, hide/show and per-side toggle; no legacy ghost trails")
print("PASS: reproduces single-anchor drag failure; two-corner selection supports native snapping and simulated Save/exit")

