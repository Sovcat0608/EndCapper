local _, E = ...
-- Cropped source-space regions, matching tools/Build-UndercityLiquid.cjs.
-- Painted streams stay in the base; these masked colour frames add downward flow.
local regions = {
    cryptgate={name="Cryptgate",x=174,y=400,w=44,h=68},
    plaguewell={name="Plaguewell",x=385,y=322,w=38,h=94},
}
local columns,frames,fps,cell,pad,atlas=8,64,24,128,2,1024
local function draw(state)
    local index=math.floor(state.elapsed*fps)%frames
    if state.index==index and state.drawnFlip==state.flip then return end
    state.index=index;state.drawnFlip=state.flip
    local x,y=(index%columns)*cell,math.floor(index/columns)*cell
    local l,r,t,b=(x+pad)/atlas,(x+cell-pad)/atlas,(y+pad)/atlas,(y+cell-pad)/atlas
    state.texture:SetTexCoord(E.UV({l,t,l,b,r,t,r,b},state.flip))
end
function E.StopLiquid(entry)
    local state=entry.liquid
    if state then state.host:SetScript("OnUpdate",nil);state.host:Hide() end
end
function E.PlayLiquid(entry)
    local state=entry.liquid
    if not state or not state.enabled or not entry.frame:IsVisible() then return end
    state.host:Show();state.host:SetScript("OnUpdate",state.tick)
end
function E.UpdateLiquid(entry,config)
    local region=regions[config.art]
    local state=entry.liquid
    if not region or config.effects==false then
        if state then state.enabled=false;E.StopLiquid(entry) end
        return
    end
    if not state then
        local host=CreateFrame("Frame",nil,entry.frame)
        host:SetAllPoints(entry.frame);host:EnableMouse(false)
        local texture=host:CreateTexture(nil,"OVERLAY",nil,7)
        texture:SetBlendMode("BLEND")
        if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
        if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
        state={host=host,texture=texture,elapsed=0}
        entry.liquid=state
        state.tick=function(_,elapsed)
            state.elapsed=(state.elapsed+elapsed)%(frames/fps)
            draw(state)
        end
    end
    local path=E.ArtworkTexture("Interface\\AddOns\\EndCapper\\Media\\"..region.name.."LiquidAtlas.tga")
    if state.path~=path then
        state.texture:SetTexture(path,"CLAMP","CLAMP","LINEAR")
        state.path=path;state.art=config.art;state.index=nil
    end
    state.enabled=true;state.flip=config.flip
    state.host:SetFrameLevel(entry.frame:GetFrameLevel()+3)
    state.host:SetAlpha(entry.alpha)
    local width,height=entry.art:GetSize()
    local u=(region.x+region.w/2)/512
    if config.flip then u=1-u end
    state.texture:SetSize(width*region.w/512,height*region.h/512)
    state.texture:ClearAllPoints()
    state.texture:SetPoint("CENTER",entry.art,"TOPLEFT",width*u,-height*(region.y+region.h/2)/512)
    draw(state);E.PlayLiquid(entry)
end
