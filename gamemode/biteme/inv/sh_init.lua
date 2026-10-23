RustOfficial = RustOfficial or {}
RustOfficial.ITEMS = {
    Rock = {
        name = "Rock",
        color = Color(200, 60, 60),
        image = "materials/items/tools/rock.png",
        func = function(ply) ply:Give("rust_rock") end,
        weapon = "rust_rock",
        Max = 1,
    },
    Wood = {
        name = "Wood",
        color = Color(200, 60, 60),
        image = "materials/items/resources/wood.png",
        func = function(ply) end,
        weapon = nil,
        Max = 1000,
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
    },
}

function RustOfficial.GetItem(id)
    return RustOfficial.ITEMS[id]
end