if SERVER then
	AddCSLuaFile()
end

local Particles = {}
Particles.PCFParticles = Particles.PCFParticles or {}
Particles.PCFParticles["impact_asphalt"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_brick"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_carpet"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_computer"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_cardboard"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_concrete"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_dirt"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_fruit"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_glass"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_gravel"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_leaves"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_metal"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_mud"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_paper"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_plastic"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_puddle"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_rock"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_rubber"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_sand"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_snow"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_tile"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_water"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_wet"] = "impact_fx_ins_conv"
Particles.PCFParticles["impact_wood"] = "impact_fx_ins_conv"
local addedparts = {}
local cachedparts = {}

function Particles.Initialize()
	for k, v in pairs(Particles.PCFParticles) do
		if not addedparts[v] then
			game.AddParticles("particles/" .. v .. ".pcf")
			addedparts[v] = true
		end

		if not cachedparts[k] and not string.find(k, "DUMMY") then
			PrecacheParticleSystem(k)
			cachedparts[k] = true
		end
	end
end

hook.Add("InitPostEntity", "Particles.Initialize", Particles.Initialize)
Particles.Initialize()
Particles.List = {}

Particles.List_Pre = {
	["wallpaper"] = "impact_cardboard"
}

Particles.List_Post = {
	["building"] = "impact_brick"
}

Particles.List_Mats = {
	[MAT_CONCRETE] = "impact_concrete",
	[MAT_DIRT] = "impact_dirt",
	[MAT_EGGSHELL] = "impact_dirt",
	[MAT_GRATE] = "impact_metal",
	[MAT_CLIP] = "impact_metal",
	[MAT_SNOW] = "impact_snow",
	[MAT_PLASTIC] = "impact_plastic",
	[MAT_METAL] = "impact_metal",
	[MAT_SAND] = "impact_sand",
	[MAT_FOLIAGE] = "impact_leaves",
	[MAT_COMPUTER] = "impact_computer",
	[MAT_SLOSH] = "impact_water",
	[MAT_TILE] = "impact_tile",
	[MAT_GRASS] = "impact_dirt",
	[MAT_VENT] = "impact_metal",
	[MAT_WOOD] = "impact_wood",
	[MAT_GLASS] = "impact_glass",
	[MAT_DEFAULT] = "NONE",--"impact_concrete",
	[MAT_FLESH] = "NONE"
}

for k, _ in pairs(Particles.PCFParticles) do
	Particles.List[string.Replace(k, "impact_", "")] = k
end

local upVec = Vector(0, 0, 1)
local hasTakenTFA = false

if SERVER then
	util.AddNetworkString("ParticleEffectLit")
end

Particles.SmokeLightingMin = Vector(0.15, 0.15, 0.15)
Particles.SmokeLightingMax = Vector(0.75, 0.75, 0.75)
Particles.SmokeLightingClamp = 1

local function ParticleEffectLit(name, pos, angle, ply)
	if name == "NONE" then return end

	if SERVER then
		net.Start("ParticleEffectLit")
		net.WriteString(name)
		net.WriteVector(pos)
		net.WriteAngle(angle)
		local crep = RecipientFilter()
		crep:AddPVS(pos)

		if IsValid(ply) and ply:IsPlayer() and not game.SinglePlayer() then
			crep:RemovePlayer(ply)
		end

		net.Send(crep)

		return
	end

	local ent = Entity(0)
	local part = CreateParticleSystem(ent, name, PATTACH_ABSORIGIN, -1, pos)

	if IsValid(part) then
		part:SetControlPoint(0, pos)
		part:SetControlPointOrientation(0, angle:Forward(), angle:Right(), angle:Up())
		part:StartEmission()
	end

	if not IsValid(part) then return end
	local licht = render.ComputeLighting(pos + upVec * 2, upVec)

	if TFA and TFA.Particles and TFA.Particles.SmokeLightingClamp and not hasTakenTFA then
		Particles.SmokeLightingClamp = TFA.Particles.SmokeLightingClamp
		Particles.SmokeLightingMin = TFA.Particles.SmokeLightingMin
		Particles.SmokeLightingMax = TFA.Particles.SmokeLightingMax
	end

	local lichtFloat = math.Clamp((licht.r + licht.g + licht.b) / 3, 0, Particles.SmokeLightingClamp) / Particles.SmokeLightingClamp
	local lichtFinal = LerpVector(lichtFloat, Particles.SmokeLightingMin, Particles.SmokeLightingMax * math.Rand(0.8, 0.9))
	part:SetControlPoint(1, lichtFinal)
end

if CLIENT then
	net.Receive("ParticleEffectLit", function()
		local name = net.ReadString()
		local pos = net.ReadVector()
		local angle = net.ReadAngle()
		ParticleEffectLit(name, pos, angle)
	end)
end

local ISPATCHING = false

hook.Add("EntityFireBullets", "InsImpacts", function(ent, data, ...)
	local bak = table.Copy(data)
	if ISPATCHING then return end
	ISPATCHING = true
	local call = hook.Run("EntityFireBullets", ent, data, ...)
	ISPATCHING = false

	if call == false then
		return false
	elseif call == nil then
		table.Empty(data)
		table.CopyFromTo(bak, data)
	end

	local cbold = data.Callback

	data.Callback = function(a, b, c, ...)
		if cbold then
			cbold(a, b, c)
		end
		if b.HitSky then return end

		local hitTex = string.lower(b.HitTexture or "")

		for k, v in pairs(Particles.List_Pre) do
			if string.find(hitTex, k) then
				local ang = b.HitNormal:Angle()
				ang:RotateAroundAxis(ang:Right(), -90)
				ParticleEffectLit(v, b.HitPos, ang, a)

				return
			end
		end

		for k, v in pairs(Particles.List) do
			if string.find(hitTex, k) then
				local ang = b.HitNormal:Angle()
				ang:RotateAroundAxis(ang:Right(), -90)
				ParticleEffectLit(v, b.HitPos, ang, a)

				return
			end
		end

		for k, v in pairs(Particles.List_Post) do
			if string.find(hitTex, k) then
				local ang = b.HitNormal:Angle()
				ang:RotateAroundAxis(ang:Right(), -90)
				ParticleEffectLit(v, b.HitPos, ang, a)

				return
			end
		end

		local partName = Particles.List_Mats[b.MatType or MAT_DEFAULT] or Particles.List_Mats[MAT_DEFAULT]
		if not partName then return end
		local ang = b.HitNormal:Angle()
		ang:RotateAroundAxis(ang:Right(), -90)
		ParticleEffectLit(partName, b.HitPos, ang, a)
	end

	return true
end)