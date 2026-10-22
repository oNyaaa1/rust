local function BackwardsEnums(enumname)
    local backenums = {}
    for k, v in pairs(_G) do
        if isstring(k) and string.find(k, "^" .. enumname) then backenums[v] = k end
    end
    return backenums
end

local placeHolster = {5, 10, 20, 40, 80, 128}
hook.Add("EntityTakeDamage", "TakeWoodDmg", function(ent, dmginfo)
    local dmginfo_Attk = dmginfo:GetAttacker()
    local MAT = BackwardsEnums("MAT_")
    local item = RustOfficial.GetItem("Wood")
    if MAT[ent:GetMaterialType()] == "MAT_WOOD" then
        if ent.amount == nil then ent.amount = 0 end
        if ent.amount >= #placeHolster then ent.amount = 0 end
        ent.amount = ent.amount + 1
        AddItemsToGmodCount(dmginfo_Attk, item.name, 100, nil, placeHolster[ent.amount])
    end
end)