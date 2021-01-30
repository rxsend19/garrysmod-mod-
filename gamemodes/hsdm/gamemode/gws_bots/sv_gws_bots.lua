--ORIGINAL ADDON: https://steamcommunity.com/sharedfiles/filedetails/?id=2352255828
GWS_BOTS = {}

GWS_BOTS.CONVARS = {
	["lookaheaddist"] = CreateConVar("bot_lookaheaddist", 200, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "lookaheaddist", 1, 2500),
	["attackdist"] = CreateConVar("bot_attackdist", 200, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "attackdist", 1, 2500),
	["navdist"] = CreateConVar("bot_navdist", 200, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "navdist", 1, 2500),
	["sidespeed"] = CreateConVar("bot_sidespeed", 10, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "sidespeed", 1, 20),
	["forwardspeed"] = CreateConVar("bot_forwardspeed", 100, {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "forwardspeed", 1, 500),
}

GWS_BOTS.WEAPON = GWS_BOTS.WEAPON or "weapon_crowbar"

GWS_BOTS.MODELS = {
	"models/player/Group01/male_03.mdl",
	"models/player/Group01/male_02.mdl",
	"models/player/Group01/male_01.mdl",
	"models/player/Group01/male_05.mdl",
	"models/player/Group01/male_04.mdl",
	"models/player/leet.mdl",
	"models/player/barney.mdl",
	"models/player/Group01/female_04.mdl",
	"models/player/gman_high.mdl",
	"models/player/hostage/hostage_04.mdl"
}

GWS_BOTS.MoveToPos = function(ply, cmd, pos)
	local am = GWS_BOTS.CONVARS["sidespeed"]:GetInt()
	local speed = GWS_BOTS.CONVARS["forwardspeed"]:GetInt()
	local ang = (pos - ply:EyePos() + Vector(0,0,50)):GetNormalized():Angle()
	--ang.x = 0
	--ang.z = 0
	cmd:SetViewAngles( ang )
	cmd:SetForwardMove( speed )
	ply.side = ply.side + math.random(-am,am)
	cmd:SetSideMove( math.Clamp(ply.side, -300, 300) )
	return true
end

GWS_BOTS.FaceTowards = function(ply, cmd, pos)
	local am = GWS_BOTS.CONVARS["sidespeed"]:GetInt()
	local ang = (pos - ply:EyePos() + Vector(0,0,50)):GetNormalized():Angle()
	--ang.x = 0
	--ang.z = 0
	cmd:SetViewAngles( ang )
	ply.side = ply.side + math.random(-am,am)
	cmd:SetSideMove( math.Clamp(ply.side, -300, 300) )
	return true
end

GWS_BOTS.SetWeapons = function(wep)
	GWS_BOTS.WEAPON = wep
end

GWS_BOTS.Wonder = function(ply)
	local am = GWS_BOTS.CONVARS["lookaheaddist"]:GetInt()
	local nav = navmesh.GetNearestNavArea( ply:GetPos() + Vector(math.random(am),math.random(am),0) )
	if IsValid(nav) and !nav:IsUnderwater() then
		local point = nav:GetRandomPoint()
		if ply:IsLineOfSightClear( point ) then
			return point
		else
			return GWS_BOTS.Wonder(ply)
		end
	else
		return ply.pos
	end
end

local GWS_BOTS_MODES = {
	["wondering"] = function(ply, cmd)
		if ply:GetPos():DistToSqr(ply.pos) < 50 * 50 or !ply:IsLineOfSightClear( ply.pos ) then
			ply.pos = GWS_BOTS.Wonder(ply)
		end
		ply.side = 0
		GWS_BOTS.MoveToPos(ply, cmd, ply.pos)
		local wep = ply:GetWeapon(ply.wonderweapon)
		if IsValid(wep) then
			cmd:SelectWeapon(wep)
		end
	end,
	["chasing"] = function(ply, cmd)
		if ply:GetPos():Distance(ply.tar:GetPos()) > ply.attackdist then
			GWS_BOTS.MoveToPos(ply, cmd, ply.tar:GetPos())
		else
			GWS_BOTS.FaceTowards(ply, cmd, ply.tar:GetPos())
		end
		local wep = ply:GetWeapon(GWS_BOTS.WEAPON)
		if IsValid(wep) and ply:GetPos():Distance(ply.tar:GetPos()) < ply.attackdist then
			cmd:SelectWeapon(wep)
			cmd:SetButtons(IN_ATTACK)
		end
	end
}

GWS_BOTS.BOTS_BEHAVIOR = function(ply, cmd)
	if ply:IsBot() then
		cmd:ClearButtons()
		cmd:ClearMovement()

		ply.tar = NULL
		ply.attackdist = GWS_BOTS.CONVARS["attackdist"]:GetInt()
		ply.lookaheaddist = GWS_BOTS.CONVARS["lookaheaddist"]:GetInt()
		local dist = math.huge
		local players = ents.FindInSphere(ply:GetPos(), ply.lookaheaddist)
		for _, v in ipairs(players) do
			if v:IsPlayer() and v!=ply and v:Team() != TEAM_SPECTATOR and v:GetPos():DistToSqr(ply:GetPos()) < dist and ply:IsLineOfSightClear( v:GetPos() ) then
				ply.tar = v
				dist = ply.tar:GetPos():DistToSqr(ply:GetPos())
			end
		end

		if IsValid(ply.tar) then

			ply.state = "chasing"
			ply.pos = ply.tar:GetPos()

		elseif ply.pos == Vector(0,0,0) then

			ply.state = "wondering"
			ply.pos = GWS_BOTS.Wonder(ply)

		else
			ply.state = "wondering"
		end

		GWS_BOTS_MODES[ply.state](ply,cmd)
	end
end

GWS_BOTS.BOTS_INITIALIZE = function(ply)
	if ply:IsBot() then
		ply.ratio = 0
		ply.pos = Vector(0,0,0)
		ply.state = "wondering"
		ply.tar = NULL
		ply.attackdist = GWS_BOTS.CONVARS["attackdist"]:GetInt()
		ply.lookaheaddist = GWS_BOTS.CONVARS["lookaheaddist"]:GetInt()
		ply.wonderweapon = "weapon_crowbar"
		ply.side = 0
	end
end

GWS_BOTS.BOTS_CHANGEMODEL = function(ply)
	if ply:IsBot() then
		local model = GWS_BOTS.MODELS[math.random(1, #GWS_BOTS.MODELS)]
		timer.Simple(0.1, function()
			ply:SetModel(model)
		end)
	end
end

GWS_BOTS.BOTS_HANDLE_DAMAGE = function(ply, dmg)
	if ply:IsBot() then
		local att = dmg:GetAttacker()

		if att:IsPlayer() then
			ply.pos = att:GetPos()
		end
	end
end

hook.Add("EntityTakeDamage", "BOTS_HANDLE_DAMAGE", GWS_BOTS.BOTS_HANDLE_DAMAGE)
hook.Add("StartCommand", "BOTS_BEHAVIOR", GWS_BOTS.BOTS_BEHAVIOR)
hook.Add("PlayerInitialSpawn", "BOTS_INITIALIZE", GWS_BOTS.BOTS_INITIALIZE)
hook.Add("PlayerSpawn", "BOTS_INITIALIZE", GWS_BOTS.BOTS_CHANGEMODEL)


concommand.Add("bot_weapon", function(ply, cmd, args)
	if ply:IsAdmin() then
		local wep = args[1]

		GWS_BOTS.SetWeapons(wep)
	end
end)