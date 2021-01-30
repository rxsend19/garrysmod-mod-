
if SERVER then

	util.AddNetworkString("ragdeath_client")
	util.AddNetworkString("ragdeath_getcreationid")
	util.AddNetworkString("ragdeath_createragdoll")
	util.AddNetworkString("ragdeath_checkragdoll")
	util.AddNetworkString("ragdeath_removeragdoll")
	util.AddNetworkString("ragdeath_entitytakedmg")
	--util.AddNetworkString("ragdeath_setnodraw")
end

local PlayerEnabledVar = CreateConVar("ragDeath_enabled_players", 1, FCVAR_ARCHIVE)
local NPCEnabledVar = CreateConVar("ragDeath_enabled_npcs", 1, FCVAR_ARCHIVE)
local IgnitionTimeVar = CreateConVar("ragDeath_ignitionTime", 10, FCVAR_ARCHIVE)
local OwnRagVar = CreateConVar("ragDeath_playersOwn", 1, FCVAR_ARCHIVE)
local CollideRagVar = CreateConVar("ragDeath_playerCollide", 0, FCVAR_ARCHIVE)
local RemoveRagVar = CreateConVar("ragDeath_removeOnDisconnect", 0, FCVAR_ARCHIVE)
local MaxDRagsVar = CreateConVar("ragDeath_keepMax", "5", FCVAR_ARCHIVE)
local TimeRemovePlayerVar = CreateConVar("ragDeath_timeRemove_player", "60", FCVAR_ARCHIVE)
local TimeRemoveNPCVar = CreateConVar("ragDeath_timeRemove_npc", "60", FCVAR_ARCHIVE)

CreateConVar("ragDeath_gamemodeOverride", 1, FCVAR_ARCHIVE)

local function IsValidEnt(entity)
	if (isentity(entity) and isfunction(entity.IsValid) and entity:IsValid()) then
		return true
	end
	
	return false
end

local function RagDeath_Enabled(entity)
	if IsValidEnt(entity) then
		if entity:IsPlayer() then
			return PlayerEnabledVar:GetBool()
		else
			return NPCEnabledVar:GetBool()
		end
	end
	
	return false
end

local RagdollEventName = "CreateEntityRagdoll"
local CSRagdollEventName = "CreateClientsideRagdoll"

local RagdollHooks = {}
local CSRagdollHooks = {}

local Hook_Add_Old = hook.Add
local Hook_Add = Hook_Add_Old

hook.Add = function(eventName, identifier, func, ...)
	if (eventName == RagdollEventName) then
		RagdollHooks[identifier] = func
		
		return
	end
	
	if (eventName == CSRagdollEventName) then
		CSRagdollHooks[identifier] = func
		
		return
	end
	
	return Hook_Add(eventName, identifier, func, ...)
end

local Hook_Remove_Old = hook.Remove
local Hook_Remove = Hook_Remove_Old

hook.Remove = function(eventName, identifier, ...)
	if (eventName == RagdollEventName) then
		RagdollHooks[identifier] = nil
		
		return
	end
	
	if (eventName == CSRagdollEventName) then
		CSRagdollHooks[identifier] = nil
		
		return
	end
	
	return Hook_Remove(eventName, identifier, ...)
end

local HookTable = hook.GetTable()
local EventTable = HookTable[RagdollEventName]

if istable(EventTable) then
	local itemsToDelete = {}
	
	for k, v in pairs(EventTable) do
		RagdollHooks[k] = v
		itemsToDelete[k] = true
	end
	
	for k, v in pairs(itemsToDelete) do
		Hook_Remove(RagdollEventName, k)
		
		local currHook = EventTable[k]
		
		if (currHook or isbool(currHook)) then
			RagdollHooks[k] = nil
		end
	end
end

local CSEventTable = HookTable[CSRagdollEventName]

if istable(CSEventTable) then
	local itemsToDelete = {}
	
	for k, v in pairs(CSEventTable) do
		CSRagdollHooks[k] = v
		itemsToDelete[k] = true
	end
	
	for k, v in pairs(itemsToDelete) do
		Hook_Remove(CSRagdollEventName, k)
		
		local currHook = CSEventTable[k]
		
		if (currHook or isbool(currHook)) then
			CSRagdollHooks[k] = nil
		end
	end
end

local CreateEntityRagdoll = function()
end

local CreateClientsideRagdoll = function()
end

local function CallRagdollHooks(...)
	for k, v in pairs(RagdollHooks) do
		if (v != CreateEntityRagdoll) then
			v(...)
		end
	end
end

local function CallCSRagdollHooks(...)
	for k, v in pairs(CSRagdollHooks) do
		if (v != CreateClientsideRagdoll) then
			v(...)
		end
	end
end

local NetTypeWhitelist = {
	[TYPE_BOOL] = true,
	[TYPE_NUMBER] = true,
	[TYPE_STRING] = true,
	[TYPE_ENTITY] = true,
	[TYPE_VECTOR] = true,
	[TYPE_ANGLE] = true,
	[TYPE_COLOR] = true
}

local TypeID_Old = TypeID

local TypeID = function(value, ...)
	if IsColor(value) then
		return TYPE_COLOR
	end
	
	return TypeID_Old(value)
end

local EntityRagdolls
local PlayerRagdolls
local NotRespawned
local PendingDamage

if SERVER then
	EntityRagdolls = {}
	PlayerRagdolls = {}
	NotRespawned = {}
	PendingDamage = {}
end

local DamageInfoGetFuncs = {
	AmmoType = function(dmgInfo)
		return dmgInfo:GetAmmoType()
	end,
	Attacker = function(dmgInfo)
		return dmgInfo:GetAttacker()
	end,
	Damage = function(dmgInfo)
		return dmgInfo:GetDamage()
	end,
	DamageBonus = function(dmgInfo)
		return dmgInfo:GetDamageBonus()
	end,
	DamageCustom = function(dmgInfo)
		return dmgInfo:GetDamageCustom()
	end,
	DamageForce = function(dmgInfo)
		return dmgInfo:GetDamageForce()
	end,
	DamagePosition = function(dmgInfo)
		return dmgInfo:GetDamagePosition()
	end,
	DamageType = function(dmgInfo)
		return dmgInfo:GetDamageType()
	end,
	Inflictor = function(dmgInfo)
		return dmgInfo:GetInflictor()
	end,
	MaxDamage = function(dmgInfo)
		return dmgInfo:GetMaxDamage()
	end,
	ReportedPosition = function(dmgInfo)
		return dmgInfo:GetReportedPosition()
	end
}

local DamageInfoSetFuncs = {
	AmmoType = function(dmgInfo, value)
		dmgInfo:SetAmmoType(value)
	end,
	Attacker = function(dmgInfo, value)
		if (not (value:IsValid() or value:IsWorld())) then return end
		
		dmgInfo:SetAttacker(value)
	end,
	Damage = function(dmgInfo, value)
		dmgInfo:SetDamage(value)
	end,
	DamageBonus = function(dmgInfo, value)
		dmgInfo:SetDamageBonus(value)
	end,
	DamageCustom = function(dmgInfo, value)
		dmgInfo:SetDamageCustom(value)
	end,
	DamageForce = function(dmgInfo, value)
		dmgInfo:SetDamageForce(value)
	end,
	DamagePosition = function(dmgInfo, value)
		dmgInfo:SetDamagePosition(value)
	end,
	DamageType = function(dmgInfo, value)
		dmgInfo:SetDamageType(value)
	end,
	Inflictor = function(dmgInfo, value)
		if (not (value:IsValid() or value:IsWorld())) then return end
		
		dmgInfo:SetInflictor(value)
	end,
	MaxDamage = function(dmgInfo, value)
		dmgInfo:SetMaxDamage(value)
	end,
	ReportedPosition = function(dmgInfo, value)
		dmgInfo:SetReportedPosition(value)
	end
}

local DamageInfoDefaults = {
	DamageType = DMG_GENERIC
}

local function DamageInfoToTable(dmgInfo)
	local newTab = {}
	
	for k, v in pairs(DamageInfoGetFuncs) do
		newTab[k] = v(dmgInfo)
	end
	
	return newTab
end

local function TableToDamageInfo(dmgTab)
	local dmgInfo = DamageInfo()
	
	for k, v in pairs(DamageInfoSetFuncs) do
		local currValue = dmgTab[k]
		
		if (currValue or isbool(currValue)) then
			v(dmgInfo, currValue)
		else
			currValue = DamageInfoDefaults[k]
			
			if (currValue or isbool(currValue)) then
				v(dmgInfo, currValue)
			end
		end
	end
	
	return dmgInfo
end

--[[
local NoForceDmgTypeList = {
	DMG_BURN,
	DMG_FALL,
	DMG_SHOCK,
	DMG_SONIC,
	DMG_ENERGYBEAM,
	DMG_PREVENT_PHYSICS_FORCE,
	DMG_NEVERGIB,
	DMG_ALWAYSGIB,
	DMG_DROWN,
	DMG_PARALYZE,
	DMG_NERVEGAS,
	DMG_POISON,
	DMG_RADIATION,
	DMG_DROWNRECOVER,
	DMG_ACID,
	DMG_SLOWBURN,
	DMG_REMOVENORAGDOLL,
	DMG_DISSOLVE,
	DMG_DIRECT
}

local NoForceDmgType = 0

for k, v in pairs(NoForceDmgTypeList) do
	NoForceDmgType = bit.bor(NoForceDmgType, v)
end
]]

--[[
local function SetEntNoDraw(entity, shouldNotDraw)
	if (not entity:IsValid()) then return end
	
	if (not SERVER) then
		entity:SetNoDraw(shouldNotDraw)
	end
	
	net.Start("ragdeath_setnodraw")
	net.WriteEntity(entity)
	net.WriteBool(shouldNotDraw)
	
	if SERVER then
		net.Broadcast()
	else
		net.SendToServer()
	end
end

local function ReceiveNoDraw(length, ply)
	local entity = net.ReadEntity()
	local shouldNotDraw = net.ReadBool()
	
	if (not SERVER) then
		if entity:IsValid() then
			entity:SetNoDraw(shouldNotDraw)
		else
			PendingNoDrawEnts[entity] = {shouldNotDraw}
		end
	elseif ply:IsValid() then
		net.Start("ragdeath_setnodraw")
		net.WriteEntity(entity)
		net.WriteBool(shouldNotDraw)
		
		if ply:IsValid() then
			net.SendOmit(ply)
		else
			net.Broadcast()
		end
	end
end

net.Receive("ragdeath_setnodraw", ReceiveNoDraw)
]]

local function EnableEntityCollision(entity, enable)
	if (not entity:GetPhysicsObject():IsValid()) then return end
	
	local physCount = entity:GetPhysicsObjectCount()
	
	if (physCount <= 1) then
		entity:GetPhysicsObject():EnableCollisions(enable)
	else
		for index = 0, (physCount - 1) do
			local PhysBone = entity:GetPhysicsObjectNum(index)
			
			if PhysBone:IsValid() then
				PhysBone:EnableCollisions(enable)
			end
		end
	end
end

local function GetPhysBoneProperties(ragdoll, noVelocities)
	local boneProperties = {}
	
	local physCount = ragdoll:GetPhysicsObjectCount()
	
	for index = 0, (physCount - 1) do
		local PhysBone = ragdoll:GetPhysicsObjectNum(index)
		
		if PhysBone:IsValid() then
			local boneID = ragdoll:TranslatePhysBoneToBone(index)
			
			if (boneID and (boneID >= 0)) then
				local boneTab = {}
				
				boneTab.Pos = PhysBone:GetPos()
				boneTab.Angles = PhysBone:GetAngles()
				
				if (not noVelocities) then
					boneTab.Velocity = PhysBone:GetVelocity()
					boneTab.AngleVelocity = PhysBone:GetAngleVelocity()
				end
				
				boneProperties[boneID] = boneTab
			end
		end
	end
	
	return boneProperties
end

local function ConfigureRagdollBones(ragdoll, boneProperties, entity, useEntVelocities)
	local boneProperties = boneProperties
	
	if (not boneProperties) then
		boneProperties = {}
	end
	
	local entIsValid
	
	if (entity and entity:IsValid()) then
		entIsValid = true
	else
		entIsValid = false
	end
	
	local entVel
	
	if entIsValid then
		entVel = entity:GetVelocity()
		
		ragdoll:SetPos(entity:GetPos())
		ragdoll:SetAngles(entity:GetAngles())
	else
		entVel = Vector(0, 0, 0)
	end
	
	local physCount = ragdoll:GetPhysicsObjectCount()
	
	for index = 0, (physCount - 1) do
		local PhysBone = ragdoll:GetPhysicsObjectNum(index)
		
		if PhysBone:IsValid() then
			local boneID = ragdoll:TranslatePhysBoneToBone(index)
			
			if (boneID and (boneID >= 0)) then
				local boneTab = boneProperties[boneID]
				
				if boneTab then
					if (boneTab.Pos and boneTab.Angles) then
						PhysBone:SetPos(boneTab.Pos)
						PhysBone:SetAngles(boneTab.Angles)
					end
					
					if ((not useEntVelocities) and boneTab.Velocity and boneTab.AngleVelocity) then
						PhysBone:SetVelocity(boneTab.Velocity)
						PhysBone:AddAngleVelocity(boneTab.AngleVelocity - PhysBone:GetAngleVelocity())
					elseif entIsValid then
						PhysBone:SetVelocity(entVel)
						PhysBone:AddAngleVelocity(-PhysBone:GetAngleVelocity())
					end
				elseif entIsValid then
					local Pos, Angles = entity:GetBonePosition(boneID)
					
					if (Pos and Angles) then
						PhysBone:SetPos(Pos)
						PhysBone:SetAngles(Angles)
					end
					
					if useEntVelocities then
						PhysBone:SetVelocity(entVel)
						PhysBone:AddAngleVelocity(-PhysBone:GetAngleVelocity())
					end
				end
			elseif useEntVelocities then
				PhysBone:SetVelocity(entVel)
				PhysBone:AddAngleVelocity(-PhysBone:GetAngleVelocity())
			end
		end
	end
end

local function SetRagdollVelocity(ragdoll, velocity)
	local physCount = ragdoll:GetPhysicsObjectCount()
	
	for index = 0, (physCount - 1) do
		local PhysBone = ragdoll:GetPhysicsObjectNum(index)
		
		if PhysBone:IsValid() then
			PhysBone:SetVelocity(velocity)
			PhysBone:AddAngleVelocity(-PhysBone:GetAngleVelocity())
		end
	end
end

--[[
local function RagdollCoroutine(self, parent)
	if (not SERVER) then return end
	
	while true do
		if (not self:IsValid()) then return end
		if (not self.RagDeath_ParentAlive) then return end
		
		if parent:IsValid() then
			local proceed
			
			if parent:IsPlayer() then
				if parent:Alive() then
					proceed = true
				else
					proceed = false
				end
			elseif parent:IsNPC() then
				if (parent:GetNPCState() != NPC_STATE_DEAD) then
					proceed = true
				else
					proceed = false
				end
			else
				proceed = false
			end
			
			if proceed then
				ConfigureRagdollBones(self, parent)
			else
				self.RagDeath_ParentAlive = false
			end
		else
			self.RagDeath_ParentAlive = false
		end
		
		if (not self.RagDeath_ParentAlive) then
			if self.RagDeath_PendingDamage then
				self:TakeDamageInfo(self.RagDeath_PendingDamage)
			end
			
			SetEntNoDraw(self, false)
			
			return
		end
		
		local deltaTime = 2 * ServerThinkInterval
		
		coroutine.wait(deltaTime)
	end
end
]]

local function GetEntityBodyGroups(entity)
	local bodyGroups = entity:GetBodyGroups()
	local newTable = {}
	
	for k, v in pairs(bodyGroups) do
		if (istable(v) and v.id) then
			local id = v.id
			local value = entity:GetBodygroup(id)
			
			newTable[id] = value
		end
	end
	
	return newTable
end

local function CreateRagdoll(entity, model, skin, bodyGroups, boneProperties, noEntVelocities)
	local model = model
	local boneProperties = boneProperties
	local skin = skin
	local bodyGroups = bodyGroups
	
	if (not (model and boneProperties)) then
		model = entity:GetModel()
		boneProperties = {}
	end
	
	if (not skin) then
		skin = entity:GetSkin()
	end
	
	if (not bodyGroups) then
		bodyGroups = {}
	end
	
	local ragdoll = ents.Create("prop_ragdoll")
	
	ragdoll:SetModel(model)
	ragdoll:SetPos(entity:GetPos())
	ragdoll:SetNoDraw(true)
	
	ragdoll:Spawn()
	
	if (not ragdoll:IsValid()) then
		return ragdoll
	end
	
	local collisionGroup
	
	if (not CollideRagVar:GetBool()) then
		collisionGroup = COLLISION_GROUP_WEAPON
	else
		collisionGroup = COLLISION_GROUP_NONE
	end
	
	ragdoll:SetCollisionGroup(collisionGroup)
	
	local entBodyGroups = entity:GetBodyGroups()
	local newBodyGroups = {}
	
	for k, v in pairs(bodyGroups) do
		newBodyGroups[k] = v
	end
	
	if istable(entBodyGroups) then
		for k, v in pairs(entBodyGroups) do
			local id = v.id
			
			if (not newBodyGroups[id]) then
				newBodyGroups[id] = entity:GetBodygroup(id)
			end
		end
	end
	
	for k, v in pairs(newBodyGroups) do
		ragdoll:SetBodygroup(k, v)
	end
	
	ragdoll:SetSkin(skin)
	
	ragdoll:SetColor(entity:GetColor())
	
	ragdoll.RagDeath_RagdollOwner = entity
	ragdoll.RagDeath_RagdollModel = model
	
	ragdoll:SetNWBool("IsRagDeath", true)
	ragdoll:SetNWEntity("RagDeath_RagdollOwner", entity)
	
	ragdoll.GetRagdollOwner = function(self)
		return self:GetNWEntity("RagDeath_RagdollOwner", NULL)
	end
	
	ragdoll.CanConstrain = true
	ragdoll.GravGunPunt = true
	ragdoll.PhysgunDisabled = false
	
	ConfigureRagdollBones(ragdoll, boneProperties, entity, (not noEntVelocities))
	
	local entIsPlayer = entity:IsPlayer()
	
	if entIsPlayer then
		entity:SetNWEntity("RagDeath_RagdollEntity", ragdoll)
		
		local PlayerColor = entity:GetPlayerColor()
		
		ragdoll:SetNWBool("RagDeath_IsPlayerRagdoll", true)
		ragdoll:SetNWVector("RagDeath_PlayerColor", PlayerColor)
		
		ragdoll.GetPlayerColor = function(self)
			return self:GetNWVector("RagDeath_PlayerColor", Vector(1, 1, 1))
		end
		
		ragdoll.SetPlayerColor = function(self, newColor)
			self:SetNWVector("RagDeath_PlayerColor", newColor)
		end
		
		local ownsRagdoll = OwnRagVar:GetBool()
		local creator = nil
		
		if ownsRagdoll then
			creator = entity
		end
		
		ragdoll:SetCreator(creator)
		
		if (CPPI and ownsRagdoll) then
			ragdoll:CPPISetOwner(entity)
		end
	end
	
	ragdoll:SetNoDraw(false)
	
	local timedgo
	
	if entIsPlayer then
		timedgo = TimeRemovePlayerVar:GetFloat()
	else
		timedgo = TimeRemoveNPCVar:GetFloat()
	end
	
	if (timedgo > 0) then
		timer.Simple(timedgo, function()
			if (ragdoll and ragdoll:IsValid()) then
				ragdoll:Remove()
			end
		end)
	end
	
	return ragdoll
end

local function RefreshPlayerRagdolls(ply)
	if (not PlayerRagdolls[ply]) then
		PlayerRagdolls[ply] = {}
	end
	
	local ragdollTable = PlayerRagdolls[ply]
	
	local maxRagdolls = MaxDRagsVar:GetInt()
	
	if (maxRagdolls >= 0) then
		local ragdollCount = #ragdollTable
		
		while (ragdollCount > maxRagdolls) do
			local currRagdoll = ragdollTable[1]
			
			if (currRagdoll and currRagdoll:IsValid()) then
				currRagdoll:Remove()
			end
			
			table.remove(ragdollTable, 1)
			
			ragdollCount = ragdollCount - 1
		end
	end
end

local function CreatePlayerRagdoll(ply, model, skin, bodyGroups, boneProperties, noEntVelocities)
	NotRespawned[ply] = true
	
	local ragdoll = CreateRagdoll(ply, model, skin, bodyGroups, boneProperties, noEntVelocities)
	
	RefreshPlayerRagdolls(ply)
	
	if (not ragdoll:IsValid()) then
		return ragdoll
	end
	
	local ragdollTable = PlayerRagdolls[ply]
	
	table.insert(ragdollTable, (#ragdollTable + 1), ragdoll)
	
	net.Start("ragdeath_client")
	
	net.WriteEntity(ply)
	net.WriteEntity(ragdoll)
	
	net.Send(ply)
	
	return ragdoll
end

local function RemovePlayerRagdolls(player)
	if (player == nil) then return end
	if (not (player == player)) then return end
	
	local ragdollTable = PlayerRagdolls[ply]
	
	if ragdollTable then
		for k, v in pairs(ragdollTable) do
			if (v and v:IsValid()) then
				v:Remove()
			end
		end
	end
end

local function EntityTakeDamage(entity, dmgInfo, resetData)
	if (not SERVER) then
		if (entity:EntIndex() >= 0) then
			net.Start("ragdeath_entitytakedmg")
			net.WriteEntity(entity)
			
			if resetData then
				net.WriteBool(true)
			else
				net.WriteBool(false)
			end
			
			net.SendToServer()
		end
		
		return
	end
	
	--[[
	local dmgType = dmgInfo:GetDamageType()
	
	if (bit.band(dmgType, DMG_PREVENT_PHYSICS_FORCE) >= DMG_PREVENT_PHYSICS_FORCE) then
		dmgInfo:SetDamageForce(Vector(0, 0, 0))
	end
	]]
	
	local proceed = false
	
	if entity:IsPlayer() then
		if PlayerEnabledVar:GetBool() then
			proceed = true
		end
	elseif entity:IsNPC() then
		if NPCEnabledVar:GetBool() then
			proceed = true
		end
	end
	
	if proceed then
		local newTab = PendingDamage[entity]
		
		if ((not newTab) or resetData) then
			newTab = {}
		end
		
		if dmgInfo then
			newTab.DmgInfo = DamageInfoToTable(dmgInfo)
		end
		
		newTab.IsOnFire = entity:IsOnFire()
		newTab.Velocity = entity:GetVelocity()
		
		PendingDamage[entity] = newTab
	end
end

net.Receive("ragdeath_entitytakedmg", function()
	local entity = net.ReadEntity()
	local resetData = net.ReadBool()
	
	if (not entity:IsValid()) then return end
	
	if SERVER then
		EntityTakeDamage(entity, nil, resetData)
	else
		net.Start("ragdeath_entitytakedmg")
		net.WriteEntity(entity)
		net.SendToServer()
	end
end)

local DissolvingEnts
local DissolveEntity

if SERVER then
	DissolvingEnts = {}

	DissolveEntity = function(entity, dissolveType, magnitude)
		if (not entity:IsValid()) then return end
		
		if (not dissolveType) then
			dissolveType = 0
		end
		
		if (not magnitude) then
			magnitude = 0
		end
		
		dissolver = ents.Create("env_entity_dissolver")
		
		dissolver:SetPos(entity:GetPos())
		dissolver:SetKeyValue("dissolvetype", dissolveType)
		dissolver:SetKeyValue("magnitude", magnitude)
		
		dissolver:Spawn()
		
		if (not dissolver:IsValid()) then return end
		
		local id = 1
		local foundID = false
		
		while (not foundID) do
			if DissolvingEnts[id] then
				id = id + 1
			else
				foundID = true
				DissolvingEnts[id] = entity
			end
		end
		
		local newName = "RagDeath_DissolvingEnt_" .. tostring(id)
		local prevName = entity:GetName()
		
		entity:SetName(newName)
		
		dissolver:Fire("Dissolve", newName, 0)
		dissolver:Fire("kill", "", 0.01)
	end
end

local RagdollsToRemove
local RemoveClientsideRagdoll

if (not SERVER) then
	RagdollsToRemove = {}
	
	RemoveClientsideRagdoll = function(ragdoll)
		if ragdoll:IsPlayer() then return end
		if (ragdoll:EntIndex() >= 0) then return end
		
		local id = 1
		local foundID = false
		
		while (not foundID) do
			local currValue = RagdollsToRemove[id]
			
			if (not currValue) then
				RagdollsToRemove[id] = ragdoll
				foundID = true
			elseif (not currValue:IsValid()) then
				RagdollsToRemove[id] = ragdoll
				foundID = true
			else
				id = id + 1
			end
		end
		
		net.Start("ragdeath_removeragdoll")
		net.WriteUInt(id, 32)
		net.SendToServer()
		
		return id
	end
end

net.Receive("ragdeath_removeragdoll", function(length, ply)
	local id = net.ReadUInt(32)
	
	if SERVER then
		if (not ply:IsValid()) then return end
		
		net.Start("ragdeath_removeragdoll")
		net.WriteUInt(id, 32)
		net.Send(ply)
	else
		local ragdoll = RagdollsToRemove[id]
		
		if (ragdoll and ragdoll:IsValid()) then
			ragdoll:Remove()
		else
			RagdollsToRemove[id] = nil
		end
	end
end)

local function OnRagdollCreated(entity, ragdoll, model, boneProperties, skin, bodyGroups)
	if (not entity:IsValid()) then
		return NULL
	end
	
	local ragdollValid = IsValidEnt(ragdoll)
	
	local boneProperties = boneProperties
	local model = model
	local skin = skin
	local bodyGroups = bodyGroups
	
	if ragdollValid then
		if (not model) then
			model = ragdoll:GetModel()
		end
		
		if (not boneProperties) then
			boneProperties = GetPhysBoneProperties(ragdoll)
		end
		
		if (not skin) then
			skin = ragdoll:GetSkin()
		end
		
		if (not bodyGroups) then
			bodyGroups = GetEntityBodyGroups(ragdoll)
		end
	else
		if (not model) then
			model = entity:GetModel()
		end
		
		if (not boneProperties) then
			boneProperties = {}
		end
		
		if (not skin) then
			skin = entity:GetSkin()
		end
		
		if (not bodyGroups) then
			bodyGroups = GetEntityBodyGroups(entity)
		end
	end
	
	local proceed = false
	local entIsPlayer
	
	if entity:IsPlayer() then
		entIsPlayer = true
		
		if PlayerEnabledVar:GetBool() then
			proceed = true
		end
	elseif entity:IsNPC() then
		entIsPlayer = false
		
		if NPCEnabledVar:GetBool() then
			proceed = true
		end
	else
		entIsPlayer = false
	end
	
	if proceed then
		proceed = false
		
		if SERVER then
			if (((not EntityRagdolls[entity]) or (not EntityRagdolls[entity][model])) and ((not ragdollValid) or (not ragdoll:IsPlayer()))) then
				proceed = true
			end
		else
			local isNetworked
			
			if ragdollValid then
				local velocity = entity:GetVelocity()
				
				local physCount = ragdoll:GetPhysicsObjectCount()
				
				for index = 0, (physCount - 1) do
					local PhysBone = ragdoll:GetPhysicsObjectNum(index)
					
					if PhysBone:IsValid() then
						PhysBone:EnableGravity(false)
						PhysBone:SetVelocity(velocity)
						PhysBone:AddAngleVelocity(-PhysBone:GetAngleVelocity())
					end
				end
				
				if (ragdoll:EntIndex() < 0) then
					isNetworked = false
					
					RemoveClientsideRagdoll(ragdoll)
				else
					isNetworked = true
				end
			else
				isNetworked = false
			end
			
			local newBoneProperties = {}
			local bonePropertiesCount = 0
			
			for k, v in pairs(boneProperties) do
				if isnumber(k) then
					local newTab = {}
					local tabCount = 0
					
					for i, j in pairs(v) do
						local iType = TypeID(i)
						local jType = TypeID(j)
						
						if (NetTypeWhitelist[iType] and NetTypeWhitelist[jType]) then
							newTab[i] = j
							tabCount = tabCount + 1
						end
					end
					
					newBoneProperties[k] = {tabCount, newTab}
					bonePropertiesCount = bonePropertiesCount + 1
				end
			end
			
			local newBodyGroups = {}
			local bodyGroupsCount = 0
			
			for k, v in pairs(bodyGroups) do
				if (isnumber(k) and isnumber(v)) then
					newBodyGroups[k] = v
					bodyGroupsCount = bodyGroupsCount + 1
				end
			end
			
			net.Start("ragdeath_createragdoll")
			net.WriteEntity(entity)
			net.WriteBool(isNetworked)
			
			if isNetworked then
				net.WriteEntity(ragdoll)
			end
			
			net.WriteString(model)
			net.WriteInt(bonePropertiesCount, 32)
			
			for k, v in pairs(newBoneProperties) do
				net.WriteInt(k, 32)
				net.WriteInt(v[1], 32)
				
				for i, j in pairs(v[2]) do
					net.WriteType(i)
					net.WriteType(j)
				end
			end
			
			net.WriteInt(skin, 32)
			net.WriteInt(bodyGroupsCount, 32)
			
			for k, v in pairs(newBodyGroups) do
				net.WriteInt(k, 32)
				net.WriteInt(v, 32)
			end
			
			net.SendToServer()
		end
		
		if proceed then
			local newRagdoll
			
			if entIsPlayer then
				newRagdoll = CreatePlayerRagdoll(entity, model, skin, bodyGroups, boneProperties, true)
			else
				newRagdoll = CreateRagdoll(entity, model, skin, bodyGroups, boneProperties, true)
			end
			
			if ragdollValid then
				ragdoll:Remove()
			end
			
			if newRagdoll:IsValid() then
				if (not EntityRagdolls[entity]) then
					EntityRagdolls[entity] = {}
				end
				
				if (not EntityRagdolls[entity][model]) then
					EntityRagdolls[entity][model] = true
				end
				
				local dmgTab = PendingDamage[entity]
				
				if dmgTab then
					local velocity = dmgTab.Velocity
					local isOnFire = dmgTab.IsOnFire
					local dmgInfoTab = dmgTab.DmgInfo
					
					if velocity then
						SetRagdollVelocity(newRagdoll, velocity)
					else
						SetRagdollVelocity(newRagdoll, entity:GetVelocity())
					end
					
					if isOnFire then
						local ignitionTime = IgnitionTimeVar:GetFloat()
						
						if (isnumber(ignitionTime) and (ignitionTime > 0)) then
							newRagdoll:Ignite(ignitionTime)
						end
					end
					
					if dmgInfoTab then
						local dmgInfo = TableToDamageInfo(dmgInfoTab)
						local dmgType = dmgInfoTab.DamageType
						
						if (not dmgType) then
							dmgType = dmgInfo:GetDamageType()
						end
						
						--[[
						local prevDmgType = dmgType + 0
						
						if ((dmgType > 0) and (bit.band(dmgType, NoForceDmgType) >= dmgType)) then
							dmgInfo:SetDamageForce(Vector(0, 0, 0))
							
							dmgType = bit.bor(dmgType, DMG_PREVENT_PHYSICS_FORCE)
							
							dmgInfo:SetDamageType(dmgType)
						end
						]]
						
						newRagdoll:TakeDamageInfo(dmgInfo)
						
						--[[
						if (dmgType != prevDmgType) then
							dmgInfo:SetDamageType(prevDmgType)
							
							dmgType = prevDmgType
						end
						]]
						
						if (bit.band(dmgType, DMG_DISSOLVE) >= DMG_DISSOLVE) then
							DissolveEntity(newRagdoll, 0, 0)
						end
					end
				else
					SetRagdollVelocity(newRagdoll, entity:GetVelocity())
				end
			end
			
			PendingDamage[entity] = nil
			
			return newRagdoll
		end
		
		return NULL
	end
end

CreateEntityRagdoll = function(entity, ragdoll, ...)
	if (IsValidEnt(entity) and RagDeath_Enabled(entity)) then
		local newRagdoll = OnRagdollCreated(entity, ragdoll)
		
		if newRagdoll:IsValid() then
			CallRagdollHooks(entity, newRagdoll, ...)
		end
		
		return
	end
	
	if (not IsValidEnt(ragdoll)) then return end
	
	CallRagdollHooks(entity, ragdoll, ...)
end

CreateClientsideRagdoll = function(entity, ragdoll, ...)
	CallCSRagdollHooks(entity, ragdoll, ...)
	
	if (not (IsValidEnt(entity) and RagDeath_Enabled(entity))) then return end
	
	OnRagdollCreated(entity, ragdoll)
end

local function NetworkEntityCreated(entity)
	if SERVER then return end
	
	if entity:GetNWBool("IsRagDeath", false) then
		entity.GetRagdollOwner = function(self)
			return self:GetNWEntity("RagDeath_RagdollOwner", NULL)
		end
		
		if entity:GetNWBool("RagDeath_IsPlayerRagdoll", false) then
			entity.GetPlayerColor = function(self)
				return self:GetNWVector("RagDeath_PlayerColor", Vector(1, 1, 1))
			end
			
			entity.SetPlayerColor = function(self, newColor)
				self:SetNWVector("RagDeath_PlayerColor", newColor)
			end
		end
	end
	
	--[[
	local NoDrawTab = PendingNoDrawEnts[entity]
	
	if istable(NoDrawTab) then
		if NoDrawTab[1] then
			entity:SetNoDraw(true)
		else
			entity:SetNoDraw(false)
		end
	end
	
	PendingNoDrawEnts[entity] = nil
	]]
end

if SERVER then
	net.Receive("ragdeath_createragdoll", function()
		local entity = net.ReadEntity()
		local ragdollValid = net.ReadBool()
		local ragdoll
		
		if ragdollValid then
			ragdoll = net.ReadEntity()
		else
			ragdoll = NULL
		end
		
		local model = net.ReadString()
		local bonePropertiesCount = net.ReadInt(32)
		
		local boneProperties = {}
		
		for h = 1, bonePropertiesCount do
			local k = net.ReadInt(32)
			local tabCount = net.ReadInt(32)
			
			local newTab = {}
			
			for l = 1, tabCount do
				local i = net.ReadType()
				local j = net.ReadType()
				
				newTab[i] = j
			end
			
			boneProperties[k] = newTab
		end
		
		local skin = net.ReadInt(32)
		local bodyGroupsCount = net.ReadInt(32)
		
		local bodyGroups = {}
		
		for i = 1, bodyGroupsCount do
			local k = net.ReadInt(32)
			local v = net.ReadInt(32)
			
			bodyGroups[k] = v
		end
		
		if entity:IsValid() then
			OnRagdollCreated(entity, ragdoll, model, boneProperties, skin, bodyGroups)
		end
	end)
end

local PLAYER_META = FindMetaTable("Player")

if PLAYER_META then
	local MetaCreateRagdoll_Old = PLAYER_META.CreateRagdoll
	local MetaCreateRagdoll = MetaCreateRagdoll_Old
	
	if isfunction(MetaCreateRagdoll) then
		PLAYER_META.CreateRagdoll = function(self, ...)
			if PlayerEnabledVar:GetBool() then
				return CreateEntityRagdoll(self)
			end
			
			return MetaCreateRagdoll(self, ...)
		end
	end
	
	local GetRagdollEntity_Old = PLAYER_META.GetRagdollEntity
	local GetRagdollEntity = GetRagdollEntity_Old
	
	if isfunction(GetRagdollEntity) then
		PLAYER_META.GetRagdollEntity = function(self, ...)
			if PlayerEnabledVar:GetBool() then
				return self:GetNWEntity("RagDeath_RagdollEntity", NULL)
			end
			
			return GetRagdollEntity(self, ...)
		end
	end
end

local function PlayerDeath(ply)
	EntityTakeDamage(ply)
end

local function OnNPCKilled(npc)
	EntityTakeDamage(npc)
end

local function PlayerSpawn(ply, isThink)
	if (not isThink) then
		NotRespawned[ply] = nil
		PendingDamage[ply] = nil
		EntityRagdolls[ply] = nil
	end
	
	RefreshPlayerRagdolls(ply)
end

local function PlayerDisconnected(ply)
	if RemoveRagVar:GetBool() then
		RemovePlayerRagdolls(ply)
	end
	
	PlayerRagdolls[ply] = nil
	NotRespawned[ply] = nil
end

local ENT_META = FindMetaTable("Entity")

if ENT_META then
	local EntSetHealth_Old = ENT_META.SetHealth
	local EntSetHealth = EntSetHealth_Old
	
	ENT_META.SetHealth = function(self, newHealth, ...)
		local proceed
		
		if self:IsPlayer() then
			if self:Alive() then
				proceed = true
			else
				proceed = false
			end
		elseif self:IsNPC() then
			if (self:GetNPCState() != NPC_STATE_DEAD) then
				proceed = true
			else
				proceed = false
			end
		end
		
		if (tonumber(newHealth) <= 0) then
			EntityTakeDamage(self, nil, true)
		end
		
		return EntSetHealth(self, newHealth, ...)
	end
end

local NPC_META = FindMetaTable("NPC")

if NPC_META then
	local NPCSetState_Old = NPC_META.SetNPCState
	local NPCSetState = NPCSetState_Old
	
	NPC_META.SetNPCState = function(self, newState, ...)
		if (tonumber(newState) == NPC_STATE_DEAD) then
			EntityTakeDamage(self, nil, true)
		end
		
		return NPCSetState(self, newState, ...)
	end
end

local function EntityRemoved(entity)
	if (not SERVER) then return end
	
	PendingDamage[entity] = nil
	
	if EntityRagdolls[entity] then
		EntityRagdolls[entity] = nil
	end
	
	local ragdollOwner = entity.RagDeath_RagdollOwner
	
	if ragdollOwner then
		if ragdollOwner:IsValid() then
			if EntityRagdolls[ragdollOwner] then
				if (not ragdollOwner:IsValid()) then
					EntityRagdolls[ragdollOwner] = nil
				end
			end
		end
	end
end

local function Think()
	if (not SERVER) then
		local itemsToDelete = {}
		
		for k, v in pairs(RagdollsToRemove) do
			if (not v:IsValid()) then
				itemsToDelete[k] = true
			end
		end
		
		for k, v in pairs(itemsToDelete) do
			RagdollsToRemove[k] = nil
		end
		
		return
	end
	
	local itemsToDelete = {}
	
	for k, v in pairs(NotRespawned) do
		if k:IsValid() then
			if k:Alive() then
				PlayerSpawn(k, true)
				itemsToDelete[k] = true
			end
		else
			itemsToDelete[k] = true
		end
	end
	
	for k, v in pairs(itemsToDelete) do
		NotRespawned[k] = nil
	end
	
	itemsToDelete = {}
	
	for k, v in pairs(EntityRagdolls) do
		if (not k:IsValid()) then
			itemsToDelete[k] = true
		elseif (k:IsPlayer() and k:Alive()) then
			itemsToDelete[k] = true
		end
	end
	
	for k, v in pairs(itemsToDelete) do
		EntityRagdolls[k] = nil
	end
	
	itemsToDelete = {}
	
	local shouldRemove = RemoveRagVar:GetBool()
	
	for k, v in pairs(PlayerRagdolls) do
		if (not k:IsValid()) then
			if shouldRemove then
				RemovePlayerRagdolls(k)
			end
			
			itemsToDelete[k] = true
		end
	end
	
	for k, v in pairs(itemsToDelete) do
		PlayerRagdolls[k] = nil
	end
	
	itemsToDelete = {}
	
	for k, v in pairs(PendingDamage) do
		if (not k:IsValid()) then
			itemsToDelete[k] = true
		end
	end
	
	for k, v in pairs(itemsToDelete) do
		PendingDamage[k] = nil
	end
	
	itemsToDelete = {}
	
	for k, v in pairs(DissolvingEnts) do
		if (not v:IsValid()) then
			itemsToDelete[k] = true
		end
	end
	
	for k, v in pairs(itemsToDelete) do
		DissolvingEnts[k] = nil
	end
end

Hook_Add(RagdollEventName, "RagDeath_CreateEntityRagdoll", CreateEntityRagdoll)
Hook_Add(CSRagdollEventName, "RagDeath_CreateClientsideRagdoll", CreateClientsideRagdoll)

if SERVER then
	hook.Add("EntityTakeDamage", "RagDeath_EntityTakeDamage", EntityTakeDamage)
	hook.Add("PlayerDeath", "RagDeath_PlayerDeath", PlayerDeath)
	hook.Add("PlayerSilentDeath", "RagDeath_PlayerDeath", PlayerDeath)
	hook.Add("OnNPCKilled", "RagDeath_OnNPCKilled", OnNPCKilled)
	hook.Add("PlayerSpawn", "RagDeath_PlayerSpawn", PlayerSpawn)
	hook.Add("PlayerDisconnected", "RagDeath_RemoveOnDisconnect", PlayerDisconnected)
	hook.Add("EntityRemoved", "RagDeath_EntityRemoved", EntityRemoved)
else
	hook.Add("NetworkEntityCreated", "RagDeath_SetNoDraw", NetworkEntityCreated)
end

hook.Add("Think", "RagDeath_Think", Think)
