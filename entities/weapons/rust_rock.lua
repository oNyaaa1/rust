AddCSLuaFile()
SWEP.ViewModel = "models/weapons/darky_m/rust/c_rock.mdl"
SWEP.WorldModel = "models/weapons/darky_m/rust/w_rock.mdl"
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = false
SWEP.UseHands = true
SWEP.Primary.Automatic = true
function SWEP:Initialize()
    self:SetHoldType("melee")
    self.delay = 0
    self.Clicked = false
end

function SWEP:PrimaryAttack()
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    pl:SetAnimation(PLAYER_ATTACK1)
    self:EmitSound("tools/rock_swing.mp3")
    self:SendWeaponAnim(ACT_VM_SWINGMISS)
    self.delay = CurTime() + 0.5
    self:SetNextPrimaryFire(CurTime() + 1.5)
    self.Clicked = true
end

function SWEP:Think()
    if CLIENT then return end
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    if self.delay < CurTime() then
        local tr = pl:GetEyeTrace()
        local dist = math.Round(pl:GetShootPos():Distance(tr.HitPos))
        if dist >= 0 and dist <= 30 and self.Clicked == true then
            local findtwig = string.find(tr.Entity:GetModel(), "twig")
            local damage = 40
            if findtwig then damage = 25 end
            self:ShootBullet(damage, 1, 0, "", 0, 1)
            self:SendWeaponAnim(ACT_VM_SWINGHIT)
            self.Clicked = false
            self.delay = CurTime() + 0.1
        end
    end
end

function SWEP:SecondaryAttack()
end