local _, E = ...

-- Registry of independently drawn artwork planes. Textures that share a host
-- (e.g. a glow and its crossfade partner) stay together as one layer.
local function artworkLayers(art)
    local rows = {}
    local function add(id, name, level, owner, host, motion)
        rows[#rows+1] = {id="art:"..id, name=name, level=level, owner=owner, host=host, motion=motion}
    end
    local artwork = E.artworkByID[art]
    if not artwork or not artwork.path then return rows end
    if not artwork.floatingOnly then
        add("base", "Base artwork", art=="skycutter" and 3 or 2, nil, "artLayer")
    end
    if artwork.overlay then add("overlay", "Ice overlay", 2, nil, "overlayLayer") end
    if E.RogueArtworks[art] then
        add("dagger", "Floating dagger", 4, "rogue", "daggerHost", "dagger")
        rows[#rows].authoredSize=E.RogueDaggerSize
    elseif E.MageArtworks[art] then
        add("book", "Floating book", 4, "mageBooks", "bookHost", "book")
        add("bookGlow", "Book emissions", 5, "mageBooks", "bookGlowHost", "book")
        add("sigil", "Floating sigil", 6, "mageSigils", "host", "sigil")
    elseif art=="skycutter" then
        add("boat", "Skycutter ship", 2, "skycutter", "host", "boat")
    elseif art=="violetSpire" or art=="soulbound" then
        add("crystal", "Floating crystal", 3, "arcane", "host", "crystal")
        rows[#rows].opacityRegion="crystal"
        add("crystalFinish", art=="violetSpire" and "Crystal emission and seal" or "Crystal emission",
            3, "arcane", "effectsHost", art=="soulbound" and "crystal" or nil)
    elseif E.TimeArtworks[art] then
        add("timeMiddle", art=="timelost" and "Clock gears" or "Flowing sand", 3, "timeworks", "middle")
        if art=="timelost" then add("timeFront", "Clock foreground", 4, "timeworks", "frontHost") end
        add("timeGlow", "Glyph emissions", 5, "timeworks", "glyphHost")
    end
    if E.MoltenArtworks[art] or E.WarlockArtworks[art] then add("molten", "Artwork emissions", 3, "molten", "host") end
    if E.FrostArtworks[art] then add("frost", "Ice and rune emissions", 3, "frost", "host") end
    if E.HaloArtworks[art] then add("halo", "Halo", 1, "halo", "host") end
    if art=="moonwell" then add("moonwell", "Pool and glyphs", 3, "moonwell", "host") end
    if art=="felwing" then add("glyphs", "Glyph emissions", 3, "glyphs", "host") end
    if art=="cryptgate" or art=="plaguewell" then add("liquid", "Falling liquid", 3, "liquid", "host") end
    return rows
end

function E.GetLayerStack(config, effects)
    local rows = artworkLayers(config.art)
    effects = effects or (E.GetLibraryRows and E.GetLibraryRows(config)) or {}
    for i, effect in ipairs(effects) do
        local level = effect.effectLayer=="back" and 1 or 3
        if effect.effectLayer~="back" then
            if effect.addedIndex then level=8+effect.addedIndex
            elseif E.MageArtworks[config.art] then level=7
            elseif config.art=="skycutter" or config.art=="violetSpire" or config.art=="soulbound" then level=4 end
        end
        rows[#rows+1] = {id=effect.builtin and "native:"..effect.builtin or "fx:"..effect.addedIndex,
            name=effect.name, level=level, effectIndex=i}
    end
    for i, row in ipairs(rows) do row.ordinal=i end
    table.sort(rows,function(a,b)
        if a.level==b.level then return a.ordinal<b.ordinal end
        return a.level<b.level
    end)
    local saved = config.layerState and config.layerState[config.art]
    if not saved then return rows end
    local ordered, byID = {}, {}
    for _, row in ipairs(rows) do byID[row.id]=row end
    for _, id in ipairs(saved.order or {}) do
        if byID[id] then
            ordered[#ordered+1]=byID[id]
            byID[id]=nil
        end
    end
    for _, row in ipairs(rows) do
        if byID[row.id] then
            ordered[#ordered+1]=row
        end
    end
    return ordered
end

local function editable(config)
    config.layerState=config.layerState or {}
    config.layerState[config.art]=config.layerState[config.art] or {}
    return config.layerState[config.art]
end

local placementDefaults={trailSize=100,trailAngle=0,trailX=0,trailY=0,trailOpacity=100}
local function placementDefault(row,key)
    if key=="trailSize" and row.authoredSize then return row.authoredSize end
    return placementDefaults[key]
end
local function artworkPlacementRow(row)
    return row and row.host and row.id~="art:base"
end

function E.GetArtworkPlacement(config,row)
    if not artworkPlacementRow(row) then return end
    local saved=config.layerState and config.layerState[config.art]
    local placement=saved and saved.placement or {}
    local result={}
    for key,default in pairs(placementDefaults) do
        local id=key=="trailOpacity" and row.id or (row.flipTarget or row.id)
        result[key]=placement[id] and placement[id][key] or placementDefault(row,key)
    end
    return result
end

local function placementValue(key,value)
    for _,spec in ipairs(E.devEffectFields) do
        if spec[1]==key and type(value)=="number" and value==value then
            return math.max(spec[3],math.min(spec[4],value))
        end
    end
end

function E.SetArtworkPlacement(config,row,key,value)
    if not E.devMode or not artworkPlacementRow(row) then return end
    value=placementValue(key,value)
    if value==nil then return end
    local id=key=="trailOpacity" and row.id or (row.flipTarget or row.id)
    local saved=editable(config)
    saved.placement=saved.placement or {}
    local tuning=saved.placement[id] or {}
    tuning[key]=value~=placementDefault(row,key) and value or nil
    saved.placement[id]=next(tuning) and tuning or nil
end

function E.ResetArtworkPlacement(config,row)
    for key in pairs(placementDefaults) do E.SetArtworkPlacement(config,row,key,placementDefault(row,key)) end
end

function E.SetLayerFlip(config,id,enabled)
    if not E.devMode then return end
    for _,row in ipairs(E.GetLayerStack(config)) do
        if row.id==id then
            local saved=editable(config)
            saved.flips=saved.flips or {}
            saved.flips[row.flipTarget or id]=enabled==true or nil
            if not next(saved.flips) then saved.flips=nil end
            return true
        end
    end
end

function E.MoveStudioLayer(config,id,change)
    if not E.devMode or (change~=1 and change~=-1) then return end
    local rows=E.GetLayerStack(config)
    for index,row in ipairs(rows) do
        local neighbor=rows[index+change]
        if row.id==id and neighbor then
            rows[index],rows[index+change]=neighbor,row
            local order={}
            for i,layer in ipairs(rows) do order[i]=layer.id end
            editable(config).order=order
            return true
        end
    end
end

function E.GetLayerMotion(config,id)
    local saved=config.layerState and config.layerState[config.art]
    return saved and saved.follow and saved.follow[id]
end

function E.SetLayerMotion(config,id,source)
    if not E.devMode then return end
    local effect, valid
    for _,row in ipairs(E.GetLayerStack(config)) do
        if row.id==id and row.effectIndex then effect=true end
        if row.id==source and row.motion then valid=true end
    end
    if not effect or (source and not valid) then return end
    local saved=editable(config)
    saved.follow=saved.follow or {}
    saved.follow[id]=source
    if not next(saved.follow) then saved.follow=nil end
end

function E.MoveStudioEffectToEdge(config,id,behind)
    local saved=config.layerState and config.layerState[config.art]
    if not saved or not saved.order then return end
    local order={}
    for _,row in ipairs(E.GetLayerStack(config)) do
        if row.id~=id then order[#order+1]=row.id end
    end
    table.insert(order,behind and 1 or #order+1,id)
    saved.order=order
end

function E.RemoveStudioLayerIndex(config,index)
    local saved=config.layerState and config.layerState[config.art]
    if not saved then return end
    local function shifted(id)
        local number=tonumber(id:match("^fx:(%d+)$"))
        if not number or number<index then return id end
        if number>index then return "fx:"..(number-1) end
    end
    local order={}
    for _,id in ipairs(saved.order or {}) do
        local key=shifted(id)
        if key then order[#order+1]=key end
    end
    if saved.order then saved.order=order end
    for _,field in ipairs({"follow","flips"}) do
        local values={}
        for id,value in pairs(saved[field] or {}) do
            local key=shifted(id)
            if key then values[key]=value end
        end
        saved[field]=next(values) and values or nil
    end
end

function E.NormalizeLayerState(value,added)
    local result={}
    value=type(value)=="table" and value or {}
    for art,saved in pairs(value) do
        local artwork=E.artworkByID[art]
        if artwork and artwork.path and type(saved)=="table" then
            local rows=E.GetLayerStack({art=art,addedEffects=added})
            local available, seen, order, follow, flips={},{},{},{},{}
            for _,row in ipairs(rows) do available[row.id]=row end
            if type(saved.order)=="table" then
                for _,id in ipairs(saved.order) do
                    if available[id] and not seen[id] then
                        seen[id]=true
                        order[#order+1]=id
                    end
                end
            end
            if type(saved.follow)=="table" then
                for _,row in ipairs(rows) do
                    local source=saved.follow[row.id]
                    if row.effectIndex and available[source] and available[source].motion then follow[row.id]=source end
                end
            end
            if type(saved.flips)=="table" then
                for _,row in ipairs(rows) do
                    if not row.flipTarget and saved.flips[row.id]==true then flips[row.id]=true end
                end
            end
            local placement={}
            if type(saved.placement)=="table" then
                for _,row in ipairs(rows) do
                    local tuning=saved.placement[row.id]
                    if artworkPlacementRow(row) and type(tuning)=="table" then
                        local values={}
                        for key,default in pairs(placementDefaults) do
                            if key=="trailOpacity" or not row.flipTarget then
                                local value=placementValue(key,tuning[key])
                                if value~=nil and value~=placementDefault(row,key) then values[key]=value end
                            end
                        end
                        if next(values) then placement[row.id]=values end
                    end
                end
            end
            if #order>0 or next(follow) or next(flips) or next(placement) then
                result[art]={order=#order>0 and order or nil,follow=next(follow) and follow or nil,
                    flips=next(flips) and flips or nil,placement=next(placement) and placement or nil}
            end
        end
    end
    -- Only the factory effect lists have these indices. A player's own list
    -- (including an explicitly empty one) keeps its own ordering and links.
    if not value.gloomfang and not (added and added.gloomfang) then
        result.gloomfang={order={"art:base","fx:2","art:dagger","fx:1"},
            follow={["fx:4"]="art:dagger",["fx:6"]="art:dagger"}}
    end
    if not value.venomveil and not (added and added.venomveil) then
        result.venomveil={order={"art:base","art:dagger","fx:3","fx:4","fx:1","fx:5","fx:6","fx:2"},
            follow={["fx:2"]="art:dagger",["fx:3"]="art:dagger"}}
    end
    return result
end

function E.GetArtworkLayerFrame(entry,row)
    local owner=row.owner and entry[row.owner] or entry
    return row.host and owner[row.host]
end

local active={}
local driver
function E.StopLayerMotion(entry)
    active[entry]=nil
    if driver and not next(active) then driver:Hide() end
end

local function motionOffset(entry,row)
    local s=entry[row.owner]
    if not s or not s.startedAt then return 0 end
    local group, legs, amplitude
    local phase=(s.elapsed+math.max(0,GetTime()-s.startedAt))%6
    if row.motion=="dagger" then
        return E.GetDaggerHoverFraction(s)*s.hoverAmplitude
    elseif row.motion=="boat" then
        group,legs,amplitude=s.motion,s.translations,s.hoverAmplitude
    elseif row.motion=="book" then
        group,legs,amplitude=s.motions[1].group,s.motions[1].legs,s.hoverAmplitude
    elseif row.motion=="sigil" then
        group,legs,amplitude=s.hover,s.hoverLegs,s.hoverAmplitude
        phase=(s.hoverStartPhase+math.max(0,GetTime()-s.startedAt))%6
    elseif row.motion=="crystal" then
        group,amplitude=s.motionGroup,s.hoverAmplitude
        legs={s.translations[1].animation,s.translations[3].animation}
    end
    if not group or not amplitude then return 0 end
    local nativeElapsed=group.GetElapsed and group:GetElapsed()
    if nativeElapsed then phase=nativeElapsed%6 end
    local rising=phase<3
    local leg=legs[rising and 1 or 2]
    local t=(phase%3)/3
    local eased=leg.GetSmoothProgress and leg:GetSmoothProgress() or t*t*(3-2*t)
    return amplitude*(rising and (2*eased-1) or (1-2*eased))
end

local function tick(entry,links)
    local offsets={}
    for _,link in ipairs(links) do
        local source=link.source
        if offsets[source]==nil then offsets[source]=motionOffset(entry,source) end
        local slot=link.slot
        local a=slot.layerAnchor
        local x,y=a[4],a[5]+offsets[source]
        if link.daggerX then
            local s=entry.rogue
            local angle=s.hoverAmplitude>0 and math.rad(s.topDegrees*offsets[source]/s.hoverAmplitude) or 0
            local dx,dy=a[4]-link.daggerX,a[5]-link.daggerY
            local cos,sin=math.cos(angle),math.sin(angle)
            x=x+(cos-1)*dx-sin*dy
            y=y+sin*dx+(cos-1)*dy
        end
        if slot.layerY~=y or slot.layerX~=x then
            slot.scene:SetPoint(a[1],a[2],a[3],x,y)
            slot.layerX,slot.layerY=x,y
        end
    end
end

function E.ResumeLayerMotion(entry)
    E.StopLayerMotion(entry)
    local links=entry.layerMotion
    if not links or #links==0 or not entry.frame:IsVisible() then return end
    if not driver then
        driver=CreateFrame("Frame")
        driver:SetScript("OnUpdate",function()
            -- These are addon-owned visual frames. Keep an existing attachment
            -- in motion during combat even though the editor is locked.
            for cap,items in pairs(active) do tick(cap,items) end
        end)
    end
    active[entry]=links
    tick(entry,links)
    driver:Show()
end

function E.ApplyLayerStack(entry,config)
    local saved=config.layerState and config.layerState[config.art]
    E.StopLayerMotion(entry)
    entry.layerMotion=nil
    if entry.handle then entry.handle:SetFrameLevel(entry.frame:GetFrameLevel()+5) end
    if not saved or not entry.owned then return end
    local rows=E.GetLayerStack(config)
    if saved.placement and E.ApplyArtworkPlacement then E.ApplyArtworkPlacement(entry,config,rows) end
    local level=entry.frame:GetFrameLevel()
    local byID, native, links={},{},{}
    local function include(effect,id)
        if effect and effect.nativeWanted and effect.nativeSmoke and id then
            native[id]=effect.nativeSmoke.slots
        end
    end
    for _,effect in pairs({entry,entry.secondaryEffect,entry.hiltEyeTrail,entry.warlockEffect}) do
        if effect.nativeLayerID then include(effect,"native:"..effect.nativeLayerID) end
    end
    for id,effect in pairs(entry.undercityEffects or {}) do include(effect,"native:"..id) end
    for index,effect in ipairs(entry.addedEffectSlots or {}) do include(effect,"fx:"..index) end
    for _,row in ipairs(rows) do byID[row.id]=row end
    for i,row in ipairs(rows) do
        local frame=E.GetArtworkLayerFrame(entry,row)
        local rank=level+i*2
        if frame and saved.order then frame:SetFrameLevel(rank) end
        local source=saved.follow and byID[saved.follow[row.id]]
        for _,slot in ipairs(native[row.id] or {}) do
            if saved.order then slot.scene:SetFrameLevel(rank) end
            if source and slot.layerAnchor and slot.layerAnchor[5] then
                local link={slot=slot,source=source}
                if source.motion=="dagger" then
                    local s=entry.rogue
                    local _,_,_,hx,hy=s.daggerHost:GetPoint(1)
                    local _,_,_,tx,ty=s.dagger:GetPoint(1)
                    link.daggerX,link.daggerY=hx+(tx or 0),hy+(ty or 0)
                end
                links[#links+1]=link
            end
        end
    end
    if saved.order and entry.handle then entry.handle:SetFrameLevel(level+#rows*2+1) end
    entry.layerMotion=links
    E.ResumeLayerMotion(entry)
end
