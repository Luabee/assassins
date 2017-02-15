
include("shared.lua")
include("sh_rounds.lua")
include("sh_chase.lua")
include("sh_autopilot.lua")
include("sh_thirdperson.lua")
include("sh_grapple_hook.lua")
include("sh_animmodel.lua")
include("sh_equipment.lua")

include("cl_music.lua")
include("cl_stencil.lua")
include("cl_halos.lua")
include("cl_gui.lua")
include("cl_fireworks.lua")
include("cl_hud.lua")

include("sh_equip_disguiser.lua")

// Clientside only stuff goes here

INTENSITY_LEVEL = INTENSITY_LEVEL or 1

function GM:InitPostEntity()
	hook.Run("PlayerDefinition",LocalPlayer())
	FreezeAllProps()
	LocalPlayer().LockPixVis = util.GetPixelVisibleHandle()
	
	RunConsoleCommand("cl_updaterate",20)
	
	//Remove matproxies. This is HUGE FPS sink with Nextbot which I don't take lightly.
	matproxy.Call = function() end
end

function GM:ShutDown()
	RunConsoleCommand("cl_updaterate",GetConVar("cl_updaterate"):GetDefault())
end

function GM:OnLoopEnd(loop)

	if INTENSITY_LEVEL == 4 then
		if loop == music.SuspenseToGuitar then
			SetIntensity(5)
		end
	elseif INTENSITY_LEVEL == 1 then
		if loop == music.AmbientLoop then
			SetIntensity(2)
		end
	end
	
	
end

local zoom = false
function GM:Think()
	
	-- if input.IsButtonDown(MOUSE_RIGHT) then
		
		-- if not zoom then
			-- zoom = true
			-- RunConsoleCommand("+zoom")
		-- end
		
	-- elseif zoom then
		-- RunConsoleCommand("-zoom")
		-- zoom = false
		
	-- end
	
end

function GM:CreateMove(cmd)
	local ply = LocalPlayer()
	//Right click zooms.
	if bit.band( buttons, IN_ATTACK2 ) == IN_ATTACK2 then
		if !ply.Zoomed then
			ply.Zoomed = true
		end
	elseif ply.Zoomed then
		ply.Zoomed = false
	end
	
	//Left click locks target.
	if bit.band( buttons, IN_ATTACK ) == IN_ATTACK then
		if !ply.lock_key_was_down then
			ply.lock_key_was_down = true
			if not IsValid(ply:GetLock()) then
				local tr = ply:GetEyeTraceInaccurate()
			
				//Else get ent at trace
				if tr.HitNonWorld and IsValid(tr.Entity) then
					if hook.Run("ASSCanPlayerLock", ply, tr.Entity) then
						ply:SetLock(tr.Entity)
					end
				end
			else
				ply:SetLock(NULL)
			end
		end
	elseif ply.lock_key_was_down then
		ply.lock_key_was_down = false
	end
end
net.Receive("ass_playerspawn",function()
	local ply = net.ReadEntity()
	GAMEMODE:PlayerSpawn(ply)
end)

net.Receive("ass_syncroundstates",function()
	ROUND_STATE = net.ReadTable()
end)

local meta = FindMetaTable("Player")
function meta:Frags() //Frags override because the client only gets sent a max of 2048 frags.
	return self:GetScore() or 0
end


function SetIntensity(i)
	if i == INTENSITY_LEVEL then return end
	if i==0 then
		music.StopMusic()
	--[[
	elseif i==1 then
		if INTENSITY_LEVEL == 4 then
			-- music.SetLoop(music.PostSound,0)
			music.SetLoop(music.AmbientLoop,-1)
		else
			music.SetNextLoop(music.AmbientLoop,-1)
		end
	elseif i==2 then
		music.SetNextLoop(music.SuspenseLoop,-1)
	elseif i==3 then
		-- music.SetNextLoop(music.SuspenseToGuitar,0)
		music.SetNextLoop(music.SuspenseLoop,-1)
	elseif i==4 then
		music.SetLoop(music.GuitarLoop, -1)
	end
	]]
	elseif i==1 then
		music.SetLoop(music.AmbientLoop,-1)
	elseif i==2 then
		music.SetNextLoop(music.AmbientLoop,-1)
	elseif i==3 then
		music.SetLoop(music.SuspenseLoop,-1)
	elseif i==4 then
		music.SetLoop(music.SuspenseToGuitar,0)
	elseif i==5 then
		music.SetLoop(music.GuitarLoop, -1)
	end
	
	INTENSITY_LEVEL = i
	
end
net.Receive("ass_intensity",function()
	SetIntensity(net.ReadUInt(3))
end)
