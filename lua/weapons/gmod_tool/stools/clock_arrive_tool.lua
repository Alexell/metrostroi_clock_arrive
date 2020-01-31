TOOL.Category		= "Metro"
TOOL.Name			= "Clock Arrive Tool"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add("Tool.clock_arrive_tool.name", "Clock Arrive Tool")
    language.Add("Tool.clock_arrive_tool.desc", "Adds arrival clocks")
    language.Add("Tool.clock_arrive_tool.0", "Primary: Spawn arrival clock. Secondary: Remove arrival clock.")
    language.Add("Undone_clock_arrive_tool", "Undone arrival clock")
end

function TOOL:LeftClick(trace)
	if SERVER then return end
	if self.LastUse and CurTime() - self.LastUse < 1 then return end
	self.LastUse = CurTime()
	local ply = self:GetOwner()
	if LocalPlayer() ~= ply then return false end
	if not ply:IsValid() or not ply:IsAdmin() then return false end
	if not trace then return false end
	if trace.Entity and trace.Entity:IsPlayer() then return false end

	local vec = trace.HitPos
	if not vec then return false end
	local ang = trace.HitNormal:Angle()
	ang:RotateAroundAxis(ang:Up(),-90)
	local station = GetConVar("clock_arrive_st"):GetString()
	local path = GetConVar("clock_arrive_path"):GetString()
	local dest = GetConVar("clock_arrive_dest"):GetString()

	net.Start("SpawnClockArrive")
		net.WriteVector(vec)
		net.WriteAngle(ang)
		net.WriteString(station)
		net.WriteString(path)
		net.WriteString(dest)
	net.SendToServer()
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return end
	
    local ply = self:GetOwner()
    if not ply:IsValid() or not ply:IsAdmin() then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end
	if not trace.HitPos then return false end
	local entlist = ents.FindInSphere(trace.HitPos,10) or {}
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_clock_arrive" then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
    end
    return true
end

-- TODO: Update entity data on Reload

function TOOL.BuildCPanel(panel)
	panel:AddControl("textbox",{ 
		Label = "ID станции", 
		Command = "clock_arrive_st"
	})
	
	panel:AddControl("textbox",{ 
		Label = "Путь", 
		Command = "clock_arrive_path"
	})
	panel:AddControl("textbox",{ 
		Label = "Направление",
		Command = "clock_arrive_dest"
	})
	panel:AddControl("button",{ 
		Label = "Сохранить часы", 
		Command = "clocks_arrive_save"
	})
	
	panel:AddControl("button",{ 
		Label = "Загрузить часы", 
		Command = "clocks_arrive_load"
	})
end