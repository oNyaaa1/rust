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

-- same order as RadialMenu.Items, so the wheel index matches
SWEP.Items = {"sent_foundation", "sent_wall", "sent_door", "sent_ceiling", "sent_doorway", "sent_stairs",}
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
    local class = self:GetSelectedClass()
    local pos, ang = DEPLOY:GetSocket(ply, class)
    if not pos then return end
    DEPLOY:SetSocket(ply, class, pos, ang) -- was hardcoded to "sent_foundation"
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

if CLIENT then
    function SWEP:RemoveGhost()
        GRUST_GHOST:ReleaseGhostEntity()
    end

    local function GetModelFor(class)
        local ent = scripted_ents.Get(class or "")
        if not ent then return end
        local m = ent.Model or ent.Models -- use whichever field your entities define
        if istable(m) then m = m[1] end
        return isstring(m) and m or nil
    end

    local function KillGhost(wep)
        if IsValid(wep) then
            if IsValid(wep.Ghost) then wep.Ghost:Remove() end
            wep.Ghost, wep.GhostModel = nil, nil
        end
    end

    function SWEP:RemoveGhost()
        KillGhost(self)
    end

    function SWEP:Think()
        local ply = self:GetOwner()
        if not IsValid(ply) or ply ~= LocalPlayer() then return end
        local class = self:GetSelectedClass()
        local model = GetModelFor(class)
        local pos, ang = DEPLOY:GetSocket(ply, class)
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
            self.Ghost:SetColor(Color(255, 255, 255, 120))
        end

        self.Ghost:SetPos(pos)
        self.Ghost:SetAngles(ang)
    end

    function SWEP:Holster()
        self:RemoveGhost()
        return true
    end

    function SWEP:OnRemove()
        self:RemoveGhost()
    end

    function SWEP:DrawHUD()
        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        local _, _, txt = DEPLOY:GetSocket(ply, self:GetSelectedClass())
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

    -- the ghost lives in a global so cleanup doesn't depend on the weapon being active
    -- the weapon the ghost belongs to, so we can clean it up from outside
    local lastWep
    hook.Add("Think", "DeployGhost_Cleanup", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        local holding = IsValid(wep) and wep:GetClass() == "rust_deploy" -- match your weapon's class (lowercase)
        if holding then
            lastWep = wep
        elseif IsValid(lastWep) then
            KillGhost(lastWep) -- switched to the rock / anything else
            lastWep = nil
        end

        if not ply:Alive() and IsValid(lastWep) then KillGhost(lastWep) end
    end)
end