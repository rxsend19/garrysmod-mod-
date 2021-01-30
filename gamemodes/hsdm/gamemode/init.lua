AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "script_init.lua")
include( "shared.lua" )

HSDM_SUPERADMIN_PLAYERMODELS = {
"models/player/gman_high.mdl"
}

HSDM_ADMIN_PLAYERMODELS = {
"models/player/combine_soldier.mdl",
"models/player/combine_super_soldier.mdl",
"models/player/combine_soldier_prisonguard.mdl",
"models/player/police.mdl"
}

HSDM_USER_PLAYERMODELS = {
--t3rr0r1sts
"models/player/leet.mdl",
"models/player/phoenix.mdl",
"models/player/guerilla.mdl",
"models/player/arctic.mdl",
--c0unt3r-t3rr0r1sts
"models/player/gasmask.mdl",
"models/player/swat.mdl",
"models/player/riot.mdl",
"models/player/urban.mdl"
}

function GM:PlayerSpawn(ply)
    if ply:IsUserGroup("superadmin") then
    	ply:SetTeam(6)
  	elseif ply:IsUserGroup("admin") then
  		ply:SetTeam(2)
  	elseif ply:SteamID64() == "76561198982442067" then
  		ply:SetTeam(3)
  	elseif ply:IsUserGroup("moderator") then
  		ply:SetTeam(5)
    elseif ply:IsUserGroup("premium") then
    	ply:SetTeam(4)
    else
    	ply:SetTeam(1)
    end
end

function GM:PlayerLoadout(nextoren)

    --if nextoren:Team() == 1 then

 		nextoren:StripWeapons()
        nextoren:Give("weapon_crowbar")
 		nextoren:Give("weapon_pistol")
 		nextoren:GiveAmmo(48, "Pistol", true)
 		nextoren:EquipSuit()
    --end
 
end

for adidas=1, 6 do
	team.SetSpawnPoint( adidas, {"info_player_start"} )
end

function GM:PlayerSpawn(ply)
	ply:Freeze(false)
	ply:AllowFlashlight(true)
	ply:SetupHands()
	
		if ply:IsAdmin() then
			ply:SetModel(table.Random(HSDM_ADMIN_PLAYERMODELS)
		elseif ply:IsSuperAdmin() then
			ply:SetModel(table.Random(HDSM_SUPERADMIN_PLAYERMODELS)
		else
			ply:SetModel(table.Random(HSDM_USER_PLAYERMODELS)
		end
end
