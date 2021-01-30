AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "script_init.lua")
include( "shared.lua" )

hsdm_playermodel = "models/player/leet.mdl"

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

for i=1, 6 do
	team.SetSpawnPoint( i, {"info_player_start"} )
end

function GM:PlayerSpawn( ply )
ply:Freeze(false)
ply:AllowFlashlight(true)
ply:SetupHands()
ply:SetModel(hsdm_playermodel)
end