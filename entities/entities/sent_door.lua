AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Door"
ENT.Category = ""
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Models = "models/deployable/wooden_door.mdl"
function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Healthz")
	self:NetworkVar("Float", 1, "MaxHealthz")
end

if SERVER then
	function ENT:Initialize()
		self.Entity:SetModel("models/deployable/wooden_door.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:EnableMotion(false)
		end

		self:SetHealthz(100)
		self.Ent_Health = 2500
		self.Ent_HealthMax = 100
		--self:SetMaterial("Model/effects/vol_light001")
		self:DrawShadow()
		self.SpawnTime = 0
		self.EntCount = 0
		self.DoorOpen = false
		self:SetNWInt("health_" .. self:GetClass(), self.Ent_Health)
	end

	--[[ function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local ent = ents.Create( "zombie_tree1" )
	ent:SetPos( tr.HitPos + tr.HitNormal * 32 ) 
	ent:Spawn()
	ent:Activate()

	return ent
end ]]
	function ENT:Think()
		local doors = 0
		for k, v in pairs(ents.FindInSphere(self:GetPos(), 30)) do
			if v:GetClass() == "sent_doorway" then doors = doors + 1 end
		end

		if doors <= 0 then self:Remove() end
	end

	function ENT:OnTakeDamage(dmg)
		self:SetHealthz(self:GetHealthz() - dmg:GetDamage())
		if self:GetHealthz() <= 0 then self:Remove() end
	end

	function ENT:Use(btn, ply)
		if ply.Meh == nil then ply.Meh = 0 end
		if ply.Meh >= CurTime() then return end
		ply.Meh = CurTime() + 0.2
		if self.DoorOpen == false then
			self.DoorPos = self:GetAngles()
			self.DoorPosa = self:GetPos()
			--self:SetPos(self:GetPos() + ply:GetForward() + Vector(28, 25, 7))
			self:SetAngles(self:GetAngles() + Angle(0, 90, 0))
			self.DoorOpen = true
		elseif self.DoorOpen == true then
			--self:SetPos(self.DoorPosa)
			self:SetAngles(self.DoorPos)
			self.DoorOpen = false
		end
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

	-- Draw some 3D text
	function ENT:Draw(flags)
		-- Draw the model
		self:DrawModel(flags)
		local DOOR_H = 110 -- target height, tune until the top touches the lintel
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local sz = maxs.z - mins.z
		if sz <= 0 then return end
		local kz = DOOR_H / sz
		-- bottom stays fixed, extra height grows upward
		local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
		local m = Matrix()
		m:Translate(pivot)
		m:Scale(Vector(1.3, 1, kz)) -- this is the line that was missing
		m:Translate(-pivot)
		self:EnableMatrix("RenderMultiply", m)
		self:SetRenderBounds(Vector(mins.x, mins.y, mins.z), Vector(maxs.x, maxs.y, mins.z + sz * kz))
	end
end