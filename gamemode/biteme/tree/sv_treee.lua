local function BackwardsEnums(enumname)
    local backenums = {}
    for k, v in pairs(_G) do
        if isstring(k) and string.find(k, "^" .. enumname) then backenums[v] = k end
    end
    return backenums
end

hook.Add("EntityTakeDamage", "TakeWoodDmg", function(ent, dmginfo)
    local dmginfo_Attk = dmginfo:GetAttacker()
    local MAT = BackwardsEnums("MAT_")
    local item = RustOfficial.GetItem("Wood")
    if MAT[ent:GetMaterialType()] == "MAT_WOOD" then
        AddItemsToGmodCount(dmginfo_Attk, item.name, 100, nil, 500)
    end
end)