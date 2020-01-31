include("shared.lua")

local function CreateFont(font,size,name)
	surface.CreateFont(name,{
		font = font or "Moscow Sans Regular",
		extended = true,
		size = size,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	})
end
CreateFont(nil,40,"ClockArriveSmall")
CreateFont(nil,70,"ClockArriveMedium")
CreateFont(nil,180,"ClockArriveDigits")
CreateFont("Moscow Sans - Pictogram",90,"ClockArriveLine")

function ENT:Initialize()
	self:SetModel("models/alexell/clock_arrive.mdl")
	self.RealInterval = 0
	self.LocalInterval = 0
	self.TrainArrived = false
	self.TrainLeave = false
	self.Dest = self:GetNW2String("Destination","Не указано")
	self.Line = self:GetNW2String("Line","1")
	local clr = self:GetNW2String("LineColor","128,128,128")
	clr = string.Explode(",",clr)
	self.Color = Color(clr[1],clr[2],clr[3],255)
	if utf8.len(self.Dest) > 18 then
		local p = utf8.offset(self.Dest,18,1)-1
		self.Dest = self.Dest:sub(1,p).."."
	end
	self.Station = self:GetNW2Int("Station",0)
	self.Path = self:GetNW2Int("Path",0)
end

function ENT:Draw()
	self:DrawModel()
	local pos = self:LocalToWorld(Vector(-5,35,33))
	local ang = self:LocalToWorldAngles(Angle(180,90,-90))
	local arr_min = 0
	local arr_sec = 0
	cam.Start3D2D(pos,ang,0.1)
		draw.Text({
			text = "Направление",
			font = "ClockArriveSmall",
			pos = {0,0},
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			color = Color(255,255,255,255)})
		draw.Text({
			text = self.Line,
			font = "ClockArriveLine",
			pos = {0,60},
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			color = self.Color})
		draw.Text({
			text = self.Dest,
			font = "ClockArriveMedium",
			pos = {70,53},
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			color = Color(255,255,255,255)})
	cam.End3D2D()
	if self.LocalInterval >= 0 then
		arr_min = string.format("%02i",math.floor(self.LocalInterval / 60))
		arr_sec = string.format("%02i",math.floor(self.LocalInterval % 60))
		cam.Start3D2D(pos,ang,0.1)
			draw.Text({
				text = "Поезд прибывает через",
				font = "ClockArriveSmall",
				pos = {0,120},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
				
			draw.Text({
				text = arr_min,
				font = "ClockArriveDigits",
				pos = {0,200},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
			draw.Text({
				text = "мин",
				font = "ClockArriveMedium",
				pos = {200,236},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
			draw.Text({
				text = arr_sec,
				font = "ClockArriveDigits",
				pos = {350,200},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
			draw.Text({
				text = "сек",
				font = "ClockArriveMedium",
				pos = {550,236},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
		cam.End3D2D()
	elseif self.LocalInterval == -1 then
		cam.Start3D2D(pos,ang,0.1)
			draw.Text({
				text = "Поезд прибывает",
				font = "ClockArriveMedium",
				pos = {100,170},
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				color = Color(255,255,255,255)})
		cam.End3D2D()
	end
end

function ENT:Think()
    if not self:GetTrain() or self.TrainLeave == true then
		self.RealInterval = self:GetNW2Int("ArrTime",-1)
		if self.RealInterval > 0 then
			if self.LastInterval == self.RealInterval then
				self.LocalInterval = self.LocalInterval - 1
			else
				self.LastInterval = self.RealInterval
				self.LocalInterval = self.RealInterval
			end
		else
			self.LocalInterval = -2
		end
	end
	if self:GetTrain() then
		if self:GetTrainStopped() then
			self.TrainArrived = true
			self.LocalInterval = -2 -- пустой экран
			self.LastInterval = 0
		else
			if self.TrainLeave == false then
				if self.TrainArrived == true then
					self.TrainArrived = false
					self.TrainLeave = true
				else
					if self.LocalInterval > 0 then
						self.LocalInterval = self.LocalInterval - 1
					else
						self.LocalInterval = -1 -- поезд прибывает
					end
				end
			end
		end
	else
		self.TrainLeave = false
	end
	self:SetNextClientThink(CurTime()+1)
end
