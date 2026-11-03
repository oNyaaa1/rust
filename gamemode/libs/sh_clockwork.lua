game.ConsoleCommand("sv_hibernate_think 1\n")
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

CLOCKWORK:Add("Test", 12, function(n, b, i, c) return function() return "Test Completed" end end, {
    HOURS = 0,
    MINUTES = 30,
    SECONDS = 10
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

local Completed = {}
timer.Create("ClearTimerClockWork", 1, 0, function()
    for k, v in pairs(CLOCKWORK.Bytes) do
        local time = SysTime()
        local hours = math.floor(time / 3600)
        local minutes = math.floor(time / 60) % 60
        local seconds = time % 60
        local formatted = string.format("%02d: %02d: %02d", hours, minutes, seconds)
        local clockworks = CLOCKWORK:GetClock(k)
        if hours >= clockworks.HOURS and minutes >= clockworks.MINUTES and seconds >= clockworks.SECONDS and not Completed[k] then
            Completed[k] = true
            print("Application: ", k, "Launched at: ", formatted)
            local compl = CLOCKWORK:GetITEM(k)
            if compl == "Test Completed" then end
        end
    end
end)