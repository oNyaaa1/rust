util.AddNetworkString("grust_MoveItem") -- client -> server: move request
util.AddNetworkString("grust_RequestInv") -- client -> server: "send me my inventory"
util.AddNetworkString("grust_SyncInv") -- server -> client: full inventory
local SLOTS = 36
local function GetInv(ply)
    return ply.GInv
end

local function SendInv(ply)
    local inv = GetInv(ply)
    net.Start("grust_SyncInv")
    for i = 1, SLOTS do
        local it = inv[i]
        if it then
            net.WriteString(it.id)
            net.WriteUInt(math.Clamp(math.floor(it.dur), 0, 100), 7) -- 7 bits holds 0-127
            net.WriteFloat(it.Count)
        else
            net.WriteString("")
        end
    end

    net.Send(ply)
end

function AddItemsToGmodeS(ply, name, dur, wep, size)
    local emptySlot, Slot = GetEmptySlot(ply)
    local tbl = {
        id = name,
        dur = dur or 100,
        weapon = wep ~= nil and wep or nil,
        Count = size,
    }

    RustOfficial.GetItem(name).func(ply)
    ply.GInv[Slot] = tbl
    SendInv(ply)
end

function GetEmptySlot(ply)
    local inv = GetInv(ply)
    for i = 1, SLOTS do
        if not inv[i] then return true, i end
    end
    return false, 1
end

function FindWood(ply, item)
    local emptySlot, Slot = GetEmptySlot(ply)
    local max = RustOfficial.GetItem(item).Max
    local maxin = 1
    for k, v in pairs(ply.GInv) do
        if v.id == item and v.Count < max then
            maxin = k
        elseif v.id == item and v.Count >= max then
            maxin = Slot
        end
    end
    return maxin
end

function AddItemsToGmodCount(ply, name, dur, wep, amount)
    local max = RustOfficial.GetItem(name).Max
    local woodSlot = FindWood(ply, "Wood")
    local count = ply.GInv[woodSlot] ~= nil and ply.GInv[woodSlot].Count or 0
    count = count + math.Clamp(amount, 0, max)
    local tbl = {
        id = name,
        dur = dur or 100,
        weapon = wep ~= nil and wep or nil,
        Count = count,
    }

    ply.GInv[woodSlot] = tbl
    SendInv(ply)
end

function AddItemsToGmod(ply, name, dur, wep, slot)
    PrintTable(ply.GInv)
    local tbl = {
        id = name,
        dur = dur or 100,
        weapon = wep ~= nil and wep or nil,
        Count = 1,
    }

    if wep ~= nil then RustOfficial.GetItem(name).func(ply) end
    ply.GInv[slot] = tbl
    SendInv(ply)
end

-- use this when an item is used, hit, etc.
function GRUST_DamageItem(ply, slot, amount)
    local it = GetInv(ply)[slot]
    if not it then return end
    it.dur = math.max(it.dur - amount, 0)
    SendInv(ply)
end

function GRUST_AddItem(ply, itemID, wep, dur)
    if not RustOfficial.GetItem(itemID) then return false end
    local inv = GetInv(ply)
    for i = 1, SLOTS do
        if not inv[i] then
            inv[i] = {
                id = itemID,
                dur = dur or 100,
                weapon = wep,
                Count = 1,
            }

            SendInv(ply)
            return true, i
        end
    end
    return false
end

concommand.Add("grust_giveitem", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not IsValid(ply) then -- needs a player to receive it
        return
    end

    local ok = GRUST_AddItem(ply, args[1] or "red")
    if not ok then ply:ChatPrint("Inventory full") end
end)

net.Receive("grust_RequestInv", function(_, ply) SendInv(ply) end)
local function DroppableBag(ply, name, count)
    local emptySlot, Slot = GetEmptySlot(ply)
    ply.GInv[Slot] = nil
    local ent = ents.Create("item_bag")
    ent:SetItemName(name)
    ent:SetSizeItem(count)
    ent:Spawn()
    ent:Activate()
    ent:SetPos(ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 32)
end

local function DropItem(ply, from)
    for k, v in pairs(ply.GInv) do
        if k == from then
            print(v.id,v.Count)
            DroppableBag(ply, v.id, v.Count)
            ply.GInv[k] = nil
        end
    end

    SendInv(ply)
end

net.Receive("grust_MoveItem", function(_, ply)
    local from, to = net.ReadUInt(8), net.ReadUInt(8)
    local inv = GetInv(ply)
    if to == 0 then
        DropItem(ply, from)
        return
    end

    if from < 1 or from > SLOTS or to < 1 or to > SLOTS or from == to then return end
    if not inv[from] then -- nothing there, resync them
        SendInv(ply)
        return
    end

    inv[from], inv[to] = inv[to], inv[from] -- swap (works for empty targets too)
    SendInv(ply)
end)

hook.Add("PlayerSpawn", "sendinv", function(ply)
    ply.GInv = nil
    ply.GInv = {}
    AddItemsToGmod(ply, "Rock", math.random(50, 60), "rust_rock", 31)
end)