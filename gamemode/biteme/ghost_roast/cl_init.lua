GRUST_GHOST = GRUST_GHOST or {}
function GRUST_GHOST:MakeGhostEntity(model, pos, angle)
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    pos = pos or tr.HitPos + tr.HitNormal * 32
    angle = ang or Angle(0, 0, 0)
    util.PrecacheModel(model)
    self:ReleaseGhostEntity()
    self.GhostEntity = ents.CreateClientProp(model)
    self.GhostEntity:SetModel(model)
    self.GhostEntity:SetPos(pos)
    self.GhostEntity:SetAngles(angle)
    self.GhostEntity:Spawn()
    self.GhostEntity:PhysicsDestroy()
    self.GhostEntity:SetMoveType(MOVETYPE_NONE)
    self.GhostEntity:SetNotSolid(true)
    self.GhostEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self.GhostEntity:SetColor(Color(255, 255, 255, 150))
    return self.GhostEntity
end

function GRUST_GHOST:ReleaseGhostEntity()
    if self.GhostEntity then
        if not IsValid(self.GhostEntity) then
            self.GhostEntity = nil
            return
        end

        self.GhostEntity:Remove()
        self.GhostEntity = nil
    end
end