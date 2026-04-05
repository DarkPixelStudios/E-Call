---@diagnostic disable: undefined-global

local lastVehicle = 0
local lastHealthSample = nil
local dispatchCooldownUntil = 0
local scriptActive = false
local forcedDoorLocks = {}
local lastBlockedExitNotifyAt = 0

local function showBlockedExitNotification()
	if Config.NotifyBlockedExit == false then
		return
	end

	local now = GetGameTimer()
	local cooldown = tonumber(Config.NotifyBlockedExitCooldownMs) or 5000
	if now < (lastBlockedExitNotifyAt + cooldown) then
		return
	end

	lastBlockedExitNotifyAt = now

	local title = Config.NotifyBlockedExitTitle or 'E-CALL'
	local message = Config.NotifyBlockedExitMessage or 'Du kannst nicht aussteigen. Warte auf die Feuerwehr.'

	if GetResourceState('v42-notify') == 'started' then
		TriggerEvent('v42-notify:client:notify', {
			type = 'error',
			title = title,
			description = message,
			duration = cooldown
		})
		return
	end

	BeginTextCommandThefeedPost('STRING')
	AddTextComponentSubstringPlayerName(message)
	EndTextCommandThefeedPostTicker(false, false)
end

local function setDoorInteractionBlocked(vehicle, blocked)
	if not DoesEntityExist(vehicle) then
		return
	end

	if blocked then
		SetVehicleDoorsLocked(vehicle, 2)
		SetVehicleDoorsLockedForAllPlayers(vehicle, true)

		for doorIndex = 0, 7 do
			SetVehicleDoorShut(vehicle, doorIndex, false)
		end

		forcedDoorLocks[vehicle] = true
		return
	end

	if forcedDoorLocks[vehicle] then
		SetVehicleDoorsLockedForAllPlayers(vehicle, false)
		SetVehicleDoorsLocked(vehicle, 1)
		forcedDoorLocks[vehicle] = nil
	end
end

RegisterNetEvent('patricks_unfallscript:client:setScriptActive', function(state)
	scriptActive = state == true
end)

CreateThread(function()
	TriggerServerEvent('patricks_unfallscript:server:requestScriptState')
end)

local function getVehicleDamage(vehicle)
	local engineHealth = GetVehicleEngineHealth(vehicle)
	local bodyHealth = GetVehicleBodyHealth(vehicle)

	local engineDamage = 1000.0 - engineHealth
	local bodyDamage = 1000.0 - bodyHealth

	return math.max(engineDamage, bodyDamage)
end

CreateThread(function()
	while true do
		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped, false) then
			local vehicle = GetVehiclePedIsIn(ped, false)

			if GetPedInVehicleSeat(vehicle, -1) == ped then
				local damage = getVehicleDamage(vehicle)
				local now = GetGameTimer()
				local criticalDamage = scriptActive and damage >= Config.Damage

				if criticalDamage then
					DisableControlAction(0, 75, true)
					setDoorInteractionBlocked(vehicle, true)

					if IsDisabledControlJustPressed(0, 75) then
						showBlockedExitNotification()
					end

					if Config.BreakEngineOnCriticalDamage then
						SetVehicleEngineHealth(vehicle, 0.0)
						SetVehicleUndriveable(vehicle, true)
						SetVehicleEngineOn(vehicle, false, true, true)
					end
				else
					setDoorInteractionBlocked(vehicle, false)
				end

				local currentHealthSample = math.min(GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle))

				if lastVehicle ~= vehicle then
					lastVehicle = vehicle
					lastHealthSample = currentHealthSample
				else
					local delta = (lastHealthSample or currentHealthSample) - currentHealthSample

					if scriptActive and delta >= Config.CrashDelta and now >= dispatchCooldownUntil then
						local coords = GetEntityCoords(vehicle)
						TriggerServerEvent('patricks_unfallscript:server:triggerECall', coords)
						dispatchCooldownUntil = now + Config.CrashCooldownMs
					end

					lastHealthSample = currentHealthSample
				end
			end
		else
			lastVehicle = 0
			lastHealthSample = nil
		end

		Wait(100)
	end
end)