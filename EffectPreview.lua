local _, E = ...
E.EffectLibrary=E.EffectLibrary or {}
local Viewer=E.EffectLibrary
local Preview = {}
Preview.__index = Preview

local function bounds(actor)
    if not actor.GetMaxBoundingBox then return 0, 0, 0, 1 end
    local x1, y1, z1, x2, y2, z2 = actor:GetMaxBoundingBox()
    if type(x1) == "table" and type(y1) == "table" then
        local bottom, top = x1, y1
        x1, y1, z1 = bottom:GetXYZ()
        x2, y2, z2 = top:GetXYZ()
    end
    if type(x1) ~= "number" or type(z2) ~= "number" then return 0, 0, 0, 1 end
    local span = math.max(x2 - x1, y2 - y1, z2 - z1)
    if span < 0.001 or span > 100000 then return 0, 0, 0, 1 end
    return (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, 2.5 / span
end

function Preview:SetView(zoom, angle)
    self.zoom, self.angle = zoom, angle
    local azimuth, elevation = math.rad(angle), math.rad(self.elevation)
    local sa, ca = math.sin(azimuth), math.cos(azimuth)
    local se, ce = math.sin(elevation), math.cos(elevation)
    local fx, fy, fz = sa * ce, ca * ce, -se
    self.scene:SetCameraPosition(-8 * fx, -8 * fy, -8 * fz)
    self.scene:SetCameraOrientationByAxisVectors(fx, fy, fz, ca, -sa, 0, sa * se, ca * se, ce)

    local scale = self.baseScale * 2 ^ zoom
    self.actor:SetScale(scale)
    self.actor:SetPosition(-self.x * scale, -self.y * scale, -self.z * scale)
end

function Preview:Clear()
    self.generation = self.generation + 1
    self.state, self.paused = nil, false
    self.actor.endCapperLibraryLoaded = nil
    self.scene:Hide()
    self.scene:SetPaused(false, false)
    self.actor:ClearModel()
end

function Preview:Load(entry, animation, keepView)
    self:Clear()
    self.animation=animation
    local generation = self.generation
    local actor, scene = self.actor, self.scene
    local preset = entry.preset
    if not keepView then
        self.zoom, self.angle, self.elevation = 0, preset and preset.angle or 0, preset and preset.elevation or 0
    end
    self.state = "loading"
    self.update("Loading effect…")

    local function fail(message)
        self:Clear()
        self.update(message)
    end

    local function finish()
        if self.generation ~= generation or self.state ~= "loading" then return end
        if not actor:IsLoaded() or actor:GetModelFileID() ~= entry.id then return end

        local ok = pcall(function()
            actor:SetAnimation(animation, 0, 1, 0)
            if preset then
                self.x, self.y, self.z = unpack(preset.origin or { 0, 0, 0 })
                self.baseScale = preset.scale
            else
                self.x, self.y, self.z, self.baseScale = bounds(actor)
            end
            self:SetView(self.zoom, self.angle)
            if scene.SetDesaturation then scene:SetDesaturation(preset and preset.desaturation or 0) end
        end)
        if not ok then fail("Preview unavailable for this model or animation."); return end
        self.state = "ready"
        actor.endCapperLibraryLoaded = nil
        scene:SetAlpha(1)
        self.update("Playing", true)
    end

    -- Defer the callback because a cached model can fire it during SetModelByFileID.
    actor.endCapperLibraryLoaded = function() C_Timer.After(0, finish) end
    scene:SetAlpha(0)
    scene:Show()
    local ok, accepted = pcall(actor.SetModelByFileID, actor, entry.id)
    if not ok or not accepted then fail("Model unavailable in this client."); return end

    local attempts = 0
    local function poll()
        finish()
        if self.generation ~= generation or self.state ~= "loading" then return end
        attempts = attempts + 1
        if attempts >= 24 then fail("Model load timed out. Try Replay to retry."); return end
        C_Timer.After(0.5, poll)
    end
    finish()
    if self.state == "loading" then C_Timer.After(0.5, poll) end
end

function Preview:TogglePause()
    if self.state ~= "ready" then return end
    self.paused = not self.paused
    self.scene:SetPaused(self.paused, false)
    self.update(self.paused and "Paused" or "Playing", true, self.paused)
end

function Preview:Fit()
    if self.state == "ready" then self:SetView(0, self.angle) end
end

function Viewer.CreatePreview(parent, update)
    local scene = CreateFrame("ModelScene", nil, parent)
    scene:SetAllPoints()
    scene:EnableMouse(false)
    scene:Hide()
    if scene.SetAllowOverlappedModels then scene:SetAllowOverlappedModels(true) end
    scene:SetDrawLayer("ARTWORK")
    scene:SetCameraNearClip(0.01)
    scene:SetCameraFarClip(100)
    scene:SetCameraFieldOfView(2 * math.atan(6 / 16))
    scene:SetLightAmbientColor(1, 1, 1)
    scene:SetLightDiffuseColor(0, 0, 0)
    local actor = scene:CreateActor(nil, "EndCapperLibraryActorTemplate")
    actor:Show()
    return setmetatable({ scene = scene, actor = actor, update = update, generation = 0 }, Preview)
end
