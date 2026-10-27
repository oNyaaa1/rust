-- lua/autorun/sh_radial_menu.lua
RadialMenu2 = RadialMenu2 or {}
RadialMenu2.Selected = 0
-- ===== CONFIG =====
-- name = label shown on the wheel, class = scripted entity to spawn
RadialMenu2.Items = {
    {
        name = "Demolish",
        class = "Demolish",
        Mat = Material("materials/icons/demolish.png", "nobip smooth")
    },
    {
        name = "Rotate",
        class = "Rotate",
        Mat = Material("materials/icons/rotate.png", "nobip smooth")
    },
    {
        name = "Wood",
        class = "woodUpgrade",
        Mat = Material("materials/items/resources/wood.png", "nobip smooth"),
        Model = {
            ["sent_wall"] = "models/building_re/wood_wall.mdl",
        },
    },
    {
        name = "Stone",
        class = "StoneUpgrade",
        Mat = Material("materials/items/resources/stone.png", "nobip smooth"),
        Model = {
            ["sent_wall"] = "models/building_re/stone_wall.mdl",
        },
    },
    {
        name = "Sheet Metal",
        class = "SheetMetalUpgrade",
        Mat = Material("materials/items/resources/metal_fragments.png", "nobip smooth"),
        Model = {
            ["sent_wall"] = "models/building_re/metal_wall.mdl",
        },
    },
    {
        name = "Armored",
        class = "ArmoredUpgrade",
        Mat = Material("materials/items/resources/hqmetal.png", "nobip smooth"),
        Model = {
            ["sent_wall"] = "models/building_re/hq_wall.mdl",
        },
    },
}

RadialMenu2.InnerRadius = 70
RadialMenu2.OuterRadius = 220
RadialMenu2.SpawnDistance = 400 -- max trace distance for placement
RadialMenu2.Cooldown = 0.5 -- seconds between spawns per player
RadialMenu2.AdminOnly = false
-- weapon that opens the wheel (hold it, press the open key)
RadialMenu2.WeaponClass = "rust_hammer" -- compared in lowercase, so case doesn't matter
RadialMenu2.OpenKey = MOUSE_RIGHT
RadialMenu2.RequireWeapon = true -- false = the +radial bind works with any weapon
-- ===== SNAP CONFIG =====
RadialMenu2.SnapRange = 256 -- how far from where you aim to look for pieces to snap to
RadialMenu2.WallHeight = 128 -- height of your wall model (ceilings stack this high)
-- free = true  -> can be placed on the ground if nothing to snap to
-- free = false -> refuses to place unless it finds a socket
-- mode: "edge"  = bottom-centre sits on the top edge of the target (walls/doors)
--       "side"  = placed next to the target, same angle (foundations)
--       "stack" = placed WallHeight above the target's top (ceilings)
--       "top"   = placed on top of the target (stairs)
-- angOffset: rotate the piece if your model faces the wrong way on an edge
--            (try 90, -90 or 180 on the yaw)
RadialMenu2.Snap = {}
-- ==================
local function IsDeployWeapon(wep)
    return IsValid(wep) and string.lower(wep:GetClass()) == string.lower(RadialMenu2.WeaponClass)
end

-- ================= SERVER =================
if SERVER then
    util.AddNetworkString("RadialMenu2_Spawn")
    net.Receive("RadialMenu2_Spawn", function(_, ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if ply.CooldownRMS == nil then ply.CooldownRMS = 0 end
        if ply.CooldownRMS >= CurTime() then return end
        ply.CooldownRMS = CurTime() + 0.1
        local tr = ply:GetEyeTrace()
        local upgr = net.ReadString()
        local a, b, c, ent = DEPLOY:GetSocket(ply, tr.Entity:GetClass())
        for k, v in pairs(RadialMenu2.Items) do
            if v.class == upgr and v.Model[tr.Entity:GetClass()] then
                ent:SetModel(v.Model[tr.Entity:GetClass()])
                ent:PhysicsInitStatic(SOLID_VPHYSICS)
                ent:SetMoveType(MOVETYPE_NONE)
                ent:SetSolid(SOLID_VPHYSICS)
            end
        end
    end)
    return
end

-- ================= CLIENT =================
local open = false
local selected = 0
local openTime = 0
local cx, cy
local function GetSelected()
    local items = RadialMenu2.Items
    local n = #items
    if n == 0 then return 0 end
    local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
    if math.sqrt(dx * dx + dy * dy) < RadialMenu2.InnerRadius then return 0 end
    local seg = 360 / n
    local ang = math.deg(math.atan2(dy, dx))
    local rel = (ang + 90 + seg / 2) % 360
    return math.floor(rel / seg) + 1
end

local function ArcPoly(a0, a1, r0, r1)
    local poly = {}
    local steps = 10
    for i = 0, steps do
        local a = math.rad(a0 + (a1 - a0) * (i / steps))
        poly[#poly + 1] = {
            x = cx + math.cos(a) * r1,
            y = cy + math.sin(a) * r1
        }
    end

    for i = steps, 0, -1 do
        local a = math.rad(a0 + (a1 - a0) * (i / steps))
        poly[#poly + 1] = {
            x = cx + math.cos(a) * r0,
            y = cy + math.sin(a) * r0
        }
    end
    return poly
end

surface.CreateFont("RadialMenu2_Font", {
    font = "Roboto",
    size = 20,
    weight = 700
})

surface.CreateFont("RadialMenu2_Center", {
    font = "Roboto",
    size = 24,
    weight = 800
})

local function OpenMenu()
    if open then return end
    open = true
    openTime = SysTime()
    selected = 0
    RadialMenu2.Selected = 0
    cx, cy = ScrW() / 2, ScrH() / 2
    gui.EnableScreenClicker(true)
    input.SetCursorPos(cx, cy)
end

local function CloseMenu(doSelect)
    if not open then return end
    open = false
    gui.EnableScreenClicker(false)
    if doSelect and selected > 0 then
        -- net.Start("RadialMenu2_Spawn")
        --net.WriteUInt(selected, 8)
        --net.SendToServer()
        -- surface.PlaySound("buttons/button15.wav")
    end
end

-- optional manual bind: bind g +radial   (releasing the key does nothing)
concommand.Add("+radialhammer", function()
    if RadialMenu2.RequireWeapon and not IsDeployWeapon(LocalPlayer():GetActiveWeapon()) then return end
    OpenMenu()
end)

concommand.Add("-radialhammer", function() end)
-- open with the deploy weapon: press right-click once, then pick with left-click
local wasDown = false
hook.Add("Think", "RadialMenu2_WeaponOpen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local holding = IsDeployWeapon(ply:GetActiveWeapon())
    local keyDown = input.IsMouseDown(RadialMenu2.OpenKey)
    if open then
        -- weapon switched or died: cancel
        if not holding or not ply:Alive() then CloseMenu(false) end
    elseif holding and keyDown and not wasDown and ply:Alive() and not vgui.CursorVisible() and not gui.IsGameUIVisible() then
        OpenMenu()
    end

    wasDown = keyDown
end)

hook.Add("GUIMousePressed", "RadialMenu2_Click", function(code)
    if not open then return end
    if SysTime() - openTime < 0.2 then -- ignore the click that opened it
        return
    end

    if code == MOUSE_LEFT then
        CloseMenu(true) -- place the hovered piece and close
    elseif code == MOUSE_RIGHT then
        CloseMenu(false) -- cancel
    end
end)

hook.Add("HUDPaint", "RadialMenu2_Draw", function()
    if not open then return end
    local items = RadialMenu2.Items
    local n = #items
    local seg = 360 / n
    local gap = 1.5
    selected = GetSelected()
    RadialMenu2.Selected = GetSelected()
    draw.NoTexture()
    for i, item in ipairs(items) do
        local center = -90 + (i - 1) * seg
        local a0, a1 = center - seg / 2 + gap, center + seg / 2 - gap
        local hovered = i == selected
        surface.SetDrawColor(hovered and Color(60, 140, 255, 220) or Color(20, 20, 20, 190))
        local r1 = hovered and RadialMenu2.OuterRadius + 12 or RadialMenu2.OuterRadius
        surface.DrawPoly(ArcPoly(a0, a1, RadialMenu2.InnerRadius, r1))
        local mid = math.rad(center)
        local tr = (RadialMenu2.InnerRadius + RadialMenu2.OuterRadius) / 2
        draw.SimpleText(item.name, "RadialMenu2_Font", cx + math.cos(mid) * tr, cy + math.sin(mid) * tr, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local label = selected > 0 and items[selected].class or "Right-click to cancel"
    local mat = items[selected] ~= nil and items[selected].Mat or ""
    -- draw.SimpleText(label, "RadialMenu2_Center", cx, cy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if mat == "" then return end
    surface.SetMaterial(mat)
    surface.SetDrawColor(color_white)
    surface.DrawTexturedRect(cx - 30, cy - 25, 64, 64)
end)

-- stop the weapon from firing while the wheel is open
hook.Add("CreateMove", "RadialMenu2_BlockAttack", function(cmd)
    if open then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end
end)