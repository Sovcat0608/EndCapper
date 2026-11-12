-- Small WoW surface mock: verifies our behavior, not Blizzard's runtime.
local E = {}
local combat, queue, eventFrame = false, {}, nil
local cursorX,cursorY=0,0
function GetCursorPosition() return cursorX,cursorY end
UIParent={GetEffectiveScale=function() return 0.8 end,GetBottom=function() return 0 end,GetLeft=function() return 0 end,
    GetWidth=function() return 2000 end,GetHeight=function() return 900 end,IsVisible=function() return true end}
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
    local s = {width=154, height=95, points={}, scripts={}, alpha=1,mouse=true}
    function s:GetAlpha() return self.alpha end
    function s:SetAlpha(alpha) self.alpha=alpha end
    function s:IsMouseEnabled() return self.mouse end
    function s:EnableMouse(enabled) self.mouse=enabled end
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
    function c:GetCenter() return self.cx,self.bottom+47.5 end
    function c:GetWidth() return 154 end
    function c:GetEffectiveScale() return 0.8 end
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
function CreateFrame(kind,name,parent)
    if parent then
        local layer={parent=parent,scripts={},shown=true,level=0}
        function layer:GetName() return name end
        function layer:IsObjectType(objectType) return kind==objectType end
        function layer:GetParent() return self.parent end
        function layer:SetParent(value) self.parent=value end
        function layer:SetNormalTexture(path) self.normal=path end
        function layer:SetHighlightTexture(path) self.highlight=path end
        function layer:SetScript(name,fn) self.scripts[name]=fn end
        layer.HookScript=layer.SetScript
        function layer:SetShown(shown)
            local was=self.shown;self.shown=shown
            local callback=self.scripts[shown and "OnShow" or "OnHide"]
            if was~=shown and callback then callback(self) end
        end
        function layer:Hide() self:SetShown(false) end
        function layer:IsVisible() return self.shown and self.parent:IsVisible() end
        function layer:GetEffectiveScale() return self.parent:GetEffectiveScale() end
        function layer:SetSize(w,h) self.width,self.height=w,h end
        function layer:GetSize() return self.width,self.height end
        function layer:GetWidth() return self.width end
        function layer:GetHeight() return self.height end
        function layer:ClearAllPoints() self.point=nil end
        function layer:SetPoint(anchor,relative,_,x,y)
            self.point={relative,x,y};self.anchor=anchor
            self.cx,self.cy=x,y
            if anchor=="BOTTOMLEFT" then self.cx=x+self.width/2;self.cy=y+self.height/2
            elseif anchor=="BOTTOMRIGHT" then
                local width=UIParent:GetWidth()*UIParent:GetEffectiveScale()/self:GetEffectiveScale()
                self.cx=width+x-self.width/2;self.cy=y+self.height/2
            end
            self.bottom=self.cy and self.cy-self.height/2
        end
        function layer:GetCenter() return self.cx,self.cy end
        function layer:GetBottom() return self.cy-self.height/2 end
        function layer:SetBackdropBorderColor(r,g,b,a) self.border={r,g,b,a} end
        for _,name in ipairs({"SetFrameStrata","SetBackdrop","RegisterForDrag"}) do
            layer[name]=function() end
        end
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
local previousDriver=RegisterStateDriver
local visibilityDriver
function RegisterStateDriver(frame,state,condition)
    visibilityDriver={frame,state,condition}
end
assert(loadfile("Model.lua"))("EndCapper", E)
assert(loadfile("Layouts.lua"))("EndCapper", E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile("Effects.lua"))("EndCapper", E)
assert(loadfile("Core.lua"))("EndCapper", E)
eventFrame:event("ADDON_LOADED", "EndCapper")
assert(E.ready and E.caps.left.frame:IsVisible() and E.caps.right.frame:IsVisible(),
    "standalone artwork renders before Blizzard creates any cap frames")
assert(visibilityDriver[1]==E.capRoot and visibilityDriver[2]=="visibility")
assert(visibilityDriver[3]=="[petbattle][overridebar][vehicleui] hide; show")
RegisterStateDriver=previousDriver
local left,right=E.caps.left,E.caps.right
-- Diagnostic command must neither open options nor refresh/restart the artwork.
do
    local oldPrint,oldOpen,oldApply=print,E.OpenOptions,E.Apply
    local reports={}
    print=function(text) reports[#reports+1]=text end
    E.OpenOptions=function() error('hover report must not open options') end
    E.Apply=function() error('hover report must not Apply') end
    SlashCmdList.ENDCAPPER('hover')
    assert(#reports==1 and reports[1]:find('not loaded',1,true))
    E.caps.left.skycutter={};E.cornerCaps.right.skycutter={}
    E.SkycutterHoverStatus=function(entry)
        assert(entry==E.caps.left or entry==E.cornerCaps.right)
        return 'diagnostic counter'
    end
    reports={};SlashCmdList.ENDCAPPER(' HOVER ')
    assert(#reports==2 and reports[1]:find('end / left',1,true) and reports[2]:find('corner / right',1,true))
    E.caps.left.skycutter=nil;E.cornerCaps.right.skycutter=nil;E.SkycutterHoverStatus=nil
    print,E.OpenOptions,E.Apply=oldPrint,oldOpen,oldApply
end
print('PASS: hover diagnostic command reports both modes without Apply or options changes')

MainActionBar = {EndCaps = {LeftEndCap = cap()}}
eventFrame:event("PLAYER_LOGIN")
assert(E.caps.left==left and E.caps.right==right and left.native and not right.native)
MainActionBar.EndCaps.RightEndCap=cap()
eventFrame:event("ADDON_LOADED","LateNativeFrames")
assert(E.caps.left==left and E.caps.right==right and right.native)
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
local selection=left.nativeFrame.Selection
local nativePoints=left.nativeFrame.points
local function assertDragFrame(c)
    assert(c.handle.allPoints==c.frame and c.frame.parent==E.capRoot and E.capRoot.parent==UIParent)
    assert(c.frame.width==c.art.width and c.frame.height==c.art.height)
    assert(c.nativeFrame.Selection.width==154 and c.nativeFrame.Selection.height==95)
end
assertDragFrame(left);assertDragFrame(right)
assert(not left.handle.shown and not right.handle.shown)
assert(selection.alpha==0 and not selection.mouse,"custom artwork disables native selection")
assert(E.launcher.shown and not E.launcherHandle.shown and E.launcher.normal:find("EcapLogo.tga",1,true))
local launcherClicked=false
E.OpenOptions=function() launcherClicked=true end
E.launcher.scripts.OnClick()
assert(launcherClicked)
assert(left.nativeFrame.points==nativePoints and not left.nativeFrame.scripts.OnDragStop)
local function artY(entry,y)
    return y+entry.art.height*((E.EffectBaselines[E.Config()[entry.side].art] or 1)-1)
end
assert(left.art.point[1]=="CENTER" and left.art.point[3]=="CENTER" and left.art.point[4]==0 and left.art.point[5]==artY(left,0),
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
assert(left.frame.width==270 and left.frame.height==180)
assertDragFrame(left)
E.Begin(); E.draft.left.size=200; E.draft.left.y=30; E.Apply()
assert(left.frame.width==450 and left.art.point[5]==artY(left,30))
assertDragFrame(left)
E.Cancel(); E.Apply(); assert(left.frame.width==270, "cancel restores drag frame geometry")
assertDragFrame(left)
E.Begin()
for _, side in ipairs({"left","right"}) do
    E.draft[side].x=-200; E.draft[side].y=200
end
E.Apply()
for _, side in ipairs({"left","right"}) do
    local c=E.caps[side]
    assertDragFrame(c)
    assert(c.art.point[2]==c.frame and c.art.point[4]==-200 and c.art.point[5]==artY(c,200))
    assert(not c.effects, "offsets cannot allocate removed custom effects")
end
E.Cancel(); E.Apply()
assert(left.art.point[4]==25 and left.art.point[5]==artY(left,0) and right.art.point[4]==0, "cancel restores artwork offsets")
combat = true
E.Begin(); E.draft.left.art = "hidden"; E.Apply()
assert(E.pending and left.art.shown, "no texture mutation during combat")
assert(left.frame.width==270 and #selection.points==2, "placement also defers in combat")
E.Cancel(); combat = false; eventFrame:event("PLAYER_REGEN_ENABLED")
assert(not E.pending and left.art.shown, "restores committed state after combat")
local function flush()
    local scheduled = queue; queue = {}
    for _, fn in ipairs(scheduled) do fn() end
    assert(#queue == 0, "own alpha updates must not schedule a loop")
end
left.native:SetAlpha(0.4); flush()
assert(left.native.alpha == 0 and left.art.alpha == 1,"Blizzard alpha does not affect custom art")
E.Begin(); E.draft.left = {art="default", flip=false, size=100, x=0, y=0}; E.Commit(); E.Apply()
assert(left.native.alpha == 0.4 and not left.art.shown, "restore original art and alpha")
assert(selection.width==154 and selection.height==95 and #selection.points==2, "native selection anchors restored exactly")
assert(left.nativeFrame.points==nativePoints and not left.frame.shown and not left.handle.shown)
assert(selection.alpha==1 and selection.mouse,"Default restores the Blizzard selector")
E.Begin(); E.draft.left.flip=true;E.draft.left.size=160;E.draft.left.frameX=999;E.Apply()
assert(left.nativeFrame.points==nativePoints and not left.art.shown and left.native.alpha==0.4)
left.native:SetAtlas("chimera");flush()
assert(left.native:GetAtlas()=="chimera" and not left.art.shown,"Default uses the native texture and anchors")
E.Cancel(); E.Begin(); E.devMode=true
E.draft.left.art='wolf'; E.draft.left.size=100; E.draft.left.flip=false
E.SetDevEffect(E.draft.left,'trailX',30); E.SetDevEffect(E.draft.left,'trailY',15); E.Apply()
assert(left.art.width==200 and left.art.height==100 and left.art.path:find('WorgenBlackCAS.tga',1,true))
assertDragFrame(left)
assert(not left.effects, 'rebuilt Worgen never allocates the old pupil or texture trails')
for _,art in ipairs({'wolf','whiteWorgen'}) do
    E.draft.left.art=art
    for _,flip in ipairs({false,true}) do
        E.draft.left.flip=flip
        for _,effect in ipairs({E.EffectProfiles[art].nativeEffect,'worgenGloom'}) do
            E.SelectEffect(E.draft.left,effect)
            E.SetDevEffect(E.draft.left,'trailX',42);E.SetDevEffect(E.draft.left,'trailOpacity',0)
            E.Apply();assert(not left.effects and left.art.shown)
            assertDragFrame(left)
        end
        E.draft.left.size=200;E.draft.left.x=42;E.draft.left.y=-18;E.Apply()
        assert(left.art.width==400 and left.art.height==200 and left.art.point[4]==42 and left.art.point[5]==artY(left,-18))
        assert(not left.effects)
        E.draft.left.size=100
    end
end
E.draft.left.art='wolf';E.draft.left.flip=true;E.Commit()
E.Begin();E.SelectArtwork(E.draft.left,'whiteWorgen','left');E.Cancel();E.Apply()
assert(left.art.path:find('WorgenBlackCAS.tga',1,true) and not left.effects)
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
            assert(overlay and overlay.shown and overlay.path==E.ArtworkTexture(E.artworkByID[art].overlay))
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
    assertDragFrame(left)
end
E.Cancel(); E.Apply(); E.devMode=false
print('PASS: seven 3:2 artworks retain art and selection geometry')
assert(left.art.parent==left.artLayer and not left.artLayer.mouse and left.frame:GetFrameLevel()==10)
assert(left.handle:GetFrameLevel()>left.artLayer:GetFrameLevel())
local panelShown=true
E.panel={IsShown=function() return panelShown end,Hide=function()
    panelShown=false;E.Cancel();E.UpdateDragHandles();E.Apply()
end}
local canSave
E.UpdateSaveButton=function() canSave=E.HasChanges() end
local function drag(entry,dx,dy)
    local handle=entry.handle
    assert(handle.shown,"drag handle must be visible during editing")
    handle.scripts.OnDragStart()
    assert(handle.scripts.OnUpdate)
    cursorX,cursorY=cursorX+dx*0.8,cursorY+dy*0.8
    handle.scripts.OnUpdate()
    handle.scripts.OnDragStop()
    assert(not handle.scripts.OnUpdate)
end
E.Begin();E.Apply()
local selectedSide
E.SelectCapSide=function(side) selectedSide=side;E.UpdateCapSelection(side) end
E.UpdateCapSelection("left")
assert(left.handle.border[3]==1 and right.handle.border[3]==0.25)
right.handle.scripts.OnMouseDown(right.handle,"LeftButton")
assert(selectedSide=="right" and right.handle.border[3]==1 and left.handle.border[3]==0.25)
left.handle.scripts.OnMouseDown(left.handle,"RightButton")
assert(selectedSide=="right" and E.launcherHandle.border[3]==0.25 and not E.HasChanges())
print("PASS: cap click selects the side and highlights only that frame")
drag({handle=E.launcherHandle},-100,-50)
assert(E.launcher.cx==1660 and E.launcher.cy==806 and canSave and not EndCapperDB.launcher.x)
E.Cancel();E.Apply();assert(E.launcher.cx==1760 and E.launcher.cy==856)
E.Begin();E.Apply();drag({handle=E.launcherHandle},-100,-50);E.Commit();E.Apply()
assert(EndCapperDB.launcher.x==1660 and EndCapperDB.launcher.y==806 and not E.launcherHandle.shown)
E.Begin();E.draft.launcher.shown=false;E.Apply();assert(not E.launcher.shown and not E.launcherHandle.shown)
E.Cancel();E.Apply();assert(E.launcher.shown and E.launcher.cx==1660)
print("PASS: launcher click, drag preview, Save/Cancel, and visibility preview")
local launcher=E.launcher
assert(launcher:GetParent()==UIParent,"standalone launcher lives under UIParent")
local previousMinimap,previousAddOns=Minimap,C_AddOns
Minimap=CreateFrame("Frame",nil,UIParent)
function Minimap:GetEffectiveScale() return 1 end
C_AddOns={IsAddOnLoaded=function(name) return name=="OneForAll" end}
eventFrame:event("ADDON_LOADED","OneForAll")
assert(E.launcher==launcher and launcher:GetParent()==Minimap)
assert(launcher:GetName()=="EndCapperMinimapButton" and launcher:IsObjectType("Button"))
assert(launcher:GetWidth()==40 and launcher:GetHeight()==40)
E.Begin();E.Apply();drag({handle=E.launcherHandle},-100,-50)
assert(math.abs(E.draft.launcher.x-1560)<0.00001 and math.abs(E.draft.launcher.y-756)<0.00001)
local oldPoint=launcher.point
local setPoint,clearPoints=launcher.SetPoint,launcher.ClearAllPoints
-- OneForAll moves minimap children into its drawer and blocks their own anchors.
local drawer=CreateFrame("Frame",nil,UIParent)
local function blocked() error("collector owns launcher positioning") end
launcher.SetPoint,launcher.ClearAllPoints=blocked,blocked
launcher:SetParent(drawer)
setPoint(launcher,"CENTER",drawer,"TOPLEFT",20,-20)
assert(not E.launcherHandle.shown,"collector must be clickable with EndCapper options open")
launcherClicked=false
launcher.scripts.OnClick()
assert(launcherClicked)
E.draft.launcher.shown=false;E.Apply()
assert(not launcher.shown)
E.Cancel();E.Apply()
assert(launcher.shown and launcher.point[1]==drawer)
launcher.SetPoint,launcher.ClearAllPoints=setPoint,clearPoints
launcher:SetParent(Minimap)
launcher.point=oldPoint
local deferred=table.remove(queue)
deferred()
assert(launcher.point[1]==UIParent and launcher.cx==1660*0.8 and launcher.cy==806*0.8)
E.Begin();E.Apply()
assert(E.launcherHandle.shown)
E.Cancel();E.Apply()
Minimap,C_AddOns=previousMinimap,previousAddOns
print("PASS: OneForAll late load, discovery, drawer click, visibility preview, and saved position on release")
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
            assert(left.frame.cx==620);assertDragFrame(left)
        end
    end
end
E.draft.left.y=15;E.Apply('left');floorCheck(left,E.draft.left)
E.LinkPair(E.draft,'left',true);E.SnapToBottom(E.draft,'left');E.Apply();floorCheck(left,E.draft.left);floorCheck(right,E.draft.right)
combat=true;local oldBottom=left.frame.bottom;E.draft.pair.size=200;E.SyncPair(E.draft);E.Apply();assert(left.frame.bottom==oldBottom and E.pending)
combat=false;E.Apply();floorCheck(left,E.draft.left)
E.Cancel();EndCapperDB=E.Normalize({left={art="wolf"},right={art="lordaeron"}})
E.Begin();E.Apply();floorCheck(left,E.draft.left)
drag(left,70,150)
assert(left.frame.cx==690 and left.frame.bottom==150 and not E.draft.left.frameBottom)
assert(EndCapperDB.left.frameBottom and not EndCapperDB.left.frameY and canSave)
left.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',350,140)
eventFrame:event('EDIT_MODE_LAYOUTS_UPDATED');flush()
assert(left.frame.cx==690 and left.frame.bottom==150,"native anchor updates cannot move the preview")
E.Cancel();E.Apply();floorCheck(left,EndCapperDB.left);assert(left.frame.cx==620 and not left.handle.shown)
E.Begin();E.Apply();drag(left,70,150);E.Commit();E.Apply()
assert(left.frame.cx==690 and left.frame.bottom==150 and EndCapperDB.left.frameY)
E.Begin();E.Apply();drag(left,0,0);assert(not canSave,"a drop without movement stays clean")
left.handle.scripts.OnDragStart();cursorY=cursorY+40;left.handle.scripts.OnUpdate()
combat=true;eventFrame:event("PLAYER_REGEN_DISABLED")
assert(not E.draft and not left.handle.shown and not left.handle.scripts.OnUpdate and E.pending)
combat=false;eventFrame:event("PLAYER_REGEN_ENABLED")
assert(left.frame.cx==690 and left.frame.bottom==150,"combat cancels the unsaved drag")
panelShown=true
E.Begin();E.SnapToBottom(E.draft,"left");E.Apply();floorCheck(left,E.draft.left)
E.Cancel();E.Apply();assert(left.frame.bottom==150,"Cancel restores the saved unsnapped position")
print("PASS: all artwork crop lines, snap, preview drag and Save/Cancel restore the custom anchors")
EndCapperDB=E.Normalize({left={art="seraph"},right={art="sanctum"}})
left.nativeFrame:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",600,27.5)
right.nativeFrame:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",1400,27.5)
E.Apply();E.Begin();E.LinkPair(E.draft,"left",true);E.Apply()
assert(E.draft.pair.separation==536 and math.abs(left.frame.cx-620)<=1 and math.abs(right.frame.cx-1380)<=1)
E.draft.pair.separation=0;E.Apply()
assert(left.frame.cx==887.5 and right.frame.cx==1112.5,"zero gap touches the frame edges")
assert(left.art.point[4]==0 and right.art.point[4]==0)
E.draft.pair.separation=1200;E.draft.pair.x=30;E.SyncPair(E.draft);E.Commit();E.Begin();E.Apply()
assert(left.frame.cx==317.5 and right.frame.cx==1742.5 and not E.HasChanges())
drag(left,25,0)
assert(left.frame.cx==342.5 and right.frame.cx==1767.5 and E.HasChanges())
assert(E.draft.left.frameBottom and E.draft.right.frameBottom,"horizontal drag preserves snap")
assert(EndCapperDB.pair.x==30 and E.draft.pair.x==55,"linked drag updates only the draft screen offset")
E.Cancel();E.Apply();assert(left.frame.cx==317.5 and right.frame.cx==1742.5)
E.Begin();E.Apply();drag(right,40,25)
assert(left.frame.cx==357.5 and right.frame.cx==1782.5 and left.frame.bottom==25 and right.frame.bottom==25)
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.Apply()
assert(left.frame.cx==357.5 and right.frame.cx==1782.5 and left.frame.bottom==25 and not E.HasChanges())
E.LinkPair(E.draft,"left",false);E.Apply()
assert(left.frame.cx==357.5 and right.frame.cx==1782.5,"unlink preserves the displayed positions")
drag(left,30,20);E.Cancel();E.Apply()
assert(left.frame.cx==357.5 and right.frame.cx==1782.5 and left.frame.bottom==25,"Cancel after preview unlink restores the saved pair")
E.Begin();E.Apply()
function right.frame:GetEffectiveScale() return 1.6 end
E.Apply();assert(math.abs(right.frame.cx*2-left.frame.cx-337.5-1200)<0.00001)
combat=true;local oldX=left.frame.cx;E.draft.pair.separation=800;E.SyncPair(E.draft);E.Apply();assert(left.frame.cx==oldX and E.pending)
combat=false;E.Apply();assert(math.abs(right.frame.cx*2-left.frame.cx-337.5-800)<0.00001)
local beforeY,otherY=left.frame.cy,right.frame.cy
E.draft.pair.centerX=900;E.draft.pair.x=30;E.Apply()
assert(E.GetPairOffset(E.draft)==-13.75,"legacy absolute position keeps its exact midpoint")
E.SetPairOffset(E.draft,0)
for _,gap in ipairs({0,1200,2000}) do
    E.draft.pair.separation=gap;E.Apply()
    assert((left.frame.cx+right.frame.cx*2)/2==1000,"zero offset centres the pair at any gap")
    assert(right.frame.cx*2-left.frame.cx-337.5==gap,"centering preserves edge gap at mixed scales")
    assert(left.frame.cy==beforeY and right.frame.cy==otherY,"centering leaves vertical placement alone")
end
E.SetPairOffset(E.draft,401);E.Apply()
assert((left.frame.cx+right.frame.cx*2)/2==1401 and E.Normalize(E.draft).pair.x==401)
print("PASS: screen-centred pair midpoint, edge separation, and saved offsets with mixed scales")
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
  assert(not E.artworkByID[E.draft.left.art].path or math.abs(gap)<0.00001,'zero gap follows frame widths/scales for '..row[1])
 end
end
print('PASS: edge-to-edge custom-frame separation 0/1200, stationary artwork offsets, X translation, Cancel, reload/unlink, dragging, mixed scales and combat deferral')
-- Reset uses the screen baseline, independent of the Blizzard frame centres.
E.SelectPair(E.draft,'seraph');E.draft.pair.size=100;E.SyncPair(E.draft);E.ResetPairSeparation(E.draft)
local expected=760-225/2-225
assert(math.abs(E.draft.pair.separation-expected)<=1,'screen default accounts for different effective frame scales')
E.draft.pair.separation=0;E.draft.pair.separationInitialized=true
E.LinkPair(E.draft,'left',false);E.LinkPair(E.draft,'left',true)
assert(E.draft.pair.separation==0,'explicit zero remains available and survives relinking')
print('PASS: screen-based initial/default gap, rounded frame-centre preservation, mixed scales, custom gap retention and deliberate zero')
function right.frame:GetEffectiveScale() return self.parent:GetEffectiveScale() end
E.Cancel()
EndCapperDB=E.Normalize({version=37,left={art="wolf",size=110},right={art="whiteWorgen",size=110}})
E.Begin();E.Apply()
local cornerLeft,cornerRight=E.cornerCaps.left,E.cornerCaps.right
assert(left.frame.shown and not cornerLeft.frame.shown,"existing saves start in End Cap only")
E.SelectMode(E.draft,"corner");assert(not E.HasChanges(),"opening a tab does not dirty the settings")
E.draft.enabled=true;E.Apply()
assert(left.frame.shown and right.frame.shown and cornerLeft.frame.shown and cornerRight.frame.shown)
left.nativeFrame.hidden=true;right.nativeFrame.hidden=true
assert(left.frame:IsVisible() and right.frame:IsVisible() and cornerLeft.frame:IsVisible() and cornerRight.frame:IsVisible(),
    "hidden Blizzard frames cannot hide either mode")
assert(left.art.uv[1]~=cornerLeft.art.uv[1] and right.art.uv[1]~=cornerRight.art.uv[1])
assert(cornerLeft.frame.anchor=="BOTTOMLEFT" and cornerRight.frame.anchor=="BOTTOMRIGHT")
assert(cornerLeft.handle.shown and not left.handle.shown,"only the editing tab exposes drag handles")
E.draft.left.size=180;E.draft.right.size=160;E.Apply()
assert(cornerLeft.frame.cx-cornerLeft.frame.width/2==0 and cornerLeft.frame.bottom==0)
assert(cornerRight.frame.cx+cornerRight.frame.width/2==2000 and cornerRight.frame.bottom==0)
assert(left.art.width==220 and right.art.width==220,"Corner sizing cannot affect End Cap")
E.LinkPair(E.draft,"left",true);E.Apply();drag(cornerRight,-50,25)
assert(cornerLeft.frame.point[2]==50 and cornerRight.frame.point[2]==-50 and cornerRight.frame.bottom==25)
E.SnapToCorner(E.draft,"right");E.Apply()
assert(cornerLeft.frame.bottom==0 and cornerLeft.frame.point[2]==0 and cornerRight.frame.point[2]==0)
E.SelectMode(E.draft,"end");E.draft.enabled=false;E.Apply()
assert(not left.frame.shown and left.native.alpha==left.nativeAlpha and cornerLeft.frame.shown)
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.Apply()
assert(not E.draft.enabled and E.draft.otherMode.enabled and not E.HasChanges())
E.SelectMode(E.draft,"corner");assert(E.draft.pair.size==180 and E.draft.enabled and not E.HasChanges())
print("PASS: simultaneous modes, automatic mirroring, independent sizing, corner growth and dragging")
-- Native layout application precedes the deferred addon reconciliation.
local priorAPI,priorEnum,priorPresets=C_EditMode,Enum,EditModePresetLayoutManager
Enum={EditModeLayoutType={Preset=0,Account=1,Character=2}}
EditModePresetLayoutManager={presetLayoutInfo={{layoutName='Modern',layoutType=0},{layoutName='Classic',layoutType=0},{layoutName='Controller',layoutType=0}}}
local layouts={activeLayout=4,layouts={{layoutName='Wide',layoutType=1},{layoutName='Narrow',layoutType=1}}}
C_EditMode={GetLayouts=function() return layouts end}
E.Cancel();EndCapperDB=E.Normalize({left={art='seraph'},right={art='sanctum'},pair={linked=true,art='seraph',centerX=1000,separation=900}})
E.Apply();local wide=E.activePositionLayout
assert(wide and EndCapperDB.pair.separation==900)
E.Begin();E.draft.pair.separation=1900;E.SelectPair(E.draft,'hexbound');E.Apply();drag(left,70,25)
layouts.activeLayout=5
left.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',200,130);right.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',800,160)
eventFrame:event('EDIT_MODE_LAYOUTS_UPDATED',layouts)
assert(E.activePositionLayout==wide,'native event must defer before changing layouts')
E.Apply();assert(not E.draft and not EndCapperDB.pair.linked)
assert(left.frame.cx==620 and left.frame.cy==75 and right.frame.cx==1380,'unused layout starts at screen defaults')
panelShown=true;E.Begin();E.SelectArtwork(E.draft.left,'wolf','left');E.SelectArtwork(E.draft.right,'whiteWorgen','right')
E.draft.left.x=33;E.draft.left.y=27;E.draft.left.size=125;E.Apply();drag(left,55,30);E.Commit();E.Apply()
local narrow=E.activePositionLayout
layouts.activeLayout=4
left.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',450,27.5);right.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',1550,27.5)
combat=true;E.Apply();assert(E.activePositionLayout==narrow and E.pending)
combat=false;E.Apply();assert(E.activePositionLayout==wide and EndCapperDB.pair.separation==900)
assert(EndCapperDB.positionProfiles[wide].pair.separation==900 and not EndCapperDB.positionProfiles[wide].left.frameY,
    'a profile switch must not commit the drag or gap preview')
assert(left.art.path==E.ArtworkTexture(E.artworkByID.seraph.path) and right.art.path==E.ArtworkTexture(E.artworkByID.sanctum.path),
    'a profile switch restores the saved linked artwork instead of the draft or outgoing selections')
assert(left.frame.cx~=200 and EndCapperDB.left.frameBottom)
layouts.activeLayout=5
left.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',200,130);right.nativeFrame:SetPoint('BOTTOM',UIParent,'BOTTOMLEFT',800,160)
E.Apply();assert(EndCapperDB.left.x==33 and EndCapperDB.left.y==27 and EndCapperDB.left.size==125)
assert(left.frame.cx==675 and left.frame.cy==92.5,'saved drag survives profile switch')
assert(left.art.path==E.ArtworkTexture(E.artworkByID.wolf.path) and right.art.path==E.ArtworkTexture(E.artworkByID.whiteWorgen.path))
eventFrame:event('PLAYER_LOGOUT');assert(EndCapperDB.positionProfiles[narrow].left.x==33)
-- Failed metadata must not block real rendering, even with existing profiles.
E.Begin();C_EditMode.GetLayouts=function() error('temporarily unavailable') end
E.SelectArtwork(E.draft.left,'whiteWorgen','left');E.draft.left.size=140;E.Apply('left')
assert(left.art.path==E.ArtworkTexture(E.artworkByID.whiteWorgen.path) and left.art.width==280,'art/size preview survives profile lookup failure')
E.Commit();E.Apply()
assert(EndCapperDB.left.art=='whiteWorgen' and EndCapperDB.left.size==140)
assert(EndCapperDB.positionProfiles[narrow].left.size==125,'unknown layout must not overwrite the last known placement record')
assert(EndCapperDB.positionProfiles[narrow].left.art=='wolf','unknown layout must not overwrite saved artwork')
C_EditMode.GetLayouts=function() return layouts end;E.Apply()
assert(EndCapperDB.left.size==140 and E.activePositionLayout==narrow)
C_EditMode,Enum,EditModePresetLayoutManager=priorAPI,priorEnum,priorPresets
print('PASS: real renderer/native layout events, deferred profile switch, native anchors, saved linked spacing, draft discard, independent offsets, combat and logout persistence')
local previousBartender=Bartender4
Bartender4=nil
assert(not E.HasBartenderArtBar())
local artModule={db={profile={enabled=true}}}
function artModule:OnEnable()
    self.bar=texture();self.bar:SetAlpha(0.75)
    self.bar.overlay=CreateFrame('Frame',nil,UIParent)
    function self.bar.overlay:IsShown() return self.shown end
    self.bar.overlay:Hide()
end
Bartender4={GetModule=function(_,name,quiet)
    assert(name=='BlizzardArt' and quiet)
    return artModule
end}
eventFrame:event('ADDON_LOADED','Bartender4')
assert(E.HasBartenderArtBar() and not artModule.bar)
E.Begin();E.draft.hideBartenderArt=true;E.Apply()
artModule:OnEnable()
local artBar=artModule.bar
assert(artBar:GetAlpha()==0 and artModule.db.profile.enabled)
artBar:SetAlpha(0.55)
assert(artBar:GetAlpha()==0)
artBar.overlay:SetShown(true)
assert(artBar:GetAlpha()==0.55)
artBar.overlay:Hide()
assert(artBar:GetAlpha()==0)
E.Cancel();E.Apply()
assert(artBar:GetAlpha()==0.55,'cancel restores the last alpha Bartender requested')
E.Begin();E.draft.hideBartenderArt=true;E.Commit();E.Apply()
assert(artBar:GetAlpha()==0 and EndCapperDB.hideBartenderArt)
combat=true;artBar:SetAlpha(0.8)
assert(E.pending and artBar:GetAlpha()==0.8)
combat=false;eventFrame:event('PLAYER_REGEN_ENABLED')
assert(not E.pending and artBar:GetAlpha()==0)
E.Begin();E.draft.hideBartenderArt=false;E.Commit();E.Apply()
assert(artBar:GetAlpha()==0.8 and artModule.db.profile.enabled)
Bartender4=previousBartender
print('PASS: late Bartender art creation, suppression, unlock, combat deferral, saved preference and reversible alpha')
local future = {version=99, custom="preserve"}
EndCapperDB = future
local newer = {}
assert(loadfile("Model.lua"))("EndCapper", newer)
assert(loadfile("Core.lua"))("EndCapper", newer)
eventFrame:event("ADDON_LOADED", "EndCapper")
assert(EndCapperDB == future and not newer.ready, "preserve future schemas")
print("PASS: late frames, native restoration, independent art, combat deferral, alpha hooks, future schema")
print("PASS: eye anchoring, scaling/opacity, hide/show and per-side toggle; no legacy ghost trails")
