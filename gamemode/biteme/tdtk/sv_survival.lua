hook.Add("PlayerSpawn", "Curse", function(pl)
    pl.Cursed = false
    pl.CursedTimer = 0
    RustNotifyRemove(pl, "DmgCurse")
end)

hook.Add("EntityTakeDamage", "Curse", function(ent, dmginfo)
    if not ent:IsPlayer() then return end
    local dmg = dmginfo:GetAttacker()
    if ent == dmg then return end
    if not IsValid(dmg) then return end
    dmg.Cursed = true
    dmg.CursedTimer = 60 * 5
end)

timer.Create("RunCurse", 1, 0, function()
    for k, v in pairs(player.GetAll()) do
        if v.CursedTimer > 0 then
            v.CursedTimer = v.CursedTimer - 1
            local time = v.CursedTimer
            local hours = math.floor(time / 3600)
            local minutes = math.floor(time / 60) % 60
            local seconds = time % 60
            local formatted = string.format("%02d: %02d: %02d", hours, minutes, seconds)
            RustNotify(v, "DmgCurse", "Cursed from SZ: " .. formatted, "", "Danger", 0, "")
        elseif v.CursedTimer <= 0 and v.Cursed then
            v.CursedTimer = 0
            v.Cursed = false
            RustNotifyRemove(v, "DmgCurse")
        end
    end
end)