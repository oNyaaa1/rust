include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

local function S(n)
    return math.Round(n * ScrH() / 1080)
end

surface.CreateFont("gRustFurn_Title", {font = "Roboto Condensed", size = S(44), weight = 800})
surface.CreateFont("gRustFurn_Label", {font = "Roboto Condensed", size = S(20), weight = 800})
surface.CreateFont("gRustFurn_Amount", {font = "Roboto Condensed", size = S(20), weight = 700})

local COL_TEXT = Color(240, 232, 224)
local COL_LABEL = Color(200, 195, 190, 200)
local COL_PANEL = Color(90, 90, 90, 90)
local COL_SLOT = Color(0, 0, 0, 90)
local COL_LINE = Color(150, 145, 140, 200)
local COL_EMPTY = Color(120, 120, 120, 120)
local COL_RED = Color(177, 68, 52)
local COL_GREEN = Color(112, 140, 52)
local COL_HOVER = Color(255, 255, 255, 20)
local FLAME = Material("icon16/fire.png")

local iconCache = {}
local function GetIcon(path)
    if not path then return end
    iconCache[path] = iconCache[path] or Material(path, "smooth")
    return iconCache[path]
end

local function DrawSlot(x, y, size, slot)
    draw.RoundedBox(0, x, y, size, size, COL_SLOT)
    if slot and (slot.amount or 0) > 0 then
        local mat = GetIcon(slot.icon)
        if mat then
            local pad = size * 0.12
            surface.SetMaterial(mat)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(x + pad, y + pad, size - pad * 2, size - pad * 2)
        end

        draw.SimpleText("x" .. string.Comma(slot.amount), "gRustFurn_Amount", x + size - S(6), y + size - S(4), COL_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    else
        -- dim gem placeholder for empty slots
        local cx, cy, r = x + size / 2, y + size / 2, size * 0.22
        surface.SetDrawColor(COL_EMPTY)
        surface.DrawLine(cx - r, cy - r * 0.3, cx, cy - r)
        surface.DrawLine(cx, cy - r, cx + r, cy - r * 0.3)
        surface.DrawLine(cx + r, cy - r * 0.3, cx, cy + r)
        surface.DrawLine(cx, cy + r, cx - r, cy - r * 0.3)
        surface.DrawLine(cx - r, cy - r * 0.3, cx + r, cy - r * 0.3)
    end
end

local function DrawArrow(cx, y1, y2)
    local hw, hh = S(9), S(10)
    surface.SetDrawColor(COL_LINE)
    surface.DrawRect(cx - 1, y1, 2, y2 - y1 - hh)
    draw.NoTexture()
    surface.DrawPoly({
        {x = cx - hw, y = y2 - hh},
        {x = cx + hw, y = y2 - hh},
        {x = cx, y = y2},
    })
end

function GRUST_FurnaceMove(ent, mode, kind, idx, name)
    net.Start("gRustFurnaceMove")
    net.WriteEntity(ent)
    net.WriteString(mode)
    net.WriteString(kind)
    net.WriteUInt(idx, 4)
    net.WriteString(name or "")
    net.SendToServer()
end

local function OpenFurnace(ent, data)
    if IsValid(GRUST_FurnaceUI) then GRUST_FurnaceUI:Remove() end

    local PW, PH, SLOT, GAP = S(570), S(504), S(86), S(7)
    local TITLE_H, CTRL_H, BTN_W = S(55), S(48), S(135)
    local W, H = PW, TITLE_H + PH + S(9) + CTRL_H

    hook.Run("ScoreboardShow") -- opens your inventory (it returns true, so the default scoreboard doesn't show)
    if not IsValid(GRUST_TEST) then return end

    local pnl = vgui.Create("DPanel", GRUST_TEST) -- child of the inventory background so drags work between them
    GRUST_FurnaceUI = pnl
    pnl.ent, pnl.data = ent, data
    pnl:SetSize(W, H)
    local invBox = IsValid(GRUST_SLOTS) and GRUST_SLOTS:GetParent()
    local px = invBox and (invBox:GetX() + invBox:GetWide() + S(30)) or (ScrW() - W) / 2
    pnl:SetPos(math.min(px, ScrW() - W - S(10)), (ScrH() - H) / 2)

    pnl.Paint = function(self, w, h)
        local d = self.data or {}
        local y0, cx = TITLE_H, w / 2
        draw.SimpleText("FURNACE", "gRustFurn_Title", 0, 0, COL_TEXT)
        draw.RoundedBox(0, 0, y0, w, PH, COL_PANEL)

        -- fuel
        draw.SimpleText("FUEL", "gRustFurn_Label", S(36), y0 + S(30), COL_LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawSlot(cx - SLOT / 2, y0 + S(51), SLOT, d.fuel)
        DrawArrow(cx, y0 + S(157), y0 + S(204))

        -- input
        draw.SimpleText("INPUT", "gRustFurn_Label", S(36), y0 + S(198), COL_LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local iy = y0 + S(220)
        DrawSlot(cx - GAP / 2 - SLOT, iy, SLOT, d.input and d.input[1])
        DrawSlot(cx + GAP / 2, iy, SLOT, d.input and d.input[2])

        -- bracket joining the two inputs into one arrow
        local lx, rx = cx - GAP / 2 - SLOT / 2, cx + GAP / 2 + SLOT / 2
        local by1, by2 = y0 + S(324), y0 + S(344)
        surface.SetDrawColor(COL_LINE)
        surface.DrawRect(lx - 1, by1, 2, by2 - by1)
        surface.DrawRect(rx - 1, by1, 2, by2 - by1)
        surface.DrawRect(lx - 1, by2 - 1, rx - lx + 2, 2)
        DrawArrow(cx, by2, y0 + S(372))

        -- output
        draw.SimpleText("OUTPUT", "gRustFurn_Label", S(36), y0 + S(366), COL_LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local ox = cx - (SLOT * 3 + GAP * 2) / 2
        for i = 1, 3 do
            DrawSlot(ox + (i - 1) * (SLOT + GAP), y0 + S(388), SLOT, d.output and d.output[i])
        end

        -- controls bar
        local cy = y0 + PH + S(9)
        draw.RoundedBox(0, 0, cy, w, CTRL_H, COL_PANEL)
        draw.SimpleText("CONTROLS", "gRustFurn_Label", S(12), cy + CTRL_H / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local btn = vgui.Create("DButton", pnl)
    btn:SetText("")
    btn:SetSize(BTN_W, CTRL_H)
    btn:SetPos(W - BTN_W, TITLE_H + PH + S(9))
    btn.Paint = function(self, w, h)
        local on = pnl.data and pnl.data.on
        draw.RoundedBox(0, 0, 0, w, h, on and COL_RED or COL_GREEN)
        if self:IsHovered() then draw.RoundedBox(0, 0, 0, w, h, COL_HOVER) end
        surface.SetMaterial(FLAME)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(S(16), h / 2 - S(8), S(16), S(16))
        draw.SimpleText(on and "TURN OFF" or "TURN ON", "gRustFurn_Label", S(42), h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
        net.Start("gRustFurnaceToggle")
        net.WriteEntity(ent)
        net.SendToServer()
    end

    local function MakeSlot(kind, idx, x, y)
        local sp = vgui.Create("DButton", pnl)
        sp:SetText("")
        sp:SetPos(x, y)
        sp:SetSize(SLOT, SLOT)
        sp.furnEnt, sp.kind, sp.idx = ent, kind, idx
        sp:Droppable("grust_item") -- same name as your inventory items

        local function slotData()
            local d = pnl.data or {}
            if kind == "fuel" then return d.fuel end
            return d[kind] and d[kind][idx]
        end

        sp.Paint = function(self)
            if self:IsHovered() then draw.RoundedBox(0, 0, 0, SLOT, SLOT, COL_HOVER) end
            if self:IsDragging() then -- the copy that follows the mouse
                local s = slotData()
                if s then DrawSlot(0, 0, SLOT, s) end
            end
        end

        local function take()
            if slotData() then GRUST_FurnaceMove(ent, "take", kind, idx) end
        end

        sp.DoRightClick, sp.DoDoubleClick = take, take -- right-click / double-click sends it back to the inventory

        if kind ~= "output" then
            sp:Receiver("grust_item", function(self, panels, dropped)
                if not dropped then return end
                local name = panels[1] and panels[1].ItemID -- furnace slots have no ItemID, so they're ignored
                if name then GRUST_FurnaceMove(ent, "put", kind, idx, name) end
            end)
        end
    end

    MakeSlot("fuel", 1, W / 2 - SLOT / 2, TITLE_H + S(51))
    MakeSlot("input", 1, W / 2 - GAP / 2 - SLOT, TITLE_H + S(220))
    MakeSlot("input", 2, W / 2 + GAP / 2, TITLE_H + S(220))
    local ox = W / 2 - (SLOT * 3 + GAP * 2) / 2
    for i = 1, 3 do
        MakeSlot("output", i, ox + (i - 1) * (SLOT + GAP), TITLE_H + S(388))
    end

    pnl.Think = function(self)
        if not IsValid(self.ent) or LocalPlayer():GetPos():DistToSqr(self.ent:GetPos()) > 200 * 200 or gui.IsGameUIVisible() then
            gui.HideGameUI()
            hook.Run("ScoreboardHide") -- your hook closes the inventory and the furnace with it
        end
    end
end

net.Receive("gRustFurnace", function()
    local ent = net.ReadEntity()
    local data = net.ReadTable()
    if not IsValid(ent) then return end

    -- already open on this furnace: just refresh the contents
    if IsValid(GRUST_FurnaceUI) and GRUST_FurnaceUI.ent == ent then
        GRUST_FurnaceUI.data = data
        return
    end

    OpenFurnace(ent, data)
end)