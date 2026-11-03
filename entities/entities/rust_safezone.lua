ENT.Type = "brush"
ENT.Base = "base_brush"
local function EnterSafeZone(pl)
    RustNotify(pl, "sz", "Safe Zone", "", "safeZone", 0, "")
    pl.SafeZone = true
end

local function ExitSafeZone(pl)
    RustNotifyRemove(pl, "sz")
    pl.SafeZone = false
end

function ENT:StartTouch(pl)
    if pl:IsPlayer() then EnterSafeZone(pl) end
end

function ENT:EndTouch(pl)
    if pl:IsPlayer() then ExitSafeZone(pl) end
end