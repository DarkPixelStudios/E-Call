---@diagnostic disable: undefined-global

local function getOnlineFirefighterCount()
	if GetResourceState('es_extended') == 'started' then
		local ok, esx = pcall(function()
			return exports['es_extended']:getSharedObject()
		end)

		if ok and esx and esx.GetExtendedPlayers then
			local players = esx.GetExtendedPlayers('job', 'firefighter')
			if players then
				return #players
			end
		end
	end

	if GetResourceState('qb-core') == 'started' then
		local ok, qb = pcall(function()
			return exports['qb-core']:GetCoreObject()
		end)

		if ok and qb and qb.Functions and qb.Functions.GetQBPlayers then
			local count = 0
			local players = qb.Functions.GetQBPlayers()

			for _, player in pairs(players) do
				local job = player and player.PlayerData and player.PlayerData.job
				if job and job.name == 'firefighter' and (job.onduty == nil or job.onduty) then
					count = count + 1
				end
			end

			return count
		end
	end

	return -1
end

local function hasEnoughFirefightersOnline()
	local minimum = tonumber(Config.Firefighteronline) or 0
	if minimum <= 0 then
		return true
	end

	local count = getOnlineFirefighterCount()
	if count == -1 then
		return true
	end

	return count >= minimum
end

local scriptActive = hasEnoughFirefightersOnline()

local function broadcastScriptState(target)
	if target then
		TriggerClientEvent('patricks_unfallscript:client:setScriptActive', target, scriptActive)
		return
	end

	TriggerClientEvent('patricks_unfallscript:client:setScriptActive', -1, scriptActive)
end

CreateThread(function()
	while true do
		local newState = hasEnoughFirefightersOnline()
		if newState ~= scriptActive then
			scriptActive = newState
			broadcastScriptState()
		end

		Wait(5000)
	end
end)

RegisterNetEvent('patricks_unfallscript:server:requestScriptState', function()
	broadcastScriptState(source)
end)

RegisterNetEvent('patricks_unfallscript:server:triggerECall', function(coords)
	if type(coords) ~= 'vector3' then
		return
	end

	if not scriptActive then
		return
	end

	TriggerEvent('emergencydispatch:emergencycall:new', 'firefighter', 'Automatische Unfallerkennung [E-Call]', coords, true)
end)