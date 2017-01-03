
grapp = grapp or {}

sound.Add( {
	name = "shoot_hook",
	channel = CHAN_WEAPON,
	volume = .4,
	level = 75,
	pitch = 100,
	sound = "bobble/grapple_hook/grappling_hook_shoot.mp3"
	-- sound = "weapons/crossbow/fire1.wav"
} )

if SERVER then
	function grapp.Fire(ply)
		autopilot.Interrupt(ply)
		
		if IsValid(ply:GetNW2Entity("ass_grapplehook")) then
			grapp.Finish(ply)
			return
		end
		
		local tr,trace = ply:GetEyeTraceAutoPilot(ConVars.Server.hookDist:GetFloat())
		local dest = grapp.ValidTarget(tr,trace)
		if !dest then
			return false
		end
		
		-- ply.GrappleEndpos = dest
		
		
		local ghook = ents.Create("ass_grapple_hook")
		ply:SetNW2Entity("ass_grapplehook",ghook)
		
		local ang = ply:GetAimVector():Angle()
		ang:RotateAroundAxis(ply:GetAimVector(),120)
		ang:RotateAroundAxis(ply:GetRight(),0)
		ang:RotateAroundAxis(ply:GetUp(),-90)
		
		ghook:SetOwner(ply)
		ghook:SetPos(ply:GetShootPos()-ply:GetAimVector()*10+ply:GetRight()*6)
		ghook:SetAngles(ang)
		ghook:Spawn()
		ghook:Activate()
		ghook:CreateRope()
		ghook:GetPhysicsObject():SetMass(1)
		ghook:GetPhysicsObject():EnableDrag(false)
		ghook:GetPhysicsObject():EnableGravity(false)
		ghook:GetPhysicsObject():ApplyForceCenter((tr.HitPos-ghook:GetPos()):GetNormalized()*1000)
		
		-- ghook:GetPhysicsObject():AddAngleVelocity( Vector(-100,0,0) )
		
		ply:EmitSound( "shoot_hook", 70,100,1,CHAN_WEAPON )
		
		return ghook
		
	end
	
	function grapp.Finish(ply,madeit)
		ply:SetMoveType(MOVETYPE_WALK)
		ply:SetAbsVelocity(Vector(0,0,0))
		
		local ghook = ply:GetNW2Entity("ass_grapplehook")
		if IsValid(ghook) then
			-- if madeit and ply.GrappleEndpos then
				-- ply:SetPos(ply.GrappleEndpos)
				-- ply.GrappleEndpos = nil
			--end
			
			if madeit then
				ply:SetPos(ghook:GetPos() + ghook:GetRight()*16 + Vector(0,0,48))
				
			end
			
			ply:SetNW2Entity("ass_grapplehook",NULL)
			ghook.grapplefinish = true
			ghook:Remove()
			
		end
		
		
	end
end

function grapp.ValidTarget(tr,trace)
	if tr.HitSky then return false end
	if tr.HitWorld or (IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_static") then
		if tr.HitPos.z < trace.start.z + 32 then
			return false
		end
		
		local uptrace = {}
		uptrace.start = tr.HitPos + tr.HitNormal*16 
		uptrace.endpos = uptrace.start + Vector(0,0,32)
		
		local uptr = util.TraceLine(uptrace)
		if uptr.Hit then return false end
		
		//Check if it's a ledge with room on top.
		local ledgetrace = {}
		ledgetrace.start = tr.HitPos + tr.HitNormal*16 + Vector(0,0,32)
		ledgetrace.endpos = ledgetrace.start - tr.HitNormal*16
		ledgetrace.mins = Vector(-16,-16,0)
		ledgetrace.maxs = Vector(16,16,72)
		ledgetrace.mask = MASK_PLAYERSOLID
		
		local ledgetr = util.TraceHull(ledgetrace)
		
		-- if CLIENT then
			-- debugoverlay.Line( tr.HitPos, ledgetrace.start, FrameTime()+.01, Color(0,0,255), false )
			-- debugoverlay.Line( ledgetrace.start, ledgetr.HitPos or ledgetrace.endpos, FrameTime()+.01, Color(0,0,255), false )
			-- debugoverlay.Box( ledgetrace.start, ledgetrace.mins, ledgetrace.maxs, FrameTime()+.01, Color(0,0,255, 100), false )
			-- if ledgetr.Hit then
				-- debugoverlay.Line( ledgetr.HitPos, ledgetrace.endpos, FrameTime()+.01, Color(255,0,0), false )
			-- end
			-- debugoverlay.Box(  ledgetr.HitPos or ledgetrace.endpos, ledgetrace.mins, ledgetrace.maxs, FrameTime()+.01, ledgetr.Hit and Color(255,0,0, 100) or Color(0,255,0, 100), false )
		-- end

		
		
		if !ledgetr.Hit then
			return ledgetr.HitPos
		else
			return false
		end
		
		
		
	end
	return false
end

hook.Add("Move","ass_grapplehook",function(ply,mv)
	
	local ghook = ply:GetNW2Entity("ass_grapplehook")
	if IsValid(ghook) and ghook.GetFlying and !ghook:GetFlying() then
		
		local speed = FrameTime()*540
		local newpos = mv:GetOrigin()
		-- local newvel = mv:GetVelocity()
		
		if SERVER then
			if newpos:DistToSqr(ghook:GetPos()) < 50^2 then
				mv:SetVelocity(Vector(0,0,0))
				timer.Simple(0,function()
					grapp.Finish(ply,true)
				end)
				return true
			end
		end
		
		local dir = (ghook:GetPos()-newpos):GetNormalized()
		-- newvel = newvel + dir * speed
		newpos = newpos + dir * speed
		
		-- mv:SetVelocity(newvel)
		mv:SetOrigin(newpos)
		mv:SetMoveAngles(dir:Angle())
		mv:SetAngles(dir:Angle())
		-- mv:SetOrigin(newpos+newvel*FrameTime())
		
		return true
		
	end
end)

if SERVER then
	concommand.Add("+ass_hook",function(ply,c,a)
		if ply:Team() == TEAM_ASS then
			if IsValid(ply:GetNW2Entity("ass_grapplehook")) then
				grapp.Finish(ply)
				ply.GrappCancel = true
			end
		end
	end)
	concommand.Add("-ass_hook",function(ply,c,a)
		if ply:Team() == TEAM_ASS then
			if not ply.GrappCancel then
				grapp.Fire(ply)
			else
				ply.GrappCancel = false
			end
		end
	end)
	
else
	

	function GM:OnSpawnMenuOpen()
		RunConsoleCommand("+ass_hook")
		LocalPlayer().AimingHook = true
	end
	function GM:OnSpawnMenuClose()
		RunConsoleCommand("-ass_hook")
		LocalPlayer().AimingHook = false
	end

end