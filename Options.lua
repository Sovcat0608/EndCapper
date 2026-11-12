local _, E = ...
local side = "left"
local refreshing = false
local nativeDialogTarget
local priestEdit = "effects" -- Session-only choice; never part of saved calibration.
local function label(parent, text, x, y, font)
    local l = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    l:SetPoint("TOPLEFT", x, y); l:SetText(text)
    return l
end
local function button(parent, text, x, y, width, callback, anchor)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24); b:SetPoint(anchor or "TOPLEFT", x, y); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function nativeSlider(parent,x,y,width,low,high,title)
    local control=CreateFrame("Frame",nil,parent,"MinimalSliderWithSteppersTemplate")
    control:SetPoint("TOPLEFT",x,y);control:SetSize(width-48,20)
    local suffix=title:find("(%)",1,true) and "%" or ""
    control:Init(low,low,high,high-low,{
        [MinimalSliderWithSteppersMixin.Label.Right]=function(value) return string.format("%g",value)..suffix end,
    })
    local slider=control.Slider
    slider.control=control
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel",function(self,delta)
        if refreshing or not E.draft or InCombatLockdown() or not control:IsSliderEnabled() then return end
        self:SetValue(self:GetValue()+delta)
    end)
    return slider
end

local function enableSlider(slider,enabled)
    slider.control:SetEnabled(enabled)
    slider:EnableMouseWheel(enabled)
end

local function pairOffset(db)
    if db.mode=="corner" then return db.pair.x end
    return E.GetPairOffset and E.GetPairOffset(db) or db.pair.x
end

local function pairLabel(art,swapped)
    if art=="default" or art=="hidden" then return E.artworkByID[art].name end
    local row=E.PairByArt[art]
    local left,right=row[1],row[2] or row[1]
    if swapped then left,right=right,left end
    return E.artworkByID[left].name.." / "..E.artworkByID[right].name
end
function E.UpdateSaveButton()
    if E.panel and E.panel.save then E.panel.save:SetEnabled(not InCombatLockdown() and E.HasChanges()) end
end
local function preview(targetSide,bothModes)
    local mode=not bothModes and E.draft and E.draft.mode or nil
    E.Apply(targetSide,mode);E.UpdateSaveButton()
end
function E.RefreshOptions()
    if not E.panel or not E.draft then return end
    refreshing = true
    local p, c = E.panel, E.draft[side]
    local shared=E.draft.pair
    local linked=shared.linked
    local corner=E.draft.mode=="corner"
    local showSpacing=linked and not corner
    for mode,tab in pairs(p.modeTabs) do
        if mode==E.draft.mode then PanelTemplates_SelectTab(tab)
        else PanelTemplates_DeselectTab(tab) end
    end
    p.enableMode:SetChecked(E.draft.enabled)
    p.showLauncher:SetChecked(E.draft.launcher.shown)
    local hasBartenderArt=E.HasBartenderArtBar and E.HasBartenderArtBar() or false
    p.hideBartenderArt:SetShown(hasBartenderArt)
    p.hideBartenderArt:SetChecked(E.draft.hideBartenderArt)
    p:SetHeight(hasBartenderArt and 640 or 614)
    if p.SetScale and UIParent.GetHeight then
        p:SetScale(math.min(1,math.max(0.5,(UIParent:GetHeight()-40)/p:GetHeight())))
    end
    p.link:SetChecked(linked);p.swap:SetShown(linked);p.swap:SetChecked(shared.swapped)
    p.resetSide:SetText(linked and "Reset pair" or "Reset side")
    local movable=E.artworkByID[c.art].path~=nil
    if c.art=="default" then
        p.positionNote:SetText("Move Default caps in Blizzard Edit Mode.")
    elseif movable then
        p.positionNote:SetText(linked and "Drag either outline to move the pair." or "Drag an outline to move a custom cap.")
    else
        p.positionNote:SetText("Select artwork to move this cap.")
    end
    p.flip:SetEnabled(movable);p.swap:SetEnabled(movable);p.snapBottom:SetEnabled(movable)
    p.snapBottom:SetText(corner and (linked and "Snap to corners" or "Snap to corner") or "Snap to bottom")
    p.snapBottom:SetSize(showSpacing and 142 or 292,24)
    p.snapCenter:SetShown(showSpacing);p.snapCenter:SetEnabled(movable)
    enableSlider(p.separation,movable)
    for _,slider in pairs(p.sliders) do enableSlider(slider,movable) end
    p.separation.control:SetShown(showSpacing);p.separationCaption:SetShown(showSpacing)
    p.separation:SetValue(shared.separation)
    local priest=E.PriestArtworks[c.art]~=nil
    local priestEffects=E.PriestEffectPairs[c.art]~=nil
    local halo=E.GetHaloConfig(c)
    local haloTabs=priestEffects and halo~=nil
    local nativeVisible=not haloTabs or priestEdit=="effects"
    local capName=corner and "corner cap" or "end cap"
    local sideName=side=="left" and "Left " or "Right "
    p.heading:SetText(linked and ("Linked "..capName.."s") or sideName..capName)
    p.flip:SetChecked(linked and shared.flip or E.FlipChecked(c,side))
    p.dev:SetShown(E.devMode == true)
    local moonlight=E.EffectProfiles[c.art] and E.EffectProfiles[c.art].moonlight
    local totem=c.art=="stormhornTotem"
    local fel=c.art=="felwing"
    local molten=E.MoltenArtworks[c.art]~=nil
    local frost=E.FrostArtworks[c.art]~=nil or c.art=="moonwell"
    p.dev.heading:SetText("Developer: " .. side .. ((moonlight or totem or fel or molten or frost or c.art=="violetSpire") and " effects" or " trail"))
    local editable=E.devArtworks[c.art]==true
    p.dev.note:SetText(totem and "Both run together. Select an effect to edit."
        or (fel and "All three run. Select a native effect to edit."
        or (moonlight and (E.artworkByID[c.art].name .. ": native effect colours.")
        or (editable and "Spectral trail only. Eye glow stays fixed." or "Select custom art to tune. Skull is finalised."))))
    local effect=E.GetEffectConfig(c)
    if E.UndeadArtworks[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText("Both run. Select one to edit; opacity 0 hides it.")
    end
    if molten then p.dev.note:SetText("Both run. Tune native effects; cracks stay fixed.") end
    if frost then p.dev.note:SetText("Both run. Tune effects; emission stays fixed.") end
    if E.FrostmourneArtworks[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText(c.art=="frostmourneHilt" and "All three run. Select one to edit." or "Both run. Select one to edit.")
    end
    if c.art=="violetSpire" then p.dev.note:SetText("Native glow only above. Seal size below.") end
    if c.art=="kirinTor" then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText("Seal + glow run together. Select one to edit.")
    end
    if E.WarlockArtworks[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText("All three run. Select one to edit; opacity 0 hides it.")
    end
    if E.UndercityEffects[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText(c.art=="cryptgate" and "All five run. Each eye trail is independent."
            or "Both fogs + lamp glow run. Select one to edit.")
    end
    if E.SylvanasEffects[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText(c.art=="highGeneral" and "All five run. Each eye trail is independent."
            or "All four run. Each eye trail is independent.")
    end
    if E.ZephrasEffects[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText("Both winds + blue mist run. Opacity 0 hides one.")
    end
    if E.WorgenArtworks[c.art] then
        p.dev.heading:SetText("Developer: "..side.." effects")
        p.dev.note:SetText("Trail + gloom run together. Select one to edit.")
    end
    if priest then
        p.dev.heading:SetText("Developer: "..side.." "..(haloTabs and priestEdit or "effects"))
        p.dev.note:SetText(haloTabs and "Both effects + halo run. Select what to edit." or "Both run together. Select an effect to edit.")
    end
    p.dev.haloTab:SetShown(haloTabs and E.devMode==true)
    p.dev.effectsTab:SetShown(haloTabs and E.devMode==true)
    p.dev.haloTab:SetEnabled(priestEdit~="halo");p.dev.effectsTab:SetEnabled(priestEdit~="effects")
    p.dev.native:ClearAllPoints();p.dev.native:SetPoint("TOPLEFT",p.dev,"TOPLEFT",0,haloTabs and -34 or 0)
    p.dev.halo:SetShown(halo~=nil and priestEdit=="halo" and E.devMode==true)
    if halo then
        for key,slider in pairs(p.dev.halo.sliders) do slider:SetValue(halo[key]) end
        p.dev.halo.reverse:SetChecked(halo.reverse)
    end
    p.dev.controls:SetShown(nativeVisible)
    local sealVisible=c.art=="violetSpire" and E.devMode==true
    p.dev.seal:SetShown(sealVisible)
    p.dev.seal.slider:SetValue(effect.sealSize or E.ArcaneSealSize)
    p.dev.behind:SetChecked(effect.effectLayer=="back")
    p.dev.behind:SetEnabled(E.devMode == true and E.EffectProfiles[c.art]~=nil)
    local radioRow=0
    for _, choice in ipairs(E.effectChoices) do
        local radio=p.dev.radios[choice.id]
        local available=nativeVisible and (E.CanSelectEffect(c.art,choice.id) or (E.EffectProfiles[c.art] and E.EffectProfiles[c.art].nativeEffect==choice.id))
        radio:SetShown(available and true or false)
        radio:SetChecked(effect.nativeEffect==choice.id)
        radio:SetEnabled(E.CanSelectEffect(c.art,choice.id))
        if available then
            radio:ClearAllPoints(); radio:SetPoint("TOPLEFT",18,-61-radioRow*25)
            radioRow=radioRow+1
        end
    end
    local extraRows = math.max(0,radioRow-2)*25
    p.dev.controls:ClearAllPoints()
    p.dev.controls:SetPoint("TOPLEFT",p.dev.native,"TOPLEFT",0,-extraRows)
    p.dev:SetSize(330,(sealVisible and 510 or (haloTabs and 487 or 453))+extraRows)
    for key, slider in pairs(p.dev.sliders) do
        slider:SetValue(effect[key]);enableSlider(slider,editable)
    end
    p.dev.reset:SetEnabled(editable); p.dev.report:SetEnabled(editable)
    local x=linked and pairOffset(E.draft) or c.x
    local limit=linked and math.min(10000,math.ceil(math.max(UIParent:GetWidth()/2,math.abs(x)))) or 200
    p.sliders.x:SetMinMaxValues(-limit,limit)
    p.sliders.x:SetValue(x)
    p.sliders.x.control:UpdateStepperStates()
    p.xCaption:SetText(linked and (corner and "Corner inset X" or "Pair centre X offset") or "Artwork X from frame centre")
    p.sliders.size:SetValue(linked and shared.size or c.size)
    p.sliders.y:SetValue(linked and shared.y or c.y)
    for _,column in ipairs({'left','right'}) do
        p.artDropdowns[column]:SetShown(not linked)
        p.artDropdownLabels[column]:SetShown(not linked)
        if not linked then p.artDropdowns[column]:GenerateMenu() end
    end
    p.pairDropdown:SetShown(linked);p.pairDropdownLabel:SetShown(linked)
    if linked then p.pairDropdown:GenerateMenu() end
    p.left:SetEnabled(not linked and side ~= "left"); p.right:SetEnabled(not linked and side ~= "right")
    if E.UpdateCapSelection then E.UpdateCapSelection(side) end
    refreshing = false
    E.UpdateSaveButton()
end
function E.SelectCapSide(selectedSide)
    if not E.draft or InCombatLockdown() or side==selectedSide then return end
    side=selectedSide
    E.RefreshOptions()
end

local function makePanel()
    local p = CreateFrame("Frame", "EndCapperOptions", UIParent, "BackdropTemplate")
    E.panel = p
    p:Hide(); p:SetSize(340,614); p:SetPoint("CENTER"); p:SetFrameStrata("DIALOG")
    p:SetClampedToScreen(true); p:EnableMouse(true); p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    label(p, "EndCapper", 20, -20, "GameFontNormalLarge")
    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() p:Hide() end)
    p.modeTabs={}
    local previous
    for _,mode in ipairs({"end","corner"}) do
        local tab=CreateFrame("Button",nil,p,"PanelTopTabButtonTemplate")
        tab:SetText(mode=="end" and "End Cap" or "Corner Cap")
        if previous then tab:SetPoint("LEFT",previous,"RIGHT",6,0)
        else tab:SetPoint("TOPLEFT",20,-46) end
        tab:SetScript("OnClick",function()
            if not E.draft or InCombatLockdown() then return end
            E.SelectMode(E.draft,mode)
            if E.UpdateDragHandles then E.UpdateDragHandles() end
            E.RefreshOptions()
        end)
        p.modeTabs[mode]=tab;previous=tab
    end
    p.enableMode=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    p.enableMode:SetPoint("TOPLEFT",15,-90);label(p,"Enable",47,-99)
    p.enableMode:SetScript("OnClick",function(self)
        if not E.draft or InCombatLockdown() then return end
        E.draft.enabled=self:GetChecked() and true or false
        preview()
    end)
    local controls=CreateFrame("Frame",nil,p,"BackdropTemplate")
    p.controls=controls;controls:SetPoint("TOPLEFT",12,-198);controls:SetSize(316,324)
    controls:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    controls:SetBackdropColor(0,0,0,0.15)
    controls:SetBackdropBorderColor(0.6,0.6,0.6,0.25)
    p.left = button(controls,"Left cap",12,-12,140,function() E.SelectCapSide("left") end)
    p.right = button(controls,"Right cap",164,-12,140,function() E.SelectCapSide("right") end)
    p.heading = label(controls,"",12,-46)
    p.link=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    p.link:SetPoint("TOPLEFT",98,-90);label(p,"Link pairs",130,-99)
    p.link:SetScript("OnClick",function(self)
        E.LinkPair(E.draft,side,self:GetChecked());preview();E.RefreshOptions()
    end)
    p.showLauncher=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    p.showLauncher:SetPoint("TOPLEFT",195,-90);label(p,"Show Ecap button",227,-99)
    p.showLauncher:SetScript("OnClick",function(self)
        E.draft.launcher.shown=self:GetChecked() and true or false
        preview()
    end)
    p.swap=CreateFrame("CheckButton",nil,controls,"UICheckButtonTemplate")
    p.swap:SetPoint("TOPLEFT",161,-64);label(p.swap,"Swap",33,-9)
    p.swap:SetScript("OnClick",function(self)
        E.draft.pair.swapped=self:GetChecked() and true or false
        E.SyncPair(E.draft);preview();E.RefreshOptions()
    end)
    local artPage = controls
    p.artDropdownLabels={left=label(p,"Left artwork",20,-130),right=label(p,"Right artwork",176,-130)}
    p.artDropdowns={}
    for index,column in ipairs({'left','right'}) do
        local dropdown=CreateFrame('DropdownButton',nil,p,'WowStyle1DropdownTemplate')
        dropdown:SetPoint('TOPLEFT',20+(index-1)*156,-152);dropdown:SetSize(144,32)
        dropdown:SetDefaultText('Select artwork')
        dropdown:SetupMenu(function(_,root)
            if not E.draft then return end
            root:SetScrollMode(280)
            -- Put the customary sister for this column first, but allow any
            -- artwork on either side in independent mode and for swapped pairs.
            for _,row in ipairs(E.ArtworkPairs) do
                local first=column=='right' and row[2] or row[1]
                first=first or row[1]
                local second
                if row[2] then second=first==row[1] and row[2] or row[1] end
                for _,id in ipairs(second and {first,second} or {first}) do
                    if id~="default" or E.draft.mode=="end" then
                        root:CreateRadio(E.artworkByID[id].name,function(value)
                            return E.draft and E.draft[column].art==value
                        end,function(value)
                            if not E.draft or E.draft.pair.linked or InCombatLockdown() then return end
                            side=column;E.SelectArtwork(E.draft[column],value,column);preview(column)
                            E.RefreshOptions()
                        end,id)
                    end
                end
            end
        end)
        p.artDropdowns[column]=dropdown
    end
    p.pairDropdownLabel=label(p,"Linked artwork",20,-130)
    local pairDropdown=CreateFrame('DropdownButton',nil,p,'WowStyle1DropdownTemplate');p.pairDropdown=pairDropdown
    pairDropdown:SetPoint('TOPLEFT',20,-152);pairDropdown:SetSize(300,32);pairDropdown:SetDefaultText('Select pair')
    pairDropdown:SetupMenu(function(_,root)
        if not E.draft then return end
        root:SetScrollMode(280)
        local function add(art)
            root:CreateRadio(pairLabel(art,E.draft.pair.swapped),function(value)
                return E.draft and E.draft.pair.art==value
            end,function(value)
                if not E.draft or not E.draft.pair.linked or InCombatLockdown() then return end
                E.SelectPair(E.draft,value);preview();E.RefreshOptions()
            end,art)
        end
        for _,row in ipairs(E.ArtworkPairs) do
            if row[1]=="default" then
                if E.draft.mode=="end" then add("default") end
                add("hidden")
            else add(row[1]) end
        end
    end)
    p.flip = CreateFrame("CheckButton", nil, artPage, "UICheckButtonTemplate")
    p.flip:SetPoint("TOPLEFT",5,-64)
    label(artPage,"Flip horizontally",38,-73)
    p.flip:SetScript("OnClick", function(self)
        if E.draft.pair.linked then
            E.draft.pair.flip=self:GetChecked() and true or false;E.SyncPair(E.draft);preview()
        else E.draft[side].flip = (self:GetChecked() and true or false) ~= E.DefaultMirror(E.draft[side].art,side); preview(side) end
    end)
    p.sliders = {}
    local function setPairX(value)
        if not E.draft or not E.draft.pair.linked or InCombatLockdown() then return end
        E.SetPairOffset(E.draft,value);preview();E.RefreshOptions()
    end
    local specs = {{"size", "Size (%)", 50, 200, artPage, -110},
        {"x", "Artwork X from frame centre", -200, 200, artPage, -153},
        {"y", "Artwork Y above bottom", -200, 200, artPage, -196}}
    for _, spec in ipairs(specs) do
        local key, title, low, high, parent, y = unpack(spec)
        local caption = label(parent,title,12,y)
        if key=="x" then p.xCaption=caption end
        local slider=nativeSlider(parent,12,y-19,290,low,high,title)
        slider:HookScript("OnValueChanged", function(_, value)
            if not refreshing and E.draft then
                if E.draft.pair.linked then
                    if key=="x" then setPairX(value)
                    else E.draft.pair[key]=math.floor(value+0.5);E.SyncPair(E.draft);preview();E.RefreshOptions() end
                else E.draft[side][key]=math.floor(value+0.5);preview(side) end
            end
        end)
        p.sliders[key] = slider
    end
    p.separationCaption=label(controls,"Separation distance",12,-239)
    local separation=nativeSlider(controls,12,-258,290,0,2000,"Separation distance");p.separation=separation
    separation:HookScript("OnValueChanged",function(_,value)
        if not refreshing and E.draft and E.draft.mode=="end" and E.draft.pair.linked then
            E.draft.pair.separation=math.floor(value+0.5);E.draft.pair.separationInitialized=true;E.SyncPair(E.draft);preview();E.RefreshOptions()
        end
    end)
    local function snapActiveMode()
        if E.draft.mode=="corner" then E.SnapToCorner(E.draft,side) else E.SnapToBottom(E.draft,side) end
    end
    p.snapBottom=button(controls,"Snap to bottom",12,-287,292,function()
        snapActiveMode()
        if E.draft.pair.linked then preview() else preview(side) end;E.RefreshOptions()
    end)
    p.snapCenter=button(controls,"Snap to center",162,-287,142,function() setPairX(0) end)
    label(p,"Save changes in both tabs.",20,-532,"GameFontHighlightSmall")
    p.positionNote=label(p,"Offsets move artwork. Drag the box to move the cap.",20,-549,"GameFontHighlightSmall")
    p.hideBartenderArt=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate")
    p.hideBartenderArt:SetPoint("TOPLEFT",15,-563)
    label(p.hideBartenderArt,"Hide Bartender Art Bar",33,-9)
    p.hideBartenderArt:Hide()
    p.hideBartenderArt:SetScript("OnClick",function(self)
        if not E.draft or InCombatLockdown() then return end
        E.draft.hideBartenderArt=self:GetChecked() and true or false
        preview()
    end)
    p.resetSide=button(p,"Reset side",20,15,96,function()
        if E.draft.pair.linked then
            local pair=E.draft.pair;pair.size=100;pair.y=0;pair.flip=false;pair.swapped=false
            E.SetPairOffset(E.draft,0)
            E.SyncPair(E.draft)
            if E.draft.mode=="end" then E.ResetPairSeparation(E.draft) end
        else E.draft[side] = E.NormalizeSide(nil, side) end
        snapActiveMode()
        if E.draft.pair.linked then preview() else preview(side) end
        E.RefreshOptions()
    end,"BOTTOMLEFT")
    button(p,"Cancel",122,15,92,function() p:Hide() end,"BOTTOMLEFT")
    p.save=button(p,"Save",220,15,100,function()
        if InCombatLockdown() or not E.HasChanges() then return end
        E.Commit(); E.Begin(); preview(nil,true); E.RefreshOptions()
    end,"BOTTOMLEFT")
    local dev=CreateFrame("Frame", nil, p, "BackdropTemplate")
    p.dev=dev; dev:Hide(); dev:SetSize(330, 453)
    dev:SetPoint("TOPLEFT", p, "TOPRIGHT", 6, 0); dev:SetClampedToScreen(true); dev:EnableMouse(true)
    dev:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,
        insets={left=5,right=5,top=5,bottom=5}})
    dev.heading=label(dev,"",18,-18,"GameFontNormalLarge")
    dev.note=label(dev,"",18,-43,"GameFontHighlightSmall")
    dev.effectsTab=button(dev,"Effects",18,-64,140,function()
        priestEdit="effects";E.RefreshOptions()
    end)
    dev.haloTab=button(dev,"Halo",170,-64,140,function()
        priestEdit="halo";E.RefreshOptions()
    end)
    local native=CreateFrame("Frame",nil,dev);dev.native=native
    native:SetSize(330,453);native:SetPoint("TOPLEFT",dev,"TOPLEFT",0,0)
    dev.radios={}
    for _, choice in ipairs(E.effectChoices) do
        local radio=CreateFrame("CheckButton",nil,native)
        radio:SetSize(290,22)
        -- Client radio-button sheet: unchecked/checked/highlight, 16px cells.
        local function radioTexture(startU, endU)
            local texture=radio:CreateTexture(nil,"ARTWORK")
            texture:SetTexture("Interface\\Buttons\\UI-RadioButton")
            texture:SetTexCoord(startU,endU,0,1); texture:SetSize(16,16)
            texture:SetPoint("LEFT",radio,"LEFT",0,0)
            return texture
        end
        radio:SetNormalTexture(radioTexture(0,0.25))
        radio:SetCheckedTexture(radioTexture(0.25,0.5))
        radio:SetHighlightTexture(radioTexture(0.5,0.75),"ADD")
        label(radio,choice.name,22,-4,"GameFontHighlightSmall")
        radio:SetScript("OnClick",function()
            if not E.draft then return end
            E.SelectEffect(E.draft[side],choice.id); preview(side); E.RefreshOptions()
        end)
        dev.radios[choice.id]=radio
    end
    local controls=CreateFrame("Frame",nil,native);dev.controls=controls
    controls:SetSize(330,453);controls:SetPoint("TOPLEFT",native,"TOPLEFT",0,0)
    dev.sliders={}
    for i,spec in ipairs(E.devEffectFields) do
        local key,title,low,high=unpack(spec)
        local y=-128-(i-1)*43
        label(controls,title,20,y)
        local slider=nativeSlider(controls,22,y-19,285,low,high,title)
        slider:HookScript("OnValueChanged",function(_,value)
            value=math.floor(value+0.5)
            if not refreshing and E.draft then E.SetDevEffect(E.draft[side],key,value); preview(side) end
        end)
        dev.sliders[key]=slider
    end
    dev.behind=CreateFrame("CheckButton",nil,controls,"UICheckButtonTemplate")
    dev.behind:SetPoint("TOPLEFT",17,-345)
    label(controls,"Effects behind artwork",50,-354)
    dev.behind:SetScript("OnClick",function(self)
        if not E.devMode or not E.draft then return end
        E.SetEffectLayer(E.draft[side],self:GetChecked() and "back" or "front")
        preview(side); E.RefreshOptions()
    end)
    dev.reset=button(controls,"Reset effect",18,-383,140,function()
        local c=E.draft[side]
        if not E.devMode or not E.devArtworks[c.art] then return end
        E.ResetDevEffect(c); preview(side); E.RefreshOptions()
    end)
    dev.report=button(controls,"Print values",170,-383,140,function()
        local c=E.draft[side]; local v=E.GetEffectConfig(c)
        local seal=c.art=="violetSpire" and string.format(", seal=%d%%",v.sealSize) or ""
        E.Message(string.format("%s / %s (%s, flip=%s, mirrored=%s): size=%d, angle=%d, origin=%d / %d, opacity=%d%%, layer=%s%s. Click Save to keep changes.",
            E.artworkByID[c.art].name,E.NativeEffectProfiles[v.nativeEffect].name,side,tostring(E.FlipChecked(c,side)),tostring(E.RenderFlip(c,E.draft.mode)),v.trailSize,v.trailAngle,v.trailX,v.trailY,v.trailOpacity,v.effectLayer,seal))
    end)
    label(controls,"Save keeps tuning; Cancel discards preview.",18,-419,"GameFontHighlightSmall")
    local halo=CreateFrame("Frame",nil,dev);dev.halo=halo;halo:Hide()
    halo:SetPoint("TOPLEFT",dev,"TOPLEFT",18,-104);halo:SetSize(295,360);halo.sliders={}
    for i,spec in ipairs(E.HaloFields) do
        local key,title,low,high=unpack(spec)
        label(halo,title,2,-(i-1)*48)
        local s=nativeSlider(halo,4,-19-(i-1)*48,285,low,high,title)
        s:HookScript("OnValueChanged",function(_,value)
            value=math.floor(value+0.5)
            if not refreshing and E.draft then E.SetHalo(E.draft[side],key,value);preview(side) end
        end)
        halo.sliders[key]=s
    end
    halo.reverse=CreateFrame("CheckButton",nil,halo,"UICheckButtonTemplate")
    halo.reverse:SetPoint("TOPLEFT",0,-238);label(halo,"Reverse rotation",32,-247)
    halo.reverse:SetScript("OnClick",function(self)
        if not E.draft then return end
        E.SetHalo(E.draft[side],"reverse",self:GetChecked() and true or false);preview(side)
    end)
    halo.reset=button(halo,"Reset halo",0,-285,140,function()
        if not E.draft then return end
        E.ResetHalo(E.draft[side]);preview(side);E.RefreshOptions()
    end)
    halo.report=button(halo,"Print values",152,-285,140,function()
        if not E.draft then return end
        local c=E.draft[side];local v=E.GetHaloConfig(c);if not v then return end
        E.Message(string.format("%s / Halo (%s, flip=%s, mirrored=%s): size=%d%%, origin=%d / %d, opacity=%d%%, revolution=%ds, reverse=%s, layer=back. Click Save to keep changes.",
            E.artworkByID[c.art].name,side,tostring(E.FlipChecked(c,side)),tostring(E.RenderFlip(c,E.draft.mode)),v.size,v.x,v.y,v.opacity,v.period,tostring(v.reverse)))
    end)
    label(halo,"Save keeps tuning; Cancel discards preview.",0,-325,"GameFontHighlightSmall")
    local seal=CreateFrame("Frame",nil,dev); dev.seal=seal
    seal:SetSize(300,46); seal:SetPoint("TOPLEFT",20,-448); seal:Hide()
    label(seal,"Seal size (%)",0,0)
    local slider=nativeSlider(seal,2,-19,285,25,250,"Seal size (%)");seal.slider=slider
    slider:HookScript("OnValueChanged",function(_,value)
        value=math.floor(value+0.5)
        if not refreshing and E.draft then E.SetSealSize(E.draft[side],value); preview(side) end
    end)
    p:SetScript("OnHide", function()
        for _,dropdown in pairs(p.artDropdowns) do dropdown:CloseMenu() end
        p.pairDropdown:CloseMenu()
        E.Cancel()
        if E.UpdateDragHandles then E.UpdateDragHandles() end
        preview()
    end)
    table.insert(UISpecialFrames, "EndCapperOptions")
end

function E.OpenOptions(selectedSide)
    if not E.ready then return end
    if InCombatLockdown() then E.Message("Artwork editing is available after combat."); return end
    if not E.caps.left or not E.caps.right then
        E.Message("Forever's native end caps were not found. Use the default mouse/keyboard action bar.")
        return
    end
    -- Resolve the initial placement before starting the editable draft.
    if E.ReconcilePositionLayout then E.ReconcilePositionLayout() end
    if not E.panel then makePanel() end
    if selectedSide then side = selectedSide end
    E.Begin()
    if not E.panel:IsShown() then
        E.panel:ClearAllPoints()
        E.panel:SetPoint("CENTER")
    end
    E.panel:Show()
    if E.UpdateDragHandles then E.UpdateDragHandles() end
    E.RefreshOptions()
end

function E.DismissNativeCapSettings()
    if not nativeDialogTarget or InCombatLockdown() then return end
    local dialog=EditModeSystemSettingsDialog
    if not dialog or not dialog:IsShown() then return end
    for _,cap in pairs(E.caps) do
        if nativeDialogTarget==cap.nativeFrame and cap.suppress then
            dialog:Hide()
            return
        end
    end
end

function E.AttachOptions()
    local dialog=EditModeSystemSettingsDialog
    if dialog and dialog.UpdateDialog and not E.dialogHooked then
        E.dialogHooked=true
        hooksecurefunc(dialog,"UpdateDialog",function(_,systemFrame)
            nativeDialogTarget=systemFrame
            E.DismissNativeCapSettings()
        end)
        dialog:HookScript("OnShow",E.DismissNativeCapSettings)
    end
    if EventRegistry and not E.registryHooked then
        E.registryHooked = true
        EventRegistry:RegisterCallback("EditMode.Exit", function()
            if E.panel then E.panel:Hide() end
        end, E)
    end
end
