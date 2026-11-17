local _, E = ...

function E.CreateStudioLayerPanel(panel,controls,button,label,gold,muted)
    local host=CreateFrame("Frame",nil,panel)
    host:SetPoint("TOPLEFT",1153,-49)
    host:SetSize(220,592)
    host:EnableMouseWheel(true)
    local heading=label(host,"GameFontNormal",gold)
    heading:SetPoint("TOPLEFT",0,0)
    heading:SetText("Layers")
    local hint=label(host,"GameFontHighlightSmall",muted)
    hint:SetPoint("TOPLEFT",0,-22)
    hint:SetText("Front to back · scroll for more")

    local state={first=1,rows={}}
    panel.layerStack=state
    local current
    local up=button(host,"Move up",103)
    up:SetPoint("TOPLEFT",0,-480)
    local down=button(host,"Move down",103)
    down:SetPoint("LEFT",up,"RIGHT",8,0)
    state.up,state.down=up,down

    local flip=CreateFrame("CheckButton",nil,host,"UICheckButtonTemplate")
    flip:SetPoint("TOPLEFT",0,-505)
    flip:SetSize(20,20)
    local flipLabel=label(host,"GameFontHighlightSmall",muted)
    flipLabel:SetPoint("LEFT",flip,"RIGHT",4,0)
    flipLabel:SetText("Flip horizontally")
    state.flip=flip
    flip:SetScript("OnClick",function(self)
        local c=E.GetEffectLibraryTarget()
        if not c or not current or InCombatLockdown() then return end
        if E.SetLayerFlip(c,current.id,self:GetChecked()) then
            E.PreviewLibraryChange()
            panel.RefreshTarget()
        end
    end)

    local followLabel=label(host,"GameFontHighlightSmall",muted)
    followLabel:SetPoint("TOPLEFT",0,-540)
    followLabel:SetText("Follow artwork motion")
    local follow=CreateFrame("DropdownButton",nil,host,"WowStyle1DropdownTemplate")
    follow:SetPoint("TOPLEFT",0,-556)
    follow:SetSize(214,30)
    state.follow=follow
    follow:SetupMenu(function(_,root)
        local c=E.GetEffectLibraryTarget()
        if not c or not current or not current.effectIndex then return end
        local id=current.id
        local function choose(source)
            local target=E.GetEffectLibraryTarget()
            if target~=c or not current or current.id~=id or InCombatLockdown() then return end
            E.SetLayerMotion(c,id,source or nil)
            E.PreviewLibraryChange()
            state.Refresh()
        end
        local function selected(source) return (E.GetLayerMotion(c,id) or false)==source end
        root:CreateRadio("None",selected,choose,false)
        for _,row in ipairs(E.GetLayerStack(c)) do
            if row.motion then root:CreateRadio(row.name,selected,choose,row.id) end
        end
    end)

    for i=1,16 do
        local row=button(host,"",214)
        row:SetPoint("TOPLEFT",0,-42-(i-1)*27)
        row:SetScript("OnClick",function()
            local item=row.item
            if not item then return end
            if panel.customArt then panel.SetCustomArtwork(false) end
            if item.effectIndex then
                controls.artSelection=nil
                controls.selected=item.effectIndex
            else
                controls.artSelection=item.id
            end
            panel.RefreshTarget()
        end)
        state.rows[i]=row
    end

    state.Refresh=function()
        local c,side,mode=E.GetEffectLibraryTarget()
        if not c then return end
        local context=mode..":"..side..":"..c.art
        local changedContext=state.context~=context
        if changedContext then state.first=1;state.context=context end
        local layers=E.GetLayerStack(c)
        local selectedIndex
        current=nil
        for i,item in ipairs(layers) do
            if (controls.artSelection and item.id==controls.artSelection) or
                (not controls.artSelection and item.effectIndex==controls.selected) then
                current=item
                selectedIndex=#layers-i+1
                break
            end
        end
        if not current and #layers>0 then
            current=layers[#layers]
            selectedIndex=1
            if not current.effectIndex then
                controls.artSelection=current.id
                controls.Refresh()
            end
        end
        if selectedIndex and (changedContext or state.selection~=current.id) then
            if selectedIndex<state.first then state.first=selectedIndex end
            if selectedIndex>=state.first+#state.rows then state.first=selectedIndex-#state.rows+1 end
        end
        state.selection=current and current.id
        state.count=#layers
        state.first=math.max(1,math.min(state.first,#layers-#state.rows+1))
        local available=not InCombatLockdown()
        flip:SetEnabled(available and current~=nil)
        flipLabel:SetText(current and current.flipTarget and "Flip with flask glass" or "Flip horizontally")
        flip:SetChecked(current~=nil and E.GetLayerFlip(c,current.flipTarget or current.id))
        for i,row in ipairs(state.rows) do
            row.item=layers[#layers-state.first-i+2]
            row:SetShown(row.item~=nil)
            if row.item then
                local name=(row.item==current and "› " or "")..row.item.name
                if E.GetLayerMotion(c,row.item.id) then name=name.."  ↕" end
                row:SetText(name)
            end
        end
        up:SetEnabled(available and selectedIndex~=nil and selectedIndex>1)
        down:SetEnabled(available and selectedIndex~=nil and selectedIndex<#layers)
        local sources=false
        for _,row in ipairs(layers) do if row.motion then sources=true;break end end
        local canFollow=current~=nil and current.effectIndex~=nil and sources
        follow:SetShown(canFollow)
        followLabel:SetShown(canFollow)
        follow:SetEnabled(canFollow and available)
        if canFollow then follow:GenerateMenu() end
    end

    host:SetScript("OnMouseWheel",function(_,delta)
        state.first=math.max(1, math.min((state.count or 0)-#state.rows+1,state.first-delta))
        state.Refresh()
    end)
    local function move(change)
        local c=E.GetEffectLibraryTarget()
        if not c or not current or InCombatLockdown() then return end
        if E.MoveStudioLayer(c,current.id,change) then
            state.selection=nil
            E.PreviewLibraryChange()
            panel.RefreshTarget()
        end
    end
    up:SetScript("OnClick",function() move(1) end)
    down:SetScript("OnClick",function() move(-1) end)
    return state
end
