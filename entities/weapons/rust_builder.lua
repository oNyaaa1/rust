AddCSLuaFile()
SWEP.PrintName = "Deploy Placer"
SWEP.Category = "Deploy"
SWEP.Spawnable = true
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Slot = 5
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "Selected")
end

SWEP.Items = {"sent_foundation"}
function SWEP:Initialize()
    self:SetHoldType("pistol")
    self:SetSelected(1)
end

function SWEP:GetSelectedClass()
    return self.Items[self:GetSelected()]
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.4)
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    local pos, ang = DEPLOY:GetSocket(ply)
    if not pos then return end
    DEPLOY:SetSocket(ply, "sent_foundation", pos, ang)
end

-- Right click: cycle item
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
    if CLIENT then return end
end

function SWEP:Reload()
end

if CLIENT then
    function SWEP:RemoveGhost()
        GRUST_GHOST:ReleaseGhostEntity()
    end

    function SWEP:Think()
        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        local pos, ang = DEPLOY:GetSocket(ply)
        if not pos then return end
        -- check how GRUST_GHOST works: this should create the ghost once
        -- and then just move it, not make a new one every frame
        GRUST_GHOST:MakeGhostEntity("models/building/twig_foundation.mdl", pos, ang)
    end

    function SWEP:DrawHUD()
        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        local _, _, txt = DEPLOY:GetSocket(ply)
        draw.SimpleTextOutlined(txt or "none", "DermaDefault", 0, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
    end

    function SWEP:Holster()
        self:RemoveGhost()
        return true
    end

    function SWEP:OnRemove()
        self:RemoveGhost()
    end

    function SWEP:OnDrop()
        self:RemoveGhost()
    end
end