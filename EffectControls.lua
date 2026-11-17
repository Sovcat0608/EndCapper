local _,E=...
function E.GetLibraryRows(config)
    local result={}
    for _,choice in ipairs(E.effectChoices) do
        local profile=E.EffectProfiles[config.art]
        if profile and (profile.nativeEffect==choice.id or E.CanSelectEffect(config.art,choice.id)) then
            local row=E.GetEffectConfig(config,choice.id)
            row.builtin=choice.id;row.name=choice.name
            row.fileID=E.NativeEffectProfiles and E.NativeEffectProfiles[choice.id] and E.NativeEffectProfiles[choice.id].fileID or 0
            result[#result+1]=row
        end
    end
    local count=#result
    for index,row in ipairs(E.GetAddedEffects(config)) do
        local copy={};for k,v in pairs(row) do copy[k]=v end
        copy.addedIndex=index;result[#result+1]=copy
    end
    return result,count
end
local function write(config,row,key,value)
    if row.builtin then
        E.SelectEffect(config,row.builtin)
        if key=="effectLayer" then E.SetEffectLayer(config,value) else E.SetDevEffect(config,key,value) end
    else E.EditAddedEffects(config)[row.addedIndex][key]=value end
end
function E.CreateLibraryControls(panel,button,label,title,gold,muted)
    local state={selected=1,sliders={}}
    panel.layerControls=state
    local outer=panel
    local host=CreateFrame("Frame",nil,outer);host:SetAllPoints();state.host=host;panel=host
    local placement=CreateFrame("Frame",nil,panel);placement:SetAllPoints();state.placement=placement
    local heading=label(panel,"GameFontNormal",gold);heading:SetPoint("TOPLEFT",845,-55);heading:SetText("Layer controls")
    local caption=label(panel,"GameFontHighlightSmall",muted);caption:SetPoint("TOPLEFT",875,-84);caption:SetWidth(220);caption:SetMaxLines(2)
    local previous=button(panel,"<",24);previous:SetPoint("TOPLEFT",845,-80)
    local next=button(panel,">",24);next:SetPoint("TOPLEFT",1110,-80)
    local remove=button(panel,"Remove layer",130);remove:SetPoint("TOPLEFT",845,-565);state.remove=remove
    local left=button(outer,"Left sister",95);left:SetPoint("TOPLEFT",570,-11)
    local right=button(outer,"Right sister",95);right:SetPoint("TOPLEFT",670,-11)
    left:SetScript("OnClick",function()E.SelectCapSide("left")end)
    right:SetScript("OnClick",function()E.SelectCapSide("right")end)
    local behind=CreateFrame("CheckButton",nil,placement,"UICheckButtonTemplate");behind:SetPoint("TOPLEFT",845,-405);state.behind=behind
    local behindText=label(placement,"GameFontHighlightSmall",muted);behindText:SetPoint("LEFT",behind,"RIGHT",0,0);behindText:SetText("Behind art")
    local function artworkRow(c,rows)
        if not state.artSelection or not E.GetLayerStack then return end
        for _,row in ipairs(E.GetLayerStack(c,rows)) do
            if row.id==state.artSelection then return row end
        end
    end
    local function target()
        if InCombatLockdown() then return end
        local c=E.GetEffectLibraryTarget();if not c then return end
        if state.artSelection then return nil,c,artworkRow(c) end
        return E.GetLibraryRows(c)[state.selected],c
    end
    local artworkLabels={trailSize="Layer size (%)",trailAngle="Layer angle (degrees)",
        trailX="Layer X offset",trailY="Layer Y offset",trailOpacity="Layer opacity (%)"}
    for i,spec in ipairs(E.devEffectFields) do
        local key,text,low,high=unpack(spec);local y=-168-(i-1)*49
        local name=label(placement,"GameFontHighlightSmall",muted);name:SetPoint("TOPLEFT",845,y);name:SetText(text)
        local control=CreateFrame("Frame",nil,placement,"MinimalSliderWithSteppersTemplate")
        control:SetPoint("TOPLEFT",847,y-21);control:SetSize(238,20)
        control:Init(low,low,high,high-low,{[MinimalSliderWithSteppersMixin.Label.Right]=function(v)return string.format("%g",v)end})
        local slider=control.Slider;slider.control=control;state.sliders[key]=slider
        slider.label=name
        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel",function(self,delta)
            local row,c,art=target()
            if row or art and E.GetArtworkPlacement(c,art) then self:SetValue(self:GetValue()+delta) end
        end)
        slider:HookScript("OnValueChanged",function(_,value)
            if state.refreshing then return end
            local row,c,art=target()
            local adjusted=math.max(low,math.min(high,math.floor(value+.5)))
            if row then
                write(c,row,key,adjusted)
            elseif art and E.GetArtworkPlacement(c,art) then
                E.SetArtworkPlacement(c,art,key,adjusted)
            else return end
            E.PreviewLibraryChange()
        end)
    end
    behind:SetScript("OnClick",function(self)
        local row,c=target();if not row then return end
        local checked=self:GetChecked()
        write(c,row,"effectLayer",checked and "back" or "front")
        if E.MoveStudioEffectToEdge then E.MoveStudioEffectToEdge(c,row.builtin and "native:"..row.builtin or "fx:"..row.addedIndex,checked) end
        E.PreviewLibraryChange();outer.RefreshTarget()
    end)
    remove:SetScript("OnClick",function()
        local row,c=target();if not row then return end
        if row.builtin then write(c,row,"trailOpacity",0) else E.RemoveLibraryEffect(c,row.addedIndex) end
        E.PreviewLibraryChange();outer.RefreshTarget()
    end)
    previous:SetScript("OnClick",function()
        local _,c=target();if not c then return end
        local n=#E.GetLibraryRows(c);if n>0 then state.artSelection=nil;state.selected=(state.selected-2)%n+1;outer.RefreshTarget() end
    end)
    next:SetScript("OnClick",function()
        local _,c=target();if not c then return end
        local n=#E.GetLibraryRows(c);if n>0 then state.artSelection=nil;state.selected=state.selected%n+1;outer.RefreshTarget() end
    end)
    local reset=button(placement,"Reset placement",140);reset:SetPoint("TOPLEFT",845,-448);state.reset=reset
    reset:SetScript("OnClick",function()
        local row,c,art=target()
        if art and E.GetArtworkPlacement(c,art) then
            E.ResetArtworkPlacement(c,art)
            E.PreviewLibraryChange();state.Refresh();return
        end
        if not row then return end
        if row.builtin then
            local defaults=E.GetEffectDefaults(c.art,row.builtin)
            for _,spec in ipairs(E.devEffectFields) do write(c,row,spec[1],defaults[spec[1]]) end
            write(c,row,"effectLayer",defaults.effectLayer or "front")
            E.PreviewLibraryChange();state.Refresh();return
        end
        for _,spec in ipairs(E.devEffectFields) do row[spec[1]]=nil end
        local normalized=E.NormalizeAddedEffect(row)
        for _,spec in ipairs(E.devEffectFields) do write(c,row,spec[1],normalized[spec[1]]) end
        write(c,row,"effectLayer","front");E.PreviewLibraryChange();state.Refresh()
    end)
    local report=button(placement,"Print values",140);report:SetPoint("TOPLEFT",995,-448);state.report=report
    report:SetScript("OnClick",function()
        local row,c,art=target()
        local _,side,mode=E.GetEffectLibraryTarget()
        local tuning=art and E.GetArtworkPlacement(c,art)
        if tuning then
            E.Message(string.format("%s %s %s: size=%g%%, angle=%g, X=%g, Y=%g, opacity=%g%%",
                mode,side,art.name,tuning.trailSize,tuning.trailAngle,tuning.trailX,tuning.trailY,tuning.trailOpacity))
            return
        end
        if not row then return end
        E.Message(string.format("%s %s layer %d: %s (%d), size=%g%%, angle=%g, X=%g, Y=%g, opacity=%g%%, %s",mode,side,state.selected,row.name,row.fileID,row.trailSize,row.trailAngle,row.trailX,row.trailY,row.trailOpacity,row.effectLayer))
    end)
    local note=label(panel,"GameFontHighlightSmall",muted);note:SetPoint("TOPLEFT",845,-602);note:SetWidth(290)
    state.Refresh=function()
        local c,side,mode=E.GetEffectLibraryTarget();if not c then return end
        local context=mode..":"..side..":"..c.art
        if state.context~=context then state.selected=1;state.artSelection=nil;state.context=context end
        local rows=E.GetLibraryRows(c);state.selected=math.max(1,math.min(#rows,state.selected))
        local row=not state.artSelection and rows[state.selected]
        local art=artworkRow(c,rows)
        local tuning=art and E.GetArtworkPlacement(c,art)
        title:SetText("Effects: "..mode.." / "..side.." / "..E.artworkByID[c.art].name)
        local captionText=row and (state.selected.."/"..#rows.."  "..row.name.." ("..row.fileID..")") or "No added layers"
        if art then captionText=art.name end
        caption:SetText(captionText)
        local effectEnabled=not not row and not InCombatLockdown()
        local enabled=not not (row or tuning) and not InCombatLockdown()
        remove:SetEnabled(effectEnabled);behind:SetEnabled(effectEnabled);reset:SetEnabled(enabled);report:SetEnabled(enabled)
        behind:SetShown(not art);behindText:SetShown(not art)
        remove:SetShown(not art)
        if state.animationControls then state.animationControls.Refresh(row,effectEnabled) end
        note:SetText(art and art.id=="art:base" and "Use the main cap controls to position base artwork." or
            "Use Save all changes to keep this placement.")
        remove:SetText(row and row.builtin and "Hide effect" or "Remove layer")
        previous:SetEnabled(not InCombatLockdown() and (#rows>1 or state.artSelection~=nil and #rows>0))
        next:SetEnabled(not InCombatLockdown() and (#rows>1 or state.artSelection~=nil and #rows>0))
        left:SetEnabled(side~="left" and not InCombatLockdown());right:SetEnabled(side~="right" and not InCombatLockdown())
        state.refreshing=true
        local values=row or tuning
        for _,spec in ipairs(E.devEffectFields) do
            local key,text=spec[1],spec[2]
            local slider=state.sliders[key]
            slider.label:SetText(art and artworkLabels[key] or text)
            slider.control:SetEnabled(enabled)
            if values then slider:SetValue(values[key]) end
        end
        behind:SetChecked(row and row.effectLayer=="back" or false);state.refreshing=false
    end
    state.animationControls=E.CreateAnimationControls(panel,state,label,muted)
    state.previous=previous;state.next=next;state.left=left;state.right=right
    return state
end
