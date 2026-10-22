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

		constraint.Weld(self, Entity(0), 0, 0, 0, true, true)
		self.CD = 0
	end

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

	local function DoDrop(self, droppedPanels, bDoDrop)
		local dragged = droppedPanels[1] -- panel being dragged
		local target = self -- slot receiving the drop
		if bDoDrop then
			net.Start("gRustRecycler")
			net.WriteString(dragged.Weap) -- weapon/item id
			net.WriteEntity(target.IDEnt)
			net.WriteFloat(target.IDID)
			net.SendToServer()
			dragged:SetParent(target)
			return -- Exit here, don't drop to world
		end
	end

	local Container = NULL
	local ent = NULL
	net.Receive("DockMain", function()
		ent = net.ReadEntity()
		local data = net.ReadTable()
		if IsValid(Container) then Container:Remove() end
		local frameWork = DockInventory()
		if not frameWork[1] then return end
		local LeftMargin = ScrW() * 0.02
		local RightMargin = ScrW() * 0.05
		ContainerR = vgui.Create("Panel", frameWork[1])
		ContainerR:Dock(RIGHT)
		ContainerR:SetTall(200)
		ContainerR:SetWide(500)
		Container = ContainerR:Add("Panel")
		Container:Dock(FILL)
		local Controls = Container:Add("Panel")
		Controls:Dock(BOTTOM)
		Controls:SetTall(ScrH() * 0.13)
		Controls:DockMargin(LeftMargin, 0, RightMargin, ScrH() * 0.15)
		local Title = Controls:Add("Panel")
		Title:Dock(TOP)
		Title:SetTall(ScrH() * 0.03)
		Title:DockMargin(0, 0, 0, ScrH() * 0.003)
		Title.Paint = function(me, w, h)
			surface.SetDrawColor(80, 76, 70, 100)
			surface.DrawRect(0, 0, w, h)
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
		ToggleButton.Think = function(me) end
		ToggleButton.DoClick = function(me) self:Togglez() end
		gui.EnableScreenClicker(true)
		local grid2 = vgui.Create("ThreeGrid", ContainerR)
		grid2:Dock(FILL)
		grid2:DockMargin(4, 4, 4, 4)
		grid2:InvalidateParent(true)
		grid2:SetColumns(6)
		grid2:SetHorizontalMargin(2)
		grid2:SetVerticalMargin(2)
		local ContainerAbove = vgui.Create("Panel", ContainerR)
		ContainerAbove:Dock(TOP)
		ContainerAbove:SetTall(300)
		ContainerAbove:SetWide(100)
		ContainerAbove:DockMargin(0, 0, 0, 140)
		for i = 1, 6 do
			local Name = vgui.Create("Panel")
			Name:SetTall(100)
			Name:SetWide(500)
			Name:Receiver("DroppableRust", DoDrop)
			Name.IDEnt = ent
			Name.IDID = i
			Name.Paint = function(me, w, h)
				surface.SetDrawColor(80, 76, 70, 100)
				surface.DrawRect(0, 0, w, h)
				draw.SimpleText("INPUT", "Default", w * 0.01, h * 0.1, Color(255, 255, 255, 200), 0, 1)
			end

			grid2:AddCell(Name)
		end

		for i = 1, 6 do
			local Name = vgui.Create("Panel")
			Name:SetTall(100)
			Name:SetWide(500)
			Name:Receiver("DroppableRust", DoDrop)
			Name.IDEnt = ent
			Name.Paint = function(me, w, h)
				surface.SetDrawColor(80, 76, 70, 100)
				surface.DrawRect(0, 0, w, h)
				draw.SimpleText("OUTPUT", "Default", w * 0.01, h * 0.1, Color(255, 255, 255, 200), 0, 1)
			end

			grid2:AddCell(Name)
		end
	end)

	function ENT:Think()
		if not IsValid(ent) then return end
		local distance = ent:GetPos():Distance(LocalPlayer():GetPos())
		if distance > 100 then
			GetFrameWorkFrame():Remove()
			gui.EnableScreenClicker(false)
		end
	end

	function ENT:Draw(flags)
		-- Draw the model
		self:DrawModel(flags)
	end
end