local PANEL = {}
function PANEL:Init()
    self:SetSize(100, 100)
    self:Center()
end

function PANEL:MoveToSlot(pnl, slot)
    pnl = pnl or {}
    pnl[slot] = pnl[slot] or {}
end

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, color_black)
end

vgui.Register("grust_Slots", PANEL, "Panel")