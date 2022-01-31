if CLIENT then
	local Station = CreateClientConVar("clock_arrive_st","0",false)
	local Path = CreateClientConVar("clock_arrive_path","0",false)
	local Line = CreateClientConVar("clock_arrive_line",1,false)
	local Line_R = CreateClientConVar("clock_arrive_line_r",128,false)
	local Line_G = CreateClientConVar("clock_arrive_line_g",128,false)
	local Line_B = CreateClientConVar("clock_arrive_line_b",128,false)
	local Next = CreateClientConVar("clock_arrive_dest","Не указано",false)
	
	hook.Add("InitPostEntity","ClocksArriveNeedUpdate", function()
		timer.Simple(5,function()
			if (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then
				chat.AddText(Color(100,100,255),"Уважаемый администратор сервера!",Color(255,255,255),"\n\nАддон Metrostroi Clock Arrive",Color(255,0,0)," устарел. ",Color(255,255,255),"Пожалуйста замените его на новую версию:\nhttps://steamcommunity.com/sharedfiles/filedetails/?id=2579263629")
			end
			hook.Remove("InitPostEntity","ClocksArriveNeedUpdate")
		end)
	end)
else
	TrainsArrive = TrainsArrive or {}
	util.AddNetworkString("SpawnClockArrive")

	local function SpawnClockArrive(ply,vec,ang,station,path,dest,line,color)
		local ex_vec
		local ex_ang
		if IsValid(ply) then
			local entlist = ents.FindInSphere(vec,10) or {}
			for k,v in pairs(entlist) do
				if v:GetClass() == "gmod_track_clock_arrive" then
					if IsValid(v) then
						ex_vec = v:GetPos()
						ex_ang = v:GetAngles()
						SafeRemoveEntity(v) 
					end
				end
			end
		end
		local ent = ents.Create("gmod_track_clock_arrive")
		ent:SetPos(ex_vec or vec)
		local angle = ex_ang or ang
		ent:SetAngles(angle)
		if IsValid(ply) and not ex_vec then ent:SetPos(ent:LocalToWorld(Vector(-5,0,-20))) end -- смещение только при спавне игроком
		ent:Spawn()
		if IsValid(ply) then
			undo.Create("clock_arrive_tool")
				undo.AddEntity(ent)
				undo.SetPlayer(ply)
			undo.Finish()
		end
		ent.Station = tonumber(station)
		ent.Path = tonumber(path)
		ent:SetNW2Int("Station",station)
		ent:SetNW2Int("Path",path)
		ent:SetNW2String("Destination",dest)
		ent:SetNW2String("Line",line)
		ent:SetNW2String("LineColor",color)
	end
	
	net.Receive("SpawnClockArrive", function(len,ply)
		if not ply:IsAdmin() then return end
		local vec,ang,station,path,dest,line,color = net.ReadVector(),net.ReadAngle(),net.ReadString(),net.ReadString(),net.ReadString(),net.ReadString(),net.ReadString()
		SpawnClockArrive(ply,vec,ang,station,path,dest,line,color)
	end)
	
	local function FindPlatform(st,path)
		for k,v in pairs(ents.FindByClass("gmod_track_platform")) do
			if not IsValid(v) then continue end
			if v.StationIndex == st and v.PlatformIndex == path then return v end
		end
	end
	
	timer.Create("CAUpdateTrainsInfo",3,0,function()
		for k,v in pairs(TrainsArrive) do
			if not Metrostroi.TrainPositions[k] then TrainsArrive[k] = nil end
		end
        for train,tpos in pairs(Metrostroi.TrainPositions) do
			if not IsValid(train) then continue end
			if train.Base ~= "gmod_subway_base" and train:GetClass() ~= "gmod_subway_base" then continue end
			local cur_st = train:ReadCell(49160)
			local next_st = 0
			local path = train:ReadCell(49167)
			if train.Speed > 10 then
				if cur_st == 0 then -- перегон
					next_st = train:ReadCell(49161)
					if next_st ~= 0 then
						if path ~= 0 then
							local platform = FindPlatform(next_st,path)
							if IsValid(platform) then
								local train_pos = tpos[1]
								local station_pos = Metrostroi.GetPositionOnTrack(platform.PlatformEnd)
								if station_pos then
									TrainsArrive[train] = {}
									station_pos = station_pos[1]
									local arr,dist = Metrostroi.GetTravelTime(train_pos.node1,station_pos.node1)
									TrainsArrive[train].station = next_st
									TrainsArrive[train].path = path
									TrainsArrive[train].arrive = math.Round(arr)
								end
							end
						end
					end
				end
			else
				TrainsArrive[train] = nil
			end
        end
		for _,ent in pairs(ents.FindByClass("gmod_track_clock_arrive")) do
			if not IsValid(ent) or not ent.Station or not ent.Path then continue end
			local ArrTimes = {}
			
			for k,v in pairs(TrainsArrive) do
				if v.station and v.path and v.arrive then 
					if ent.Path ~= v.path or ent.Station ~= v.station then continue end
					table.insert(ArrTimes,v.arrive)
				end
			end

			if #ArrTimes < 1 then 
				ent:SetNW2Int("ArrTime",-1) 
			else
				local min_arr
				for k,v in pairs(ArrTimes) do
					if not min_arr or v < min_arr then min_arr = v end
				end
				ent:SetNW2Int("ArrTime",min_arr) 
			end
		end
	end)
	
	concommand.Add("clocks_arrive_save", function(ply)
		if not IsValid(ply) or not ply:IsAdmin() then return end
		local fl = file.Read("clocks_arrive.txt")
		local Clocks = fl and util.JSONToTable(fl) or {}
		local cur_map = game.GetMap()
		Clocks[cur_map] = {}
		for _,ent in pairs(ents.FindByClass("gmod_track_clock_arrive")) do
			if IsValid(ent) then table.insert(Clocks[cur_map],1,{ent:GetPos(),ent:GetAngles(),ent.Station,ent.Path,ent:GetNW2String("Destination"),ent:GetNW2String("Line"),ent:GetNW2String("LineColor")}) end
		end
		file.Write("clocks_arrive.txt", util.TableToJSON(Clocks,true))
		print("Saved "..#Clocks[cur_map].." clocks arrive.")
		if IsValid(ply) then ply:ChatPrint("Saved "..#Clocks[cur_map].." clocks arrive.") end
	end)
	concommand.Add("clocks_arrive_load", function(ply)
		if IsValid(ply) and not ply:IsAdmin() then return end
		local fl = file.Read("clocks_arrive.txt")
		local Clocks = fl and util.JSONToTable(fl) or {}
		local cur_map = game.GetMap()
		Clocks = Clocks[cur_map]
		
		for k,v in pairs(ents.FindByClass("gmod_track_clock_arrive")) do
			SafeRemoveEntity(v)
		end
		if not Clocks or #Clocks < 1 then
			print("No clocks arrive for this map")
			if IsValid(ply) then ply:ChatPrint("No clocks arrive for this map.") end
			return
		else
			for _,val in ipairs(Clocks) do
				SpawnClockArrive(nil,val[1],val[2],val[3],val[4],val[5],val[6],val[7])
			end
			print("Loaded "..#Clocks.." clocks arrive.")
		end
		if IsValid(ply) then ply:ChatPrint("Loaded "..#Clocks.." clocks arrive.") end
	end)
	
	-- Временная команда
	concommand.Add("clocks_arrive_fix", function(ply)
		if not IsValid(ply) or not ply:IsAdmin() then return end
		local col = 0
		for _,ent in pairs(ents.FindByClass("gmod_track_clock_arrive")) do
			if not IsValid(ent) then continue end
			local ang = ent:GetAngles()
			ang:RotateAroundAxis(ang:Up(),-90)
			ent:SetAngles(ang)
			ent:SetPos(ent:LocalToWorld(Vector(3,0,0)))
			col = col + 1
		end
		if IsValid(ply) then ply:ChatPrint("Fixed "..col.." clocks arrive.") end
	end)
	timer.Create("ClocksArriveLoad",4,1,function() RunConsoleCommand("clocks_arrive_load") timer.Remove("ClocksArriveLoad") end)
end