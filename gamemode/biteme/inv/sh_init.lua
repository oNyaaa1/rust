RustOfficial = RustOfficial or {}
RustOfficial.GhostGD = {}
RustOfficial.GhostGD.GhostModel = ""
if SERVER then
    util.AddNetworkString("SendClientinfoGDL")
    util.AddNetworkString("GarageDoorPlaceL")
    local IDS = {
        ["rust_furnace"] = "Furnace",
        ["sent_garagedoor"] = "GarageDoor",
    }

    net.Receive("GarageDoorPlaceL", function(len, ply)
        local bang = net.ReadString()
        local pos, ang, name = DEPLOY:GetSocket(ply, bang)
        if name ~= "doorwayl" and IDS[bang] == "GarageDoor" then return end
        print(IDS[bang], bang)
        DEPLOY.FItem(ply, bang, pos, ang)
        DeleteItem(ply, IDS[bang])
        SendInv(ply)
    end)
end

RustOfficial.ITEMS = {
    Rock = {
        name = "Rock",
        color = Color(200, 60, 60),
        image = "materials/items/tools/rock.png",
        func = function(ply) ply:Give("rust_rock") end,
        weapon = "rust_rock",
        Max = 1,
        wModel = "models/weapons/darky_m/rust/w_rock.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Charcoal = {
        name = "Charcoal",
        color = Color(200, 60, 60),
        image = "materials/items/resources/charcoal.png",
        func = function(ply) end,
        weapon = nil,
        Max = 1,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Hammer = {
        name = "Hammer",
        color = Color(200, 60, 60),
        image = "materials/items/tools/hammer.png",
        func = function(ply) ply:Give("rust_hammer") end,
        weapon = "rust_hammer",
        Max = 1,
        wModel = "models/weapons/darky_m/rust/w_hammer.mdl",
        Craftable = true,
        BluePrint = false,
    },
    GarageDoor = {
        name = "Garage Door",
        color = Color(200, 60, 60),
        image = "materials/items/deployable/garage_door.png",
        func = function(ply)
            if SERVER then
                ply.SelectedGarageDoor = nil
                net.Start("SendClientinfoGDL")
                net.WriteBool(true)
                net.WriteString("sent_garagedoor")
                net.Send(ply)
            end
        end,
        weapon = nil,
        Max = 1000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = true,
    },
    Builder = {
        name = "Building Plan",
        color = Color(200, 60, 60),
        image = "materials/items/misc/blueprint.png",
        func = function(ply) ply:Give("rust_builder") end,
        weapon = "rust_builder",
        Max = 1000,
        wModel = "models/weapons/darky_m/rust/w_buildingplan.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Wood = {
        name = "Wood",
        color = Color(200, 60, 60),
        image = "materials/items/resources/wood.png",
        func = function(ply) end,
        weapon = nil,
        Max = 2000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = false,
        BluePrint = false,
    },
    Stone = {
        name = "Stone",
        color = Color(200, 60, 60),
        image = "materials/items/resources/stone.png",
        func = function(ply) end,
        weapon = nil,
        Max = 2000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Sulfur = {
        name = "Sulfur",
        color = Color(200, 60, 60),
        image = "materials/items/resources/sulfur_ore.png",
        func = function(ply) end,
        weapon = nil,
        Max = 2000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Metal = {
        name = "Metal",
        color = Color(200, 60, 60),
        image = "materials/items/resources/metal_ore.png",
        func = function(ply) end,
        weapon = nil,
        Max = 2000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = false,
    },
    Furnace = {
        name = "Furnace",
        color = Color(200, 60, 60),
        image = "materials/items/deployable/furnace.png",
        func = function(ply)
            if SERVER then
                ply.SelectedGarageDoor = nil
                net.Start("SendClientinfoGDL")
                net.WriteBool(true)
                net.WriteString("rust_furnace")
                net.Send(ply)
            end
        end,
        weapon = nil,
        Max = 2000,
        wModel = "models/environment/misc/loot_bag.mdl",
        Craftable = true,
        BluePrint = false,
    },
}

function RustOfficial.GetItem(key)
    local items = RustOfficial.ITEMS -- adjust to your table name
    if items[key] then return items[key] end
    for id, def in pairs(items) do
        if def.name == key then return def, id end
    end
end

if CLIENT then
    local classes = ""
    net.Receive("SendClientinfoGDL", function()
        local ply = LocalPlayer()
        local bool = net.ReadBool()
        classes = net.ReadString()
        if IsValid(RustOfficial.GhostGD.Ghost) then RustOfficial.GhostGD.Ghost:Remove() end
        print(classes, bool)
        local function GetModelFor(class)
            local ent = scripted_ents.Get(class or "")
            if not ent then return end
            local m = ent.Model or ent.Models
            if istable(m) then m = m[1] end
            return isstring(m) and m or nil
        end

        local model = GetModelFor(classes)
        print(model)
        util.PrecacheModel(model)
        RustOfficial.GhostGD.Ghost = ClientsideModel(model, RENDERGROUP_TRANSLUCENT)
        RustOfficial.GhostGD.GhostModel = model
        RustOfficial.GhostGD.Ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
        RustOfficial.GhostGD.Ghost:SetColor(Color(255, 255, 255, 120))
        ply.SelectedGarageDoor = true
    end)

    hook.Add("Think", "GarageDoor", function()
        local ply = LocalPlayer()
        if not RustOfficial.GhostGD then RustOfficial.GhostGD = {} end
        if ply.SelectedGarageDoor == nil then ply.SelectedGarageDoor = false end
        if not ply.CoolDownCDL then ply.CoolDownCD = 0 end
        if ply.SelectedGarageDoor and IsValid(RustOfficial.GhostGD.Ghost) then
            local pos, ang = DEPLOY:GetSocket(ply, classes)
            if not isvector(pos) or not isangle(ang) then return end
            RustOfficial.GhostGD.Ghost:SetPos(pos)
            RustOfficial.GhostGD.Ghost:SetAngles(ang)
            if ply:KeyDown(IN_ATTACK) and ply.CoolDownCD <= CurTime() then
                ply.SelectedGarageDoor = false
                net.Start("GarageDoorPlaceL")
                net.WriteString(classes)
                net.SendToServer()
                ply.CoolDownCD = CurTime() + 1
            end
        elseif ply.SelectedGarageDoor == false then
            if IsValid(RustOfficial.GhostGD.Ghost) then
                RustOfficial.GhostGD.Ghost:Remove()
                RustOfficial.GhostGD.Ghost = nil
            end
        end
    end)
end