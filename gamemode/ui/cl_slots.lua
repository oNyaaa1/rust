local CONT_INV, CONT_HOT, CONT_CLOTH = 0, 1, 2
local INV_SLOTS, HOT_SLOTS, CONT_SLOTS = 30, 6, 6
local CONT_BITS = 2 -- 0..2 needs 2 bits. Server must ReadUInt(2) for container IDs.
-- ===== Sync =====
-- Server order: 30 inventory slots, 6 hotbar slots, 6 clothing slots.
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
    local inv = ReadContainer(INV_SLOTS)
    local hot = ReadContainer(HOT_SLOTS)
    local cloth = {}
    if (net.BytesLeft() or 0) > 0 then cloth = ReadContainer(CONT_SLOTS) end
    local data = {
        [CONT_INV] = inv,
        [CONT_HOT] = hot,
        [CONT_CLOTH] = cloth,
    }

    GRUST_LASTINV = data
    if IsValid(GRUST_SLOTS) then GRUST_SLOTS:SetInventory(data) end
    if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:SetInventory(data) end
    if IsValid(GRUST_HB2) then GRUST_HB2:SetInventory(data) end
    -- keep the hotbar above the inventory background while the inventory is open
    if IsValid(GRUST_TEST) and IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:MoveToFront() end
end)

-- ===== Slot grid (base class: builds nothing by itself) =====
local PANEL = {}
function PANEL:Init()
    self.Slots = {}
    self.SlotSize, self.Padding = 84, 4
    self.ShowKeys = false
end

function PANEL:BuildSlots(cols, rows, container)
    self.Container = container
    local s, p = self.SlotSize, self.Padding
    self:SetSize(cols * (s + p) + p, rows * (s + p) + p)
    for i = 1, cols * rows do
        local slot = vgui.Create("DPanel", self)
        slot:SetSize(s, s)
        slot:SetPos(p + ((i - 1) % cols) * (s + p), p + math.floor((i - 1) / cols) * (s + p))
        slot.SlotID = i
        slot.Container = container
        slot.Paint = function(_, w, h)
            surface.SetDrawColor(55, 55, 55, 110)
            surface.DrawRect(0, 0, w, h)
            if self.ShowKeys then draw.SimpleText(tostring(i), "DermaDefault", 5, 3, color_white) end
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
    net.WriteUInt(fromCont, CONT_BITS)
    net.WriteUInt(from, 8)
    net.WriteUInt(toCont, CONT_BITS)
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
            surface.SetDrawColor(def.color or color_white)
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

-- data = {[0] = inventory, [1] = hotbar, [2] = clothing}
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
-- ===== Main inventory (6x5 = 30) =====
local INVENTORY = {}
function INVENTORY:Init()
    self:BuildSlots(6, 5, CONT_INV)
end

vgui.Register("grust_Inventory", INVENTORY, "grust_SlotsGrid")
-- ===== Hotbar =====
local HOTBAR = {}
function HOTBAR:Init()
    self.ShowKeys = true
    self:BuildSlots(6, 1, CONT_HOT)
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
-- ===== Clothing bar =====
local CHARBAR = {}
function CHARBAR:Init()
    self.SlotSize = 70
    self:BuildSlots(6, 1, CONT_CLOTH)
end

vgui.Register("grust_Charbar", CHARBAR, "grust_SlotsGrid")
-- ===== Inventory open/close =====
local function SlotAtCursor(grid)
    if not IsValid(grid) then return end
    local mx, my = gui.MousePos()
    for _, slot in ipairs(grid.Slots) do
        if IsValid(slot) then
            local x, y = slot:LocalToScreen(0, 0)
            if mx >= x and mx < x + slot:GetWide() and my >= y and my < y + slot:GetTall() then return slot end
        end
    end
end

hook.Add("ScoreboardShow", "Scoreboard_Open", function()
    if IsValid(GRUST_TEST) then GRUST_TEST:Remove() end
    -- fullscreen background: dropping on it = drop item into the world
    local bg = vgui.Create("DPanel")
    bg:SetSize(ScrW(), ScrH())
    bg.Paint = function() end
    bg:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        timer.Simple(0, function() if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:MoveToFront() end end)
        local item = panels[1]
        local fromSlot = IsValid(item) and item:GetParent()
        if not IsValid(fromSlot) or not fromSlot.SlotID then return end
        -- dropped over the hotbar or clothing bar? move there instead of dropping
        local target = SlotAtCursor(GRUST_HOTBAR) or SlotAtCursor(GRUST_HB2)
        if target then
            GRUST_SLOTS:MoveItem(item, target) -- MoveItem doesn't depend on which grid calls it
            return
        end

        net.Start("grust_MoveItem")
        net.WriteUInt(fromSlot.Container, CONT_BITS)
        net.WriteUInt(fromSlot.SlotID, 8)
        net.WriteUInt(0, CONT_BITS)
        net.WriteUInt(0, 8) -- to == 0 means drop
        net.SendToServer()
    end)

    bg:MakePopup()
    bg:SetKeyboardInputEnabled(false)
    GRUST_TEST = bg -- removing the root removes everything
    -- main inventory (swallows drops so gaps don't count as "drop in world")
    local invBox = vgui.Create("DPanel", bg)
    invBox.Paint = function() end
    invBox:Receiver("grust_item", function() end)
    local slots = vgui.Create("grust_Inventory", invBox)
    slots:SetPos(5, 5)
    GRUST_SLOTS = slots
    invBox:SetSize(slots:GetWide() + 10, slots:GetTall() + 10)
    invBox:SetPos(bg:GetWide() * 0.33, bg:GetTall() * 0.35)
    if GRUST_LASTINV then slots:SetInventory(GRUST_LASTINV) end
    -- clothing panel, to the left of the inventory
    local charBox = vgui.Create("DPanel", bg)
    charBox:Receiver("grust_item", function() end)
    charBox.Paint = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(52, 52, 52, 100)) end
    local hb2 = vgui.Create("grust_Charbar", charBox)
    hb2:SetPos(0, 5)
    GRUST_HB2 = hb2
    charBox:SetSize(hb2:GetWide(), hb2:GetTall() + 10)
    charBox:SetPos(math.max(10, invBox:GetX() - charBox:GetWide() - 20), invBox:GetY() + 350)
    if GRUST_LASTINV then hb2:SetInventory(GRUST_LASTINV) end
    -- hotbar on top, interactive while the inventory is open
    local hb = EnsureHotbar()
    hb:SetParent(bg)
    hb:SetMouseInputEnabled(true)
    hb:SetKeyboardInputEnabled(false)
    hb:MoveToFront()
    net.Start("grust_RequestInv")
    net.SendToServer()
    return true
end)

hook.Add("ScoreboardHide", "Scoreboard_Close", function()
    if IsValid(GRUST_HOTBAR) then
        GRUST_HOTBAR:SetParent(nil)
        GRUST_HOTBAR:SetMouseInputEnabled(false)
    end

    if IsValid(GRUST_TEST) then GRUST_TEST:Remove() end
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