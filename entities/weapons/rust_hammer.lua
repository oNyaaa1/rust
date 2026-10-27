AddCSLuaFile()
SWEP.PrintName = "Deploy Placer"
SWEP.Category = "Deploy"
SWEP.Spawnable = true
SWEP.DrawCrosshair = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/darky_m/rust/c_hammer.mdl"
SWEP.WorldModel = "models/weapons/darky_m/rust/w_hammer.mdl"
SWEP.Slot = 5
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
if SERVER then util.AddNetworkString("RemoveGhostGRUST") end
function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "Selected")
end

function SWEP:Initialize()
    self:SetHoldType("pistol")
    self:SetSelected(1)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if SERVER then return end
    local ply = self:GetOwner()
    local items = RadialMenu2.Items
    local select = items[RadialMenu2.Selected] and items[RadialMenu2.Selected].class or ""
    net.Start("RadialMenu2_Spawn")
    net.WriteString(select)
    net.SendToServer()
end

-- Right click: cycle item
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
    local ply = self:GetOwner()
    ply:ConCommand("+radialhammer")
    if CLIENT then return end
end

function SWEP:Reload()
end

function SWEP:RemoveGhost()
end

function SWEP:Think()
end

function SWEP:OnRemove()
end

function SWEP:DrawHUD()
end

function SWEP:Deploy()
    return true
end

function SWEP:Holster()
    return true
end