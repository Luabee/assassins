
local meta = FindMetaTable("Player")

util.AddNetworkString("ass_playertarget")
util.AddNetworkString("ass_playerlock")
util.AddNetworkString("ass_playerheat")
util.AddNetworkString("ass_playerspawn")
util.AddNetworkString("ass_killpoints")



function meta:SpawnForRound()
	
	self.NextSpawnTime = CurTime()+1
	
	self:SetHealth(self:GetMaxHealth())
	self:StripWeapons()
	
	self:Spawn()
	
	self.DeathSeq = nil
	self.AttackSeq = nil
	
	self:SetHull(Vector(-16,-16,0),Vector(16,16,72))
	
	-- timer.Simple(.1,function()
	local lead = table.RandomSeq(ents.FindByClass("npc_group_leader"))
	if IsValid(lead) then
		local pos = FindBystandSpawnPos(30,nil,lead:GetPos())
		if pos then
			for k,v in pairs(lead.Followers)do
				if not IsValid(v:GetNW2Entity("ass_player")) then
					v:SetModel(self:GetModel())
					break
				end
			end
			self:SetPos(pos)
		else
			pos = FindBystandSpawnPos()
			if pos then
				self:SetPos(Vector(0,0,0))
			else
				ErrorNoHalt("Could not find suitable spawn positon. Is navmesh loaded??\n")
			end
		end
	else
		pos = FindBystandSpawnPos()
		if pos then
			self:SetPos(Vector(0,0,0))
		else
			ErrorNoHalt("Could not find suitable spawn positon. Is navmesh loaded??\n")
		end
	end
	
	autopilot.Begin(self)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	-- end)
	
	net.Start("ass_playerspawn")
		net.WriteEntity(self)
	net.Broadcast()
end

function meta:SetIntensity(new)
	net.Start("ass_intensity")
		net.WriteUInt(new,3)
	net.Send(self)
end


function GM:ShowHelp(ply)
	ply:ConCommand("ass_tutorial")
end

function GM:PlayerDisconnected( ply )
	if #player.GetAll() < 3 then
		WAITING_FOR_PLAYERS = true
		GAMEMODE:SetRoundNumber(CURRENT_ROUND + 1)
	end
end

function GM:PlayerCanPickupWeapon( ply, wep )
	return false
end
function GM:PlayerCanPickupItem( ply, item )
	return false
end

function GM:SetupPlayerVisibility( ply,viewent )
	-- AddOriginToPVS( GAMEMODE:CalcView(ply,ply:EyePos(),ply:EyeAngles()).origin )
	-- AddOriginToPVS( ply:GetPosAutoPilot() )
	
	-- if IsValid(ply:GetTarget()) then
		-- AddOriginToPVS( ply:GetTarget():GetPosAutoPilot() )
	-- end
	-- if autopilot.Sync then
		-- for k,v in pairs(player.GetAll())do
			-- AddOriginToPVS( v:GetPosAutoPilot() )
		-- end
	-- end
	for k,v in pairs(ply.Pursuers)do
		if IsValid(v) and v:GetChase() != 0 then
			AddOriginToPVS( v:GetPos() )
		end
	end
end

function GM:GetFallDamage( ply, flFallSpeed )

	if( GetConVarNumber( "mp_falldamage" ) > 0 ) then -- realistic fall damage is on
		return ( flFallSpeed - 526.5 ) * ( 100 / 396 ) -- the Source SDK value
	end
	
	return 10

end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, rf )
	return true -- Don't allow default footsteps
end

function GM:PlayerSwitchFlashlight( ply, b )
	return true
end

local targets = {}
function GM:GetNewTarget(ply)
	
	if ply:Alive() then
	
		//Are we past the point of single-assignments?
		local beyond = CurTime()-ROUND_START_TIME > ConVars.Server.multiPursue:GetFloat()
		local ranks = beyond and player.GetScoreSorted()
		
		//Assign randomly.
		for k,v in RandomPairs(player.GetAll()) do
			if v:Team() != TEAM_ASS then continue end
			if v == ply then continue end
			
			if v:Alive() and v:GetTarget() != ply then
				if ply:Alive() and v:GetPosAutoPilot():DistToSqr(ply:GetPosAutoPilot()) < ConVars.Server.minDist:GetFloat()^2 then continue end
				
				local count = #v.Pursuers
				
				//If we've reached that point, then start assigning multiple people to one person
				if beyond then
					if count < math.max(1, ConVars.Server.maxPursuers:GetInt() - (table.KeyFromValue(ranks,v) - 1) ) then
						return v
					end
				else
					if count == 0 then
						return v
					end
				end
			end
			
			
		end
		
	end
	
	return NULL
	
end

function GM:PlayerKillBystander(ply,victim)
	//TODO: Notify target.
	
	DelayNewTarget(ply)
end

local scoreobj = {amt={},mod={}}
function scoreobj:Add(amt,reason)
	if not isnumber(amt) then return end
	if amt != 0 then
		amt = math.floor(amt)
		table.insert(self.amt, {amt,reason or "Bonus"})
	end
end
function scoreobj:Get()
	return self.amt
end
function scoreobj:GetSum()
	local sum,mod = 0, 1
	for k,v in ipairs(self.mod)do
		mod = mod + v[1]
	end
	for k,v in ipairs(self.amt)do
		sum = sum + v[1]*mod
	end
	return sum
end
function scoreobj:Scale(amt,reason)
	if not isnumber(amt) then return end
	if amt > 0 then
		table.insert(self.mod, {amt,reason or "Bonus"})
	end
end

//IN THIS HOOK: use scoreobj to track the point value, so we can modify it within other hooks.
function GM:GetKillPoints(victim,attacker,dmginfo,score)
	
	//Add points for sneakiness
	score:Add( (4-attacker:GetHeatLevel())*ConVars.Server.scoreSneak:GetFloat(), attacker:GetHeatDescription() )
	
	//Add spree bonus
	if attacker:GetSpree() > ConVars.Server.spreeSize:GetInt() then
		score:Scale( ConVars.Server.scoreSpree:GetFloat(), "Killing Spree" )
	end
	
	return score
end

local function SendKillPoints(ply,points)
	net.Start("ass_killpoints")
	
		local amtct = #points.amt
		local modct = #points.mod
		net.WriteUInt(amtct,8)
		for i=1, amtct do
			net.WriteFloat(points.amt[i][1])
			net.WriteString(points.amt[i][2])
		end
		net.WriteUInt(modct,8)
		for i=1, modct do
			net.WriteFloat(points.mod[i][1])
			net.WriteString(points.mod[i][2])
		end
		
		
	net.Send(ply)
end

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	
	autopilot.Interrupt(ply)
	if IsValid(ply:GetAutoPilot()) then
		ply:GetAutoPilot():Remove()
	end
	
	ply:CreateRagdoll()
	
	ply:AddDeaths( 1 )
	ply:SetSpree(0)
	
	if ( attacker:IsValid() and attacker:IsPlayer() and attacker:GetTarget() == ply ) then
		
		attacker:SetSpree(attacker:GetSpree()+1)
		
		local score = table.Copy(scoreobj)
		score.amt[1]={ConVars.Server.scoreBase:GetInt(),"Assassination"} --base kill points.
		local killpoints = hook.Run("GetKillPoints",ply,attacker,dmginfo,score)
		
		local sum = killpoints:GetSum()
		attacker:AddFrags( sum )
		attacker:SetScore( attacker:GetScore() + sum )
		SendKillPoints(attacker, killpoints)
		
	end
	
end

function GM:PlayerDeath( ply, inflictor, attacker )
	
	//Reassign targets
	for k,v in pairs(player.GetAll())do
		if v:GetTarget() == ply then
			//TODO: Notify failures.
			DelayNewTarget(v)
		end
	end
	DelayNewTarget(ply)
	
	//Default behavior:
	
	-- Don't spawn for at least x seconds
	ply.NextSpawnTime = CurTime() + ConVars.Server.respawnTime:GetFloat()
	ply.DeathTime = CurTime()
	
	if ( IsValid( attacker ) && attacker:GetClass() == "trigger_hurt" ) then attacker = ply end
	
	if ( IsValid( attacker ) && attacker:IsVehicle() && IsValid( attacker:GetDriver() ) ) then
		attacker = attacker:GetDriver()
	end

	if ( !IsValid( inflictor ) && IsValid( attacker ) ) then
		inflictor = attacker
	end

	-- Convert the inflictor to the weapon that they're holding if we can.
	-- This can be right or wrong with NPCs since combine can be holding a
	-- pistol but kill you by hitting you with their arm.
	if ( IsValid( inflictor ) && inflictor == attacker && ( inflictor:IsPlayer() || inflictor:IsNPC() ) ) then
	
		inflictor = inflictor:GetActiveWeapon()
		if ( !IsValid( inflictor ) ) then inflictor = attacker end

	end

	if ( attacker == ply ) then
	
		net.Start( "PlayerKilledSelf" )
			net.WriteEntity( ply )
		net.Broadcast()
		
		MsgAll( attacker:Nick() .. " suicided!\n" )
		
	return end

	if ( attacker:IsPlayer() ) then
	
		net.Start( "PlayerKilledByPlayer" )
		
			net.WriteEntity( ply )
			net.WriteString( inflictor:GetClass() )
			net.WriteEntity( attacker )
		
		net.Broadcast()
		
		-- MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )
		
	return end
	
	net.Start( "PlayerKilled" )
	
		net.WriteEntity( ply )
		net.WriteString( inflictor:GetClass() )
		net.WriteString( attacker:GetClass() )

	net.Broadcast()
	
	-- MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )
	
end

function GM:PlayerDeathThink( pl )
	
	if ( pl.NextSpawnTime && pl.NextSpawnTime > CurTime() ) then return end

	
	pl:SpawnForRound()
	
end

function GM:PlayerDeathSound(ply)
	return true
end

local SwingSound = Sound( "WeaponFrag.Throw" )
function GM:PlayerUse( ply, ent )
	if ply:GetObserverMode() == OBS_MODE_ROAMING then
		return false
	end
	if ent:IsPlayer() and ply:Team() == TEAM_ASS and not ent.DeathSeq then
		
		if ply:GetTarget() == ent then
			Assassinate(ent,ply)
		else --if ent:GetTarget() == ply then
			Stun(ent,ply)
		end
		
		return false
	end
	if ent:GetClass():find("func_break") and ply:Team() == TEAM_ASS then
		BreakGlass(ent,ply)
		
		return false
	end
	return true
end


function GM:PlayerLoadout( ply )
end

function GM:PostPlayerThink(ply)
	if !ply.NextEyeThink or ply.NextEyeThink < CurTime() then
		ply:SetEyeTarget(ply:GetPos() + ply:GetForward()*40 + Vector(0,0,62) + VectorRand():GetNormalized()*8) //Make them look like bots.
		ply.NextEyeThink = CurTime() + math.Rand(.7,1.8)
	end
end
	
	
function GM:PlayerSetModel( ply )

	local gen = RandomGender()
	ply:SetGender(gen)
	ply:SetModel(RandomModel(gen))
	
end

function GM:PlayerSpawnAsSpectator( pl )

	pl:StripWeapons()

	pl:SetTeam( TEAM_SPECTATOR )
	pl:Spectate( OBS_MODE_ROAMING )

end

function GM:AllowPlayerPickup(ply,ent)
	return false
end

function GM:PlayerInitialSpawn(ply)
	hook.Run("PlayerDefinition",ply)
	
	ply:SetTeam(TEAM_SPECTATOR)
	
	if #player.GetAll() > 2 then
		WAITING_FOR_PLAYERS = false
		BroadcastLua("WAITING_FOR_PLAYERS = false")
	end
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

function SpawnAllPlayers()

	local plys = player.GetAll()
	
	for k, ply in pairs(plys) do
		if IsValid(ply) then
			ply:SpawnForRound()
		end
	end
	
end

function AssignRoles()
	
	for k,v in pairs(player.GetAll()) do
	
		if IsValid(v) then
			if v:Team() == TEAM_SPECTATOR then
				v:SetObserverMode(OBS_MODE_NONE)
				v:UnSpectate()
			end
			
			v:SetTeam(TEAM_ASSASSIN) --all assassins.
		end
		
	end
	
end

function AssignAllTargets()
	local plys = team.GetPlayers(TEAM_ASS)
	for k,v in pairs(plys)do
		-- v:SetTarget(GAMEMODE:GetNewTarget(v))
		
		local nk,nv = next(plys,k)
		if nk then
			v:SetTarget(nv)
		else
			v:SetTarget(plys[1])
		end
	end
end

function DelayNewTarget(ply,delay)
	ply:SetTarget(NULL,true)
	timer.Create("ass_plytargetdelay"..ply:SteamID(), delay or ConVars.Server.newTargetDelay:GetFloat(), 1, function()
		if IsValid(ply) then
			ply:SetTarget(GAMEMODE:GetNewTarget(ply))
		end
	end)
end

function ClearScores()
	for k,ply in pairs(player.GetAll()) do
		ply:SetFrags(0)
		ply:SetScore(0)
		ply:SetSpree(0)
		ply:SetDeaths(0)
	end
end
