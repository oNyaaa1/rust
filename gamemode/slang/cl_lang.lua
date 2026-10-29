print("LAng")
LANG.Allowed = {}
function LANG:Refresh(files)
    hook.Run(files)
end

function LANG:setLanguage(lang)
    if not LANG.Allowed[string.lower(lang)] then
        print("Allowed List:")
        PrintTable(LANG.Allowed)
        return
    end

    RustOfficial.Lang = string.lower(lang)
    LANG:Refresh("sLangCode", lang)
end

concommand.Add("rust_cl", function(ply, cmd, args)
    local lang = args[1]
    print("Language = ", lang)
    LANG:setLanguage(lang)
end)

function LANG:AddLanguage(lng, master, trans)
    RustOfficial.fah = RustOfficial.fah or {}
    LANG.Allowed[lng] = true
    RustOfficial.fah[lng] = RustOfficial.fah[lng] or {}
    RustOfficial.fah[lng][master] = trans
end

function LANG:getLanguage()
    return RustOfficial.fah[RustOfficial.Lang] or "en"
end

hook.Add("sLangCode", "LanguageBarrier", function() RustOfficial.moco:LoadAll() end)
LANG:AddLanguage("en", "Hello", "Hello")
LANG:AddLanguage("ru", "Hello", "cyka blyat")
print("Languages:", #LANG)