AddCSLuaFile()

ENT.Base 			= "npc_ass_base"
ENT.Spawnable		= true

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.WalkSpeed = 90
ENT.WanderDist = 50


function ENT:Initialize()

	
	self:SetModel( "models/mossman.mdl" );
	self:SetRenderMode(RENDERMODE_NONE)
	self:DrawShadow(false)
	self:SetNoDraw(true)
	
	self:SetSolid(SOLID_NONE)
	self:SetCollisionBounds( Vector(-4,-4,0), Vector(4,4,72) )
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	if SERVER then
		self:SetSolidMask(MASK_NPCSOLID_BRUSHONLY)
		self:SetHealth(100000)
	else
		self:SetLOD( 8 )
		self:SetIK(false)
	end
	
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
	self.StuckCount = 0
	self.LastPos = {}
	self.Followers = {}
	-- table.insert(ALL_CIVS,self)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end

function ENT:SetupDataTables()

	//SetMode(int) - Change between different passive behaviors.
	//		0: Wander aimlessly (default)
	//		1: Stand still and pose
	self:NetworkVar("Int",0,"Mode")
	-- self:NetworkVar("Bool",0,"Disabled")
	if SERVER then
		self:NetworkVarNotify("Mode",function(self,name,old,new) self.BreakPath = true end)
	end
end

function ENT:OnRemove()
	-- table.RemoveByValue(ALL_CIVS,self)
	
	for k,v in pairs(self.Followers)do
		if v.GetGroupLeader and v:GetGroupLeader() == self then
			v:SetMode(0)
		end
	end
end

function ENT:BodyUpdate()
end
----------------------------------------------------
-- ENT:RunBehaviour()
-- This is where the meat of our AI is
----------------------------------------------------
function ENT:RunBehaviour()
	-- This function is called when the entity is first spawned. It acts as a giant loop that will run as long as the NPC exists
	while ( true ) do
		
		if self:GetMode() == 0 then
			self.loco:SetDesiredSpeed( self.WalkSpeed )
			
			local result = self:WalkTo( {pos = self:FindNewDestination()} ) -- walk to a random place
			-- print(result)
			
		else
			
			coroutine.yield( )
			
		end
		coroutine.yield( )

	end

end

function ENT:HandleStuck()
	
end

function ENT:Think()
	
end

list.Set( "NPC", "npc_autopilot", {
	Name = "Autopilot bot",
	Class = "npc_autopilot",
	Category = "NextBot"
} )