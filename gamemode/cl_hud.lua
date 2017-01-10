
hud = hud or {}

-- for i=12, 64 do
	-- surface.CreateFont("assassin"..i, {font = "impact", size = i, weight = 2, additive = false, antialias = true})
-- end

//Return vis, text, pos for the ActionKey HUD. Return false to prevent it from showing.
function GM:ASSActionKeyHover(ent)
	if ent:IsPlayer() then
		if not ent.DeathSeq then
			if ent == LocalPlayer():GetTarget() and !ent.DeathSeq then
				return true, "Assassinate", ent:GetPos() + ent:OBBCenter()
			else --if ent:GetTarget() == LocalPlayer() then
				if !ent:GetNW2Bool("ass_stunned",false) then
					return true, "Assassinate", ent:GetPos() + ent:OBBCenter()
				end
			end
		end
	end
	
	if ent:GetClass():find("func_breakable") then
		return true, "Break", ent:GetPos() + ent:OBBCenter()
	end
	
	return false
end

local nodraw = {["CHudAmmo"]=true, ["CHudSecondaryAmmo"]=true, ["CHudBattery"]=true, ["CHudHealth"]=true, ["CHudSuitPower"]=true, ["CHudCrosshair"]=true, ["CHudZoom"]=true}
function GM:HUDShouldDraw( name )
	if nodraw[name] then
		return false
	end
	return true
end
function GM:HUDDrawTargetID()
end
local xhair = Material("assassins/xhair.png","noclamp unlitgeneric")
local xhair_z = Material("assassins/xhair_zoom.png","noclamp unlitgeneric")
local matlock = Material("assassins/padlock.png","noclamp unlitgeneric smooth")
local matlock_f = Material("assassins/padlock_filled.png","noclamp unlitgeneric smooth")
local keycol = Color(52,84,115)
local keycol_trans = Color(52,84,115,150)
local blink = function(x) return (.08*x*math.cos(1.5*math.pi*x*x)-.08*x+.1) > 0 end
local was = true
local blip = Sound("buttons/button16.wav")
function GM:HUDPaint()
	local sw,sh = ScrW(),ScrH()
	
	local xhair_col = color_white
	
	if not CURRENT_STATE then return end
	
	//Draw round timer
	if CURRENT_STATE.number == 2  then
		local timerem = RoundStateTimeLeft()
		local time = string.ToMinutesSeconds(timerem)
		surface.SetFont("bobbleTitle30")
		local tw,th = surface.GetTextSize(time)
		local tcol = timerem >= 30 and color_white or (math.floor(timerem)%2==0 and color_white or Color(255,100,100))
		tw=math.max(tw,45)
		surface.SetDrawColor(keycol_trans)
		surface.DrawRect(ScrW()/2-tw/2-10,100,tw+20,th+10)
		draw.SimpleText(time, "bobbleTitle30", ScrW()/2, 105, tcol, TEXT_ALIGN_CENTER)
	end
	
	
	//Draw Crosshair
	if LocalPlayer().AimingHook then
		surface.SetMaterial(xhair_z)
		surface.SetDrawColor(color_black)
		surface.DrawTexturedRect(sw/2-31,sh/2-31+5,64,64)
		
		local tr,trace = LocalPlayer():GetEyeTraceAutoPilot(GetConVarNumber("ass_grapple_hook_dist"))
		local dest = grapp.ValidTarget(tr,trace)
		if dest then
			xhair_col = Color(100,255,100)
		else
			xhair_col = Color(255,100,100)
		end
		surface.SetDrawColor(xhair_col)
		surface.DrawTexturedRect(sw/2-32,sh/2-32+5,64,64)
	elseif LocalPlayer().Zoomed then
		surface.SetMaterial(xhair_z)
		surface.SetDrawColor(color_black)
		surface.DrawTexturedRect(sw/2-31,sh/2-31+5,64,64)
		surface.SetDrawColor(xhair_col)
		surface.DrawTexturedRect(sw/2-32,sh/2-32+5,64,64)
	end
	
	surface.SetMaterial(xhair)
	surface.SetDrawColor(color_black)
	surface.DrawTexturedRect(sw/2-31,sh/2-31+5,64,64)
	surface.SetDrawColor(xhair_col)
	surface.DrawTexturedRect(sw/2-32,sh/2-32+5,64,64)
	
	
	local lock = LocalPlayer():GetLockEnt()
	if IsValid(lock) then
		-- lock.LastSeenTime = lock.LastSeenTime or CurTime() 
		cam.Start3D()
			local tos = (lock:GetPos()+Vector(0,0,80)):ToScreen()
		cam.End3D()
		
		//Do lastseen processing
		-- if tos.visible and tos.x>0 and tos.x<ScrW() and tos.y>0 and tos.y<ScrW() and LocalPlayer():IsLineOfSightClear( lock ) then
		local pvis = util.PixelVisible(lock:GetPos()+lock:OBBCenter(), 16, LocalPlayer().LockPixVis)
		if pvis and pvis > 0 then
			lock.LastSeenTime = CurTime()
		elseif CurTime() > lock.LastSeenTime + GetConVarNumber("ass_lock_lose_time") then //lose our lock.
			net.Start("ass_playerlock")
			net.SendToServer()
			LocalPlayer():SetLock(NULL)
		end
		
		//Draw Lock over head
		local dtime = CurTime() - lock.LastSeenTime
		if blink(dtime, GetConVarNumber("ass_lock_lose_time")) then
			if not was then
				surface.PlaySound(blip)
				was = true
			end
			
			tos.x = math.Clamp(tos.x,100,sw-100)
			tos.y = math.Clamp(tos.y,100,sh-100)
			
			surface.SetMaterial(matlock_f)
			surface.SetDrawColor(color_white)
			surface.DrawTexturedRect(tos.x-16,tos.y-16,32,32)
			
			surface.SetMaterial(matlock)
			surface.SetDrawColor(keycol)
			surface.DrawTexturedRect(tos.x-16,tos.y-16,32,32)
		else
			was=false
		end
		
	end
	
	
end

local data = render.CreateOutlineData(.8, 1, Color(255,255,255,255))
-- hook.Add("PreDrawHalos","ass_highlightTarget",function()
hook.Add("PostDrawTranslucentRenderables","ass_highlightTarget",function(sky)
	if sky then return end
	
	local ply = LocalPlayer()
	
	//Highlight priority: use target, lock ent, trace target.
	local ent = hook.Run("FindUseEntity", ply)
	ent = IsValid(ent) and ent or ply:GetLockEnt()
	ent = IsValid(ent) and ent or ply:GetEyeTraceInaccurate().Entity
	
	//Action key highlighting
	local vis = false
	if IsValid(ent) then
		
		//Is this an entity which we can highlight?
		local text, vec
		if isfunction(ent.ActionKeyHover) then
			vis, text, vec = ent:ActionKeyHover() //Create this on your ent to accept action key hovers
		else
			vis, text, vec = hook.Run("ASSActionKeyHover",ent)
		end
		
		if ent:GetPos():DistToSqr(ply:GetPosAutoPilot()) < GetConVarNumber("ass_use_dist")^2 then
			hud.SetActionKey(vis,text,vec)
		else
			hud.SetActionKey(false)
		end
		
		if vis then
		
			render.RenderOutline(ent, data)
			-- halo.Add( {ent}, Color(255,255,255), 1, 1, 1, true, false )
		end
	else
		hud.SetActionKey(false)
	end
	
	
	//Group highlighting
	-- local pos = (ply:GetAutoPilot() and IsValid(ply:GetAutoPilot()) and !ply:GetAutoPilot():GetDisabled()) and ply:GetAutoPilot():GetPos() or ply:GetPos()
	-- local lead = GetNearestGroup(pos)
	-- if IsValid(lead) then
		-- local e = {}
		-- for k,v in pairs(ALL_CIVS) do
			-- if v:GetGroupLeader() == lead and !v:GetDisabled() and v != LocalPlayer():GetAutoPilot() and (not vis or v != ent) then
				-- table.insert(e,v)
			-- end
		-- end
		-- halo.Add( e, Color(0,145,255), 1, 1, 1, true, false )
	-- end
	
	
end)

--[[ TOO EXPENSIVE:
-- local function isClockwise(poly)
	-- local sum = 0
	-- local count = #poly
    -- for i=1, count-1 do
        -- local cur = poly[i]
        -- local next = poly[i+1]
        -- sum = sum + (next.x - cur.x) * (next.y + cur.y)
    -- end
    -- return sum > 0
	
-- end

-- local webmat = Material("assassins/web.png","unlitgeneric smooth")
-- local circlemat = Material("assassins/circle_bord.png", "unlitgeneric smooth")
-- hook.Add("PreDrawEffects","ass_groupcircles",function()
	
	-- local ply = LocalPlayer()
	-- local pos = ply:GetPosAutoPilot()
	-- local lead = GetNearestGroup(pos)
	-- if IsValid(lead) then
		
		-- render.SetMaterial(circlemat)
		
		
		-- local followers = {}
		-- -- local s = 8
		-- for k,p in pairs(player.GetAll()) do
			-- if p:Alive() and (!IsValid(p:GetAutoPilot()) or p:GetAutoPilot():GetDisabled()) and p:GetPos():DistToSqr(lead:GetPos()) < 160^2 then 
				-- table.insert(followers,p) 
				-- render.DrawQuadEasy( p:GetPos(), Vector(0,0,1), 32, 32, keycol_trans )
			-- end
		-- end
		
		
		-- for k,v in pairs(ALL_CIVS) do
			-- -- if v:GetMode() == 1 and !v:GetDisabled() then
			-- if v:GetGroupLeader() == lead and !v:GetDisabled() and v:GetPos():DistToSqr(lead:GetPos()) < 160^2  then
				-- table.insert(followers,v)
				
				-- render.DrawQuadEasy( v:GetPos(), Vector(0,0,1), 32, 32, keycol_trans )
				
			-- end
		-- end
		
		-- //Neat effect:
		-- render.SetColorMaterial()
		-- stencil.Push()
			-- stencil.Clear()
			-- stencil.Enable(true)
			-- stencil.Reference(1)
			-- stencil.Mask(255)
			-- stencil.SetOperations(STENCIL_REPLACE,STENCIL_KEEP,STENCIL_KEEP)
			-- stencil.Compare(STENCIL_NOTEQUAL)
			
			-- local count = #followers
			-- if count > 2 then
				-- for k=1, count do
					-- for i=2, count do
						-- local poly = {}
						-- poly[1] = followers[k]:GetPos() + Vector(0,0,5.2)
						-- poly[2] = followers[i]:GetPos() + Vector(0,0,5.1)
						-- poly[3] = (i+1 > count and followers[1] or followers[i+1]):GetPos() + Vector(0,0,5)
						-- poly[4] = (i+2 > count and followers[(i+2 - count)] or followers[i+2]):GetPos() + Vector(0,0,5)
						
						-- if isClockwise(poly) then
							-- render.DrawQuad( poly[1], poly[2], poly[3], poly[4], keycol_trans )
						-- else
							-- render.DrawQuad( poly[4], poly[3], poly[2], poly[1], keycol_trans )
						-- end
					-- end
				-- end
			-- end
			
			-- stencil.Pass(STENCIL_REPLACE)
			-- stencil.Compare(STENCIL_EQUAL)
			
			-- render.SetMaterial(webmat)
			-- local w,h = 128,128
			-- for x = -w, w*2, w do
				-- for y = -h, h*2, h do
					-- local p = lead:GetPos()
					-- p.x = p.x + x
					-- p.y = p.y + y
					-- p.z = p.z + 20
					-- render.DrawQuadEasy( p, Vector(0,0,1), w, h, Color(255,255,255,100) )
				-- end
			-- end
			
			-- stencil.Enable(false)
		-- stencil.Pop()
		
	
	-- end
-- end)]]

--portrait x,y,w,h = 25, 47, 80, 100
function hud.RoundStateChanged(round,state) --called every time the round state changes.
    local sw, sh = ScrW(), ScrH()
    
	
	
end


 
//Elements:

//Use key
if hud.actionKey then hud.actionKey:Remove() end
hud.actionKey = vgui.Create("ass_ActionKey")
hud.actionKey:ParentToHUD()
hud.actionKey:SetVisible(false) 

--Convenience function
function hud.SetActionKey(vis,text,pos)
	if vis != nil then
		hud.actionKey:SetVisible(vis)
	end
	if pos then
		hud.actionKey:SetVector(pos)
	end
	if text then
		hud.actionKey:SetText(text)
	end
end

//Radar
if IsValid(hud.radar) then hud.radar:Remove() end
hud.radar = vgui.Create("ass_Radar")
hud.radar:ParentToHUD()
hud.radar:CenterHorizontal()
hud.radar:AlignBottom(150)

//Target
if IsValid(hud.target) then hud.target:Remove() end
hud.target = vgui.Create("ass_TargetModel")
hud.target:ParentToHUD()
hud.target:AlignRight(100)
hud.target:AlignTop(100)

//Convenience Function 
function hud.SetTarget(tar)
	hud.radar:SetTarget(tar)
	hud.target:SetTarget(tar)
end
if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetTarget()) then
	hud.SetTarget(LocalPlayer():GetTarget())
end

//Pursuers
if IsValid(hud.hunt) then hud.hunt:Remove() end
hud.hunt = vgui.Create("ass_HuntedBy")
hud.hunt:ParentToHUD()
hud.hunt:AlignLeft(100)
hud.hunt:AlignTop(100)

//Chasedby
hud.chasedby = hud.chasedby or {}
for i=1, ConVars.Server.maxPursuers:GetInt() do
	if IsValid(hud.chasedby[i]) then hud.chasedby[i]:Remove() end
	local bar = vgui.Create("ass_ChaseBar")
	bar:ParentToHUD()
	bar:AlignLeft(300)
	bar:AlignTop(280+bar:GetTall()*(i-1)+5*(i-1))
	bar:SetChasing(false)
	bar:SetPursuerNum(i)
	hud.chasedby[i] = bar
end

//Chasing
hud.chasing = vgui.Create("ass_ChaseBar")
hud.chasing:ParentToHUD()
hud.chasing:AlignRight(300)
hud.chasing:AlignTop(280)
hud.chasing:SetChasing(true)


//KillPoints
net.Receive("ass_killpoints",function()
	
	local scoretbl = {amt={},mod={}}
	for i=1,net.ReadUInt(8)do
		scoretbl.amt[i] = {net.ReadFloat(),net.ReadString()}
	end
	for i=1,net.ReadUInt(8)do
		scoretbl.mod[i] = {net.ReadFloat(),net.ReadString()}
	end
	
	hud.KillPoints(scoretbl)
	
end)
function hud.KillPoints(scoretbl)
	
	local score = vgui.Create("ass_ScoreTotal")
	score:ParentToHUD()
	score:SetPos(ScrW()/2+100,ScrH()/2-score:GetTall()*.8)
	score:StartAnim(scoretbl)
	
	timer.Simple(30,function()if IsValid(score) then score:Remove() end end)
	
end


--Fade In/Out
if not hud.BlackScreen then
	hud.BlackScreen = vgui.Create("Panel")
	-- hud.BlackScreen:ParentToHUD()
	hud.BlackScreen:SetSize(2*ScrW(),2*ScrH())
	hud.BlackScreen:SetPos(-ScrW()/2,-ScrH()/2)
	hud.BlackScreen.Alpha = 255
	hud.BlackScreen.Target = 255
	hud.BlackScreen.Time = 0
	hud.BlackScreen.Delta = 0
	function hud.BlackScreen:Paint(w,h)
		draw.NoTexture()
		surface.SetDrawColor(Color(0,0,0,self.Alpha))
		surface.DrawRect(0,0,w,h)
		
		if WAITING_FOR_PLAYERS then
			draw.SimpleText("NEED MORE PLAYERS. Run 'add_bot' in the console!","bobbleTitle32",w/2, 500, color_white, TEXT_ALIGN_CENTER)
		end
	end
	function hud.BlackScreen:Think()
		if self.Time <= 0 then
			self.Time = 0
			return
		end
		
		local dt = RealFrameTime()
		self.Time = self.Time - dt
		self.Alpha = math.Approach(self.Alpha, self.Target, (self.Delta * dt))
	end
end
function hud.FadeIn(time)
	hud.BlackScreen.Target = 0
	hud.BlackScreen.Delta = 255/time
	hud.BlackScreen.Time = time
end
function hud.FadeOut(time)
	hud.BlackScreen.Target = 255
	hud.BlackScreen.Delta = 255/time
	hud.BlackScreen.Time = time
end



