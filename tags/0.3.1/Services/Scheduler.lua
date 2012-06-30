-- ***************************************************************************************************************************************************
-- * Services/Scheduler.lua                                                                                                                          *
-- ***************************************************************************************************************************************************
-- * Coordinates execution of long tasks, so they don't trigger the Evil Watchdog                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.0  / 2012.05.30 / Baanano: First version                                                                                                    *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier

local WATCHDOG_TIME = 0.1
local LIMITS = { 0.75, 0.6, 0.6, 0.45, 0.3, 0.15 }
local PRIORITIES =
{
	CRITICAL = 1,
	HIGH = 2,
	UI = 3,
	MEDIUM = 4,
	LOW = 5,
	IDLE = 6,
}

local cronActive = false
local cronID = nil
local queues = { {}, {}, {}, {}, {}, {} }

local CCreate,          CStatus,          CResume,          ITFrame,            ITReal,            TInsert,      TRemove = 
      coroutine.create, coroutine.status, coroutine.resume, Inspect.Time.Frame, Inspect.Time.Real, table.insert, table.remove
local CronNew, CronPause, CronResume = Library.LibCron.new, Library.LibCron.pause, Library.LibCron.resume

local function GetSpentTimeSlice()
	return (ITReal() - ITFrame()) / WATCHDOG_TIME
end

local function RunTask(taskCoroutine, priority)
	local run, result = false, nil
	while CStatus(taskCoroutine) ~= "dead" and GetSpentTimeSlice() < LIMITS[priority] do
		local ok
		ok, result = CResume(taskCoroutine)
		if not ok then error(result) end
		run = true
	end
	return run, result
end

local function RunScheduler()
	local noTasks = true
	for priority, queue in ipairs(queues) do
		local stop = false
		noTasks = noTasks and #queue <= 0

		while #queue > 0 do
			local nextTask = queue[1]
			local ok, run, result = pcall(RunTask, nextTask[1], priority)
			
			if not ok then
				TRemove(queue, 1)
				error(run)
			end
			
			if run then
				if CStatus(nextTask[1]) == "dead" then
					TRemove(queue, 1)
					if type(nextTask[2]) == "function" then
						nextTask[2](result)
					end
				end
			else
				stop = true
				break
			end
		end
		
		if stop then break end
	end
	if noTasks then
		CronPause(cronID)
		cronActive = false
	end
end
cronID = CronNew(addonID, 0, true, true, RunScheduler)
if cronID then CronPause(cronID) end

InternalInterface.Scheduler = InternalInterface.Scheduler or {}

-- ***************************************************************************************************************************************************
-- * Priorities (enum)                                                                                                                               *
-- ***************************************************************************************************************************************************
-- * The possible priorities the processes may use                                                                                                   *
-- ***************************************************************************************************************************************************
InternalInterface.Scheduler.Priorities = PRIORITIES

function InternalInterface.Scheduler.QueueTask(priority, task, callback)
	priority = type(priority) == "number" and priority or PRIORITIES[priority or 0]
	if not priority or not queues[priority] or type(task) ~= "function" then return false end
	
	local queuedTask = { CCreate(task), callback }
	
	TInsert(queues[priority], queuedTask)
	if not cronActive then
		CronResume(cronID)
		cronActive = true
	end
	return true
end