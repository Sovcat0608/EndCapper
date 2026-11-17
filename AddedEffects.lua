local _,E=...
function E.StopAddedEffects(entry)
    for _,effect in ipairs(entry.addedEffectSlots or {}) do
        E.StopNativeSmoke(effect)
    end
end
function E.PlayAddedEffects(entry)
    for _,effect in ipairs(entry.addedEffectSlots or {}) do
        E.PlayNativeSmoke(effect)
    end
end
function E.UpdateAddedEffects(entry,config)
    local rows=E.GetAddedEffects(config)
    if #rows>0 then entry.addedEffectSlots=entry.addedEffectSlots or {} end
    for i,row in ipairs(rows) do
        local effect=entry.addedEffectSlots[i] or {frame=entry.frame,art=entry.art}
        entry.addedEffectSlots[i]=effect
        effect.side=entry.side;effect.alpha=entry.alpha;effect.addedIndex=i
        effect.effectsEnabled=config.effects~=false;effect.nativeWanted=effect.effectsEnabled and config.nativeSmoke~=false
        effect.libraryLevel=row.effectLayer=="back" and 1 or 8+i
        effect.libraryProfile={fileID=row.fileID,name=row.name,animation=row.animation,modelScale=row.scale,
            emitterX=row.originX,emitterY=row.originY,emitterZ=row.originZ,cameraAzimuth=row.azimuth,
            cameraElevation=row.elevation,desaturation=row.desaturation,centered=true,naturalEdges=true,opacity=1}
        local c={art=config.art,flip=config.flip,effectLayer=row.effectLayer,layerState=config.layerState}
        for _,spec in ipairs(E.devEffectFields) do c[spec[1]]=row[spec[1]] end
        if effect.nativeWanted then effect.nativeActive=E.UpdateNativeSmoke(effect,c)
        else E.StopNativeSmoke(effect) end
    end
    for i=#rows+1,#(entry.addedEffectSlots or {}) do
        local effect=entry.addedEffectSlots[i];effect.effectsEnabled=false;effect.nativeWanted=false
        E.StopNativeSmoke(effect)
        -- Release the model while keeping the small scene pool reusable.
        local state=effect.nativeSmoke
        if state and state.profileID then
            state.generation=state.generation+1;state.profileID=nil;state.profile=nil;state.polling=false
            for _,slot in ipairs(state.slots) do slot.actor.endCapperOnModelLoaded=nil;slot.actor:ClearModel() end
        end
    end
end
