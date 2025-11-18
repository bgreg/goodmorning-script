on run argv
	set maxEmails to item 1 of argv as integer

	tell application "Mail"
		set unreadMessages to (every message of inbox whose read status is false)
		set emailList to {}

		repeat with i from 1 to (count of unreadMessages)
			if i > maxEmails then exit repeat
			set thisMessage to item i of unreadMessages
			set emailInfo to (subject of thisMessage) & " | " & (sender of thisMessage)
			set end of emailList to emailInfo
		end repeat

		return emailList as text
	end tell
end run
