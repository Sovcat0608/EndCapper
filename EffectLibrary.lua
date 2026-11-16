local _, E = ...
E.EffectLibrary=E.EffectLibrary or {}
local Viewer=E.EffectLibrary
local entries, byID

local function indexCatalog()
    entries, byID = {}, {}
    for idText, path in Viewer.catalog:gmatch("(%d+);([^\n]*)\n") do
        local id = tonumber(idText)
        local preset = Viewer.presets[id]
        local basename = path:match("([^/]+)%.m2$") or ("Model " .. idText)
        local name = preset and preset.name or (basename:gsub("[_%-]+", " "):gsub("^%l", string.upper))
        local entry = { id = id, path = path, name = name, preset = preset }
        entry.nameKey = name:lower()
        entry.searchKey = (entry.nameKey .. " " .. path .. " " .. (preset and preset.aliases or "")):lower()
        entries[#entries + 1], byID[id] = entry, entry
    end
    table.sort(entries, function(a, b)
        if (a.preset ~= nil) ~= (b.preset ~= nil) then return a.preset ~= nil end
        if a.nameKey ~= b.nameKey then return a.nameKey < b.nameKey end
        return a.id < b.id
    end)
end

function Viewer.Search(query)
    if not entries then indexCatalog() end
    query = query:lower():match("^%s*(.-)%s*$")
    if query == "" then return entries end
    if query:match("^%d+$") then
        local id = tonumber(query)
        if id < 1 or id > 4294967295 then return {} end
        return { byID[id] or { id = id, name = "Model " .. id, path = "" } }
    end

    local terms, matches = {}, {}
    for term in query:gmatch("%S+") do terms[#terms + 1] = term end
    for _, entry in ipairs(entries) do
        local matchesAll = true
        for _, term in ipairs(terms) do
            if not entry.searchKey:find(term, 1, true) then
                matchesAll = false
                break
            end
        end
        if matchesAll then matches[#matches + 1] = entry end
    end
    return matches
end
