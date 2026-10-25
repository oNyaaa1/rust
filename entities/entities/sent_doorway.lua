AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Doorway"
ENT.Category = ""
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Models = "models/building_re/twig_dframe.mdl"
function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Healthz")
	self:NetworkVar("Float", 1, "MaxHealthz")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Models)
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:EnableMotion(false)
		end

		self:SetHealthz(100)
		self.Ent_Health = 25
		self.Ent_HealthMax = 25
		--self:SetMaterial("Model/effects/vol_light001")
		self:DrawShadow()
		self.SpawnTime = 0
		self.EntCount = 0
		self:SetNWInt("health_" .. self:GetClass(), self.Ent_Health)
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
		self:SetHealthz(self:GetHealthz() - dmg:GetDamage())
		if self:GetHealthz() <= 0 then self:Remove() end
	end

	function ENT:Use(btn, ply)
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
		local DOOR_W = 137.78 -- frame opening width
		local DOOR_H = 140.78 -- frame opening height
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local sx, sy, sz = maxs.x - mins.x, maxs.y - mins.y, maxs.z - mins.z
		-- the thin horizontal axis is the door's thickness
		local thinX = sx < sy
		local width = thinX and sy or sx
		local kw = (width > 0) and (DOOR_W / width) or 1
		local kz = (sz > 0) and (DOOR_H / sz) or 1
		local scale = thinX and Vector(1, kw, kz) or Vector(kw, 1, kz)
		-- pivot on the hinge edge at the floor (flip to maxs if it grows the wrong way)
		local pivot = Vector(thinX and (mins.x + maxs.x) / 2 or mins.x, thinX and mins.y or (mins.y + maxs.y) / 2, mins.z)
		local function scaled(v)
			return Vector(pivot.x + (v.x - pivot.x) * scale.x, pivot.y + (v.y - pivot.y) * scale.y, pivot.z + (v.z - pivot.z) * scale.z)
		end

		local rmins, rmaxs = scaled(mins), scaled(maxs)
		self:SetRenderBounds(Vector(math.min(rmins.x, rmaxs.x), math.min(rmins.y, rmaxs.y), math.min(rmins.z, rmaxs.z)), Vector(math.max(rmins.x, rmaxs.x), math.max(rmins.y, rmaxs.y), math.max(rmins.z, rmaxs.z)))
		local m = Matrix()
		m:Translate(pivot)
		m:Scale(scale)
		m:Translate(-pivot)
		self:EnableMatrix("RenderMultiply", m)
	end

	function ENT:Draw(flags)
		-- Draw the model
		self:DrawModel(flags)
	end
end