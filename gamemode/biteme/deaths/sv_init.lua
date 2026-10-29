util.AddNetworkString("DeathScreen_Respawn")
util.AddNetworkString("DeathScreen_Info")
hook.Add("PlayerDeath", "DeathScreen_Time", function(victim, inflictor, attacker)
    victim.DeathTime = CurTime()
    local name = ""
    if IsValid(attacker) then name = attacker:IsPlayer() and attacker:Nick() or attacker:GetClass() end
    if attacker == victim then name = "yourself" end
    net.Start("DeathScreen_Info")
    net.WriteString(name)
    net.Send(victim)
end)

-- stops the default "press any key to respawn"
hook.Add("PlayerDeathThink", "DeathScreen_BlockAuto", function(ply) if CurTime() < (ply.DeathTime or 0) + 5 then return true end end)
net.Receive("DeathScreen_Respawn", function(_, ply)
    if ply:Alive() then return end
    if CurTime() < (ply.DeathTime or 0) + 5 then -- keep in sync with RESPAWN_DELAY
        return
    end

    ply:Spawn()
end)