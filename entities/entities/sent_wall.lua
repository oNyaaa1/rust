AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Wall"
ENT.Category = ""
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Models = "models/building_re/twig_wall.mdl"
function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Healthz")
	self:NetworkVar("Float", 1, "MaxHealthz")
end

if SERVER then
	function ENT:Initialize()
		self.Entity:SetModel(self.Models)
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			--phys:EnableMotion(false)
		end

		--local FOUNDATION_WIDTH = 145.78 -- from your foundation's OBB
		--local mins, maxs = self:OBBMins(), self:OBBMaxs()
		--local length = math.max(maxs.x - mins.x, maxs.y - mins.y)
		--if length > 0 then self:SetModelScale(FOUNDATION_WIDTH / length, 0) end
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

	function ENT:OnRemove()
		self:EmitSound("zohart/building/wood_gib-4.wav")
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
	end

	function ENT:Draw(flags)
		-- Draw the model
		self:DrawModel(flags)
		local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local sx, sy = maxs.x - mins.x, maxs.y - mins.y
		local len = math.max(sx, sy)
		if len > 0 and len < WALL_LENGTH then
			local k = WALL_LENGTH / len
			-- scale only the longer horizontal axis; thickness and height stay as-is
			local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
			local sz = maxs.z - mins.z
			local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
			self:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
			local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
			local m = Matrix()
			m:Translate(pivot)
			m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
			m:Translate(-pivot)
			self:EnableMatrix("RenderMultiply", m)
		end
	end
end