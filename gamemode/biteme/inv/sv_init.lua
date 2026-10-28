util.AddNetworkString("grust_MoveItem") -- client -> server
util.AddNetworkString("grust_RequestInv") -- client -> server
util.AddNetworkString("grust_SyncInv") -- server -> client
util.AddNetworkString("gRustSelectWep")
local INV, HOT, CLOTH = "Inventory", "HotBar", "Clothing"
local SIZE = {
    [INV] = 30,
    [HOT] = 6,
    [CLOTH] = 6
}

-- network id -> container name (must match the client's CONT_INV/CONT_HOT/CONT_CLOTH)
local CONT_ID = {
    [0] = INV,
    [1] = HOT,
    [2] = CLOTH
}

local function GetMaxStack(id)
    local def = RustOfficial.GetItem(id)
    return def and def.Max or 1
end

local function GetSlot(ply, slot)
    ply.GInv = ply.GInv or {}
    ply.GInv[slot] = ply.GInv[slot] or {}
    return ply.GInv[slot]
end

local function GetSlots(ply, item)
    ply.GInv = ply.GInv or {}
    local items = nil
    for k, v in pairs(ply.GInv) do
        for _, j in pairs(v) do
            if j["id"] == item then
                items = k
                break
            end
        end
    end
    return items
end

local function GetItem(ply, cont, slot)
    local s = ply.GInv and ply.GInv[slot]
    return s and s[cont]
end

local function SetItem(ply, cont, slot, item)
    GetSlot(ply, slot)[cont] = item
end

local function ValidSlot(cont, slot)
    local max = cont and SIZE[cont]
    return max ~= nil and slot >= 1 and slot <= max
end

-- can this item be placed in this container?
-- clothing is permissive until your item defs have a clothing flag, then enable the line below
local function CanPlace(cont, it)
    if not it then -- moving "nothing" is always fine
        return true
    end

    if cont == CLOTH then
        local def = RustOfficial.GetItem(it.id)
        if not def then return false end
        -- return def.clothing == true
    end
    return true
end

function GetEmptySlot(ply, cont)
    for i = 1, SIZE[cont] do
        if not GetItem(ply, cont, i) then return true, i end
    end
    return false, nil
end

local function WriteItem(it)
    if it then
        net.WriteString(it.id)
        net.WriteUInt(math.Clamp(math.floor(it.dur or 100), 0, 100), 7)
        net.WriteFloat(it.Count or 1)
    else
        net.WriteString("")
    end
end

-- order: 30 inventory slots, 6 hotbar slots, 6 clothing slots (client reader must match)
function SendInv(ply)
    if not ply.GInv then return end
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

local function MakeItem(name, dur, wep, count, model, slot)
    local def = RustOfficial.GetItem(name)
    return {
        id = name,
        dur = dur or 100,
        weapon = wep,
        Count = count or 1,
        wModel = def.wModel,
        slot = slot,
    }
end

-- generic add into a specific container/slot
function AddItemsToGmod(ply, cont, slot, name, dur, wep, count)
    if not ValidSlot(cont, slot) then return false end
    local def = RustOfficial.GetItem(name)
    if not def then return false end
    SetItem(ply, cont, slot, MakeItem(name, dur, wep, count, slot))
    if wep ~= nil and def.func then def.func(ply) end
    SendInv(ply)
    return true
end

-- remove `amount` from a specific container/slot (nil amount = remove the whole stack)
-- returns removed(bool), amountRemoved
function GInv_RemoveItem(ply, cont, slot, amount)
    if not IsValid(ply) or not ply.GInv then return false, 0 end
    if not ValidSlot(cont, slot) then return false, 0 end
    local it = GetItem(ply, cont, slot)
    if not it then return false, 0 end
    local have = it.Count or 1
    local take = math.min(amount or have, have)
    if take >= have then
        SetItem(ply, cont, slot, nil)
    else
        it.Count = have - take
    end

    SendInv(ply)
    return true, take
end

-- auto-search never includes CLOTH, so resources/weapons are never auto-placed there
local SEARCH = {HOT, INV}
-- finds the first slot that actually contains the item
-- returns cont, slot (or nil if the player doesn't have it)
function FindExistingItem(ply, item)
    for _, cont in ipairs(SEARCH) do
        for i = 1, SIZE[cont] do
            local it = GetItem(ply, cont, i)
            if it and it.id == item then return cont, i end
        end
    end
    return nil
end

function GInv_RemoveAmount(ply, item, amount)
    local left = amount
    while left > 0 do
        local cont, slot = FindExistingItem(ply, item)
        if not cont then break end
        local ok, taken = GInv_RemoveItem(ply, cont, slot, left)
        if not ok then break end
        left = left - taken
    end
    return left <= 0, left -- success, amount still missing
end

-- returns cont, slot, existing  (or nil if there is no room anywhere)
function FindItems(ply, item)
    local def = RustOfficial.GetItem(item)
    if not def then return nil end
    for _, cont in ipairs(SEARCH) do
        for _, v in pairs(ply.GInv[def.slot]) do
            if v[1] == cont then return cont, v[2], false end
        end
    end
    return nil
end

local ORDER_HOT_FIRST = {
    HOT, -- weapons/tools: hotbar first
    INV
}

local ORDER_INV_FIRST = {
    INV, -- resources like Wood: inventory first
    HOT
}

local function GetAddOrder(def)
    -- anything that isn't a weapon goes to the inventory first
    if def.weapon then return ORDER_HOT_FIRST end
    return ORDER_INV_FIRST
end

-- returns cont, slot, existing (or nil if there is no room anywhere)
function FindItem(ply, item)
    local def = RustOfficial.GetItem(item)
    if not def then return nil end
    local max = def.Max or 1
    local order = GetAddOrder(def)
    -- 1) partial stack of the same item
    for _, cont in ipairs(order) do
        for i = 1, SIZE[cont] do
            local it = GetItem(ply, cont, i)
            if it and it.id == item and (it.Count or 1) < max then return cont, i, true end
        end
    end

    -- 2) first empty slot (in preferred order)
    for _, cont in ipairs(order) do
        local ok, slot = GetEmptySlot(ply, cont)
        if ok then return cont, slot, false end
    end
    return nil -- full
end

function FindItemsNew(ply, item)
    local def = RustOfficial.GetItem(item)
    local slots = GetSlots(ply, item)
    if not def then return nil end
    for _, cont in ipairs(SEARCH) do
        local tbl = istable(GetSlot(ply, slots)[cont]) and GetSlot(ply, slots)[cont] or {}
        for _, v in pairs(tbl) do
            return v
        end
    end
    return nil
end

local function findInvSlot(ply, item)
    local inv = ply.GInv
    local works = {}
    local cont = ""
    local slot = 0
    local bool = false
    for new = 1, 50 do
        if inv[new] == nil then continue end
        for k, v in pairs(SIZE) do
            for i = 1, #inv[new] do
                if istable(inv[i][k]) then
                    PrintTable(inv[i][k])
                    works = inv[i][k]
                    slot = i
                    cont = k
                    bool = true
                    break
                end
            end
        end
    end
    return works, bool, cont, slot
end

function DeleteItem(ply, itemID)
    local sel = ply.SelectedITEMS and ply.SelectedITEMS[1]
    if not sel then return false end
    local s = ply.GInv and ply.GInv[sel[2]]
    local it = s and s[sel[1]]
    local wep = ply:GetActiveWeapon()
    if not it or it.id ~= itemID then -- selected item isn't the door, delete nothing
        return false
    end

    if it.id == "GarageDoor" and wep:GetClass() == "rust_hands" then
        s[sel[1]] = nil
        return true
    end

    if (it.Count or 1) > 1 then
        it.Count = it.Count - 1
    else
        s[sel[1]] = nil
    end
    return true
end

-- add into 
-- add into stacks / first empty slots
-- returns added(bool), leftover(number)
function AddItemsToGmodeS(ply, name, dur, wep, size)
    local def = RustOfficial.GetItem(name)
    if not def then return false, size or 1 end
    local want = size or 1
    local max = def.Max or 1
    local left = want
    while left > 0 do
        local cont, slot, existing = FindItem(ply, name)
        if not cont then -- everything full
            break
        end

        if existing then
            local it = GetItem(ply, cont, slot)
            local add = math.min(max - (it.Count or 1), left)
            it.Count = (it.Count or 1) + add
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
    local def = RustOfficial.GetItem(name)
    if not def then return false end
    local cont, slot, existing = FindItem(ply, name)
    if not cont then return false end
    local cur = existing and GetItem(ply, cont, slot).Count or 0
    SetItem(ply, cont, slot, MakeItem(name, dur, wep, math.Clamp(math.Round(cur + amount), 0, def.Max), slot))
    SendInv(ply)
    return true
end

function GRUST_AddItem(ply, itemID, wep, dur, cont)
    if not RustOfficial.GetItem(itemID) then return false end
    cont = cont or INV
    local ok, slot = GetEmptySlot(ply, cont)
    if not ok then return false end
    SetItem(ply, cont, slot, MakeItem(itemID, dur, wep, 1, slot))
    SendInv(ply)
    return true, slot
end

function GRUST_DamageItem(ply, cont, slot, amount)
    local it = GetItem(ply, cont, slot)
    if not it then return end
    it.dur = math.max(it.dur - amount, 0)
    SendInv(ply)
end

concommand.Add("grust_giveitem", function(ply, _, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    if not GRUST_AddItem(ply, args[1] or "red") then ply:ChatPrint("Inventory full") end
end)

net.Receive("grust_RequestInv", function(_, ply) SendInv(ply) end)
-- drop
local function DropItem(ply, cont, slot)
    local it = GetItem(ply, cont, slot)
    if not it then return end
    local ent = ents.Create("item_bag")
    ent:SetModel(it.wModel)
    ent:SetItemName(it.id)
    ent:SetSizeItem(it.Count)
    ent:Spawn()
    ent:Activate()
    ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 50)
    SetItem(ply, cont, slot, nil)
    local def = RustOfficial.GetItem(it.id)
    if def and def.weapon then
        local remaining = false
        for _, c in ipairs({INV, HOT}) do
            for i = 1, SIZE[c] do
                local o = GetItem(ply, c, i)
                if o and o.id == it.id then
                    remaining = true
                    break
                end
            end
        end

        if not remaining and ply:HasWeapon(def.weapon) then ply:StripWeapon(def.weapon) end
    end

    SendInv(ply)
end

function GRUST_FindStackableSlot(ply, wepID)
    for _, c in ipairs({INV, HOT}) do
        for i = 1, SIZE[c] do
            local it = GetItem(ply, c, i)
            if it and it.id == wepID and it.Count < GetMaxStack(it.id) then return c, i, it end
        end
    end
end

function GRUST_GetItemFromWep(ply, wepID)
    local total = 0
    for _, c in ipairs({INV, HOT}) do
        for i = 1, SIZE[c] do
            local it = GetItem(ply, c, i)
            if it and it.id == wepID and it.Count < GetMaxStack(it.id) then total = total + it.Count end
        end
    end
    return total
end

local lastMove = {}
net.Receive("grust_MoveItem", function(_, ply)
    if (lastMove[ply] or 0) > CurTime() then return end
    lastMove[ply] = CurTime() + 0.05
    if not ply.GInv then return end
    -- ids come in as numbers, convert them to container names
    local fromCont = CONT_ID[net.ReadUInt(2)]
    local from = net.ReadUInt(8)
    local toCont = CONT_ID[net.ReadUInt(2)]
    local to = net.ReadUInt(8)
    if not fromCont or not ValidSlot(fromCont, from) then return end
    if not GetItem(ply, fromCont, from) then
        SendInv(ply)
        return
    end

    -- to == 0 means drop into the world
    if to == 0 then
        DropItem(ply, fromCont, from)
        return
    end

    if not toCont or not ValidSlot(toCont, to) then return end
    if fromCont == toCont and from == to then return end
    local a, b = GetItem(ply, fromCont, from), GetItem(ply, toCont, to)
    -- both directions of the swap must be allowed (e.g. clothing rules)
    if not CanPlace(toCont, a) or not CanPlace(fromCont, b) then
        SendInv(ply) -- snap the client UI back
        return
    end

    SetItem(ply, fromCont, from, b)
    SetItem(ply, toCont, to, a)
    -- only treat the destination as the selected slot when it is the hotbar
    local item = GetItem(ply, toCont, to)
    if toCont == HOT then ply.SelectedITEMS[1] = {HOT, to, item.id} end
    SendInv(ply)
end)

net.Receive("gRustSelectWep", function(_, ply)
    local num = net.ReadUInt(3)
    if num < 1 or num > SIZE[HOT] then return end
    local item = GetItem(ply, HOT, num)
    ply.SelectedITEMS[1] = {HOT, num, item.id}
    if not item then
        ply:SelectWeapon("rust_hands")
        return
    end

    local def = RustOfficial.GetItem(item.id)
    if not def then return end
    if not def.weapon then
        if def.func then
            def.func(ply)
            ply:SelectWeapon("rust_hands")
        end
        return
    end

    if not ply:HasWeapon(def.weapon) and def.func then def.func(ply) end
    if ply:HasWeapon(def.weapon) then ply:SelectWeapon(def.weapon) end
end)

function GM:PlayerSetHandsModel(pl, ent)
    ent:SetModel("models/player/darky_m/rust/c_arms_human.mdl")
end

local SpawnsPos = {}
local ModelsP = {"models/player/Group01/male_04.mdl", "models/player/Group01/female_01.mdl", "models/player/Group01/female_05.mdl", "models/player/Group01/female_04.mdl", "models/player/Group01/female_03.mdl", "models/player/Group01/male_03.mdl", "models/player/Group01/male_07.mdl", "models/player/Group01/male_06.mdl", "models/player/Group01/male_01.mdl", "models/player/Group01/male_02.mdl"}
hook.Add("PlayerSpawn", "sendinv", function(ply)
    if not IsValid(ply) and not ply:IsFullyAuthenticated() then return end
    ply:SetModel(ModelsP[math.random(#ModelsP)])
    ply.GInv = {}
    ply.SelectedITEMS = {}
    AddItemsToGmod(ply, HOT, 1, "Rock", math.random(50, 60), "rust_rock", 1)
    AddItemsToGmod(ply, INV, 1, "GarageDoor", math.random(50, 60), nil, 1)
    AddItemsToGmod(ply, INV, 2, "GarageDoor", math.random(50, 60), nil, 1)
    AddItemsToGmod(ply, INV, 3, "GarageDoor", math.random(50, 60), nil, 1)
    AddItemsToGmod(ply, INV, 4, "Builder", math.random(50, 60), nil, 1)
    AddItemsToGmod(ply, INV, 5, "Hammer", math.random(50, 60), nil, 1)
    ply:Give("rust_hands")
    ply:SetHealth(math.random(45, 65))
    ply.Food = math.random(60, 80)
    ply.Water = math.random(60, 80)
    net.Start("gRust_Survival") -- make sure this is registered elsewhere
    net.WriteFloat(ply.Food)
    net.WriteFloat(ply.Water)
    net.Send(ply)
    ply:SetupHands()
    if SpawnsPos[ply:SteamID64()] then
        ply:SetPos(SpawnsPos[ply:SteamID64()][2])
        ply:SetEyeAngles(SpawnsPos[ply:SteamID64()][1])
    end
end)

hook.Add("PlayerDisconnected", "grust_cleanup", function(ply)
    lastMove[ply] = nil
    SpawnsPos[ply:SteamID64()] = {ply:EyeAngles(), ply:GetPos()}
end)