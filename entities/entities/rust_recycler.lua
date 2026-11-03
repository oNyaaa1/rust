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
	util.AddNetworkString("grust_FurnaceMove")
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

	util.AddNetworkString("grust_FurnaceMove")
	function ENT:SendContents(ply)
		net.Start("DockMain")
		net.WriteEntity(self)
		net.WriteTable({
			fuel = self.FuelSlots,
			input = self.InputSlots,
			output = self.OutputSlots,
		})

		net.Send(ply)
	end

	net.Receive("grust_FurnaceMove", function(len, ply)
		local ent = net.ReadEntity()
		local action = net.ReadString()
		local kind = net.ReadString()
		local idx = net.ReadUInt(4)
		local fromCont = net.ReadUInt(2)
		local fromSlot = net.ReadUInt(8)
		if not IsValid(ent) or ent:GetPos():DistToSqr(ply:GetPos()) > 200 * 200 then return end
		local tbl = ({
			fuel = ent.FuelSlots,
			input = ent.InputSlots,
			output = ent.OutputSlots
		})[kind]

		if not tbl then return end
		if action == "put" then
			if kind == "output" then -- outputs are take-only
				return
			end

			if tbl[idx] then -- slot already full
				return
			end

			-- PLACEHOLDER: replace with your real inventory functions
			local item = GetInventoryItem(ply, fromCont, fromSlot)
			if not item then return end
			tbl[idx] = {
				id = item.id,
				dur = item.dur,
				count = item.count
			}

			RemoveInventoryItem(ply, fromCont, fromSlot)
		elseif action == "take" then
			local item = tbl[idx]
			if not item then return end
			-- PLACEHOLDER: replace with your real "give item" function
			if not GiveInventoryItem(ply, item.id, item.count, item.dur) then return end
			tbl[idx] = nil
		end

		ent:SendContents(ply)
	end)

	function ENT:SpawnFunction(ply, tr)
		if not tr.Hit then return end
		local ent = ents.Create("zombie_tree1")
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

	function ENT:Think()
	end

	function ENT:OnTakeDamage(dmg)
	end

	function ENT:Use(btn, ply)
		net.Start("DockMain")
		net.WriteEntity(self)
		net.WriteTable(self.data or {})
		net.Send(ply)
		net.Start("DragNDropRust")
		net.WriteTable(ply.tbl)
		net.Send(ply)
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
		-- open the inventory if it isn't already, the same way the scoreboard key does
		if not IsValid(GRUST_TEST) then hook.Run("ScoreboardShow") end
		if not IsValid(GRUST_TEST) then return {} end
		return {GRUST_TEST}
	end

	function GRUST_FurnaceMove(ent, action, kind, idx, fromCont, fromSlot)
		net.Start("grust_FurnaceMove")
		net.WriteEntity(ent)
		net.WriteString(action) -- "put" or "take"
		net.WriteString(kind) -- "fuel", "input", "output"
		net.WriteUInt(idx, 4)
		net.WriteUInt(fromCont or 0, 2) -- only used for "put"
		net.WriteUInt(fromSlot or 0, 8) -- only used for "put"
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
			if not IsValid(item) or item.furnEnt then -- ignore items already in the furnace
				return
			end

			local fromSlot = item:GetParent()
			if not IsValid(fromSlot) or not fromSlot.Container then return end
			GRUST_FurnaceMove(target.IDEnt, "put", target.Kind, target.IDID, fromSlot.Container, fromSlot.SlotID)
		end

		local function FillSlot(slot, i, it)
			if not it then return end
			-- borrow grust_SlotsGrid:AddItem so icons look and drag like the inventory ones
			local fake = {
				Slots = {
					[i] = slot
				},
				MoveItem = function(_, item, target) DoDrop(target, {item}, true) end,
			}

			local item = GRID.AddItem(fake, i, it.id, it.dur, it.count)
			if item then item.furnEnt, item.kind, item.idx = ent, slot.Kind, i end
		end

		-- ===== layout =====
		local LeftMargin = ScrW() * 0.02
		local RightMargin = ScrW() * 0.05
		ContainerR = vgui.Create("Panel", frameWork[1])
		ContainerR:Dock(RIGHT)
		ContainerR:SetWide(500)
		-- slots panel is created BEFORE the FILL panel so docking works out
		local S, P = 84, 4 -- same size as inventory slots
		local SlotsPanel = vgui.Create("Panel", ContainerR)
		SlotsPanel:Dock(TOP)
		SlotsPanel:SetTall(3 * (S + P) + P)
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

		-- row 1: fuel
		local fuel = MakeSlot(P, P, "FUEL", "fuel", 1, true)
		FillSlot(fuel, 1, data.fuel and data.fuel[1])
		-- row 2: two inputs
		for i = 1, 2 do
			local s = MakeSlot(P + (i - 1) * (S + P), P + (S + P), "INPUT", "input", i, true)
			FillSlot(s, i, data.input and data.input[i])
		end

		-- row 3: three outputs (take-only, no receiver)
		for i = 1, 3 do
			local s = MakeSlot(P + (i - 1) * (S + P), P + 2 * (S + P), "OUTPUT", "output", i, false)
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
		ToggleButton:SetText("Turn On")
		ToggleButton:DockMargin(Margin, Margin, Margin, Margin)
		ToggleButton:SetWide(ScrW() * 0.11)
		ToggleButton.DoClick = function(me)
			net.Start("DockToggle") -- change to your real net message name
			net.WriteEntity(ent)
			net.SendToServer()
		end
	end)

	function ENT:Draw(flags)
		-- Draw the model
		self:DrawModel(flags)
	end
end