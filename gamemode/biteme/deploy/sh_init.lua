DEPLOY = DEPLOY or {}
DEPLOY.FItem = function(ply, item)
    if CLIENT then return end
    local ent = ents.Create(item)
    if not IsValid(ent) then return end
    local tr = ply:GetEyeTrace()
    ent:SetPos(tr.HitPos + tr.HitNormal * 12)
    ent:Spawn()
    ent:Activate()
    return ent
end

function DEPLOY:SetSocket(ply, class, pos, ang)
    if CLIENT then return end
    if not IsValid(ply) or not pos or not ang then return end
    ply.Sockets = ply.Sockets or {}
    -- reject if too close to an existing socket
    for _, v in ipairs(ply.Sockets) do
        if pos:Distance(v[1]) <= 50 then return end
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    ply.Sockets[#ply.Sockets + 1] = {pos, class}
    return ent
end

function DEPLOY:GetSocket(ply)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local fallbackPos = tr.HitPos + tr.HitNormal * 32
    local foundation = ply:GetGroundEntity()
    if not IsValid(foundation) or foundation:GetClass() ~= "sent_foundation" then return fallbackPos, Angle(0, 0, 0), "none" end
    local mins, maxs = foundation:OBBMins(), foundation:OBBMaxs()
    local halfX = (maxs.x - mins.x) - 8
    local halfY = (maxs.y - mins.y) - 8
    -- yaw relative to the foundation, so rotated foundations work
    local yaw = math.NormalizeAngle(ply:EyeAngles().y - foundation:GetAngles().y)
    local offset, edgeYaw, name
    if yaw >= -45 and yaw < 45 then
        offset, edgeYaw, name = Vector(halfX, 0, 0), 0, "North"
    elseif yaw >= 45 and yaw < 135 then
        offset, edgeYaw, name = Vector(0, halfY, 0), 90, "West"
    elseif yaw >= -135 and yaw < -45 then
        offset, edgeYaw, name = Vector(0, -halfY, 0), -90, "East"
    else
        offset, edgeYaw, name = Vector(-halfX, 0, 0), 180, "South"
    end
    return foundation:LocalToWorld(offset), foundation:LocalToWorldAngles(Angle(0, edgeYaw, 0)), name
end