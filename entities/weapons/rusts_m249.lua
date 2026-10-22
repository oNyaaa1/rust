AddCSLuaFile()
SWEP.ViewModel = "models/weapons/darky_m/rust/c_m249.mdl"
SWEP.WorldModel = "models/weapons/darky_m/rust/w_m249.mdl"
SWEP.DrawCrosshair = false
SWEP.UseHands = true
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 120
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "M249_AMMO"
function SWEP:Initialize()
    self:SetHoldType("smg")
    self.delay = 0
    self.Clicked = false
    if SERVER then
        local pl = self:GetOwner()
        if IsValid(pl) then pl:GiveAmmo(120, self.Primary.Ammo, true) end
    end
    self.CoolDownRL = 0
end

function SWEP:Reload(tr)
    if self.CoolDownRL <= CurTime() then
        self.CoolDownRL = CurTime() + 4
        self:SendWeaponAnim(ACT_VM_RELOAD)
    end
    
    
end

function SWEP:PrimaryAttack()
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    pl:SetAnimation(PLAYER_ATTACK1)
    self:EmitSound("weapons/zohart/ak74u-attack-2.mp3")
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.delay = CurTime() + 0.5
    self:SetNextPrimaryFire(CurTime() + 0.15)
    local tr = pl:GetEyeTrace()
    self.Clicked = true
    local bullet = {}
    bullet.Num = 1
    bullet.Src = pl:GetShootPos()
    bullet.Dir = pl:GetForward()
    bullet.Spread = Vector(0.01, 0.01, 0)
    bullet.Tracer = 1
    bullet.Force = 2
    bullet.Damage = 25
    pl:FireBullets(bullet)
    local fx = EffectData()
    fx:SetEntity(self)
    fx:SetOrigin(pl:GetShootPos())
    fx:SetNormal(pl:GetAimVector())
    fx:SetAttachment("1")
    util.Effect("muzzleflash", fx)
end

function SWEP:Think()
end

SWEP.IronSightsPos = Vector(-6.1, -20, 3.4)
SWEP.IronSightsAng = Vector(0, 0, 0)
function SWEP:GetViewModelPosition(EyePos, EyeAng)
    if self.AnglesMode == 0 then return end
    local Mul = 1.0
    local Offset = self.IronSightsPos
    if self.IronSightsAng then
        EyeAng = EyeAng * 1
        EyeAng:RotateAroundAxis(EyeAng:Right(), self.IronSightsAng.x * Mul)
        EyeAng:RotateAroundAxis(EyeAng:Up(), self.IronSightsAng.y * Mul)
        EyeAng:RotateAroundAxis(EyeAng:Forward(), self.IronSightsAng.z * Mul)
    end

    local Right = EyeAng:Right()
    local Up = EyeAng:Up()
    local Forward = EyeAng:Forward()
    EyePos = EyePos + Offset.x * Right * Mul
    EyePos = EyePos + Offset.y * Forward * Mul
    EyePos = EyePos + Offset.z * Up * Mul
    return EyePos, EyeAng
end

--self:GetViewModelPosition(self:GetOwner():GetShootPos(), self:GetOwner():GetAngles()) 
function SWEP:Think()
    if self:GetOwner():KeyDown(IN_ATTACK2) then
        self.AnglesMode = 1
    elseif not self:GetOwner():KeyDown(IN_ATTACK2) then
        self.AnglesMode = 0
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:DrawHUD()
    if self.AnglesMode == 1 then return end
    local width = ScrW()
    local height = ScrH()
    local r, g, b, a = 255, 255, 255, 255
    surface.DrawLine(width / 2 - 10, height / 2, width / 2 + 10, height / 2)
    surface.DrawLine(width / 2, height / 2 - 10, width / 2, height / 2 + 10)
    surface.SetDrawColor(r, g, b, a)
end