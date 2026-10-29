local WORLD_LOOT = {
    {
        class = "rust_ores",
    },
}

local MAX_WORLD_BAGS = 500
local RESPAWN_EVERY = 30 -- seconds
local worldBags = {}
local function FindRandomSpot()
    local mins, maxs = game.GetWorld():GetModelBounds()
    for _ = 1, 50 do
        local p = Vector(math.Rand(mins.x, maxs.x), math.Rand(mins.y, maxs.y), math.Rand(mins.z, maxs.z))
        if not util.IsInWorld(p) then continue end
        local tr = util.TraceLine({
            start = p,
            endpos = p - Vector(0, 0, 4000),
            mask = MASK_SOLID_BRUSHONLY
        })

        if tr.Hit and not tr.StartSolid and not tr.HitSky and tr.HitNormal.z > 0.7 and bit.band(util.PointContents(tr.HitPos + Vector(0, 0, 10)), CONTENTS_WATER) == 0 then return tr.HitPos + Vector(0, 0, 10) end
    end
end

local function SpawnWorldBag()
    local pos = FindRandomSpot()
    if not pos then
        print("[worldloot] no valid spot found")
        return
    end

    local entry = WORLD_LOOT[math.random(#WORLD_LOOT)]
    local ent = ents.Create(entry.class)
    if not IsValid(ent) then
        print("[worldloot] couldn't create " .. entry.class)
        return
    end

    ent:SetPos(pos)
    ent:Spawn()
    ent:Activate()
    worldBags[#worldBags + 1] = ent
end

local function TopUpWorldBags()
    for i = #worldBags, 1, -1 do
        if not IsValid(worldBags[i]) then table.remove(worldBags, i) end
    end

    for _ = #worldBags + 1, MAX_WORLD_BAGS do
        SpawnWorldBag()
    end
end

hook.Add("InitPostEntity", "grust_worldloot", function()
    TopUpWorldBags()
    timer.Create("grust_worldloot", RESPAWN_EVERY, 0, TopUpWorldBags)
end)