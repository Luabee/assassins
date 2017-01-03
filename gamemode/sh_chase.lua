
chase = chase or {}

chase.chases = chase.chases or {}

sound.Add({
	name = "ass_chase_losing",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = 100,
	sound = "assassins/losing_target.wav"
})
sound.Add({
	name = "ass_chase_hiding",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = 100,
	sound = "assassins/hiding.wav"
})

local meta = FindMetaTable("Player")

function meta:BeingChasedBy(ply)
	return ply:IsChasing() and ply:GetTarget() == self
end
function meta:BeingChased()
	for k,v in pairs(self.Pursuers) do
		if !IsValid(v) then continue end
		if v:IsChasing() then return true end
	end
	return false
end
function meta:IsChasing()
	return self:GetChase() > 0
end

function meta:GetChase()
	return self:GetNW2Float("ass_getaway",0)
end
function meta:SetChase(new)
	self:SetNW2Float("ass_getaway",math.Clamp(new,0,100))
end



function chase.IsDegrading(ply,victim)
	local ap = victim:GetAutoPilot()
	return (IsValid(ap) and !ap:GetDisabled()) or not victim:GetEnt():IsLineOfSightClear(ply)
end

function chase.Begin(ply,victim)
	if !IsValid(ply) then return end
	if ply:IsChasing() then chase.Finish(ply,victim) end
	
	ply:SetChase(100)
	chase.chases[ply]=victim
	victim:SetIntensity(5)
	
	hook.Run("ASSChaseStart",ply,victim)
	
end

function chase.Finish(ply,victim,failure)
	if !IsValid(ply) and !IsValid(victim) then return end
	if ply:IsChasing() or failure then
		
		hook.Run("ASSChaseEnd",ply,victim)
		
		ply:SetChase(0)
		chase.chases[ply] = nil
		
		if failure then
			if SERVER then
				DelayNewTarget(ply)
				ply:SetIntensity(1)
				victim:SetIntensity(1)
			end
		end
		
		if CLIENT then
			if ply == LocalPlayer() then
				LocalPlayer():StopSound("ass_chase_losing")
			elseif victim == LocalPlayer() then
				LocalPlayer():StopSound("ass_chase_hiding")
			end
		end
		
	end
	
	
end
	

function chase.Tick()
	for k,v in pairs(chase.chases)do
		local ply,victim = k,v
		if IsValid(ply) and IsValid(victim) then
			if ply:Alive() and victim:Alive() then
				if ply:GetTarget() == victim then
				
					local ch = ply:GetChase()
					if ch <= 0 then chase.chases[k] = nil continue end
					
					if chase.IsDegrading(ply,victim) then
						local new = ch - (100/ConVars.Server.chaseSpeed:GetFloat()) * engine.TickInterval()
						ply:SetChase(new)
						
						if new <= 0 then
							chase.Finish(ply,victim,true)
						end
						
					else
						ply:SetChase(100)
					end
					
				else
					chase.Finish(ply,victim,true)
				end
			else
				chase.Finish(ply,victim,true)
			end
			
		elseif ply:IsValid() then
			chase.Finish(ply,victim,true)
		else
			chase.chases[ply] = nil
		end
		
	end
end
hook.Add("Tick","ass_chase",chase.Tick)
