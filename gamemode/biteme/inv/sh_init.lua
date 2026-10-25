RustOfficial = RustOfficial or {}
RustOfficial.ITEMS = {
    Rock = {
        name = "Rock",
        color = Color(200, 60, 60),
        image = "materials/items/tools/rock.png",
        func = function(ply) ply:Give("rust_rock") end,
        weapon = "rust_rock",
        Max = 1,
        wModel = "models/weapons/darky_m/rust/w_rock.mdl",
    },
    Wood = {
        name = "Wood",
        color = Color(200, 60, 60),
        image = "materials/items/resources/wood.png",
        func = function(ply) end,
        weapon = nil,
        Max = 1000,
        wModel = "models/environment/misc/loot_bag.mdl"
    },
    GarageDoor = {
        name = "Garage Door",
        color = Color(200, 60, 60),
        image = "materials/items/deployable/garage_door.png",
        func = function(ply)
            if SERVER then
                DEPLOY.FItem(ply, "sent_garagedoor")
                local emptySlot, Slot = FindItems(ply, "GarageDoor")
                ply.GInv[Slot] = nil
                SendInv(ply)
            end
        end,
        weapon = nil,
        Max = 1000,
        wModel = "models/environment/misc/loot_bag.mdl"
    },
    Builder = {
        name = "Building Plan",
        color = Color(200, 60, 60),
        image = "materials/items/misc/blueprint.png",
        func = function(ply) ply:Give("rust_builder") end,
        weapon = "rust_builder",
        Max = 1000,
        wModel = "models/environment/misc/loot_bag.mdl"
    },
}

function RustOfficial.GetItem(key)
    local items = RustOfficial.ITEMS -- adjust to your table name
    if items[key] then return items[key] end
    for id, def in pairs(items) do
        if def.name == key then return def, id end
    end
end