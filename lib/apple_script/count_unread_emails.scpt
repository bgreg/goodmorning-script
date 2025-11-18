tell application "Mail"
	count (every message of inbox whose read status is false)
end tell
