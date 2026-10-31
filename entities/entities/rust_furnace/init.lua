AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/deployable/furnace.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end

    self.Slots = {
        fuel = {},
        input = {},
        output = {}
    }
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local ent = ents.Create(ClassName) -- this entity's own class, not rust_ores
    ent:SetPos(tr.HitPos + tr.HitNormal * 32)
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:OnTakeDamage(dmg)
    if not IsValid(self) then return end
    local attacker = dmg:GetAttacker()
    if not (IsValid(attacker) and attacker:IsPlayer()) then return end
    if self.SetHealthz == nil then self.SetHealthz = 300 end
    self.SetHealthz = self.SetHealthz - 30
    if self.SetHealthz <= 0 then self:Remove() end
end

function ENT:ToggleFurnace(state)
    if state == nil then state = not self:GetOn() end
    -- optional: refuse to light it with no fuel
    -- if state and not self:HasFuel() then return end
    self:SetOn(state)
    self:EmitSound(state and "ambient/fire/ignite.wav" or "ambient/fire/gascan_ignite1.wav")
end

local SMELT = {
    ["Metal"] = "MetalOre",
    ["Sulfur"] = "SulfurOre",
}

local INPUT_ITEMS = SMELT
local TICK = 1 -- seconds per smelt step
local FUEL_PER_TICK = 1
local function FindOutputSlot(out, name)
    for o = 1, 3 do
        if out[o] and out[o].name == name then return o end
    end

    for o = 1, 3 do
        if not out[o] then return o end
    end
end

local CHARCOAL = "Charcoal" -- your charcoal item id
local CHARCOAL_PER_FUEL = 2 -- charcoal made per wood burned
function ENT:Think()
    self:NextThink(CurTime() + TICK)
    if not self:GetOn() then return true end
    local fuel = self.Slots.fuel[1]
    local out = self.Slots.output
    local o = FindOutputSlot(out, CHARCOAL)
    if not fuel or fuel.amount < FUEL_PER_TICK or not o then
        self:ToggleFurnace(false) -- out of wood, or no output slot free for charcoal
    else
        -- burn wood -> charcoal
        fuel.amount = fuel.amount - FUEL_PER_TICK
        if fuel.amount <= 0 then self.Slots.fuel[1] = nil end
        local cur = out[o]
        out[o] = {
            name = CHARCOAL,
            amount = (cur and cur.amount or 0) + CHARCOAL_PER_FUEL
        }

        -- ore smelting still works alongside it, no ore means this loop does nothing
        for i = 1, 2 do
            local inp = self.Slots.input[i]
            local outName = inp and SMELT[inp.name]
            local so = outName and FindOutputSlot(out, outName)
            if so then
                inp.amount = inp.amount - 1
                if inp.amount <= 0 then self.Slots.input[i] = nil end
                local c = out[so]
                out[so] = {
                    name = outName,
                    amount = (c and c.amount or 0) + 1
                }
            end
        end
    end

    -- keep the open furnace screen up to date
    local v = self.viewer
    if IsValid(v) and v:GetPos():DistToSqr(self:GetPos()) < 250 * 250 then self:SendFurnaceUI(v, false) end
    return true
end

util.AddNetworkString("gRustFurnace")
util.AddNetworkString("gRustFurnaceToggle")
util.AddNetworkString("gRustFurnaceMove")
local FUEL_ITEMS = {
    ["Wood"] = true -- your fuel item names
}

local SLOT_COUNT = {
    fuel = 1,
    input = 2,
    output = 3
}

local function Pack(slots)
    local out = {}
    for i, s in pairs(slots) do
        local info = RustOfficial.GetItem(s.name)
        out[i] = {
            name = s.name,
            amount = s.amount,
            icon = info and info.image
        }
    end
    return out
end

function ENT:SendFurnaceUI(ply, opened)
    net.Start("gRustFurnace")
    net.WriteEntity(self)
    net.WriteTable({
        on = self:GetOn(),
        fuel = Pack(self.Slots.fuel)[1],
        input = Pack(self.Slots.input),
        output = Pack(self.Slots.output),
        open = opened,
    })

    net.Send(ply)
end

net.Receive("gRustFurnaceMove", function(_, ply)
    local ent = net.ReadEntity()
    local mode = net.ReadString() -- "put" or "take"
    local kind = net.ReadString()
    local idx = net.ReadUInt(4)
    local name = net.ReadString()
    if not IsValid(ent) or not ent.Slots then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 250 * 250 then return end
    if not SLOT_COUNT[kind] or idx < 1 or idx > SLOT_COUNT[kind] then return end
    local slots = ent.Slots[kind]
    local slot = slots[idx]
    if mode == "put" then
        local allowed = (kind == "fuel" and FUEL_ITEMS[name]) or (kind == "input" and INPUT_ITEMS[name])
        if not allowed then return end
        if slot and slot.name ~= name then return end
        local has, amount = CalcItem(ply, name)
        if not has or amount <= 0 then return end
        GInv_RemoveItem(ply, name, amount)
        slots[idx] = {
            name = name,
            amount = (slot and slot.amount or 0) + amount
        }
    elseif mode == "take" then
        if not slot then return end
        local item = RustOfficial.GetItem(slot.name)
        if not item then return end
        AddItemsToGmodCount(ply, item.name, 100, nil, slot.amount) -- same call shape as your tree code, check the 100
        slots[idx] = nil
    else
        return
    end

    ent:SendFurnaceUI(ply)
end)

net.Receive("gRustFurnaceToggle", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or not ent.Slots then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 250 * 250 then return end
    ent:ToggleFurnace()
    ent:SendFurnaceUI(ply, true)
end)

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    self.viewer = activator
    self:SendFurnaceUI(activator, true)
end

function ENT:StartTouch(ent)
    return false
end

function ENT:EndTouch(ent)
    return false
end

function ENT:Touch(ent)
    return false
end