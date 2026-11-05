ITEMS:RegisterItem("Cloth", {
    Name = "Cloth",
    Info = "For bandages etc",
    Category = "ADMIN",
    InfoTag = "Cloth",
    model = "materials/items/resources/cloth.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 500,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "Cloth",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")

ITEMS:RegisterItem("AnimalFat", {
    Name = "Animal Fat",
    Info = "For bandages etc",
    InfoTag = "AnimalFat",
    Category = "ADMIN",
    model = "materials/items/resources/animal_fat.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 200,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "AnimalFat",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")

ITEMS:RegisterItem("Wood", {
    Name = "Wood",
    Info = "For upgrading your base!",
    InfoTag = "Wood",
    Category = "ADMIN",
    model = "materials/items/resources/wood.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 2000,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "Wood",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")

ITEMS:RegisterItem("MetalOre", {
    Name = "Metal Fragments",
    Info = "For Pickaxes etc",
    InfoTag = "MetalOre",
    Category = "ADMIN",
    model = "materials/items/resources/metal_fragments.png",
    Weapon = "",
    Count = 50,
    Stackable = true,
    StackSize = 2000,
    IzAdmin = true,
    Craft = function()
        return {
            {
                Time = 0,
                CanCraft = false,
                {
                    ITEM = "MetalOre",
                    AMOUNT = 0,
                },
            },
        }
    end,
}, "ADMIN")