local CONT_INV, CONT_HOT = 0, 1
local INV_SLOTS, HOT_SLOTS = 30, 6

-- ===== Sync =====
-- Server order: 30 inventory slots, then 6 hotbar slots.
local function ReadContainer(n)
    local t = {}
    for i = 1, n do
        local id = net.ReadString()
        if id ~= "" then
            t[i] = {
                id = id,
                dur = net.ReadUInt(7),
                count = net.ReadFloat(),
            }
        end
    end
    return t
end

net.Receive("grust_SyncInv", function()
    local data = {
        [CONT_INV] = ReadContainer(INV_SLOTS),
        [CONT_HOT] = ReadContainer(HOT_SLOTS),
    }

    GRUST_LASTINV = data -- so panels created later can fill immediately
    if IsValid(GRUST_SLOTS) then GRUST_SLOTS:SetInventory(data) end
    if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:SetInventory(data) end
end)

-- ===== Slot grid =====
local PANEL = {}
function PANEL:Init()
    self.Slots = {}
    self.SlotSize, self.Padding = 84, 4
    self:BuildSlots(6, 4, CONT_INV) -- cols, rows, container (6x5 = 30 slots)
end

function PANEL:BuildSlots(cols, rows, container)
    self.Container = container
    local s, p = self.SlotSize, self.Padding
    self:SetSize(cols * (s + p) + p, rows * (s + p) + p)
    for i = 1, cols * rows do
        local slot = vgui.Create("DPanel", self)
        slot:SetSize(s, s)
        slot:SetPos(p + ((i - 1) % cols) * (s + p), p + math.floor((i - 1) / cols) * (s + p))
        slot.SlotID = i -- index inside its container
        slot.Container = container
        slot.Paint = function(_, w, h)
            surface.SetDrawColor(55, 55, 55, 110)
            surface.DrawRect(0, 0, w, h)
            if self.ShowKeys then draw.SimpleText(i, "DermaDefault", 5, 3, color_white) end
        end

        slot:Receiver("grust_item", function(target, panels, dropped)
            if not dropped then return end
            self:MoveItem(panels[1], target)
        end)

        self.Slots[i] = slot
    end
end

function PANEL:MoveItem(item, target)
    if not IsValid(item) or not IsValid(target) then return end
    local fromSlot = item:GetParent()
    if not IsValid(fromSlot) then return end
    local fromCont, from = fromSlot.Container, fromSlot.SlotID
    local toCont, to = target.Container, target.SlotID
    if not from or not to or not fromCont or not toCont then return end
    if fromCont == toCont and from == to then return end
    net.Start("grust_MoveItem")
    net.WriteUInt(fromCont, 1)
    net.WriteUInt(from, 8)
    net.WriteUInt(toCont, 1)
    net.WriteUInt(to, 8)
    net.SendToServer()
end

function PANEL:AddItem(slotID, itemID, dur, count)
    local slot = self.Slots[slotID]
    local def = RustOfficial.GetItem(itemID)
    if not IsValid(slot) or not def then return end
    dur = math.Clamp(dur or 100, 0, 100)
    count = tostring(math.floor(count or 1))
    local mat = def.image and Material(def.image) or nil
    local item = vgui.Create("DPanel", slot)
    item:SetSize(slot:GetWide(), slot:GetTall())
    item.ItemID = itemID
    item:SetTooltip(def.name .. " (" .. dur .. "%)")
    item.Paint = function(_, w, h)
        local pad, barW = 4, 6
        local cx = barW + pad
        local cw = w - cx - pad
        if mat and not mat:IsError() then
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(cx, pad, cw, h - pad * 2 - 15)
        else
            surface.SetDrawColor(def.color)
            surface.DrawRect(cx, pad, cw, h - pad * 2)
        end

        draw.SimpleTextOutlined(def.name, "DermaDefault", cx + cw / 2, h - 12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
        draw.SimpleTextOutlined(count, "DermaDefault", cx + cw / 2, h - 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, barW, h)
        local fill = math.floor(h * dur / 100)
        surface.SetDrawColor(HSVToColor(dur * 1.2, 1, 1))
        surface.DrawRect(0, h - fill, barW, fill)
    end

    item:Droppable("grust_item")
    item:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        self:MoveItem(panels[1], slot)
    end)

    slot.Item = item
    return item
end

-- data = {[0] = inventory table, [1] = hotbar table}
function PANEL:SetInventory(data)
    for _, slot in pairs(self.Slots) do
        if IsValid(slot.Item) then slot.Item:Remove() end
        slot.Item = nil
    end

    local mine = data and data[self.Container]
    if not mine then return end
    for slotID, it in pairs(mine) do
        self:AddItem(slotID, it.id, it.dur, it.count)
    end
end

vgui.Register("grust_SlotsGrid", PANEL, "Panel")

-- ===== Hotbar =====
local HOTBAR = {}
function HOTBAR:Init()
    self.Slots = {}
    self.SlotSize, self.Padding = 84, 4
    self.ShowKeys = true
    self:BuildSlots(6, 1, CONT_HOT) -- 6 slots, hotbar container
end

vgui.Register("grust_Hotbar", HOTBAR, "grust_SlotsGrid")

local function EnsureHotbar()
    if IsValid(GRUST_HOTBAR) then return GRUST_HOTBAR end
    local hb = vgui.Create("grust_Hotbar")
    hb:SetPos((ScrW() - hb:GetWide()) / 2, ScrH() - hb:GetTall() - 20)
    hb:SetMouseInputEnabled(false)
    GRUST_HOTBAR = hb
    if GRUST_LASTINV then hb:SetInventory(GRUST_LASTINV) end
    net.Start("grust_RequestInv")
    net.SendToServer()
    return hb
end

hook.Add("InitPostEntity", "grust_HotbarInit", EnsureHotbar)

-- ===== Inventory open/close =====
hook.Add("ScoreboardShow", "Scoreboard_Open", function()
    if IsValid(GRUST_TEST) then GRUST_TEST:Remove() end
    local hidebg = vgui.Create("DPanel")
    hidebg.Paint = function() end
    hidebg:SetSize(ScrW(), ScrH())
    hidebg:Droppable("grust_item")
    -- dropping on the background = drop item into the world
    hidebg:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        local fromSlot = IsValid(panels[1]) and panels[1]:GetParent()
        if not IsValid(fromSlot) or not fromSlot.SlotID then return end
        net.Start("grust_MoveItem")
        net.WriteUInt(fromSlot.Container, 1)
        net.WriteUInt(fromSlot.SlotID, 8)
        net.WriteUInt(0, 1)
        net.WriteUInt(0, 8) -- to == 0 means drop
        net.SendToServer()
    end)

    -- the inventory area swallows drops so they don't count as "drop in world"
    local hidebgb = vgui.Create("DPanel", hidebg)
    hidebgb:Droppable("grust_item")
    hidebgb:Receiver("grust_item", function() end)
    hidebgb.Paint = function() end
    local frame = vgui.Create("DPanel", hidebgb)
    GRUST_TEST = hidebg -- remove the root so nothing is left behind
    local slots = vgui.Create("grust_SlotsGrid", frame)
    GRUST_SLOTS = slots
    slots:SetPos(5, 5)
    frame:SetSize(slots:GetWide() + 10, slots:GetTall() + 10)
    hidebgb:SetSize(slots:GetWide() + 10, slots:GetTall() + 10)
    frame.Paint = function() end
    frame:MakePopup()
    frame:SetPos(hidebg:GetWide() * 0.33, hidebg:GetTall() * 0.35)
    hidebgb:SetPos(hidebg:GetWide() * 0.33, hidebg:GetTall() * 0.35)
    frame:SetKeyboardInputEnabled(false)
    if GRUST_LASTINV then slots:SetInventory(GRUST_LASTINV) end
    local hb = EnsureHotbar()
    hb:MakePopup()
    hb:SetMouseInputEnabled(true)
    hb:SetKeyboardInputEnabled(false)
    hb:MoveToFront()
    net.Start("grust_RequestInv")
    net.SendToServer()
    return true
end)

hook.Add("ScoreboardHide", "Scoreboard_Close", function()
    if IsValid(GRUST_TEST) then GRUST_TEST:Remove() end
    if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:SetMouseInputEnabled(false) end
end)

-- ===== Hotbar keys =====
hook.Add("PlayerBindPress", "Bindpressgturst", function(ply, bind, pressed)
    if not pressed then return end
    bind = string.lower(bind)
    local num = tonumber(string.match(bind, "^slot(%d+)$"))
    if not num or num < 1 or num > HOT_SLOTS then return end
    net.Start("gRustSelectWep")
    net.WriteUInt(num, 3) -- matches server ReadUInt(3)
    net.SendToServer()
    return true
end)