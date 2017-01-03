AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

if SERVER then
	util.AddNetworkString("ass_npc_disabled")
end

ENT.WalkSpeed = 85
ENT.RunSpeed = 140
ENT.WanderDist = 12

function ENT:Initialize()

	self:SetModel(table.RandomSeq(CIVILIAN_MODELS.MALE))

	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds( Vector(-16,-16,0), Vector(16,16,72) )
	
	if SERVER then
		
		
		self:SetSolidMask(MASK_NPCSOLID_BRUSHONLY)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		
	end
	
	self.loco:SetStepHeight(30)
	self.loco:SetDeathDropHeight(21)
	self.loco:SetMaxYawRate( 10 )
	
	self.StuckCount = 0
	self.LastPos = {}
	self.BreakPath = false
	self.NextFollowUpdate = .5
	
	-- table.insert(ALL_CIVS,self)
end

function ENT:OnRemove()
	-- table.RemoveByValue(ALL_CIVS,self)
end

function ENT:OnContact( ent )
    -- if ent:IsPlayer() then
        -- self.loco:SetVelocity( (ent:GetPos()-self:GetPos()):GetNormalized()*-600 )
    -- end
end

-- function ENT:SetPlayerColor(c)
	-- self.PlayerColor = c
-- end
-- function ENT:GetPlayerColor()
	-- return IsValid(self.Player) and self.Player:GetPlayerColor() or self.PlayerColor or Vector(0.243137, 0.345098, 0.415686)
-- end

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"Disabled")
end

function ENT:Draw() if self:GetDisabled() then return end self:DrawModel() end
function ENT:DrawTranslucent() if self:GetDisabled() then return end self:DrawModel() end

-- function ENT:GetDisabled()
	-- return self.Disabled == true
-- end
-- function ENT:SetDisabled(b)
	-- self.Disabled = b
	-- if SERVER then
		-- self.BreakPath = b
		-- net.Start("ass_npc_disabled")
			-- net.WriteEntity(self)
			-- net.WriteBit(b)
		-- net.Broadcast()
	-- end
-- end
-- if CLIENT then
	-- net.Receive("ass_npc_disabled",function()
		-- local ent = net.ReadEntity()
		-- if ent.SetDisabled then
			-- ent:SetDisabled(net.ReadBit() == 1)
		-- end
	-- end)
-- end


function ENT:RunBehaviour()
	
	while ( true ) do
		if not self:GetDisabled() then
		
			self:StartActivity( ACT_HL2MP_WALK )
			self.loco:SetDesiredSpeed( self.WalkSpeed )
			
			local result = self:WalkTo( {pos = self:FindNewDestination()} ) -- walk to a random place
			-- print(result)
			self:StartActivity( ACT_HL2MP_IDLE )
		end
		
		
		coroutine.yield()

	end

end

-- ENT.BodySkip = false
function ENT:BodyUpdate()
	
	if isfunction(self.GetDisabled) and self:GetDisabled() then return end
	
	local act = self:GetActivity()

	if ( act == ACT_HL2MP_RUN or act == ACT_HL2MP_WALK ) then

		self:BodyMoveXY()
		
	else
		self:FrameAdvance()
	end


end


function ENT:HandleStuck()
	
	self.loco:ClearStuck()
	
	if !IsValid(self.Player) then //Respawn non-players.
		self:Remove()
	else
		self:SetMode(0)
	end
	-- else //Move players.
		-- local newpos
		-- local pos = self:GetPos()
		-- //sphere trace for antistuck
		-- local hulltr = {start=pos, endpos=pos, mask=MASK_NPCSOLID, filter=self}
		-- local stuck = util.TraceEntity(hulltr,self)
		-- if stuck.StartSolid then
			-- local dist = 16
			-- local accuracy = .5
			-- local found = false
			-- hulltr.start=pos
			-- local function unstick()
				-- for x=1,-1,-accuracy do
					-- for y=1,-1,-accuracy do
						-- for z=-1,1,accuracy do
							
							
							-- local dir = Vector(x,y,z)
							-- hulltr.endpos = hulltr.start + dir*dist
							
							-- local line = util.TraceLine(hulltr)
							-- if not line.Hit and not line.StartSolid then
								-- local trace= {start=hulltr.endpos, endpos=hulltr.endpos, mask=MASK_NPCSOLID, mins=mins, maxs=maxs, filter=ply}
								-- local htr = util.TraceHull(trace)
								
								-- if not htr.Hit and not htr.StartSolid then
									-- -- local a = SERVER and debugoverlay.Box(hulltr.endpos,mins,maxs,15,Color(0,255,0,100))
									-- newpos = hulltr.endpos
									-- found = true
								-- end
							-- end
							
							-- -- local a = SERVER and debugoverlay.Line(hulltr.start,hulltr.endpos,15,Color(255,0,0))
							
							
							-- if found then break end
						-- end
						-- if found then break end
					-- end
					-- if found then break end
				-- end
			-- end
			-- repeat 
				-- unstick()
				-- dist = dist + 16
			-- until found or dist > 2000
		-- end
		-- if newpos then 
			-- self:SetGroupLeader(NULL)
			-- self:SetGroupOffset(Vector(0,0,0))
			-- self:SetMode(0)
			-- self:SetPos(newpos)
		-- else
			-- if IsValid(self:GetNW2Entity("ass_player")) then
				-- self:GetNW2Entity("ass_player"):Kill()
			-- end
			-- self:Remove()
			-- print("PLAYER STUCK! Had to kill them. :("..self:GetNW2Entity("ass_player"):Nick())
		-- end
	-- end

end


function ENT:WalkTo( options )

	local options = options or {}

	local path = Path( "Follow" )
	
	path:SetMinLookAheadDistance( options.lookahead or 20 )
	path:SetGoalTolerance( options.tolerance or 30 )
	
	self:ComputePath(path, options.pos or self:GetPos()) --compute path with no doors.
	
	if ( !path:IsValid() ) then 
		self.StuckCount = 0
		self.LastPos = {self:GetPos()}
		return "failed" 
	end
	
	-- local last = self:GetPos()
	-- for k,v in ipairs(path:GetAllSegments())do
		-- local trace = { start = last, endpos = v.pos+Vector(0,0,12), filter = self, mask=MASK_NPCSOLID}
		-- local res = util.TraceLine(trace)
		-- last = v.pos+Vector(0,0,1)
		-- if res.Hit then
			-- return "blocked"
		-- end
	-- end

	while ( path:IsValid() ) and (not self.BreakPath) do
		if not self:IsValid() then
			return "removed"
		end
		
		path:Update( self )								-- This function moves the bot along the path
		
		-- table.insert(self.LastPos, 1, self:GetPos())
		
		
		-- local count = #self.LastPos
		-- local minCheck = 23
		-- if count > minCheck then
			-- self.LastPos[minCheck+1] = nil
			-- local sum = 0
			-- for i=1, minCheck do
				-- sum = sum + (self:GetPos() - self.LastPos[i]):Length2DSqr()
			-- end
			-- if (sum/minCheck) < self.WalkSpeed*.8 then
				-- self.StuckCount = self.StuckCount + 1
				
				-- if self.StuckCount > 30 then
					-- self.LastPos = {self:GetPos()}
					-- self.StuckCount = 0
					-- self:HandleStuck()
				
					-- return "stuck"
				-- end
				
			-- end
		-- end
		
		-- if ( GetConVarNumber("nav_edit")==1 and not game.IsDedicated() ) then path:Draw() end
		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			
			self.LastPos = {self:GetPos()}
			self.StuckCount = 0
			self:HandleStuck()
			
			return "stuck"
			
		end
		
		coroutine.yield()
		
	end
	
	local wasbroke = self.BreakPath
	
	self.BreakPath = false
	self.StuckCount = 0
	self.LastPos = {self:GetPos()}
	
	if wasbroke then
		return "interrupted"
	end
	
	return "ok"

end

function ENT:ComputePath(path, pos)
	local time = SysTime()
	path:Compute( self, pos, function(area, fromArea, ladder, elevator, length )
		if ( !IsValid( fromArea ) ) then

			// first area in path, no cost
			return 0

		else
			if ( !fromArea:IsConnected(area) ) then
				return -1
			end

			if ( !self.loco:IsAreaTraversable( area ) ) then
				// our locomotor says we can't move here
				return -1
			end
			
			// compute distance traveled along path so far
			local dist = 0

			--[[ if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			else]]if ( length > 0 ) then
				// optimization to avoid recomputing length
				dist = length
			else
				dist = ( area:GetCenter() - fromArea:GetCenter() ):Length()
				-- dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
			end

			local cost = dist + fromArea:GetCostSoFar()
			
			-- local doors = ents.FindInBox(area:GetCorner(0), area:GetCorner(2) + Vector(0,0,100))
			-- for k,v in pairs(doors) do
				-- if v:GetClass():find("door") or v:GetClass():find("breakable") then
					-- -- cost = cost + 5
					-- return -1
				-- end
			-- end
			
			-- local avoidPenalty = 1.2
			-- if area:HasAttributes(NAV_MESH_AVOID) then
				-- if self.FreakingOut then //if we're in a hurry, allow movement through avoid areas.
					-- cost = cost + avoidPenalty * dist
				-- else
					-- return -1
				-- end
			-- end
			
			-- if area:HasAttributes(NAV_MESH_JUMP) or area:HasAttributes(NAV_MESH_CROUCH) then
				-- return -1
			-- end
			
			-- if area:HasAttributes(NAV_MESH_NO_HOSTAGES) and (IsValid(self:GetMode() == 1) or self:GetClass()=="npc_group_leader" ) then
				-- return -1
			-- end

			-- // check height change
			-- local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			-- -- local deltaZ = fromArea:ComputeGroundHeightChange( area )
			-- if ( deltaZ >= self.loco:GetStepHeight() ) then
				-- if ( deltaZ >= self.loco:GetMaxJumpHeight() ) then
					-- // too high to reach
					-- return -1
				-- end

			-- elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
				-- // too far to drop
				-- return -1
			-- end

			return cost
		end
	end)
	
	local dtime = SysTime() - time
	if dtime > 1.1 then
		print(self, " took "..dtime.." seconds to calculate path! Removing...")
		self:Remove()
	end
	
end

if SERVER then
	function ENT:FindNewDestination()
		-- local time = SysTime()
		-- local area = navmesh.GetNearestNavArea(self:GetPos(), false, 1000)
		-- if not area then return self:GetPos() end
		
		-- local previous = {}
		
		-- local i = 0
		-- while i < self.WanderDist or (area:HasAttributes(NAV_MESH_AVOID) and i < 100) do
		
			-- -- if math.random(0,5) != 0 then
				-- local new = table.Random(area:GetAdjacentAreas() or {})
				
				-- if not new then //Nowhere to go.
					-- break
				-- end
				
				-- if not previous[new] then //we've not been here already.
					-- previous[new] = true
					-- area = new
				-- end
				
			-- -- end
			
			-- i=i+1
		-- end
		
		-- if SysTime() - time > 1 then
			-- print("Took "..SysTime() - time.." to find new destination!")
		-- end
		
		-- return area:GetRandomPoint()
		
		return table.RandomSeq(NAV_AREAS):GetRandomPoint()
	end
end


function ENT:Think()
	if CLIENT then
		self:SetEyeTarget(self:GetPos() + self:GetForward()*40 + Vector(0,0,62) + VectorRand():GetNormalized()*8)
		self:SetNextClientThink(CurTime() + math.Rand(.7,1.8))
		return true
	end
end

list.Set( "NPC", "npc_autopilot", {
	Name = "Autopilot bot",
	Class = "npc_autopilot",
	Category = "NextBot"
} )