local _,E=...

local function secret(value)
    return (issecretvalue and issecretvalue(value)) or (type(value)=="table" and issecrettable and issecrettable(value))
end
local function component(value)
    value=tostring(value);return #value..":"..value
end
local function layoutKeys(info)
    if type(info)~="table" or secret(info) or type(info.layouts)~="table" or secret(info.layouts) or secret(info.activeLayout) then return end
    if type(info.activeLayout)~="number" then return end
    -- GetLayouts returns saved layouts only. activeLayout indexes Blizzard's
    -- combined preset + saved list (EditModeManager:UpdateLayoutInfo).
    local manager=EditModePresetLayoutManager
    if type(manager)~="table" or secret(manager) or type(manager.presetLayoutInfo)~="table" or secret(manager.presetLayoutInfo) then return end
    local layouts={}
    for _,layout in ipairs(manager.presetLayoutInfo) do layouts[#layouts+1]=layout end
    for _,layout in ipairs(info.layouts) do layouts[#layouts+1]=layout end
    local guid=UnitGUID and UnitGUID("player")
    if secret(guid) or type(guid)~="string" then guid=nil end
    local keys,count={scopes={},presetCount=#manager.presetLayoutInfo,characterGUID=guid},0
    for index,layout in ipairs(layouts) do
        if type(layout)~="table" or secret(layout) or secret(layout.layoutName) or secret(layout.layoutType) or secret(layout.interfaceStyle) then return end
        if type(layout.layoutName)~="string" or type(layout.layoutType)~="number" then return end
        local scope="account"
        if not Enum or not Enum.EditModeLayoutType then return end
        if layout.layoutType==Enum.EditModeLayoutType.Character then
            if not guid then return end
            scope=guid
        end
        local prefix=component(scope)..component(layout.layoutType)..component(layout.interfaceStyle or "default")
        keys.scopes[index]=prefix
        keys[index]=prefix..component(layout.layoutName)
        count=count+1
    end
    return keys,info.activeLayout,count
end

function E.SavePositionProfile(key)
    key=key or E.activePositionLayout
    if not key or not EndCapperDB or E.positionLayoutUnavailable then return end
    for _,db in ipairs({EndCapperDB,EndCapperDB.otherMode}) do
        db.positionProfiles[key]=E.CapturePosition(db)
    end
end

local function defaultPosition(db)
    if db.mode=="corner" then return E.NormalizePosition({}) end
    return E.NormalizePosition({left={frameBottom=false},right={frameBottom=false}})
end

function E.ReconcilePositionLayout()
    if E.switchingPositionLayout then return false end
    if not C_EditMode or not C_EditMode.GetLayouts then E.positionLayoutUnavailable=true;return true,false end
    local ok,info=pcall(C_EditMode.GetLayouts)
    if not ok then E.positionLayoutUnavailable=true;return true,false end
    local keys,index,count=layoutKeys(info)
    local key=keys and keys[index]
    -- Metadata must never gate artwork/control rendering or cancel a draft.
    -- Keep the last binding, but do not write placement to an unknown layout.
    if not key then E.positionLayoutUnavailable=true;return true,false end
    E.positionLayoutUnavailable=nil
    local previous=E.positionLayoutKeys
    local activeDeleted=false
    -- Names are the available stable identity; indices shift after deletion.
    -- Recognize an in-session rename only when exactly one key changed.
    if previous and #previous==count then
        local removed,added={},{};local oldSet,newSet={},{}
        for _,v in ipairs(previous) do oldSet[v]=true end
        for _,v in ipairs(keys) do newSet[v]=true end
        for v in pairs(oldSet) do if not newSet[v] then removed[#removed+1]=v end end
        for v in pairs(newSet) do if not oldSet[v] then added[#added+1]=v end end
        local renamedIndex
        if #removed==1 and #added==1 then
            for i,oldKey in ipairs(previous) do
                if oldKey==removed[1] and keys[i]==added[1] and previous.scopes[i]==keys.scopes[i] then renamedIndex=i end
            end
        end
        if renamedIndex then
            local from,to=removed[1],added[1]
            if from==E.activePositionLayout then E.SavePositionProfile() end
            for _,db in ipairs(E.draft and {EndCapperDB,E.draft} or {EndCapperDB}) do
                for _,mode in ipairs({db,db.otherMode}) do
                    local records=mode.positionProfiles
                    if records[from] then records[to]=records[from];records[from]=nil end
                end
            end
            if from==E.activePositionLayout then E.activePositionLayout=to end
        end
    end
    -- Only prune saved layouts seen disappearing in this character's session.
    if previous and previous.characterGUID==keys.characterGUID and
        #previous-previous.presetCount>count-keys.presetCount then
        local current={}
        for _,v in ipairs(keys) do current[v]=true end
        for i=previous.presetCount+1,#previous do
            local removed=previous[i]
            if not current[removed] then
                for _,db in ipairs(E.draft and {EndCapperDB,E.draft} or {EndCapperDB}) do
                    db.positionProfiles[removed]=nil
                    if db.otherMode then db.otherMode.positionProfiles[removed]=nil end
                end
                if removed==E.activePositionLayout then activeDeleted=true end
            end
        end
    end
    if key==E.activePositionLayout then
        E.positionLayoutKeys=keys;E.positionLayoutIndex=index;return true,false
    end
    local old=E.activePositionLayout
    if old and not activeDeleted then E.SavePositionProfile(old) end
    if old then E.Cancel() end
    local created=previous and count>#previous
    if created then for _,existing in ipairs(previous) do if existing==key then created=false end end end
    for _,db in ipairs({EndCapperDB,EndCapperDB.otherMode}) do
        local profiles=db.positionProfiles
        local profile=profiles[key]
        if not profile then
            if (not old and next(profiles)==nil) or created then profile=E.CapturePosition(db)
            else profile=defaultPosition(db) end
            profiles[key]=profile
        end
        E.RestorePosition(db,profile)
    end
    if E.CaptureNativePairSpacing then E.CaptureNativePairSpacing() end
    E.activePositionLayout=key;E.positionLayoutKeys=keys;E.positionLayoutIndex=index
    E.switchingPositionLayout=true
    if old and E.panel then E.panel:Hide() end
    E.switchingPositionLayout=false
    return true,true
end
