local _, E = ...
-- Felwing's registered emission atlas: 16 authored frames, 8 fps / 2 seconds.
-- This plane follows the ARTWORK, independently of native effect calibration.
local columns, frames, fps = 4, 16, 8
local function draw(state)
    local index=math.floor(state.elapsed*fps)%frames
    if state.index==index and state.drawnFlip==state.flip then return end
    state.index=index; state.drawnFlip=state.flip
    local left,top=(index%columns)/columns,math.floor(index/columns)/columns
    local right,bottom=left+1/columns,top+1/columns
    state.texture:SetTexCoord(E.UV({left,top,left,bottom,right,top,right,bottom},state.flip))
end
function E.StopGlyphs(entry)
    local state=entry.glyphs
    if not state then return end
    state.host:SetScript("OnUpdate",nil)
    state.host:Hide()
end
function E.PlayGlyphs(entry)
    local state=entry.glyphs
    if not state or not state.enabled or not entry.frame:IsVisible() then return end
    state.host:Show()
    state.host:SetScript("OnUpdate",state.tick)
end
function E.UpdateGlyphs(entry,config)
    local enabled=config.art=="felwing" and config.effects~=false
    local state=entry.glyphs
    if not enabled then
        if state then state.enabled=false; E.StopGlyphs(entry) end
        return
    end
    if not state then
        local host=CreateFrame("Frame",nil,entry.frame)
        host:SetAllPoints(entry.frame); host:EnableMouse(false)
        local texture=host:CreateTexture(nil,"OVERLAY",nil,7)
        texture:SetBlendMode("ADD")
        state={host=host,texture=texture,elapsed=0}
        entry.glyphs=state
        state.tick=function(_,elapsed)
            -- One UV update at most per render tick; skip missed frames rather
            -- than replaying them after a stall. No work while hidden/disabled.
            state.elapsed=(state.elapsed+elapsed)%(frames/fps)
            draw(state)
        end
    end
    state.texture:SetTexture(E.ArtworkTexture("Interface\\AddOns\\EndCapper\\Media\\FelwingGlyphAtlas.tga"))
    state.enabled=true; state.flip=config.flip
    state.host:SetFrameLevel(entry.frame:GetFrameLevel()+3)
    state.host:SetAlpha(entry.alpha)
    local width,height=entry.art:GetSize()
    state.texture:SetSize(width,height)
    state.texture:ClearAllPoints()
    state.texture:SetPoint("CENTER",entry.art,"CENTER",0,0)
    draw(state)
    E.PlayGlyphs(entry)
end
