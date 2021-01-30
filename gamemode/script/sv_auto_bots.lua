CreateConVar("bot_quota", "7", FCVAR_ARCHIVE, "How many bots to spawn", 0, 128)

if GetConVar("bot_quota"):GetInt() > 0 then
for k, GetConVar("bot_quota"):GetInt() do
	RunConsoleCommand("bot")
end

hook.Add("Think", "dzhambolat_nadezhda_kibersporta", function()
	--[[
    if table.Count(player.GetHumans()) == 0 and table.Count(player.GetBots()) > 0 then
        for k, v in ipairs(player.GetBots()) do
            v:Kick("Отключён системой")
        end
    end
    --]]
    if table.Count(player.GetBots()) > GetConVar("bot_quota"):GetInt() then
    	for k, v in ipairs(player.GetBots()) do
    		v:Kick("Отключён системой")
		end

		for k, GetConVar("bot_quota"):GetInt() do
			RunConsoleCommand("bot")
		end

	end

	if table.Count(player.GetHumans()) == GetConVar("bot_quota"):GetInt() then
		for k, v in ipairs(player.GetBots()) do
			v:Kick("Отключён системой")
		end
	end
end)