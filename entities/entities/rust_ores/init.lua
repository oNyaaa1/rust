AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local matr = {"models/blacksnow/rust_rock", "models/blacksnow/rock_ore"}
function ENT:Initialize()
    self:SetModel("models/environment/ores/ore_node_stage1.mdl")
    self:SetSkin(math.random(1, 3))
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    self.firsthit = false
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
        phys:SetMass(50)
    end

    self.SetHealthz = 300
    self.SpawnTime = CurTime()
    self:NewWeakspot()
end

function ENT:SpawnFunction(ply, tr)
    if not tr.Hit then return end
    local ent = ents.Create("rust_ores")
    ent:SetPos(tr.HitPos + tr.HitNormal * 32)
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:RecoveryTime(pos)
    timer.Simple(60 * 5, function()
        if not util.IsInWorld(pos) then return end
        local ent = ents.Create("rust_ores")
        ent:SetPos(pos)
        ent:Spawn()
        ent:Activate()
    end)
end

function ENT:NewWeakspot()
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    local h = maxs.z - mins.z
    for _ = 1, 15 do
        local z = mins.z + h * math.Rand(0.25, 0.85)
        local center = self:LocalToWorld(Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, z))
        local dir = Angle(0, math.random(0, 359), 0):Forward()
        local tr = util.TraceLine({
            start = center + dir * 200,
            endpos = center,
            filter = function(e) return e == self end
        })

        if tr.Hit and tr.Entity == self then
            self:SetNW2Vector("Weakspot", tr.HitPos + tr.HitNormal * 2)
            return
        end
    end

    -- fallback if no trace hit: top of the rock
    --self:SetNW2Vector("Weakspot", self:LocalToWorld(Vector(0, 0, maxs.z)))
    self:SetNW2Vector("Weakspot", Vector(0, 0, maxs.z))
end

local placeHolster = {30, 60, 90, 120}
function ENT:OnTakeDamage(dmg)
    if not IsValid(self) then return end
    local attacker = dmg:GetAttacker()
    if not (IsValid(attacker) and attacker:IsPlayer()) then return end
    local ws = self:GetNW2Vector("Weakspot")
    if ws ~= vector_origin and attacker:GetEyeTrace().HitPos:DistToSqr(ws) < 25 * 25 then
        self.SetHealthz = (self.SetHealthz or 300) - 30 -- bonus on top of the normal 30
        self:NewWeakspot()
        attacker:EmitSound("farming/flare_hit.wav")
    else
        attacker:EmitSound("tools/rock_strike_1.mp3")
    end

    if self.SetHealthz == nil then self.SetHealthz = 300 end
    self.SetHealthz = self.SetHealthz - 30
    local ent = self
    if self:GetSkin() == 3 then
        local item = RustOfficial.GetItem("Stone")
        if ent.amount == nil then ent.amount = 0 end
        if ent.amount >= #placeHolster then ent.amount = 0 end
        local mathd = GRUST_GetItemFromWep(attacker, "Stone")
        ent.amount = ent.amount + 1
        if mathd >= item.Max then ent.amount = 1 end
        AddItemsToGmodCount(attacker, item.name, 100, nil, placeHolster[ent.amount])
    end

    if self.SetHealthz <= 240 then self:SetModel("models/environment/ores/ore_node_stage2.mdl") end
    if self.SetHealthz <= 150 then self:SetModel("models/environment/ores/ore_node_stage3.mdl") end
    if self.SetHealthz <= 60 then self:SetModel("models/environment/ores/ore_node_stage4.mdl") end
    if self.SetHealthz <= 0 then
        self:RecoveryTime(self:GetPos())
        self:Remove()
    end
end

function ENT:Think()
end

function ENT:Use(btn, ply)
end

function ENT:StartTouch(ent)
    return false
end

function ENT:EndTouch(ent)
    return false
end

function ENT:Touch(ent)
    return false
end