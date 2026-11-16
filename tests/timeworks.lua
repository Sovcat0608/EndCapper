local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('Timeworks.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
local hosts={}
local now=0
function GetTime() return now end
local function surface()
    local t={scripts={}}
    function t:EnableMouse(v) self.mouse=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:SetAlpha(v) self.alpha=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:SetScript(k,v) self.scripts[k]=v end
    function t:SetTexture(v,x,y,filter) self.path,self.wrapX,self.wrapY,self.filter=v,x,y,filter end
    function t:SetSnapToPixelGrid(v) self.snap=v end
    function t:SetTexelSnappingBias(v) self.bias=v end
    function t:SetBlendMode(v) self.blend=v end
    function t:SetTexCoord(...) self.uv={...} end
    function t:SetSize(w,h) self.width,self.height=w,h end
    function t:ClearAllPoints() self.point=nil end
    function t:SetPoint(...) self.point={...} end
    function t:CreateTexture() return surface() end
    function t:CreateAnimationGroup()
        local g={animations={},owner=self,plays=0}
        function g:SetLooping(v) self.loop=v end
        function g:Play(_,offset) self.playing=true;self.offset=offset;self.plays=self.plays+1 end
        function g:Stop() self.playing=false end
        function g:IsPlaying() return self.playing end
        function g:CreateAnimation(kind)
            assert(kind=='Rotation' or kind=='Translation' or kind=='Alpha');local a={kind=kind}
            function a:SetDuration(v) self.duration=v end
            function a:SetOrder(v) self.order=v end
            function a:SetSmoothing(v) self.smoothing=v end
            function a:SetOrigin(...) self.origin={...} end
            function a:SetDegrees(v) self.degrees=v end
            function a:SetTarget(v) self.target=v;return true end
            function a:SetOffset(x,y) self.x,self.y=x,y end
            function a:SetFromAlpha(v) self.from=v end
            function a:SetToAlpha(v) self.to=v end
            g.animations[#g.animations+1]=a
            return a
        end
        return g
    end
    return t
end
function CreateFrame(kind,_,parent)
    assert(kind=='Frame');local h=surface();h.parent=parent;hosts[#hosts+1]=h;return h
end
E.UpdateNativeSmoke=function(e,c) e.nativeConfig=c;return false end
local function entry()
    return {alpha=0.6,art={GetSize=function() return 225,150 end},frame={scripts={},
        GetFrameLevel=function() return 10 end,IsVisible=function(self) return not self.hidden end,
        HookScript=function(self,k,fn) self.scripts[k]=fn end}}
end

function GetPhysicalScreenSize() return 1920,1080 end
local e=entry();e.frame.GetEffectiveScale=function()return .8 end
local c=E.NormalizeSide({art='timelost',flip=false},'right')
E.UpdateEffects(e,c);local s=e.timeworks
assert(s and s.middle.level==13 and s.frontHost.level==14 and s.middle.shown and s.frontHost.shown)
assert(s.glyphHost.level==15 and s.glyphHost.shown and #s.glyphs==2)
for _,layer in ipairs(s.glyphs) do
 assert(layer.texture.blend=='ADD' and layer.texture.width==225 and layer.texture.height==150)
 assert(layer.group.playing and layer.group.loop=='REPEAT' and #layer.group.animations==2)
 assert(layer.group.animations[1].duration==3 and layer.group.animations[2].duration==3)
 assert(layer.texture.path:find('TimelostGlyph',1,true))
end
assert(not e.nativeWanted and not e.effectsEnabled,'New pair must not request native effects')
assert(#s.gears==3 and not s.middle.scripts.OnUpdate,'Gear movement must use native animation')
for i,g in ipairs(s.gears) do
 assert(g.texture.snap==false and g.texture.bias==0 and g.texture.blend=='BLEND')
 assert(g.group.playing and g.group.loop=='REPEAT' and g.rotation.smoothing=='NONE')
 assert(g.texture.path:find('CASSize64.tga',1,true))
end
assert(s.gears[1].rotation.duration==32 and s.gears[2].rotation.duration==24 and s.gears[3].rotation.duration==28)
assert(s.gears[1].rotation.degrees==360 and s.gears[2].rotation.degrees==-360)
local plays=s.gears[1].group.plays;E.PlayEffects(e);assert(s.gears[1].group.plays==plays)
now=13.25;E.UpdateEffects(e,c);assert(s.elapsed==13.25 and s.gears[1].group.offset==13.25)
assert(s.glyphs[2].group.offset==1.25,'Glyph pulse preserves phase alongside gear rotation')
c.flip=true;E.UpdateEffects(e,c)
assert(s.gears[1].rotation.degrees==-360 and s.front.uv[1]==1)
assert(s.glyphs[2].texture.uv[1]==1,'Glyph mask mirrors with source art')
assert(math.abs(s.gears[1].texture.point[4]-225*(1-866/1086))<.00001)
now=15;e.frame.hidden=true;e.frame.scripts.OnHide();assert(not s.middle.shown and not s.gears[1].group.playing and s.elapsed==15)
now=1000;e.frame.hidden=false;e.frame.scripts.OnShow();assert(s.gears[1].group.offset==15)
c.effects=false;E.UpdateEffects(e,c);assert(s.middle.shown and s.frontHost.shown and not s.gears[1].group.playing)
assert(not s.glyphHost.shown and not s.glyphs[2].group.playing)
local other=entry();E.UpdateEffects(other,E.NormalizeSide({art='timelost'},'right'));assert(other.timeworks~=s and other.timeworks.elapsed==0)
c=E.NormalizeSide({art='timekeeper',flip=false},'left');E.UpdateEffects(e,c)
assert(s.art=='timekeeper' and s.elapsed==0 and s.middle.shown and not s.frontHost.shown and s.middle.scripts.OnUpdate)
assert(s.glyphs[2].texture.path:find('TimekeeperGlyph',1,true) and s.glyphs[2].group.playing)
for _,g in ipairs(s.gears)do assert(not g.texture.shown and not g.group.playing)end
assert(s.sand[1].width==225*184/1086 and s.sand[1].height==150*208/724)
now=1000.03125;s.middle.scripts.OnUpdate();assert(math.abs(s.sand[1].alpha-.5)<.00001 and math.abs(s.sand[2].alpha-.5)<.00001)
local uv=s.sand[1].uv[1];now=1002.03125;s.middle.scripts.OnUpdate();assert(s.sand[1].uv[1]==uv,'Sand loop must wrap exactly')
now=1002.1;E.StopEffects(e);local phase=s.elapsed;assert(not s.middle.scripts.OnUpdate and not s.middle.shown)
now=2000;E.PlayEffects(e);assert(s.elapsed==phase and s.middle.scripts.OnUpdate)
c.effects=false;E.UpdateEffects(e,c);assert(not s.middle.shown and not s.middle.scripts.OnUpdate)
E.UpdateEffects(e,E.NormalizeSide({art='default'},'left'));assert(not s.enabled and not s.middle.shown and not s.frontHost.shown)
assert(E.DefaultMirror('timekeeper','left') and not E.DefaultMirror('timekeeper','right'))
assert(E.DefaultMirror('timelost','right') and not E.DefaultMirror('timelost','left'))
print('PASS: Timeworks three native gear rotations, layer order, mirroring, phase/lifecycle, independent caps, sand crossfade and no native effects')
