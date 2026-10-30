-- lua/autorun/rustnotify.lua
-- Rust-style notification stack, drawn above the bottom-right HUD bars.
if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("RustNotify")
    -- RustNotify(ply, id, text, value, style, duration, icon)
    -- style: "pickup" (green) | "effect" (blue) | "info" (olive)
    -- duration: seconds, 0 = stays until RustNotifyRemove
    function RustNotify(ply, id, text, value, style, duration, icon)
        net.Start("RustNotify")
        net.WriteString(id or text)
        net.WriteString(text or "")
        net.WriteString(tostring(value or ""))
        net.WriteString(style or "info")
        net.WriteFloat(duration or 4)
        net.WriteString(icon or "")
        net.Send(ply)
    end

    function RustNotifyRemove(ply, id)
        net.Start("RustNotify")
        net.WriteString(id)
        net.WriteString("")
        net.WriteString("")
        net.WriteString("remove")
        net.WriteFloat(0)
        net.WriteString("")
        net.Send(ply)
    end
    return
end

---------------------------------------------------------------------
-- CLIENT
---------------------------------------------------------------------
local notes = {}
local STYLES = {
    pickup = {
        bg = Color(88, 112, 46),
        icon = "icon16/arrow_down.png"
    },
    effect = {
        bg = Color(40, 112, 176),
        icon = "icon16/cog.png"
    },
    info = {
        bg = Color(78, 98, 40),
        icon = "icon16/house.png"
    },
}

local mats = {}
local function GetMat(path)
    mats[path] = mats[path] or Material(path)
    return mats[path]
end

local function S(n)
    return math.floor(n * (ScrH() / 1080))
end

local function MakeFonts()
    surface.CreateFont("RustNotify", {
        font = "Roboto Condensed",
        size = S(15),
        weight = 800,
        extended = true
    })
end

MakeFonts()
hook.Add("OnScreenSizeChanged", "RustNotify_Fonts", MakeFonts)
local function Add(id, text, value, style, duration, icon)
    if style == "remove" then
        for _, n in ipairs(notes) do
            if n.id == id then n.dieAt = CurTime() end
        end
        return
    end

    local now = CurTime()
    for _, n in ipairs(notes) do
        if n.id == id and n.dieAt > now then
            -- same id: refresh, and add up numeric pickups (+1 -> +2)
            local old, new = tonumber(n.value), tonumber(value)
            n.value = (style == "pickup" and old and new) and (old + new) or value
            n.text, n.style = text, style
            n.start = now
            n.dieAt = duration > 0 and (now + duration) or math.huge
            n.duration = duration
            return
        end
    end

    notes[#notes + 1] = {
        id = id,
        text = text,
        value = value,
        style = style,
        icon = icon ~= "" and icon or nil,
        start = now,
        born = now,
        duration = duration,
        dieAt = duration > 0 and (now + duration) or math.huge,
        y = 0,
    }
end

RustNotify = Add
net.Receive("RustNotify", function()
    local id, text, value = net.ReadString(), net.ReadString(), net.ReadString()
    local style, duration, icon = net.ReadString(), net.ReadFloat(), net.ReadString()
    Add(id, text, value, style, duration, icon)
end)

hook.Add("HUDPaint", "RustNotify_Draw", function()
    if #notes == 0 then return end
    local now = CurTime()
    local hx, hy = ScrW() - 255, ScrH() - 110 -- your HUD origin
    local w, h, gap = 220, S(30), S(2)
    local x = hx
    local baseY = hy - h - S(6)
    for i = #notes, 1, -1 do
        if now > notes[i].dieAt + 0.3 then table.remove(notes, i) end
    end

    for i, n in ipairs(notes) do
        local st = STYLES[n.style] or STYLES.info
        local fadeIn = math.Clamp((now - n.born) / 0.15, 0, 1)
        local fadeOut = n.dieAt == math.huge and 1 or math.Clamp(1 - (now - n.dieAt) / 0.3, 0, 1)
        local a = fadeIn * fadeOut
        -- newest at the bottom, older ones pushed up
        local targetY = baseY - (#notes - i) * (h + gap)
        n.y = n.y == 0 and targetY or Lerp(FrameTime() * 12, n.y, targetY)
        local y = n.y
        surface.SetDrawColor(st.bg.r, st.bg.g, st.bg.b, 235 * a)
        surface.DrawRect(x, y, w, h)
        -- icon
        surface.SetDrawColor(255, 255, 255, 255 * a)
        surface.SetMaterial(GetMat(n.icon or st.icon))
        surface.DrawTexturedRect(x + S(4), y + (h - S(14)) / 2, S(14), S(14))
        -- label
        draw.SimpleText(string.upper(n.text), "RustNotify", x + S(24), y + h / 2, Color(255, 255, 255, 255 * a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- value (effects with a duration show a live countdown like "1s")
        local val = n.value
        if n.style == "effect" and n.duration > 0 and val == "" then
            val = math.max(0, math.ceil(n.dieAt - now)) .. "s"
        elseif n.style == "pickup" and tonumber(val) then
            val = "+" .. val
        end

        if val ~= "" then draw.SimpleText(val, "RustNotify", x + w - S(6), y + h / 2, Color(255, 255, 255, 255 * a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    end
end)

-- test: type rn_test in console
concommand.Add("rn_test", function()
    Add("bandage", "Bandage", "1", "pickup", 4, "")
    Add("bandage_fx", "Bandage", "", "effect", 8, "")
    Add("upkeep", "Upkeep Time", "33 hrs", "info", 0, "")
    Add("bp", "Building Privilege", "", "info", 0, "icon16/box.png")
end)