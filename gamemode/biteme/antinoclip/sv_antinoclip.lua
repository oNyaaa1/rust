local unhook = {
	["PlayerNoClip"] = true
}

for k, v in pairs(hook.GetTable()) do
	if unhook[k] and istable(v) then
		for _, j in pairs(v) do
			hook.Remove(k, _)
			print("Useless hook Removing: ", k, _, j)
		end
	end
end

hook.Add("PlayerNoClip", "antinoclip", function(ply) return ply:IsAdmin() end)
print("hi")