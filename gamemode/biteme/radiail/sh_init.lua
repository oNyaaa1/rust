-- lua/autorun/sh_radial_menu.lua
RadialMenu = RadialMenu or {}
-- ===== CONFIG =====
-- name = label shown on the wheel, class = scripted entity to spawn
RadialMenu.Items = {
    {
        name = "Foundation",
        class = "sent_foundation"
    },
    {
        name = "Wall",
        class = "sent_wall"
    },
    {
        name = "Door",
        class = "sent_door"
    },
    {
        name = "Ceiling",
        class = "sent_ceiling"
    },
    {
        name = "Doorway",
        class = "sent_doorway"
    },
    {
        name = "Stairs",
        class = "sent_stairs"
    },
}

RadialMenu.InnerRadius = 70
RadialMenu.OuterRadius = 220
RadialMenu.SpawnDistance = 400 -- max trace distance for placement
RadialMenu.Cooldown = 0.5 -- seconds between spawns per player
RadialMenu.AdminOnly = false
-- weapon that opens the wheel (hold it, press the open key)
RadialMenu.WeaponClass = "rust_builder" -- compared in lowercase, so case doesn't matter
RadialMenu.OpenKey = MOUSE_RIGHT
RadialMenu.RequireWeapon = true -- false = the +radial bind works with any weapon
-- ===== SNAP CONFIG =====
RadialMenu.SnapRange = 256 -- how far from where you aim to look for pieces to snap to
RadialMenu.WallHeight = 128 -- height of your wall model (ceilings stack this high)
-- free = true  -> can be placed on the ground if nothing to snap to
-- free = false -> refuses to place unless it finds a socket
-- mode: "edge"  = bottom-centre sits on the top edge of the target (walls/doors)
--       "side"  = placed next to the target, same angle (foundations)
--       "stack" = placed WallHeight above the target's top (ceilings)
--       "top"   = placed on top of the target (stairs)
-- angOffset: rotate the piece if your model faces the wrong way on an edge
--            (try 90, -90 or 180 on the yaw)
RadialMenu.Snap = {
    sent_foundation = {
        free = true,
        rules = {
            {
                to = "sent_foundation",
                mode = "side"
            }
        },
    },
    sent_wall = {
        free = false,
        rules = {
            {
                to = {"sent_foundation", "sent_ceiling"},
                mode = "edge",
                angOffset = Angle(0, 90, 0)
            }
        },
    },
    sent_door = {
        free = false,
        rules = {
            {
                to = {"sent_foundation", "sent_ceiling"},
                mode = "edge",
                angOffset = Angle(0, 90, 0)
            }
        },
    },
    sent_doorway = {
        free = false,
        rules = {
            {
                to = {"sent_foundation", "sent_ceiling"},
                mode = "edge",
                angOffset = Angle(0, 90, 0)
            }
        },
    },
    sent_ceiling = {
        free = false,
        rules = {
            {
                to = "sent_foundation",
                mode = "stack"
            },
            {
                to = "sent_ceiling",
                mode = "side"
            },
        },
    },
    sent_stairs = {
        free = false,
        rules = {
            {
                to = {"sent_foundation", "sent_ceiling"},
                mode = "top"
            }
        },
    },
}

-- ==================
local function IsDeployWeapon(wep)
    return IsValid(wep) and string.lower(wep:GetClass()) == string.lower(RadialMenu.WeaponClass)
end

-- ================= SERVER =================
if SERVER then
    util.AddNetworkString("RadialMenu_Spawn")
    local lastSpawn = {}
    -- world-space direction from a local direction
    local function WorldDir(ent, v)
        return (ent:LocalToWorld(v) - ent:GetPos()):GetNormalized()
    end

    -- candidate attach points on a target piece
    local function Sockets(target, rule)
        local mins, maxs = target:OBBMins(), target:OBBMaxs()
        local c = (mins + maxs) / 2
        local out = {}
        if rule.mode == "edge" or rule.mode == "side" then
            local z = (rule.mode == "edge") and maxs.z or mins.z
            local pts = {{Vector(maxs.x, c.y, z), Vector(1, 0, 0), "x"}, {Vector(mins.x, c.y, z), Vector(-1, 0, 0), "x"}, {Vector(c.x, maxs.y, z), Vector(0, 1, 0), "y"}, {Vector(c.x, mins.y, z), Vector(0, -1, 0), "y"},}
            for _, p in ipairs(pts) do
                out[#out + 1] = {
                    pos = target:LocalToWorld(p[1]),
                    normal = WorldDir(target, p[2]),
                    axis = p[3],
                }
            end
        else -- stack / top
            out[1] = {
                pos = target:LocalToWorld(Vector(c.x, c.y, maxs.z)),
                normal = WorldDir(target, Vector(0, 0, 1)),
            }
        end
        return out
    end

    -- pick the closest valid socket to where the player is aiming
    local function FindSnap(class, hitPos)
        local cfg = RadialMenu.Snap[class]
        if not cfg then return end
        local best, bestDist
        for _, ent in ipairs(ents.FindInSphere(hitPos, RadialMenu.SnapRange)) do
            if IsValid(ent) then
                for _, rule in ipairs(cfg.rules) do
                    local targets = istable(rule.to) and rule.to or {rule.to}
                    if table.HasValue(targets, ent:GetClass()) then
                        for _, sock in ipairs(Sockets(ent, rule)) do
                            local d = sock.pos:DistToSqr(hitPos)
                            if not bestDist or d < bestDist then
                                best = {
                                    rule = rule,
                                    sock = sock,
                                    target = ent
                                }

                                bestDist = d
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    -- move the spawned piece so its bottom-centre lands on the socket
    local function ApplySnap(ent, snap)
        local rule, sock, target = snap.rule, snap.sock, snap.target
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        local c = (mins + maxs) / 2
        local ang, anchor
        if rule.mode == "edge" then
            ang = sock.normal:Angle() + (rule.angOffset or angle_zero)
            anchor = sock.pos
        elseif rule.mode == "side" then
            ang = target:GetAngles()
            local half = (sock.axis == "x" and (maxs.x - mins.x) or (maxs.y - mins.y)) / 2
            anchor = sock.pos + sock.normal * half
        elseif rule.mode == "stack" then
            ang = target:GetAngles()
            anchor = sock.pos + sock.normal * RadialMenu.WallHeight
        else -- top
            ang = target:GetAngles()
            anchor = sock.pos
        end

        ent:SetAngles(ang)
        ent:SetPos(anchor)
        local bottomCentre = ent:LocalToWorld(Vector(c.x, c.y, mins.z))
        ent:SetPos(anchor + (ent:GetPos() - bottomCentre))
    end

    net.Receive("RadialMenu_Spawn", function(_, ply) end)
    net.Receive("RadialMenu_Spawn", function(_, ply)
        if not IsValid(ply) or not ply:Alive() then return end
        local wep = ply:GetActiveWeapon()
        if not IsDeployWeapon(wep) then return end
        local idx = net.ReadUInt(8)
        if not RadialMenu.Items[idx] then return end
        wep:SetSelected(idx)
        if not item then return end
        if RadialMenu.AdminOnly and not ply:IsAdmin() then
            ply:ChatPrint("[Radial] Admins only.")
            return
        end

        if (lastSpawn[ply] or 0) + RadialMenu.Cooldown > CurTime() then return end
        lastSpawn[ply] = CurTime()
        if not scripted_ents.GetStored(item.class) and not scripted_ents.Get(item.class) then
            ply:ChatPrint("[Radial] Entity '" .. item.class .. "' doesn't exist.")
            return
        end

        -- respect sandbox limits / permissions
        if hook.Run("PlayerSpawnSENT", ply, item.class) == false then return end
        local tr = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * RadialMenu.SpawnDistance,
            filter = ply,
        })

        local cfg = RadialMenu.Snap[item.class]
        local snap = FindSnap(item.class, tr.HitPos)
        if cfg and not cfg.free and not snap then
            ply:ChatPrint("[Radial] " .. item.name .. " must be placed on a valid piece.")
            return
        end

        local ent = ents.Create(item.class)
        if not IsValid(ent) then return end
        ent:SetPos(tr.HitPos + tr.HitNormal * 8)
        ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
        ent:Spawn()
        ent:Activate()
        if snap then
            ApplySnap(ent, snap)
            -- block duplicate pieces in the same spot
            for _, other in ipairs(ents.FindInSphere(ent:GetPos(), 8)) do
                if other ~= ent and other:GetClass() == item.class then
                    ent:Remove()
                    ply:ChatPrint("[Radial] Something is already placed there.")
                    return
                end
            end

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) end
        end

        if ent.CPPISetOwner then ent:CPPISetOwner(ply) end
        hook.Run("PlayerSpawnedSENT", ply, ent)
        undo.Create(item.name)
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
        undo.Finish()
    end)

    hook.Add("PlayerDisconnected", "RadialMenu_Cleanup", function(ply) lastSpawn[ply] = nil end)
    return
end

-- ================= CLIENT =================
local open = false
local selected = 0
local openTime = 0
local cx, cy
local function GetSelected()
    local items = RadialMenu.Items
    local n = #items
    if n == 0 then return 0 end
    local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
    if math.sqrt(dx * dx + dy * dy) < RadialMenu.InnerRadius then return 0 end
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

surface.CreateFont("RadialMenu_Font", {
    font = "Roboto",
    size = 20,
    weight = 700
})

surface.CreateFont("RadialMenu_Center", {
    font = "Roboto",
    size = 24,
    weight = 800
})

local function OpenMenu()
    if open then return end
    open = true
    openTime = SysTime()
    selected = 0
    cx, cy = ScrW() / 2, ScrH() / 2
    gui.EnableScreenClicker(true)
    input.SetCursorPos(cx, cy)
end

local function CloseMenu(doSelect)
    if not open then return end
    open = false
    gui.EnableScreenClicker(false)
    if doSelect and selected > 0 then
        net.Start("RadialMenu_Spawn")
        net.WriteUInt(selected, 8)
        net.SendToServer()
        surface.PlaySound("buttons/button15.wav")
    end
end

-- optional manual bind: bind g +radial   (releasing the key does nothing)
concommand.Add("+radial", function()
    if RadialMenu.RequireWeapon and not IsDeployWeapon(LocalPlayer():GetActiveWeapon()) then return end
    OpenMenu()
end)

concommand.Add("-radial", function() end)
-- open with the deploy weapon: press right-click once, then pick with left-click
local wasDown = false
hook.Add("Think", "RadialMenu_WeaponOpen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local holding = IsDeployWeapon(ply:GetActiveWeapon())
    local keyDown = input.IsMouseDown(RadialMenu.OpenKey)
    if open then
        -- weapon switched or died: cancel
        if not holding or not ply:Alive() then CloseMenu(false) end
    elseif holding and keyDown and not wasDown and ply:Alive() and not vgui.CursorVisible() and not gui.IsGameUIVisible() then
        OpenMenu()
    end

    wasDown = keyDown
end)

hook.Add("GUIMousePressed", "RadialMenu_Click", function(code)
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

hook.Add("HUDPaint", "RadialMenu_Draw", function()
    if not open then return end
    local items = RadialMenu.Items
    local n = #items
    local seg = 360 / n
    local gap = 1.5
    selected = GetSelected()
    draw.NoTexture()
    for i, item in ipairs(items) do
        local center = -90 + (i - 1) * seg
        local a0, a1 = center - seg / 2 + gap, center + seg / 2 - gap
        local hovered = i == selected
        surface.SetDrawColor(hovered and Color(60, 140, 255, 220) or Color(20, 20, 20, 190))
        local r1 = hovered and RadialMenu.OuterRadius + 12 or RadialMenu.OuterRadius
        surface.DrawPoly(ArcPoly(a0, a1, RadialMenu.InnerRadius, r1))
        local mid = math.rad(center)
        local tr = (RadialMenu.InnerRadius + RadialMenu.OuterRadius) / 2
        draw.SimpleText(item.name, "RadialMenu_Font", cx + math.cos(mid) * tr, cy + math.sin(mid) * tr, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local label = selected > 0 and items[selected].class or "Right-click to cancel"
    draw.SimpleText(label, "RadialMenu_Center", cx, cy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- stop the weapon from firing while the wheel is open
hook.Add("CreateMove", "RadialMenu_BlockAttack", function(cmd)
    if open then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end
end)