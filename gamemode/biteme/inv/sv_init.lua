-- =========================================================
-- Network strings
-- =========================================================
util.AddNetworkString("grust_MoveItem")
util.AddNetworkString("grust_RequestInv")
util.AddNetworkString("grust_SyncInv")
util.AddNetworkString("gRustSelectWep")
util.AddNetworkString("grust_LootOpen")
util.AddNetworkString("grust_LootUpdate")
util.AddNetworkString("grust_LootTake")
util.AddNetworkString("DeathScreen_Respawn")
util.AddNetworkString("DeathScreen_Info")
-- =========================================================
-- Inventory configuration
-- =========================================================
local INV, HOT, CLOTH = "Inventory", "HotBar", "Clothing"
local SIZE = {
    [INV] = 24,
    [HOT] = 6,
    [CLOTH] = 6
}

local CONT_ID = {
    [0] = INV,
    [1] = HOT,
    [2] = CLOTH
}

local CONT_INV = 0
local CONT_HOT = 1
local CONT_CLOTH = 2
local CONT_LOOT = 3
local CONT_LOOT_HOT = 4
local function ValidSlot(cont, slot)
    local max = SIZE[cont]
    return max ~= nil and isnumber(slot) and slot >= 1 and slot <= max and slot == math.floor(slot)
end

local function GetSlot(ply, slot)
    ply.GInv = ply.GInv or {}
    ply.GInv[slot] = ply.GInv[slot] or {}
    return ply.GInv[slot]
end

local function GetItem(ply, cont, slot)
    local data = ply.GInv and ply.GInv[slot]
    return data and data[cont]
end

local function SetItem(ply, cont, slot, item)
    GetSlot(ply, slot)[cont] = item
end

function GetEmptySlot(ply, cont)
    if not SIZE[cont] then return false, nil end
    for i = 1, SIZE[cont] do
        if not GetItem(ply, cont, i) then return true, i end
    end
    return false, nil
end

-- =========================================================
-- Item creation and syncing
-- =========================================================
local function MakeItem(name, dur, wep, count, slot)
    local def = RustOfficial.GetItem(name)
    if not def then return end
    return {
        id = name,
        dur = dur or 100,
        weapon = wep,
        Count = count or 1,
        wModel = def.wModel,
        slot = slot
    }
end

local function WriteItem(item)
    if not item then
        net.WriteString("")
        return
    end

    net.WriteString(item.id)
    net.WriteUInt(math.Clamp(math.floor(item.dur or 100), 0, 100), 7)
    net.WriteFloat(item.Count or 1)
end

function SendInv(ply)
    if not IsValid(ply) or not ply.GInv then return end
    net.Start("grust_SyncInv")
    for i = 1, SIZE[INV] do
        WriteItem(GetItem(ply, INV, i))
    end

    for i = 1, SIZE[HOT] do
        WriteItem(GetItem(ply, HOT, i))
    end

    for i = 1, SIZE[CLOTH] do
        WriteItem(GetItem(ply, CLOTH, i))
    end

    net.Send(ply)
end

function AddItemsToGmod(ply, cont, slot, name, dur, wep, count)
    if not IsValid(ply) then return false end
    if not ValidSlot(cont, slot) then return false end
    if GetItem(ply, cont, slot) then return false end
    local def = RustOfficial.GetItem(name)
    if not def then return false end
    local item = MakeItem(name, dur, wep, count, slot)
    if not item then return false end
    SetItem(ply, cont, slot, item)
    if wep ~= nil and def.func then def.func(ply) end
    SendInv(ply)
    return true
end

-- =========================================================
-- Find and remove items
-- =========================================================
local SEARCH = {HOT, INV}
function FindExistingItem(ply, itemID)
    if not IsValid(ply) or not ply.GInv then return nil end
    for _, cont in ipairs(SEARCH) do
        for i = 1, SIZE[cont] do
            local item = GetItem(ply, cont, i)
            if item and item.id == itemID then return cont, i end
        end
    end
    return nil
end

function GetSlots(ply, itemID)
    local cont, slot = FindExistingItem(ply, itemID)
    return slot, cont
end

local function RemoveFromSlot(ply, cont, slot, amount)
    if not IsValid(ply) then return false, 0 end
    if not ValidSlot(cont, slot) then return false, 0 end
    local item = GetItem(ply, cont, slot)
    if not item then return false, 0 end
    local have = item.Count or 1
    local take = math.min(amount or have, have)
    if take <= 0 then return false, 0 end
    if take >= have then
        SetItem(ply, cont, slot, nil)
    else
        item.Count = have - take
    end

    SendInv(ply)
    return true, take
end

function GInv_RemoveItem(ply, itemID, amount)
    if not IsValid(ply) then return false, 0 end
    local cont, slot = FindExistingItem(ply, itemID)
    if not cont then return false, 0 end
    return RemoveFromSlot(ply, cont, slot, amount)
end

function GInv_RemoveAmount(ply, itemID, amount)
    local left = amount
    while left > 0 do
        local cont, slot = FindExistingItem(ply, itemID)
        if not cont then break end
        local ok, taken = RemoveFromSlot(ply, cont, slot, left)
        if not ok then break end
        left = left - taken
    end
    return left <= 0, left
end

function CalcItem(ply, itemID)
    local cont, slot = FindExistingItem(ply, itemID)
    if not cont then return false, 0 end
    local item = GetItem(ply, cont, slot)
    return item ~= nil, item and (item.Count or 1) or 0
end

-- =========================================================
-- Add items / stacking
-- =========================================================
local ORDER_HOT_FIRST = {HOT, INV}
local ORDER_INV_FIRST = {INV, HOT}
local function FindItem(ply, itemID)
    local def = RustOfficial.GetItem(itemID)
    if not def then return nil end
    local max = def.Max or 1
    local order = def.weapon and ORDER_HOT_FIRST or ORDER_INV_FIRST
    -- Find an existing partial stack.
    for _, cont in ipairs(order) do
        for i = 1, SIZE[cont] do
            local item = GetItem(ply, cont, i)
            if item and item.id == itemID and (item.Count or 1) < max then return cont, i, true end
        end
    end

    -- Find an empty slot.
    for _, cont in ipairs(order) do
        local ok, slot = GetEmptySlot(ply, cont)
        if ok then return cont, slot, false end
    end
    return nil
end

function AddItemsToGmodeS(ply, name, dur, wep, amount)
    if not IsValid(ply) then return false, amount or 1 end
    local def = RustOfficial.GetItem(name)
    if not def then return false, amount or 1 end
    local want = math.max(1, math.floor(amount or 1))
    local max = math.max(1, math.floor(def.Max or 1))
    local left = want
    while left > 0 do
        local cont, slot, existing = FindItem(ply, name)
        if not cont then break end
        if existing then
            local item = GetItem(ply, cont, slot)
            if not item then break end
            local space = max - (item.Count or 1)
            local add = math.min(space, left)
            if add <= 0 then break end
            item.Count = (item.Count or 1) + add
            left = left - add
        else
            local add = math.min(max, left)
            if not AddItemsToGmod(ply, cont, slot, name, dur, wep, add) then break end
            left = left - add
        end
    end

    SendInv(ply)
    return left < want, left
end

function AddItemsToGmodCount(ply, name, dur, wep, amount)
    if not IsValid(ply) then return false end
    local cont, slot, existing = FindItem(ply, name)
    if not cont then return false end
    local item = GetItem(ply, cont, slot)
    if existing and item then
        item.Count = (item.Count or 1) + amount
    else
        if not AddItemsToGmod(ply, cont, slot, name, dur, wep, amount) then return false end
    end

    if wep ~= nil and def and def.func then def.func(ply) end
    SendInv(ply)
    return true
end

function GRUST_AddItem(ply, itemID, wep, dur, cont)
    if not IsValid(ply) then return false end
    if not RustOfficial.GetItem(itemID) then return false end
    cont = cont or INV
    local ok, slot = GetEmptySlot(ply, cont)
    if not ok then return false end
    return AddItemsToGmod(ply, cont, slot, itemID, dur, wep, 1), slot
end

function GRUST_DamageItem(ply, cont, slot, amount)
    local item = GetItem(ply, cont, slot)
    if not item then return end
    item.dur = math.max((item.dur or 100) - amount, 0)
    SendInv(ply)
end

-- =========================================================
-- Drop items
-- =========================================================
local function DropItem(ply, cont, slot)
    local item = GetItem(ply, cont, slot)
    if not item then return end
    local ent = ents.Create("item_bag")
    if not IsValid(ent) then return end
    ent:SetModel(item.wModel or "models/props_junk/cardboard_box004a.mdl")
    ent:SetItemName(item.id)
    ent:SetSizeItem(item.Count or 1)
    ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 50)
    ent:Spawn()
    ent:Activate()
    SetItem(ply, cont, slot, nil)
    local def = RustOfficial.GetItem(item.id)
    if def and def.weapon then
        local remaining = false
        for _, container in ipairs({INV, HOT}) do
            for i = 1, SIZE[container] do
                local other = GetItem(ply, container, i)
                if other and other.id == item.id then
                    remaining = true
                    break
                end
            end
        end

        if not remaining and ply:HasWeapon(def.weapon) then ply:StripWeapon(def.weapon) end
    end

    SendInv(ply)
end

-- =========================================================
-- Normal inventory movement
-- =========================================================
local lastMove = {}
net.Receive("grust_MoveItem", function(_, ply)
    if (lastMove[ply] or 0) > CurTime() then return end
    lastMove[ply] = CurTime() + 0.05
    if not ply.GInv then return end
    local fromCont = CONT_ID[net.ReadUInt(2)]
    local from = net.ReadUInt(8)
    local toContID = net.ReadUInt(2)
    local to = net.ReadUInt(8)
    local toCont = CONT_ID[toContID]
    if not fromCont or not ValidSlot(fromCont, from) then return end
    local a = GetItem(ply, fromCont, from)
    if not a then
        SendInv(ply)
        return
    end

    if to == 0 then
        DropItem(ply, fromCont, from)
        return
    end

    if not toCont or not ValidSlot(toCont, to) then return end
    if fromCont == toCont and from == to then return end
    local b = GetItem(ply, toCont, to)
    -- Stack same items.
    if b and a.id == b.id then
        local def = RustOfficial.GetItem(a.id)
        local max = def and (def.Max or 1) or 1
        local space = max - (b.Count or 1)
        if space > 0 then
            local moved = math.min(a.Count or 1, space)
            b.Count = (b.Count or 1) + moved
            a.Count = (a.Count or 1) - moved
            if a.Count <= 0 then SetItem(ply, fromCont, from, nil) end
            SendInv(ply)
            return
        end
    end

    -- Swap items.
    SetItem(ply, fromCont, from, b)
    SetItem(ply, toCont, to, a)
    if toCont == HOT then
        ply.SelectedITEMS = ply.SelectedITEMS or {}
        ply.SelectedITEMS[1] = {HOT, to, a.id}
    end

    SendInv(ply)
end)

-- =========================================================
-- Weapon selection
-- =========================================================
net.Receive("gRustSelectWep", function(_, ply)
    local num = net.ReadUInt(3)
    if num < 1 or num > SIZE[HOT] then return end
    local item = GetItem(ply, HOT, num)
    ply.SelectedITEMS = ply.SelectedITEMS or {}
    ply.SelectedITEMS[1] = item and {HOT, num, item.id} or nil
    if not item then
        if ply:HasWeapon("rust_hands") then ply:SelectWeapon("rust_hands") end
        return
    end

    local def = RustOfficial.GetItem(item.id)
    if not def then return end
    if not def.weapon then
        if def.func then
            def.func(ply)
            if ply:HasWeapon("rust_hands") then ply:SelectWeapon("rust_hands") end
        end
        return
    end

    if not ply:HasWeapon(def.weapon) and def.func then def.func(ply) end
    if ply:HasWeapon(def.weapon) then ply:SelectWeapon(def.weapon) end
end)

-- =========================================================
-- Corpse loot
-- =========================================================
local LOOT_DISTANCE = 100
local lootCooldown = {}
local openCooldown = {}
local function BuildLootData(rag)
    local data = {
        [CONT_LOOT] = {},
        [CONT_LOOT_HOT] = {}
    }

    for slot, containers in pairs(rag.LootInv or {}) do
        local invItem = containers[INV]
        local hotItem = containers[HOT]
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

local function CanLoot(ply, rag)
    if not IsValid(ply) or not ply:Alive() then return false end
    if not IsValid(rag) or not rag:IsRagdoll() then return false end
    if not rag.LootInv then return false end
    return ply:GetPos():DistToSqr(rag:GetPos()) <= LOOT_DISTANCE ^ 2
end

local function SendLoot(ply, rag, message)
    if not IsValid(ply) or not IsValid(rag) then return end
    net.Start(message)
    net.WriteEntity(rag)
    net.WriteTable(BuildLootData(rag))
    net.Send(ply)
end

hook.Add("PlayerUse", "gRust_CorpseLoot", function(ply, ent)
    if not IsValid(ent) or not ent:IsRagdoll() then return end
    if not ent.LootInv then return end
    if not CanLoot(ply, ent) then return true end
    if (openCooldown[ply] or 0) > CurTime() then return true end
    openCooldown[ply] = CurTime() + 0.5
    SendLoot(ply, ent, "grust_LootOpen")
    return true
end)

net.Receive("grust_LootTake", function(_, ply)
    if (lootCooldown[ply] or 0) > CurTime() then return end
    lootCooldown[ply] = CurTime() + 0.15
    local rag = net.ReadEntity()
    local containerID = net.ReadUInt(3)
    local slot = net.ReadUInt(8)
    if not CanLoot(ply, rag) then return end
    local containerName
    local maxSlots
    if containerID == CONT_LOOT then
        containerName = INV
        maxSlots = SIZE[INV]
    elseif containerID == CONT_LOOT_HOT then
        containerName = HOT
        maxSlots = SIZE[HOT]
    else
        return
    end

    if slot < 1 or slot > maxSlots then return end
    local corpseSlot = rag.LootInv[slot]
    local item = corpseSlot and corpseSlot[containerName]
    if not item or not item.id then
        SendLoot(ply, rag, "grust_LootUpdate")
        return
    end

    local amount = math.max(1, item.Count or 1)
    local _, left = AddItemsToGmodeS(ply, item.id, item.dur, item.weapon, amount)
    left = math.Clamp(tonumber(left) or amount, 0, amount)
    local transferred = amount - left
    if transferred <= 0 then
        SendLoot(ply, rag, "grust_LootUpdate")
        return
    end

    if left <= 0 then
        corpseSlot[containerName] = nil
    else
        item.Count = left
    end

    if not next(corpseSlot) then rag.LootInv[slot] = nil end
    SendInv(ply)
    SendLoot(ply, rag, "grust_LootUpdate")
end)

-- =========================================================
-- Death ragdoll and death screen
-- =========================================================
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

    -- Snapshot before PlayerSpawn resets GInv.
    rag.LootInv = table.Copy(ply.GInv or {})
    rag.DeathSteamID = ply:SteamID64()
    rag:Spawn()
    rag:Activate()
    rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    local phys = rag:GetPhysicsObject()
    if IsValid(phys) then phys:SetVelocity(ply:GetVelocity()) end
    ply.DeathRagdoll = rag
end)

hook.Add("PlayerDeathThink", "DeathScreen_BlockAuto", function(ply) if CurTime() < (ply.DeathTime or 0) + 5 then return true end end)
net.Receive("DeathScreen_Respawn", function(_, ply)
    if ply:Alive() then return end
    if CurTime() < (ply.DeathTime or 0) + 5 then return end
    ply:Spawn()
end)

-- =========================================================
-- Player setup
-- =========================================================
function GM:PlayerSetHandsModel(pl, ent)
    ent:SetModel("models/player/darky_m/rust/c_arms_human.mdl")
end

local ModelsP = {"models/player/Group01/male_04.mdl", "models/player/Group01/female_01.mdl", "models/player/Group01/female_05.mdl", "models/player/Group01/female_04.mdl", "models/player/Group01/female_03.mdl", "models/player/Group01/male_03.mdl", "models/player/Group01/male_07.mdl", "models/player/Group01/male_06.mdl", "models/player/Group01/male_01.mdl", "models/player/Group01/male_02.mdl"}
local SpawnsPos = {}
hook.Add("PlayerSpawn", "sendinv", function(ply)
    if not IsValid(ply) then return end
    ply:SetModel(ModelsP[math.random(#ModelsP)])
    ply.GInv = {}
    ply.SelectedITEMS = {}
    AddItemsToGmod(ply, HOT, 1, "Rock", math.random(50, 60), "rust_rock", 1)
    ply:Give("rust_hands")
    ply:SetHealth(math.random(45, 65))
    ply.Food = math.random(60, 80)
    ply.Water = math.random(60, 80)
    net.Start("gRust_Survival")
    net.WriteFloat(ply.Food)
    net.WriteFloat(ply.Water)
    net.Send(ply)
    ply:SetupHands()
    local saved = SpawnsPos[ply:SteamID64()]
    if saved then
        ply:SetPos(saved[2])
        ply:SetEyeAngles(saved[1])
    end
end)

net.Receive("grust_RequestInv", function(_, ply) SendInv(ply) end)
hook.Add("PlayerDisconnected", "grust_cleanup", function(ply)
    lastMove[ply] = nil
    lootCooldown[ply] = nil
    openCooldown[ply] = nil
    SpawnsPos[ply:SteamID64()] = {ply:EyeAngles(), ply:GetPos()}
end)