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
if SERVER then util.AddNetworkString("RemoveGhostGRUST") end
function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "Selected")
end

-- same order as RadialMenu.Items, so the wheel index matches
SWEP.Items = {"sent_foundation", "sent_wall", "sent_door", "sent_ceiling", "sent_doorway", "sent_stairs", "sent_doorwayl"}
function SWEP:Initialize()
    self:SetHoldType("pistol")
    self:SetSelected(1)
end

function SWEP:GetSelectedClass()
    return self.Items[self:GetSelected()] or "sent_foundation"
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then return end
    local ply = self:GetOwner()
    local class = self:GetSelectedClass()
    local pos, ang, text = DEPLOY:GetSocket(ply, class)
    if not pos or text == "none" then return end
    local ok, taken = GInv_RemoveItem(ply, "Wood", 50)
    if ok == false then return end
    DEPLOY:SetSocket(ply, class, pos, ang)
    ply:EmitSound("building/hammer_saw_" .. math.random(1, 3) .. ".wav")
end

-- Right click: cycle item
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
    local ply = self:GetOwner()
    ply:ConCommand("+radial")
    if CLIENT then return end
end

function SWEP:Reload()
end

function SWEP:RemoveGhost()
    if SERVER then return end
    if IsValid(self.Ghost) then
        self.Ghost:Remove()
        self.Ghost = nil
    end
end

local function GetModelFor(class)
    local ent = scripted_ents.Get(class or "")
    if not ent then return end
    local m = ent.Model or ent.Models -- use whichever field your entities define
    if istable(m) then m = m[1] end
    return isstring(m) and m or nil
end

function SWEP:Think()
    if SERVER then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or ply ~= LocalPlayer() then return end
    local class = self:GetSelectedClass()
    local model = GetModelFor(class)
    local ent = ply:GetEyeTrace()
    local pos, ang, text = DEPLOY:GetSocket(ply, class)
    if not model or not pos then
        self:RemoveGhost()
        return
    end

    -- create once, or rebuild only when the selected piece changes
    if not IsValid(self.Ghost) or self.GhostModel ~= model then
        self:RemoveGhost()
        util.PrecacheModel(model)
        self.Ghost = ClientsideModel(model, RENDERGROUP_TRANSLUCENT)
        self.GhostModel = model
        self.Ghost:SetRenderMode(RENDERMODE_TRANSALPHA)
    end

    -- update colour every frame so it reacts to blocked spots
    if text == "none" then
        self.Ghost:SetColor(Color(255, 0, 0, 120))
    else
        self.Ghost:SetColor(Color(0, 255, 0, 120))
    end

    self.Ghost:SetPos(pos)
    self.Ghost:SetAngles(ang)
end

function SWEP:OnRemove()
    self:RemoveGhost()
end

function SWEP:DrawHUD()
end

function SWEP:Deploy()
    return true
end

function SWEP:Holster()
    return true
end

local function RemoveGhost(wer)
    if IsValid(wer) and IsValid(wer.Ghost) then
        wer.Ghost:Remove()
        wer.Ghost = nil
    end
end

hook.Add("Think", "RemoveGhost", function()
    if SERVER then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if not lastwe and wep:GetClass() == "rust_builder" then lastwe = wep end
    RemoveGhost(lastwe)
end)

function SWEP:OnRemove()
    self:RemoveGhost()
end

function SWEP:OnDrop()
    self:RemoveGhost()
end