if SERVER then game.ConsoleCommand("sv_hibernate_think 1\n") end
CLOCKWORK = CLOCKWORK or {}
CLOCKWORK.Bytes = {}
function CLOCKWORK:Add(name, bytes, item, clock)
    CLOCKWORK.Bytes[name] = {
        {
            Bytes = bytes,
            Time = clock,
            ITEM = item(name, bytes, item, clock),
        },
    }
end

local Night = false
CLOCKWORK:Add("Night", 12, function(n, b, i, c) return function() return "Night" end end, {
    HOURS = 0,
    MINUTES = 10,
    SECONDS = 0
})

CLOCKWORK:Add("Day", 12, function(n, b, i, c) return function() return "Day" end end, {
    HOURS = 0,
    MINUTES = 20,
    SECONDS = 5
})

function CLOCKWORK:GetClock(name)
    return {
        HOURS = CLOCKWORK.Bytes[name][1]["Time"]["HOURS"],
        MINUTES = CLOCKWORK.Bytes[name][1]["Time"]["MINUTES"],
        SECONDS = CLOCKWORK.Bytes[name][1]["Time"]["SECONDS"]
    }
end

function CLOCKWORK:GetITEM(name)
    return CLOCKWORK.Bytes[name][1]["ITEM"]()
end

local Order = {"Day", "Night"}
if CLIENT then -- 0 = full day, 1 = full night
    local nightAmount = 0
    local cm = {
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }

    hook.Add("RenderScreenspaceEffects", "ClockworkDayNight", function()
        -- fade toward the current phase (lower the 0.5 for a slower fade)
        if not Night and nightAmount < 0.01 then return end
        nightAmount = Lerp(FrameTime() * 0.5, nightAmount, Night and 1 or 0)
        -- Day values on the left, Night values on the right
        cm["$pp_colour_addr"] = Lerp(nightAmount, 0, -0.03)
        cm["$pp_colour_addg"] = Lerp(nightAmount, 0, -0.01)
        cm["$pp_colour_addb"] = Lerp(nightAmount, 0, 0.05)
        cm["$pp_colour_brightness"] = Lerp(nightAmount, 0, -0.18)
        cm["$pp_colour_contrast"] = Lerp(nightAmount, 1.05, 0.9)
        cm["$pp_colour_colour"] = Lerp(nightAmount, 1.1, 0.55)
        DrawColorModify(cm)
    end)
end

local function SetPhase(name)
    local compl = CLOCKWORK:GetITEM(name)
    if CLIENT then Night = compl == "Night" end
    print("Phase:", name, "started at", string.format("%.1f", CurTime()))
end

local function GetDuration(name)
    local c = CLOCKWORK:GetClock(name)
    return c.HOURS * 3600 + c.MINUTES * 60 + c.SECONDS
end

local function GetPhase()
    local total = 0
    for _, name in ipairs(Order) do
        total = total + GetDuration(name)
    end

    local t = CurTime() % total
    for _, name in ipairs(Order) do
        local d = GetDuration(name)
        if t < d then -- name, seconds left
            return name, d - t
        end

        t = t - d
    end
end

local LastPhase
timer.Create("ClearTimerClockWork", 1, 0, function()
    local name = GetPhase()
    if name ~= LastPhase then
        SetPhase(GetPhase())
        LastPhase = GetPhase()
    end
end)