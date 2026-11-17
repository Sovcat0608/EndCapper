local _, E = ...

local corners={{-1,1},{-1,-1},{1,1},{1,-1}}

function E.RestoreArtworkPlacement(entry)
    local applied=entry.appliedArtworkPlacement
    if not applied then return end
    for frame,alpha in pairs(applied.alpha) do frame:SetAlpha(alpha) end
    for texture,original in pairs(applied.textures) do
        texture:ClearAllPoints()
        texture:SetPoint(unpack(original.point))
        texture:SetSize(original.width,original.height)
        if original.rotated then
            for index=1,4 do texture:SetVertexOffset(index,0,0) end
        end
    end
    entry.appliedArtworkPlacement=nil
end

local function measure(frame)
    if not frame or not frame.GetRegions then return end
    local textures={}
    local xmin,xmax,ymin,ymax
    for _,texture in ipairs({frame:GetRegions()}) do
        if texture.GetTexCoord and texture:IsShown() and
            (not texture.GetObjectType or texture:GetObjectType()~="MaskTexture") then
            local x,y=texture:GetCenter()
            local w,h=texture:GetSize()
            local point={texture:GetPoint(1)}
            if x and y and w>0 and h>0 and point[1]=="CENTER" then
                textures[#textures+1]={texture=texture,x=x,y=y,width=w,height=h,point=point}
                xmin=math.min(xmin or math.huge,x-w/2)
                xmax=math.max(xmax or -math.huge,x+w/2)
                ymin=math.min(ymin or math.huge,y-h/2)
                ymax=math.max(ymax or -math.huge,y+h/2)
            end
        end
    end
    if #textures==0 then return end
    return {textures=textures,x=(xmin+xmax)/2,y=(ymin+ymax)/2}
end

local function transform(piece,pivot,tuning,dx,dy,applied)
    local angle=math.rad(tuning.trailAngle)
    local sin,cos=math.sin(angle),math.cos(angle)
    local scale=tuning.trailSize/100
    local x,y=(piece.x-pivot.x)*scale,(piece.y-pivot.y)*scale
    local offsetX=pivot.x+cos*x-sin*y+dx-piece.x
    local offsetY=pivot.y+sin*x+cos*y+dy-piece.y
    local texture=piece.texture
    local point=piece.point
    local width,height=piece.width*scale,piece.height*scale
    texture:ClearAllPoints()
    texture:SetPoint(point[1],point[2],point[3],(point[4] or 0)+offsetX,(point[5] or 0)+offsetY)
    texture:SetSize(width,height)
    if tuning.trailAngle~=0 and texture.SetVertexOffset then
        -- Rotate the quad rather than its UVs. Atlas cells and alpha masks
        -- remain identical as the artwork and its animation play.
        for index,corner in ipairs(corners) do
            local vx,vy=corner[1]*width/2,corner[2]*height/2
            texture:SetVertexOffset(index,cos*vx-sin*vy-vx,sin*vx+cos*vy-vy)
        end
        piece.rotated=true
    end
    applied.textures[texture]=piece
end

function E.ApplyArtworkPlacement(entry,config,rows)
    local applied={alpha={},textures={}}
    local measurements={}
    local width,height=entry.art:GetSize()
    -- Capture pivots before transforming any artwork.
    for _,row in ipairs(rows) do
        if row.host and row.id~="art:base" then
            measurements[row.id]=measure(E.GetArtworkLayerFrame(entry,row))
        end
    end
    for _,row in ipairs(rows) do
        local tuning=E.GetArtworkPlacement(config,row)
        local frame=E.GetArtworkLayerFrame(entry,row)
        if tuning and frame then
            if row.authoredSize then tuning.trailSize=tuning.trailSize*100/row.authoredSize end
            local measured=measurements[row.id]
            local pivot=measurements[row.flipTarget or row.id]
            if measured and pivot and (tuning.trailSize~=100 or tuning.trailAngle~=0 or
                tuning.trailX~=0 or tuning.trailY~=0) then
                for _,piece in ipairs(measured.textures) do
                    transform(piece,pivot,tuning,tuning.trailX*width/225,tuning.trailY*height/150,applied)
                end
            end
            if tuning.trailOpacity~=100 then
                local region=row.opacityRegion and entry[row.owner][row.opacityRegion] or frame
                local alpha=region:GetAlpha()
                applied.alpha[region]=alpha
                region:SetAlpha(alpha*tuning.trailOpacity/100)
            end
        end
    end
    entry.appliedArtworkPlacement=applied
end
