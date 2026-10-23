local Food, Water = 0, 0
net.Receive("gRust_Survival", function()
    local food, water = net.ReadFloat(), net.ReadFloat()
    Food = food
    Water = water
end)

hook.Add("HUDPaint", "gRust.SurvivalHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local x, y = ScrW() - 255, ScrH() - 110
    local bars = {
        {
            "HEALTH", --
            ply:Health(),
            100,
            Color(190, 55, 45),
            Mat = Material("materials/icons/health.png", "noclamp smooth")
        },
        {
            "FOOD", --
            Food,
            175,
            Color(190, 145, 55),
            Mat = Material("materials/icons/food.png", "noclamp smooth")
        },
        {
            "WATER", --
            Water,
            150,
            Color(55, 135, 205),
            Mat = Material("materials/icons/cup.png", "noclamp smooth")
        }
    }

    for i, b in ipairs(bars) do
        local yy = y + (i - 1) * 24
        draw.RoundedBox(4, x, yy, 220, 22, Color(54, 54, 54, 120))
        draw.RoundedBox(4, x + 2, yy + 2, 216 * math.Clamp(b[2] / b[3], 0, 1), 18, b[4])
        surface.SetMaterial(b.Mat)
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(x + 2, yy + 2, 16, 16)
        draw.SimpleText(b[1] .. "  " .. math.max(0, math.floor(b[2])), "DermaDefaultBold", x + 22, yy + 9, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)

function GM:PostDrawViewModel(vm, ply, weapon)
    if weapon.UseHands or not weapon:IsScripted() then
        local hands = LocalPlayer():GetHands()
        if IsValid(hands) then hands:DrawModel() end
    end
end