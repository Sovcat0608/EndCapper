local _,E=...

function E.AnimationSummary(id)
    local rows=E.EffectAnimations and E.EffectAnimations[id]
    if not rows then return "Segments unverified. Preview animation IDs before use." end
    local function segment(label,n)return label..(rows[n] and string.format(" %.2fs",rows[n]) or " —")end
    return segment("Stand / intro",0).."  |  "..segment("Hold",158).."  |  "..segment("End",159)
end

function E.AnimationAvailable(id,animation)
    local rows=E.EffectAnimations and E.EffectAnimations[id]
    return not rows or rows[animation]~=nil
end

-- A native sequence choice is visual tuning, independent of gameplay events.
function E.CreateAnimationControls(panel,state,label,muted)
    local title=label(panel,"GameFontHighlightSmall",muted)
    title:SetPoint("TOPLEFT",845,-488);title:SetText("Layer animation ID (Enter to apply)")
    local input=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    input:SetSize(100,24);input:SetPoint("TOPLEFT",850,-510)
    input:SetAutoFocus(false);input:SetNumeric(true);input:SetMaxLetters(5)
    if not input.SetEnabled then
        function input:SetEnabled(v)
            if v then self:Enable()else self:Disable();self:ClearFocus()end
            self:SetAlpha(v and 1 or .5)
        end
    end
    input:SetScript("OnEnterPressed",function(self)
        if InCombatLockdown() then return end
        local c=E.GetEffectLibraryTarget();local row=c and E.GetLibraryRows(c)[state.selected]
        local id=tonumber(self:GetText())
        if row and row.addedIndex and id and id==math.floor(id) and id>=0 and id<=65535 then
            E.EditAddedEffects(c)[row.addedIndex].animation=id;E.PreviewLibraryChange()
        end
        self:ClearFocus();state.Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)self:ClearFocus();state.Refresh()end)
    local controls={input=input}
    function controls.Refresh(row,enabled)
        local added=row and row.addedIndex~=nil
        title:SetShown(added==true);input:SetShown(added==true)
        input:SetEnabled(enabled and added==true)
        if not input:HasFocus()then input:SetText(tostring(row and row.animation or 0))end
    end
    return controls
end
