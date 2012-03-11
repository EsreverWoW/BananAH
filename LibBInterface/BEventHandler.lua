function Library.LibBInterface.BEventHandler(element, events)
	local newEventHandler = {}
	local handledEvents = {}
	
	for _, event in pairs(events) do
		handledEvents[event] = true
	end

	local oldEventHandler = element.Event

	setmetatable(newEventHandler, {
		__index = function(tab, event)
			if handledEvents[event] then
				return rawget(tab, event)
			elseif oldEventHandler then
				return oldEventHandler[event]
			else
				error("Invalid event: " .. event)
			end
		end,
		
		__newindex = function(tab, event, func)
			if handledEvents[event] then
				rawset(tab, event, func)
			elseif oldEventHandler then
				oldEventHandler[event] = func
			else
				error("Invalid event: " .. event)
			end
		end
	})

	element.Event = newEventHandler
end