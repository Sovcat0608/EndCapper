local addonName, E = ...
E.caps = {}
local events = CreateFrame("Frame")
local function message(text) print("|cffb8e08cEndCapper:|r " .. text) end
E.Message = message

local function frameScreenX(frame)
    if not frame.GetCenter or not frame.GetEffectiveScale or not UIParent.GetEffectiveScale then return end
    local x=frame:GetCenter()
    if x then return x*frame:GetEffectiveScale()/UIParent:GetEffectiveScale()-(UIParent:GetLeft() or 0) end
end
local function frameHalfWidth(entry,config)
    local art=E.artworkByID[config.art]
    local width
    if art and art.path then width=art.width*config.size/100
    elseif config.art=="hidden" then width=entry.frame:GetSize()
    elseif config.flip or config.size~=100 or config.x~=0 or config.y~=0 then
        width=entry.native:GetSize();width=width*config.size/100
    else width=entry.frame:GetSize() end
    return width/2*entry.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
end
local function recordDraggedPairCenter(db,entry,x)
    local pair=db.pair
    if not pair.linked then return end
    local side=entry.side
    local config=db[side]
    pair.centerX=x-pair.x-E.PairFrameOffset(config,side,pair.separation,frameHalfWidth(entry,config))
end
function E.CaptureNativePairSpacing()
    local left,right=E.caps.left,E.caps.right
    if not left or not right then return end
    local x1,x2=frameScreenX(left.frame),frameScreenX(right.frame)
    if x1 and x2 and x2>x1 then E.nativePairSpan=x2-x1 end
end
function E.GetDefaultPairSeparation(db)
    local left,right=E.caps.left,E.caps.right
    if not left or not right then return end
    local span=E.nativePairSpan
    if not span then
        local x1,x2=frameScreenX(left.frame),frameScreenX(right.frame)
        if x1 and x2 and x2>x1 then span=x2-x1 end
    end
    if not span then return end
    local gap=span-frameHalfWidth(left,db.left)-frameHalfWidth(right,db.right)
    return math.max(0,math.min(2000,math.floor(gap/2+0.5)*2))
end
function E.ResolvePairFrames()
    local db=E.Config();local p=db.pair
    if not p or not p.linked then return end
    local left,right=E.caps.left,E.caps.right
    if not left or not right or left.dragging or right.dragging then return end
    if not left.frame.GetEffectiveScale or not right.frame.GetEffectiveScale or not UIParent.GetEffectiveScale then return end
    if not p.separationInitialized then E.ResetPairSeparation(db) end
    if not p.centerX then
        local x1,x2=frameScreenX(left.frame),frameScreenX(right.frame)
        if not x1 or not x2 then return end
        p.centerX=(x1+x2)/2
    end
    for _,side in ipairs({"left","right"}) do
        local entry=E.caps[side]
        db[side].frameX=p.centerX+p.x+E.PairFrameOffset(db[side],side,p.separation,frameHalfWidth(entry,db[side]))
    end
end

function E.AlignBottom(entry,config)
    local frame=entry.frame
    if not frame.GetCenter or not frame.GetBottom or not frame.GetEffectiveScale or
        not UIParent.GetEffectiveScale or not UIParent.GetBottom then return end
    if config.frameX~=nil and not entry.frameXOriginal then
        entry.frameXOriginal={}
        for i=1,frame:GetNumPoints() do entry.frameXOriginal[i]={frame:GetPoint(i)} end
    elseif config.frameX==nil and entry.frameXOriginal then
        entry.settingBottom=true;frame:ClearAllPoints()
        for _,point in ipairs(entry.frameXOriginal) do frame:SetPoint(unpack(point)) end
        entry.settingBottom=false;entry.frameXOriginal=nil
    end
    if not config.frameBottom and config.frameX==nil then
        if entry.bottomOriginal then
            entry.settingBottom=true;frame:ClearAllPoints()
            for _,point in ipairs(entry.bottomOriginal) do frame:SetPoint(unpack(point)) end
            entry.settingBottom=false;entry.bottomOriginal=nil
        end
        return
    end
    local x=frame:GetCenter();if not x or not frame:GetBottom() or not UIParent:GetBottom() then return end
    local scale=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
    local _,frameHeight=frame:GetSize()
    local selectionHeight=entry.suppress and config.art~="hidden" and select(2,entry.art:GetSize()) or frameHeight
    local bottom=config.frameBottom and (selectionHeight-frameHeight)/2 or frame:GetBottom()-UIParent:GetBottom()*scale
    local targetX=config.frameX and config.frameX*scale or x-(UIParent:GetLeft() or 0)*scale
    if math.abs(frame:GetBottom()-UIParent:GetBottom()*scale-bottom)<0.01 and
        math.abs(x-(UIParent:GetLeft() or 0)*scale-targetX)<0.01 then return end
    if not entry.bottomOriginal then
        entry.bottomOriginal={}
        for i=1,frame:GetNumPoints() do entry.bottomOriginal[i]={frame:GetPoint(i)} end
    end
    entry.settingBottom=true
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",targetX,bottom)
    entry.settingBottom=false
end

function E.UpdateSelection(entry, config)
    local selection = entry.frame.Selection
    if not selection then return end
    if not entry.selectionOriginal then
        local original = {points = {}, width = selection:GetWidth(), height = selection:GetHeight(),
            levelOffset=selection:GetFrameLevel()-entry.frame:GetFrameLevel()}
        for i = 1, selection:GetNumPoints() do original.points[i] = {selection:GetPoint(i)} end
        entry.selectionOriginal = original
        selection:HookScript("OnShow", function() E.Schedule(entry.side) end)
    end
    -- Keep the native drag handlers and the system frame's layout/size intact.
    -- Match artwork size, but keep the drag region centred on the cap frame.
    -- Artwork offsets must never relocate the native drag target.
    if entry.suppress and config.art ~= "hidden" then
        local width, height = entry.art:GetSize()
        local frameWidth, frameHeight = entry.frame:GetSize()
        local insetX, insetY = (frameWidth-width)/2, (height-frameHeight)/2
        selection:ClearAllPoints()
        selection:SetSize(width, height)
        -- Blizzard's GetLeft/TopOffset reads point 1; GetRight/BottomOffset
        -- reads point 2. A lone CENTER anchor breaks snapping before the native
        -- OnDragStop can record the changed position for layout saving.
        selection:SetPoint("TOPLEFT", entry.frame, "TOPLEFT", insetX, insetY)
        selection:SetPoint("BOTTOMRIGHT", entry.frame, "BOTTOMRIGHT", -insetX, -insetY)
        -- Keep the existing interactive highlight above our three visual planes.
        selection:SetFrameLevel(entry.frame:GetFrameLevel()+math.max(config.art=="violetSpire" and 5 or 4,entry.selectionOriginal.levelOffset))
        entry.selectionAdjusted = true
    elseif entry.selectionAdjusted then
        local original = entry.selectionOriginal
        selection:ClearAllPoints(); selection:SetSize(original.width, original.height)
        for _, point in ipairs(original.points) do selection:SetPoint(unpack(point)) end
        selection:SetFrameLevel(entry.frame:GetFrameLevel()+original.levelOffset)
        entry.selectionAdjusted = false
    end
    if entry.frame.UpdateClampOffsets then entry.frame:UpdateClampOffsets() end
end

function E.Apply(targetSide)
    if not E.ready then return end
    if InCombatLockdown() then E.pending = true; return end
    E.pending = false
    if E.ReconcilePositionLayout then
        local allowed,changed=E.ReconcilePositionLayout()
        if not allowed then return end
        if changed then targetSide=nil end
    end
    E.ResolvePairFrames()
    for side, entry in pairs(E.caps) do
        if not targetSide or side == targetSide then
            local c = E.Config()[side]
            local native, art = entry.native, entry.art
            entry.suppress = c.art ~= "default" or c.flip or c.size ~= 100 or c.x ~= 0 or c.y ~= 0
            entry.settingAlpha = true
            native:SetAlpha(entry.suppress and 0 or entry.alpha)
            entry.settingAlpha = false
            art:Hide()
            if entry.artOverlay then entry.artOverlay:Hide() end
            if entry.suppress and c.art ~= "hidden" then
                local width, height = 150, 150
                local artwork=E.artworkByID[c.art]
                if artwork and artwork.path then
                    art:SetTexture(artwork.path)
                    width, height = artwork.width or 150, artwork.height or 150
                    art:SetTexCoord(E.UV({0, 0, 0, 1, 1, 0, 1, 1}, c.flip))
                else
                    local atlas = native:GetAtlas()
                    if atlas then art:SetAtlas(atlas) else art:SetTexture(native:GetTexture()) end
                    art:SetTexCoord(E.UV({native:GetTexCoord()}, c.flip))
                    width, height = native:GetSize()
                end
                art:SetSize(width * c.size / 100, height * c.size / 100)
                art:SetAlpha(entry.alpha)
                art:ClearAllPoints()
                local offsetY=c.y
                -- The visible drag box is art-sized for custom artwork. Its
                -- lower edge is the zero reference, excluding transparent padding.
                if c.artBottom and entry.frame.GetCenter then
                    local baseline=E.EffectBaselines[c.art] or 1
                    offsetY=offsetY+height*c.size/100*(baseline-1)
                end
                art:SetPoint("CENTER", entry.frame, "CENTER", c.x, offsetY)
                art:Show()
                if artwork and artwork.overlay then
                    -- Static foreground artwork shares the base plane, above its
                    -- texture but below front native effects. It is not an effect.
                    local overlay=entry.artOverlay
                    if not overlay then
                        overlay=entry.artLayer:CreateTexture(nil,"OVERLAY",nil,7)
                        entry.artOverlay=overlay
                        overlay:SetBlendMode("BLEND")
                    end
                    overlay:SetTexture(artwork.overlay)
                    overlay:SetSize(width*c.size/100,height*c.size/100)
                    overlay:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},c.flip))
                    overlay:SetAlpha(entry.alpha)
                    overlay:ClearAllPoints()
                    overlay:SetPoint("CENTER",art,"CENTER",0,0)
                    overlay:Show()
                end
            end
            E.UpdateSelection(entry, c)
            E.AlignBottom(entry,c)
            E.UpdateEffects(entry, E.GetEffectConfig(c))
        end
    end
end

local scheduledSides = {}
function E.Schedule(side)
    if side == "left" or side == "right" then scheduledSides[side] = true
    else scheduledSides.left, scheduledSides.right = true, true end
    if E.scheduled then return end
    E.scheduled = true
    C_Timer.After(0, function()
        local sides = scheduledSides
        scheduledSides = {}; E.scheduled = false
        if sides.left and sides.right then E.Apply()
        else E.Apply(sides.left and "left" or "right") end
    end)
end

function E.Attach()
    if not E.ready or InCombatLockdown() then E.pending = true; return end
    local root = MainActionBar and MainActionBar.EndCaps
    if not root then return end
    for _, side in ipairs({"left", "right"}) do
        local cap = root[side == "left" and "LeftEndCap" or "RightEndCap"]
        if cap and cap.Texture and not E.caps[side] then
            local native = cap.Texture
            -- A separate, noninteractive plane allows native models below/above
            -- the artwork without changing the native cap frame level.
            local artLayer=CreateFrame("Frame",nil,cap)
            artLayer:SetAllPoints(cap); artLayer:EnableMouse(false)
            artLayer:SetFrameLevel(cap:GetFrameLevel()+2)
            local art = artLayer:CreateTexture(nil, "OVERLAY", nil, 6)
            local entry = { side = side, frame = cap, artLayer=artLayer, native = native, art = art, alpha = native:GetAlpha() }
            E.caps[side] = entry
            local function scheduleSide() E.Schedule(entry.side) end
            -- Observe Blizzard artwork changes without replacing its methods or settings.
            hooksecurefunc(native, "SetAtlas", scheduleSide)
            hooksecurefunc(native, "SetTexture", scheduleSide)
            hooksecurefunc(native, "SetTexCoord", scheduleSide)
            hooksecurefunc(native, "SetAlpha", function(_, alpha)
                if entry.settingAlpha then return end
                entry.alpha = alpha
                scheduleSide()
            end)
            cap:HookScript("OnSizeChanged", scheduleSide)
            hooksecurefunc(cap,"SetPoint",function()
                if not entry.settingBottom then scheduleSide() end
            end)
            local function releaseBottom()
                -- Native dragging owns the new layout position. Keep the
                -- artwork's crop-relative Y, but release automatic floor anchoring.
                entry.dragging=true
                E.Config()[side].frameBottom=false;E.Config()[side].frameX=nil;entry.bottomOriginal=nil;entry.frameXOriginal=nil
                if EndCapperDB and EndCapperDB[side] then EndCapperDB[side].frameBottom=false;EndCapperDB[side].frameX=nil end
            end
            if cap.OnDragStart then
                hooksecurefunc(cap,"OnDragStart",function() if cap.isDragging then releaseBottom() end end)
            else cap:HookScript("OnDragStart",releaseBottom) end
            local function finishDrag()
                if not entry.dragging then return end
                entry.dragging=false
                local db=E.Config();local x=frameScreenX(cap)
                if x then
                    -- Cancel restores the saved geometry around the same dragged frame.
                    recordDraggedPairCenter(db,entry,x)
                    if db~=EndCapperDB then recordDraggedPairCenter(EndCapperDB,entry,x) end
                    if db.pair.linked then E.Schedule() end
                end
                if E.SavePositionProfile then E.SavePositionProfile() end
            end
            if cap.OnDragStop then hooksecurefunc(cap,"OnDragStop",finishDrag)
            else cap:HookScript("OnDragStop",finishDrag) end
        end
    end
    if not E.nativePairSpan then E.CaptureNativePairSpacing() end
    E.Apply()
    if E.AttachOptions then E.AttachOptions() end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(EndCapperDB) == "table" and type(EndCapperDB.version) == "number" and EndCapperDB.version > E.schemaVersion then
            message("Settings are from a newer version. This version will leave them untouched.")
            return
        end
        EndCapperDB = E.Normalize(EndCapperDB)
        E.ready = true
        SLASH_ENDCAPPER1 = "/endcapper"
        SLASH_ENDCAPPER2 = "/ecap"
        SlashCmdList.ENDCAPPER = function(command)
            local cmd=(command or ""):lower():match("^%s*(.-)%s*$")
            if cmd=="dev" or cmd=="dev on" or cmd=="dev off" then
                if InCombatLockdown() then message("Developer editing is available after combat."); return end
                E.devMode=cmd~="dev off" and (cmd=="dev on" or not E.devMode)
                message(E.devMode and "Developer mode on: artwork effect calibration unlocked." or "Developer mode off. Applied calibration is retained.")
                E.OpenOptions()
            elseif cmd=="status" then
                for _, side in ipairs({"left", "right"}) do
                    message(side .. ": " .. E.NativeSmokeStatus(E.caps[side]))
                end
            else E.OpenOptions() end
        end
    end
    if not E.ready then return end
    if event=="ADDON_LOADED" and name~=addonName and E.caps.left and E.caps.right then
        if E.AttachOptions and not (E.dialogHooked and E.registryHooked) and not InCombatLockdown() then
            E.AttachOptions()
        end
        return
    end
    if event=="PLAYER_LOGOUT" then
        if E.SavePositionProfile then E.SavePositionProfile() end
        return
    end
    if event=="EDIT_MODE_LAYOUTS_UPDATED" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        -- The native manager must finish applying its own anchors first.
        E.Schedule();return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if E.panel then E.panel:Hide() end
    else
        E.Attach()
    end
end)
