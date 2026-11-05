local CONT_INV, CONT_HOT, CONT_CLOTH = 0, 1, 2
local CONT_LOOT, CONT_LOOT_HOT = 3, 4
local INV_SLOTS, HOT_SLOTS, CONT_SLOTS = 24, 6, 6
local CONT_BITS = 2
-- =========================================================
-- Inventory sync
-- =========================================================
local function ReadContainer(amount)
    local data = {}
    for i = 1, amount do
        local id = net.ReadString()
        if id ~= "" then
            data[i] = {
                id = id,
                dur = net.ReadUInt(7),
                count = net.ReadFloat()
            }
        end
    end
    return data
end

net.Receive("grust_SyncInv", function()
    local data = {
        [CONT_INV] = ReadContainer(INV_SLOTS),
        [CONT_HOT] = ReadContainer(HOT_SLOTS),
        [CONT_CLOTH] = ReadContainer(CONT_SLOTS)
    }

    GRUST_LASTINV = data
    if IsValid(GRUST_SLOTS) then GRUST_SLOTS:SetInventory(data) end
    if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:SetInventory(data) end
    if IsValid(GRUST_HB2) then GRUST_HB2:SetInventory(data) end
    if IsValid(GRUST_LOOT_OWNINV) then GRUST_LOOT_OWNINV:SetInventory(data) end
    if IsValid(GRUST_LOOT_OWNHOTBAR) then GRUST_LOOT_OWNHOTBAR:SetInventory(data) end
    if IsValid(GRUST_TEST) and IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:MoveToFront() end
end)

-- =========================================================
-- Base slot panel
-- =========================================================
local PANEL = {}
function PANEL:Init()
    self.Slots = {}
    self.SlotSize = 84
    self.Padding = 4
    self.ShowKeys = false
end

function PANEL:BuildSlots(cols, rows, container)
    self.Slots = {}
    self.Container = container
    local s = self.SlotSize or 84
    local p = self.Padding or 4
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

        if not self.IsLoot then
            slot:Receiver("grust_item", function(target, panels, dropped)
                if not dropped then return end
                self:MoveItem(panels[1], target)
            end)
        end

        self.Slots[i] = slot
    end
end

function PANEL:MoveItem(item, target)
    if not IsValid(item) or not IsValid(target) then return end
    if item.takeFn then return item.takeFn() end
    local fromSlot = item:GetParent()
    if not IsValid(fromSlot) then return end
    local fromCont = fromSlot.Container
    local from = fromSlot.SlotID
    local toCont = target.Container
    local to = target.SlotID
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
    item:Droppable("grust_item")
    item.DoDoubleClick = function(self) if self.takeFn then return self.takeFn() end end
    item.OnMousePressed = function(self, code)
        if self.takeFn and code == MOUSE_RIGHT then return self.takeFn() end
        self:MouseCapture(true)
        self:DragMousePress(code)
    end

    item.OnMouseReleased = function(self, code)
        self:MouseCapture(false)
        self:DragMouseRelease(code)
    end

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

    if self.IsLoot then
        item:SetMouseInputEnabled(true)
        item.OnMousePressed = function(_, code)
            if code ~= MOUSE_LEFT then return end
            if not IsValid(GRUST_LOOT_RAG) then return end
            net.Start("grust_LootTake")
            net.WriteEntity(GRUST_LOOT_RAG)
            net.WriteUInt(self.Container, 3)
            net.WriteUInt(slotID, 8)
            net.SendToServer()
        end
    else
        item:Droppable("grust_item")
        item:Receiver("grust_item", function(_, panels, dropped)
            if not dropped then return end
            self:MoveItem(panels[1], slot)
        end)
    end

    slot.Item = item
    return item
end

function PANEL:SetInventory(data)
    for _, slot in pairs(self.Slots or {}) do
        if IsValid(slot.Item) then slot.Item:Remove() end
        slot.Item = nil
    end

    local contents = data and data[self.Container]
    if not contents then return end
    for slotID, item in pairs(contents) do
        if item and item.id then self:AddItem(slotID, item.id, item.dur, item.count) end
    end
end

vgui.Register("grust_SlotsGrid", PANEL, "Panel")
-- =========================================================
-- Register ALL inventory panels before creating any hooks
-- =========================================================
local INVENTORY = {}
function INVENTORY:Init()
    self:BuildSlots(6, 4, CONT_INV)
end

vgui.Register("grust_Inventory", INVENTORY, "grust_SlotsGrid")
local LOOT = {}
function LOOT:Init()
    self.IsLoot = true
    self:BuildSlots(6, 4, CONT_LOOT)
end

vgui.Register("grust_LootInventory", LOOT, "grust_SlotsGrid")
local HOTBAR = {}
function HOTBAR:Init()
    self.ShowKeys = true
    self:BuildSlots(6, 1, CONT_HOT)
end

vgui.Register("grust_Hotbar", HOTBAR, "grust_SlotsGrid")
local LOOT_HOTBAR = {}
function LOOT_HOTBAR:Init()
    self.IsLoot = true
    self:BuildSlots(6, 1, CONT_LOOT_HOT)
end

vgui.Register("grust_LootHotbar", LOOT_HOTBAR, "grust_SlotsGrid")
local CHARBAR = {}
function CHARBAR:Init()
    self.SlotSize = 70
    self:BuildSlots(6, 1, CONT_CLOTH)
end

vgui.Register("grust_Charbar", CHARBAR, "grust_SlotsGrid")
-- =========================================================
-- Main hotbar
-- =========================================================
local function EnsureHotbar()
    if IsValid(GRUST_HOTBAR) then return GRUST_HOTBAR end
    local hb = vgui.Create("grust_Hotbar")
    if not IsValid(hb) then
        ErrorNoHalt("[gRust] Failed to create grust_Hotbar\n")
        return
    end

    hb:SetPos((ScrW() - hb:GetWide()) / 2, ScrH() - hb:GetTall() - 20)
    hb:SetMouseInputEnabled(false)
    GRUST_HOTBAR = hb
    if GRUST_LASTINV then hb:SetInventory(GRUST_LASTINV) end
    net.Start("grust_RequestInv")
    net.SendToServer()
    return hb
end

hook.Add("InitPostEntity", "grust_HotbarInit", EnsureHotbar)
-- =========================================================
-- Cursor slot lookup
-- =========================================================
local function SlotAtCursor(grid)
    if not IsValid(grid) then return end
    local mx, my = gui.MousePos()
    for _, slot in ipairs(grid.Slots or {}) do
        if IsValid(slot) then
            local x, y = slot:LocalToScreen(0, 0)
            if mx >= x and mx < x + slot:GetWide() and my >= y and my < y + slot:GetTall() then return slot end
        end
    end
end

-- =========================================================
-- Scoreboard inventory
-- =========================================================
hook.Add("ScoreboardShow", "Scoreboard_Open", function()
    if IsValid(GRUST_TEST) then GRUST_TEST:Remove() end
    local bg = vgui.Create("DPanel")
    if not IsValid(bg) then return true end
    bg:SetSize(ScrW(), ScrH())
    bg.Paint = function() end
    bg:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        timer.Simple(0, function() if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:MoveToFront() end end)
        local item = panels[1]
        local fromSlot = IsValid(item) and item:GetParent()
        if not IsValid(fromSlot) or not fromSlot.SlotID then return end
        local target = SlotAtCursor(GRUST_HOTBAR) or SlotAtCursor(GRUST_HB2)
        if target then
            if IsValid(GRUST_SLOTS) then GRUST_SLOTS:MoveItem(item, target) end
            return
        end

        net.Start("grust_MoveItem")
        net.WriteUInt(fromSlot.Container, CONT_BITS)
        net.WriteUInt(fromSlot.SlotID, 8)
        net.WriteUInt(0, CONT_BITS)
        net.WriteUInt(0, 8)
        net.SendToServer()
    end)

    bg:MakePopup()
    bg:SetKeyboardInputEnabled(false)
    GRUST_TEST = bg
    -- Inventory
    local invBox = vgui.Create("DPanel", bg)
    invBox.Paint = function() end
    invBox:Receiver("grust_item", function() end)
    local slots = vgui.Create("grust_Inventory", invBox)
    if not IsValid(slots) then
        ErrorNoHalt("[gRust] grust_Inventory is not registered\n")
        bg:Remove()
        return true
    end

    slots:SetPos(5, 5)
    GRUST_SLOTS = slots
    invBox:SetSize(slots:GetWide() + 10, slots:GetTall() + 10)
    invBox:SetPos(bg:GetWide() * 0.33, bg:GetTall() * 0.45)
    if GRUST_LASTINV then slots:SetInventory(GRUST_LASTINV) end
    -- Clothing
    local charBox = vgui.Create("DPanel", bg)
    charBox:Receiver("grust_item", function() end)
    charBox.Paint = function() end
    local hb2 = vgui.Create("grust_Charbar", charBox)
    if IsValid(hb2) then
        hb2:SetPos(0, 5)
        GRUST_HB2 = hb2
        charBox:SetSize(hb2:GetWide(), hb2:GetTall() + 10)
        charBox:SetPos(math.max(10, invBox:GetX() - charBox:GetWide() - 20), invBox:GetY() + 275)
        if GRUST_LASTINV then hb2:SetInventory(GRUST_LASTINV) end
    end

    -- Player model
    local icon = vgui.Create("DModelPanel", bg)
    icon:SetSize(400, 400)
    icon:SetModel(LocalPlayer():GetModel())
    icon:SetLookAt(Vector(20, LocalPlayer():GetForward().y, 40))
    function icon:LayoutEntity(ent)
        ent:SetAngles(Angle(0, 30, 0))
    end

    icon:SetPos(math.max(10, invBox:GetX() - charBox:GetWide() - 20), invBox:GetY() - 120)
    -- Main hotbar
    local hb = EnsureHotbar()
    if IsValid(hb) then
        hb:SetParent(bg)
        hb:SetMouseInputEnabled(true)
        hb:SetKeyboardInputEnabled(false)
        hb:MoveToFront()
    end

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

-- =========================================================
-- Corpse loot window
-- =========================================================
local function CreateLootWindow(rag, inventory)
    if not IsValid(rag) then return end
    if IsValid(GRUST_LOOT) then GRUST_LOOT:Remove() end
    GRUST_LOOT_RAG = rag
    local frame = vgui.Create("DFrame")
    if not IsValid(frame) then return end
    frame:SetSize(1160, 650)
    frame:Center()
    frame:SetTitle("Death inventory")
    frame:MakePopup()
    frame.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100)) end
    GRUST_LOOT = frame
    -- Corpse inventory
    local lootInv = vgui.Create("grust_LootInventory", frame)
    if not IsValid(lootInv) then
        frame:Remove()
        ErrorNoHalt("[gRust] Failed to create grust_LootInventory\n")
        return
    end

    lootInv:SetPos(30, 70)
    lootInv:SetInventory(inventory)
    GRUST_LOOT_INV = lootInv
    -- Player inventory
    local ownInv = vgui.Create("grust_Inventory", frame)
    if not IsValid(ownInv) then
        frame:Remove()
        return
    end

    ownInv:SetPos(590, 70)
    ownInv:SetInventory(GRUST_LASTINV or {})
    GRUST_LOOT_OWNINV = ownInv
    -- Corpse hotbar
    local lootHotbar = vgui.Create("grust_LootHotbar", frame)
    if IsValid(lootHotbar) then
        lootHotbar:SetPos(30, 440)
        lootHotbar:SetInventory(inventory)
        GRUST_LOOT_HOTBAR = lootHotbar
    end

    -- Player hotbar
    local ownHotbar = vgui.Create("grust_Hotbar", frame)
    if IsValid(ownHotbar) then
        ownHotbar:SetPos(590, 440)
        ownHotbar:SetInventory(GRUST_LASTINV or {})
        GRUST_LOOT_OWNHOTBAR = ownHotbar
    end

    frame.OnClose = function()
        GRUST_LOOT = nil
        GRUST_LOOT_RAG = nil
        GRUST_LOOT_INV = nil
        GRUST_LOOT_HOTBAR = nil
        GRUST_LOOT_OWNINV = nil
        GRUST_LOOT_OWNHOTBAR = nil
    end
end

net.Receive("grust_LootOpen", function()
    local rag = net.ReadEntity()
    local inventory = net.ReadTable()
    CreateLootWindow(rag, inventory)
end)

net.Receive("grust_LootUpdate", function()
    local rag = net.ReadEntity()
    local inventory = net.ReadTable()
    if not IsValid(GRUST_LOOT) or rag ~= GRUST_LOOT_RAG then
        CreateLootWindow(rag, inventory)
        return
    end

    if IsValid(GRUST_LOOT_INV) then GRUST_LOOT_INV:SetInventory(inventory) end
    if IsValid(GRUST_LOOT_HOTBAR) then GRUST_LOOT_HOTBAR:SetInventory(inventory) end
end)

-- =========================================================
-- Hotbar keys
-- =========================================================
hook.Add("PlayerBindPress", "Bindpressgturst", function(ply, bind, pressed)
    if not pressed then return end
    bind = string.lower(bind)
    local num = tonumber(string.match(bind, "^slot(%d+)$"))
    if not num or num < 1 or num > HOT_SLOTS then return end
    net.Start("gRustSelectWep")
    net.WriteUInt(num, 3)
    net.SendToServer()
    return true
end)