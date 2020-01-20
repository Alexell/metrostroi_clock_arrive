ENT.Type            = "anim"
ENT.Category		= "Metrostroi (utility)"
ENT.Spawnable       = true
ENT.AdminSpawnable  = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"Train")
	self:NetworkVar("Bool",0,"TrainStopped")
end