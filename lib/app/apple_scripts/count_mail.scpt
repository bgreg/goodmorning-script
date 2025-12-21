tell application "Mail"
	if not running then return 0

	set totalUnread to 0
	repeat with acct in accounts
		repeat with mb in mailboxes of acct
			if name of mb is "INBOX" then
				set totalUnread to totalUnread + (unread count of mb)
			end if
		end repeat
	end repeat

	return totalUnread
end tell
