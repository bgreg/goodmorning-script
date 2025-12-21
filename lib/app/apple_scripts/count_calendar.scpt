tell application "Calendar"
	set todayStart to current date
	set time of todayStart to 0
	set todayEnd to todayStart + (24 * hours)

	set eventCount to 0
	repeat with cal in calendars
		set calEvents to (every event of cal whose start date ≥ todayStart and start date < todayEnd)
		set eventCount to eventCount + (count of calEvents)
	end repeat

	return eventCount
end tell
