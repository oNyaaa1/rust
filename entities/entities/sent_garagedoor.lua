AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Door"
ENT.Category = "Other"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true
ENT.Model = "models/darky_m/rust/building/garage_door.mdl"
function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Healthz")
	self:NetworkVar("Float", 1, "MaxHealthz")
	self:NetworkVar("Bool", 0, "GarageDoor") -- true = open
end

if SERVER then
	function ENT:SetupCollision(open)
		local mins, maxs = self.Mins, self.Maxs
		if open then mins = Vector(mins.x, mins.y, maxs.z - 20) end
		local verts = {Vector(mins.x, mins.y, mins.z), Vector(mins.x, mins.y, maxs.z), Vector(mins.x, maxs.y, mins.z), Vector(mins.x, maxs.y, maxs.z), Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, mins.y, maxs.z), Vector(maxs.x, maxs.y, mins.z), Vector(maxs.x, maxs.y, maxs.z),}
		self:PhysicsInitConvex(verts)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:EnableCustomCollisions(true)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	end

	-- is a player/NPC standing inside the doorway?
	function ENT:DoorwayBlocked()
		local wmins, wmaxs = self:WorldSpaceAABB()
		for _, e in ipairs(ents.FindInBox(wmins, wmaxs)) do
			if e ~= self and (e:IsPlayer() or e:IsNPC()) then return true end
		end
		return false
	end

	function ENT:Initialize()
		self:SetModel(self.Model)
		self.Mins, self.Maxs = self:GetModelBounds()
		self:SetUseType(SIMPLE_USE)
		self:SetMaxHealthz(100)
		self:SetHealthz(100)
		self:SetGarageDoor(false) -- spawn closed
		self:SetupCollision(false)
		self:ResetSequence(self:LookupSequence("idle"))
		self:DrawShadow(true)
	end

	function ENT:Think()
		self:NextThink(CurTime())
		return true
	end

	function ENT:OnTakeDamage(dmg)
		self:SetHealthz(self:GetHealthz() - dmg:GetDamage())
		if self:GetHealthz() <= 0 then self:Remove() end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if (self.NextUse or 0) > CurTime() then return end
		local open = not self:GetGarageDoor()
		-- don't close the door on someone standing in it
		if not open and self:DoorwayBlocked() then
			self.NextUse = CurTime() + 0.5
			return
		end

		self:SetGarageDoor(open)
		local seq = self:LookupSequence(open and "open" or "close")
		self:ResetSequence(seq)
		self:SetCycle(0)
		self:SetPlaybackRate(1)
		local dur = self:SequenceDuration(seq)
		self.NextUse = CurTime() + dur + 0.1
		if open then
			-- stay solid while it rises, then leave only the top slab
			timer.Simple(dur, function() if IsValid(self) and self:GetGarageDoor() then self:SetupCollision(true) end end)
		else
			-- area is clear, so block immediately
			self:SetupCollision(false)
		end
	end
end

if SERVER then return end
local DOOR_H = 140
function ENT:ApplyDoorScale()
	if not self.DoorMatrix then
		local mins, maxs = self:GetModelBounds()
		local sz = maxs.z - mins.z
		if sz <= 0 then return end
		local kz = DOOR_H / sz
		local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
		local m = Matrix()
		m:Translate(pivot)
		m:Scale(Vector(1.2, 1, kz))
		m:Translate(-pivot)
		local pad = Vector(64, 64, 64)
		self.DoorMatrix = m
		self.DoorBoundsMin = mins - pad
		self.DoorBoundsMax = Vector(maxs.x, maxs.y, mins.z + sz * kz) + pad
	end

	self:EnableMatrix("RenderMultiply", self.DoorMatrix)
	self:SetRenderBounds(self.DoorBoundsMin, self.DoorBoundsMax)
end

function ENT:Draw()
	self:ApplyDoorScale()
	self:DrawModel()
end