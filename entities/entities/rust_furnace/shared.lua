ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.Model = "models/deployable/furnace.mdl"
function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "On")
end