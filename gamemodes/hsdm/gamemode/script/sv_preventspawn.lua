hook.Add("PlayerSpawnEffect", "rxsend_effects", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnNPC", "rxsend_npcs", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnObject", "rxsend_objects", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnProp", "rxsend_props", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnRagdoll", "rxsend_ragdolls", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnSENT", "rxsend_sents", function(ply, model)
    return false
end)
hook.Add("PlayerSpawnSWEP", "rxsend_sweps", function(ply, wep)
	if RESTRICTED_WEAPONS[ wep ] then
		return false
	else
		return true
	end
end)
hook.Add("PlayerSpawnVehicle", "rxsend_vehicles", function(ply, model)
    return false
end)

RESTRICTED_WEAPONS = {
	"weapon_physgun" = true,
	"gmod_tool" = true,
	"gmod_camera" = true,
	"weapon_physcannon" = true,
	"weapon_rpg" = true
}
