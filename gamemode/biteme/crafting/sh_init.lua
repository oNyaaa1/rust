ITEMS = {}
ITEMS.ITEM = {}
COUNT = COUNT or {}
if SERVER then
	util.AddNetworkString("TimerToPlux")
	concommand.Add("sandbox_give", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local me = ply:ExistingInventoryItem({
			Weapon = tostring(args[1])
		}, tonumber(args[2]))

		if me then return end
		ply:AddInventoryItem({
			Weapon = tostring(args[1]),
		}, true, tonumber(args[2]))
		--sandbox_wood_give "Wood" 300
	end)

	local ConVarAdmin = CreateConVar("admin_freepass", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Free stuff for admins")
	util.AddNetworkString("CraftingAbility")
	net.Receive("CraftingAbility", function(len, ply)
		local tbl = net.ReadTable()
		local toCraft = ""
		local toAmount = 0
		local toTime = 30
		local item = ITEMS:GetItem(tbl[1].Info)
		if ConVarAdmin:GetInt() == 1 and ply:IsAdmin() then
			AddItemsToGmod(ply, "Inventory", 1, item.InfoTag, math.random(50, 60), item.Weapon, 1)
			return
		end

		for k, v in pairs(item:Craft()) do
			local itemz = v[1]
			toCraft = itemz.ITEM
			toAmount = itemz.AMOUNT
			toTime = v.Time
		end

		local bool, amount = CalcItem(ply, toCraft)
		if amount < toAmount then return end
		local gate = CurTime() + toTime
		local timerlapse = 1
		if timer.Exists("Craft" .. ply:SteamID64() .. item.Name) then timerlapse = timerlapse + 1 end
		GInv_RemoveItem(ply, toCraft, toAmount)
		timer.Create("Craft" .. ply:SteamID64() .. item.Name .. timerlapse, 1, 0, function()
			local realtime = math.Round(gate - CurTime())
			RustNotify(ply, item.Name, item.Name, realtime, "effect", 8)
			if realtime <= 0 then
				AddItemsToGmod(ply, "Inventory", 1, item.InfoTag, math.random(50, 60), item.Weapon, 1)
				RustNotifyRemove(ply, item.Name)
				timer.Remove("Craft" .. ply:SteamID64() .. item.Name .. timerlapse)
			end
		end)
	end)
end

ITEMS.Catergories = {
	[1] = {"FAVORITE", Material("icons/favorite_inactive.png", "noclamp nobips")},
	[2] = {"COMMON", Material("icons/servers.png", "noclamp nobips")},
	[3] = {"CONSTRUCTION", Material("icons/construction.png", "noclamp nobips")},
	[4] = {"ITEMS", Material("icons/extinguish.png", "noclamp nobips")},
	[5] = {"RESOURCES", Material("icons/servers.png", "noclamp nobips")},
	[6] = {"CLOTHING", Material("icons/servers.png", "noclamp nobips")},
	[7] = {"TOOLS", Material("icons/tools.png", "noclamp nobips")},
	[8] = {"MEDICAL", Material("icons/medical.png", "noclamp nobips")},
	[9] = {"WEAPONS", Material("icons/weapon.png", "noclamp nobips")},
	[10] = {"AMMO", Material("icons/ammo.png", "noclamp nobips")},
	[11] = {"ELECTRICAL", Material("icons/electric.png", "noclamp nobips")},
	[12] = {"FUN", Material("icons/dots.png", "noclamp nobips")},
	[13] = {"OTHER", Material("icons/dots.png", "noclamp nobips")},
	[14] = {"ADMIN", Material("icons/servers.png", "noclamp nobips")}
}

function ITEMS:RegisterItem(itemName, items, category)
	if items.InfoTag == nil then return end
	self[itemName] = items
	local countz = 0
	for k, v in pairs(ITEMS) do
		if type(v) == "table" and v.Category == category then countz = countz + 1 end
	end

	COUNT[string.lower(category)] = countz
end

function ITEMS:GetItem(itemName)
	return self[itemName]
end