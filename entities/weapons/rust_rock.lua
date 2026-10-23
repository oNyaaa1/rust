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
    self.SWING = CreateSound(self, "tools/rock_swing.mp3")
    self.HIT = CreateSound(self, "tools/rock_strike_" .. math.random(1, 4) .. ".mp3")
    self.Throwing = false
end

function SWEP:Deploy()
    self:SetHoldType("melee")
    self.delay = 0
    self.Clicked = false
    self.SWING = CreateSound(self, "tools/rock_swing.mp3")
    self.HIT = CreateSound(self, "tools/rock_strike_" .. math.random(1, 4) .. ".mp3")
    self.Throwing = false
    return true
end

function SWEP:PrimaryAttack()
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    if self.Throwing then
        self.Throwing = false
        return
    end

    pl:SetAnimation(PLAYER_ATTACK1)
    self.HIT:Stop()
    self.SWING:Play()
    self:SendWeaponAnim(ACT_VM_SWINGMISS)
    self.delay = CurTime() + 0.5
    self:SetNextPrimaryFire(CurTime() + 1.5)
    self.Clicked = true
end

local function DroppableBag(ply, name, count, model)
    local emptySlot, Slot = GetEmptySlot(ply)
    ply.GInv[31] = nil
    local ent = ents.Create("item_bag")
    ent:SetItemName(name)
    ent:SetSizeItem(count)
    ent:SetModel(model)
    ent:Spawn()
    ent:Activate()
    ent:SetPos(ply:GetPos() + ply:GetUp() * 40 + ply:EyeAngles():Forward() * 30)
    local wep = RustOfficial.GetItem(name)
    if wep and wep.weapon then
        local hasRemaining = false
        for _, v in pairs(ply.GInv) do
            if v.id == name then
                hasRemaining = true
                break
            end
        end

        if not hasRemaining and ply:HasWeapon(wep.weapon) then ply:StripWeapon(wep.weapon) end
    end

    SendInv(ply)
    return ent
end

function SWEP:Think()
    if CLIENT then return end
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    if self.Throwing and pl:KeyDown(IN_ATTACK2) and pl:KeyPressed(IN_ATTACK) then
        self:SendWeaponAnim(ACT_VM_THROW)
        pl:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_THROW)
        local bag = DroppableBag(pl, "Rock", 1, "models/weapons/darky_m/rust/w_rock.mdl")
        local phys = bag:GetPhysicsObject()
        if phys and IsValid(phys) then phys:SetVelocity(pl:EyeAngles():Forward() * 1500) end
        return
    elseif self.Throwing and not pl:KeyDown(IN_ATTACK2) then
        self.Throwing = false
        pl:SetAnimation(PLAYER_ATTACK1)
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    end

    if self.delay < CurTime() then
        local tr = pl:GetEyeTrace()
        local dist = math.Round(pl:GetShootPos():Distance(tr.HitPos))
        if dist >= 0 and dist <= 30 and self.Clicked == true then
            self.SWING:Stop()
            self.HIT:Play()
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
    local pl = self:GetOwner()
    if not IsValid(pl) then return end
    self:SendWeaponAnim(ACT_VM_PULLPIN)
    self.Throwing = true
end