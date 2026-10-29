local function BackwardsEnums(enumname)
    local backenums = {}
    for k, v in pairs(_G) do
        if isstring(k) and string.find(k, "^" .. enumname) then backenums[v] = k end
    end
    return backenums
end

local multiPlyer = {
    ["rust_rock"] = 1
}

local function MakeTreeFall(ent)
    if not IsValid(ent) then return end
    local treePos = ent:GetPos() -- Store tree information for respawn
    local treeAngles = ent:GetAngles()
    local treeModel = ent:GetModel()
    ent:SetMoveType(MOVETYPE_VPHYSICS) -- Convert to physics object and make it fall
    ent:SetSolid(SOLID_VPHYSICS) -- Keep solid for world collision
    ent:PhysicsInit(SOLID_VPHYSICS)
    ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS) -- Don't collide with players but still with world
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(800) -- Realistic tree weight
        local fallDirection = Angle(0, math.random(0, 360), 0):Forward() -- Choose a random direction to fall (like wind direction)
        fallDirection.z = 0 -- Keep it horizontal
        fallDirection:Normalize()
        local torque = Vector(fallDirection.y, -fallDirection.x, 0) * 3000 -- Apply torque to make it tip over from the base (like a real tree)
        phys:ApplyTorqueCenter(torque)
        local push = fallDirection * 100 -- Small initial push in the fall direction
        push.z = -50 -- Slight downward force
        phys:ApplyForceCenter(push)
        phys:SetMass(800) -- Set the tree's center of mass higher to make it tip more naturally
    end

    ent.treeFallen = true
    timer.Simple(3, function()
        if IsValid(ent) then -- Start transparency fade after 3 seconds (give more time to see the fall)
            local alpha = 255
            local fadeTimer = "tree_fade_" .. ent:EntIndex()
            timer.Create(fadeTimer, 0.1, 40, function()
                if IsValid(ent) then -- Slower fade (4 seconds)
                    alpha = alpha - 6.375 -- Fade over 4 seconds (40 * 0.1 = 4s)
                    ent:SetColor(Color(255, 255, 255, math.max(0, alpha)))
                    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
                    if alpha <= 0 then
                        timer.Remove(fadeTimer)
                        ent:Remove()
                    end
                else
                    timer.Remove(fadeTimer)
                end
            end)
        end
    end)

    timer.Simple(math.random(300, 600), function()
        local newTree = ents.Create("rust_trees") -- Respawn tree after 10-15 minutes
        if IsValid(newTree) then
            newTree:SetModel(treeModel)
            newTree:SetPos(treePos)
            newTree:SetAngles(treeAngles)
            newTree:Spawn()
            newTree:Activate()
            newTree.treeHealth = nil -- Reset tree health so it can be chopped again
            newTree.treeHits = nil
            newTree.treeFallen = false
        end
    end)
end

local TREE_MODELS = {
    ["models/props_foliage/ah_super_large_pine002.mdl"] = 220,
    ["models/props_foliage/ah_large_pine.mdl"] = 190,
    ["models/props/cs_militia/tree_large_militia.mdl"] = 140,
    ["models/props_foliage/ah_medium_pine.mdl"] = 220,
    ["models/brg_foliage/tree_scotspine1.mdl"] = 160,
    ["models/props_foliage/ah_super_pine001.mdl"] = 180,
    ["models/props_foliage/ah_ash_tree001.mdl"] = 190,
    ["models/props_foliage/ah_ash_tree_cluster1.mdl"] = 140,
    ["models/props_foliage/ah_ash_tree_med.mdl"] = 170,
    ["models/props_foliage/ah_hawthorn_sm_static.mdl"] = 150,
    ["models/props_foliage/coldstream_cedar_trunk.mdl"] = 170,
    ["models/props_foliage/ah_ash_tree_lg.mdl"] = 190
}

local placeHolster = {5, 10, 20, 40, 80, 128}
hook.Add("EntityTakeDamage", "TakeWoodDmg", function(ent, dmginfo)
    local dmginfo_Attk = dmginfo:GetAttacker()
    if not IsValid(dmginfo_Attk) then return end
    local MAT = BackwardsEnums("MAT_")
    local item = RustOfficial.GetItem("Wood")
    local tr = dmginfo_Attk:GetEyeTrace()
    if not tr.Entity then return end
    if MAT[ent:GetMaterialType()] == "MAT_WOOD" and TREE_MODELS[tr.Entity:GetModel()] then
        if ent.amount == nil then ent.amount = 0 end
        if ent.amount >= #placeHolster then ent.amount = 0 end
        local mathd = GRUST_GetItemFromWep(dmginfo_Attk, "Wood")
        ent.amount = ent.amount + 1
        if mathd >= item.Max then ent.amount = 1 end
        AddItemsToGmodCount(dmginfo_Attk, item.name, 100, nil, placeHolster[ent.amount] * multiPlyer[dmginfo_Attk:GetActiveWeapon():GetClass()])
        local maxHP = TREE_MODELS[ent:GetModel()]
        if not ent.treeHealth then ent.treeHealth, ent.treeHits = maxHP, 0 end
        if ent.treeHealth == nil then return end
        ent.treeHealth, ent.treeHits = ent.treeHealth - 20, ent.treeHits + 1
        if ent.treeHealth <= 0 then MakeTreeFall(ent) end
    end
end)