local _, E = ...
E.EffectLibrary=E.EffectLibrary or {}
local Viewer=E.EffectLibrary
local ROWS, ROW_HEIGHT = 12, 28
local PANEL_WIDTH, PANEL_HEIGHT = 1390, 700
local gold = { 0.96, 0.78, 0.43 }
local muted = { 0.62, 0.68, 0.74 }
local white = { 0.90, 0.92, 0.95 }

local function fill(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, a or 1)
    return texture
end

local function label(parent, font, color)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetTextColor(unpack(color))
    text:SetJustifyH("LEFT")
    return text
end

local function button(parent, title, width)
    local item = CreateFrame("Button", nil, parent)
    item:SetSize(width, 24)
    item:SetNormalTexture(fill(item, "BACKGROUND", 0.15, 0.19, 0.24))
    item:SetHighlightTexture(fill(item, "HIGHLIGHT", 0.30, 0.36, 0.44))
    item:SetDisabledTexture(fill(item, "BACKGROUND", 0.10, 0.12, 0.15))
    local text = label(item, "GameFontHighlightSmall", white)
    text:SetPoint("CENTER")
    text:SetWidth(width-12);text:SetMaxLines(1)
    item:SetFontString(text)
    item:SetDisabledFontObject(GameFontDisableSmall)
    item:SetText(title)
    return item
end

local function input(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 24)
    box:SetAutoFocus(false)
    if not box.SetEnabled then function box:SetEnabled(v)if v then self:Enable()else self:Disable();self:ClearFocus()end;self:SetAlpha(v and 1 or .5)end end
    box:SetScript("OnEscapePressed", box.ClearFocus)
    return box
end

local function createWindow()
    local panel = CreateFrame("Frame", "EndCapperEffectBrowser", UIParent, "BackdropTemplate")
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel:SetBackdropColor(0.055, 0.068, 0.085, 0.99)
    panel:SetBackdropBorderColor(0.32, 0.29, 0.22)
    panel:Hide()
    tinsert(UISpecialFrames, panel:GetName())

    local title = label(panel, "GameFontNormalLarge", gold)
    title:SetWidth(540);title:SetMaxLines(1)
    title:SetPoint("TOPLEFT", 18, -14)
    title:SetText("EndCapper Effect studio")
    local close = button(panel, "Close", 54)
    close:SetPoint("TOPRIGHT", -16, -11)
    close:SetScript("OnClick", function() panel:Hide() end)

    local search = input(panel, 280)
    search:SetPoint("TOPLEFT", 23, -49)
    search:SetMaxLetters(150)
    local placeholder = label(search, "GameFontHighlightSmall", muted)
    placeholder:SetPoint("LEFT", 5, 0)
    placeholder:SetText("Search names, paths or FileDataID")

    local list = CreateFrame("Frame", nil, panel)
    list:SetSize(290, ROWS * ROW_HEIGHT)
    list:SetPoint("TOPLEFT", 17, -83)
    list:EnableMouseWheel(true)
    local rows, page, matches = {}, 1, {}
    local selected, preview
    local prevPage = button(panel, "Prev", 52)
    prevPage:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -10)
    local nextPage = button(panel, "Next", 52)
    nextPage:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", 0, -10)
    local count = label(panel, "GameFontHighlightSmall", muted)
    count:SetPoint("CENTER", list, "BOTTOM", 0, -22)

    local name = label(panel, "GameFontNormalLarge", white)
    name:SetPoint("TOPLEFT", 325, -48)
    name:SetWidth(497)
    name:SetMaxLines(1)
    local path = label(panel, "GameFontHighlightSmall", muted)
    path:SetPoint("TOPLEFT", 325, -73)
    path:SetWidth(497)
    path:SetMaxLines(2)

    local stage = CreateFrame("Frame", nil, panel)
    stage:SetPoint("TOPLEFT", 325, -105)
    stage:SetPoint("BOTTOMRIGHT", -567, 190)
    local background = fill(stage, "BACKGROUND", 0.11, 0.13, 0.17)
    stage:EnableMouseWheel(true)
    local status = label(panel, "GameFontHighlightSmall", muted)
    status:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 0, -8)
    local contrast = button(panel, "Light BG", 62)
    contrast:SetHeight(18)
    contrast:SetPoint("TOPRIGHT", stage, "BOTTOMRIGHT", 0, -3)
    local lightBackground = false
    contrast:SetScript("OnClick", function()
        lightBackground = not lightBackground
        if lightBackground then
            background:SetColorTexture(0.54, 0.57, 0.62, 1)
        else
            background:SetColorTexture(0.11, 0.13, 0.17, 1)
        end
        contrast:SetText(lightBackground and "Dark BG" or "Light BG")
    end)

    local replay = button(panel, "Replay", 56)
    replay:SetPoint("BOTTOMLEFT", 325, 76)
    local pause = button(panel, "Pause", 56)
    pause:SetPoint("LEFT", replay, "RIGHT", 5, 0)
    local rotate = button(panel, "Rotate", 56)
    rotate:SetPoint("LEFT", pause, "RIGHT", 5, 0)
    local fit = button(panel, "Fit", 36)
    fit:SetPoint("LEFT", rotate, "RIGHT", 5, 0)
    local zoomOut = button(panel, "–", 26)
    zoomOut:SetPoint("LEFT", fit, "RIGHT", 7, 0)
    local zoomIn = button(panel, "+", 26)
    zoomIn:SetPoint("LEFT", zoomOut, "RIGHT", 3, 0)

    local animation = input(panel, 58)
    animation:SetPoint("BOTTOMLEFT", 759, 76)
    animation:SetNumeric(true)
    animation:SetMaxLetters(5)
    local animationLabel = label(panel, "GameFontHighlightSmall", muted)
    animationLabel:SetPoint("RIGHT", animation, "LEFT", -8, 0)
    animationLabel:SetText("Animation ID")

    local id = input(panel, 95)
    id:SetPoint("BOTTOMLEFT", 401, 44)
    local idLabel = label(panel, "GameFontHighlightSmall", muted)
    idLabel:SetPoint("BOTTOMLEFT", 325, 51)
    idLabel:SetText("FileDataID")
    id:SetScript("OnTextChanged", function(self, byUser)
        if byUser then self:SetText(selected and tostring(selected.id) or ""); self:HighlightText() end
    end)
    id:SetScript("OnEditFocusGained", id.HighlightText)
    local copy = button(panel, "Select ID", 70)
    copy:SetPoint("LEFT", id, "RIGHT", 12, 0)
    copy:SetScript("OnClick", function() id:SetFocus(); id:HighlightText() end)

    local added=E.CreateLibraryControls(panel,button,label,title,gold,muted)
    local stack=E.CreateStudioLayerPanel and E.CreateStudioLayerPanel(panel,added,button,label,gold,muted)
    local custom=button(panel,"Custom artwork",145);custom:SetPoint("TOPLEFT",785,-11);panel.custom=custom
    panel.SetCustomArtwork=function(shown)
        panel.customArt=shown;added.host:SetShown(not shown)
        custom:SetText(panel.customArt and "Game effects" or "Custom artwork")
        if E.DockCustomElements then E.DockCustomElements(panel,panel.customArt) end
    end
    custom:SetScript("OnClick",function() panel.SetCustomArtwork(not panel.customArt) end)
    local add=button(panel,"Add effect",220)
    add:SetPoint("BOTTOMLEFT",600,44);panel.add=add
    add:SetEnabled(false)
    local function addEffect()
        local c=E.GetEffectLibraryTarget()
        if not c or InCombatLockdown() or not selected or not preview or preview.state~="ready" then return end
        local index=E.AddLibraryEffect(c,{fileID=selected.id,name=selected.name,animation=preview.animation,
            scale=preview.baseScale*2^preview.zoom,originX=preview.x,originY=preview.y,originZ=preview.z,
            azimuth=preview.angle,elevation=preview.elevation,desaturation=selected.preset and selected.preset.desaturation or 0})
        if index then
            panel.customArt=false;custom:SetText("Custom artwork")
            local _,builtins=E.GetLibraryRows(c);added.selected=index+builtins;added.artSelection=nil
            E.PreviewLibraryChange();panel.RefreshTarget()
        end
    end
    add:SetScript("OnClick",addEffect)
    panel.RefreshTarget=function()
        local c=E.GetEffectLibraryTarget()
        if not c then panel:Hide();return end
        added.Refresh()
        if stack then stack.Refresh() end
        added.host:SetShown(not panel.customArt)
        if E.DockCustomElements then E.DockCustomElements(panel,panel.customArt) end
        if panel.saveAll then panel.saveAll:SetEnabled(not InCombatLockdown() and E.HasChanges()) end
        add:SetEnabled(not InCombatLockdown() and preview and preview.state=="ready" and #E.GetAddedEffects(c)<E.AddedEffectLimit)
    end
    panel:RegisterEvent("PLAYER_REGEN_DISABLED");panel:RegisterEvent("PLAYER_REGEN_ENABLED")
    panel:SetScript("OnEvent",panel.RefreshTarget)
    local function setStatus(message, ready, paused)
        status:SetText(message)
        local c=E.GetEffectLibraryTarget()
        add:SetEnabled(ready==true and c~=nil and not InCombatLockdown() and #E.GetAddedEffects(c)<E.AddedEffectLimit)
        pause:SetText(paused and "Resume" or "Pause")
        for _, control in ipairs({ pause, rotate, fit, zoomOut, zoomIn }) do
            control:SetEnabled(ready == true)
        end
    end
    local previewOK, created = pcall(Viewer.CreatePreview, stage, setStatus)
    if previewOK then preview = created;panel.preview=preview end

    local function renderRows()
        local first = (page - 1) * ROWS + 1
        for i, row in ipairs(rows) do
            local entry = matches[first + i - 1]
            row.entry = entry
            if entry then
                row.name:SetText(entry.name)
                row.id:SetText(entry.id)
                row.selection:SetShown(selected and entry.id == selected.id or false)
            end
            row:SetShown(entry ~= nil)
        end
        local last = math.min(#matches, first + ROWS - 1)
        count:SetText(#matches == 0 and "No matching effects" or (first .. "–" .. last .. " of " .. #matches))
        prevPage:SetEnabled(page > 1)
        nextPage:SetEnabled(last < #matches)
    end

    local function play(keepView)
        if not selected or not preview then return end
        local sequence = tonumber(animation:GetText()) or (selected.preset and selected.preset.animation or 0)
        sequence=math.max(0,math.min(65535,math.floor(sequence)))
        animation:SetText(tostring(sequence))
        preview:Load(selected, sequence, keepView)
    end

    local segmentSummary=label(panel,"GameFontHighlightSmall",muted);segmentSummary:SetPoint("BOTTOMLEFT",325,112);segmentSummary:SetWidth(495)
    panel.segmentButtons={}
    for i,v in ipairs({{"Stand / intro",0},{"Hold",158},{"End",159}})do
        local b=button(panel,v[1],155);b:SetPoint("BOTTOMLEFT",325+(i-1)*165,144);panel.segmentButtons[v[2]]=b
        b:SetScript("OnClick",function()if selected and E.AnimationAvailable(selected.id,v[2]) then animation:SetText(tostring(v[2]));play(true)end end)
    end
    local save=button(panel,"Save all changes",140);save:SetPoint("BOTTOMLEFT",845,16);panel.saveAll=save
    save:SetScript("OnClick",function()if E.SaveEffectStudio then E.SaveEffectStudio()end;panel.RefreshTarget()end)
    local cancel=button(panel,"Cancel changes",140);cancel:SetPoint("BOTTOMLEFT",995,16)
    cancel:SetScript("OnClick",function()panel:Hide();if E.CancelEffectStudio then E.CancelEffectStudio()end end)
    panel.rows=rows;panel.search=search
    local function selectEntry(entry)
        selected = entry
        segmentSummary:SetText(E.AnimationSummary(entry.id))
        for id,b in pairs(panel.segmentButtons)do b:SetEnabled(E.AnimationAvailable(entry.id,id))end
        name:SetText(entry.name)
        path:SetText(entry.path)
        id:SetText(tostring(entry.id))
        animation:SetText(tostring(entry.preset and entry.preset.animation or 0))
        renderRows()
        if preview then play(false) end
    end

    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, list)
        row:SetSize(290, ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        fill(row, "BACKGROUND", 0.085, 0.104, 0.13)
        row.selection = fill(row, "BORDER", 0.26, 0.22, 0.14)
        row:SetHighlightTexture(fill(row, "HIGHLIGHT", 0.18, 0.22, 0.27, 0.6))
        row.name = label(row, "GameFontHighlight", white)
        row.name:SetPoint("LEFT", 9, 0)
        row.name:SetWidth(190)
        row.name:SetMaxLines(1)
        row.id = label(row, "GameFontHighlightSmall", muted)
        row.id:SetPoint("RIGHT", -9, 0)
        row:SetScript("OnClick", function(self)
            search:ClearFocus()
            selectEntry(self.entry)
        end)
        rows[i] = row
    end

    local function changePage(delta)
        page = math.max(1, math.min(page + delta, math.ceil(#matches / ROWS)))
        renderRows()
    end
    prevPage:SetScript("OnClick", function() changePage(-1) end)
    nextPage:SetScript("OnClick", function() changePage(1) end)
    list:SetScript("OnMouseWheel", function(_, delta) changePage(-delta) end)

    local function filter()
        local query = search:GetText()
        placeholder:SetShown(query == "" and not search:HasFocus())
        matches, page = Viewer.Search(query), 1
        renderRows()
    end
    search:SetScript("OnTextChanged", filter)
    search:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    search:SetScript("OnEditFocusLost", function() placeholder:SetShown(search:GetText() == "") end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local entry = matches[(page - 1) * ROWS + 1]
        if entry then selectEntry(entry) end
    end)
    replay:SetEnabled(preview ~= nil)
    animation:SetEnabled(preview ~= nil)
    replay:SetScript("OnClick", function() animation:ClearFocus(); play(true) end)
    animation:SetScript("OnEnterPressed", function(self) self:ClearFocus(); play(true) end)
    pause:SetScript("OnClick", function() preview:TogglePause() end)
    fit:SetScript("OnClick", function() preview:Fit() end)
    rotate:SetScript("OnClick", function() preview:SetView(preview.zoom, (preview.angle + 45) % 360) end)
    local function zoom(delta)
        if preview and preview.state == "ready" then
            preview:SetView(math.max(-8, math.min(8, preview.zoom + delta / 2)), preview.angle)
        end
    end
    zoomOut:SetScript("OnClick", function() zoom(-1) end)
    zoomIn:SetScript("OnClick", function() zoom(1) end)
    stage:SetScript("OnMouseWheel", function(_, delta) zoom(delta) end)

    panel:SetScript("OnShow", function()
        if selected then play(true) else selectEntry(Viewer.Search("166011")[1]) end
    end)
    panel:SetScript("OnHide", function()
        if E.DockCustomElements then E.DockCustomElements(nil,false) end
        search:ClearFocus()
        animation:ClearFocus()
        id:ClearFocus()
        if preview then preview:Clear() end
    end)
    setStatus(preview and "" or "Native model preview is unavailable in this client.")
    filter()
    return panel
end

function Viewer.Open()
    if not E.GetEffectLibraryTarget() or InCombatLockdown() then return end
    Viewer.window=Viewer.window or createWindow()
    local panel=Viewer.window
    panel:SetScale(math.max(0.25,math.min(1,(UIParent:GetWidth()-24)/PANEL_WIDTH,(UIParent:GetHeight()-24)/PANEL_HEIGHT)))
    panel:Show();panel.RefreshTarget()
end
function Viewer.RefreshTarget()
    if Viewer.window and Viewer.window:IsShown() then Viewer.window.RefreshTarget() end
end
function Viewer.Close()
    if Viewer.window then Viewer.window:Hide() end
end
