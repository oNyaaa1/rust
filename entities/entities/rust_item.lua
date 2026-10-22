AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Dropped Item"
ENT.Author = "Time"
ENT.Spawnable = false
if SERVER then
	function ENT:Initialize()
		-- default model until we set proper model from item data
		local defmodel = "models/environment/misc/loot_bag.mdl"
		self:SetModel(defmodel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end
		-- default networked values
		if not self:GetNWString("rust_item_id", "") then self:SetNWString("rust_item_id", "") end
		if not self:GetNWInt("rust_item_count", 0) then self:SetNWInt("rust_item_count", 0) end
		-- timeout auto-remove to avoid clutter
		self.RemoveTime = CurTime() + 600 -- 10 minutes
		//timer.Simple(0.5, function() constraint.Weld(self, Entity(0), 0, 0, 0, true, true) end)
		self.Cooled = 0
	end

	function ENT:Think()
		if self.RemoveTime and CurTime() > self.RemoveTime then
			SafeRemoveEntity(self)
			return
		end
	end

	-- Safe setters/getters -------------------------------------------------
	function ENT:SetItem(itemID)
		if not itemID then return end
		self:SetNWString("rust_item_id", tostring(itemID))
		-- if ITEMS is available, set model to the item's world model/icon
		if ITEMS and ITEMS.GetItem then
			local info = ITEMS:GetItem(itemID)
			if info and info.WorldModel then
				local ok, err = pcall(function() self:SetModel(info.WorldModel) end)
				if not ok then
					-- fallback silently
				end
			end
		end
	end

	function ENT:GetItem()
		return self:GetNWString("rust_item_id", "")
	end

	function ENT:SetCount(n)
		n = tonumber(n) or 1
		self:SetNWInt("rust_item_count", n)
	end

	function ENT:GetCount()
		return self:GetNWInt("rust_item_count", 1)
	end

	-- convenience: add an amount to current count
	function ENT:AddCount(n)
		n = tonumber(n) or 1
		local cur = self:GetCount() or 0
		self:SetCount(cur + n)
	end

	-- When a player touches / uses the item, give it to them (simple pickup)
	function ENT:Use(activator, caller)
		if self.Cooled >= CurTime() then return end
		self.Cooled = CurTime() + 1
		if not IsValid(activator) or not activator:IsPlayer() then return end
		-- your pickup logic here; example: give into player's inventory table
		local itemID = self:GetItem()
		local count = self:GetCount()
		caller:GiveItem(itemID, count, true)
		self:Remove()
		-- fallback: if player can't receive, do nothing
	end

	function ENT:OnRemove()
		-- optional cleanup
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		-- optional: draw count text
		local itemid = self:GetNWString("rust_item_id", "")
		local cnt = self:GetNWInt("rust_item_count", 0)
		if itemid ~= "" then
			local pos = self:GetPos() + Vector(0, 0, 10)
			local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
			cam.Start3D2D(pos, ang, 0.1)
			draw.SimpleTextOutlined(itemid .. " x" .. cnt, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			cam.End3D2D()
		end
	end
end