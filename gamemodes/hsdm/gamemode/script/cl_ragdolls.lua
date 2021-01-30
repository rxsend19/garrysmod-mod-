
local FPRagVar = CreateClientConVar("ragDeath_firstPerson", 0, true, false)
local ZNearVar = CreateClientConVar("ragDeath_fp_zNear", "0.5", true, false)
local LookDistVar = CreateClientConVar("ragDeath_tp_lookDist", "120", true, false)
local CamPaddingVar = CreateClientConVar("ragDeath_tp_camCollisionPadding", "5", true, false)

local ViewEventName = "CalcView"

local CalcViewHooks = {}

local Hook_Add_Old = hook.Add
local Hook_Add = Hook_Add_Old

hook.Add = function(eventName, identifier, func, ...)
	if (eventName == ViewEventName) then
		CalcViewHooks[identifier] = func
		
		return
	end
	
	return Hook_Add(eventName, identifier, func, ...)
end

local Hook_Remove_Old = hook.Remove
local Hook_Remove = Hook_Remove_Old

hook.Remove = function(eventName, identifier, ...)
	if (eventName == ViewEventName) then
		CalcViewHooks[identifier] = nil
		
		return
	end
	
	return Hook_Remove(eventName, identifier, ...)
end

local HookTable = hook.GetTable()
local EventTable = HookTable[ViewEventName]

if istable(EventTable) then
	local itemsToDelete = {}
	
	for k, v in pairs(EventTable) do
		CalcViewHooks[k] = v
		itemsToDelete[k] = true
	end
	
	for k, v in pairs(itemsToDelete) do
		Hook_Remove(ViewEventName, k)
		
		local currHook = EventTable[k]
		
		if (currHook or isbool(currHook)) then
			CalcViewHooks[k] = nil
		end
	end
end

local CalcView_Hook = function()
end

local function CallCalcViewHook(ply, pos, angles, fov, znear, zfar, ...)
	local valueReturned = false
	local view = {}
	
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.znear = znear
	view.zfar = zfar
	
	for k, v in pairs(CalcViewHooks) do
		if (v != CalcView_Hook) then
			local result = v(ply, view.origin, view.angles, view.fov, view.znear, view.zfar, ...)
			
			if istable(result) then
				for k, v in pairs(result) do
					view[k] = v
				end
				
				valueReturned = true
			end
		end
	end
	
	if valueReturned then
		return view
	end
end

local LocalRagdoll = NULL
local LastView

local function CalcView(ply, pos, angles, fov, znear, zfar, ...)
	local view = {}
	local localPly = LocalPlayer()
	
	if localPly:Alive() then
		view.drawviewer = true
		view.origin = pos
		view.angles = angles
		view.fov = fov
		view.znear = znear
		view.zfar = zfar
		
		LastView = view
		
		return
	end
	
	local firstPerson = FPRagVar:GetBool()
	
	if (not LocalRagdoll:IsValid()) then
		if (firstPerson and LastView) then
			return LastView
		end
		
		return
	end
	
	local ent = localPly:GetViewEntity()
	
	if (ent != localPly) then
		return
	end
	
	view.drawviewer = false
	view.fov = fov
	view.zfar = zfar
	
	local thirdPerson = true
	local head
	
	if firstPerson then
		local attachment = LocalRagdoll:LookupAttachment("eyes")
		
		if (attachment <= 0) then
			attachment = LocalRagdoll:LookupAttachment("anim_attachment_head")
		end
		
		if (attachment > 0) then
			head = LocalRagdoll:GetAttachment(attachment)
			
			if head then
				thirdPerson = false
			end
		end
	elseif (not GetConVar("ragDeath_enabled_players"):GetBool()) then
		return
	end
	
	if thirdPerson then
		local normal = angles:Forward()
		local camPadding = CamPaddingVar:GetFloat()
		local lookDist = LookDistVar:GetFloat() + camPadding
		local origin
		local bone = LocalRagdoll:LookupBone("ValveBiped.Bip01_Spine")
		
		if bone then
			origin = LocalRagdoll:GetBonePosition(bone)
		else
			origin = LocalRagdoll:GetPos()
		end
		
		local tr = util.TraceLine({
			start = origin,
			endpos = origin - normal * lookDist,
			filter = {LocalRagdoll, localPly}
		})
		
		view.origin = origin - normal * (lookDist * tr.Fraction - camPadding)
		view.angles = angles
		view.znear = znear
	else
		view.origin = head.Pos
		view.angles = head.Ang
		
		local ZNearValue = ZNearVar:GetFloat()
		
		if (ZNearValue > 0) then
			view.znear = ZNearValue
		else
			view.znear = znear
		end
	end
	
	return view
end

local function Initialize()
	local calcViewFunc_Old = GAMEMODE.CalcView
	local calcViewFunc = calcViewFunc_Old
	
	if (not isfunction(calcViewFunc)) then return end
	
	GAMEMODE.CalcView = function(self, ply, pos, angles, fov, znear, zfar, ...)
		local ply = ply
		local pos = pos
		local angles = angles
		local fov = fov
		local znear = znear
		local zfar = zfar
		
		local origView = calcViewFunc(self, ply, pos, angles, fov, znear, zfar, ...)
		
		if (not GetConVar("ragDeath_gamemodeOverride"):GetBool()) then
			return origView
		end
		
		if (not (origView or isbool(origView))) then return end
		
		if istable(origView) then
			pos = origView.origin
			angles = origView.angles
			fov = origView.fov
			znear = origView.znear
			zfar = origView.zfar
		end
		
		local view = CalcView(ply, pos, angles, fov, znear, zfar, ...)
		
		if view then
			return view
		end
		
		return origView
	end
end

CalcView_Hook = function(ply, pos, angles, fov, znear, zfar, ...)
	local ply = ply
	local pos = pos
	local angles = angles
	local fov = fov
	local znear = znear
	local zfar = zfar
	
	local origView = CallCalcViewHook(ply, pos, angles, fov, znear, zfar, ...)
	
	if istable(origView) then
		pos = origView.origin
		angles = origView.angles
		fov = origView.fov
		znear = origView.znear
		zfar = origView.zfar
	end
	
	local view = CalcView(ply, pos, angles, fov, znear, zfar, ...)
	
	if view then
		return view
	end
	
	return origView
end

Hook_Add("Initialize", "RagDeath_PlayerCamera", Initialize)
Hook_Add(ViewEventName, "RagDeath_PlayerCamera", CalcView_Hook)

net.Receive("ragdeath_client", function()
	local ply = net.ReadEntity()
	local ragdoll = net.ReadEntity()
	
	if (ply:IsValid() and (ply == LocalPlayer())) then
		LocalRagdoll = ragdoll
	end
end)

--[[
function RagDeath_SetClientsideRagdoll(ply, ragdoll)
	if (ply == LocalPlayer()) then
		if (not ragdoll:IsValid()) then
			LocalRagdoll = NULL
			
			return
		end
		
		LocalRagdoll = ragdoll
	end
end
]]

local function Settings_Client(panel)
	panel:Help("First-Person Death sets whether to enable a first-person view of your death ragdoll before respawning.")
	panel:CheckBox("First-Person Death", "ragDeath_firstPerson")
	panel:Help("First-Person Settings:")
	panel:Help("Near Clipping Plane Distance sets the distance of the near clipping plane from the camera when in first-person. Set to 0 to use the setting for the normal first-person camera.")
	panel:NumSlider("Near Clipping\nPlane Distance", "ragDeath_fp_zNear", 0, 2, 6)
	panel:Help("Third-Person Settings:")
	panel:NumSlider("Look Distance", "ragDeath_tp_lookDist", 10, 400, 3)
	panel:Help("Camera Collision Padding sets the amount of extra distance between the third-person death camera and any surface it hits.")
	panel:NumSlider("Camera Collision\nPadding", "ragDeath_tp_camCollisionPadding", 0, 15, 4)
end

local function Settings_Server(panel)
	panel:CheckBox("Enabled for Players", "ragDeath_enabled_players")
	panel:CheckBox("Enabled for NPCs", "ragDeath_enabled_npcs")
	panel:Help("Gamemode Override sets whether the death view overrides the original death view for the gamemode (if one exists).")
	panel:CheckBox("Gamemode Override", "ragDeath_gamemodeOverride")
	panel:CheckBox("Players Own Ragdolls", "ragDeath_playersOwn")
	panel:Help("Ragdoll Ignition Time sets the amount of time in seconds that a death ragdoll will be on fire if the player/NPC dies while on fire.")
	panel:NumSlider("Ragdoll Ignition Time", "ragDeath_ignitionTime", 0, 120, 3)
	panel:CheckBox("Ragdolls Collide\nwith Players", "ragDeath_playerCollide")
	panel:CheckBox("Remove Ragdolls\non Disconnect", "ragDeath_removeOnDisconnect")
	panel:NumSlider("Player Ragdoll\nRemove Time", "ragDeath_timeRemove_player", 0, 300, 3)
	panel:NumSlider("NPC Ragdoll\nRemove Time", "ragDeath_timeRemove_npc", 0, 300, 3)
	panel:Help("Set \"Player Ragdoll Remove Time\" or \"NPC Ragdoll Remove Time\" to 0 to keep ragdolls indefinitely.")
	panel:NumSlider("Max Ragdolls\n(Per Player)", "ragDeath_keepMax", -1, 20, 0)
	panel:Help("Set \"Max Ragdolls (Per Player)\" to -1 to keep all player ragdolls until the specified remove time.")
end

local function RagDeath_Menu()
	spawnmenu.AddToolMenuOption("Options", "Ragdoll Death", "RagDeath_Client", "Client Settings", "", "", Settings_Client)
	spawnmenu.AddToolMenuOption("Options", "Ragdoll Death", "RagDeath_Server", "Server Settings", "", "", Settings_Server)
end

hook.Add("PopulateToolMenu", "RagDeath_Menu", RagDeath_Menu)
