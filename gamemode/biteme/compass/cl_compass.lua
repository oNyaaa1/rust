local adv_compass_tbl = {
    [0] = {"N", 0, 45},
    [45] = {"NE", 45, 90},
    [90] = {"E", 90, 135},
    [135] = {"SE", 135, 180},
    [180] = {"S", 180, 225},
    [225] = {"SW", 225, 270},
    [270] = {"W", 270, 315},
    [315] = {"NW", 315, 360},
    [360] = {"N", 360, 0}
}

function GetCompassDelta(t)
    local delta = "N"
    local num = tonumber(t)
    for k, v in SortedPairs(adv_compass_tbl) do
        if num >= v[2] and num < v[3] then delta = v[1] end
    end
    return delta
end

RunConsoleCommand("mcompass_style", "2") 
--[[hook.Add("HUDPaint", "identifier", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local w, h = ScrW(), ScrH()
    local ang = ply:GetAngles()
    local rbbd = math.Round(360 - (ang.y % 360))
    local getDelta = GetCompassDelta(rbbd)
    local compreh = adv_compass_tbl[360 - (rbbd % 360)]
    local text2 = compreh and compreh[1] or 360 - (rbbd % 360)
    draw.RoundedBox(0, w * 0.50, 0, 50, 40, Color(64, 64, 64, 255))
    draw.DrawText(text2, "DermaDefault", w * 0.512, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
    draw.DrawText(getDelta, "DermaDefault", w * 0.512, 15, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
end)]]