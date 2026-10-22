include("shared.lua")
function ENT:PlaceAndWeird(model, pos)
    local ent = ents.Create("prop_physics")
    ent:SetModel(model)
    ent:SetPos(self:GetPos() + pos)
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:Initialize()
    self:SetModel("models/deployable/turret_base.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self.pitch = self:PlaceAndWeird("models/deployable/turret_pitch.mdl", Vector(0, 0, 5))
    self.yaw = self:PlaceAndWeird("models/deployable/turret_yaw.mdl", Vector(0, 0, 30))
end