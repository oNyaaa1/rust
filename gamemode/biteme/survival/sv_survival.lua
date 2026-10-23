util.AddNetworkString("gRust_Survival")

timer.Create("GRust_Survival", 30, 0, function()
    for k, v in pairs(player.GetAll()) do
        v.Food = v.Food - 1
        v.Water = v.Water - 1
        net.Start("gRust_Survival")
        net.WriteFloat(v.Food)
        net.WriteFloat(v.Water)
        net.Send(v)
    end
end)