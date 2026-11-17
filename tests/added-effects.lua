local E = {}
assert(loadfile("Model.lua"))("EndCapper", E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile("Effects.lua"))("EndCapper", E)
assert(loadfile("NativeSmoke.lua"))("EndCapper", E)
assert(loadfile('AddedEffects.lua'))('EndCapper',E)
local queue, scenes, mode, combat, scheduled = {}, {}, "ready", false, 0
function InCombatLockdown() return combat end
C_Timer = {After = function(_, fn) table.insert(queue, fn) end}
E.Schedule = function() scheduled = scheduled+1 end
local function tick()
    local callbacks = queue; queue = {}
    for _, fn in ipairs(callbacks) do fn() end
end
function CreateFrame(kind)
    assert(kind == "ModelScene")
    if mode == "unsupported" then error("unsupported scene") end
    local s = {}
    for _, key in ipairs({"SetCameraNearClip", "SetCameraFarClip", "SetCameraPosition", "SetCameraOrientationByAxisVectors",
        "SetCameraFieldOfView", "SetLightAmbientColor", "SetLightDiffuseColor", "SetDrawLayer", "EnableMouse", "SetFrameLevel", "SetDesaturation"}) do
        s[key] = function(self, ...) self[key .. "Value"] = {...} end
    end
    function s:Show() self.shown = true end
    function s:Hide() self.shown = false end
    function s:SetAlpha(v) self.alpha = v end
    function s:SetSize(w,h) self.width,self.height = w,h end
    function s:ClearAllPoints() self.point = nil end
    function s:SetPoint(...) self.point = {...} end
    function s:CreateActor(_, template)
        assert(template == "EndCapperSmokeActorTemplate")
        local a = {ready = mode == "ready"}
        function a:ClearModel() self.ready=false; self.fileID=nil end
        function a:SetModelByFileID(id)
            self.fileID=id; self.ready=mode=="ready" or mode=="sync"
            self.modelCalls=(self.modelCalls or 0)+1
            if mode=="sync" and self.endCapperOnModelLoaded then self.endCapperOnModelLoaded() end
            return mode~="reject"
        end
        function a:GetModelFileID() return self.fileID end
        function a:IsLoaded() return self.ready end
        function a:SetAnimation(...) self.animation = {...}; self.animationCalls=(self.animationCalls or 0)+1 end
        function a:SetScale(v) self.scale = v end
        function a:SetYaw(v) self.yaw = v end
        function a:SetPitch(v) self.pitch = v end
        function a:SetRoll(v) self.roll = v end
        function a:SetPosition(x,y,z) self.x,self.y,self.z = x,y,z end
        function a:Show() self.shown = true end
        self.actor = a; return a
    end
    table.insert(scenes,s); return s
end
local function entry()
    return {alpha = 0.8, effectsEnabled = true, nativeWanted = true,
        frame = {HookScript = function(self, event, fn) self[event]=fn end, IsVisible = function(self) return not self.hidden end, GetFrameLevel = function() return 10 end},
        art = {GetSize = function(self) return self.width or 150, self.height or self.width or 150 end}}
end

E.devMode=true
EndCapperDB=E.Normalize({left={art='timekeeper',addedEffects={timekeeper={},timelost={}}},right={art='timelost',addedEffects={timekeeper={},timelost={}}}});E.Begin()
local c=E.draft.left
assert(E.AddLibraryEffect(c,{fileID=166011,name='Fire',scale=.7,originX=.2,originZ=.3,azimuth=45,elevation=25})==1)
assert(E.AddLibraryEffect(c,{fileID=166011,name='Second Fire'})==2 and E.HasChanges())
assert(#E.GetAddedEffects(E.draft.right)==0 and #E.GetAddedEffects(E.draft.otherMode.left)==0)
local left=entry();left.side='left';E.UpdateEffects(left,c)
assert(not left.effectsEnabled and #left.addedEffectSlots==2,'Custom effects work on a cap without built-in effects')
local first,second=left.addedEffectSlots[1],left.addedEffectSlots[2]
local a,b=first.nativeSmoke.slots[1],second.nativeSmoke.slots[1]
assert(a.scene~=b.scene and a.actor.fileID==166011 and a.scene.shown and b.scene.shown)
assert(a.scene.SetFrameLevelValue[1]==19 and b.scene.SetFrameLevelValue[1]==20)
assert(a.actor.scale==.7 and math.abs(a.actor.x+.14)<.00001 and math.abs(a.actor.z+.21)<.00001)
local axes=a.scene.SetCameraOrientationByAxisVectorsValue
for j=0,2 do local n=0;for k=1,3 do n=n+axes[j*3+k]^2 end;assert(math.abs(n-1)<.00001)end
for j=0,1 do for k=j+1,2 do local n=0;for d=1,3 do n=n+axes[j*3+d]*axes[k*3+d]end;assert(math.abs(n)<.00001)end end
local calls=a.actor.modelCalls
local normalCamera=a.scene.SetCameraPositionValue
local anchor=a.scene.point
c.layerState={timekeeper={flips={["fx:1"]=true}}}
E.UpdateEffects(left,c)
local mirroredCamera=a.scene.SetCameraPositionValue
assert(mirroredCamera[1]==-normalCamera[1] and mirroredCamera[2]==-normalCamera[2])
assert(a.scene.point[4]==anchor[4] and a.scene.point[5]==anchor[5])
assert(a.actor.modelCalls==calls and a.actor.animationCalls==1)
c.layerState=nil
E.GetAddedEffects(c)[1].trailY=55;E.GetAddedEffects(c)[1].effectLayer='back';E.UpdateEffects(left,c)
assert(a.actor.modelCalls==calls and a.scene.SetFrameLevelValue[1]==11 and a.scene.height==a.scene.width)
E.Commit();assert(#E.GetAddedEffects(EndCapperDB.left)==2);E.Begin();assert(not E.HasChanges())
E.RemoveLibraryEffect(E.draft.left,1);assert(E.HasChanges());E.Cancel();E.Begin();assert(#E.GetAddedEffects(E.draft.left)==2)
E.SelectMode(E.draft,'corner');assert(#E.GetAddedEffects(E.draft.left)==0)
E.AddLibraryEffect(E.draft.left,{fileID=165792,name='Snow',animation=158});E.SelectMode(E.draft,'end');assert(#E.GetAddedEffects(E.draft.left)==2)
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);assert(#E.GetAddedEffects(EndCapperDB.left)==2 and #E.GetAddedEffects(EndCapperDB.otherMode.left)==1)
E.Begin();c=E.draft.left;E.RemoveLibraryEffect(c,2);E.UpdateEffects(left,c)
assert(not b.scene.shown and b.actor.fileID==nil and not second.nativeWanted)
E.SelectArtwork(c,'timelost','left');E.UpdateEffects(left,c);assert(not a.scene.shown and a.actor.fileID==nil)
E.SelectArtwork(c,'timekeeper','left');E.UpdateEffects(left,c);assert(a.scene.shown and a.actor.fileID==166011)
left.frame.hidden=true;left.frame.OnHide();assert(not a.scene.shown);left.frame.hidden=false;left.frame.OnShow();assert(a.scene.shown)
local source=c.addedEffects;local normalized=E.NormalizeSide(c,'left');normalized.addedEffects.timekeeper[1].trailX=100;assert(source.timekeeper[1].trailX==0)
local bad=E.NormalizeAddedEffect({fileID=166011,scale=0/0,trailX=math.huge});assert(bad.scale==1 and bad.trailX==0)
assert(not E.NormalizeAddedEffect({fileID=0}) and not E.NormalizeAddedEffect({fileID=1.5}))
E.RemoveLibraryEffect(c,1);E.UpdateEffects(left,c);assert(not a.scene.shown and not first.nativeWanted)
mode='loading';E.AddLibraryEffect(c,{fileID=165792,name='Cold'});E.UpdateEffects(left,c)
local stale=a.actor.endCapperOnModelLoaded
E.RemoveLibraryEffect(c,1);E.UpdateEffects(left,c);local before=scheduled;stale();tick();assert(scheduled==before and not a.scene.shown,'Removed layer cannot return after a late callback')
E.devMode=false;assert(not E.AddLibraryEffect(c,{fileID=166011}))
print('PASS: added-effect duplicate scenes, arbitrary fitted profile, camera basis, layers, pooled cleanup, late-load invalidation, Save/Cancel/reload, side/art/mode isolation and validation')
