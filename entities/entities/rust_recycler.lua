AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Recycler"
ENT.Category = ""
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.INPUT = {}
ENT.OUTPUT = {}
if SERVER then
	util.AddNetworkString("DockMain")
	util.AddNetworkString("gRustRecycler")
	util.AddNetworkString("Rust_recyclerInv")
	util.AddNetworkString("DockToggle")
	util.AddNetworkString("grust_RecyclerMove")
	function ENT:Initialize()
		self:SetModel("models/environment/misc/recycler.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:EnableMotion(false)
		end

		self.FuelSlots, self.InputSlots, self.OutputSlots = {}, {}, {}
		self.CD = 0
	end

	net.Receive("DockToggle", function(len, ply)
		local ent = net.ReadEntity()
		if not IsValid(ent) or ent:GetPos():DistToSqr(ply:GetPos()) > 200 * 200 then return end
		-- call your toggle function here, e.g. ent:Togglez()
	end)

	function ENT:SendContents(ply)
		net.Start("DockMain")
		net.WriteEntity(self)
		net.WriteTable({
			on = self.On or false,
			fuel = self.FuelSlots,
			input = self.InputSlots,
			output = self.OutputSlots,
		})

		net.Send(ply)
	end

	local FUEL_ITEMS = {
		LowGradeFueld = true
	}

	local SLOT_COUNT = {
		fuel = 1,
		input = 6,
		output = 6
	}

	local RECIPES = {
		GarageDoor = {
			MetalOre = 25
		},
		Furnace = {
			Stone = 100
		},
		ToolCupboard = {
			Wood = 50
		},
		Hammer = {
			MetalOre = 5,
			Wood = 5
		},
	}

	local CYCLE_TIME = 5 -- seconds per recycle step
	local function CanFit(out, recipe)
		local empty = 0
		for i = 1, 6 do
			if not out[i] then empty = empty + 1 end
		end

		for id in pairs(recipe) do
			local has = false
			for i = 1, 6 do
				if out[i] and out[i].id == id then
					has = true
					break
				end
			end

			if not has then empty = empty - 1 end
		end
		return empty >= 0
	end

	local function AddOutput(out, id, amount)
		for i = 1, 6 do
			if out[i] and out[i].id == id then
				out[i].count = out[i].count + amount
				return
			end
		end

		for i = 1, 6 do
			if not out[i] then
				out[i] = {
					id = id,
					dur = 100,
					count = amount
				}
				return
			end
		end
	end

	net.Receive("grust_RecyclerMove", function(_, ply)
		local ent = net.ReadEntity()
		local mode = net.ReadString()
		local kind = net.ReadString()
		local idx = net.ReadUInt(4)
		local name = net.ReadString()
		if not IsValid(ent) or ent:GetClass() ~= "rust_recycler" or not ent.InputSlots then return end
		if ply:GetPos():DistToSqr(ent:GetPos()) > 250 * 250 then return end
		if not SLOT_COUNT[kind] or idx < 1 or idx > SLOT_COUNT[kind] then return end
		local tbl = ({
			fuel = ent.FuelSlots,
			input = ent.InputSlots,
			output = ent.OutputSlots
		})[kind]

		local slot = tbl[idx]
		if mode == "put" then
			if kind == "output" then return end
			if kind == "fuel" and not FUEL_ITEMS[name] then return end
			if kind == "input" and FUEL_ITEMS[name] then -- fuel can't go in input slots
				return
			end

			if kind == "input" and not RECIPES[name] then return end
			if not RustOfficial.GetItem(name) then return end
			if slot and slot.id ~= name then return end
			local has, amount = CalcItem(ply, name)
			if not has or amount <= 0 then return end
			GInv_RemoveItem(ply, name, amount)
			tbl[idx] = {
				id = name,
				dur = 100,
				count = (slot and slot.count or 0) + amount
			}
		elseif mode == "take" then
			if not slot then return end
			
			if not AddItemsToGmodCount(ply, slot.id, slot.dur, nil, slot.count) then return end
			tbl[idx] = nil
		else
			return
		end

		ent:SendContents(ply)
	end)

	function ENT:SpawnFunction(ply, tr)
		if not tr.Hit then return end
		local ent = ents.Create("rust_recycler")
		ent:SetPos(tr.HitPos + tr.HitNormal * 32)
		ent:Spawn()
		ent:Activate()
		return ent
	end

	net.Receive("gRustRecycler", function(len, ply)
		local str = net.ReadString()
		local ent = net.ReadEntity()
		local slotid = net.ReadFloat()
		if ent.CD >= CurTime() then return end
		ent.CD = CurTime() + 1
		if not ent.data then ent.data = {} end
		table.insert(ent.data, {slotid, str})
	end)

	net.Receive("DockToggle", function(_, ply)
		local ent = net.ReadEntity()
		if not IsValid(ent) or ent:GetClass() ~= "rust_recycler" then return end
		if ply:GetPos():DistToSqr(ent:GetPos()) > 250 * 250 then return end
		ent.On = not ent.On
		if ent.On and not ent.FuelSlots[1] then ent.On = false end
		ent.NextCycle = CurTime() + CYCLE_TIME
		ent:SendContents(ply)
	end)

	function ENT:Refresh()
		local v = self.viewer
		if IsValid(v) and v:GetPos():DistToSqr(self:GetPos()) < 250 * 250 then self:SendContents(v) end
	end

	function ENT:Think()
		self:NextThink(CurTime() + 1)
		if not self.On or CurTime() < (self.NextCycle or 0) then return true end
		local fuel = self.FuelSlots[1]
		local did = false
		if fuel and fuel.count >= 1 then
			for i = 1, 6 do
				local it = self.InputSlots[i]
				local recipe = it and RECIPES[it.id]
				if recipe and CanFit(self.OutputSlots, recipe) then
					it.count = it.count - 1
					if it.count <= 0 then self.InputSlots[i] = nil end
					for id, amt in pairs(recipe) do
						AddOutput(self.OutputSlots, id, amt)
					end

					did = true
				end
			end
		end

		if did then
			fuel.count = fuel.count - 1
			if fuel.count <= 0 then self.FuelSlots[1] = nil end
			self.NextCycle = CurTime() + CYCLE_TIME
		else
			self.On = false -- no fuel, nothing to recycle, or outputs full
		end

		self:Refresh()
		return true
	end

	function ENT:Use(btn, ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		self.viewer = ply
		self:SendContents(ply)
	end

	function ENT:OnTakeDamage(dmg)
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

	local ContainerR = NULL
	local ent = NULL
	-- opens your inventory (same as the scoreboard key) and returns it as the parent
	local function DockInventory()
		if not IsValid(GRUST_TEST) then hook.Run("ScoreboardShow") end
		if not IsValid(GRUST_TEST) then return {} end
		return {GRUST_TEST}
	end

	function GRUST_RecyclerMove(ent, mode, kind, idx, name)
		net.Start("grust_RecyclerMove")
		net.WriteEntity(ent)
		net.WriteString(mode)
		net.WriteString(kind)
		net.WriteUInt(idx, 4)
		net.WriteString(name or "")
		net.SendToServer()
	end

	net.Receive("DockMain", function()
		ent = net.ReadEntity()
		local data = net.ReadTable()
		if IsValid(ContainerR) then ContainerR:Remove() end
		local frameWork = DockInventory()
		if not frameWork[1] then return end
		-- ===== drag and drop helpers (must be defined before the slots) =====
		local GRID = vgui.GetControlTable("grust_SlotsGrid")
		local function DoDrop(target, panels, dropped)
			if not dropped then return end
			local item = panels[1]
			local name = IsValid(item) and item.ItemID
			if not name or item.takeFn then -- ignore items already in the recycler
				return
			end

			GRUST_RecyclerMove(target.IDEnt, "put", target.Kind, target.IDID, name)
		end

		local function FillSlot(slot, i, it)
			if not it then return end
			local fake = {
				Slots = {
					[i] = slot
				},
				MoveItem = function(_, item, target) DoDrop(target, {item}, true) end,
			}

			local item = GRID.AddItem(fake, i, it.id, it.dur, it.count)
			if item then item.takeFn = function() GRUST_RecyclerMove(ent, "take", slot.Kind, i) end end
		end

		-- ===== layout =====
		ContainerR = vgui.Create("Panel", frameWork[1])
		ContainerR:Dock(RIGHT)
		ContainerR:SetWide(500)
		local S, P = 84, 4 -- same size as inventory slots
		local SlotsPanel = vgui.Create("Panel", ContainerR)
		SlotsPanel:Dock(TOP)
		SlotsPanel:SetTall(4 * (S + P) + P + 10)
		SlotsPanel:DockMargin(0, ScrH() * 0.4, 0, 0)
		local function MakeSlot(x, y, label, kind, idx, accepts)
			local slot = vgui.Create("DPanel", SlotsPanel)
			slot:SetSize(S, S)
			slot:SetPos(x, y)
			slot.IDEnt, slot.IDID, slot.Kind = ent, idx, kind
			if accepts then slot:Receiver("grust_item", DoDrop) end
			slot.Paint = function(me, w, h)
				surface.SetDrawColor(80, 76, 70, 100)
				surface.DrawRect(0, 0, w, h)
				draw.SimpleText(label, "Default", 4, 3, Color(255, 255, 255, 200))
			end
			return slot
		end

		-- row 1: low grade fuel
		local fuel = MakeSlot(P, P, "FUEL", "fuel", 1, true)
		FillSlot(fuel, 1, data.fuel and data.fuel[1])
		-- rows 2-3: inputs
		for i = 1, 6 do
			local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
			local s = MakeSlot(P + col * (S + P), P + (row + 1) * (S + P), "INPUT", "input", i, true)
			FillSlot(s, i, data.input and data.input[i])
		end

		-- rows 4-5: outputs (take-only)
		for i = 1, 6 do
			local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
			local s = MakeSlot(P + col * (S + P), P + (row + 3) * (S + P) + 10, "OUTPUT", "output", i, false)
			FillSlot(s, i, data.output and data.output[i])
		end

		-- ===== controls bar =====
		local Container = ContainerR:Add("Panel")
		Container:Dock(FILL)
		local Controls = Container:Add("Panel")
		Controls:Dock(TOP)
		Controls:SetTall(ScrH() * 0.13)
		Controls:DockMargin(0, ScrH() * 0.01, 0, 0)
		local Title = Controls:Add("Panel")
		Title:Dock(TOP)
		Title:SetTall(ScrH() * 0.03)
		Title:DockMargin(0, 0, 0, ScrH() * 0.003)
		Title.Paint = function(me, w, h)
			surface.SetDrawColor(80, 76, 70, 100)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText("CONTROLS", "Default", 6, h / 2, Color(255, 255, 255, 200), 0, 1)
		end

		local ButtonPanel = Controls:Add("Panel")
		ButtonPanel:Dock(FILL)
		ButtonPanel.Paint = function(me, w, h)
			surface.SetDrawColor(80, 76, 70, 100)
			surface.DrawRect(0, 0, w, h)
		end

		local Margin = ScrH() * 0.01
		local ToggleButton = ButtonPanel:Add("DButton")
		ToggleButton:Dock(LEFT)
		ToggleButton:SetText(data.on and "Turned On" or "Turn On")
		ToggleButton:DockMargin(Margin, Margin, Margin, Margin)
		ToggleButton:SetWide(ScrW() * 0.11)
		ToggleButton.DoClick = function(me)
			me:SetText(me:GetText() == "Turn On" and "Turned On" or "Turn Off")
			net.Start("DockToggle")
			net.WriteEntity(ent)
			net.SendToServer()
		end
	end)

	function ENT:Draw(flags)
		self:DrawModel(flags)
	end
end