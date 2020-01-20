TOOL.Category		= "Metro"
TOOL.Name			= "Clock Arrive Tool"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add("Tool.clock_arrive_tool.name", "Clock Arrive Tool")
    language.Add("Tool.clock_arrive_tool.desc", "Creating clocks arrive")
    language.Add("Tool.clock_arrive_tool.0", "Primary: Spawn clock arrive entity\nSecondary: Remove clock arrive")
    language.Add("Undone_clock_arrive_tool", "Undone clock arrive")
end

function TOOL:LeftClick(trace)
	if SERVER then return end
	if self.LastUse and CurTime() - self.LastUse < 1 then return end
	self.LastUse = CurTime()
	local ply = self:GetOwner()
	if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
	if not trace then return false end
	if trace.Entity and trace.Entity:IsPlayer() then return false end

	local vec = trace.HitPos
	local ang = trace.HitNormal:Angle()
	local station = GetConVar("clock_arrive_st"):GetString()
	local path = GetConVar("clock_arrive_path"):GetString()
	local nxt = GetConVar("clock_arrive_next"):GetString()

	net.Start("SpawnClockArrive")
		net.WriteVector(vec)
		net.WriteAngle(ang)
		net.WriteString(station)
		net.WriteString(path)
		net.WriteString(nxt)
	net.SendToServer()
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return end
	
    local ply = self:GetOwner()
    if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end
	
	local entlist = ents.FindInSphere(trace.HitPos,10) or {}
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_clock_arrive" then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
    end
    return true
end

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
		Label = "След. станция",
		Command = "clock_arrive_next"
	})
	panel:AddControl("button",{ 
		Label = "Сохранить часы", 
		Command = "clocks_arrive_save"
	})
	
	panel:AddControl("button",{ 
		Label = "Загрузить часы", 
		Command = "clocks_arrive_load" -- создать конкомманду в авторане
	})
end