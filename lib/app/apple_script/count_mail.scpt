tell application "Mail"
	if it is running then
		count (every message of inbox whose read status is false)
	else
		0
	end if
end tell
