-- ***************************************************************************************************************************************************
-- * Scheduler.lua                                                                                                                                   *
-- ***************************************************************************************************************************************************
-- * Coordinates execution of long tasks, so they don't trigger the Evil Watchdog                                                                    *
-- ***************************************************************************************************************************************************
-- * 0.4.12/ 2013.09.17 / Baanano: Updated events to the new model                                                                                   *
-- * 0.4.4 / 2012.09.26 / Baanano: Externalized to LibScheduler and added new features                                                               *
-- * 0.4.1 / 2012.08.12 / Baanano: Copied to LibPGCEx                                                                                                *
-- * 0.4.1 / 2012.07.10 / Baanano: Adapted to the new incarnation of the Watchdog                                                                    *
-- * 0.4.0 / 2012.05.30 / Baanano: First version                                                                                                     *
-- ***************************************************************************************************************************************************

local addonInfo, InternalInterface = ...
local addonID = addonInfo.identifier
_G[addonID] = _G[addonID] or {}
local PublicInterface = _G[addonID]

local WATCHDOG_LIMIT = 0.05
local NUM_INSTANCES = 1

local CCreate = coroutine.create
local CEAttach = Command.Event.Attach
local CResume = coroutine.resume
local CStatus = coroutine.status
local CYield = coroutine.yield
local ISWatchdog = Inspect.System.Watchdog
local TInsert = table.insert 
local TRemove = table.remove
local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local type = type

local activeQueue = {}
local waitQueue = {}
local taskLookup = {}
local taskSequence = 0

local function NormalizeWaitOn(taskIDs)
	if type(taskIDs) == "number" then taskIDs = { [taskIDs] = false, } end
	if type(taskIDs) ~= "table" then return nil end
	
	local normalizedTaskIDs = {}
	
	local empty = true
	for taskID, taskCascade in pairs(taskIDs) do
		if type(taskCascade) == "boolean" then
			if taskLookup[taskID] then
				normalizedTaskIDs[taskID] = taskCascade
				empty = false
			end
		elseif type(taskCascade) == "number" then
			if taskLookup[taskCascade] then
				normalizedTaskIDs[taskCascade] = false
				empty = false
			end
		end
	end
	
	if empty then return nil end
	
	return normalizedTaskIDs
end

local function TaskFinished(id, success, result)
	local task = nil
	
	local queue = taskLookup[id] or nil
	if not queue then return end
	for index, taskInfo in ipairs(queue) do
		if taskInfo.taskID == id then
			task = taskInfo
			TRemove(queue, index)
			taskLookup[id] = nil
			break
		end
	end
	
	if not task then return end
	
	local proceedChain = {}
	local errorChain = {}
	for index, taskInfo in ipairs(waitQueue) do
		if not success and taskInfo.waitingOn[id] then
			TInsert(errorChain, taskInfo.taskID)
		else
			taskInfo.waitingOn[id] = nil
			if not next(taskInfo.waitingOn) then
				TInsert(proceedChain, taskInfo.taskID)
			end
		end
	end
	
	if success then
		if type(task.onComplete) == "function" then
			pcall(task.onComplete, result)
		end
	else
		if type(task.onError) == "function" then
			pcall(task.onError, result)
		end
	end
	
	while #proceedChain > 0 do
		local proceedID = proceedChain[1]
		TRemove(proceedChain, 1)
		
		for index, taskInfo in ipairs(waitQueue) do
			if taskInfo.taskID == proceedID then
				TInsert(activeQueue, taskInfo)
				TRemove(waitQueue, index)
				taskLookup[proceedID] = activeQueue
			end
		end
	end
	
	for _, errorID in ipairs(errorChain) do
		TaskFinished(errorID, false, "Cascade task error")
	end
end

local function RunScheduler()
	while #activeQueue > 0 and ISWatchdog() > WATCHDOG_LIMIT do
		local nextTask = activeQueue[1]
		
		local success, result = CResume(nextTask.taskCoroutine)
		--if not success then print(result) end
		
		if CStatus(nextTask.taskCoroutine) == "dead" then
			TaskFinished(nextTask.taskID, success, result)
		end
	end
end
for instance = 1, NUM_INSTANCES do
	CEAttach(Event.System.Update.Begin, RunScheduler, addonID .. ".Scheduler." .. instance)
end

function PublicInterface.CreateTask(task, onComplete, onError, waitOn)
	if type(task) ~= "function" then return false end
	
	taskSequence = taskSequence + 1

	waitOn = NormalizeWaitOn(waitOn)
	
	local taskInfo =
	{
		taskID = taskSequence,          -- Unique identifier of the task
		taskCoroutine = CCreate(task),  -- Task coroutine
		onComplete = onComplete,        -- Function to call when the task is successfully completed
		onError = onError,              -- Function to call if the task fails
		waitingOn = waitOn,             -- Task IDs this task is waiting on, and whether errors in them cause this one to fail too
	}
	
	if waitOn then
		TInsert(waitQueue, taskInfo)
		taskLookup[taskSequence] = waitQueue
	else
		TInsert(activeQueue, taskInfo)
		taskLookup[taskSequence] = activeQueue
	end
	
	return taskSequence
end

function PublicInterface.WaitOn(taskIDs)
	local currentTask = #activeQueue > 0 and activeQueue[1] or nil
	if not currentTask or not currentTask.taskCoroutine or CStatus(currentTask.taskCoroutine) ~= "running" then return false end
	
	taskIDs = NormalizeWaitOn(taskIDs)
	if not taskIDs then return false end
	
	currentTask.waitingOn = taskIDs
	
	TInsert(waitQueue, currentTask)
	taskLookup[currentTask.taskID] = waitQueue
	TRemove(activeQueue, 1)
	
	CYield()
	return true
end

function PublicInterface.Release()
	local currentTask = #activeQueue > 0 and activeQueue[1] or nil
	if currentTask and currentTask.taskCoroutine and CStatus(currentTask.taskCoroutine) == "running" and ISWatchdog() <= WATCHDOG_LIMIT then
		CYield()
	end
end
