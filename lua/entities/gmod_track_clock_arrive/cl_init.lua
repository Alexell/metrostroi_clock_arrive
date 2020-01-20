include("shared.lua")

local function FindPlatform(st,path)
	for k,v in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(v) then continue end
		if v:GetNWInt("StationIndex") == st and v:GetNWInt("PlatformIndex") == path then return v end
	end
end

function ENT:Initialize()
	self:SetModel("models/metrostroi/clock_interval_moscow.mdl")
	self.LastTime = 0
	self.RealInterval = 0
	self.LocalInterval = 0
	self.Text = self:GetNW2String("NextStation","Неизвестно")
	if utf8.len(self.Text) > 20 then
		local p = utf8.offset(self.Text,20,1)-1
		self.Text = self.Text:sub(1,p).."."
	end
	self.Station = self:GetNW2Int("Station",0)
	self.Path = self:GetNW2Int("Path",0)
	self.Platform = FindPlatform(self.Station,self.Path)
	self.TrainInStation = false
end

function ENT:Draw()
	self:DrawModel()
	local pos = self:LocalToWorld(Vector(22,-1.5,0))
	local ang = self:LocalToWorldAngles(Angle(180,0,-90))
	local arr_min = "--"
	local arr_sec = "--"
	cam.Start3D2D(pos,ang,0.3)
		draw.Text({
			text = "Направление",
			font = "HudHintTextSmall",
			pos = {0,-35},
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			color = Color(200,255,255,255)})
		draw.Text({
			text = self.Text,
			font = "HudHintTextLarge",
			pos = {0,-24},
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			color = Color(200,255,255,255)})
	cam.End3D2D()
	if self.LocalInterval >= 0 then
		if self.LocalInterval > 0 then
			arr_min = string.format("%02i",math.floor(self.LocalInterval / 60))
			arr_sec = string.format("%02i",math.floor(self.LocalInterval % 60))
		end
		cam.Start3D2D(pos,ang,0.3)
			draw.Text({
				text = "Поезд прибывает через",
				font = "HudHintTextSmall",
				pos = {0,-5},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
				
			draw.Text({
				text = arr_min,
				font = "ContentHeader",
				pos = {0,20},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
			draw.Text({
				text = "мин",
				font = "HudHintTextLarge",
				pos = {47,30},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
			draw.Text({
				text = arr_sec,
				font = "ContentHeader",
				pos = {75,20},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
			draw.Text({
				text = "сек",
				font = "HudHintTextLarge",
				pos = {122,30},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
		cam.End3D2D()
	elseif self.LocalInterval == -1 then
		cam.Start3D2D(pos,ang,0.5)
			draw.Text({
				text = "Поезд прибывает",
				font = "HudHintTextSmall",
				pos = {7,10},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(200,255,255,255)})
		cam.End3D2D()
	end
end

function ENT:Think()
	if CurTime() - self.LastTime < 1 then return end
	self.LastTime = CurTime()
	
    if self.RealInterval ~= -1 and self.TrainInStation ~= true then
		self.RealInterval = self:GetNW2Int("ArrTime",-2)
	end
	
	if self.RealInterval > 0 then
		if self.LastInterval == self.RealInterval then
			self.LocalInterval = self.LocalInterval - 1
		else
			self.LastInterval = self.RealInterval
			self.LocalInterval = self.RealInterval
		end
	elseif self.RealInterval == -1 then
		if self.TrainInStation == false then -- чтобы не срабатывало при отправлении
			if self.LocalInterval > 1 then
				self.LocalInterval = self.LocalInterval - 1
			else
				self.LocalInterval = -1
			end
		end
	elseif self.RealInterval == -2 then
		self.LocalInterval = 0
	end
	if self.Platform then
		if self.Platform:GetNW2Int("TrainDoorCount",0) > 0 then
			self.TrainInStation = true
			self.LocalInterval = -2
			self.LastInterval = 0
		else
			if self.TrainInStation == true then
				if self.LocalInterval == -2 then self.LocalInterval = 0 end
				timer.Simple(5,function()
					self.TrainInStation = false
					if self.RealInterval == -1 then self.RealInterval = 0 end
				end)
			end
		end
	end
end
