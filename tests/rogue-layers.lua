local E={}
for _,file in ipairs({"Model.lua","LayerStack.lua","LayerPlacement.lua","Rogue.lua","EffectControls.lua","Effects.lua"}) do
    assert(loadfile(file))("EndCapper",E)
end

local now=0
local screenHeight=1080
local driver
function GetTime() return now end
function GetPhysicalScreenSize() return 1920,screenHeight end
function InCombatLockdown() return false end
local function frame()
    local result={scripts={},visible=true,regions={},vertices={}}
    function result:GetSize() return self.width or 225,self.height or 150 end
    function result:GetEffectiveScale() return 1 end
    function result:GetFrameLevel() return self.level or 10 end
    function result:SetFrameLevel(level) self.level=level end
    function result:SetSize(w,h) self.width,self.height=w,h end
    function result:IsVisible() return self.visible end
    result.IsShown=result.IsVisible
    function result:Show() self.visible=true end
    function result:Hide() self.visible=false end
    function result:SetShown(shown) self.visible=shown end
    function result:EnableMouse() end
    function result:SetAlpha(alpha) self.alpha=alpha end
    function result:GetAlpha() return self.alpha or 1 end
    function result:ClearAllPoints() self.point=nil end
    function result:SetPoint(...) self.point={...} end
    function result:SetAllPoints(relative)
        self.relative=relative
        self:SetPoint("CENTER",relative,"CENTER")
    end
    function result:GetPoint() return unpack(self.point or {}) end
    function result:GetCenter()
        if not self.point then return 0,0 end
        local _,relative,relativePoint,x,y=unpack(self.point)
        local rx,ry=relative:GetCenter()
        if relativePoint=="TOPLEFT" then
            local w,h=relative:GetSize()
            rx,ry=rx-w/2,ry+h/2
        end
        return rx+(x or 0),ry+(y or 0)
    end
    function result:HookScript(name,handler) self.scripts[name]=handler end
    result.SetScript=result.HookScript
    function result:SetTexture(path,_,_,filter) self.path=path;self.filter=filter;self.mask=nil end
    function result:SetTexCoord(...) self.uv={...} end
    function result:GetTexCoord() return unpack(self.uv or {}) end
    function result:SetVertexOffset(index,x,y) self.vertices[index]={x,y} end
    function result:GetVertexOffset(index) return unpack(self.vertices[index] or {0,0}) end
    function result:SetSnapToPixelGrid(value) self.snap=value end
    function result:SetTexelSnappingBias(value) self.bias=value end
    function result:CreateTexture(_,layer)
        local texture=frame()
        texture.drawLayer=layer
        self.regions[#self.regions+1]=texture
        return texture
    end
    function result:CreateMaskTexture()
        local mask=self:CreateTexture()
        function mask:GetObjectType() return "MaskTexture" end
        return mask
    end
    function result:AddMaskTexture(mask)
        assert(self.path and mask.path and not self.mask)
        self.mask=mask
    end
    function result:GetNumMaskTextures() return self.mask and 1 or 0 end
    function result:GetRegions() return unpack(self.regions) end
    function result:CreateAnimationGroup()
        local group={plays=0,turns={}}
        function group:SetLooping(loop) self.loop=loop end
        function group:Play(_,offset) self.plays=self.plays+1;self.offset=offset end
        function group:Stop() self.stopped=true end
        function group:CreateAnimation(kind)
            assert(kind=="Translation" or kind=="Rotation")
            local leg={}
            if kind=="Rotation" then self.turns[#self.turns+1]=leg end
            function leg:SetOrigin(point,x,y) assert(point=="CENTER" and x==0 and y==0) end
            function leg:SetDegrees(v) self.degrees=v end
            function leg:SetDuration(v) self.duration=v end
            function leg:SetOrder(v) self.order=v end
            function leg:SetSmoothing(v) self.smoothing=v end
            function leg:SetOffset(_,y) self.y=y end
            function leg:SetTarget(target) self.target=target end
            return leg
        end
        return group
    end
    return result
end
function CreateFrame(_,_,parent)
    local new=frame()
    if not parent then driver=new end
    return new
end

local c=E.NormalizeSide({art="venomveil",addedEffects={venomveil={},gloomfang={}}},"right")
local entry={side="right",frame=frame(),art=frame(),artLayer=frame(),owned=true,alpha=.65}
E.UpdateEffects(entry,c)
local rogue=entry.rogue
local pair=E.PairByArt.venomveil
assert(pair[1]=="gloomfang" and pair[2]=="venomveil")
assert(not c.flip and E.DefaultMirror("venomveil","left") and not E.DefaultMirror("gloomfang","left"))
assert(rogue.daggerHost.visible and rogue.dagger.path:find("VenomveilDaggerCASSize384%.tga"))
assert(rogue.daggerHost.point[4]==225*.71 and rogue.dagger.uv[1]==0)
assert(rogue.dagger.snap==false and rogue.dagger.bias==0)
assert(#rogue.daggerHost.regions==1 and rogue.daggerHost.regions[1]==rogue.dagger)
assert(rogue.motion.plays==1 and rogue.motion.loop=="REPEAT" and rogue.motion.offset==1.5)
local function checkCycle(s,top)
    local angles={-top,2*top,-top}
    local travel={-s.hoverAmplitude,2*s.hoverAmplitude,-s.hoverAmplitude}
    local duration=0
    for i,move in ipairs(s.translations) do
        local turn=s.motion.turns[i]
        assert(move.y==travel[i] and turn.degrees==angles[i] and turn.target==s.dagger)
        assert(move.order==turn.order and move.duration==turn.duration and move.smoothing==turn.smoothing)
        duration=duration+move.duration
    end
    assert(duration==6 and math.abs(2*s.hoverAmplitude-2*150*.88*.012-4)<1e-9)
end
checkCycle(rogue,1)
local left={side="left",frame=frame(),art=frame(),artLayer=frame(),owned=true,alpha=.65}
E.UpdateEffects(left,c)
checkCycle(left.rogue,-1)
assert(not rogue.flaskHost and not entry.roguePoison)
E.devMode=true
local layers={}
for _,row in ipairs(E.GetLayerStack(c)) do layers[row.id]=row end
local daggerLayer=layers["art:dagger"]
E.SetArtworkPlacement(c,daggerLayer,"trailSize",130)
E.SetArtworkPlacement(c,daggerLayer,"trailX",15)
E.SetArtworkPlacement(c,daggerLayer,"trailAngle",-20)
E.UpdateEffects(entry,c)
assert(rogue.dagger.vertices[1][1]~=0)
E.ResetArtworkPlacement(c,daggerLayer)
E.UpdateEffects(entry,c)
assert(E.MoveStudioLayer(c,"art:dagger",-1))
E.UpdateEffects(entry,c)
assert(rogue.daggerHost.level<entry.artLayer.level)
assert(E.MoveStudioLayer(c,"art:dagger",1))
E.AddLibraryEffect(c,{fileID=166011})
E.SetLayerMotion(c,"fx:1","art:dagger")
assert(E.MoveStudioLayer(c,"fx:1",-1))
local scene=frame()
local slot={scene=scene,layerAnchor={"CENTER",entry.art,"TOPLEFT",90,-40}}
entry.addedEffectSlots={{nativeWanted=true,nativeSmoke={slots={slot}}}}
E.ApplyLayerStack(entry,c)
local amplitude=rogue.hoverAmplitude
local function checkAttachment(fraction)
    local angle=math.rad(fraction)
    local cx,cy=225*.71,-150*.375
    local dx,dy=90-cx,-40-cy
    assert(math.abs(scene.point[4]-(cx+dx*math.cos(angle)-dy*math.sin(angle)))<1e-8)
    assert(math.abs(scene.point[5]-(cy+dx*math.sin(angle)+dy*math.cos(angle)+fraction*amplitude))<1e-8)
end
assert(driver.visible)
checkAttachment(-1)
assert(scene.level<rogue.daggerHost.level and scene.level>entry.artLayer.level)
now=1.5;driver.scripts.OnUpdate()
assert(math.abs(scene.point[5]+40)<1e-9)
now=3;driver.scripts.OnUpdate()
checkAttachment(1)
E.StopEffects(entry)
assert(not driver.visible and not rogue.daggerHost.visible and rogue.elapsed==4.5)
now=6
E.PlayEffects(entry)
assert(driver.visible and rogue.motion.offset==4.5)
checkAttachment(1)
E.UpdateEffects(entry,c)
assert(rogue.motion.plays==2,"Depth or effect refresh must not restart the dagger")
c.effects=false;E.UpdateEffects(entry,c)
assert(rogue.daggerHost.visible and not rogue.startedAt and scene.point[5]==-40)
c.art="gloomfang";c.effects=true;c.flip=true;E.UpdateEffects(entry,c)
assert(rogue.dagger.path:find("GloomfangDagger") and rogue.dagger.uv[1]>0)
assert(not driver.visible)
print("PASS: rogue pair defaults, two-layer artwork and dagger placement, native hover, live attachment and static fallback")
