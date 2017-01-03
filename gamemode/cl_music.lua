
local ply = LocalPlayer()
music = music or {}

hook.Add("InitPostEntity", "ass_SetupMusic", function()	
	music.CreateSound("assassins/music/guitarloop.wav", "GuitarLoop")
	music.CreateSound("assassins/music/suspenseloop.wav", "SuspenseLoop")
	music.CreateSound("assassins/music/ambientloop.wav", "AmbientLoop")
	music.CreateSound("assassins/music/suspensetoguitar.wav", "SuspenseToGuitar")
	music.CreateSound("assassins/music/prepsound.mp3", "PrepSound")
	music.CreateSound("assassins/music/postsound.mp3", "PostSound")
end)

function music.CreateSound(File, name)
	--There's some stupid callback lag so we need to work around it cleverly.
	local Sound = {}
	
	--Use this to determine length of sound. IGModAudioChannel can't do this apparently.
	Sound.snd = CreateSound(LocalPlayer(), File)
	
	local function finish()
		music[name] = Sound
	end
	
	local callback = function(s)
		Sound.len = s:GetLength()
		finish()
	end
	sound.PlayFile("sound/"..File,"noplay", callback)
	
	
end

music.NextLoop = {}--will contain sound and reps.
music.CurrentLoop = {sound=nil,reps=0}
music.BreakLoop = false

function music.SetLoop(sound,reps) -- to play continuously, do -1 reps.
	if not sound then return end
	music.StopMusic()
	
	music.CurrentLoop.sound = sound
	music.CurrentLoop.reps = reps
	timer.Create("assassins_MusicTimer", sound.len, 1, function() music.OnLoopEnd(sound) end)
	
	music.NextLoop = {}
	
	if ConVars.Client.music:GetBool() then
		sound.snd:Play()
	end
end

function music.StopMusic()
	timer.Destroy("assassins_MusicTimer")
	if music.CurrentLoop.sound then
		music.CurrentLoop.sound.snd:Stop()
	end
end

function music.OnLoopEnd(loop)
	GAMEMODE:OnLoopEnd(loop)
	if music.NextLoop.sound then --if there's another sound to play, play that.
		music.PlayNextLoop()
		music.BreakLoop = false
	elseif music.CurrentLoop.reps != 0 and not music.BreakLoop then --if the loop has more reps to go then play it again (excluding infinite loops)
		music.SetLoop(music.CurrentLoop.sound, music.CurrentLoop.reps-1) --subtract 1 from the reps.
	end
end

function music.PlayNextLoop()
	music.SetLoop(music.NextLoop.sound, music.NextLoop.reps)
end

function music.SetNextLoop(sound,reps)
	music.NextLoop = {sound=sound,reps=reps}
	if not timer.Exists("assassins_MusicTimer") then
		music.PlayNextLoop()
	end
end
