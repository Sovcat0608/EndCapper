-- Exercise real Options.lua handlers with a small widget surface mock.
local E={ready=true,caps={left={},right={}}}
assert(loadfile('Model.lua'))('EndCapper',E)
assert(loadfile("Clipping.lua"))("EndCapper", E)
assert(loadfile('NativeSmoke.lua'))('EndCapper',E)
local function widget()
    local w={scripts={},shown=true,enabled=true}
    for _,name in ipairs({'SetFrameStrata','SetClampedToScreen','EnableMouse','SetMovable','RegisterForDrag',
        'SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetAlpha','SetOrientation','EnableMouseWheel','SetAtlas','SetAllPoints','SetThumbTexture',
        'SetValueStep','SetObeyStepOnDrag','SetNormalTexture','SetCheckedTexture','SetHighlightTexture','SetTexture','SetTexCoord'}) do
        w[name]=function() end
    end
    function w:EnableMouse(v) self.mouse=v end
    function w:SetSize(x,y) self.width,self.height=x,y end
    function w:SetPoint(...) self.point={...} end
    function w:ClearAllPoints() self.point=nil end
    function w:SetText(v) self.text=v end
    function w:SetChecked(v) self.checked=v end
    function w:GetChecked() return self.checked end
    function w:SetEnabled(v) self.enabled=v end
    function w:SetScript(name,fn) self.scripts[name]=fn end
    function w:HookScript(name,fn)
        local old=self.scripts[name]
        self.scripts[name]=function(...) if old then old(...) end;fn(...) end
    end
    function w:Show() self.shown=true end
    function w:Hide()
        local was=self.shown; self.shown=false
        if was and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function w:IsShown() return self.shown end
    function w:SetShown(v) if v then self:Show() else self:Hide() end end
    function w:CreateFontString() return widget() end
    function w:CreateTexture() return widget() end
    function w:SetMinMaxValues(low,high) self.low,self.high=low,high end
    function w:GetMinMaxValues() return self.low,self.high end
    function w:GetWidth() return self.width or 2000 end
    function w:SetValue(v)
        if self.low then v=math.max(self.low,math.min(self.high,v)) end
        self.value=v
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
    end
    function w:GetValue() return self.value end
    function w:Click()
        if self.enabled and self.scripts.OnClick then self.checked=not self.checked; self.scripts.OnClick(self) end
    end
    function w:SetDefaultText(text) self.text=text end
    function w:SetupMenu(generator) self.generator=generator end
    function w:GenerateMenu()
        local root={items={}}
        function root:SetScrollMode(height) self.scrollHeight=height end
        function root:CreateRadio(text,selected,callback,data)
            local item={text=text,selected=selected,callback=callback,data=data}
            table.insert(self.items,item);return item
        end
        self.generator(self,root);self.menuDescription=root
        for _,item in ipairs(root.items) do if item.selected(item.data) then self.text=item.text end end
    end
    function w:CloseMenu() self.closed=true end
    return w
end
local widgets={}
MinimalSliderWithSteppersMixin={Label={Right=2}}
function PanelTemplates_SelectTab(tab) tab:SetEnabled(false) end
function PanelTemplates_DeselectTab(tab) tab:SetEnabled(true) end
function CreateFrame(_,_,parent,template)
    local w=widget();w.parent=parent;w.template=template;widgets[#widgets+1]=w
    if template=="MinimalSliderWithSteppersTemplate" then
        w.Slider,w.Back,w.Forward=widget(),widget(),widget()
        function w:UpdateStepperStates()
            local value=self.Slider:GetValue()
            self.Back:SetEnabled(self.enabled and value>self.Slider.low)
            self.Forward:SetEnabled(self.enabled and value<self.Slider.high)
        end
        function w:Init(value,low,high,steps,formatters)
            self.Slider:SetMinMaxValues(low,high)
            local step=(high-low)/steps
            self.Back:SetScript("OnClick",function() self.Slider:SetValue(self.Slider:GetValue()-step) end)
            self.Forward:SetScript("OnClick",function() self.Slider:SetValue(self.Slider:GetValue()+step) end)
            self.Slider:SetScript("OnValueChanged",function(_,v)
                self.rightText=formatters[MinimalSliderWithSteppersMixin.Label.Right](v)
                self:UpdateStepperStates()
            end)
            self.Slider:SetValue(value)
        end
        function w:SetEnabled(enabled)
            self.enabled=enabled;self.Slider:EnableMouse(enabled);self:UpdateStepperStates()
        end
        function w:IsSliderEnabled() return self.enabled end
    end
    return w
end
function InCombatLockdown() return false end
UIParent=widget(); UISpecialFrames={}
local applied={}
E.Apply=function(side) applied[#applied+1]=side or 'both' end
local printed
E.Message=function(v) printed=v end
EndCapperDB=E.Normalize({version=5,left={art='verdantRoot',devEffects={verdantRoot={trailOpacity=39}}}})
assert(loadfile('Options.lua'))('EndCapper',E)
E.devMode=true; E.OpenOptions('left')
local p=E.panel
local function choose(id,column)
    column=column or (p.heading.text=="Right end cap" and "right" or "left")
    local linked=E.draft.pair.linked
    local dropdown=linked and p.pairDropdown or p.artDropdowns[column]
    if linked and id~='default' and id~='hidden' then id=E.PairByArt[id][1] end
    dropdown:GenerateMenu()
    for _,item in ipairs(dropdown.menuDescription.items) do
        if item.data==id then item.callback(item.data);return end
    end
    error("Missing menu option "..id)
end
local function selected(id)
    local count=0
    for _,r in pairs(p.dev.radios) do if r:IsShown() and r.checked then count=count+1 end end
    assert(count==1 and p.dev.radios[id].checked, 'exactly one radio selected')
end
selected('moonlight')
p.dev.radios.faerieFire:Click(); selected('faerieFire')
p.dev.sliders.trailOpacity:SetValue(22)
p.dev.radios.faerieFire:Click(); selected('faerieFire') -- clicking selected never clears it
p.dev.radios.moonlight:Click(); selected('moonlight'); assert(p.dev.sliders.trailOpacity.value==39)
p.dev.radios.faerieFire:Click(); assert(p.dev.sliders.trailOpacity.value==22)
p.dev.report:Click(); assert(printed:find('Verdant / Faerie Fire',1,true))
p.dev.reset:Click(); selected('faerieFire'); assert(p.dev.sliders.trailOpacity.value==65)
p.dev.radios.moonlight:Click(); assert(p.dev.sliders.trailOpacity.value==39)
for _,id in ipairs({'verdantRoot'}) do
    choose(id); selected('moonlight')
    p.dev.radios.faerieFire:Click(); selected('faerieFire')
end
p.right:Click(); selected('amberFlow'); assert(not p.dev.radios.faerieFire:IsShown() and not p.dev.radios.coldFlame:IsShown())
choose('wolf'); selected('coldFlame'); assert(p.dev.radios.coldFlame.enabled and p.dev.radios.worgenGloom:IsShown())
p.left:Click(); selected('faerieFire')
p:Hide(); assert(E.draft==nil and EndCapperDB.left.art=='verdantRoot')
E.OpenOptions('left'); selected('moonlight')
E.devMode=false; E.RefreshOptions(); assert(not p.dev:IsShown())
print('PASS: real radio handlers, exactly-one selection/reclick, isolated sliders/reset/report, art/side switching and close rollback')
E.devMode=true; E.RefreshOptions()
for _,art in ipairs({'skull','lordaeron'}) do
    choose(art);selected('amberFlow')
    assert(p.dev.radios.amberFlow.shown and p.dev.radios.rotFog.shown and not p.dev.radios.coldFlame.shown)
    p.dev.sliders.trailX:SetValue(-30);p.dev.radios.rotFog:Click();selected('rotFog')
    assert(p.dev.sliders.trailX.value==(art=='skull' and -9 or 12) and not p.dev.behind.checked)
    p.dev.sliders.trailOpacity:SetValue(0);p.dev.behind:Click();p.dev.report:Click()
    assert(printed:find('Rot Fog',1,true) and printed:find('layer=back',1,true))
    p.dev.radios.amberFlow:Click();assert(p.dev.sliders.trailX.value==-30 and not p.dev.behind.checked)
    p.dev.radios.rotFog:Click();assert(p.dev.sliders.trailOpacity.value==0)
    p.dev.reset:Click();assert(p.dev.sliders.trailOpacity.value==3 and not p.dev.behind.checked)
end
p:Hide();E.OpenOptions('left');assert(E.draft.left.art=='verdantRoot')
print('PASS: Undead sister radios, independent sliders/layers, zero opacity, Print, Reset and Cancel')
E.devMode=true; E.RefreshOptions()
choose('stormhornTotem'); selected('blueGlow')
assert(p.dev.radios.blueGlow.enabled and not p.dev.radios.faerieFire:IsShown())
p.dev.sliders.trailX:SetValue(24); p.dev.sliders.trailOpacity:SetValue(41)
p.dev.report:Click(); assert(printed:find('Stormhorn / Blue Glow',1,true))
assert(E.GetEffectConfig(E.draft.left).trailX==24 and E.GetEffectConfig(E.draft.left).trailOpacity==41)
p.dev.reset:Click(); assert(p.dev.sliders.trailX.value==43 and p.dev.sliders.trailOpacity.value==100)
p.dev.sliders.trailOpacity:SetValue(41)
p.dev.radios.broadFlame:Click(); selected('broadFlame')
p.dev.sliders.trailOpacity:SetValue(27)
p.dev.radios.broadFlame:Click(); selected('broadFlame')
p.dev.report:Click(); assert(printed:find('Stormhorn / Broad Blue Flame',1,true))
p.dev.radios.blueGlow:Click(); assert(p.dev.sliders.trailOpacity.value==41)
p.dev.radios.broadFlame:Click(); assert(p.dev.sliders.trailOpacity.value==27)
p.dev.reset:Click(); assert(p.dev.sliders.trailOpacity.value==100)
p.dev.radios.blueGlow:Click(); assert(p.dev.sliders.trailOpacity.value==41)
p:Hide(); assert(EndCapperDB.left.art=='verdantRoot')
E.OpenOptions('left'); E.devMode=false; E.RefreshOptions()
choose('stormhornTotem')
assert(p.behind==nil and p.dev.behind.parent==p.dev.controls and not p.dev:IsShown())
assert(not p.dev.behind.enabled and not p.dev.behind.checked)
p.dev.behind:Click(); assert(E.GetEffectConfig(E.draft.left).effectLayer=='front')
E.devMode=true; E.RefreshOptions(); assert(p.dev:IsShown() and p.dev.behind.enabled)
p.dev.behind:Click(); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
E.Commit(); E.Begin()
E.devMode=false; E.RefreshOptions()
assert(not p.dev:IsShown() and not p.dev.behind.enabled and p.dev.behind.checked)
p.dev.behind:Click(); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
p:Hide(); E.OpenOptions('left'); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
E.devMode=true; E.RefreshOptions(); p.dev.radios.broadFlame:Click()
assert(p.dev.behind.checked); p.dev.behind:Click(); assert(not p.dev.behind.checked)
p.dev.report:Click(); assert(printed:find('layer=front',1,true))
p.dev.reset:Click(); assert(p.dev.behind.checked)
p.dev.radios.blueGlow:Click(); assert(p.dev.behind.checked)
choose('skull'); p.dev.behind:Click(); assert(E.GetEffectConfig(E.draft.left).effectLayer=='back')
choose('default'); assert(not p.dev.behind.enabled)
p:Hide()
print('PASS: totem exclusive radios, isolated calibration, Print/Reset/Cancel and dev-only layer control with persistent applied values')
E.devMode=true; E.OpenOptions('left'); choose('felwing'); selected('felDrip'); p.dev.radios.felGlow:Click(); selected('felGlow')
assert(p.dev.note.text:find('All three run',1,true) and not p.dev.radios.blueGlow:IsShown())
assert(p.artDropdowns.left.point[3]-p.artDropdowns.left.height>p.controls.point[3]+p.flip.point[3], 'flip stays below the artwork grid')
p.dev.sliders.trailX:SetValue(12); p.dev.radios.felDrip:Click(); selected('felDrip')
assert(p.dev.sliders.trailX.value==67)
p.dev.sliders.trailOpacity:SetValue(32); p.dev.behind:Click(); p.dev.report:Click()
assert(printed:find('Felwing / Fel Green Dripping',1,true) and printed:find('opacity=32%, layer=back',1,true))
p.dev.radios.felGlow:Click(); assert(p.dev.sliders.trailX.value==12 and not p.dev.behind.checked)
p.dev.radios.felDrip:Click(); p.dev.reset:Click(); assert(p.dev.sliders.trailOpacity.value==43 and not p.dev.behind.checked)
p:Hide()
print('PASS: Felwing dev radios, separate tuning/layers, report/reset and artwork grid spacing')

-- Checkbox reverses the per-artwork default, while stored flip stays a raw mirror.
local mirrorSide={cryptgate='left',plaguewell='right',hexbound='right',soulbound='left',frostmourneHilt='right',frostmourneBlade='left',seraph='left',sanctum='left',umbra='left',eclipse='left',skull='left',lordaeron='right',wolf='right',whiteWorgen='left',moonbough='left',verdantRoot='left',moonwell='left',
    lunarRelic='left',stormhornTotem='right',felwing='right',violetSpire='left',kirinTor='left',cinderforged='left',cindermaw='left',rimeforged='left',rimeguard='left'}
mirrorSide.banshee='right';mirrorSide.highGeneral='left'
EndCapperDB=E.Normalize(nil)
for _,side in ipairs({'left','right'}) do
    E.OpenOptions(side)
    assert(not p.flip.checked)
    for _,art in ipairs(E.artworks) do
        local expected=mirrorSide[art.id]==side
        choose(art.id)
        assert(not p.flip.checked and E.draft[side].flip==expected, art.id..' default '..side)
        if not art.path then
            assert(not p.flip.enabled and not p.snapBottom.enabled and not p.sliders.size.mouse)
            E.Commit();E.Begin();E.RefreshOptions()
        else
            p.flip:Click();assert(p.flip.checked and E.draft[side].flip==not expected)
            E.Commit(); EndCapperDB=E.Normalize(EndCapperDB); E.Begin(); E.RefreshOptions()
            assert(p.flip.checked and E.draft[side].flip==not expected, 'checked survives reload')
            p.flip:Click(); assert(not p.flip.checked and E.draft[side].flip==expected)
            E.Commit(); EndCapperDB=E.Normalize(EndCapperDB); E.Begin(); E.RefreshOptions()
            assert(not p.flip.checked and E.draft[side].flip==expected, 'default survives reload')
        end
    end
    choose('moonbough'); p.flip:Click()
    choose('wolf')
    assert(p.flip.checked and E.draft[side].flip==(side=='left'), 'switch preserves reversal intent')
    choose('moonbough')
    assert(p.flip.checked and E.draft[side].flip==(side=='right'))
    p:Hide(); assert(EndCapperDB[side].art=='hidden', 'close discards orientation preview')
end
for _,side in ipairs({'left','right'}) do
    for _,art in ipairs(E.artworks) do
        for _,raw in ipairs({false,true}) do
            EndCapperDB=E.Normalize({version=12,[side]={art=art.id,flip=raw,x=23,size=137}})
            E.OpenOptions(side)
            assert(E.draft[side].flip==raw and p.flip.checked==(raw~=(mirrorSide[art.id]==side)))
            E.Commit(); EndCapperDB=E.Normalize(EndCapperDB)
            assert(EndCapperDB[side].flip==raw and EndCapperDB[side].x==23 and EndCapperDB[side].size==137)
            p:Hide()
        end
    end
end
EndCapperDB=E.Normalize({left={art='moonbough'}})
E.OpenOptions('left'); p.dev.report:Click()
assert(printed:find('flip=false, mirrored=true',1,true), 'report distinguishes UI flip from texture mirror')
p:Hide()
print('PASS: all artwork/side default facings, checkbox reversal, art switching, reload/Cancel and saved appearance compatibility')
E.devMode=true;E.OpenOptions('right');choose('violetSpire')
selected('arcaneGlow');assert(not p.dev.radios.arcaneGlow.enabled)
assert(p.dev.note.text:find('Native glow only',1,true) and not p.dev.behind.checked)
p.dev.sliders.trailX:SetValue(-30);p.dev.sliders.trailOpacity:SetValue(21);p.dev.behind:Click()
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.RefreshOptions()
assert(p.dev.sliders.trailX.value==-30 and p.dev.sliders.trailOpacity.value==21 and p.dev.behind.checked)
p.dev.report:Click();assert(printed:find('Violetspire / Arcane Glow',1,true))
p.dev.reset:Click();assert(p.dev.sliders.trailX.value==-23 and p.dev.sliders.trailOpacity.value==61 and not p.dev.behind.checked)
p:Hide();E.OpenOptions('right');assert(p.dev.sliders.trailX.value==-30)
assert(p.height==614 and p.artDropdowns.left.point[3]-p.artDropdowns.left.height>p.controls.point[3]+p.flip.point[3])
p:Hide()
print('PASS: arcane dev glow calibration, Print/Reset/Cancel/reload, layer controls and artwork grid spacing')
EndCapperDB=E.Normalize({version=14,left={art='violetSpire'},right={art='violetSpire'}})
E.devMode=true;E.OpenOptions('left')
assert(p.dev.seal:IsShown() and p.dev.height==510 and p.dev.seal.slider.value==153)
p.dev.seal.slider:SetValue(175);p.dev.sliders.trailOpacity:SetValue(23)
assert(E.GetEffectConfig(E.draft.left).sealSize==175 and E.GetEffectConfig(E.draft.right).sealSize==153)
p.dev.report:Click();assert(printed:find('seal=175%',1,true))
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.RefreshOptions()
assert(p.dev.seal.slider.value==175 and E.draft.left.trailOpacity==23)
p.dev.seal.slider:SetValue(80);p:Hide();E.OpenOptions('left');assert(p.dev.seal.slider.value==175)
p.dev.reset:Click();assert(p.dev.seal.slider.value==153);p:Hide()
E.devMode=false;E.OpenOptions('left');assert(not p.dev.seal:IsShown())
p.dev.seal.slider:SetValue(50);assert(E.GetEffectConfig(E.draft.left).sealSize==175)
E.devMode=true;E.RefreshOptions();choose('wolf')
assert(not p.dev.seal:IsShown() and p.dev.height==453)
p.dev.seal.slider:SetValue(50);choose('violetSpire');assert(p.dev.seal.slider.value==175)
p.right:Click();assert(p.dev.seal.slider.value==153)
p:Hide()
for _,spec in ipairs({{0,25},{999,250},{0/0,153},{'invalid',153}}) do
    local c=E.NormalizeSide({art='violetSpire',devEffects={violetSpire={sealSize=spec[1]}}},'left')
    assert(c.sealSize==spec[2])
end
print('PASS: dev-only seal slider, independent sides/art, bounds, Print/Reset, Apply/Cancel/reload and native-tuning preservation')
E.devMode=true;E.OpenOptions('right')
for _,art in ipairs({'cinderforged','cindermaw'}) do
    choose(art); selected('fireGlow')
    assert(p.dev.radios.fireGlow.shown and p.dev.radios.fireFlame.shown and not p.dev.seal.shown)
    p.dev.radios.fireFlame:Click();selected('fireFlame')
    assert(p.dev.sliders.trailX.mouse and p.dev.behind.enabled)
    assert(p.dev.note.text:find('cracks stay fixed',1,true))
end
print('PASS: two molten choices, native edit radios and dev controls; no seal/eye controls')
E.devMode=true;E.OpenOptions('right')
for _,art in ipairs({'rimeforged','rimeguard'}) do
    choose(art);selected('coldFlame')
    assert(p.dev.radios.coldFlame.shown and p.dev.radios.frostEnchant.shown and not p.dev.seal.shown)
    p.dev.radios.frostEnchant:Click();selected('frostEnchant')
    p.dev.sliders.trailX:SetValue(39);p.dev.report:Click();assert(printed:find('Frost Form',1,true))
    p.dev.radios.coldFlame:Click();assert(p.dev.sliders.trailX.value==(art=='rimeforged' and -150 or -89))
    assert(p.dev.note.text:find('emission stays fixed',1,true))
end
assert(p.height==614)
print('PASS: frost native edit radios, independent slider/report controls and fourteen-choice grid')
choose('moonwell');selected('moonwellGlow')
assert(p.dev.radios.waterRipple.shown and not p.dev.radios.frostEnchant.shown)
p.dev.sliders.trailOpacity:SetValue(23);p.dev.radios.waterRipple:Click();selected('waterRipple')
p.dev.sliders.trailX:SetValue(38);p.dev.report:Click();assert(printed:find('Moonwell / Water Ripples',1,true))
p.dev.radios.moonwellGlow:Click();assert(p.dev.sliders.trailOpacity.value==23)
p.dev.radios.waterRipple:Click();assert(p.dev.sliders.trailX.value==38)
print('PASS: Moonwell radios, independent calibration, report and expanded chooser')
choose('seraph');selected('holyGlow')
assert(p.dev.effectsTab:IsShown() and p.dev.haloTab:IsShown() and p.dev.height==487)
assert(p.dev.radios.sunRays:IsShown() and not p.dev.halo:IsShown())
p.dev.sliders.trailOpacity:SetValue(29);p.dev.radios.sunRays:Click();selected('sunRays')
p.dev.sliders.trailX:SetValue(17);p.dev.behind:Click();p.dev.report:Click()
assert(printed:find('Seraph / Divine Radiance',1,true) and printed:find('layer=back',1,true))
p.dev.radios.holyGlow:Click();assert(p.dev.sliders.trailOpacity.value==29)
p.dev.haloTab:Click();assert(p.dev.halo:IsShown() and not p.dev.controls:IsShown())
for _,r in pairs(p.dev.radios) do assert(not r:IsShown()) end
p.dev.halo.sliders.size:SetValue(170);p.dev.halo.sliders.x:SetValue(11);p.dev.halo.sliders.period:SetValue(75)
p.dev.halo.reverse:Click();p.dev.halo.report:Click()
assert(printed:find('Seraph / Halo',1,true) and printed:find('revolution=75s',1,true))
choose('umbra');assert(p.dev.halo.sliders.size.value==132)
choose('seraph');assert(p.dev.halo.sliders.size.value==170 and p.dev.halo.reverse.checked)
p.dev.halo.reset:Click();assert(p.dev.halo.sliders.period.value==40 and p.dev.halo.sliders.x.value==-40 and p.dev.halo.sliders.size.value==125)
p.dev.effectsTab:Click();p.dev.radios.sunRays:Click();assert(p.dev.sliders.trailX.value==17 and p.dev.behind.checked)
choose('umbra');selected('voidGlow');assert(p.dev.radios.voidSmoke:IsShown() and not p.dev.radios.holyGlow:IsShown())
p.dev.radios.voidSmoke:Click();p.dev.sliders.trailOpacity:SetValue(31);p.dev.report:Click()
assert(printed:find('Umbra / Void Smoke',1,true))
E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.RefreshOptions()
assert(p.dev.sliders.trailOpacity.value==31)
p.dev.sliders.trailOpacity:SetValue(8);p:Hide();E.OpenOptions('right');assert(p.dev.sliders.trailOpacity.value==31)
p.dev.reset:Click();assert(p.dev.sliders.trailOpacity.value==20)
p.dev.haloTab:Click() -- Switching from a hood's Halo tab must expose sister effects.
for _,spec in ipairs({{'sanctum','holyGlow','sunRays','Sanctum / Divine Radiance',1},
    {'eclipse','voidGlow','voidSmoke','Eclipse / Void Smoke',18}}) do
    local art,glow,other,report,opacity=unpack(spec)
    choose(art);selected(glow)
    assert(p.dev.height==453 and not p.dev.halo:IsShown() and p.dev.report:IsShown())
    assert(not p.dev.haloTab:IsShown() and not p.dev.effectsTab:IsShown() and p.dev.sliders.trailX:IsShown())
    assert(p.dev.radios[other]:IsShown() and p.dev.behind:IsShown())
    p.dev.sliders.trailOpacity:SetValue(19);p.dev.radios[other]:Click();selected(other)
    p.dev.sliders.trailX:SetValue(27);p.dev.sliders.trailOpacity:SetValue(12);p.dev.behind:Click();p.dev.report:Click()
    assert(printed:find(report,1,true) and printed:find('layer=back',1,true))
    E.Commit();EndCapperDB=E.Normalize(EndCapperDB);E.Begin();E.RefreshOptions()
    assert(p.dev.sliders.trailX.value==27 and p.dev.behind.checked)
    p.dev.sliders.trailX:SetValue(80);p:Hide();E.OpenOptions('right');assert(p.dev.sliders.trailX.value==27)
    p.dev.reset:Click();assert(p.dev.sliders.trailOpacity.value==opacity and not p.dev.behind.checked)
    p.dev.radios[glow]:Click();assert(p.dev.sliders.trailOpacity.value==19)
end
choose('umbra');assert(p.dev.halo:IsShown() and not p.dev.controls:IsShown())
p.dev.effectsTab:Click();selected('voidSmoke');assert(p.dev.sliders.trailOpacity.value==20)
choose('seraph');p.dev.radios.holyGlow:Click();assert(p.dev.sliders.trailOpacity.value==29)
choose('moonwell');assert(not p.dev.halo:IsShown() and p.dev.sliders.trailX:IsShown());selected('waterRipple')
E.devMode=false;choose('seraph');assert(not p.dev:IsShown() and not p.dev.halo:IsShown())
print('PASS: hood-only halo tabs, all priest effect radios, sister tuning isolation, Print/Reset, Apply/Cancel/reload and dev visibility')
-- Every live preview, including developer controls, targets the active side.
local function targets(expected,fn)
    applied={};fn()
    assert(#applied>0,'expected preview update')
    for _,side in ipairs(applied) do assert(side==expected,'preview refreshed the wrong side: '..side) end
end
local function panelButton(text)
    for _,w in ipairs(widgets) do if w.parent==p and w.text==text then return w end end
    error('missing button '..text)
end
E.devMode=true
for _,active in ipairs({'left','right'}) do
    E.OpenOptions(active)
    targets(active,function() choose('moonwell') end)
    targets(active,function() p.flip:Click() end)
    targets(active,function() p.sliders.x:SetValue(11) end)
    targets(active,function() p.dev.radios.waterRipple:Click() end)
    targets(active,function() p.dev.sliders.trailX:SetValue(9) end)
    targets(active,function() p.dev.behind:Click() end)
    targets(active,function() p.dev.reset:Click() end)
    targets(active,function() choose('seraph') end)
    p.dev.haloTab:Click()
    targets(active,function() p.dev.halo.sliders.size:SetValue(130) end)
    targets(active,function() p.dev.halo.reverse:Click() end)
    targets(active,function() p.dev.halo.reset:Click() end)
    targets(active,function() choose('violetSpire') end)
    targets(active,function() p.dev.seal.slider:SetValue(140) end)
    targets(active,function() panelButton('Reset side'):Click() end)
    targets('both',function() panelButton('Save'):Click() end)
    targets('both',function() p:Hide() end)
end
E.OpenOptions('left');applied={};p.right:Click();p.left:Click();E.RefreshOptions()
assert(#applied==0,'side tabs and widget synchronization must not refresh effects')
print('PASS: every real preview handler targets its active side; Apply/Cancel still cover both; side tabs do not render')

E.devMode=true;E.OpenOptions('left')
for _,art in ipairs({'moonbough','lunarRelic'}) do
 choose(art);assert(not p.dev.radios.faerieFire:IsShown() and p.dev.radios.moonlight:IsShown())
end
choose('verdantRoot');assert(p.dev.radios.faerieFire:IsShown())
p:Hide()
print('PASS: Moonbough/Lunar hide removed radio, Verdant retains it')

-- Shared controls exercise the real panel handlers, with persistence and rollback.
EndCapperDB=E.Normalize({left={art='seraph',size=120,x=12,y=-8},right={art='wolf',size=85}})
E.OpenOptions('left');assert(not p.link.checked and not p.swap:IsShown() and not p.separation.control:IsShown())
assert(p.artDropdowns.left.point[2]<p.artDropdowns.right.point[2])
assert(p.artDropdowns.left.menuDescription.scrollHeight==280 and p.artDropdowns.right.menuDescription.scrollHeight==280)
assert(E.PairByArt.moonbough==E.PairByArt.lunarRelic and E.PairByArt.verdantRoot==E.PairByArt.moonwell)
assert(p.artButtons==nil and p.placeholders==nil)
p.link:Click()
assert(E.draft.pair.linked and not p.left.enabled and not p.right.enabled and p.swap:IsShown())
assert(E.draft.left.art=='seraph' and E.draft.right.art=='sanctum')
assert(not p.artDropdowns.left:IsShown() and not p.artDropdowns.right:IsShown() and p.pairDropdown:IsShown())
p.right:Click();assert(p.heading.text=='Linked end caps')
p.swap:Click();assert(E.draft.left.art=='sanctum' and E.draft.right.art=='seraph')
p.flip:Click();assert(E.FlipChecked(E.draft.left,'left') and E.FlipChecked(E.draft.right,'right'))
p.sliders.size:SetValue(135);p.sliders.x:SetValue(20);p.sliders.y:SetValue(-30);p.separation:SetValue(80)
assert(E.draft.left.size==135 and E.draft.right.size==135 and E.draft.left.x==0 and E.draft.right.x==0 and E.draft.pair.x==20)
assert(E.draft.left.y==-30 and E.draft.right.y==-30)
E.Commit();E.Begin();E.RefreshOptions();assert(p.link.checked and p.swap.checked and p.separation.value==80)
p.link:Click();assert(not E.draft.pair.linked and p.right.enabled and not p.swap:IsShown())
assert(E.draft.left.x==0 and E.draft.right.x==0 and E.draft.pair.x==20)
p.sliders.size:SetValue(75);assert(E.draft.right.size==135)
p:Hide();E.OpenOptions('left');assert(E.draft.pair.linked and E.draft.left.size==135)
for _,row in ipairs(E.ArtworkPairs) do
 if row[1]~='default' then
  choose(row[1],'right')
  assert(E.draft.left.art==(row[2] or row[1]) and E.draft.right.art==row[1])
 end
end
p.resetSide:Click();assert(not E.draft.pair.swapped and E.draft.pair.size==100 and E.draft.pair.separation==600)
choose('hidden');assert(E.draft.left.art=='hidden' and E.draft.right.art=='hidden')
p:Hide()
print('PASS: real linked controls, joined sister rows, placeholders, side locks, swap, flip, shared sliders, separation, Reset, utility choices, Apply/reopen and Cancel')

EndCapperDB=E.Normalize({left={art='wolf',x=27,y=40,frameBottom=false,artBottom=false},right={art='moonbough',y=50,frameBottom=false}})
E.OpenOptions('left');local n=#applied;p.snapBottom:Click()
assert(E.draft.left.frameBottom and E.draft.left.artBottom and E.draft.left.y==0 and E.draft.left.x==27)
assert(E.draft.right.y==50 and not E.draft.right.frameBottom and applied[#applied]=='left')
p:Hide();E.OpenOptions('left');assert(not E.draft.left.frameBottom and E.draft.left.y==40)
p.link:Click();E.draft.left.frameBottom=false;E.draft.right.frameBottom=false;p.sliders.y:SetValue(70)
p.snapBottom:Click();assert(E.draft.left.frameBottom and E.draft.right.frameBottom and E.draft.pair.y==0 and applied[#applied]=='both')
p.sliders.y:SetValue(30);p.resetSide:Click();assert(E.draft.pair.y==0 and E.draft.left.frameBottom and E.draft.right.frameBottom)
p.link:Click();E.draft.left.frameBottom=false;p.sliders.y:SetValue(30);p.resetSide:Click()
assert(E.draft.left.y==0 and E.draft.left.frameBottom and E.draft.left.artBottom)
p:Hide()
assert(p.controls.point[3]+p.snapBottom.point[3]-p.snapBottom.height>p.resetSide.point[3],'Snap control stays above footer buttons')
print('PASS: Snap bottom and Reset handlers in both modes, targeted versus paired refresh, X preservation and Cancel')

EndCapperDB=E.Normalize(nil);E.OpenOptions('left')
for _,column in ipairs({'left','right'}) do
 local dropdown=p.artDropdowns[column];dropdown:GenerateMenu()
 local seen,count={},0
 for _,item in ipairs(dropdown.menuDescription.items) do
  assert(not seen[item.data],'menu must not duplicate standalone choices');seen[item.data]=true;count=count+1
 end
 assert(count==#E.artworks and dropdown.menuDescription.scrollHeight==280)
 for _,art in ipairs(E.artworks) do
  choose(art.id,column);assert(E.draft[column].art==art.id)
  assert(p.heading.text==(column=='left' and 'Left end cap' or 'Right end cap'))
 end
end
p.link:Click()
assert(p.pairDropdown:IsShown() and not p.artDropdowns.left:IsShown() and not p.artDropdowns.right:IsShown())
p.pairDropdown:GenerateMenu()
assert(#p.pairDropdown.menuDescription.items==17 and p.pairDropdown.menuDescription.scrollHeight==280)
for _,row in ipairs(E.ArtworkPairs) do
 choose(row[1])
 local left,right=row[1],row[2] or row[1]
 if row[1]=='default' then right='default' end
 assert(E.draft.left.art==left and E.draft.right.art==right)
end
choose('moonbough');assert(E.draft.right.art=='lunarRelic' and p.pairDropdown.text=='Moonbough / Lunar')
p.swap:Click();assert(p.pairDropdown.text=='Lunar / Moonbough')
p.swap:Click();choose('verdantRoot');assert(E.draft.right.art=='moonwell')
E.Commit();E.Begin();E.RefreshOptions()
assert(p.pairDropdown.text=='Verdant / Moonwell')
p:Hide();assert(p.artDropdowns.left.closed and p.artDropdowns.right.closed and p.pairDropdown.closed)
print('PASS: scrolling native-menu generators, unique complete choices in each column, both-column independent targeting, linked sister orientation, utility/twin choices, labels, commit and close cleanup')

EndCapperDB=E.Normalize(nil);E.OpenOptions('left');p.link:Click()
assert(p.separation.low==0 and p.separation.high==2000)
p.separation:SetValue(2000)
assert(E.draft.pair.separation==2000 and E.draft.left.x==0 and E.draft.right.x==0)
p.separation.scripts.OnMouseWheel(p.separation,1);assert(p.separation.value==2000)
p.separation:SetValue(0);p.separation.scripts.OnMouseWheel(p.separation,-1);assert(p.separation.value==0)
p:Hide()
print('PASS: separation slider and wheel bounds 0..2000, with frame spacing separate from artwork X')

EndCapperDB=E.Normalize({left={art='wolf'},right={art='wolf'}});E.OpenOptions('left')
assert(p.save.text=='Save' and not p.save.enabled and not p.pairDropdown:IsShown())
local before=#applied;p.save:Click();assert(#applied==before,'disabled Save does nothing')
p.sliders.x:SetValue(1);assert(p.save.enabled)
p.sliders.x:SetValue(0);assert(not p.save.enabled,'returning to saved X disables Save')
p.flip:Click();assert(p.save.enabled);p.flip:Click();assert(not p.save.enabled)
p.link:Click();assert(p.save.enabled and p.pairDropdown:IsShown())
assert(not p.artDropdowns.left:IsShown() and not p.artDropdowns.right:IsShown())
assert(not p.artDropdownLabels.left:IsShown() and p.pairDropdownLabel:IsShown())
p.save:Click();assert(not p.save.enabled and EndCapperDB.pair.linked)
p.swap:Click();assert(p.save.enabled);p.swap:Click();assert(not p.save.enabled)
choose('moonbough');assert(p.save.enabled and p.pairDropdown.text=='Moonbough / Lunar')
p.save:Click();assert(not p.save.enabled and EndCapperDB.left.art=='moonbough' and EndCapperDB.right.art=='lunarRelic')
p.separation:SetValue(200);assert(p.save.enabled)
p:Hide();E.OpenOptions('left');assert(not p.save.enabled and p.separation.value==600)
p.link:Click();assert(p.save.enabled and not p.pairDropdown:IsShown() and p.artDropdowns.left:IsShown() and p.artDropdowns.right:IsShown())
p.save:Click();assert(not p.save.enabled)
E.devMode=true;E.RefreshOptions();local original=p.dev.sliders.trailOpacity.value
p.dev.sliders.trailOpacity:SetValue(original+1);assert(p.save.enabled)
p.dev.sliders.trailOpacity:SetValue(original);assert(not p.save.enabled)
p:Hide()
print('PASS: single visible linked combo menu, paired labels, Save rename/enabling/no-op, reverted values, save/cancel, mode switching and developer slider dirty state')

-- Use the real profile reconciler in the preview path, not an unconditional
-- Apply stub: the native active index includes three omitted preset rows.
local oldAPI,oldEnum,oldPresets=C_EditMode,Enum,EditModePresetLayoutManager
Enum={EditModeLayoutType={Preset=0,Account=1,Character=2}}
EditModePresetLayoutManager={presetLayoutInfo={{layoutName='Modern',layoutType=0},{layoutName='Classic',layoutType=0},{layoutName='Controller',layoutType=0}}}
local info={activeLayout=4,layouts={{layoutName='Druid',layoutType=1}}}
C_EditMode={GetLayouts=function() return info end}
assert(loadfile('Layouts.lua'))('EndCapper',E)
local rendered
E.Apply=function()
    local allowed=E.ReconcilePositionLayout()
    if allowed then rendered=E.Normalize(E.Config()) end
end
EndCapperDB=E.Normalize({left={art='moonbough'},right={art='lunarRelic'},pair={linked=true,art='moonbough'}})
E.OpenOptions('left');assert(E.activePositionLayout and E.draft and p:IsShown())
choose('seraph');assert(rendered.left.art=='seraph' and rendered.right.art=='sanctum')
p.sliders.size:SetValue(130);p.sliders.x:SetValue(18);p.sliders.y:SetValue(21);p.separation:SetValue(778)
assert(rendered.pair.size==130 and rendered.pair.x==18 and rendered.pair.y==21 and rendered.pair.separation==778)
p.flip:Click();p.swap:Click();assert(rendered.left.art=='sanctum')
p.save:Click();assert(not p.save.enabled and EndCapperDB.pair.size==130)
local key=E.activePositionLayout
assert(EndCapperDB.positionProfiles[key].pair.separation==778)
C_EditMode.GetLayouts=function() return nil end
choose('wolf');p.sliders.size:SetValue(150)
assert(rendered.left.art=='whiteWorgen' and rendered.right.art=='wolf' and rendered.pair.size==150 and p.save.enabled)
p.link:Click();choose('felwing','right');assert(rendered.right.art=='felwing')
p:Hide();assert(EndCapperDB.pair.art=='seraph' and EndCapperDB.pair.size==130)
C_EditMode.GetLayouts=function() return info end
E.OpenOptions('left');assert(not p.save.enabled and E.draft.pair.size==130);p:Hide()
C_EditMode,Enum,EditModePresetLayoutManager=oldAPI,oldEnum,oldPresets
print('PASS: real profile reconciliation through menu/slider/flip/swap/link/Save/Cancel handlers, native preset index mapping and lookup-failure previews')

EndCapperDB=E.Normalize(nil);E.OpenOptions('left');p.link:Click()
assert(p.separation.value==600 and E.draft.pair.separationInitialized)
p.separation:SetValue(962);p.link:Click();p.save:Click();p:Hide()
E.OpenOptions('left');p.link:Click();assert(p.separation.value==962,'saved unlinked spacing survives relink')
p.separation:SetValue(0);p.link:Click();p.link:Click();assert(p.separation.value==0,'user zero remains zero')
p.resetSide:Click();assert(p.separation.value==600,'Reset pair restores the native default provider')
p:Hide()
print('PASS: real Link/Save/reopen handlers retain separation, deliberate zero and native-default Reset')

EndCapperDB=E.Normalize(nil);E.devMode=true;E.OpenOptions('right');choose('kirinTor','right')
selected('arcaneGlow');assert(p.dev.radios.kirinSeal:IsShown() and not p.dev.seal:IsShown())
p.dev.radios.kirinSeal:Click();selected('kirinSeal')
p.dev.sliders.trailOpacity:SetValue(31);p.dev.behind:Click()
p.dev.radios.arcaneGlow:Click();assert(p.dev.sliders.trailOpacity.value==61)
p.dev.radios.kirinSeal:Click();assert(p.dev.sliders.trailOpacity.value==31)
p.save:Click();p:Hide();E.OpenOptions('right');selected('kirinSeal');assert(p.dev.sliders.trailOpacity.value==31)
p.link:Click();assert(p.pairDropdown.text=='Violetspire / Kirin Tor' and E.draft.left.art=='violetSpire' and E.draft.right.art=='kirinTor')
p.swap:Click();assert(p.pairDropdown.text=='Kirin Tor / Violetspire')
p:Hide()
print('PASS: Kirin Tor menu/paired labels, independent seal/glow controls, no custom rotating-seal slider, Save/reopen and Swap')

EndCapperDB=E.Normalize(nil);E.devMode=true;E.OpenOptions('left')
for _,art in ipairs({'wolf','whiteWorgen'}) do
    local trail=art=='wolf' and 'coldFlame' or 'amberFlow'
    choose(art,'left');selected(trail)
    assert(p.dev.radios.worgenGloom:IsShown() and p.dev.radios[trail].enabled)
    assert(not p.dev.radios[art=='wolf' and 'amberFlow' or 'coldFlame']:IsShown())
    p.dev.sliders.trailX:SetValue(art=='wolf' and -39 or 35)
    p.dev.radios.worgenGloom:Click();selected('worgenGloom')
    p.dev.sliders.trailX:SetValue(art=='wolf' and 14 or -15)
    p.dev.sliders.trailOpacity:SetValue(29)
    p.dev.report:Click();assert(printed:find('Gloom',1,true))
    p.dev.radios[trail]:Click();assert(p.dev.sliders.trailX.value==(art=='wolf' and -39 or 35))
end
p.save:Click();p:Hide();E.OpenOptions('left');choose('wolf','left')
p.dev.radios.worgenGloom:Click();assert(p.dev.sliders.trailX.value==14)
choose('whiteWorgen','left');p.dev.radios.worgenGloom:Click();assert(p.dev.sliders.trailX.value==-15)
p.link:Click();assert(p.pairDropdown.text=='Snowfang / Shadowfang')
p.swap:Click();assert(p.pairDropdown.text=='Shadowfang / Snowfang')
p:Hide();E.devMode=false
print('PASS: Shadowfang/Snowfang real dev radios, independent trail/gloom controls, Print, Save/reopen and linked Swap labels')

EndCapperDB=E.Normalize(nil);E.devMode=true;E.OpenOptions('left')
choose('frostmourneHilt','left');selected('frostGlow')
assert(p.dev.radios.frostMist:IsShown() and not p.dev.radios.frostEnchant:IsShown())
assert(p.dev.radios.coldFlame:IsShown() and p.dev.radios.coldFlame.enabled)
assert(p.dev.height==478 and p.dev.controls.point[5]==-25)
p.dev.sliders.trailOpacity:SetValue(31)
p.dev.radios.frostMist:Click();selected('frostMist');p.dev.sliders.trailX:SetValue(44)
p.dev.report:Click();assert(printed:find('Frosthilt / Icy Mist',1,true))
p.dev.radios.coldFlame:Click();selected('coldFlame')
assert(p.dev.sliders.trailSize.value==50 and p.dev.sliders.trailAngle.value==-162 and p.dev.sliders.trailX.value==-36)
p.dev.sliders.trailSize:SetValue(85);p.dev.sliders.trailAngle:SetValue(-94)
p.dev.sliders.trailX:SetValue(-9);p.dev.sliders.trailY:SetValue(8);p.dev.sliders.trailOpacity:SetValue(0)
p.dev.report:Click();assert(printed:find('Frosthilt / Cold flame',1,true))
p.save:Click();p:Hide();EndCapperDB=E.Normalize(EndCapperDB);E.OpenOptions('left');selected('coldFlame')
assert(p.dev.sliders.trailSize.value==85 and p.dev.sliders.trailAngle.value==-94)
assert(p.dev.sliders.trailX.value==-9 and p.dev.sliders.trailY.value==8 and p.dev.sliders.trailOpacity.value==0)
p.dev.radios.frostGlow:Click();assert(p.dev.sliders.trailOpacity.value==31)
p.dev.radios.frostMist:Click();assert(p.dev.sliders.trailX.value==44)
p.dev.radios.coldFlame:Click();p.dev.reset:Click()
assert(p.dev.sliders.trailSize.value==50 and p.dev.sliders.trailAngle.value==-162 and p.dev.sliders.trailOpacity.value==98)
assert(p.dev.sliders.trailX.value==-36 and p.dev.sliders.trailY.value==17)
assert(E.GetEffectConfig(E.draft.left,'frostGlow').trailOpacity==31 and E.GetEffectConfig(E.draft.left,'frostMist').trailX==44)
choose('frostmourneBlade','right')
assert(not p.dev.radios.coldFlame:IsShown() and p.dev.height==453)
choose('frostmourneHilt','left')
p.link:Click();assert(p.pairDropdown.text=='Frosthilt / Frostblade')
assert(E.draft.left.art=='frostmourneHilt' and E.draft.right.art=='frostmourneBlade')
p.swap:Click();assert(p.pairDropdown.text=='Frostblade / Frosthilt')
p:Hide();E.devMode=false
print('PASS: Frostmourne real dev controls for all three hilt effects, Print, Save/reload, isolated Reset, and linked Swap')

-- Saved drag coordinates use the same controls and exit callback as other edits.
p:Hide()
local previousRegistry=EventRegistry
local callbacks={}
EventRegistry={RegisterCallback=function(_,name,fn) callbacks[name]=fn end}
E.registryHooked=nil;E.AttachOptions()
EndCapperDB=E.Normalize({version=34,left={art="wolf",frameX=300,frameBottom=false}})
E.OpenOptions("left")
assert(not p.save.enabled and not E.draft.left.frameY)
E.draft.left.frameX=420;E.draft.left.frameY=190;E.UpdateSaveButton()
assert(p.save.enabled);p.save:Click()
assert(not p.save.enabled and EndCapperDB.left.frameX==420 and EndCapperDB.left.frameY==190)
E.draft.left.frameY=250;E.UpdateSaveButton();assert(p.save.enabled)
callbacks["EditMode.Exit"]()
assert(not E.draft and EndCapperDB.left.frameY==190 and not p:IsShown())
EventRegistry=previousRegistry
print("PASS: Save commits drag coordinates and leaving Edit Mode cancels the next preview")

E.OpenOptions("left")
assert(p.showLauncher:GetChecked())
p.showLauncher:Click();assert(not E.draft.launcher.shown and p.save.enabled)
p.save:Click();assert(not EndCapperDB.launcher.shown and not p.save.enabled)
p.showLauncher:Click();assert(E.draft.launcher.shown and p.save.enabled)
p:Hide();assert(not EndCapperDB.launcher.shown)
local oldDialog=EditModeSystemSettingsDialog
local oldHook=hooksecurefunc
local dialog=widget()
function dialog:UpdateDialog() end
function dialog:HookScript(name,fn) self:SetScript(name,fn) end
function dialog:Show()
    self.shown=true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
hooksecurefunc=function(object,method,fn)
    local original=object[method]
    object[method]=function(...) original(...);fn(...) end
end
EditModeSystemSettingsDialog=dialog;E.dialogHooked=nil;E.AttachOptions()
E.caps.left.nativeFrame={};E.caps.left.suppress=true
dialog:UpdateDialog(E.caps.left.nativeFrame);dialog:Show()
assert(not dialog:IsShown(),"custom native dialog remains closed even when shown after UpdateDialog")
E.caps.left.suppress=false;dialog:UpdateDialog(E.caps.left.nativeFrame);dialog:Show()
assert(dialog:IsShown() and not p:IsShown(),"Default retains the Blizzard dialog")
E.caps.left.suppress=true;E.DismissNativeCapSettings();assert(not dialog:IsShown())
dialog:UpdateDialog({});dialog:Show();assert(dialog:IsShown(),"other Blizzard settings remain available")
EditModeSystemSettingsDialog=oldDialog;hooksecurefunc=oldHook
print("PASS: launcher checkbox Save/Cancel and side-specific Blizzard settings suppression")

EndCapperDB=E.Normalize({left={art="wolf"},right={art="whiteWorgen"}})
local highlightedSide
E.UpdateCapSelection=function(side) highlightedSide=side end
E.OpenOptions("left");applied={}
assert(highlightedSide=="left" and not p.left.enabled and p.right.enabled)
E.SelectCapSide("right")
assert(highlightedSide=="right" and p.left.enabled and not p.right.enabled and p.heading.text=="Right end cap")
assert(#applied==0 and not p.save.enabled,"focusing a cap leaves the draft clean")
p.left:Click();assert(highlightedSide=="left")
p.link:Click();assert(not p.left.enabled and not p.right.enabled)
E.SelectCapSide("right")
assert(highlightedSide=="right" and p.heading.text=="Linked end caps")
assert(p.dev.heading.text:find("right",1,true))
p:Hide()
print("PASS: frame focus and panel side selectors stay in sync, including linked developer controls")

EndCapperDB=E.Normalize({left={art="wolf"},right={art="whiteWorgen"}})
E.OpenOptions("left")
assert(not p.snapCenter:IsShown() and not p.separation.control:IsShown())
local function checkChevrons(slider,read)
    local low,high=slider:GetMinMaxValues()
    assert(slider.control.template=="MinimalSliderWithSteppersTemplate")
    slider:SetValue(low+1)
    assert(read()==low+1,"slider updates the setting")
    slider.control.Forward:Click();assert(read()==low+2,"right chevron adds one")
    slider.control.Back:Click();assert(read()==low+1,"left chevron subtracts one")
    slider:SetValue(high);slider.control.Forward:Click();assert(read()==high,"upper bound")
    slider:SetValue(low);slider.control.Back:Click();assert(read()==low,"lower bound")
end
for key,slider in pairs(p.sliders) do checkChevrons(slider,function() return E.draft.left[key] end) end
p.link:Click()
assert(p.snapCenter:IsShown() and p.snapCenter.enabled and p.separation.control:IsShown())
checkChevrons(p.sliders.x,function() return E.draft.pair.x end)
checkChevrons(p.separation,function() return E.draft.pair.separation end)
p.sliders.x:SetValue(300);p.sliders.y:SetValue(17);p.separation:SetValue(713)
p.snapCenter:Click()
assert(E.draft.pair.x==0 and not E.draft.pair.centerX and p.sliders.x.value==0)
assert(p.xCaption.text=="Pair centre X offset" and p.sliders.x.control.rightText=="0" and E.draft.pair.y==17 and E.draft.pair.separation==713)
p.save:Click();assert(EndCapperDB.pair.x==0 and EndCapperDB.pair.separation==713 and not p.save.enabled)
p:Hide()

EndCapperDB=E.Normalize({left={art="violetSpire"},right={art="seraph"}})
E.devMode=true;E.OpenOptions("left")
for key,slider in pairs(p.dev.sliders) do
    checkChevrons(slider,function() return E.GetEffectConfig(E.draft.left)[key] end)
end
checkChevrons(p.dev.seal.slider,function() return E.GetEffectConfig(E.draft.left).sealSize end)
p.right:Click();p.dev.haloTab:Click()
for key,slider in pairs(p.dev.halo.sliders) do
    checkChevrons(slider,function() return E.GetHaloConfig(E.draft.right)[key] end)
end
p:Hide()
print("PASS: Snap to center and one-unit chevrons for every artwork and developer slider")

EndCapperDB=E.Normalize({version=37,left={art="wolf",size=119},right={art="whiteWorgen"}})
E.OpenOptions("left")
assert(p.modeTabs["end"].text=="End Cap" and p.modeTabs.corner.text=="Corner Cap")
assert(p.enableMode:GetChecked() and not p.modeTabs["end"].enabled and not p.save.enabled)
p.modeTabs.corner:Click()
assert(E.draft.mode=="corner" and not p.enableMode:GetChecked() and not p.save.enabled)
p.enableMode:Click();p.sliders.size:SetValue(163);p.link:Click()
assert(not p.separation.control:IsShown() and not p.snapCenter:IsShown() and p.snapBottom.text=="Snap to corners")
p.sliders.x:SetValue(40);p.snapBottom:Click();assert(E.draft.pair.x==0)
p.modeTabs["end"]:Click();assert(E.draft.enabled and E.draft.left.size==119 and not E.draft.pair.linked)
p.save:Click();p:Hide()
E.OpenOptions("left");p.modeTabs.corner:Click()
assert(E.draft.enabled and E.draft.pair.linked and E.draft.pair.size==163 and not p.save.enabled)
p.enableMode:Click();p:Hide()
assert(EndCapperDB.otherMode.enabled,"Cancel keeps the saved Corner Cap toggle")
print("PASS: native tabs, separate Enable toggles, saved mode settings and linked corner controls")

EndCapperDB=E.Normalize({left={art='hexbound'},right={art='soulbound'}})
E.devMode=true;E.OpenOptions('left')
for _,side in ipairs({'left','right'}) do
    E.OpenOptions(side)
    for index,id in ipairs({'felFlame','felMagic','shadowGlow'}) do
        assert(p.dev.radios[id].shown and p.dev.radios[id].enabled)
        p.dev.radios[id]:Click();p.dev.sliders.trailOpacity:SetValue(index*10)
        p.dev.sliders.trailX:SetValue(index*7)
    end
    for index,id in ipairs({'felFlame','felMagic','shadowGlow'}) do
        p.dev.radios[id]:Click()
        assert(p.dev.sliders.trailOpacity.value==index*10 and p.dev.sliders.trailX.value==index*7)
    end
end
p.save:Click();p:Hide()
EndCapperDB=E.Normalize(EndCapperDB)
for _,side in ipairs({'left','right'}) do
    for index,id in ipairs({'felFlame','felMagic','shadowGlow'}) do
        assert(E.GetEffectConfig(EndCapperDB[side],id).trailOpacity==index*10)
    end
end
print('PASS: both warlock sisters expose all three dev radios and preserve independent tuning through Save and reload')

EndCapperDB=E.Normalize({version=40,left={art='cryptgate'},right={art='plaguewell'}})
E.devMode=true;E.OpenOptions('left')
local cryptIDs={'greenGroundFog','eerieGroundFog','candleFlame','amberEyeLeft','amberEyeRight'}
for index,id in ipairs(cryptIDs) do
    assert(p.dev.radios[id].shown and p.dev.radios[id].enabled)
    p.dev.radios[id]:Click()
    p.dev.sliders.trailX:SetValue(index*9)
    p.dev.sliders.trailY:SetValue(-index*5)
    p.dev.sliders.trailSize:SetValue(50+index)
    p.dev.sliders.trailAngle:SetValue(index*15)
    p.dev.sliders.trailOpacity:SetValue(index*7)
end
for index,id in ipairs(cryptIDs) do
    p.dev.radios[id]:Click()
    assert(p.dev.sliders.trailX.value==index*9 and p.dev.sliders.trailOpacity.value==index*7)
end
p.dev.radios.amberEyeLeft:Click();p.dev.behind:Click()
p.save:Click();p:Hide();EndCapperDB=E.Normalize(EndCapperDB)
local savedEye=E.GetEffectConfig(EndCapperDB.left,'amberEyeLeft')
assert(savedEye.effectLayer=='back')
for index,id in ipairs(cryptIDs) do
    local c=E.GetEffectConfig(EndCapperDB.left,id)
    assert(c.trailX==index*9 and c.trailY==-index*5 and c.trailSize==50+index and c.trailAngle==index*15 and c.trailOpacity==index*7)
end
E.OpenOptions('left');p.dev.radios.amberEyeRight:Click();p.dev.reset:Click()
assert(p.dev.sliders.trailX.value==-16 and E.GetEffectConfig(E.draft.left,'amberEyeLeft').trailX==36)
p:Hide();assert(E.GetEffectConfig(EndCapperDB.left,'amberEyeRight').trailX==45)
E.OpenOptions('right')
assert(p.dev.radios.greenGroundFog.shown and p.dev.radios.eerieGroundFog.shown)
assert(not p.dev.radios.candleFlame.shown and not p.dev.radios.amberEyeLeft.shown and not p.dev.radios.amberEyeRight.shown)
assert(p.dev.radios.lampGlow.shown and p.dev.radios.lampGlow.enabled)
p.dev.radios.lampGlow:Click()
assert(p.dev.sliders.trailX.value==11 and p.dev.sliders.trailY.value==11 and p.dev.sliders.trailSize.value==70)
p.dev.sliders.trailOpacity:SetValue(42);p.dev.sliders.trailX:SetValue(13)
p.save:Click();p:Hide();EndCapperDB=E.Normalize(EndCapperDB)
assert(E.GetEffectConfig(EndCapperDB.right,'lampGlow').trailOpacity==42)
assert(E.GetEffectConfig(EndCapperDB.right,'lampGlow').trailX==13)
assert(E.GetEffectConfig(EndCapperDB.right,'greenGroundFog').trailOpacity==30)
E.OpenOptions('right');p.dev.radios.lampGlow:Click();p.dev.reset:Click()
assert(p.dev.sliders.trailOpacity.value==35 and p.dev.sliders.trailX.value==11)
p:Hide();assert(E.GetEffectConfig(EndCapperDB.right,'lampGlow').trailX==13)
E.OpenOptions('left');assert(not p.dev.radios.lampGlow.shown)
p.modeTabs.corner:Click();assert(E.GetEffectConfig(E.draft.left,'amberEyeLeft').trailX==-27)
p:Hide()
print('PASS: Undercity five/three effect controls, independent eyes/lamp glow, Save/reload, isolated Reset/Cancel and mode tuning')

EndCapperDB=E.Normalize({left={art='banshee'},right={art='highGeneral'}})
for _,side in ipairs({'left','right'}) do
    E.OpenOptions(side)
    local ids=E.SylvanasEffects[E.draft[side].art]
    local visible=0
    for _,radio in pairs(p.dev.radios) do if radio.shown then visible=visible+1 end end
    assert(visible==#ids and p.dev.note.text:find(side=='right' and 'All five run' or 'All four run',1,true))
    for i,id in ipairs(ids) do
        assert(p.dev.radios[id].shown and p.dev.radios[id].enabled)
        p.dev.radios[id]:Click()
        p.dev.sliders.trailX:SetValue(i*8)
        p.dev.sliders.trailOpacity:SetValue(i*12)
    end
    p.save:Click();p:Hide();EndCapperDB=E.Normalize(EndCapperDB)
    for i,id in ipairs(ids) do
        local c=E.GetEffectConfig(EndCapperDB[side],id)
        assert(c.trailX==i*8 and c.trailOpacity==i*12)
    end
    E.OpenOptions(side);p.dev.radios[ids[2]]:Click();p.dev.reset:Click()
    assert(E.GetEffectConfig(E.draft[side],ids[3]).trailX==24)
    p:Hide();assert(E.GetEffectConfig(EndCapperDB[side],ids[2]).trailX==16)
end
print('PASS: Sylvanas four/five dev radios, separate eye sliders, Save/reload and isolated Reset/Cancel')
