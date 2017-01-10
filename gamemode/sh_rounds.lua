

ROUND_START_TIME,ROUND_DURATION = ROUND_START_TIME or 0, ROUND_DURATION or 0
ROUND_STATE = ROUND_STATE or {}
CURRENT_ROUND = CURRENT_ROUND or 1

function AddRoundState(name, time) --If you want the ROUND_STATE to have no time limit, use 0 as the time.
	local num = #ROUND_STATE+1
	local time = time or 0
	local rnd = {time=time,name=name, number=num}
	ROUND_STATE[num] = rnd
	if not CURRENT_STATE then
		if SERVER then
			hook.Add("PostNavmeshLoaded", "ass_roundRotation", function()
				GAMEMODE:SetRoundNumber(1) --Must be called as lua starts up.
			end)
		end
	end
	return rnd
end

if SERVER then
	
	//Define ROUND_STATE States
	hook.Add("InitPostEntity","ass_roundinit",function()
		AddRoundState("Prep", ConVars.Server.prep:GetFloat())	-- state 1
		AddRoundState("Active", ConVars.Server.active:GetFloat())	-- state 2
		AddRoundState("Post", ConVars.Server.post:GetFloat())	-- state 3
	end)
	
	util.AddNetworkString("ass_roundstate")
	
	//Call this hook to change the round number. Also resets the round state to 1.
	function GM:SetRoundNumber(num)
		--Do Stuff Here. Do not override unless you mean it.
		
		CURRENT_ROUND = num
		hook.Run("SetRoundState", ROUND_STATE[1])--Keep these lines if you override it.
	end
	
	//Call this hook to change the round state. Probably shouldn't override it.
	function GM:SetRoundState(state)
		--Do Stuff Here. Do not override unless you mean it.
		
		CURRENT_STATE=state
		GAMEMODE:RoundStateChanged(state, CURRENT_ROUND)--Keep these lines if you override it.
		net.Start("ass_roundstate")
			net.WriteUInt(state.number,4)
			net.WriteUInt(CURRENT_ROUND,16)
			net.WriteBool(false)
		net.Broadcast()
		
	end
	
	function GM:ShouldProgressRound(state,ROUND_STATE)
		if not (#player.GetAll() > 2) then
			WAITING_FOR_PLAYERS = true
			-- print("Not enough players to change rounds.")
			return false
		end
		return true
	end
	
	function ProgressRound(notfirst) //Increases ROUND_STATE state by 1 until it reaches more than there are states, then goes back to 1 and increases current ROUND_STATE.
		local state = CURRENT_STATE
		if GAMEMODE:ShouldProgressRound(CURRENT_ROUND,state) then
			if not ROUND_STATE[state.number+1] then 
				GAMEMODE:SetRoundNumber(CURRENT_ROUND+1)
			else
				state = ROUND_STATE[state.number+1]
				hook.Run("SetRoundState", state)
			end
		else
			if !notfirst then
				print("Can't change round states yet. Waiting...")
			end
			timer.Simple(1, function() ProgressRound(true) end)
		end
	end
	
	concommand.Add("ass_progressround",function(p,c,a)
		if a:IsSuperAdmin() then
			ProgressRound()
		end
	end)
	
else
	function ProgressRound() end
end

function RoundStateTimeLeft()
	return math.max(0, ROUND_DURATION - (CurTime() - ROUND_START_TIME))
end

function StartStateTimer(state,amt) --Starts the timer for the given ROUND_STATE state. Calls ProgressRound when it's finished.
	ROUND_START_TIME = CurTime()
	ROUND_DURATION = amt or state.time
	if SERVER then
		if state.time > 0 then
			timer.Create("ass_roundstate", amt or state.time, 1, ProgressRound)
		else
			timer.Destroy("ass_roundstate")
		end
	end
end

function GetRoundState()
	return CURRENT_STATE
end
function GetRoundNumber()
	return CURRENT_ROUND
end
--On ROUND_STATE changed. This is the main round logic hook
function GM:RoundStateChanged(state, round)
	-- debug.Trace()
	if CLIENT then
		hud.RoundStateChanged(round,state)
	end
	
	if state.number == 1 and round == 1 then
		StartStateTimer(state,GetConVarNumber("ass_firstpreptime"))
	else
		StartStateTimer(state)
	end
	
	-- print(round, table.ToString(state or {}))
	if state.number == 1 then
	
		if CLIENT then
			
			print("ROUND "..round.." is now preparing.")
			if not music then 
				timer.Simple(1, function() music.SetLoop(music.PrepSound, 0) end)
			else
				music.SetLoop(music.PrepSound, 0)
			end
			
			
		else
			
			print("ROUND "..round.." is now preparing.")
			
			SpawnAllBystands()
			ClearScores()
			
		end
		
		
	elseif state.number == 2 then
		
		print("ROUND "..round.." is now active.")
		if CLIENT then
			hud.FadeIn(4)
			SetIntensity(1)
		else
			AssignRoles()
			SpawnAllPlayers()
			AssignAllTargets()
		end
		
		
	else
		
		print("ROUND "..round.." has ended.")
		if CLIENT then
			hud.FadeOut(4)
			SetIntensity(0)
			music.SetLoop(music.PostSound, 0)
			ShowScores()
		else
			local scores = player.GetScoreSorted()
			PrintMessage(HUD_PRINTCONSOLE,"1st place: "..scores[1]:Nick())
			PrintMessage(HUD_PRINTCONSOLE,"2nd place: "..scores[2]:Nick())
			PrintMessage(HUD_PRINTCONSOLE,"3nd place: "..scores[3]:Nick())
			CleanupEverything()
		end
		
		
	end
	
end
net.Receive("ass_roundstate",function()
	local state, round = net.ReadUInt(4),net.ReadUInt(16)
	print("Round state changed: round, state=", round..","..state)
	CURRENT_ROUND,CURRENT_STATE = round, ROUND_STATE[state]
	hook.Run("RoundStateChanged",CURRENT_STATE,CURRENT_ROUND)
	
	local b = net.ReadBool()
	if b then
		ROUND_DURATION = CURRENT_STATE.time
		ROUND_START_TIME = net.ReadFloat()
	end
end)
