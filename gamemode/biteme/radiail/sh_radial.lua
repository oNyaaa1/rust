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
        Sound = "building/hammer_saw_1.wav",
        Cost = 200,
        HP = 1000,
        UpgradeLevel = 1,
        Model = {
            ["sent_foundation"] = {"models/building_re/wood_foundation.mdl"},
            ["sent_wall"] = {
                "models/building_re/wood_wall.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local ak = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * ak, mins.y * ak, mins.z * kz), Vector(maxs.x * ak, maxs.y * ak, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(ak, 1, kz) or Vector(1, ak, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_ceiling"] = {
                "models/building_re/wood_floor.mdl",
                DoFuncWhat = function(ent)
                    self:DrawModel()
                    local SPACING = 137.78 -- must match DEPLOY.ClassDist.sent_foundation
                    local mins, maxs = self:OBBMins(), self:OBBMaxs()
                    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
                    if width > 0 and width < SPACING then
                        -- stretch only the footprint, leave thickness alone
                        local m = Matrix()
                        m:Scale(Vector(SPACING / width, SPACING / width, 1))
                        self:EnableMatrix("RenderMultiply", m) -- client-side visual only
                    end
                end
            },
            ["sent_doorway"] = {
                "models/building_re/wood_dframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_doorwayl"] = {
                "models/building_re/wood_gframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_stairs"] = {"models/building_re/wood_lst.mdl",},
        },
    },
    {
        name = "Stone",
        class = "StoneUpgrade",
        Mat = Material("materials/items/resources/stone.png", "nobip smooth"),
        Sound = "building/rust_stone_1.wav",
        HP = 1500,
        Cost = 500,
        UpgradeLevel = 2,
        Model = {
            ["sent_foundation"] = {"models/building_re/stone_foundation.mdl"},
            ["sent_wall"] = {
                "models/building_re/stone_wall.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local ak = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * ak, mins.y * ak, mins.z * kz), Vector(maxs.x * ak, maxs.y * ak, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(ak, 1, kz) or Vector(1, ak, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_ceiling"] = {
                "models/building_re/stone_floor.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local SPACING = 137.78 -- must match DEPLOY.ClassDist.sent_foundation
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
                    if width > 0 and width < SPACING then
                        -- stretch only the footprint, leave thickness alone
                        local m = Matrix()
                        m:Scale(Vector(SPACING / width, SPACING / width, 1))
                        ent:EnableMatrix("RenderMultiply", m) -- client-side visual only
                    end
                end
            },
            ["sent_doorway"] = {
                "models/building_re/stone_dframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_doorwayl"] = {
                "models/building_re/stone_gframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_stairs"] = {"models/building_re/stone_lst.mdl",},
        },
    },
    {
        name = "Sheet Metal",
        class = "SheetMetalUpgrade",
        Mat = Material("materials/items/resources/metal_fragments.png", "nobip smooth"),
        Sound = "building/rust_metal_1.wav",
        Cost = 800,
        HP = 3000,
        UpgradeLevel = 3,
        Model = {
            ["sent_foundation"] = {"models/building_re/metal_foundation.mdl"},
            ["sent_wall"] = {
                "models/building_re/metal_wall.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local ak = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * ak, mins.y * ak, mins.z * kz), Vector(maxs.x * ak, maxs.y * ak, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(ak, 1, kz) or Vector(1, ak, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_ceiling"] = {
                "models/building_re/metal_floor.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local SPACING = 137.78 -- must match DEPLOY.ClassDist.sent_foundation
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
                    if width > 0 and width < SPACING then
                        -- stretch only the footprint, leave thickness alone
                        local m = Matrix()
                        m:Scale(Vector(SPACING / width, SPACING / width, 1))
                        ent:EnableMatrix("RenderMultiply", m) -- client-side visual only
                    end
                end
            },
            ["sent_doorway"] = {
                "models/building_re/metal_dframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_doorwayl"] = {
                "models/building_re/metal_gframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_stairs"] = {"models/building_re/metal_lst.mdl",},
        },
    },
    {
        name = "Armored",
        class = "ArmoredUpgrade",
        Mat = Material("materials/items/resources/hqmetal.png", "nobip smooth"),
        Sound = "building/rust_metal_3.wav",
        Cost = 1000,
        HP = 5000,
        UpgradeLevel = 4,
        Model = {
            ["sent_foundation"] = {"models/building_re/hq_foundation.mdl",},
            ["sent_wall"] = {
                "models/building_re/hq_wall.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local ak = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * ak, mins.y * ak, mins.z * kz), Vector(maxs.x * ak, maxs.y * ak, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(ak, 1, kz) or Vector(1, ak, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_ceiling"] = {
                "models/building_re/hq_floor.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local SPACING = 137.78 -- must match DEPLOY.ClassDist.sent_foundation
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
                    if width > 0 and width < SPACING then
                        -- stretch only the footprint, leave thickness alone
                        local m = Matrix()
                        m:Scale(Vector(SPACING / width, SPACING / width, 1))
                        ent:EnableMatrix("RenderMultiply", m) -- client-side visual only
                    end
                end
            },
            ["sent_doorway"] = {
                "models/building_re/hq_dframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel()
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_doorwayl"] = {
                "models/building_re/hq_gframe.mdl",
                DoFuncWhat = function(ent)
                    ent:DrawModel(flags)
                    local WALL_LENGTH = 137.78 + 14 -- match your DEPLOY.ClassDist entry for the wall class
                    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                    local sx, sy = maxs.x - mins.x, maxs.y - mins.y
                    local len = math.max(sx, sy)
                    if len > 0 and len < WALL_LENGTH then
                        local k = WALL_LENGTH / len
                        -- scale only the longer horizontal axis; thickness and height stay as-is
                        local WALL_HEIGHT = 140.78 -- set to your floor-to-ceiling distance
                        local sz = maxs.z - mins.z
                        local kz = (sz > 0 and sz < WALL_HEIGHT) and (WALL_HEIGHT / sz) or 1
                        ent:SetRenderBounds(Vector(mins.x * k, mins.y * k, mins.z * kz), Vector(maxs.x * k, maxs.y * k, maxs.z * kz))
                        local pivot = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z)
                        local m = Matrix()
                        m:Translate(pivot)
                        m:Scale(sx >= sy and Vector(k, 1, kz) or Vector(1, k, kz))
                        m:Translate(-pivot)
                        ent:EnableMatrix("RenderMultiply", m)
                    end
                end
            },
            ["sent_stairs"] = {"models/building_re/hq_lst.mdl",},
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
    util.AddNetworkString("gRust_RadialDeployment")
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
            if v.class == upgr and v.Model[tr.Entity:GetClass()] ~= nil then
                if not IsValid(ent) then return end
                local curLevel = ent.Upgradelevel or 0
                if v.UpgradeLevel and v.UpgradeLevel <= curLevel then -- same or lower: refuse
                    return
                end

                ent.Upgradelevel = v.UpgradeLevel
                net.Start("gRust_RadialDeployment")
                net.WriteEntity(ent)
                net.WriteFloat(ent.Upgradelevel)
                net.Send(ply)
                ent:SetModel(v.Model[tr.Entity:GetClass()][1])
                ent:SetHealth(v.HP)
                ent:PhysicsInitStatic(SOLID_VPHYSICS)
                ent:SetMoveType(MOVETYPE_NONE)
                ent:SetSolid(SOLID_VPHYSICS)
                ply:EmitSound(v.Sound)
                function ent:Draw()
                    if v.Model[tr.Entity:GetClass()].DoFuncWhat then v.Model[tr.Entity:GetClass()].DoFuncWhat(self) end
                end
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

local col_H_D, col_ReColor = {}, {}
net.Receive("gRust_RadialDeployment", function()
    local ent = net.ReadEntity()
    local level = net.ReadFloat()
    col_H_D[ent] = level
end)

hook.Add("HUDPaint", "RadialMenu2_Draw", function()
    if not open then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local items = RadialMenu2.Items
    local n = #items
    local seg = 360 / n
    local gap = 1.5
    selected = GetSelected()
    RadialMenu2.Selected = GetSelected()
    draw.NoTexture()
    local trEnt = ply:GetEyeTrace().Entity
    local curLevel = IsValid(trEnt) and col_H_D[trEnt] or 0
    for i, item in ipairs(items) do
        local center = -90 + (i - 1) * seg
        local a0, a1 = center - seg / 2 + gap, center + seg / 2 - gap
        local hovered = i == selected
        surface.SetDrawColor(hovered and Color(60, 140, 255, 220) or Color(20, 20, 20, 190))
        local r1 = hovered and RadialMenu2.OuterRadius + 12 or RadialMenu2.OuterRadius
        surface.DrawPoly(ArcPoly(a0, a1, RadialMenu2.InnerRadius, r1))
        local mid = math.rad(center)
        local tr = (RadialMenu2.InnerRadius + RadialMenu2.OuterRadius) / 2
        local txtCol = color_white
        if item.UpgradeLevel and item.UpgradeLevel <= curLevel then
            txtCol = Color(64, 64, 64, 255) -- same or lower level: blacked out
        end

        draw.SimpleText(item.name, "RadialMenu2_Font", cx + math.cos(mid) * tr, cy + math.sin(mid) * tr, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local mat = items[selected] ~= nil and items[selected].Mat or ""
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