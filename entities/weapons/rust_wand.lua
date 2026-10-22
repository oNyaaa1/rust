AddCSLuaFile()
SWEP.ViewModel = Model("models/hpwrewrite/c_magicwand.mdl")
SWEP.WorldModel = Model("models/hpwrewrite/w_magicwand.mdl")
SWEP.DrawCrosshair = false
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 120
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "AK47_AMMO"
SWEP.Secondary.Automatic = false
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
    --self:EmitSound("weapons/zohart/ak74u-attack-2.mp3")
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.delay = CurTime() + 0.5
    self:SetNextPrimaryFire(CurTime() + 0.15)
    if SERVER then
        WH:GetSpell(pl, self, pl.SelectedSpell)
    end
    
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

function SWEP:Think()
end

function SWEP:SecondaryAttack()
    if CLIENT then WandMenu(self, self:GetOwner()) end
    self:SetNextSecondaryFire(CurTime() + 0.5)
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