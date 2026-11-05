ENT.Type = "brush"
ENT.Base = "base_brush"
local function RunBlockedZone(pl, bool)
    if CLIENT then return end
    pl.CanBuild = true
    RustNotify(pl, "BBlockd", "Building Blocked", "", "Danger", 0, "")
end

local function RunBlockedZonez(pl, bool)
    if CLIENT then return end
    pl.CanBuild = false
    RustNotifyRemove(pl, "BBlockd")
end

function ENT:StartTouch(pl)
    if not pl:IsPlayer() then return end
    RunBlockedZone(pl)
end

function ENT:EndTouch(pl)
    if not pl:IsPlayer() then return end
    RunBlockedZonez(pl)
end