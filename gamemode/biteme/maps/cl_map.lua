local MapMaterial    = Material("ui/map.png", "smooth")
local PlayerMaterial = Material("icons/player_marker.png", "smooth")

local WORLD_MIN_X, WORLD_MAX_X = -15040, 15104
local WORLD_MIN_Y, WORLD_MAX_Y = -15152, 15536

local function GetMapRect()
	return 0, 0, ScrW(), ScrH()
end

local function VectorToMap(vec)
	local mx, my, mw, mh = GetMapRect()
	local x = math.Remap(vec.x, WORLD_MIN_X, WORLD_MAX_X, mx, mx + mw)
	local y = math.Remap(vec.y, WORLD_MIN_Y, WORLD_MAX_Y, my + mh, my)
	return x, y
end

hook.Add("HUDPaint", "MiniMap", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not input.IsKeyDown(KEY_G) then return end
	if gui.IsGameUIVisible() or ply:IsTyping() then return end

	local mx, my, mw, mh = GetMapRect()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(MapMaterial)
	surface.DrawTexturedRect(mx, my, mw, mh)

	local x, y = VectorToMap(ply:GetPos())
	surface.SetMaterial(PlayerMaterial)
	surface.DrawTexturedRectRotated(x, y, 24, 24, ply:EyeAngles().y - 90)
end)