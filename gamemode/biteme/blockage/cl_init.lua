local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudWeaponSelection"] = true,
}

hook.Add("HUDShouldDraw", "HideHUD", function(name)
    if hide[name] then return false end
    --
end)

