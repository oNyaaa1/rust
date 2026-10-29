surface.CreateFont("RustDeath_Dead", {
    font = "Roboto",
    size = ScreenScale(15),
    weight = 800
})

surface.CreateFont("RustDeath_Label", {
    font = "Roboto",
    size = ScreenScale(4.5),
    weight = 700
})

surface.CreateFont("RustDeath_Box", {
    font = "Roboto",
    size = ScreenScale(7),
    weight = 700
})

local RESPAWN_DELAY = 5
local BAR = 0.13 -- bar height as a fraction of the screen
local panel
-- tracks how long you were alive
local aliveSince, wasAlive = CurTime(), false
hook.Add("Think", "RustDeath_TrackAlive", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local alive = ply:Alive()
    if alive and not wasAlive then aliveSince = CurTime() end
    wasAlive = alive
end)

local MapMaterial = Material("ui/map.png", "smooth")
local DeathMap = Material("icons/death_marker.png", "smooth")
--MapMaterial:GetInt("$realwidth"), MapMaterial:GetInt("$realheight")
-- World boundaries of your Rust map.
local MAP_MIN = Vector(-14587, -14659, 0)
local MAP_MAX = Vector(15901, 14129, 0)
local function VectorToMap(vec, mapX, mapY, mapW, mapH)
    local x = math.Remap(vec.x, MAP_MIN.x, MAP_MAX.x, mapX, mapX + mapW)
    local y = math.Remap(vec.y, MAP_MIN.y, MAP_MAX.y, mapY + mapH, mapY)
    return x, y
end

local function OpenDeathScreen(killer)
    if IsValid(panel) then panel:Remove() end
    local ply = LocalPlayer()
    local start = CurTime()
    local x, y = nil, nil
    panel = vgui.Create("DPanel")
    panel:SetSize(ScrW(), ScrH())
    panel:MakePopup()
    panel:SetKeyboardInputEnabled(false)
    local aliveFor = math.max(0, CurTime() - aliveSince)
    local aliveStr = string.format("%dm%02ds", math.floor(aliveFor / 60), math.floor(aliveFor % 60))
    panel.Paint = function(_, w, h)
        local ply = LocalPlayer()
        local deathPos = ply:GetPos()
        local a = math.Clamp((CurTime() - start) / 1.0, 0, 1)
        local barH = h * BAR
        local my, mh = barH, h - barH * 2
        -- map
        surface.SetDrawColor(255, 255, 255, 255 * a)
        surface.SetMaterial(MapMaterial)
        surface.DrawTexturedRect(0, my, w, mh)
        -- grid lines
        surface.SetDrawColor(0, 0, 0, 45 * a)
        for i = 1, 9 do
            surface.DrawRect(w / 10 * i, my, 1, mh)
        end

        for i = 1, 3 do
            surface.DrawRect(0, my + mh / 4 * i, w, 1)
        end

        -- death marker
        -- Convert the player's death position to map coordinates.
        local mapX, mapY = 0, my
        local mapW, mapH = w, mh
        local x, y = VectorToMap(deathPos, mapX, mapY, mapW, mapH)
        -- Center the marker on the player's position.
        local markerSize = ScreenScale(8)
        surface.SetDrawColor(255, 255, 255, 255 * a)
        surface.SetMaterial(DeathMap)
        surface.DrawTexturedRect(x - markerSize / 2, y - markerSize / 2, markerSize, markerSize)
        -- bars
        surface.SetDrawColor(18, 18, 18, 255 * a)
        surface.DrawRect(0, 0, w, barH)
        surface.DrawRect(0, h - barH, w, barH)
        -- DEAD
        draw.SimpleText("DEAD", "RustDeath_Dead", w * 0.08, barH / 2, Color(110, 110, 110, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- alive for / killed by
        local aliveW, killW, gap = ScreenScale(34), ScreenScale(70), ScreenScale(8)
        local x = w / 2 - (aliveW + gap + killW) / 2
        local labelY, boxY, boxH = barH * 0.26, barH * 0.4, barH * 0.38
        draw.SimpleText("ALIVE FOR", "RustDeath_Label", x, labelY, Color(150, 150, 150, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(110, 140, 45, 255 * a)
        surface.DrawRect(x, boxY, aliveW, boxH)
        draw.SimpleText(aliveStr, "RustDeath_Box", x + aliveW / 2, boxY + boxH / 2, Color(225, 240, 190, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local kx = x + aliveW + gap
        draw.SimpleText("KILLED BY", "RustDeath_Label", kx, labelY, Color(150, 150, 150, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(225, 120, 40, 255 * a)
        surface.DrawRect(kx, boxY, boxH, boxH)
        surface.SetDrawColor(170, 70, 55, 255 * a)
        surface.DrawRect(kx + boxH, boxY, killW - boxH, boxH)
        draw.SimpleText(killer ~= "" and killer or "Unknown", "RustDeath_Box", kx + boxH + (killW - boxH) / 2, boxY + boxH / 2, Color(255, 255, 255, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    panel.Think = function(s) if CurTime() - start > 0.5 and LocalPlayer():Alive() and LocalPlayer():Health() > 0 then s:Remove() end end
    local barH = ScrH() * BAR
    local btn = vgui.Create("DButton", panel)
    btn:SetSize(ScreenScale(75), barH * 0.55)
    btn:SetPos(ScrW() - btn:GetWide() - ScrW() * 0.04, ScrH() - barH / 2 - btn:GetTall() / 2)
    btn:SetText("")
    btn.Paint = function(s, w, h)
        local left = math.ceil(RESPAWN_DELAY - (CurTime() - start))
        local ready = left <= 0
        local col = Color(55, 68, 28, 255)
        if ready then col = s:IsHovered() and Color(130, 165, 55, 255) or Color(105, 135, 45, 255) end
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(ready and "RESPAWN  »" or ("RESPAWN IN " .. left), "RustDeath_Btn", w / 2, h / 2, Color(200, 230, 120, ready and 255 or 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
        if CurTime() - start < RESPAWN_DELAY then return end
        net.Start("DeathScreen_Respawn")
        net.SendToServer()
    end
end

net.Receive("DeathScreen_Info", function() OpenDeathScreen(net.ReadString()) end)