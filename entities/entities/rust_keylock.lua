AddCSLuaFile()
ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "KeyLock"
ENT.Radius = 625 ^ 2
ENT.Models = "models/deployable/key_lock.mdl"
ENT.Authorized = {}
if SERVER then
    function ENT:Initialize()
        self:SetModel("models/deployable/key_lock.mdl")
        self:PhysicsInitStatic(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    end

    function ENT:Use(act, ply)
    end

    function ENT:OnRemove()
        local p = self:GetParent()
        if IsValid(p) then
            p.Lock = nil
            p:SetNWBool("HasLock", false)
        end
    end
else
end