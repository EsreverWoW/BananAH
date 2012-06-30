--[[ LibCron

]]--

local addoninfo, cron = ...
Library = Library or {}
Library[addoninfo.identifier] = cron

local events = {} -- Baanano: extracted "private" variables and functions from cron.* to local to prevent manipulation
local sorted_tags = {}
local next_tag = 1 -- Baanano: Assign increasing Task IDs instead of reusing them

function sort_events()
  table.sort(sorted_tags, function(a, b) return (events[a] and events[a].stamp or 0) < (events[b] and events[b].stamp or 0) end)
  -- IDEA: Fire Event.LibCron.TaskListChanged
end

local function cron_printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

local function update()
  local now = Inspect.Time.Frame()
  
  local tag = sorted_tags[1]
  local event = tag and events[tag]
  while event and event.stamp < now do
    -- Baanano: Can't track errors anymore, as execution is being credited to the addon that registered the task
    Utility.Dispatch(event.func, event.addon, "(" .. addoninfo.identifier .. " task)")
    
    if type(event.recurring) == "number" then -- Baanano: Now recurring can be a number of repetitions
      event.recurring = event.recurring - 1
      if event.recurring <= 0 then
        table.remove(sorted_tags, 1)
        events[tag] = nil
        -- IDEA: Fire Event.LibCron.TaskFinished(tag)
        event = nil
      end
    end
    if event then
      event.stamp = math.max(now, event.stamp + event.secs)
    end

    sort_events()

    tag = sorted_tags[1]
    event = tag and events[tag]
  end
end

function cron.list()
  local now = Inspect.Time.Frame()
  cron_printf("Tags:")
  for _, tag in ipairs(sorted_tags) do
    local event = events[tag]
    if event then
      -- Baanano: Added new features to the list (prevent_delete, number of repetitions, addon name, pause state)
      cron_printf("%s%-3d %3s %s %s %s", event.prevent_delete and "@" or " ", tag, event.recurring == true and "***" or event.recurring, event.addon, event.pause and "(paused)" or string.format("%-6.1f", event.stamp - now), event.code or tostring(event.func))
    end
  end
end

function cron.delete(tag)
  local found
  for idx, value in ipairs(sorted_tags) do
    if value == tag then
      found = idx
      break
    end
  end
  if found and not events[tag].prevent_delete then
    table.remove(sorted_tags, found)
    events[tag] = nil
    -- IDEA: Fire Event.LibCron.TaskRemoved(tag)
  end
end

function cron.snooze(tag, secs)
  if not secs or type(secs) ~= 'number' then
    cron_printf("Snooze: Must be given number of seconds.")
    return false
  end
  
  if events[tag] then
    events[tag].stamp = events[tag].stamp + secs
    sort_events()
    return true
  else
    cron_printf("Snooze: Invalid tag '%s'.", tostring(tag))
    return false
  end
end

-- Baanano: new creating method
function cron.new(addon, secs, repeats, prevent_delete, func, ...)
  local now = Inspect.Time.Frame()

  if not pcall(Utility.Dispatch, function() end, addon, "Test") then
    cron_printf("Create failed: addon doesn't exist")
    return nil
  end

  if not secs or type(secs) ~= "number" then
    cron_printf("Create failed: seconds must be numeric.")
    return nil
  end

  if repeats and type(repeats) ~= "number" and type(repeats) ~= "boolean" then
    cron_printf("Create failed: repeats must be a number or boolean value.")
    return nil
  end
  if not repeats or (type(repeats) == "number" and repeats < 1) then repeats = 1 end

  prevent_delete = prevent_delete and true or nil

  local args = { ... }
  local closure = function() func(unpack(args)) end
  local event = { addon = addon, secs = secs, recurring = repeats, prevent_delete = prevent_delete, func = closure, stamp = now + secs }

  local tag = next_tag
  next_tag = tag + 1
  
  events[tag] = event
  table.insert(sorted_tags, tag)
  -- IDEA: Fire Event.LibCron.TaskAdded(tag)
  
  sort_events()
  
  return tag
end

-- Baanano: old creating methods, maintain behaviour and use addoninfo.identifier as identifier
function cron.create(secs, func, ...)
  return cron.new(addoninfo.identifier, secs, 1, nil, func, ...)
end

function cron.recurring(secs, func, ...)
  return cron.new(addoninfo.identifier, secs, true, nil, func, ...)
end

-- Baanano: new pause method
function cron.pause(tag)
  local now = Inspect.Time.Frame()
  
  if not events[tag] then
    cron_printf("Pause: Invalid tag '%s'.", tostring(tag))
    return false
  end
  
  if events[tag].pause then
    cron_printf("Pause: Already paused '%s'.", tostring(tag))
    return false
  end
  
  events[tag].pause = events[tag].stamp - now
  events[tag].stamp = math.huge
  sort_events()
  return true
end

-- Baanano: new resume method
function cron.resume(tag)
  local now = Inspect.Time.Frame()
  
  if not events[tag] then
    cron_printf("Resume: Invalid tag '%s'.", tostring(tag))
    return false
  end
  
  if not events[tag].pause then
    cron_printf("Resume: Already active '%s'.", tostring(tag))
    return false
  end
  
  events[tag].stamp = events[tag].pause + now
  events[tag].pause = nil
  sort_events()
  return true
end

if Library.LibGetOpt then -- Baanano: Made LibGetOpt optional
  local function slashcommand(args)
    if not args or not (args.c or args.d or args.l or args.r or args.s or args.p or args.u) then -- Baanano: Added p (pause) and u (unpause/resume)
      print [[Usage:
  /cron -l
    List tags
  /cron -c <secs> code
  	Create one-time tag.
  /cron -d <tag>
  	Delete a tag.
  /cron -r <secs> code
  	Recur every <secs> seconds.
  /cron -R n [...]
  	Specify repeat count.
  /cron -s <tag> <secs>
  	Snooze a tag.
  /cron -p <tag>
  /cron -u <tag>]]
      return
      end

    if args.l then
      cron.list()
      return
    end
    
    if args.d then
      cron.delete(args.d)
      return
    end

    if args.s then
      local secs = tonumber(args.leftover_args[1])
      if secs then
        cron.snooze(args.s, secs)
      else
        cron_printf("Usage: /cron -s <tag> <secs>")
      end
      return
    end

    if args.c or args.r then
      local func, err = loadstring(args.leftover)
      if func then
        local tag
        if args.c then
          tag = cron.create(args.c, func)
        else
	  if args.R then
	    tag = cron.new(addoninfo.identifier, args.r, tonumber(args.R), nil, func)
	  else
            tag = cron.recurring(args.r, func)
	  end
        end
        events[tag].code = args.leftover
      else
          cron_printf("Failed to load code: %s", err)
          return
      end
    end
    
    if args.p then
      cron.pause(args.p)
      return
    end
    
    if args.u then
      cron.resume(args.u)
      return
    end
  end
  Library.LibGetOpt.makeslash("c#d#lr#R#s#p#u#", addoninfo.identifier, "cron", slashcommand)
end

table.insert(Event.System.Update.Begin, { update, addoninfo.identifier, "update hook" })
