//GUI Elements are at the bottom of this file.


//Fonts
for i=12,64 do
	surface.CreateFont("bobbleTitle"..i,{
		weight=500 + 48 - i%48,
		font="BigNoodleTitling",
		size=i
	})
	surface.CreateFont("bobbleRoboto"..i,{
		weight=510 + 48 - i%48,
		font="Roboto",
		size=i
	})
end

//Colors
local keycol = Color(52,84,115)
local keycol_trans = Color(52,84,115,150)

//Key material
local keymat = Material("assassins/key.png","smooth unlitgeneric")
local keymat_small = Material("assassins/key_small.png","smooth unlitgeneric")

//Draw functions
-- Draws an arc on your screen.
-- startang and endang are in degrees, 
-- radius is the total radius of the outside edge to the center.
-- cx, cy are the x,y coordinates of the center of the arc.
-- roughness determines how few triangles are drawn. Number between 1-360; 2 or 3 is a good number.
function draw.Arc(cx,cy,radius,thickness,startang,endang,roughness,color)
	surface.SetDrawColor(color)
	surface.DrawArc(surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness))
end

function surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness)
	local triarc = {}
	-- local deg2rad = math.pi / 180
	
	-- Define step
	local roughness = math.max(roughness or 1, 1)
	local step = roughness
	
	-- Correct start/end ang
	local startang,endang = startang or 0, endang or 0
	
	if startang > endang then
		step = math.abs(step) * -1
	end
	
	-- Create the inner circle's points.
	local inner = {}
	local r = radius - thickness
	for deg=startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx+(math.cos(rad)*r), cy+(-math.sin(rad)*r)
		table.insert(inner, {
			x=ox,
			y=oy,
			u=(ox-cx)/radius + .5,
			v=(oy-cy)/radius + .5,
		})
	end
	
	
	-- Create the outer circle's points.
	local outer = {}
	for deg=startang, endang, step do
		local rad = math.rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx+(math.cos(rad)*radius), cy+(-math.sin(rad)*radius)
		table.insert(outer, {
			x=ox,
			y=oy,
			u=(ox-cx)/radius + .5,
			v=(oy-cy)/radius + .5,
		})
	end
	
	
	-- Triangulize the points.
	for tri=1,#inner*2 do -- twice as many triangles as there are degrees.
		local p1,p2,p3
		p1 = outer[math.floor(tri/2)+1]
		p3 = inner[math.floor((tri+1)/2)+1]
		if tri%2 == 0 then --if the number is even use outer.
			p2 = outer[math.floor((tri+1)/2)]
		else
			p2 = inner[math.floor((tri+1)/2)]
		end
	
		table.insert(triarc, {p1,p2,p3})
	end
	
	-- Return a table of triangles to draw.
	return triarc
	
end

function surface.DrawArc(arc) //Draw a premade arc.
	for k,v in ipairs(arc) do
		surface.DrawPoly(v)
	end
end


//Action Key for +use
local PANEL = {}

AccessorFunc(PANEL,"Text","Text",FORCE_STRING)
AccessorFunc(PANEL,"Vector","Vector")
AccessorFunc(PANEL,"KeyBind","KeyBind",FORCE_STRING)
function PANEL:Init()
	
	self:SetVector(Vector(0,0,0))
	self:SetText("")
	self:SetSize(100,64)
	self:SetKeyBind("+use")
	
end
function PANEL:Think()
	cam.Start3D()
		local tos = self:GetVector():ToScreen()
		self:SetPos(tos.x-self:GetWide()/2,tos.y-self:GetTall()/2)
	cam.End3D()
end

function PANEL:SetVector(vec)
	self.Vector = vec
	cam.Start3D()
		local tos = vec:ToScreen()
		self:SetPos(tos.x-self:GetWide()/2,tos.y-self:GetTall()/2)
	cam.End3D()
end

function PANEL:Paint(w,h)
	
	local usekey = input.LookupBinding( self.KeyBind ):upper()
	
	//Bg box
	local gap = 8
	draw.RoundedBox(8,0,gap,w,h-2*gap,Color(0,0,0,200))
	
	//Key image
	surface.SetDrawColor(color_white)
	surface.SetMaterial(keymat)
	surface.DrawTexturedRect(gap,0,h,h)
	draw.NoTexture()
	
	//Label
	local tw,th = draw.Text({
		text = self:GetText(),
		pos = { gap+h+4, h/2 },
		xalign=TEXT_ALIGN_LEFT,
		yalign=TEXT_ALIGN_CENTER,
		font = "bobbleTitle26",
	})
	
	//Key label
	draw.Text({
		text = usekey,
		pos = { gap+20, gap+10 },
		xalign=TEXT_ALIGN_LEFT,
		yalign=TEXT_ALIGN_CENTER,
		font = "bobbleTitle24",
		color=keycol,
	})
	
	//Resize
	self:SetWide(math.max(gap+tw+h+4+gap,100))
	
end
vgui.Register("ass_ActionKey",PANEL,"Panel")


//Radar for target-seeking
local function GetDistMod(dist) //Function which decides how much to show on the radar. Returns degrees/2.

	local mod = 0
	
	if dist < 450 then
		mod = 180
	else
		-- mod = math.ceil(math.max(5,(-15*(dist^(1/3))) + 180))
		mod = math.ceil(math.max(5,(-4.6*(dist^(1/2))) + 180))
	end
	
	return mod
end

local PANEL = {}

local upmat = Material("assassins/radar_up.png","noclamp smooth unlitgeneric")
local downmat = Material("assassins/radar_down.png","noclamp smooth unlitgeneric")
AccessorFunc(PANEL,"Target","Target")
PANEL.Vector = Vector(0,0,0)
function PANEL:Init()
	
	self:SetSize(170,170)
	
end

function PANEL:Paint(w,h)
	local target,ply,pos,dist = self:GetTarget(), LocalPlayer()
	local plypos = ply:GetPosAutoPilot()
	if IsValid(target) and target:Alive() then
		pos = target:GetPosAutoPilot()
		dist = plypos:Distance(pos)
	end
	
	//Precache arc
	self.FillArc = self.FillArc or surface.PrecacheArc(w/2,h/2,w/2,w/4,0,360,12)
	
	//Make oblique
	self.Matrix = Matrix()
	self.Matrix:Translate(Vector(0,ScrH()/2,0))
	self.Matrix:Scale(Vector(1,.5,1))
	cam.PushModelMatrix(self.Matrix)
		
		//Bg box
		-- draw.RoundedBox(8,0,0,w,h,Color(0,0,0,200))
		
		//Background arc
		draw.NoTexture()
		surface.SetDrawColor(keycol_trans)
		surface.DrawArc(self.FillArc)
		
		//Foreground arc
		if IsValid(target) and target:Alive() then
			local cansee = ply:GetTargetEnt():IsLineOfSightClear(ply)
			local col = cansee and color_white or Color(0,0,0,255)
			local sang,eang,cang = 0,0,0
			local dmod = GetDistMod(dist)
			
			self.DistMod = math.Approach(self.DistMod or 0, dmod, RealFrameTime()*180)
			
			//Distance-based intensity
			-- if self.DistMod == 180 and INTENSITY_LEVEL == 2 then //If we're within the closeness limit
				-- SetIntensity(3)
			-- elseif self.DistMod < 180 and INTENSITY_LEVEL == 3 then
				-- SetIntensity(2)
			-- end
			
			
			local norm = (plypos-pos):GetNormalized()
			cang = math.deg(math.atan2(norm.y,norm.x))
			cang = (cang - (EyeAngles().y + 90)) % 360
			
			sang,eang = cang-self.DistMod,cang+self.DistMod
			
			draw.Arc(w/2,h/2,w/2-3,w/4-6,sang,eang,3,col)
		
			//Up and down
			if plypos.z-pos.z < -90 then
				surface.SetMaterial(upmat)
				surface.SetDrawColor(color_black)
				surface.DrawTexturedRect(w/2-32+1,h/2-32+1,64,64)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(w/2-32,h/2-32,64,64)
			elseif plypos.z-pos.z > 90 then
				surface.SetMaterial(downmat)
				surface.SetDrawColor(color_black)
				surface.DrawTexturedRect(w/2-32+1,h/2-32+1,64,64)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(w/2-32,h/2-32,64,64)
			end
		end
		
	cam.PopModelMatrix()
	
end
vgui.Register("ass_Radar",PANEL,"DPanel")


local PANEL = {}

AccessorFunc(PANEL,"Target","Target")
-- AccessorFunc(PANEL,"Heat","Heat",FORCE_NUMBER)
function PANEL:Init()
	
	self:SetSize(160,160)
	-- self:SetHeat(0)
	
	//Define Avatars
	self.avatars = {}
	for i=1,ConVars.Server.maxPursuers:GetInt() do
		local av = vgui.Create("AvatarImage",self)
		self.avatars[i] = av
		local x,y,w,h = (i-1)%2, math.floor((i-1)/2), 20, 20
		av:SetSize(16,16)
		-- av:SetPos((i-1)%2*75+10, math.floor((i-1)/2)*75+10)
		av:AlignRight(x*w+5)
		av:AlignTop(y*h+5)
		av:SetPlayer(LocalPlayer(),64)
		av:SetVisible(false)
		
	end
	
	//Define elements
	local mdl = vgui.Create("DModelPanel",self)
	self.Mdl = mdl
	local search = vgui.Create("DImage",self)
	self.Searching = search
	
	//Init elements
	mdl:SetSize(self:GetWide(),self:GetTall()-16)
	function mdl.LayoutEntity(this,ent)
		-- function ent.GetPlayerColor(this)
			-- return self:GetTarget():GetPlayerColor()
		-- end
		ent:SetSequence(0)
		ent:SetAngles(Angle(0,30,0))
		this:SetLookAt(ent:GetPos()+Vector(0,0,63))
		this:SetFOV(18)
	end
	
	search:SetSize(64,64)
	search:Center()
	search:SetImage("assassins/smallcircleload","vgui/avatar_default")
	search:SetVisible(false)
	
	
end
function PANEL:SetTarget(new)
	self.Target = new
	
	timer.Simple(1, function()
		if !IsValid(self) then return end
		if !IsValid(self.Mdl) then return end
		if !IsValid(new) then return end
		self.Mdl:SetModel(new:GetModel())
	end)
end
function PANEL:Think()
	local num = ConVars.Server.maxPursuers:GetInt()
	if IsValid(self.Target) and self.Target:Alive() then
		self.Mdl:SetVisible(true)
		self.Searching:SetVisible(false)
		-- if self.Mdl:GetModel() != self.Target:GetModel() then
			-- self.Mdl:SetModel(self.Target:GetModel())
		-- end
		
		local i=1
		for k,o in pairs(player.GetAll())do
			if o:Team() != TEAM_ASS then continue end
			if o:GetTarget() == self.Target then
				
				self.avatars[i]:SetVisible(true)
				self.avatars[i]:SetPlayer(o,64)
				
				i = i + 1
				
				if i> num then break end
			end
		end
		
		for j=i,num do
			self.avatars[j]:SetVisible(false)
		end
	else
		self.Mdl:SetVisible(false)
		self.Searching:SetVisible(true)
		for i=1,num do
			self.avatars[i]:SetVisible(false)
		end
	end
end
function PANEL:Paint(w,h)
	
	local heat = LocalPlayer():GetHeat()/100 * w
	self.segw = math.Approach(self.segw or 0, heat, RealFrameTime()*w)
	
	//ent bg
	draw.RoundedBox(8,0,0,w,h,keycol_trans)
	
	//Heat bg
	draw.RoundedBoxEx(8,0,h-16,w,16,Color(0,0,0,200),false,false,true,true)
	
	//Heat Bar
	-- stencil.Push()
		stencil.Enable(true)
		stencil.Clear()
		stencil.Reference(1)
		stencil.Mask(255)
		stencil.SetOperations(STENCIL_KEEP,STENCIL_REPLACE,STENCIL_REPLACE)
		stencil.Compare(STENCIL_NEVER)
		draw.RoundedBoxExStencil(8,0,h-16,w,16,Color(0,0,0,200),false,false,true,true)
		
		stencil.SetOperations(STENCIL_DECRSAT,STENCIL_KEEP,STENCIL_KEEP)
		stencil.Compare(STENCIL_EQUAL)
		draw.RoundedBoxEx(0,0,h-16,self.segw,16,color_white,false,false,true,true)
		
		-- //Text
		-- stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
		-- stencil.Compare(STENCIL_NOTEQUAL)
		-- draw.SimpleText(" Silent     Discrete       Audacious     !!!","bobbleTitle16",4,h-8,color_black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		
		//Segments
		stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
		stencil.Compare(STENCIL_NOTEQUAL)
		surface.SetDrawColor(color_black)
		surface.DrawRect(36,h-16,1,16)
		surface.DrawRect(84,h-16,1,16)
		surface.DrawRect(141,h-16,1,16)
		
		stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
		stencil.Compare(STENCIL_EQUAL)
		surface.SetDrawColor(color_white)
		surface.DrawRect(36,h-16,1,15)
		surface.DrawRect(84,h-16,1,15)
		surface.DrawRect(141,h-16,1,15)
		
		stencil.Enable(false)
	-- stencil.Pop()
	
	
	surface.DisableClipping(true)
	
	local ox,oy = self.segw, h+2
	surface.SetDrawColor(color_white)
	surface.DrawLine(ox,oy,ox,oy+20)
	surface.DrawLine(ox,oy+20,ox-15,oy+30)
	
	draw.SimpleText(LocalPlayer():GetHeatDescription(),"bobbleTitle20",ox,oy+30,color_white,TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP)
	
	surface.DisableClipping(false)
	
	
end
function PANEL:PaintOver(w,h)
	local text = "Target:"
	if IsValid(self:GetTarget()) then
		text = text .. "  " .. self:GetTarget():Nick()
	else
		text = text .. "  Searching..."
	end
	surface.SetFont("bobbleTitle16")
	local tw = surface.GetTextSize(text)
	self.texw = math.Approach(self.texw or 0, tw, RealFrameTime()*w*.75)
	
	//Title bg
	draw.RoundedBoxEx(8,0,0,self.texw+12,16,color_white,true,false,false,true)
	
	//Title text
	-- stencil.Push()
		stencil.Enable(true)
		stencil.Reference(1)
		stencil.Mask(255)
		stencil.SetOperations(STENCIL_KEEP,STENCIL_REPLACE,STENCIL_REPLACE)
		stencil.Compare(STENCIL_NEVER)
		surface.DrawRect(0,0,self.texw+12,16)
		
		
		stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
		stencil.Compare(STENCIL_EQUAL)
		draw.SimpleText(text,"bobbleTitle16",6,8,color_black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		
		stencil.Enable(false)
	-- stencil.Pop()
	
	
	
end
vgui.Register("ass_TargetModel",PANEL,"Panel")

//Hunted HUD
local PANEL = {}
function PANEL:Init()
	self:SetSize(160,160)
	local search = vgui.Create("DImage",self)
	self.Searching = search
	
	self.avatars = {}
	for i=1,4 do
		local av = vgui.Create("AvatarImage",self)
		self.avatars[i] = av
		av:SetPos((i-1)%2*75+10, math.floor((i-1)/2)*75+10)
		av:SetSize(64,64)
		av:SetPlayer(LocalPlayer(),64)
		av:SetVisible(false)
		
	end
	
	search:SetSize(64,64)
	search:Center()
	search:SetImage("assassins/smallcircleload","vgui/avatar_default")
	search:SetVisible(false)
	
end

function PANEL:Paint(w,h)
	local ply = LocalPlayer()
	
	draw.RoundedBox(8,0,0,w,h,keycol_trans)
	
	local num = ConVars.Server.maxPursuers:GetInt()
	local i=1
	for k,o in pairs(player.GetAll())do
		if o:Team() != TEAM_ASS then continue end
		if o:GetTarget() == ply then
			
			self.avatars[i]:SetVisible(true)
			self.avatars[i]:SetPlayer(o,64)
			
			i = i + 1
			
			if i> num then break end
		end
	end
	
	for j=i,num do
		self.avatars[j]:SetVisible(false)
	end
	
	if i == 1 then
		self.Searching:SetVisible(true)
	else
		self.Searching:SetVisible(false)
	end
	
	
end

function PANEL:PaintOver(w,h)
	local text = "Pursuers:"
	surface.SetFont("bobbleTitle16")
	
	//Title bg
	draw.RoundedBoxEx(8,0,0,56,16,color_white,true,false,false,true)
	
	//Title text
	draw.SimpleText(text,"bobbleTitle16",6,8,color_black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
	
	
	
end

vgui.Register("ass_HuntedBy",PANEL,"Panel")



local PANEL = {}
function PANEL:Init()
	self:SetSize(300,180)
	
end
function PANEL:StartAnim(scoretbl)
	self.scoretbl = scoretbl
	self.starttime = RealTime()
	self.lasti=-1
end

local delay = 1.3
function PANEL:Paint(w,h)
	draw.RoundedBox(8,0,116,w-68,h-116,keycol_trans)
	
	if self.starttime then
		local scoretbl = self.scoretbl
		local dt = RealTime() - self.starttime
		local i = math.floor(dt/delay)+1
		local timesince = i-dt/delay
		
		//Get current score based on what we've shown already.
		local cursum,curmod,cur,curtype = 0,1,{}
		local idex = 0
		for k=1, #scoretbl.amt do
			if idex < i then
				cursum = cursum + scoretbl.amt[k][1]
				cur = scoretbl.amt[k]
				curtype = "+ "
				idex = idex + 1
			end
		end
		for k=1, #scoretbl.mod do
			if idex < i then
				curmod = curmod + scoretbl.mod[k][1]
				cur = scoretbl.mod[k]
				curtype = "× "
				idex = idex + 1
			end
		end
		cursum = cursum * curmod
		
		//Draw sum
		self.lastsum = math.ceil(Lerp(timesince/delay/8,self.lastsum or 0,cursum))
		draw.SimpleText(tostring(self.lastsum),"bobbleTitle64",6,h,color_white,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,1,color_black)
		draw.SimpleText("points","bobbleTitle64",w-74,h,color_white,TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM,1,color_black)
		
		//Draw bonus
		if curtype and idex==i then
			local col = Color(255,255,255,Lerp(timesince/delay-.1,0,300))
			-- local colo = Color(0,0,0,Lerp(timesince/delay-.1,0,255))
			draw.SimpleText(curtype..tostring(cur[1]).." "..cur[2],"bobbleTitle32",6,h-100-timesince*-50,col,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,1,colo)
		end
		
	end
end


function PANEL:Think()
	if self.starttime then
		local scoretbl = self.scoretbl
		local dt = RealTime() - self.starttime
		local i = math.floor(dt/delay)
		local count = #scoretbl.amt+#scoretbl.mod
		if i > count then
			self:Remove()
		elseif i != self.lasti then
			self.lasti=i
			if i == count then
				surface.PlaySound("ui/achievement_earned.wav")
			else
				surface.PlaySound("ui/hint.wav")
			end
		end
	end
end

vgui.Register("ass_ScoreTotal",PANEL,"Panel")

local PANEL = {}
AccessorFunc(PANEL,"Chasing","Chasing",FORCE_BOOL)
AccessorFunc(PANEL,"PursuerNum","PursuerNum",FORCE_NUMBER)
function PANEL:Init()
	self:SetSize(ScrW()/6,40)
	self:SetPursuerNum(1)
	self.was = false
end

function PANEL:GetText()
	if self:GetChasing() then
		if chase.IsDegrading(LocalPlayer(),LocalPlayer():GetTarget()) then
			if !self.was then
				LocalPlayer():EmitSound("ass_chase_losing")
				self.was = true
			end
			return "FIND TARGET"
		else
			if self.was then
				LocalPlayer():StopSound("ass_chase_losing")
				self.was = false
			end
			return "KILL TARGET"
		end
	else
		if chase.IsDegrading(LocalPlayer().Pursuers[self:GetPursuerNum()],LocalPlayer()) then
			if !self.was then
				LocalPlayer():EmitSound("ass_chase_hiding")
				self.was = true
			end
			return "HIDE"
		else
			if self.was then
				LocalPlayer():StopSound("ass_chase_hiding")
				self.was = false
			end
			return "RUN"
		end
	end
end
function PANEL:GetProg()
	if self:GetChasing() then
		return LocalPlayer():GetChase()/100
	else
		return LocalPlayer().Pursuers[self:GetPursuerNum()]:GetChase()/100
	end
end

function PANEL:Paint(w,h)
	if self:GetChasing() and not LocalPlayer():IsChasing() then return end
	if !self:GetChasing() and not IsValid(LocalPlayer().Pursuers[self:GetPursuerNum()]) then return end
	if !self:GetChasing() and not LocalPlayer():BeingChased() then return end
	
	//bg
	draw.RoundedBox(0,0,0,w,h,keycol)
	
	stencil.Enable(true)
	stencil.Clear()
	stencil.Reference(1)
	stencil.Mask(255)
	stencil.SetOperations(STENCIL_KEEP,STENCIL_REPLACE,STENCIL_REPLACE)
	stencil.Compare(STENCIL_NEVER)
	-- draw.RoundedBoxExStencil(8,4,4,w-8,h-8,Color(0,0,0,200),true,true,true,true)
	surface.DrawRect(2,2,w-4,h-4)
	
	stencil.SetOperations(STENCIL_DECRSAT,STENCIL_KEEP,STENCIL_KEEP)
	stencil.Compare(STENCIL_EQUAL)
	draw.RoundedBox(0,0,0,w*self:GetProg(),h,color_white)
	
	
	local txt = self:GetText()
	
	stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
	stencil.Compare(STENCIL_NOTEQUAL)
	draw.SimpleText(txt,"bobbleTitle48",w/2,h/2,keycol,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	
	stencil.SetOperations(STENCIL_KEEP,STENCIL_KEEP,STENCIL_KEEP)
	stencil.Compare(STENCIL_EQUAL)
	draw.SimpleText(txt,"bobbleTitle48",w/2,h/2,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	
	stencil.Enable(false)
end

vgui.Register("ass_ChaseBar",PANEL,"Panel")

local PANEL = {}
PANEL.Stages = {
	Material("assassins/tut/tut1.png","unlitgeneric smooth"),
	Material("assassins/tut/tut2.png","unlitgeneric smooth"),
	Material("assassins/tut/tut3.png","unlitgeneric smooth"),
	Material("assassins/tut/tut4.png","unlitgeneric smooth"),
	Material("assassins/tut/tut5.png","unlitgeneric smooth"),
	Material("assassins/tut/tut6.png","unlitgeneric smooth"),
	Material("assassins/tut/tut7.png","unlitgeneric smooth"),
	Material("assassins/tut/tut8.png","unlitgeneric smooth")
}
function PANEL:Init()
	
	self.stage = 1
	self.max = #self.Stages-1
	
	local img = vgui.Create("DImage",self)
	img:SetSize(800,600)
	img:SetMaterial(self.Stages[1])
	self.img = img
	
	local bot = vgui.Create("Panel",self)
	bot:SetTall(45)
	bot:Dock(BOTTOM)
	
	local prev = vgui.Create("DButton",bot)
	prev:Dock(LEFT)
	prev:SetWide(150)
	prev:SetText("Previous")
	function prev.DoClick(btn)
		self.stage = math.max(self.stage-1,1)
		img:SetMaterial(self.Stages[self.stage])
		self.prog:SetFraction(self.stage/self.max)
	end
	self.prev = prev
	
	local next = vgui.Create("DButton",bot)
	next:Dock(RIGHT)
	next:SetWide(150)
	next:SetText("Next")
	function next.DoClick(btn)
		self.stage = math.min(self.stage+1,self.max)
		img:SetMaterial(self.Stages[self.stage])
		self.prog:SetFraction(self.stage/self.max)
	end
	self.next = next
	
	local prog = vgui.Create("DProgress",bot)
	prog:Dock(FILL)
	prog:DockMargin(5,5,5,5)
	prog:SetFraction(1/self.max)
	self.prog = prog
	
	
end
vgui.Register("ass_Tutorial",PANEL,"Panel")
local TUT
concommand.Add("ass_tutorial",function()
	if IsValid(TUT) then TUT:Remove() end

	TUT = vgui.Create("DFrame")
	TUT:SetSize(810,683)
	TUT:Center()
	TUT:SetTitle("Quickstart Guide")
	TUT:MakePopup()

	local tut = vgui.Create("ass_Tutorial",TUT)
	tut:Dock(FILL)
end)
hook.Add("InitPostEntity","ass_tutorial",function() //Show firsttimers the tutorial.
	timer.Simple(4,function()
		if cookie.GetNumber("ass_tutorial",0) != 1 then
			cookie.Set("ass_tutorial",1)
			RunConsoleCommand("ass_tutorial")
		end
	end)
end)

local PANEL = {}
local hex = Material("assassins/hexagon.png","unlitgeneric smooth")
local hexalpha = Material("assassins/hexagon.png","unlitgeneric smooth alphatest")
AccessorFunc(PANEL,"Key","Key",FORCE_STRING)
AccessorFunc(PANEL,"CD","CD",FORCE_NUMBER)
function PANEL:Init()
	
	self:SetSize(56,56)
	self:DockPadding(10,10,10,10)
	self.nextUse = CurTime()
	
	local img = vgui.Create("DImage",self)
	self.img = img
	img:Dock(FILL)
	
	self:SetMaterial(hex)
	
end
function PANEL:PaintOver(w,h)
	
	//Paint cooldown
	local timeUntil = self.nextUse - CurTime()
	if timeUntil > 0 then
		
		stencil.Enable(true)
			stencil.Clear()
			stencil.Reference(1)
			stencil.Mask(255)
			stencil.Compare(STENCIL_NEVER)
			stencil.SetOperations(STENCIL_KEEP,STENCIL_REPLACE,STENCIL_REPLACE)
			
			surface.SetMaterial(hexalpha)
			surface.DrawTexturedRect(0,0,w,h)
			
			stencil.Compare(STENCIL_EQUAL)
			stencil.SetOperations(STENCIL_INCR,STENCIL_KEEP,STENCIL_KEEP)
			
			draw.NoTexture()
			draw.Arc(w/2,h/2,w/2,w/2,90,360*timeUntil/self:GetCD()+90,3,color_black)
			-- surface.DrawRect(0,h-h*timeUntil/self:GetCD(),w,h*timeUntil/self:GetCD())
			
			stencil.Compare(STENCIL_NOTEQUAL)
			local t = math.Round(timeUntil)
			draw.SimpleText(t, "bobbleTitle26", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			stencil.Compare(STENCIL_EQUAL)
			draw.SimpleText(t, "bobbleTitle26", w/2, h/2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		stencil.Enable(false)
		
		
	end
	
	
	//Paint key
	surface.SetDrawColor(color_white)
	surface.SetMaterial(keymat_small)
	local s = 24
	surface.DrawTexturedRect(w-s,h-s,s,s)
	draw.SimpleText(input.LookupBinding("slot"..(self:GetKey() or "")), "bobbleTitle16", w-s/2-1, h-s/2-1, keycol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
end
function PANEL:StartCD(nextUse)
	self.nextUse = nextUse or (self:GetCD() + CurTime()) 
end

vgui.Register("ass_Equipment",PANEL,"DImage")
