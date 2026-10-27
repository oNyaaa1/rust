DEPLOY = DEPLOY or {}
DEPLOY.FItem = function(ply, item, pos, ang)
    if CLIENT then return end
    local ent = ents.Create(item)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    return ent
end

DEPLOY.AllowedOn = {
    sent_foundation = nil, -- nil = anything (current behaviour)
    sent_stairs = {
        sent_stairs = true,
        sent_wall = true,
        sent_door = true,
        sent_doorway = true,
        sent_ceiling = true,
        sent_foundation = false,
        sent_doorwayl = true,
    },
    sent_ceiling = {
        sent_stairs = true,
        sent_wall = true,
        sent_door = true,
        sent_doorway = true,
        sent_ceiling = true,
        sent_foundation = false,
        sent_doorwayl = true,
    },
    sent_doorwayl = {
        sent_garagedoor = true,
        sent_doorwayl = false,
        sent_wall = false,
        sent_door = false,
    }
}

DEPLOY.ClassDist = {
    sent_foundation = 132.78, -- full spacing (neighbouring foundation)
    sent_wall = 72.9, -- half width = the edge
    sent_door = 72.9,
    sent_doorway = 72.9,
    sent_stairs = 0,
    sent_ceiling = 0,
    sent_garagedoor = 72.9,
    sent_doorwayl = 72.9,
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
    sent_garagedoor = 90,
    sent_doorwayl = 90,
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
    sent_garagedoor = 0,
    sent_doorwayl = 0,
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
    sent_garagedoor = 0,
    sent_doorwayl = 0,
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
    sent_wall = true,
}

DEPLOY.ClassSide = {
    sent_door = -25, -- start at 0, then nudge until it sits in the middle of the frame
}

DEPLOY.GarageOffset = Vector(0, 0, 0)
function DEPLOY:GetDoorwayL(ply)
    -- distance from the foundation origin to where each piece's origin sits
    local tr = ply:GetEyeTrace()
    local best, bestDist = nil, 150
    for _, e in ipairs(ents.FindByClass("sent_doorwayl")) do
        local d = tr.HitPos:Distance(e:GetPos())
        if d < bestDist then best, bestDist = e, d end
    end
    return best
end

function DEPLOY:BlockedByDoorwayL(class, pos)
    if class ~= "sent_wall" then return false end
    for _, e in ipairs(ents.FindByClass("sent_doorwayl")) do
        if pos:Distance(e:GetPos()) < 60 then return true end
    end
    return false
end

local EDGE_CLASSES = {
    sent_wall = true,
    sent_doorway = true,
    sent_doorwayl = true,
}

function DEPLOY:EdgeOccupied(class, pos)
    if not EDGE_CLASSES[class] then return false end
    for c in pairs(EDGE_CLASSES) do
        for _, e in ipairs(ents.FindByClass(c)) do
            local p = e:GetPos()
            if math.abs(p.z - pos.z) < 64 and (p - pos):Length2D() < 40 then return true end
        end
    end
    return false
end

function DEPLOY:GetGround(ply, class)
    local ent = ply:GetGroundEntity()
    if IsValid(ent) and ent:GetClass() == "worldspawn" and class == "sent_foundation" then return ent, ply:GetAngles(), "worldspawn" end
    if IsValid(ent) and ent:GetClass() == "worldspawn" and class == "sent_ceiling" then return ent, ply:GetAngles(), "none" end
    -- fallback for the client: hull trace straight down
    local pos = ply:GetPos()
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 4),
        endpos = pos - Vector(0, 0, 16),
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        filter = ply,
    })

    if IsValid(ent) and self.BaseClasses[ent:GetClass()] then return tr.Entity, ply:GetAngles(), "none" end
    if IsValid(tr.Entity) and self.BaseClasses[tr.Entity:GetClass()] then return tr.Entity, ply:GetAngles(), "worldspawn" end
end

function DEPLOY:SetSocket(ply, class, pos, ang)
    if CLIENT then return end
    if not IsValid(ply) or not pos or not ang then return end
    ply.Sockets = ply.Sockets or {}
    for _, v in ipairs(ply.Sockets) do
        if pos:Distance(v[1]) <= 50 and class == "sent_foundation" then return end
    end

    if self:EdgeOccupied(class, pos) then
        print("edge occupied", class)
        return
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

function DEPLOY:GetSocket(ply, class)
    if not IsValid(ply) then return end
    class = string.lower(class or "")
    local tr = ply:GetEyeTrace()
    local entTRR = tr.Entity ~= nil and tr.Entity:GetClass() ~= "worldspawn" and tr.Entity
    local base = entTRR or DEPLOY:GetGround(ply, class)
    local ent = tr.Entity
    if IsValid(ent) and not ent:IsWorld() then
        local top = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z))
        top.z = top.z + (self.ClassZ[class] or self.DefaultZ)
        return top, Angle(0, ent:GetAngles().y, 0), "upper"
    end

    local fallbackPos = tr.HitPos + tr.HitNormal * 32
    local fallbackAng = Angle(0, ply:GetAngles().yaw, 0)
    if class == "sent_garagedoor" then
        local door = self:GetDoorwayL(ply)
        if not IsValid(door) then return fallbackPos, fallbackAng, "none" end
        local pos, ang = LocalToWorld(self.GarageOffset, Angle(0, 0, 0), door:GetPos(), door:GetAngles())
        return pos, ang, "doorwayl"
    end

    if not IsValid(base) or not (self.BaseClasses and self.BaseClasses[base:GetClass()]) then
        if class == "sent_foundation" then return tr.HitPos, fallbackAng, "worldspawn" end
        if not IsValid(ent) then return tr.HitPos, ply:GetAngles(), "none" end
    end

    local baseClass = base:GetClass()
    local allowed = self.AllowedOn[baseClass]
    if allowed and not allowed[class] then return fallbackPos, fallbackAng, "none" end
    -- pick the edge from where you are aiming on the base
    local fYaw = base:GetAngles().y
    local lp = base:WorldToLocal(tr.HitPos)
    local name
    if math.abs(lp.x) > math.abs(lp.y) then
        name = lp.x > 0 and "North" or "South"
    else
        name = lp.y > 0 and "West" or "East"
    end

    local edge = EDGES[name]
    local dist = self.ClassDist[class] or self.DefaultDist
    local side = self.ClassSide[class] or 0
    local perp = Vector(-edge.dir.y, edge.dir.x, 0)
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

    if self:BlockedByDoorwayL(class, worldPos) or self:EdgeOccupied(class, worldPos) then return fallbackPos, fallbackAng, "none" end
    return worldPos, ang, name
end