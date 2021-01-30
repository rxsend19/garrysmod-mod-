--ORIGINAL ADDON: https://steamcommunity.com/sharedfiles/filedetails/?id=2352255828
if SERVER then AddCSLuaFile() end

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"


function ENT:ChasePos()
  if self.PosGen == nil then return end

  --if self.P == nil then 
    self.P = Path("Follow")
    self.P:SetMinLookAheadDistance(00)
    self.P:SetGoalTolerance(100)
    self.P:Compute(self, self.PosGen)
  --end
  if !self.P:IsValid() then return end

  if self.P:GetAge() > 0.05 then
    self.P:Compute(self, self.PosGen)
  end
  self:MoveToPos( self.PosGen )
end

function ENT:HandleStuck()
  self.loco:ClearStuck()
end

function ENT:SetTar(tar)
   self.PosGen = tar
end

function ENT:RunBehaviour()
  while (true) do
  self.loco:SetDesiredSpeed( 100 )
  self:SetTar(Entity(1):GetPos())
  self:ChasePos()
		
  coroutine.yield()
  end
end

function ENT:Initialize()
  self:SetModel("models/props_lab/huladoll.mdl")
  self:SetNoDraw(false)
  self:DrawShadow(false)
  self:SetSolid(SOLID_NONE)
  self.PosGen = nil
end
