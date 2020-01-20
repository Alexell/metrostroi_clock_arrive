AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local function FindPlatform(st,path)
	for k,v in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(v) then continue end
		if v.StationIndex == st and v.PlatformIndex == path then return v end
	end
end

function ENT:Initialize()
	self:SetModel("models/metrostroi/clock_interval_moscow.mdl")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self.Station = self:GetNW2Int("Station",0)
	self.Path = self:GetNW2Int("Path",0)
	self.Platform = FindPlatform(self.Station,self.Path)
end

function ENT:Think()
if self.Station == 151 and self.Path == 1 then
	if IsValid(self.Platform) then
		if IsValid(self.Platform.CurrentTrain) then
			local train = self.Platform.CurrentTrain
			self:SetTrain(true)
			if train.Speed < 1 then
				self:SetTrainStopped(true)
			else
				self:SetTrainStopped(false)
			end
		else
			self:SetTrain(false)
			self:SetTrainStopped(false)
		end
	else
		self.Platform = FindPlatform(self.Station,self.Path)
	end
	self:NextThink(CurTime()+1)
	return true
end
end
