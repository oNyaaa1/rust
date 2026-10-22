AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Wall"
ENT.Category = ""
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Models = "models/environment/misc/loot_bag.mdl"
if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Models)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then phys:Wake() end
	end

	function ENT:SpawnFunction(ply, tr)
		if not tr.Hit then return end
		local ent = ents.Create("zombie_tree1")
		ent:SetPos(tr.HitPos + tr.HitNormal * 32)
		ent:Spawn()
		ent:Activate()
		return ent
	end

	function ENT:Think()
	end

	function ENT:OnTakeDamage(dmg)
	end

	function ENT:OnRemove()
	end

	function ENT:SetItemName(name)
		self.Item = name
	end

	function ENT:SetSizeItem(loot)
		self.Sizez = loot
	end

	function ENT:Use(btn, ply)
		local item = RustOfficial.GetItem(self.Item)
		AddItemsToGmodeS(ply, item.name, math.random(50, 60), item.weapon, self.Sizez)
		self:Remove()
	end

	function ENT:StartTouch(entity)
		return false
	end

	function ENT:EndTouch(entity)
		return false
	end

	function ENT:Touch(entity)
		return false
	end
end

if CLIENT then
	ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
	function ENT:Initialize()
	end

	function ENT:Draw()
		self:DrawModel()
	end
end