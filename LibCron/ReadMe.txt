Scheduled and/or regular events:

	tag = cron.create(time, function, ...)
		In time seconds (or a little longer), call function(...).
	tag = cron.recurring(interval, function, ...)
		Call function(...) every interval seconds, starting about
		interval seconds from now.  If interval is 0, calls every
		update.

	cron.delete(tag)
		Deletes tag.  This tag is no longer valid, and will
		not be called.
	cron.snooze(tag, secs)
		Postpones tag.

	func, ... = cron.details(tag)
	secs = cron.remaining(tag)

/cron -l
	List tags
/cron -d <tag>
/cron -s <tag> <secs>
/cron -c <secs> code
/cron -r <secs> code
/cron -v
	Toggle error reporting/tracebacks from calls.
