net.Receive("grust_SyncInv", function()
    local inv = {}
    for i = 1, 36 do
        local id = net.ReadString()
        if id ~= "" then
            inv[i] = {
                id = id,
                dur = net.ReadUInt(7),
                count = net.ReadFloat(),
            }
        end
    end

    if IsValid(GRUST_SLOTS) then GRUST_SLOTS:SetInventory(inv) end
    if IsValid(GRUST_HOTBAR) then GRUST_HOTBAR:SetInventory(inv) end
end)

local PANEL = {}
function PANEL:Init()
    self.Slots = {}
    self.SlotSize, self.Padding = 84, 4
    self:BuildSlots(6, 5, 0) -- cols, rows, slot ID offset
end

function PANEL:BuildSlots(cols, rows, offset)
    local s, p = self.SlotSize, self.Padding
    self:SetSize(cols * (s + p) + p, rows * (s + p) + p)
    for i = 1, cols * rows do
        local slotID = offset + i
        local slot = vgui.Create("DPanel", self)
        slot:SetSize(s, s)
        slot:SetPos(p + ((i - 1) % cols) * (s + p), p + math.floor((i - 1) / cols) * (s + p))
        slot.SlotID = slotID
        slot.Paint = function(_, w, h)
            surface.SetDrawColor(55, 55, 55, 110)
            surface.DrawRect(0, 0, w, h)
            if self.ShowKeys then draw.SimpleText(i, "DermaDefault", 5, 3, color_white) end
        end

        slot:Receiver("grust_item", function(target, panels, dropped)
            if not dropped then return end
            self:MoveItem(panels[1], target)
        end)

        self.Slots[slotID] = slot
    end
end

function PANEL:MoveItem(item, target)
    if not IsValid(item) or not IsValid(target) then return end
    local from = item:GetParent().SlotID
    local to = target.SlotID
    if not from or not to or from == to then return end
    net.Start("grust_MoveItem")
    net.WriteUInt(from, 8)
    net.WriteUInt(to, 8)
    net.SendToServer()
end

function PANEL:AddItem(slotID, itemID, dur, count)
    local slot = self.Slots[slotID]
    local def = RustOfficial.GetItem(itemID)
    if not IsValid(slot) or not def then return end
    dur = math.Clamp(dur or 100, 0, 100)
    local mat = def.image and Material(def.image) or nil
    local item = vgui.Create("DPanel", slot)
    item:SetSize(slot:GetWide(), slot:GetTall())
    item.ItemID = itemID
    item:SetTooltip(def.name .. " (" .. dur .. "%)")
    item.Paint = function(_, w, h)
        local pad, barW = 4, 6
        local cx = barW + pad -- content starts after the bar
        local cw = w - cx - pad -- content width
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
        -- durability bar, left edge, fills from the bottom
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

function PANEL:SetInventory(inv)
    for _, slot in pairs(self.Slots) do -- pairs, not ipairs
        if IsValid(slot.Item) then slot.Item:Remove() end
        slot.Item = nil
    end

    for slotID, it in pairs(inv) do
        self:AddItem(slotID, it.id, it.dur, it.count)
    end
end

vgui.Register("grust_SlotsGrid", PANEL, "Panel")
local HOTBAR = {}
function HOTBAR:Init()
    self.Slots = {}
    self.SlotSize, self.Padding = 84, 4
    self.ShowKeys = true
    self:BuildSlots(6, 1, 30) -- 6 cols, 1 row, slots 31-36
end

vgui.Register("grust_Hotbar", HOTBAR, "grust_SlotsGrid")
local function EnsureHotbar()
    if IsValid(GRUST_HOTBAR) then return GRUST_HOTBAR end
    local hb = vgui.Create("grust_Hotbar")
    hb:SetPos((ScrW() - hb:GetWide()) / 2, ScrH() - hb:GetTall() - 20)
    hb:SetMouseInputEnabled(false) -- display only until the inventory opens
    GRUST_HOTBAR = hb
    net.Start("grust_RequestInv")
    net.SendToServer()
    return hb
end

hook.Add("InitPostEntity", "grust_HotbarInit", EnsureHotbar)
hook.Add("ScoreboardShow", "Scoreboard_Open", function()
    local hidebg = vgui.Create("DPanel")
    hidebg.Paint = function(s, w, h) end
    hidebg:SetSize(ScrW(), ScrH())
    hidebg:Droppable("grust_item")
    hidebg:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        if slot ~= nil then return end
        net.Start("grust_MoveItem")
        net.WriteUInt(panels[1]:GetParent().SlotID, 8)
        net.WriteUInt(0, 8)
        net.SendToServer()
    end)

    local hidebgb = vgui.Create("DPanel", hidebg)
    hidebgb:Droppable("grust_item")
    hidebgb:Receiver("grust_item", function(_, panels, dropped)
        if not dropped then return end
        if slot ~= nil then return end
    end)

    hidebgb.Paint = function(s, w, h) end
    local frame = vgui.Create("DPanel", hidebgb)
    GRUST_TEST = hidebgb
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

hook.Add("PlayerBindPress", "Bindpressgturst", function(ply, bind, pressed)
    if not pressed then return end
    bind = string.lower(bind)
    local num = tonumber(string.match(bind, "^slot(%d+)$"))
    if not num or num < 1 or num > 6 then return end
    net.Start("gRustSelectWep")
    net.WriteFloat(num)
    net.SendToServer()
    return true
end)