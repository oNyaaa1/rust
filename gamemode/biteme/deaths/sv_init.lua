util.AddNetworkString("DeathScreen_Respawn")
util.AddNetworkString("DeathScreen_Info")
util.AddNetworkString("grust_LootOpen")
util.AddNetworkString("grust_LootUpdate")
util.AddNetworkString("grust_LootTake")
local CONT_INV = 0
local CONT_HOT = 1
local CONT_LOOT = 3
local CONT_LOOT_HOT = 4
local LOOT_DISTANCE = 100
local LOOT_COOLDOWN = 0.15
local lastLoot = {}
-- Convert the corpse inventory into the format used by cl_slots.lua.
local function BuildLootData(rag)
    local data = {
        [CONT_LOOT] = {},
        [CONT_LOOT_HOT] = {}
    }

    for slot, containers in pairs(rag.LootInv or {}) do
        local invItem = containers.Inventory
        local hotItem = containers.HotBar
        if invItem then
            data[CONT_LOOT][slot] = {
                id = invItem.id,
                dur = invItem.dur,
                count = invItem.Count
            }
        end

        if hotItem then
            data[CONT_LOOT_HOT][slot] = {
                id = hotItem.id,
                dur = hotItem.dur,
                count = hotItem.Count
            }
        end
    end
    return data
end

local function SendLoot(ply, rag, networkName)
    if not IsValid(ply) or not IsValid(rag) then return end
    net.Start(networkName)
    net.WriteEntity(rag)
    net.WriteTable(BuildLootData(rag))
    net.Send(ply)
end

local function CanLoot(ply, rag)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not IsValid(rag) or not rag:IsRagdoll() then return false end
    if not rag.LootInv then return false end
    if ply:GetPos():DistToSqr(rag:GetPos()) > LOOT_DISTANCE * LOOT_DISTANCE then return false end
    return true
end

-- Death screen information.
hook.Add("PlayerDeath", "DeathScreen_Time", function(victim, inflictor, attacker)
    victim.DeathTime = CurTime()
    local name = ""
    if IsValid(attacker) then name = attacker:IsPlayer() and attacker:Nick() or attacker:GetClass() end
    if attacker == victim then name = "yourself" end
    net.Start("DeathScreen_Info")
    net.WriteString(name)
    net.Send(victim)
end)

hook.Add("PlayerDeath", "Death_CreateRagdoll", function(ply)
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return end
    rag:SetModel(ply:GetModel())
    rag:SetPos(ply:GetPos())
    rag:SetAngles(ply:GetAngles())
    rag:SetSkin(ply:GetSkin())
    for _, bodygroup in ipairs(ply:GetBodyGroups()) do
        rag:SetBodygroup(bodygroup.id, ply:GetBodygroup(bodygroup.id))
    end

    -- Save inventory before PlayerSpawn resets GInv.
    rag.LootInv = table.Copy(ply.GInv or {})
    rag.DeathSteamID = ply:SteamID64()
    rag:Spawn()
    rag:Activate()
    rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    local phys = rag:GetPhysicsObject()
    if IsValid(phys) then phys:SetVelocity(ply:GetVelocity()) end
    ply.DeathRagdoll = rag
end)

hook.Add("PlayerUse", "DeathUse", function(ply, ent)
    if not IsValid(ent) or not ent:IsRagdoll() then return end
    if not ent.LootInv then return end
    if not CanLoot(ply, ent) then return true end
    SendLoot(ply, ent, "grust_LootOpen")
    return true
end)

-- Take an item from a corpse.
net.Receive("grust_LootTake", function(_, ply)
    if (lastLoot[ply] or 0) > CurTime() then return end
    lastLoot[ply] = CurTime() + LOOT_COOLDOWN
    local rag = net.ReadEntity()
    local containerID = net.ReadUInt(3)
    local slot = net.ReadUInt(8)
    if not CanLoot(ply, rag) then return end
    if not isnumber(slot) or slot < 1 or slot > 24 and containerID == CONT_LOOT then return end
    if slot < 1 or slot > 6 and containerID == CONT_LOOT_HOT then return end
    local containerName
    if containerID == CONT_LOOT then
        containerName = "Inventory"
    elseif containerID == CONT_LOOT_HOT then
        containerName = "HotBar"
    else
        return
    end

    local corpseSlot = rag.LootInv[slot]
    local item = corpseSlot and corpseSlot[containerName]
    if not item or not item.id then
        SendLoot(ply, rag, "grust_LootUpdate")
        return
    end

    local amount = item.Count or 1
    -- AddItemsToGmodeS returns the amount that could not fit.
    local added, left = AddItemsToGmodeS(ply, item.id, item.dur, item.weapon, amount)
    local transferred = amount - left
    if transferred <= 0 then
        SendLoot(ply, rag, "grust_LootUpdate")
        return
    end

    -- Remove only the amount successfully transferred.
    if transferred >= amount then
        corpseSlot[containerName] = nil
    else
        item.Count = amount - transferred
    end

    if table.IsEmpty(corpseSlot) then rag.LootInv[slot] = nil end
    SendInv(ply)
    SendLoot(ply, rag, "grust_LootUpdate")
end)

hook.Add("PlayerDisconnected", "DeathLoot_Cleanup", function(ply) lastLoot[ply] = nil end)
-- Death screen respawn delay.
hook.Add("PlayerDeathThink", "DeathScreen_BlockAuto", function(ply) if CurTime() < (ply.DeathTime or 0) + 5 then return true end end)
net.Receive("DeathScreen_Respawn", function(_, ply)
    if ply:Alive() then return end
    if CurTime() < (ply.DeathTime or 0) + 5 then return end
    ply:Spawn()
end)