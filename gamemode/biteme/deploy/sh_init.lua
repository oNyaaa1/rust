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

-- distance from the foundation origin to where each piece's origin sits
DEPLOY.ClassDist = {
    sent_foundation = 137.78, -- full spacing (neighbouring foundation)
    sent_wall = 72.9, -- half width = the edge
    sent_door = 72.9,
    sent_doorway = 72.9,
}

DEPLOY.DefaultDist = 72.9
-- extra yaw per class (tune per model: 0, 90, -90 or 180)
DEPLOY.ClassRot = {
    sent_foundation = 0,
    sent_wall = 90,
    sent_door = 90,
    sent_doorway = 90,
}

-- false = keep the foundation's own yaw instead of facing the edge
DEPLOY.ClassFaceEdge = {
    sent_foundation = false,
}

-- height above the foundation origin (positive = up). 14.04 = foundation top surface
DEPLOY.DefaultZ = 14.04
DEPLOY.ClassZ = {
    sent_foundation = 0,
    sent_wall = 0,
    sent_door = 0,
    sent_doorway = 0,
}

local EDGES = {
    North = {
        dir = Vector(1, 0, 0),
        yaw = 0
    },
    West = {
        dir = Vector(0, 1, 0),
        yaw = 90
    },
    East = {
        dir = Vector(0, -1, 0),
        yaw = -90
    },
    South = {
        dir = Vector(-1, 0, 0),
        yaw = 180
    },
}

-- centred over the foundation (0 = no edge offset)
DEPLOY.ClassDist.sent_ceiling = 0
-- height above the foundation origin: the wall's height plus the wall's own offset
-- start with a guess, then tune live (see below)
DEPLOY.ClassZ.sent_ceiling = 14.04 + 128
-- keep the foundation's yaw instead of facing an edge
DEPLOY.ClassFaceEdge.sent_ceiling = false
DEPLOY.ClassRot.sent_ceiling = 0
function DEPLOY:GetGround(ply)
    local ent = ply:GetGroundEntity()
    if IsValid(ent) and ent:GetClass() == "sent_foundation" then return ent end
    -- fallback for the client: hull trace straight down
    local pos = ply:GetPos()
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 4),
        endpos = pos - Vector(0, 0, 16),
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        filter = ply,
    })

    if IsValid(tr.Entity) and tr.Entity:GetClass() == "sent_foundation" then return tr.Entity end
end

function DEPLOY:GetSocket(ply, class)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local fallbackPos = tr.HitPos + tr.HitNormal * 32
    local foundation = self:GetGround(ply)
    if not IsValid(foundation) or foundation:GetClass() ~= "sent_foundation" then return fallbackPos, Angle(0, 0, 0), "none" end
    class = string.lower(class or "")
    local fYaw = foundation:GetAngles().y
    local yaw = math.NormalizeAngle(ply:EyeAngles().y - fYaw)
    local name
    if yaw >= -45 and yaw < 45 then
        name = "North"
    elseif yaw >= 45 and yaw < 135 then
        name = "West"
    elseif yaw >= -135 and yaw < -45 then
        name = "East"
    else
        name = "South"
    end

    local edge = EDGES[name]
    local dist = self.ClassDist[class] or self.DefaultDist
    local worldPos = LocalToWorld(edge.dir * dist, angle_zero, foundation:GetPos(), Angle(0, fYaw, 0))
    worldPos.z = foundation:GetPos().z + (self.ClassZ[class] or self.DefaultZ)
    local rot = self.ClassRot[class] or 0
    local ang
    if self.ClassFaceEdge[class] == false then
        ang = Angle(0, fYaw + rot, 0)
    else
        ang = Angle(0, fYaw + edge.yaw + rot, 0)
    end
    return worldPos, ang, name
end