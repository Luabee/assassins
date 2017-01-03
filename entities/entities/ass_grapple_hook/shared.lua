
AddCSLuaFile( )

ENT.Type 		= "anim"

ENT.PrintName	= "Grapple Hook"
ENT.Author		= "Bobblehead"
ENT.Contact		= "luabeegaming@gmail.com"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_TRANSLUCENT



local LandSound = Sound( "bobble/grapple_hook/grappling_hook_impact.mp3" )
local FailSound = Sound( "weapons/hegrenade/he_bounce-1.wav" )

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self:SetModel("models/props_junk/meathook001a.mdl")
	self:SetModelScale(.5)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetFlying(true)
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
	else
		self:SetPredictable(true)
	end
	
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Flying" );
end

function ENT:CreateRope()
	local owner = self:GetOwner()
	local Lpos = self:GetRight()*-8+self:GetForward()*5-self:GetUp()*5
	local par = IsValid(owner:GetActiveWeapon()) and owner:GetActiveWeapon() or owner
	
	//Create keyframe rope
	self.kfr = ents.Create( "keyframe_rope" )
	self.kfr:SetKeyValue( "MoveSpeed", "64" )
	self.kfr:SetKeyValue( "Slack", "1000" )
	self.kfr:SetKeyValue( "Subdiv", "2" )
	self.kfr:SetKeyValue( "Width", "1" )
	self.kfr:SetKeyValue( "TextureScale", "1" )
	self.kfr:SetKeyValue( "Collide", "0" )
	self.kfr:SetKeyValue( "RopeMaterial", "cable/cable2.vmt" )
	self.kfr:SetKeyValue( "targetname", "kfr"..owner:UserID() )
	self.kfr:SetEntity( "StartEntity", owner )
	self.kfr:SetKeyValue( "StartOffset", tostring(Vector(0,0,0)) )
	self.kfr:SetKeyValue( "StartBone", 0 )
	self.kfr:SetEntity( "EndEntity", self )
	self.kfr:SetKeyValue( "EndOffset", tostring(Lpos) )
	self.kfr:SetKeyValue( "EndBone", 0 )
	self.kfr:SetPos( self:GetPos() + Lpos )
	self.kfr:Spawn()
	self.kfr:Activate()
	
	self:DeleteOnRemove(self.kfr)
end


if SERVER then
	function ENT:OnRemove()
		if not self.grapplefinish then
			grapp.Finish(self:GetOwner())
		end
	end
end

function ENT:Think()
	if SERVER then
		local owner = self:GetOwner()
		if !self:GetFlying() then
			local speed = 540*FrameTime()
			-- if !owner:OnGround() and owner:KeyDown(IN_JUMP) then
			
				-- //Suck us up.
				
				self.ropelength = self.ropelength - speed
				
				-- if self.ropelength < 1 or owner:GetPos().z > self:GetPos().z then
					-- grapp.Finish(owner)
					-- return
				-- else
					self.kfr:SetKeyValue( "Slack", tostring( self.ropelength - self.ropelength_original ) )
					-- -- self.rope:SetKeyValue( "length", tostring( self.ropelength - self.ropelength_original ) )
				-- end
			-- end
			
			-- local owner = self:GetOwner()
			-- local tension = self:GetPos()-owner:GetPos()
			-- local stretch = tension:Length()
			-- local ropeforce = Vector(0,0,0)
			-- if ( self.ropelength < stretch ) then
				-- local tension_norm = tension:GetNormal()
				-- local user_vel = owner:GetVelocity()
				
				-- local tension_vel_mag = tension_norm:DotProduct(user_vel)
				
				-- if ( tension_vel_mag < 0 ) then
					-- ropeforce = tension_norm * ( ( tension_vel_mag * -.1 ) + ( stretch - self.ropelength ) ) -- Stretched and moving the wrong way
				-- else
					-- ropeforce = tension_norm * ( stretch - self.ropelength ) * .2 -- Stretched and moving the right way
				-- end
				
				
			-- end
				
			-- owner:SetVelocity( ropeforce )
			
			
			
			
			
			
			
			self:NextThink(CurTime())
			return true
			
		end
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:PhysicsCollide(data,obj)
	local other = data.HitEntity
	if other then
		
		local owner = self:GetOwner()
		if owner:GetPos().z > self:GetPos().z then
			timer.Simple(0,function()
				grapp.Finish(owner)
			end)
			return
		end
		
		local norm = data.HitNormal
		norm.z = math.Round(norm.z,2)
		
		
		self:PhysicsDestroy()
		self:SetPos(data.HitPos-norm)
		local ang = norm:Angle()
		ang:RotateAroundAxis(data.HitNormal,145)
		ang:RotateAroundAxis(data.HitNormal:Angle():Right(),0)
		ang:RotateAroundAxis(data.HitNormal:Angle():Up(),-90)
		self:SetAngles(ang)
		self:EmitSound(LandSound, 80, 100, 1)
		timer.Simple(0,function()
			if self:IsValid() then
				if self:GetOwner():IsValid() then
					self:GetOwner():SetAbsVelocity(Vector(0,0,0))
					owner:SetMoveType(MOVETYPE_NOCLIP)
					-- owner:StripWeapon("weapon_ass_grapplehook")
					self:SetFlying(false)
				else
					self:Remove()
				end
			end
		end)
		
		
		local dist = owner:GetPos():Distance(self:GetPos())
		self.kfr:SetKeyValue("Slack",dist)
		
		self.ropelength = dist
		self.ropelength_original = dist
		
	else
		grapp.Finish(self:GetOwner())
	end
end