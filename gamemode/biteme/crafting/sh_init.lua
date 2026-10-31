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

	local Queues = {}
	local MAX_QUEUE = 10
	local function StopCrafting(id, ply)
		timer.Remove("Craft" .. id)
		local front = Queues[id] and Queues[id][1]
		if front and IsValid(ply) then RustNotifyRemove(ply, front.item.Name) end
		Queues[id] = nil
	end

	local function StartCraft(ply)
		local id = ply:SteamID64()
		local job = Queues[id] and Queues[id][1]
		if not job then return StopCrafting(id, ply) end
		job.finish = CurTime() + job.time
		timer.Create("Craft" .. id, 1, 0, function()
			if not IsValid(ply) or not ply:Alive() then return StopCrafting(id, ply) end
			local item = job.item
			local left = math.Round(job.finish - CurTime())
			RustNotify(ply, item.Name, item.Name, left, "effect", 8)
			if left > 0 then return end
			AddItemsToGmod(ply, "Inventory", 1, item.InfoTag, math.random(50, 60), item.Weapon, 1)
			RustNotifyRemove(ply, item.Name)
			table.remove(Queues[id], 1)
			StartCraft(ply) -- starts the next job, or cleans up if the queue is empty
		end)
	end

	hook.Add("PlayerDisconnected", "CraftQueueCleanup", function(ply) StopCrafting(ply:SteamID64(), nil) end)
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
		local id = ply:SteamID64()
		Queues[id] = Queues[id] or {}
		if #Queues[id] >= MAX_QUEUE then return end
		GInv_RemoveItem(ply, toCraft, toAmount)
		table.insert(Queues[id], {
			item = item,
			time = toTime
		})

		if #Queues[id] == 1 then StartCraft(ply) end
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