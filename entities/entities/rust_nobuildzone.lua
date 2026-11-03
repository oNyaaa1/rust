ENT.Type = "brush"
ENT.Base = "base_brush"
local function RunBlockedZone(pl, bool)
    pl.CanBuild = bool
    if bool then
        RustNotify(pl, "BBlockd", "Building Blocked", "", "Danger", 0, "")
    else
        RustNotifyRemove(v, "BBlockd")
    end
end

function ENT:StartTouch(pl)
    if not pl:IsPlayer() then return end
    RunBlockedZone(pl, true)
end

function ENT:EndTouch(pl)
    if not pl:IsPlayer() then return end
    RunBlockedZone(pl, false)
end