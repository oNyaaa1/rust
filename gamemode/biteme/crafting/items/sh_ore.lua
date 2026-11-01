ITEMS:RegisterItem("Sulfur", {
    Name = "Sulfur Ore",
    Info = "For smelting and crafting stuff",
    Category = "ADMIN",
    InfoTag = "Sulfur",
    model = "materials/items/resources/sulfur_ore.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 1000,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "Sulfur Ore",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")

ITEMS:RegisterItem("Metal", {
    Name = "Metal Ore",
    Info = "For smelting and crafting stuff",
    Category = "ADMIN",
    InfoTag = "Metal",
    model = "materials/items/resources/metal_ore.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 1000,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "Metal Ore",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")

ITEMS:RegisterItem("Stone", {
    Name = "Stone",
    Info = "Used for upgrading your base!",
    InfoTag = "Stone",
    Category = "ADMIN",
    model = "materials/items/resources/stone.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    IzAdmin = true,
    StackSize = 1000,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "Stone",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")