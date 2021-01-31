--ORIGINAL ADDON: https://steamcommunity.com/sharedfiles/filedetails/?id=2352255828
AddCSLuaFile() -- if this seems kind of complex for this simple addon, this InitFiles function is what I use for everything so whatever.
GWS_BOTS = GWS_BOTS or {}
local function InitFiles(dir)
	local fil, fol = file.Find(dir.."/*", "LUA")

	for k, folder in pairs(fol) do
		InitFiles(dir.."/"..folder)
	end

	for k, v in pairs(fil) do
		local realm = string.sub(v,0,2)
		if realm != "sv" then -- Only cl_ files will pass this check and is loaded only on the client
			AddCSLuaFile(dir.."/"..v)
			if CLIENT then
				include(dir.."/"..v)
			end
			print("Loading "..dir.."/"..v.." on the client...")
		end
		if SERVER and realm != "cl" then -- Only sv_ files will pass this check and is loaded only on the server.
			include(dir.."/"..v)
			print("Loading "..dir.."/"..v.." on the server...")
		end --Everytihng else, such as sh_, will pass both checks and is shared.
	end
	print("Finished initializing "..dir)
end
InitFiles("gws_bots")
