CodeLock = CodeLock or {}
-- anything in here (or with ENT.CodeLockable = true) can take a lock
CodeLock.Lockable = {
    prop_door_rotating = true,
    func_door = true,
    func_door_rotating = true,
    sent_door = true, -- your door from the building system
}

hook.Add("PlayerUse", "CodeLock_Block", function(ply, ent)
    local lock = ent.CodeLock
    if not IsValid(lock) then
        local p = ent:GetParent() -- door leaves point at the main door
        if IsValid(p) then lock = p.CodeLock end
    end

    if IsValid(lock) and lock:GetLocked() and not lock:HasAccess(ply) then
        if (ply.NextLockDeny or 0) < CurTime() then
            ply.NextLockDeny = CurTime() + 1
            ent:EmitSound("buttons/button10.wav")
        end
        return false
    end
end)