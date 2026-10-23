DEPLOY = {}
DEPLOY.FItem = function(ply, item)
    if CLIENT then return end
    local ent = ents.Create(item)
    ent:SetPos(ply:GetEyeTrace().HitPos + ply:GetEyeTrace().HitNormal * 12)
    ent:Spawn()
    ent:Activate()
end