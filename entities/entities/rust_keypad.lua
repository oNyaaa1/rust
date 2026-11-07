AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Code Lock"
ENT.Spawnable = false
ENT.Model = "models/deployable/keypad.mdl"
ENT.UseDist = 150
ENT.LEDOffset = Vector(2, 0, 4) -- tweak so the LED sits on the keypad face
function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Locked")
end

if SERVER then
    util.AddNetworkString("CodeLock_Open")
    util.AddNetworkString("CodeLock_Action")
    util.AddNetworkString("CodeLock_Result")
    function ENT:Initialize()
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetUseType(SIMPLE_USE)
        self.Code, self.GuestCode = nil, nil
        self.Master, self.Guests, self.Fails, self.NextTry = {}, {}, {}, {}
    end

    function ENT:HasAccess(ply)
        local id = ply:SteamID64()
        return self.Master[id] or self.Guests[id] or false
    end

    local function Result(ply, ok, msg, close)
        net.Start("CodeLock_Result")
        net.WriteBool(ok)
        net.WriteString(msg)
        net.WriteBool(close or false)
        net.Send(ply)
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        local id = ply:SteamID64()
        net.Start("CodeLock_Open")
        net.WriteEntity(self)
        net.WriteBool(self:GetLocked())
        net.WriteBool(self.Master[id] == true)
        net.WriteBool(self.Guests[id] == true)
        net.Send(ply)
    end

    function ENT:Punish(ply)
        local id = ply:SteamID64()
        local f = self.Fails[id]
        if not f or CurTime() - f.t > 30 then
            f = {
                n = 0
            }
        end

        f.n, f.t = f.n + 1, CurTime()
        self.Fails[id] = f
        local dmg = DamageInfo()
        dmg:SetDamage(math.min(f.n * 4, 40)) -- grows each miss, capped
        dmg:SetDamageType(DMG_SHOCK)
        dmg:SetAttacker(self)
        dmg:SetInflictor(self)
        ply:TakeDamageInfo(dmg)
        self:EmitSound("buttons/button10.wav")
        local ed = EffectData()
        ed:SetOrigin(self:GetPos())
        ed:SetMagnitude(2)
        ed:SetScale(1)
        ed:SetRadius(2)
        util.Effect("ElectricSpark", ed)
    end

    function ENT:HandleAction(ply, action, code)
        local id = ply:SteamID64()
        local valid = code:match("^%d%d%d%d$") ~= nil
        if action == "try" then
            if not self:GetLocked() or not valid then return end
            if (self.NextTry[id] or 0) > CurTime() then return end
            self.NextTry[id] = CurTime() + 0.5
            if code == self.Code then
                self.Master[id] = true
                self:EmitSound("buttons/button14.wav")
                Result(ply, true, "Access granted", true)
            elseif self.GuestCode and code == self.GuestCode then
                self.Guests[id] = true
                self:EmitSound("buttons/button14.wav")
                Result(ply, true, "Guest access granted", true)
            else
                self:Punish(ply)
                Result(ply, false, "Wrong code")
            end
        elseif action == "setcode" then
            if self:GetLocked() or not valid then return end
            self.Code = code
            self.Master, self.Guests = {
                [id] = true -- changing code revokes everyone else
            }, {}

            Result(ply, true, "Code set")
        elseif action == "setguest" then
            if self:GetLocked() or not valid or not self.Code then return end
            self.GuestCode = code
            self.Guests = {}
            Result(ply, true, "Guest code set")
        elseif action == "lock" then
            if self:GetLocked() or not self.Code then return Result(ply, false, "Set a code first") end
            self:SetLocked(true)
            self.Master[id] = true
            self:EmitSound("buttons/button3.wav")
            Result(ply, true, "Locked", true)
        elseif action == "unlock" then
            if not self:GetLocked() or not self.Master[id] then return end
            self:SetLocked(false)
            self:EmitSound("buttons/button3.wav")
            Result(ply, true, "Unlocked", true)
        elseif action == "remove" then
            if self:GetLocked() then return end
            if IsValid(self.Target) then self.Target.CodeLock = nil end
            self:Remove()
        end
    end

    net.Receive("CodeLock_Action", function(_, ply)
        local lock = net.ReadEntity()
        local action = net.ReadString()
        local code = net.ReadString()
        if not IsValid(lock) or lock:GetClass() ~= "sent_codelock" then return end
        if not ply:Alive() then return end
        if ply:GetPos():DistToSqr(lock:GetPos()) > lock.UseDist ^ 2 then return end
        lock:HandleAction(ply, action, code)
    end)
end

if CLIENT then
    local ledMat = Material("sprites/glow04_noz")
    function ENT:Draw()
        self:DrawModel()
        local col = self:GetLocked() and Color(255, 30, 30) or Color(30, 255, 30)
        render.SetMaterial(ledMat)
        render.DrawSprite(self:LocalToWorld(self.LEDOffset), 4, 4, col)
    end

    local function Send(lock, action, code)
        net.Start("CodeLock_Action")
        net.WriteEntity(lock)
        net.WriteString(action)
        net.WriteString(code or "")
        net.SendToServer()
    end

    local function Btn(parent, text, x, y, w, h, fn)
        local b = vgui.Create("DButton", parent)
        b:SetPos(x, y)
        b:SetSize(w, h)
        b:SetText(text)
        b.DoClick = fn
        return b
    end

    net.Receive("CodeLock_Open", function()
        local lock = net.ReadEntity()
        local locked = net.ReadBool()
        local master = net.ReadBool()
        local guest = net.ReadBool()
        if not IsValid(lock) then return end
        if IsValid(CodeLockPanel) then CodeLockPanel:Remove() end
        local f = vgui.Create("DFrame")
        CodeLockPanel = f
        f:SetTitle("Code Lock")
        f:SetSize(230, 120)
        f:Center()
        f:MakePopup()
        f.Code = ""
        f.Disp = vgui.Create("DLabel", f)
        f.Disp:SetPos(20, 30)
        f.Disp:SetSize(190, 30)
        f.Disp:SetFont("DermaLarge")
        f.Disp:SetText("")
        function f:Show(txt)
            self.Disp:SetText(txt)
        end

        -- locked, and you hold the main code: just offer unlock
        if locked and master then
            f:Show("Locked")
            Btn(f, "Unlock", 20, 70, 190, 35, function() Send(lock, "unlock") end)
            return
        end

        -- locked, guest: nothing to do
        if locked and guest then
            f:Show("Guest access")
            return
        end

        -- keypad
        f:SetSize(230, locked and 335 or 375)
        f:Center()
        local function refresh()
            f:Show(string.rep("*", #f.Code))
        end

        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "<"}
        for i, k in ipairs(keys) do
            local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
            Btn(f, k, 20 + col * 65, 70 + row * 50, 60, 45, function()
                if k == "C" then
                    f.Code = ""
                elseif k == "<" then
                    f.Code = f.Code:sub(1, -2)
                elseif #f.Code < 4 then
                    f.Code = f.Code .. k
                end

                refresh()
            end)
        end

        if locked then
            Btn(f, "Enter", 20, 280, 190, 40, function() Send(lock, "try", f.Code) end)
        else
            Btn(f, "Set Code", 20, 280, 92, 40, function() Send(lock, "setcode", f.Code) end)
            Btn(f, "Guest Code", 118, 280, 92, 40, function() Send(lock, "setguest", f.Code) end)
            Btn(f, "Lock", 20, 325, 92, 40, function() Send(lock, "lock") end)
            Btn(f, "Remove", 118, 325, 92, 40, function()
                Send(lock, "remove")
                f:Close()
            end)
        end
    end)

    net.Receive("CodeLock_Result", function()
        local ok, msg, close = net.ReadBool(), net.ReadString(), net.ReadBool()
        local f = CodeLockPanel
        if not IsValid(f) then return end
        if close then
            f:Close()
            return
        end

        f.Code = ""
        f:Show(msg)
    end)
end