
GM.Name 	= "Assassins"
GM.Author 	= "Bobblehead and Gambit"
GM.Email 	= "luabeegaming@gmail.com"
GM.Website 	= "http://luabee.com/"

DeriveGamemode("base")

//DEBUG:
-- RCC = RunConsoleCommand

//Convars:
ConVars = {}
	ConVars.Server = {}
	ConVars.Server.firstprep = CreateConVar("ass_firstpreptime", 30, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Sets the time before the first round starts.")
	ConVars.Server.prep = CreateConVar("ass_preptime", 10.8, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Sets the time before the round starts.")
	ConVars.Server.post = CreateConVar("ass_posttime", 10.8, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Sets the time after the round starts.")
	ConVars.Server.active = CreateConVar("ass_activetime", 60*5, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Sets the time that the round runs.")
	
	ConVars.Server.civCount = CreateConVar("ass_bystand_count", 30, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many bystanders/groups should be on the map at once.")
	ConVars.Server.groupSize = CreateConVar("ass_group_size", 3, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Max bystanders in a single group.")
	ConVars.Server.groupMaxSize = CreateConVar("ass_group_size_max", 4, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "New bystanders won't enter a group of this size.")
	
	ConVars.Server.respawnTime = CreateConVar("ass_respawn_time", 7, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How long it takes to respawn.")
	ConVars.Server.newTargetDelay = CreateConVar("ass_new_target_delay", 5, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How long it takes to get a new target after an assassination (failed or successful).")
	ConVars.Server.minDist = CreateConVar("ass_min_target_dist", 300, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Minimum distance a player must be from their new target.")
	
	ConVars.Server.useDist = CreateConVar("ass_use_dist", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How far a player can use/assassinate objects from.")
	ConVars.Server.lockLoseTime = CreateConVar("ass_lock_lose_time", 3.8, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How long before a locked target is lost due to line of sight.")
	ConVars.Server.heatSpeed = CreateConVar("ass_heat_speed", 33, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How much heat is generated per second of high activity.")
	ConVars.Server.heatRecover = CreateConVar("ass_heat_recovery_speed", 33/4, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How much heat per second is lost when out of sight before entering audacious.")
	
	ConVars.Server.stunDur = CreateConVar("ass_stun_time", 4.5, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How long a player is stunned for.")	
	ConVars.Server.stunCD = CreateConVar("ass_stun_cooldown", 3, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How long after being stunned before a player can be stunned again. Prevents stun-spamming.")
	
	ConVars.Server.maxPursuers = CreateConVar("ass_max_pursuers", 4, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many people can pursue one target. MAX 4 OR HUD WILL BREAK.")
	ConVars.Server.multiPursue = CreateConVar("ass_multi_pursue_time", 60*2, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many seconds before multiple people are assigned to the higher-ranked players.")
	
	ConVars.Server.hookDist = CreateConVar("ass_grapple_hook_dist", 1050, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Distance that a player's grapple hook can go.")

	ConVars.Server.scoreBase = CreateConVar("ass_score_base", 100, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How much score a player gets for killing  someone, before multipliers and additions.")
	ConVars.Server.scoreSneak = CreateConVar("ass_score_sneak", 50, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many points are given for sneakiness. At silent, this is multiplied by 3; at discrete, this multiplied by 2; at audacious, this is multiplied by 1; and at reckless this is multiplied by 0.")
	ConVars.Server.scoreSpree = CreateConVar("ass_score_spree", 1.25, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "Score multiplier for killing spree.")
	ConVars.Server.spreeSize = CreateConVar("ass_spree_size", 4, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many kills constitutes a killing spree.")
	
	ConVars.Server.chaseSpeed = CreateConVar("ass_chase_loserate", 8, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE}, "How many seconds it takes for a chase to end while the victim is out of sight or blended. ")
	
if CLIENT then
	ConVars.Client = {}
	ConVars.Client.autoCrouch = CreateClientConVar("ass_auto_crouch", 1, true, true, "Whether to automatically crouch while jumping and sprinting.")
	ConVars.Client.music = CreateClientConVar("ass_music", 1, true, false, "Whether to play music.")
end

hook.Remove("PlayerTick","TickWidgets")

function GM:Initialize()

	self.BaseClass.Initialize( self )
	
	WAITING_FOR_PLAYERS = true --until first player joins.
	
	RunConsoleCommand("mp_show_voice_icons",0)
	
end

function GM:OnEntityCreated( ent )
	if ent:IsPlayer() then
		ent:InstallDataTable()
		ent:NetworkVar("Int", 1, "Spree")
		ent:NetworkVar("Float", 1, "Chase")
		ent:NetworkVar("Float", 2, "Score")
		ent.Pursuers = {}
	end
	if SERVER then
		if ent:GetClass():find("door") then //No doors!
			ent:Remove()
		end
		if ent:IsPlayer() then
			function ent:UpdateTransmitState()
				return TRANSMIT_ALWAYS
			end
		end
	end
end

function GM:PlayerDefinition(ply)
	if SERVER then
		timer.Simple(1.6,function()
			-- BroadcastLua([[Player(]]..ply:UserID()..[[):SetLOD(2)]])
			
			net.Start("ass_roundstate")
				net.WriteUInt(CURRENT_STATE.number,4)
				net.WriteUInt(CURRENT_ROUND,16)
				net.WriteBool(true)
				net.WriteFloat(ROUND_START_TIME)
			net.Send(ply)
		end)
		for k,v in pairs(ConVars.Server) do
			RunConsoleCommand(v:GetName(),v:GetString()) --Sync replicated convars
		end
		
			
		net.Start("ass_syncroundstates")
			net.WriteTable(ROUND_STATE)
		net.Send(ply)
		
	else
		-- timer.Simple(1,function()
			-- if CURRENT_STATE.number == 2 then
				-- hud.FadeIn(3)
			-- end
		-- end)
	end
	
	ply:SetNWVarProxy( "ass_heat", function(a,b,c,d)GAMEMODE:ASSPlayerHeatChanged(a,c,d) end )
	ply:SetWalkSpeed(100)
	ply:SetRunSpeed(270)
	ply:SetJumpPower(195)
end

function player.GetScoreSorted(t)
	local tbl
	if t then
		tbl = team.GetPlayers(t)
	else
		tbl = player.GetAll()
	end
	table.sort(tbl,function(a,b)
		return a:GetScore() > b:GetScore()
	end)
	return tbl
end

-- hook.Add("EntityEmitSound","ass_nofallsound",function(data)
	-- if data.OriginalSoundName == "Player.FallDamage" then
		-- return false
	-- end
-- end)

//Prevent crashes, reduce lag:
function FreezeAllProps()
	//Freeze props.
	for k,v in pairs(ents.FindByClass("prop_physics*")) do
		if v:IsValid() and v:GetPhysicsObject():IsValid() then
			v:GetPhysicsObject():EnableMotion(false)
		end
	end
end
hook.Add("PreCleanupMap","ass_cleanupMap",function()
	CLEAN_UP = true
end)
hook.Add("PostCleanupMap","ass_cleanupMap",function()
	CLEAN_UP = false
	FreezeAllProps()
end)
hook.Add("ShutDown","ass_endmap",function()
	CLEAN_UP = true
end)
hook.Add("InitPostEntity","ass_freezeprops",FreezeAllProps)

local SwingSound = Sound( "WeaponFrag.Throw" )
//This is the death sequence. Kills the target, plays anims, calls hooks.
function Assassinate(ent,attacker,deathseq,attseq)
	
	if CURRENT_STATE.number != 2 then return end
	if not IsValid(ent) then return end
	if not IsValid(attacker) then return end
	
	//Pull players out of npc's
	if SERVER then
		if IsValid(ent:GetNW2Entity("ass_player")) then
			autopilot.Interrupt(ent:GetNW2Entity("ass_player"))
			ent = ent:GetNW2Entity("ass_player")
		end
		
	end
	
	//Set sequences
	attacker.AttackSeq = attseq or table.RandomSeq(ATTACK_POSES)
	deathseq = deathseq or table.RandomSeq(DEATH_POSES)
	
	//Perform class-specific death
	if ent:IsPlayer() then
		
		
		print(attacker:Nick().. " assassinated " ..ent:Nick())
		chase.Finish(attacker,ent)
		
		if SERVER then
			-- ent:SetEyeAngles((attacker:GetPos()-(ent:GetPos()+Vector(0,0,32))):Angle())
			ent:Freeze(true)
		end
		
		ent.DeathSeq = "seq_preskewer"
		ent:SetSequence(ent.DeathSeq)
		ent:AnimRestartMainSequence()
		
		timer.Simple(.20, function()
			if IsValid(ent) then
				
				if SERVER then
					local sn = table.RandomSeq(DEATH_SOUNDS[ent:GetGender()])
					ent:EmitSound(sn)
				end
				
				ent.DeathSeq = deathseq
				ent:SetSequence(ent.DeathSeq)
				ent:AnimRestartMainSequence()
				if SERVER then
					timer.Simple(ent:SequenceDuration()*.9,function()
						if IsValid(ent) then
							ent:Freeze(false)
							ent:TakeDamage( ent:Health(), attacker, attacker )
						end
					end)
				else
					if ent == LocalPlayer() then
						hud.FadeOut(3)
						SetIntensity(0)
					end
				end
			end
		end)
	else
		ent.DeathSeq = deathseq
		print(attacker:Nick().." killed a bystander.")
		
		hook.Run("PlayerKillBystander",attacker,ent)
		
		ent.Killer = attacker
		ent:SetSequence(ent.DeathSeq)
		if SERVER then
			ent:Dissolve(attacker)
		end
	end
	
	//Play attacker anim
	if attacker:IsPlayer() then //Why wouldn't they be?
		
		autopilot.Interrupt(attacker)
		attacker:SetSequence(attacker.AttackSeq)
		attacker:SetPlaybackRate(2)
		attacker:AnimRestartMainSequence()
		
		if SERVER then
			-- attacker:SetEyeAngles((ent:GetPos()-(attacker:GetPos()+Vector(0,0,32))):Angle())
		end
		
		attacker:EmitSound("weapons/knife/knife_deploy1.wav")
		
		timer.Simple(attacker:SequenceDuration()*.8-.2,function()
			if IsValid(attacker) then
				if SERVER then
					attacker:SetLock(NULL)
					-- attacker:StripWeapon("weapon_ass_fakeknife")
					attacker:Freeze(false)
					attacker:SetPlaybackRate(1)
				else
					if attacker == LocalPlayer() then
						hud.SetTarget(NULL)
					end
					if IsValid(attacker.fakeknife) then
						attacker.fakeknife:Remove()
					end
				end
				attacker.AttackSeq = nil
			end
		end)
		
		if SERVER then
			//Knife-in-the-hand and movement lock
			-- attacker:SetActiveWeapon(attacker:Give("weapon_ass_fakeknife"))
			
			attacker:Freeze(true)
		else
			attacker.fakeknife = ClientsideModel("models/weapons/w_knife_t.mdl")
			attacker.fakeknife:SetParent(attacker)
			attacker.fakeknife:AddEffects(EF_BONEMERGE)
		end
		
		//swing sound
		attacker:EmitSound(SwingSound)
		timer.Simple(.20, function()
			if IsValid(attacker) and IsValid(ent) then
				if CLIENT then
					if attacker == LocalPlayer() then
						SetIntensity(1)
					end
				else
					if ent:IsPlayer() then
						attacker:EmitSound(table.RandomSeq(STAB_SOUNDS), 65)
					else
						attacker:EmitSound(table.RandomSeq(BYSTAND_DISSOLVE_SOUNDS), 65)
					end
				end
			end
		end)
	end
	
	//Sync to clients
	if SERVER then
		net.Start("ass_assassinated")
			net.WriteEntity(ent)
			net.WriteEntity(attacker)
			net.WriteString(deathseq)
			net.WriteString(attacker.AttackSeq)
		net.Broadcast()
	end
end

function Stun(ent,attacker)
	
	if CURRENT_STATE.number != 2 then return end
	if not IsValid(ent) then return end
	if not IsValid(attacker) then return end
	
	
	
	//Pull players out of npc's
	if SERVER then
		if IsValid(ent:GetNW2Entity("ass_player")) then
			autopilot.Interrupt(ent:GetNW2Entity("ass_player"))
			ent = ent:GetNW2Entity("ass_player")
		end
		
		-- attacker:EmitSound("weapons/knife/knife_deploy1.wav")
	end
	
	if ent:GetNW2Bool("ass_stunned",false) then return end
	if (ent.laststunnedtime or 0) + ConVars.Server.stunCD:GetFloat() > CurTime() then return end
	
	//Set sequences
	attacker.AttackSeq = attseq or table.RandomSeq(ATTACK_POSES)
	ent.DeathSeq = deathseq or table.RandomSeq(STUN_POSES)
	
	//Perform stun sequences and effects
	if ent:IsPlayer() then
		print(attacker:Nick().." stunned "..ent:Nick())
		autopilot.Interrupt(ent)
		
		ent:SetSequence(ent.DeathSeq)
		ent:AnimRestartMainSequence()
		-- ent:SetEyeAngles((attacker:GetPos()-(ent:GetPos()+Vector(0,0,32))):Angle())
		
		ent:Freeze(true)
		ent:SetNW2Bool("ass_stunned",true)
		
		timer.Simple(.20, function()
			if IsValid(ent) then
				if SERVER then
					DelayNewTarget(ent)
				end
				timer.Simple(GetConVarNumber("ass_stun_time"),function()
					if IsValid(ent) then
						ent.DeathSeq = nil
						if SERVER then
							ent.laststunnedtime = CurTime()
							ent:Freeze(false)
							ent:SetNW2Bool("ass_stunned",false)
						end
					end
				end)
				
			end
		end)
	end
	
	//Play attacker anim
	if attacker:IsPlayer() then //Why wouldn't they be?
		
		autopilot.Interrupt(attacker)
		attacker:SetSequence(attacker.AttackSeq)
		attacker:SetPlaybackRate(2)
		attacker:AnimRestartMainSequence()
		-- attacker:SetEyeAngles((ent:GetPos()-(attacker:GetPos()+Vector(0,0,32))):Angle())
		
		timer.Simple(attacker:SequenceDuration()*.8-.2,function()
			if IsValid(attacker) then
				if SERVER then
					attacker:SetLock(NULL)
					attacker:Freeze(false)
				end
				attacker.AttackSeq = nil
			end
		end)
		
		if SERVER then
			//movement lock
			attacker:Freeze(true)
			
			//swing sound
			attacker:EmitSound(SwingSound)
			timer.Simple(.20, function()
				if IsValid(attacker) and IsValid(ent) then
					attacker:EmitSound(table.RandomSeq(STUN_SOUNDS), 65)
				end
			end)
		end
	end
	
	
	//Sync to clients
	if SERVER then
		net.Start("ass_stunned")
			net.WriteEntity(ent)
			net.WriteEntity(attacker)
			net.WriteString(ent.DeathSeq)
			net.WriteString(attacker.AttackSeq)
		net.Broadcast()
	end
end

function BreakGlass(ent,ply,attseq)
	ply.AttackSeq = attseq or table.RandomSeq(ATTACK_POSES)
	
	if SERVER then
		autopilot.Interrupt(ply)
		
		//Knife-in-the-hand and movement lock
		ply:Give("weapon_ass_fakeknife")
		ply:SetActiveWeapon(ply:GetWeapon("weapon_ass_fakeknife"))
		ply:Freeze(true)
		
		//swing sound
		ply:EmitSound(SwingSound)
		timer.Simple(.25, function()
			if IsValid(ent) then
				//Break glass
				ent:Fire("break")
			end
		end)
		
		net.Start("ass_glassbreak")
			net.WriteEntity(ply)
			net.WriteString(ply.AttackSeq)
		net.Broadcast()
	end
	
	ply:SetSequence(ply.AttackSeq)
	ply:SetPlaybackRate(2)
	ply:AnimRestartMainSequence()
	timer.Simple(ply:SequenceDuration()*.8-.2,function()
		if IsValid(ply) then
			if SERVER then
				ply:StripWeapon("weapon_ass_fakeknife")
				ply:Freeze(false)
			end
			ply.AttackSeq = nil
		end
	end)
	
end

if CLIENT then
	net.Receive("ass_glassbreak",function()
		local attacker = net.ReadEntity()
		local aseq = net.ReadString()
		BreakGlass(nil,attacker,aseq)
	end)
	
	net.Receive("ass_assassinated",function()
		local ent = net.ReadEntity()
		local attacker = net.ReadEntity()
		local dseq = net.ReadString()
		local aseq = net.ReadString()
		Assassinate(ent,attacker,dseq,aseq)
	end)
	net.Receive("ass_stunned",function()
		local ent = net.ReadEntity()
		local attacker = net.ReadEntity()
		local dseq = net.ReadString()
		local aseq = net.ReadString()
		Stun(ent,attacker,dseq,aseq)
	end)
end

function GM:ASSPlayerHeatChanged(ply,old,new)
	
	local olevel,nlevel = ply:GetHeatLevel(old),ply:GetHeatLevel(new)
	
	if nlevel != olevel then
		if CLIENT then
			if nlevel == 1 then
				SetIntensity(2)
			elseif nlevel == 2 then
				SetIntensity(3)
			elseif nlevel == 3 then
				SetIntensity(4)
			end
			
		else
		
			if nlevel == 4 then
				chase.Begin(ply,ply:GetTarget())
			end
		end
		
	end
	
	return true
	
end

function GM:ASSCanPlayerLock(ply,ent)
	local class = ent:GetClass()
	if class == "npc_walking" then
		if not IsValid(ent:GetNW2Entity("ass_player")) then
			return true
		elseif ent.Player == ply:GetTarget() then
			return true
		else--if ent.Player:GetTarget() == ply then
			return true
		end
	elseif ent:IsPlayer() then
		if ply:GetTarget() == ent then
			return true
		else--if ent:GetTarget() == ply then
			return true
		end
	end
end

function GM:FindUseEntity(ply, def)
	
	local usedist = GetConVarNumber("ass_use_dist")
	local lock = ply:GetLockEnt()
	if IsValid(lock) then
		if ply:GetPosAutoPilot():DistToSqr(lock:GetPos()) <= usedist^2 then
			//Return lock whenever we can.
			return lock
		end
	else
		local tr = ply:GetEyeTraceInaccurate(usedist)
		
		//Else get ent at trace
		if tr.HitNonWorld and IsValid(tr.Entity) then
			return tr.Entity
		end
		
	end
	return def
	
end

function GM:PlayerNoClip( ply, desiredState )
	return ply:IsAdmin()
end


//Copied the base gamemode code and added the dying/attacking clause
function GM:CalcMainActivity( ply, velocity )
	
	ply.CalcIdeal = ACT_MP_STAND_IDLE
	
	if ply.DeathSeq then
		ply.CalcSeqOverride = ply:LookupSequence(ply.DeathSeq)
	elseif ply.AttackSeq then
		ply.CalcSeqOverride = ply:LookupSequence(ply.AttackSeq)
	elseif ply.ClimbSeq then
		ply.CalcSeqOverride = ply:LookupSequence(ply.ClimbSeq)
	else
		ply.CalcSeqOverride = -1
	end

	self:HandlePlayerLanding( ply, velocity, ply.m_bWasOnGround )

	if not ( self:HandlePlayerNoClipping( ply, velocity ) ||
		self:HandlePlayerDriving( ply ) ||
		self:HandlePlayerVaulting( ply, velocity ) ||
		self:HandlePlayerJumping( ply, velocity ) ||
		self:HandlePlayerSwimming( ply, velocity ) ||
		self:HandlePlayerDucking( ply, velocity ) ) then

		local len2d = velocity:Length2D()
		if ( len2d > 150 ) then ply.CalcIdeal = ACT_MP_RUN elseif ( len2d > 0.5 ) then ply.CalcIdeal = ACT_MP_WALK end

	end
	
	if ( ply:GetMoveType() == MOVETYPE_NOCLIP ) then
		local ghook = ply:GetNW2Entity("ass_grapplehook")
		if IsValid(ghook) and ghook.GetFlying and !ghook:GetFlying() then
			ply.CalcIdeal = ACT_MP_JUMP
		end
	end
	
	ply.m_bWasOnGround = ply:IsOnGround()
	ply.m_bWasNoclipping = ( ply:GetMoveType() == MOVETYPE_NOCLIP && !ply:InVehicle() )

	return ply.CalcIdeal, ply.CalcSeqOverride

end


//Returns the nearest group leader.
function GetNearestGroup(pos,dist)
	if CLIENT and IsValid(LocalPlayer():GetAutoPilot()) and !LocalPlayer():GetAutoPilot():GetDisabled() and IsValid(LocalPlayer():GetAutoPilot():GetGroupLeader()) then return LocalPlayer():GetAutoPilot():GetGroupLeader() end
	
	local found = false
	local dist = dist or 150^2
	for k,v in pairs(ents.FindByClass("npc_group_leader"))do
		local d = (v:GetPos()-pos):LengthSqr()
		if d < dist then
			found = v
			dist = d
		end
	end
	return found
end

local meta = FindMetaTable("Player")
function meta:GetEyeTraceAutoPilot(dist)--Eye trace which includes your autopilot.
	local trace = {}
	trace.mask = MASK_SHOT
	
	local view = GAMEMODE:CalcView(self, self:EyePos(), self:EyeAngles())
	trace.start = view.origin
	trace.endpos = trace.start + view.angles:Forward()*((dist or 16000)+100)
	
	-- trace.start=(self:GetAutoPilot() and IsValid(self:GetAutoPilot()) and !self:GetAutoPilot():GetDisabled()) and self:GetAutoPilot():GetPos() + Vector(0,0,64) or self:GetShootPos()
	-- trace.endpos=trace.start+self:GetAimVector()*(dist or 16000)
	
	trace.filter={self,self:GetAutoPilot()}
	
	local tr = util.TraceLine(trace)
	-- debugoverlay.Line(trace.start,tr.HitPos,FrameTime()+.01,Color(255,0,0))
	
	return tr,trace
end
function meta:GetEyeTraceInaccurate(dist) --A larger trace for reduced accuracy requirements. Somewhat expensive.
	local spread = 3
	local tr,trace = {},{}
	
	local view = GAMEMODE:CalcView(self, self:EyePos(), self:EyeAngles())
	
	for offset=0, 16, spread do
		
		trace.mask = MASK_SHOT
		trace.start=view.origin
		trace.start=trace.start + self:EyeAngles():Right() * -offset
		trace.endpos=trace.start + view.angles:Forward()*((dist or 16000)+100)
		trace.filter={self,self:GetAutoPilot()}
		
		tr = util.TraceLine(trace)
		-- debugoverlay.Line(trace.start,tr.HitPos or trace.endpos,FrameTime()+.01,Color(255,0,0))
		if tr.HitNonWorld then
			return tr, trace
		end
		
		trace.mask = MASK_SHOT
		trace.start=view.origin
		trace.start=trace.start + self:EyeAngles():Right() * offset
		trace.endpos=trace.start + view.angles:Forward()*((dist or 16000)+100)
		trace.filter={self,self:GetAutoPilot()}
		
		tr = util.TraceLine(trace)
		-- debugoverlay.Line(trace.start,tr.HitPos or trace.endpos,FrameTime()+.01,Color(255,0,0))
		if tr.HitNonWorld then
			return tr,trace
		end
		
	end
	
	return tr,trace
end
function meta:GetPosAutoPilot()
	if self:GetAutoPilot() and IsValid(self:GetAutoPilot()) and !self:GetAutoPilot():GetDisabled() then
		return self:GetAutoPilot():GetPos()
	else
		return self:GetPos()
	end
end

//If noretry is nil, we will keep trying to assign every second till we succeed. use true if you're trying to clear the target.
function meta:SetTarget(target,noretry)

	if target != self.AssassinTarget then
		chase.Finish(self,self.AssassinTarget)
	end
	
	if SERVER then
		if not IsValid(target) then
			if not noretry then
				-- print("Couldn't find a valid target for "..self:Nick()..". Retrying in 1 second...")
				DelayNewTarget(self,1)
				return
			end
		end
	end
	
	
	if IsValid(self.AssassinTarget) then //if we had an old one, remove ourselves.
		self.AssassinTarget.Pursuers = self.AssassinTarget.Pursuers or {}
		table.RemoveByValue(self.AssassinTarget.Pursuers,self)
	end
	if IsValid(target) then //add ourselves to the new.
		target.Pursuers = target.Pursuers or {}
		table.insert(target.Pursuers,self)
	end
	
	self:SetHeat(0)
	
	self.AssassinTarget = target
	hook.Run("ASSPlayerTargetAssigned",self,target)
	if SERVER then
		net.Start("ass_playertarget")
			net.WriteEntity(self)
			net.WriteEntity(target)
		net.Broadcast()
	elseif self == LocalPlayer() then
		hud.SetTarget(target)
	end
end
function meta:GetTarget()
	return self.AssassinTarget or NULL
end
function meta:GetTargetEnt() //Returns autopilot if it's valid, otherwise player.
	local target = self:GetTarget()
	if IsValid(target) then
		local ap = target:GetAutoPilot()
		if IsValid(ap) and !ap:GetDisabled() then
			return ap
		else
			return target
		end
	else
		return NULL
	end
end
net.Receive("ass_playertarget",function()
	local ply, target = net.ReadEntity(),net.ReadEntity()
	-- if not(IsValid(target) and IsValid(ply)) then
		-- MsgC(Color(200,80,80),"Couldn't assign a target to a player: "..tostring(ply).." "..tostring(target) ..  " \n")
	-- end
	if IsValid(ply) then
		ply:SetTarget(target)
	end
end)

//Nosync means don't tell sync with the other state (server or client).
function meta:SetLock(target,nosync)
	
	if hook.Run("ASSPlayerLock",self,self.AssassinLock,target) == false then return end
	
	if not nosync then
		net.Start("ass_playerlock")
			net.WriteEntity(target)
		if SERVER then
			net.Send(self)
		else
			net.SendToServer()
		end
	end
	
	if CLIENT then
		if IsValid(target) then
			target.LastSeenTime = CurTime()
			if IsValid(target:GetAutoPilot()) then
				target:GetAutoPilot().LastSeenTime = CurTime()
			end
			
			surface.PlaySound("buttons/button15.wav")
		elseif IsValid(self.AssassinLock) then
			surface.PlaySound("buttons/button18.wav")
		end
	end
	
	self.AssassinLock = target
end
function meta:GetLock()
	return self.AssassinLock or NULL
end
function meta:GetLockEnt()
	return IsValid(self:GetLock()) and ((IsValid(self.AssassinLock:GetAutoPilot()) and !self.AssassinLock:GetAutoPilot():GetDisabled()) and self.AssassinLock:GetAutoPilot() or self.AssassinLock) or NULL
end
if CLIENT then
	net.Receive("ass_playerlock",function()
		LocalPlayer():SetLock(net.ReadEntity(),true)
	end)
else
	net.Receive("ass_playerlock",function(len,ply)
		ply:SetLock(net.ReadEntity(),true)
	end)
end

function meta:SetHeat(heat)
	local old = self:GetNW2Float("ass_heat")
	if heat == old then return end
	
	-- if hook.Run("ASSPlayerHeatChanged",self,old,heat) == false then return end
	
	self:SetNW2Float("ass_heat", heat)
	
	-- if SERVER then
		-- net.Start("ass_playerheat")
			-- net.WriteFloat(heat)
		-- net.Send(self)
	-- end
end
function meta:GetHeat()
	return self:GetNW2Float("ass_heat") or 0
end
-- if CLIENT then
	-- net.Receive("ass_playerheat",function()
		-- LocalPlayer():SetHeat(net.ReadFloat())
	-- end)
-- end
function meta:GetHeatLevel(heat)
	h = (heat or self:GetHeat())/100
	
	if h > .88 then
		return 4 //Reckless
	elseif h > .525 then
		return 3 //Audacious
	elseif h > .225 then
		return 2 //Discreet
	else
		return 1 //Silent
	end
end
local levels= {
	"Silent",
	"Discreet",
	"Audacious",
	"Reckless"
}
function meta:GetHeatDescription(heat)
	return levels[self:GetHeatLevel(heat)]
end

function meta:GetGender()
	return self:GetNWString("ass_gender","MALE")
end
function meta:SetGender(v)
	self:SetNWString("ass_gender",v)
end

function RandomGender()
	return math.random(0,1) == 0 and "MALE" or "FEMALE"
end
function RandomModel(gend)
	return table.RandomSeq(PLAYER_MODELS[gend or RandomGender()])
end

function table.RandomSeq(tbl)
	local rand = math.random( 1, #tbl )
	return tbl[rand], rand
end

--Team List:
TEAM_ASSASSIN = 2
TEAM_ASS = 2 --second name for it.
team.SetUp(TEAM_ASSASSIN, "Assassins", Color(180,20,20,255))
team.SetSpawnPoint(TEAM_ASSASSIN, "info_player_spawn")


ALL_CIVS = ALL_CIVS or {}


IDLE_POSES = {
	"pose_standing_01",
	"pose_standing_02",
}

ATTACK_POSES = {
	"seq_baton_swing",
	-- "seq_throw",
}

STUN_SOUNDS = {
	Sound( "Flesh.ImpactHard" ),
}

STUN_POSES = {
	"idle_all_cower",
}
DEATH_POSES = {
	"death_01",
	"death_02",
	"death_03",
	"death_04"
}

CLIMB_POSES = {
	"zombie_climb_start",
	"zombie_climb_loop",
	"zombie_climb_end",
}

BYSTAND_DISSOLVE_SOUNDS = {
	"buttons/combine_button1.wav",
	"buttons/combine_button2.wav",
	"buttons/combine_button3.wav",
	"buttons/combine_button5.wav",
	"buttons/combine_button7.wav",
	"buttons/combine_button_locked.wav",
}

STAB_SOUNDS = {
	"weapons/knife/knife_hit1.wav",
	"weapons/knife/knife_hit2.wav",
	"weapons/knife/knife_hit3.wav",
	"weapons/knife/knife_hit4.wav",
	"weapons/knife/knife_stab.wav",
}

DEATH_SOUNDS = {
	MALE =  {
		"vo/npc/male01/help01.wav",
		"vo/npc/male01/no01.wav",
		"vo/npc/male01/no02.wav",
		"vo/npc/male01/ow01.wav",
		"vo/npc/male01/ow02.wav",
		"vo/npc/male01/pain02.wav",
		"vo/npc/male01/pain07.wav",
		"vo/npc/male01/pain08.wav",
		"vo/npc/male01/pain09.wav",
		"vo/npc/barney/ba_no01.wav",
		"vo/npc/barney/ba_no02.wav",
		"vo/npc/barney/ba_ohshit03.wav",
		"vo/npc/barney/ba_pain01.wav",
		"vo/npc/barney/ba_pain02.wav",
		"vo/npc/barney/ba_pain03.wav",
		"vo/npc/barney/ba_pain04.wav",
		"vo/npc/barney/ba_pain05.wav",
		"vo/npc/barney/ba_pain06.wav",
		"vo/npc/barney/ba_pain07.wav",
		"vo/npc/barney/ba_pain09.wav",
		"vo/npc/barney/ba_pain10.wav",
	},
	FEMALE  = {
		"vo/npc/female01/help01.wav",
		"vo/npc/female01/no01.wav",
		"vo/npc/female01/no02.wav",
		"vo/npc/female01/ow01.wav",
		"vo/npc/female01/ow02.wav",
		"vo/npc/female01/pain02.wav",
		"vo/npc/female01/pain07.wav",
		"vo/npc/female01/pain08.wav",
		"vo/npc/female01/pain09.wav",
		"vo/npc/alyx/uggh02.wav",
		
	}
}

//SOME MODELS DON'T WORK WITH OUR HIGHLIGHTING SYSTEM (ones without movable eyes, it would seem). TEST ALL MODELS.
//You can add your own models here OR you can do this in any shared file:

-- table.insert(PLAYER_MODELS.MALE, "models/your/male/model.mdl")
-- table.insert(PLAYER_MODELS.FEMALE, "models/your/male/model.mdl")

PLAYER_MODELS = {
	MALE={
		"models/player/Group03/male_01.mdl",
		"models/player/barney.mdl",
		"models/player/gman_high.mdl",
		"models/player/eli.mdl",
		"models/player/breen.mdl",
		"models/player/kleiner.mdl",
		"models/player/monk.mdl",
		-- "models/player/guerilla.mdl",
		-- "models/player/leet.mdl",
		-- "models/player/gasmask.mdl",
		"models/player/soldier_stripped.mdl",
		-- "models/player/combine_super_soldier.mdl",
		"models/player/hostage/hostage_01.mdl",
		
		
	},
	FEMALE={
		"models/player/Group03m/Female_03.mdl",
		"models/player/alyx.mdl",
		"models/player/mossman.mdl",
		-- "models/player/police_fem.mdl",
		-- "models/player/p2_chell.mdl",
		
	}
}
