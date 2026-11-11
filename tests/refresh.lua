-- Real Core + Effects + NativeSmoke: UI refreshes must not restart the other cap.
-- Counts native scene transitions as well as model requests; IsLoaded alone
-- cannot detect the hide/show interruption reported in the client.
local E={}
local now,queue,combat,mode=0,{},false,'ready'
function InCombatLockdown() return combat end
C_Timer={After=function(delay,fn) queue[#queue+1]={at=now+delay,fn=fn} end}
local function advance(seconds)
    local untilTime=now+seconds
    for _=1,200 do
        local index
        for i,v in ipairs(queue) do
            if v.at<=untilTime and (not index or v.at<queue[index].at) then index=i end
        end
        if not index then now=untilTime;return end
        local next=table.remove(queue,index);now=next.at;next.fn()
    end
    error('refresh did not settle')
end
local function surface()
    local s={shown=true,alpha=1,width=154,height=95,level=10,scripts={},uv={0,0,0,1,1,0,1,1}}
    function s:Show() if not self.shown then self.shows=(self.shows or 0)+1 end;self.shown=true end
    function s:Hide() if self.shown then self.hides=(self.hides or 0)+1 end;self.shown=false end
    function s:IsVisible() return self.shown end
    function s:SetAlpha(v) self.alpha=v end
    function s:GetAlpha() return self.alpha end
    function s:SetSize(w,h) self.width,self.height=w,h end
    function s:GetSize() return self.width,self.height end
    function s:SetFrameLevel(v) self.level=v end
    function s:GetFrameLevel() return self.level end
    function s:SetTexture(v) self.path=v end
    function s:GetTexture() return self.path end
    function s:SetAtlas(v) self.atlas=v end
    function s:GetAtlas() return self.atlas end
    function s:SetTexCoord(...) self.uv={...} end
    function s:GetTexCoord() return unpack(self.uv) end
    function s:ClearAllPoints() self.point=nil end
    function s:SetPoint(...) self.point={...} end
    function s:CreateTexture() return surface() end
    function s:HookScript(name,fn) self.scripts[name]=fn end
    function s:SetScript(name,fn) self.scripts[name]=fn end
    function s:RegisterEvent() end
    function s:SetAllPoints() end
    function s:EnableMouse() end
    return s
end
function CreateFrame(kind,_,parent)
    local s=surface()
    s.parent=parent
    if kind=='ModelScene' then
        function s:SetAllowOverlappedModels(v) self.allowOverlap=v end
        function s:GetAllowOverlappedModels() return self.allowOverlap==true end
        function s:SetViewInsets(...) self.insets={...} end
        function s:SetViewTranslation(...) self.translation={...} end
        for _,name in ipairs({'SetCameraNearClip','SetCameraFarClip','SetCameraPosition','SetCameraOrientationByAxisVectors',
            'SetCameraFieldOfView','SetLightAmbientColor','SetLightDiffuseColor','SetDrawLayer','SetDesaturation'}) do
            s[name]=function() end
        end
        function s:CreateActor()
            local a={modelCalls=0,animationCalls=0,positionCalls=0}
            function a:IsLoaded() return self.ready end
            function a:GetModelFileID() return self.id end
            function a:ClearModel() self.ready=false;self.id=nil end
            function a:SetModelByFileID(id)
                self.id=id;self.ready=mode=='ready';self.modelCalls=self.modelCalls+1
                self.overlapAtLoad=s:GetAllowOverlappedModels();return true
            end
            function a:SetAnimation() self.animationCalls=self.animationCalls+1 end
            function a:SetPosition() self.positionCalls=self.positionCalls+1 end
            function a:SetScale() end
            function a:SetPitch() end
            function a:SetYaw() end
            function a:SetRoll() end
            function a:Show() end
            return a
        end
    end
    return s
end
function hooksecurefunc(target,name,fn)
    local original=target[name]
    target[name]=function(...) original(...);fn(...) end
end
SlashCmdList={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile('Layouts.lua'))('EndCapper',E)
assert(loadfile('Clipping.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
assert(loadfile('NativeSmoke.lua'))('EndCapper',E)
assert(loadfile('Core.lua'))('EndCapper',E)
local function cap() local c=surface();c.Texture=surface();return c end
MainActionBar={EndCaps={LeftEndCap=cap(),RightEndCap=cap()}}
EndCapperDB=E.Normalize({left={art='seraph'},right={art='eclipse'}})
E.ready=true;E.Attach();advance(0);E.Begin()
local left,right=E.caps.left,E.caps.right
local function snapshot(entry)
    local result={}
    for _,item in ipairs({entry,entry.secondaryEffect}) do
        local slot=item.nativeSmoke.slots[1]
        result[#result+1]=table.concat({slot.scene.hides or 0,slot.scene.shows or 0,
            slot.actor.modelCalls,slot.actor.animationCalls,slot.actor.positionCalls},':')
    end
    return table.concat(result,'/')
end
local untouched=snapshot(right)
E.SelectArtwork(E.draft.left,'sanctum','left');E.Apply('left');advance(0)
assert(snapshot(right)==untouched,'changing left must not touch right effects')
untouched=snapshot(left)
E.SelectArtwork(E.draft.right,'umbra','right');E.Apply('right');advance(0)
assert(snapshot(left)==untouched,'changing right must not touch left effects')

local function transitions(entry)
    return (entry.nativeSmoke.slots[1].scene.hides or 0)+(entry.secondaryEffect.nativeSmoke.slots[1].scene.hides or 0)
end
local lh,rh=transitions(left),transitions(right)
E.Apply();advance(0)
assert(transitions(left)==lh and transitions(right)==rh,'Apply must not hide active native effects')
E.draft.left.x=27;E.draft.left.size=125;E.Apply('left')
assert(transitions(left)==lh and left.art.width==281.25,'placement preview updates in place')

-- A secondary finishes after its primary. Neither the primary nor the other
-- cap may be hidden by the callback/poll refresh.
mode='pending';E.SelectArtwork(E.draft.left,'moonwell','left');E.Apply('left')
local first=left.nativeSmoke.slots[1]
local second=left.secondaryEffect.nativeSmoke.slots[1]
first.actor.ready=true;first.actor.endCapperOnModelLoaded();advance(0)
assert(first.scene.shown and first.scene.alpha>0 and second.scene.alpha==0)
untouched=snapshot(right);local firstHides=first.scene.hides
second.actor.ready=true;second.actor.endCapperOnModelLoaded();advance(0)
assert(second.scene.shown and second.scene.alpha>0,'second effect appears without Apply')
assert(first.scene.hides==firstHides,'secondary completion must not interrupt the primary')
assert(snapshot(right)==untouched,'secondary completion must refresh only its owning side')
advance(0.75);assert(snapshot(right)==untouched,'stale polls must not update the other side')

-- Coalescing must retain both sides; a global hook must supersede a queued side.
local updates={left=0,right=0}
local update=E.UpdateEffects
E.UpdateEffects=function(entry,c) updates[entry.side]=updates[entry.side]+1;return update(entry,c) end
E.Schedule('left');E.Schedule('left');advance(0)
assert(updates.left==1 and updates.right==0,'coalesce same-side refresh')
updates.left=0;E.Schedule('left');E.Schedule('right');advance(0)
assert(updates.left==1 and updates.right==1,'do not lose the second queued side')
updates.left=0;updates.right=0;E.Schedule('left');E.Schedule();advance(0)
assert(updates.left==1 and updates.right==1,'global refresh includes both caps')
updates.left=0;updates.right=0;right.native:SetAlpha(0.6);advance(0)
assert(updates.left==0 and updates.right==1 and right.alpha==0.6,'native alpha hook belongs to one cap')
updates.left=0;updates.right=0;left.frame.scripts.OnSizeChanged(left.frame);advance(0)
assert(updates.left==1 and updates.right==0,'size hook belongs to one cap')

-- Commit/Cancel affect both drafts, while actual disable/hide still stops models.
mode='ready';E.Commit();E.Begin();E.SelectArtwork(E.draft.left,'hidden','left');E.Apply('left')
assert(not first.scene.shown and not second.scene.shown,'Hidden stops both native layers')
untouched=snapshot(right);E.Cancel();E.Apply();advance(0)
assert(first.scene.shown and second.scene.shown and right.nativeSmoke.slots[1].scene.shown)
E.Begin();E.draft.left.effects=false;E.Apply('left')
assert(not first.scene.shown and not second.scene.shown,'effects off stops both layers')
E.draft.left.effects=true;E.draft.left.nativeSmoke=false;E.Apply('left')
assert(not first.scene.shown and not second.scene.shown,'native effects off stays hidden')
E.Cancel();E.Apply();advance(0)
left.frame:Hide();left.frame.scripts.OnHide();assert(not first.scene.shown and not second.scene.shown)
left.frame:Show();left.frame.scripts.OnShow();advance(0);assert(first.scene.shown and second.scene.shown)
combat=true;untouched=snapshot(left);E.Begin();E.draft.left.x=40;E.Apply('left')
assert(E.pending and snapshot(left)==untouched,'combat defers targeted previews')
combat=false;E.Apply();assert(not E.pending and left.art.point[4]==40)
E.Cancel();E.Apply();advance(0)
print('PASS: real Core/Effects/native side isolation, uninterrupted active scenes, paired load completion, coalesced sides, hooks, commit/cancel, disable/hide and combat')

-- User's exact combination: Sanctum on both sides, with the large holy glow
-- behind the artwork. Check the real overlap opt-in, not a mock GPU algorithm.
E.Begin()
for _,side in ipairs({'left','right'}) do E.draft[side]=E.NormalizeSide({art='sanctum'},side) end
E.Apply();advance(0)
local function checkSanctums()
    for _,entry in ipairs({left,right}) do
        for _,item in ipairs({entry,entry.secondaryEffect}) do
            local slot=item.nativeSmoke.slots[1]
            assert(slot.scene:GetAllowOverlappedModels(),'both Sanctum layers must opt into overlapping model rendering')
            assert(slot.actor.overlapAtLoad,'overlap must be enabled before model loading')
            assert(slot.actor:IsLoaded() and slot.scene.shown and slot.scene.alpha>0)
            assert(slot.scene.parent==entry.frame and not slot.scene.endCapperClip,
                'native models must remain outside generic clipping wrappers')
            assert(slot.scene.insets and slot.scene.insets[4]==0,'camera insets stay clear')
            local crop=slot.scene.width-slot.scene.height
            assert(crop>0,'both native frame rectangles stop at the artwork base')
            assert(math.abs(slot.scene.translation[2]+crop/2)<.00001,'crop compensation survives Apply')
        end
        assert(entry.nativeSmoke.slots[1].scene.level<entry.artLayer.level,'holy glow stays behind artwork')
        assert(entry.secondaryEffect.nativeSmoke.slots[1].scene.level>entry.artLayer.level,'radiance stays in front')
    end
end
checkSanctums()
local hidesLeft,hidesRight=transitions(left),transitions(right)
local glowLeft,glowRight=left.nativeSmoke.slots[1].actor.modelCalls,right.nativeSmoke.slots[1].actor.modelCalls
for _=1,12 do E.Commit();E.Begin();E.Apply();advance(0);checkSanctums() end
assert(transitions(left)==hidesLeft and transitions(right)==hidesRight)
assert(left.nativeSmoke.slots[1].actor.modelCalls==glowLeft and right.nativeSmoke.slots[1].actor.modelCalls==glowRight)
assert(E.NativeSmokeStatus(left):find('overlap=on',1,true),'status reports actual native overlap flag')
print('PASS: dual Sanctum overlap opt-in before load, all four scenes retained across repeated Apply, unchanged front/back placement and status readback')

E.Cancel();EndCapperDB=E.Normalize({left={art='seraph'},right={art='wolf'}});E.Begin()
E.LinkPair(E.draft,'left',true);E.draft.pair.size=130;E.draft.pair.x=20;E.draft.pair.y=-12;E.draft.pair.separation=100;E.SyncPair(E.draft)
E.Apply();advance(0)
assert(left.art.point[4]==0 and right.art.point[4]==0 and left.art.point[5]==-12 and right.art.point[5]==-12)
assert(left.art.width==292.5 and right.art.width==292.5)
local beforeLeft,beforeRight=transitions(left),transitions(right)
for _=1,4 do E.Commit();E.Begin();E.Apply();advance(0) end
assert(transitions(left)==beforeLeft and transitions(right)==beforeRight)
E.draft.pair.swapped=true;E.SyncPair(E.draft);E.Apply();advance(0)
assert(E.draft.left.art=='sanctum' and E.draft.right.art=='seraph')
assert(left.nativeActive and right.nativeActive and left.secondaryEffect.nativeActive and right.secondaryEffect.nativeActive)
combat=true;E.draft.pair.separation=160;E.SyncPair(E.draft);E.Apply()
assert(E.pending and left.art.point[4]==0 and right.art.point[4]==0)
combat=false;E.Apply();advance(0);assert(left.art.point[4]==0 and right.art.point[4]==0)
E.Cancel();E.Apply();advance(0);assert(left.art.point[4]==0 and right.art.point[4]==0)
print('PASS: linked settings render both sides with separation, paired native effects, stable repeated Apply, swap, combat deferral and Cancel')
