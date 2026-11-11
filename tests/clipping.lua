-- Integration mock: clipping geometry and hierarchy, not GPU rasterization.
local E={}
for _,file in ipairs({"Model","Clipping","NativeSmoke","Glyphs","Arcane","Molten","Frost","Moonwell","Halos","Effects"}) do
    assert(loadfile(file..".lua"))("EndCapper",E)
end
local allocations,combat=0,false
function GetTime() return 10 end
function InCombatLockdown() return combat end
C_Timer={After=function() error("ready scenes must not poll") end}
E.Schedule=function() end
local function surface(parent)
    local s={parent=parent,shown=true,level=10,scripts={}}
    for _,method in ipairs({"SetTexture","SetBlendMode","SetTexCoord","SetDesaturation","SetDrawLayer",
        "SetSnapToPixelGrid","SetTexelSnappingBias","SetCameraNearClip","SetCameraFarClip",
        "SetCameraPosition","SetCameraOrientationByAxisVectors","SetCameraFieldOfView","SetViewInsets","SetViewTranslation",
        "SetLightAmbientColor","SetLightDiffuseColor"}) do
        s[method]=function(self,...) self[method.."Value"]={...} end
    end
    function s:EnableMouse(v) self.mouse=v end
    function s:SetClipsChildren(v) self.clips=v end
    function s:SetParent(p) self.parent=p end
    function s:SetFrameLevel(v) self.level=v end
    function s:GetFrameLevel() return self.level end
    function s:SetSize(w,h) self.width,self.height=w,h end
    function s:GetSize() return self.width,self.height end
    function s:ClearAllPoints() self.point=nil end
    function s:SetPoint(...) self.point={...} end
    function s:SetAllPoints(p) self.allPoints=p end
    function s:SetAlpha(v) self.alpha=v end
    function s:Show() self.shown=true end
    function s:Hide() self.shown=false end
    function s:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function s:HookScript(k,fn) self.scripts[k]=fn end
    function s:SetScript(k,fn) self.scripts[k]=fn end
    function s:CreateTexture() return surface(self) end
    function s:CreateAnimationGroup()
        local g={animations={},parent=self}
        function g:SetLooping(v) self.loop=v end
        function g:Play() self.playing=true end
        function g:Stop() self.playing=false end
        function g:CreateAnimation(kind)
            local a={kind=kind}
            for _,method in ipairs({"SetDuration","SetOrder","SetSmoothing","SetOrigin","SetDegrees",
                "SetTarget","SetOffset","SetFromAlpha","SetToAlpha"}) do
                a[method]=function(self,...) self[method.."Value"]={...};return true end
            end
            self.animations[#self.animations+1]=a;return a
        end
        return g
    end
    function s:CreateActor()
        local a={}
        function a:ClearModel() end
        function a:SetModelByFileID(id) self.fileID=id;return true end
        function a:IsLoaded() return true end
        for _,method in ipairs({"SetAnimation","SetScale","SetYaw","SetPitch","SetRoll","SetPosition","Show"}) do
            a[method]=function(self,...) self[method.."Value"]={...} end
        end
        return a
    end
    return s
end
function CreateFrame(kind,_,parent)
    assert(kind=="Frame" or kind=="ModelScene")
    allocations=allocations+1;return surface(parent)
end
local function entry()
    local cap=surface();local art=surface(cap);art:SetSize(225,150)
    -- World positions are only test inputs. Production follows anchors.
    art.cx,art.cy=100,120
    return {frame=cap,art=art,artLayer=surface(cap),alpha=.8}
end
local function bounds(clip)
    local p=clip.point;local art=p[2]
    assert(p[1]=="BOTTOM" and p[3]=="TOP" and p[4]==0)
    local bottom=art.cy+art.height/2+p[5]
    return art.cx-clip.width/2,art.cx+clip.width/2,bottom,bottom+clip.height
end
local function inside(clip,x,y)
    local l,r,b,t=bounds(clip)
    return x>=l and x<=r and y>=b and y<=t
end
local function check(entry,config,render,level)
    local clip=render.endCapperClip
    assert(clip and render.parent==clip and clip.parent==entry.frame)
    assert(clip.clips and clip.mouse==false and clip.level==level and render.level==level)
    assert(not clip.scripts.OnUpdate and clip.point[2]==entry.art)
    local l,r,b,t=bounds(clip)
    local expected=entry.art.cy+entry.art.height*(.5-E.EffectBaselines[config.art])
    assert(math.abs(b-expected)<.00001)
    -- Effect vertices on either side / high above remain inside; below is out.
    assert(l<entry.art.cx-1000 and r>entry.art.cx+1000 and t>b+2000)
    assert(inside(clip,entry.art.cx-1000,expected+.01))
    assert(inside(clip,entry.art.cx+1000,expected+2000))
    assert(not inside(clip,entry.art.cx,expected-.01))
    assert(not entry.frame.clips and not entry.artLayer.clips and not entry.art.clips)
    return clip
end
local function checkNative(entry,config,scene,level)
    assert(scene.parent==entry.frame and not scene.endCapperClip,
        "native scenes must not use generic clipping parents")
    assert(scene.level==level and not scene.clips and not entry.frame.clips)
    local v,h=scene.width,scene.height
    local bottom=scene.point[5]-h/2
    local baseline=-entry.art.height*E.EffectBaselines[config.art]
    local crop=v-h
    local insets=scene.SetViewInsetsValue
    assert(insets and insets[1]==0 and insets[2]==0 and insets[3]==0 and insets[4]==0,
        "camera insets do not establish the physical particle boundary")
    assert(h>0 and h<=v)
    if bottom+h<=baseline then
        assert(scene.alpha==0,"fully cropped scenes must have zero alpha and a valid viewport")
        return
    end
    assert(bottom>=baseline-.00001,"native frame extends below the artwork baseline")
    if crop>0 then assert(math.abs(bottom-baseline)<.00001,"physical boundary must meet the artwork baseline") end
    local translation=scene.SetViewTranslationValue
    assert(translation[1]==0)
    -- Compare perspective projections at multiple depths, not just the origin.
    -- Both axes must retain their original scale, and the viewport centre its
    -- original position. This checks the math, not GPU rasterization.
    local fov=scene.SetCameraFieldOfViewValue[1]
    for _,depth in ipairs({4,8,12}) do
        for _,point in ipairs({-1,0,1}) do
            local original=point*v/(2*depth*(3/8))
            local projectedY=crop/2+translation[2]+point*h/(2*depth*math.tan(fov/2))
            local projectedX=translation[1]+point*v/(2*depth*math.tan(fov/2)*(v/h))
            assert(math.abs(projectedY-original)<.00001,"native crop shifted/resized vertical projection")
            assert(math.abs(projectedX-original)<.00001,"native crop resized horizontal projection")
        end
    end
end
for _,art in ipairs(E.artworks) do
    if art.path then
        assert(E.EffectBaselines[art.id],"missing artwork baseline: "..art.id)
        local e=entry()
        for _,mirror in ipairs({false,true}) do
            for _,scale in ipairs({.5,1,2}) do
                e.art:SetSize(art.width*scale,art.height*scale)
                local c=E.GetEffectConfig(E.NormalizeSide({art=art.id,flip=mirror},"left"))
                E.UpdateEffects(e,c)
                local primary=e.nativeSmoke.slots[1].scene
                checkNative(e,c,primary,10+(c.effectLayer=="back" and 1 or art.id=="violetSpire" and 4 or 3))
                -- Width stays fixed; the physical height stops at the baseline.
                local expected=288*(e.art.width/150)*c.trailSize/100
                assert(math.abs(primary.width-expected)<.00001 and primary.height<=primary.width)
                local x,y,direction=E.EffectAnchor(E.EffectEmitters[1],e.art.width,e.art.height,c)
                local profile=E.NativeEffectProfiles[e.nativeSmoke.profileID]
                if not profile.centered then x=x+direction*.5*expected/6;y=y+.15*expected/6 end
                assert(math.abs(primary.point[4]-x)<.00001)
                assert(math.abs(primary.point[5]+primary.SetViewTranslationValue[2]-y)<.00001,
                    "cropped frame projection must retain the original calibrated centre")
                if e.secondaryEffect then
                    local second=e.secondaryEffect.nativeSmoke.slots[1].scene
                    checkNative(e,c,second,second.level)
                    assert(second~=primary,"paired layers have independent viewports")
                end
                for _,key in ipairs({"glyphs","molten","frost","moonwell","halo"}) do
                    if e[key] and e[key].enabled then check(e,c,e[key].host,10+(key=="halo" and 1 or 3)) end
                end
                if e.arcane then
                    local s=e.arcane
                    assert(not s.host.clips and s.host.parent==e.frame and s.crystal.parent==s.host)
                    assert(s.effectsHost.parent==s.host and s.effectsHost.clips)
                    assert(s.emission.parent==s.effectsHost and s.sigil.parent==s.effectsHost)
                    assert(s.effectsHost.point[2]==e.art and s.sigil.point[2]==s.host)
                    assert(#s.motionGroup.animations==4 and #s.rotationGroup.animations==1)
                end
                local n=allocations;E.UpdateEffects(e,c);assert(allocations==n,"Apply must reuse clips")
            end
        end
        E.UpdateEffects(e,E.NormalizeSide({art="hidden"},"left"))
        assert(not e.nativeSmoke.slots[1].scene.shown)
    end
end
-- Offsets/dragging follow the art without changing the selection frame; back
-- and front layers can swap independently on already allocated paired scenes.
local e=entry();local c=E.GetEffectConfig(E.NormalizeSide({art="skull"},"left"))
E.UpdateEffects(e,c)
local scene=e.nativeSmoke.slots[1].scene
local function nativeBottom()
    return e.art.cy+e.art.height/2+scene.point[5]-scene.height/2
end
local before=nativeBottom()
e.art.cx=e.art.cx+48;e.art.cy=e.art.cy+37
assert(math.abs(nativeBottom()-before-37)<.00001,"anchor follows artwork without Apply")
local point=scene.point;local size=scene.width
c.effectLayer="back";E.UpdateEffects(e,c)
checkNative(e,c,scene,11)
assert(e.secondaryEffect.nativeSmoke.slots[1].scene.level==13)
assert(scene.point[4]==point[4] and scene.point[5]==point[5] and scene.width==size)
e.frame:Hide();e.frame.scripts.OnHide();assert(not scene:IsVisible())
e.frame:Show();e.frame.scripts.OnShow();assert(scene:IsVisible())
local n=allocations;combat=true
assert(not E.UpdateNativeSmoke(e,c) and allocations==n and E.pending)
combat=false
-- Extreme supported controls preserve the original viewport's top/side edges.
for _,flip in ipairs({false,true}) do
    for _,x in ipairs({-150,150}) do
        for _,y in ipairs({-150,150}) do
            c.flip=flip;c.trailX=x;c.trailY=y;c.trailSize=200
            E.UpdateNativeSmoke(e,c)
            checkNative(e,c,scene,11)
        end
    end
end
-- A whole scene below the baseline must not create a zero-height projection.
c.trailSize=25;c.trailY=-150;E.UpdateNativeSmoke(e,c);checkNative(e,c,scene,11)
assert(scene.alpha==0)
c.trailY=150;E.UpdateNativeSmoke(e,c);checkNative(e,c,scene,11)
assert(scene.alpha>0 and scene.height==scene.width,"reuse restores a fully visible scene")
-- Missing native crop capability must not fall back to the failing wrapper.
for _,missing in ipairs({"SetViewTranslation"}) do
    local old=entry();E.UpdateEffects(old,c)
    local native=old.nativeSmoke.slots[1].scene
    native[missing]=nil
    c.trailY=-100;E.UpdateNativeSmoke(old,c)
    assert(native.parent==old.frame and not native.endCapperClip and native.alpha>0)
    assert(math.abs(native.SetCameraFieldOfViewValue[1]-2*math.atan(3/8))<.00001)
    assert(native.width==native.height)
end
-- Custom texture clipping retains its own capability fallback.
local old=entry();old.frame.SetClipsChildren=nil
E.UpdateEffects(old,E.GetEffectConfig(E.NormalizeSide({art="felwing"},"left")))
assert(not old.glyphs.host.endCapperClip)
print("PASS: native bottom-only crop/projection for 18 designs, custom masks, both facings/scales, paired layers, whole-scene crop/recovery, anchor motion, reuse, visibility, combat and capability fallbacks")
