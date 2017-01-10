AddCSLuaFile()


ENT.Base 			= "npc_ass_base"
ENT.Spawnable		= true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.WalkSpeed = 85
ENT.RunSpeed = 160
ENT.WanderDist = 50

function ENT:Initialize()
	
	if SERVER then
		
		self:SetUseType(SIMPLE_USE)
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds( Vector(-4,-4,0), Vector(4,4,72) )
		
		-- self:SetSolidMask(MASK_NPCSOLID)
		self:SetSolidMask(MASK_NPCSOLID_BRUSHONLY)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	else
		-- self:SetLOD( 2 )
		self:SetIK(false)
	end
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
	
	self.NextFollowUpdate = .5
	self.StuckCount = 0
	self.LastPos = {}
	table.insert(ALL_CIVS,self)
end

function ENT:Think()
	if IsValid(self:GetNW2Entity("ass_player")) then
		if self:GetDisabled() then
			self:SetPos(self:GetNW2Entity("ass_player"):GetPos())
			self:SetAngles(self:GetNW2Entity("ass_player"):GetAngles())
			self:SetRenderMode(RENDERMODE_NONE)
		else
			self:GetNW2Entity("ass_player"):SetPos(self:GetPos()-Vector(0,0,8))
			self:SetRenderMode(RENDERMODE_NORMAL)
		end
	end
end

AccessorFunc(ENT,"GroupOffset","GroupOffset")
function ENT:SetupDataTables()

	//SetMode(int) - Change between different passive behaviors.
	//		0: Wander aimlessly (default)
	//		1: Fit in with group
	//		2: Sit on bench
	self:NetworkVar("Int",0,"Mode")
	self:NetworkVar("Entity",0,"GroupLeader")
	self:NetworkVar("String",0,"Gender")
	self:NetworkVar("Bool",0,"Disabled")
	
	if SERVER then
		self:NetworkVarNotify("Mode",function(self,name,old,new) self.BreakPath = true end)
	end
	self:NetworkVarNotify("GroupLeader",function(self,name,old,new)
		if IsValid(old) then
			table.RemoveByValue(old.Followers,self)
			if #old.Followers <= 0 then
				old:Remove()
			end
		end
		if IsValid(new) then
			table.insert(new.Followers,self)
		end
	end)
end

function ENT:UpdateTransmitState()
	if IsValid(self:GetNW2Entity("ass_player")) then
		return TRANSMIT_ALWAYS
	end

	return TRANSMIT_PVS
end
function ENT:OnRemove()
	table.RemoveByValue(ALL_CIVS,self)
	if IsValid(self:GetNW2Entity("ass_player")) then
		autopilot.Interrupt(self:GetNW2Entity("ass_player"))
	end
	if SERVER then
		if CURRENT_STATE.number == 2 and !CLEAN_UP then
			SpawnBystand()
		end
		self:SetGroupLeader(NULL)
	end
end

----------------------------------------------------
-- ENT:RunBehaviour()
-- This is where the meat of our AI is
----------------------------------------------------
function ENT:RunBehaviour()
	
	while ( true ) do
		if not self:GetDisabled() then
			local mode = self:GetMode()
			
			if self.DeathSeq then  //die
				self.loco:FaceTowards( self.Killer:GetPos() )
				self:SetSequence(self.DeathSeq)
				coroutine.yield()
				
			elseif mode == 1 then //Follow a group.
				
				self:StartActivity( ACT_HL2MP_WALK )
				
				local leader = self:GetGroupLeader()
				self.loco:SetDesiredSpeed( self.WalkSpeed )
				
				-- local result = self:MoveToPos( leader:GetPos() + self:GetGroupOffset(), {draw=GetConVar("nav_edit"):GetBool()} ) -- walk to a random place
				local result = self:Follow( leader, self:GetGroupOffset() ) -- follow the leader
				
				//Strike a pose.
				while self:GetMode() == 1 and leader:GetMode() == 1 and !self.BreakPath and !self:GetDisabled() do
					
					//Start posing.
					if not self.Pose then
						self.Pose = IDLE_POSES[math.random(1,#IDLE_POSES)]
						self:StartActivity(ACT_HL2MP_IDLE)
					end
					
					self.loco:FaceTowards( leader:GetPos() )
					self:SetSequence( self.Pose )
					
					//small chance to leave the standing group.
					if math.random(0,4500) == 0 and not IsValid(self.Player) and #self:GetGroupLeader().Followers > 3 then
						self:SetMode(0)
						self:SetGroupOffset(Vector(0,0,0))
						self:SetGroupLeader(NULL)
					end
					
					coroutine.yield()
				end
				self:ResetSequence(self.DeathSeq or "walk_all")
				self:StartActivity(ACT_HL2MP_WALK)
				self.BreakPath = false
				
				coroutine.yield()
				
			else //Wander aimlessly
				
				if self.Pose then
					self.Pose = nil
				end
				
				self:StartActivity( ACT_HL2MP_WALK )
				
				self.loco:SetDesiredSpeed( self.WalkSpeed )
				
				local result = self:WalkTo( {pos = self:FindNewDestination()} ) -- walk to a random place
				-- print(result)
				self:StartActivity( ACT_HL2MP_IDLE )
				
				//Chance to find a group and join.
				if math.random(0,55) == 0 then
					local groupsize = ConVars.Server.groupMaxSize:GetInt()
					for k,lead in RandomPairs(ents.FindByClass("npc_group_leader")) do
						if IsValid(lead) and #lead.Followers < groupsize then
							local offset = VectorRand() * 40 //Group spacing is 40 units.
							offset.z = 0
							self:SetMode(1)
							self:SetGroupOffset(offset)
							self:SetGroupLeader(lead)
							break
						end
					end
				end
				
				if !self.DeathSeq then
					coroutine.yield()
				end
				
			end
			
			coroutine.yield()
			
		else
		
			coroutine.yield()
		end

	end

end

function ENT:Follow(target, offset)

	local options = options or {}

	-- local path = Path( "Chase" )
	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 200 )
	path:SetGoalTolerance( options.tolerance or 15 )
	path:Compute( self, target:GetPos() + offset )		-- Compute the path towards the enemy's position

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and target:IsValid() ) do
		
		if self.BreakPath then return "ok" end
		
		if target:GetMode() != 1 and self:GetPos():DistToSqr(target:GetPos()) > 150*150 then
			self.loco:SetDesiredSpeed( self.RunSpeed )
		else
			self.loco:SetDesiredSpeed( self.WalkSpeed )
		end
		
		if ( path:GetAge() > self.NextFollowUpdate) then-- Since we are following the player we have to constantly remake the path
			
			
			//small chance to leave the group.
			if math.random(0,1500) == 0 and not IsValid(self.Player) and #self:GetGroupLeader().Followers > 3 then
				self:SetMode(0)
				self:SetGroupOffset(Vector(0,0,0))
				self:SetGroupLeader(NULL)
				
				return "ok"
			end
			
			path:Compute( self, target:GetPos()+offset )-- Compute the path towards the enemy's position again
			self.NextFollowUpdate = math.Rand(.8,1.8)
		end
		-- path:Chase( self, target )								-- This function moves the bot along the path
		path:Update( self )								-- This function moves the bot along the path

		-- if ( options.draw ) then path:Draw() end
		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()

	end

	return "ok"

end

function ENT:Use(ply,a,type,info)
	if self.DeathSeq then return end
	if ply == self:GetNW2Entity("ass_player") then return end
	
	if IsValid(ply:GetLock()) and self != ply:GetLockEnt() then
		return false
	end
	
	if !IsValid(self:GetNW2Entity("ass_player")) then
		Assassinate(self,ply)
	else
		
		if ply:GetTarget() == self:GetNW2Entity("ass_player")  then
			Assassinate(self,ply)
		else--if self.Player:GetTarget() == ply then
			Stun(self,ply)
		end
	end
	
end

function ENT:Dissolve(attacker)
	self.BreakPath = true
	self:SetName("cleanser_dissolve")
	local dissolver = ents.Create( "env_entity_dissolver" )
	dissolver:SetPos( self:GetPos() )
	dissolver:Spawn()
	dissolver:Activate()
	dissolver:SetKeyValue( "magnitude", 100 )
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:Fire( "Dissolve","cleanser_dissolve" )
		
	timer.Simple(self:SequenceDuration()*.8-.2,function()
		if IsValid(self) then
			self:TakeDamage( self:Health(), attacker, attacker )
			dissolver:Remove()
		end
	end)
end

function ENT:ActionKeyHover()
	if self.DeathSeq then return false end
	
	local ply = self:GetNW2Entity("ass_player")
	if !IsValid(ply) then
		return true, "Assassinate", self:GetPos() + self:OBBCenter()
	else
		if LocalPlayer():GetTargetEnt() == self then
			return true, "Assassinate", self:GetPos() + self:OBBCenter()
		elseif not ply.DeathSeq then --if ply:GetTarget() == LocalPlayer() then
			return true, "Assassinate", self:GetPos() + self:OBBCenter()
		-- else
			-- return false
		end
	end
	
	return false
end

list.Set( "NPC", "npc_autopilot", {
	Name = "Autopilot bot",
	Class = "npc_autopilot",
	Category = "NextBot"
} )