local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
for _,f in ipairs({'EffectCatalog.lua','EffectLibrary.lua','EffectPreview.lua','EffectAnimations.lua','EffectSegments.lua','EffectControls.lua','EffectBrowser.lua'}) do assert(loadfile(f))('EndCapper',E)end
local Viewer=E.EffectLibrary
unpack, tinsert = table.unpack, table.insert
local all = Viewer.Search("")
assert(#all > 9000 and all[1].preset)
local ids = {}
local presets = 0
for _, entry in ipairs(all) do
    assert(not ids[entry.id]); ids[entry.id] = true
    if entry.preset then presets = presets + 1 end
end
assert(presets == 32)
assert(Viewer.Search(" 166011 ")[1].name == "Fire")
assert(Viewer.Search("RED eye trail")[1].id == 166011)
assert(Viewer.Search("snowrain frost")[1].id == 165792)
assert(Viewer.Search("dalaran_eye_01.m2")[1].id == 243044)
assert(Viewer.Search("4294967295")[1].id == 4294967295)
assert(#Viewer.Search("4294967296") == 0 and #Viewer.Search("000") == 0)
assert(#Viewer.Search("[%") == 0)
print("Catalog PASS: unique model IDs, presets, aliases, literal search, and unlisted IDs")

local timers = {}
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function drain()
    while #timers > 0 do table.remove(timers, 1)() end
end

local widgets = {}
local function noop() end
local function object(kind, name)
    local widget = { kind = kind, name = name, shown = true, enabled = true, scripts = {}, value = "" }
    for method in ([=[SetAllPoints EnableMouse SetFrameStrata SetMovable SetClampedToScreen
        RegisterForDrag StartMoving StopMovingOrSizing SetBackdrop SetBackdropColor SetBackdropBorderColor
        SetPoint SetSize SetWidth SetHeight SetScale SetAutoFocus SetMaxLetters SetMaxLines SetTextColor
        SetJustifyH SetNormalTexture SetHighlightTexture SetDisabledTexture SetFontString
        SetDisabledFontObject SetDrawLayer SetAllowOverlappedModels SetCameraNearClip SetCameraFarClip
        SetCameraFieldOfView SetLightAmbientColor SetLightDiffuseColor SetDesaturation EnableMouseWheel
        SetNumeric SetAlpha]=]):gmatch("%S+") do widget[method] = noop end
    function widget:RegisterEvent()end
    function widget:SetChecked(v)self.checked=v end
    function widget:GetChecked()return self.checked end
    function widget:HookScript(k,fn)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;fn(...)end end
    function widget:SetValue(v)self.number=v;self:emit('OnValueChanged',v)end
    function widget:GetValue()return self.number end
    function widget:GetText() return self.value end
    function widget:GetName() return self.name end
    function widget:SetEnabled(enabled) self.enabled = enabled end
    if kind=='EditBox' then widget.SetEnabled=nil;function widget:Enable()self.enabled=true end;function widget:Disable()self.enabled=false end end
    function widget:SetColorTexture(...) self.color = { ... } end
    function widget:SetScript(event, handler) self.scripts[event] = handler end
    function widget:emit(event, ...) if self.scripts[event] then self.scripts[event](self, ...) end end
    function widget:Show() self:SetShown(true) end
    function widget:Hide() self:SetShown(false) end
    function widget:IsShown() return self.shown end
    function widget:SetShown(shown)
        if self.shown == shown then return end
        self.shown = shown
        self:emit(shown and "OnShow" or "OnHide")
    end
    function widget:CreateTexture() return object("Texture") end
    function widget:CreateFontString() return object("FontString") end
    function widget:HasFocus() return self.focus end
    function widget:SetFocus() self.focus = true; self:emit("OnEditFocusGained") end
    function widget:ClearFocus() self.focus = false; self:emit("OnEditFocusLost") end
    function widget:HighlightText() self.highlighted = true end
    function widget:SetText(text) self.value = text; self:emit("OnTextChanged", false) end
    widgets[#widgets + 1] = widget
    return widget
end

local function modelScene(scene)
    local actor = object("Actor")
    function actor:ClearModel() self.id, self.ready = nil, false end
    function actor:SetModelByFileID(id)
        self.id = id
        if id == 1 then return false end
        if id == 166011 then
            self.ready = true
            self.endCapperLibraryLoaded()
        end
        return true
    end
    function actor:GetModelFileID() return self.id end
    function actor:IsLoaded() return self.ready end
    function actor:SetAnimation(id) self.animation = id end
    function actor:SetScale(scale) self.scale = scale end
    function actor:SetPosition(...) self.position = { ... } end
    function actor:GetMaxBoundingBox() return -1, -2, 0, 1, 2, 4 end
    function scene:CreateActor() return actor end
    function scene:SetCameraPosition(...) self.camera = { ... } end
    function scene:SetCameraOrientationByAxisVectors(...) self.axes = { ... } end
    function scene:SetPaused(paused, affectsGlobalPause) assert(not affectsGlobalPause); self.paused = paused end
    return scene
end

function CreateFrame(kind, name,parent,template)
    local frame = object(kind, name)
    if kind == "ModelScene" then return modelScene(frame) end
    if template=="MinimalSliderWithSteppersTemplate" then
        frame.Slider=object("Slider")
        function frame:Init()end
    end
    return frame
end

local status
local preview = Viewer.CreatePreview(nil, function(message) status = message end)
preview:Load(Viewer.Search("165792")[1], 158)
local stale = preview.actor.endCapperLibraryLoaded
assert(preview.state == "loading")
preview:Load(Viewer.Search("166011")[1], 0)
stale()
drain()
assert(status == "Playing" and preview.actor.id == 166011 and preview.actor.animation == 0)
preview:TogglePause()
assert(status == "Paused" and preview.scene.paused)
preview:Load(Viewer.Search("166011")[1], 55, true)
assert(not preview.scene.paused and not preview.paused and preview.actor.animation == 55)
preview:TogglePause()
assert(status == "Paused" and preview.scene.paused)
preview:Load(Viewer.Search("2")[1], 0)
preview.actor.ready = true
drain()
assert(preview.state == "ready" and preview.actor.scale == 0.625 and preview.actor.position[3] == -1.25)
preview:SetView(1, 90)
assert(preview.actor.scale == 1.25 and math.abs(preview.scene.camera[1] + 8) < 0.00001)
preview:Fit()
assert(preview.actor.scale == 0.625)
preview:Load(Viewer.Search("1")[1], 0)
assert(status:find("unavailable") and not preview.scene:IsShown())
preview:Load(Viewer.Search("2")[1], 0)
drain()
assert(status:find("timed out") and not preview.scene:IsShown())
preview:Load(Viewer.Search("2")[1], 0)
preview:Clear()
drain()
assert(not preview.actor.id and not preview.scene:IsShown())
print("Preview PASS: cached load, polling fallback, stale callback, pause, replay, framing, rejection, and timeout")


UIParent={GetWidth=function()return 1920 end,GetHeight=function()return 1080 end};UISpecialFrames={}
MinimalSliderWithSteppersMixin={Label={Right=1}}
E.devMode=true;local combat=false;function InCombatLockdown()return combat end
EndCapperDB=E.Normalize({left={art='timekeeper',addedEffects={timekeeper={},timelost={}}},right={art='timelost',addedEffects={timekeeper={},timelost={}}}});E.Begin()
local side='left';local updates=0
E.GetEffectLibraryTarget=function()if E.draft and E.devMode then return E.draft[side],side,E.draft.mode end end
E.PreviewLibraryChange=function()updates=updates+1 end
E.SelectCapSide=function(v)if not combat then side=v;Viewer.RefreshTarget()end end
E.Message=function(v)E.report=v end
Viewer.Open();local panel=Viewer.window;drain();assert(panel:IsShown() and panel.add.enabled and panel.preview.state=='ready')
local controls=panel.layerControls
panel.add:emit('OnClick');assert(#E.GetAddedEffects(E.draft.left)==1 and E.HasChanges() and updates==1)
panel.add:emit('OnClick');assert(#E.GetAddedEffects(E.draft.left)==2 and controls.selected==2)
controls.sliders.trailY:SetValue(48);assert(E.GetAddedEffects(E.draft.left)[2].trailY==48)
controls.behind:SetChecked(true);controls.behind:emit('OnClick');assert(E.GetAddedEffects(E.draft.left)[2].effectLayer=='back')
controls.previous:emit('OnClick');controls.remove:emit('OnClick');assert(#E.GetAddedEffects(E.draft.left)==1 and E.GetAddedEffects(E.draft.left)[1].trailY==48)
controls.right:emit('OnClick');assert(controls.selected==1 and not controls.remove.enabled)
panel.add:emit('OnClick');assert(#E.GetAddedEffects(E.draft.right)==1)
E.Commit();E.Begin();panel.RefreshTarget();assert(not E.HasChanges())
controls.sliders.trailOpacity:SetValue(30);assert(E.HasChanges());E.Cancel();E.Begin();panel.RefreshTarget();assert(E.GetAddedEffects(E.draft.right)[1].trailOpacity==70)
combat=true;panel:emit('OnEvent');assert(not panel.add.enabled and not controls.remove.enabled)
local count=#E.GetAddedEffects(E.draft.right);panel.add:emit('OnClick');controls.remove:emit('OnClick');assert(#E.GetAddedEffects(E.draft.right)==count)
combat=false;panel:emit('OnEvent')
panel.search:SetText('165792');panel.search:emit('OnEnterPressed');assert(not panel.add.enabled)
panel.preview.actor.ready=true;panel.preview.actor.endCapperLibraryLoaded();drain();assert(panel.add.enabled)
panel.add:emit('OnClick');assert(E.GetAddedEffects(E.draft.right)[2].animation==158)
E.SelectMode(E.draft,'corner');panel.RefreshTarget();assert(not controls.remove.enabled)
E.devMode=false;Viewer.RefreshTarget();assert(not panel:IsShown() and not panel.preview.scene:IsShown() and panel.preview.actor.id==nil)
print('PASS: embedded library search/preview, ready-only Add, duplicate layers, selection/remove, real sliders, front/back, target switches, mode isolation, Save/Cancel, combat and dev-only cleanup')

E.Cancel();E.devMode=true;EndCapperDB=E.Normalize({left={art='frostbound'},right={art='emberbound'}});E.Begin();side='left'
Viewer.Open();panel.RefreshTarget()
local rows,builtins=E.GetLibraryRows(E.draft.left);assert(builtins==3 and #rows==3)
controls.selected=1;controls.Refresh();local id=rows[1].builtin
controls.sliders.trailY:SetValue(83);assert(E.GetEffectConfig(E.draft.left,id).trailY==83 and E.HasChanges())
controls.behind:SetChecked(true);controls.behind:emit('OnClick');assert(E.GetEffectConfig(E.draft.left,id).effectLayer=='back')
controls.remove:emit('OnClick');assert(E.GetEffectConfig(E.draft.left,id).trailOpacity==0,'Baked effect Hide preserves layer')
controls.reset:emit('OnClick');assert(E.GetEffectConfig(E.draft.left,id).trailOpacity==E.GetEffectDefaults('frostbound',id).trailOpacity)
panel.preview.actor.ready=true;panel.preview.actor.endCapperLibraryLoaded();drain();panel.add:emit('OnClick')
assert(controls.selected==4 and #E.GetAddedEffects(E.draft.left)==1,'Added layer selected after built-ins')
controls.sliders.trailX:SetValue(39);assert(E.GetAddedEffects(E.draft.left)[1].trailX==39)
E.Commit();E.Begin();panel.RefreshTarget();assert(not E.HasChanges())
controls.sliders.trailX:SetValue(20);E.Cancel();E.Begin();panel.RefreshTarget();assert(E.GetAddedEffects(E.draft.left)[1].trailX==39)
print('PASS: library edits baked native layers, hides/resets without deleting, mixed-layer indexing and Save/Cancel')

assert(panel.addBound==nil and controls.trigger==nil and controls.stopTest==nil and controls.bindingUI==nil)
local animation=controls.animationControls.input
animation:SetText('159');animation:emit('OnEnterPressed')
assert(E.GetAddedEffects(E.draft.left)[1].animation==159 and E.HasChanges())
E.Commit();E.Begin();panel.RefreshTarget();assert(not E.HasChanges())
animation:SetText('0');animation:emit('OnEnterPressed');assert(E.HasChanges())
E.Cancel();E.Begin();panel.RefreshTarget();assert(E.GetAddedEffects(E.draft.left)[1].animation==159)
combat=true;panel:emit('OnEvent');animation:SetText('0');animation:emit('OnEnterPressed')
assert(not animation.enabled and E.GetAddedEffects(E.draft.left)[1].animation==159)
combat=false;panel:emit('OnEvent');panel.custom:emit('OnClick');assert(panel.customArt and not controls.host:IsShown())
panel.custom:emit('OnClick');assert(not panel.customArt and controls.host:IsShown())
print('PASS: binding UI absent, aesthetic animation selection persists, Save/Cancel/combat guards and custom-art navigation retained')
