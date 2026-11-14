local E={}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile('MageBooks.lua'))('EndCapper',E)
assert(loadfile('MageSigils.lua'))('EndCapper',E)
assert(loadfile('Effects.lua'))('EndCapper',E)
local nativeCalls={}
function E.UpdateNativeSmoke(entry,c) nativeCalls[#nativeCalls+1]={entry=entry,config=c};return true end
function E.StopNativeSmoke() end
function E.PlayNativeSmoke() end
assert(E.GetSigilConfig({art='emberbound'}).cycle==4,'Gentle flame defaults to four seconds')
assert(E.GetSigilConfig({art='emberbound',sigils={emberbound={cycle=7}}}).cycle==7,'Explicit timing remains respected')
local now=0
function GetTime() return now end
local function surface()
    local t={scripts={}}
    function t:EnableMouse(v) self.mouse=v end
    function t:Show() self.shown=true end
    function t:Hide() self.shown=false end
    function t:IsVisible() return not self.hidden end
    function t:SetScript(k,v) self.scripts[k]=v end
    function t:HookScript(k,v) self.scripts[k]=v end
    function t:SetFrameLevel(v) self.level=v end
    function t:GetFrameLevel() return self.level or 10 end
    function t:GetEffectiveScale() return 1 end
    function t:SetAlpha(v) self.alpha=v end
    function t:SetSize(w,h) self.width,self.height=w,h end
    function t:GetSize() return self.width or 225,self.height or 225 end
    function t:SetPoint(...) self.point={...} end
    function t:ClearAllPoints() self.point=nil end
    function t:SetTexture(v,...) self.path=v;self.filter={...} end
    function t:SetBlendMode(v) self.blend=v end
    function t:SetTexCoord(...) self.uv={...} end
    function t:SetSnapToPixelGrid(v) self.snap=v end
    function t:SetTexelSnappingBias(v) self.bias=v end
    function t:CreateTexture() return surface() end
    function t:CreateAnimationGroup()
        local g={animations={},plays=0}
        function g:SetLooping(v) self.loop=v end
        function g:Play(_,offset) self.playing=true;self.offset=offset;self.plays=self.plays+1 end
        function g:Stop() self.playing=false end
        function g:CreateAnimation(kind)
            local a={kind=kind}
            for _,key in ipairs({'Duration','Order','Smoothing','Degrees','FromAlpha','ToAlpha'}) do
                a['Set'..key]=function(self,v) self[key]=v end
            end
            function a:SetOrigin(...) self.origin={...} end
            function a:SetOffset(x,y) self.x,self.y=x,y end
            g.animations[#g.animations+1]=a;return a
        end
        return g
    end
    return t
end
function CreateFrame(_,_,parent) local t=surface();t.parent=parent;return t end
local function entry() return {frame=surface(),art=surface(),alpha=.6} end
local cold,fire=entry(),entry()
local c=E.NormalizeSide({art='frostbound',flip=false},'left')
local f=E.NormalizeSide({art='emberbound',flip=true},'right')
local retired=E.NormalizeSide({art='frostbound',devEffects={frostbound={selectedEffect='skyWind',skyWind={trailX=19}}}},'left')
assert(not E.CanSelectEffect('frostbound','skyWind') and E.SelectedEffect(retired)=='frostParticles')
assert(not retired.devEffects.frostbound.skyWind,'retired wind tuning is discarded')
E.UpdateEffects(cold,c);E.UpdateEffects(fire,f)
local s=cold.mageSigils;local hot=fire.mageSigils
assert(s.enabled and hot.enabled and cold.nativeWanted and fire.nativeWanted)
assert(s.host.parent==cold.frame and s.host.alpha==.6*.42 and s.host.level==16)
assert(s.host.point[5]==98-225*.72*.012 and s.host.width==225*.72*.65*.5,'above book, scales with artwork')
assert(s.hover.offset==5 and cold.mageBooks.motions[1].group.offset==0,'sigil lags book by one second')
assert(s.hoverLegs[1].Duration==3 and s.hoverLegs[2].Duration==3 and s.hoverLegs[1].Smoothing=='IN_OUT')
assert(#nativeCalls==7,'three frost and four fire native layers')
assert(cold.undercityEffects.blueGlow~=fire.undercityEffects.fireEmbers)
assert(not s.rotationGroup.playing and hot.rotationGroup.playing and hot.rotation.Degrees==-360)
assert(hot.rotation.Duration==40 and not hot.atlases[2].a.shown)
assert(hot.atlases[1].a.width==hot.base.width*.9 and hot.atlases[1].b.width==hot.base.width*.9,'only the flame is ten percent smaller')
assert(s.atlases[1].a.blend=='ADD' and s.base.blend=='ADD' and s.base.snap==false and s.base.bias==0)
now=1.25;s.tick();hot.tick()
local eye=s.atlases[1];local curl=s.atlases[2]
assert(eye.index==10 and curl.index==15,'pupil twice as fast; curls retain their period')
assert(math.abs(eye.a.alpha+eye.b.alpha-1)<.0001,'crossfade preserves total additive intensity')
local plays=hot.rotationGroup.plays
E.UpdateEffects(cold,c);assert(hot.rotationGroup.plays==plays,'other side does not restart')
assert(s.elapsed==1.25 and s.startedAt==1.25)
assert(s.hover.offset==.25 and cold.mageBooks.motions[1].group.offset==1.25,'refresh keeps book leading')
cold.frame.hidden=true;cold.frame.scripts.OnHide()
assert(not s.host.shown and not s.host.scripts.OnUpdate and not s.startedAt)
now=500;cold.frame.hidden=false;cold.frame.scripts.OnShow()
assert(s.startedAt==500 and s.elapsed==1.25,'hidden time does not advance or reset phase')
assert(s.hover.offset==.25 and cold.mageBooks.motions[1].group.offset==1.25,'hidden resume keeps one-second lag')
E.devMode=true;E.SetSigil(c,'x',20);E.SetSigil(c,'opacity',45);c.flip=true;c.size=150;cold.art:SetSize(337.5,337.5)
E.UpdateEffects(cold,c)
assert(s.host.point[4]==-30 and s.host.point[5]==147-337.5*.72*.012 and s.host.alpha==.6*.45)
assert(s.atlases[1].a.uv[1]>s.atlases[1].a.uv[5],'frame UVs mirror without changing atlas row')
E.SetSigil(c,'flip',true);E.UpdateEffects(cold,c);assert(not s.flip)
E.SetSigil(c,'opacity',0);E.UpdateEffects(cold,c);assert(not s.enabled and not s.host.shown and not s.host.scripts.OnUpdate)
E.SetSigil(c,'opacity',80);c.effects=false;E.UpdateEffects(cold,c);assert(not s.enabled)
c.effects=true;E.UpdateEffects(cold,c);E.UpdateEffects(cold,E.NormalizeSide({art='skull'},'left'))
assert(not s.enabled and not s.host.shown and not s.rotationGroup.playing)
-- Save/Cancel, normalization and mode isolation use the existing transactions.
EndCapperDB=E.Normalize({left={art='frostbound'},right={art='emberbound'}})
E.Begin();assert(not E.HasChanges())
E.SetSigil(E.draft.left,'size',120);assert(E.HasChanges())
E.SetSigil(E.draft.left,'size',50);assert(not E.HasChanges(),'explicit defaults remain clean')
E.SetSigil(E.draft.left,'y',111);E.Commit();E.Begin()
assert(E.GetSigilConfig(E.draft.left).y==111 and not E.HasChanges())
E.SelectMode(E.draft,'corner');assert(E.GetSigilConfig(E.draft.left).y==68)
E.SetSigil(E.draft.left,'y',88);E.Commit();E.Begin();E.SelectMode(E.draft,'end')
assert(E.GetSigilConfig(E.draft.left).y==111)
E.SetSigil(E.draft.left,'y',44);E.Cancel();E.Begin();E.SelectMode(E.draft,'end')
assert(E.GetSigilConfig(E.draft.left).y==111)
local bad=E.NormalizeSide({art='frostbound',sigils={frostbound={size=0/0,x=999,y=-999,opacity=-1,cycle=999,period=-99},invalid={}}},'left')
local v=E.GetSigilConfig(bad)
assert(v.size==50 and v.x==200 and v.y==-250 and v.opacity==0 and v.cycle==20 and v.period==8 and not bad.sigils.invalid)
E.devMode=false;E.SetSigil(bad,'x',0);assert(E.GetSigilConfig(bad).x==200)
E.Cancel()
print('PASS: mage sigil layers, independent native hover with one-second lag, UV frames/crossfades, mirroring, lifecycle, side isolation, modes, Save/Cancel and normalization')
