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

DEPLOY.AllowedOn = {
    sent_foundation = nil, -- nil = anything (current behaviour)
    sent_ceiling = {
        sent_stairs = true,
        sent_wall = true,
        sent_door = true,
        sent_doorway = true,
        sent_ceiling = true,
        sent_foundation = false,
    },
}

function DEPLOY:SetSocket(ply, class, pos, ang)
    if CLIENT then return end
    if not IsValid(ply) or not pos or not ang then return end
    ply.Sockets = ply.Sockets or {}
    -- reject if too close to an existing socket
    for _, v in ipairs(ply.Sockets) do
        if pos:Distance(v[1]) <= 50 and class == "sent_foundation" then return end
    end

    -- everything except a foundation must be placed while standing on a foundation or ceiling
    if class ~= "sent_foundation" then
        local base = self:GetGround(ply)
        if not IsValid(base) then return end
        -- also enforce the AllowedOn rules server-side
        local allowed = self.AllowedOn[base:GetClass()]
        if allowed and not allowed[class] then return end
    end

    -- doors only go where a doorway already exists (closest one wins)
    local doorway
    if class == "sent_door" then
        local nearestDist = math.huge
        for _, e in ipairs(ents.FindByClass("sent_doorway")) do
            local d = pos:Distance(e:GetPos())
            if d < nearestDist then doorway, nearestDist = e, d end
        end

        if not IsValid(doorway) or nearestDist > 80 then return end
        if IsValid(doorway.Door) then -- already has a door
            return
        end
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    if IsValid(doorway) then doorway.Door = ent end
    ply.Sockets[#ply.Sockets + 1] = {pos, class}
    return ent
end

-- distance from the foundation origin to where each piece's origin sits
DEPLOY.ClassDist = {
    sent_foundation = 132.78, -- full spacing (neighbouring foundation)
    sent_wall = 72.9, -- half width = the edge
    sent_door = 72.9,
    sent_doorway = 72.9,
    sent_stairs = 0,
    sent_ceiling = 0,
}

DEPLOY.DefaultDist = 72.9
-- extra yaw per class (tune per model: 0, 90, -90 or 180)
DEPLOY.ClassRot = {
    sent_foundation = 0,
    sent_wall = 90,
    sent_door = 90,
    sent_doorway = 90,
    sent_stairs = 90,
    sent_ceiling = 0,
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
    sent_stairs = 0,
    sent_ceiling = 0,
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

DEPLOY.CeilingZ = {
    sent_stairs = 0,
    sent_wall = 0,
    sent_door = 0,
    sent_doorway = 0,
    sent_ceiling = 128,
}

-- centred over the foundation (0 = no edge offset)
DEPLOY.ClassDist.sent_ceiling = 0
-- height above the foundation origin: the wall's height plus the wall's own offset
-- start with a guess, then tune live (see below)
DEPLOY.ClassZ.sent_ceiling = 14.04 + 128
-- keep the foundation's yaw instead of facing an edge
DEPLOY.ClassFaceEdge.sent_ceiling = false
DEPLOY.ClassRot.sent_ceiling = 0
DEPLOY.BaseClasses = {
    sent_foundation = true,
    sent_ceiling = true,
}

function DEPLOY:GetGround(ply)
    local ent = ply:GetGroundEntity()
    if IsValid(ent) and self.BaseClasses[ent:GetClass()] then return ent end
    -- fallback for the client: hull trace straight down
    local pos = ply:GetPos()
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 4),
        endpos = pos - Vector(0, 0, 16),
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        filter = ply,
    })

    if IsValid(tr.Entity) and self.BaseClasses[tr.Entity:GetClass()] then return tr.Entity end
end

DEPLOY.ClassSide = {
    sent_door = -25, -- start at 0, then nudge until it sits in the middle of the frame
}

function DEPLOY:GetSocket(ply, class)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local fallbackPos = tr.HitPos + tr.HitNormal * 32
    local base = self:GetGround(ply)
    if not IsValid(base) then return fallbackPos, Angle(0, ply:GetAngles().yaw, 0), "none" end
    class = string.lower(class or "")
    local baseClass = base:GetClass()
    -- restrict what can be placed on this base
    local allowed = self.AllowedOn[baseClass]
    if allowed and not allowed[class] then return fallbackPos, Angle(0, ply:GetAngles().yaw, 0), "none" end
    local fYaw = base:GetAngles().y
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
    local side = self.ClassSide[class] or 0
    local perp = Vector(-edge.dir.y, edge.dir.x, 0) -- 90 degrees to the edge direction
    local worldPos = LocalToWorld(edge.dir * dist + perp * side, angle_zero, base:GetPos(), Angle(0, fYaw, 0))
    if baseClass == "sent_ceiling" then
        worldPos.z = base:GetPos().z + (self.CeilingZ[class] or self.DefaultZ)
    else
        worldPos.z = base:GetPos().z + (self.ClassZ[class] or self.DefaultZ)
    end

    local rot = self.ClassRot[class] or 0
    local ang
    if self.ClassFaceEdge[class] == false then
        ang = Angle(0, fYaw + rot, 0)
    else
        ang = Angle(0, fYaw + edge.yaw + rot, 0)
    end
    return worldPos, ang, name
end