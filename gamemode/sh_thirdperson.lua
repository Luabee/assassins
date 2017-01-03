




function GM:PlayerSpawn(ply)
	if !ply.UnSpec then
		if SERVER then
			self.BaseClass.PlayerSpawn(self,ply)
		
			
			if ply:Team() == TEAM_UNASSIGNED or ply:Team() == TEAM_SPECTATOR then
				GAMEMODE:PlayerSpawnAsSpectator( ply )
			end
		else
			if ply == LocalPlayer() then
				timer.Simple(.5,function()
					SetIntensity(1)
					hud.FadeIn(4)
				end)
			end
		end
		
		ply.DeathSeq = nil
		ply.AttackSeq = nil
	end
end

function GM:PlayerTick( ply, mv )
	
	if (CLIENT and ConVars.Client.autoCrouch:GetBool()) or (SERVER and ply:GetInfoNum("ass_auto_crouch",1)==1) then
		//Shift and jump activates crouch.
		-- if IsFirstTimePredicted() then
			if bit.band( mv:GetButtons(), IN_JUMP ) == IN_JUMP then
				if bit.band( mv:GetButtons(), IN_SPEED ) == IN_SPEED then
					mv:AddKey(IN_DUCK)
				end
			end
		-- end
	end
	
	//Heat generation
	if SERVER then
		local target = ply:GetTarget()
		if target:IsValid() and target:Alive() and !target.DeathSeq then
			local hl = ply:GetHeatLevel()
			if hl >= 3 then
			
				local old = ply:GetHeat()
				local new = math.min(100, old + 16.5 * FrameTime())
				ply:SetHeat(new)
				
			elseif ply:GetTargetEnt():IsLineOfSightClear(ply) and (mv:KeyDown(IN_SPEED) and (mv:KeyDown(IN_FORWARD) or mv:KeyDown(IN_BACK) or mv:KeyDown(IN_MOVELEFT) or mv:KeyDown(IN_MOVERIGHT) ) ) then
				local old = ply:GetHeat()
				local new = math.min(100, old + ConVars.Server.heatSpeed:GetFloat() * FrameTime())
				ply:SetHeat(new)
				
			elseif hl < 3 then
				
				local old = ply:GetHeat()
				local new = math.max(0, old - ConVars.Server.heatRecover:GetFloat() * FrameTime())
				ply:SetHeat(new)
				
			end
			
		end 
	
		if ply:Alive() and not util.IsInWorld(ply:GetPosAutoPilot()) then
			ply.outworld = (ply.outworld or 0) + 1
			if ply.outworld > 100 then
				ply:KillSilent()
				MsgC(Color(255,20,20),ply:Nick().." WAS OUT OF WORLD! Respawning them...\n")
				ply.outworld = -100
			end
		else
			ply.outworld = 0
		end
	end
	
end

//Calc third person view.
function GM:CalcView(ply, origin, angles, fov, znear, zfar)
	local view = {
		drawhud=true,
		dopostprocess=true,
		drawmonitors=true,
	}
	
	if ply.Zoomed and fov then
		fov = fov - 30
	end
	
	local npc = ply:GetObserverTarget()
	if IsValid(npc) then
		
		origin = npc:GetPos() + Vector(0,0,78)
		local trace = {start=origin, endpos=origin +angles:Forward()*-100,filter={ply,npc},mask=MASK_OPAQUE,mins=Vector(-5,-5,-5),maxs=Vector(5,5,5)}
		local tr = util.TraceHull(trace)
		
		view.origin = tr.Hit and tr.HitPos or trace.endpos
		view.angles = angles
		view.fov = fov
		view.drawviewer = false
		
	elseif ply:GetObserverMode() == OBS_MODE_ROAMING then
	
		view.origin = origin
		view.angles = angles
		view.fov = fov
		view.drawviewer = false
		
	else
	
		local trace = {start=origin, endpos=origin + Vector(0,0,14) + angles:Forward()*-100,filter=ply,mask=MASK_OPAQUE,mins=Vector(-10,-10,-10),maxs=Vector(10,10,10)}
		local tr = util.TraceHull(trace)
		
		view.origin = tr.Hit and tr.HitPos or trace.endpos
		view.angles = angles
		view.fov = fov
		view.drawviewer = true
	end
	
	-- if ply.lastOrigin then
		-- view.origin.x = math.Approach(ply.lastOrigin.x,view.origin.x,100*FrameTime())
		-- view.origin.y = math.Approach(ply.lastOrigin.y,view.origin.y,100*FrameTime())
		-- view.origin.z = math.Approach(ply.lastOrigin.z,view.origin.z,100*FrameTime())
		
		-- view.angles.p = math.ApproachAngle(ply.lastAngs.p,view.angles.p,100*FrameTime())
		-- view.angles.y = math.ApproachAngle(ply.lastAngs.y,view.angles.y,100*FrameTime())
		-- view.angles.r = math.ApproachAngle(ply.lastAngs.r,view.angles.r,100*FrameTime())
		
	-- end
	-- ply.lastOrigin = view.origin
	-- ply.lastAngs = view.angles
	
	return view
end


