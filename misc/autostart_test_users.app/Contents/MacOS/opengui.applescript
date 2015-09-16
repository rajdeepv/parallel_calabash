#!/usr/bin/osascript
#
# Enable automatic graphic login.
#
# To log in to another machine, just opengui vnc://user:password@hostname
#
# To log in to the local host as another user, disable the localhost check for this machine:
#
# sudo defaults write com.apple.ScreenSharing skipLocalAddressCheck -boolean YES
#
# Then, once after each reboot, redirect the port as ANY user:
#
# ssh -N -L 6900:127.0.0.1:5900 user@localhost &
#
# Then run this for each user for which you want an active desktop:
#
# opengui vnc://user:password@localhost:6900

on run argv
	local originalWindowCount
	local tryCount
	local vncUrl
	set vncUrl to item 1 of argv
	#set vncUrl to "vnc://ruthmarten:qazwsx@localhost:6900"
	tell application "Screen Sharing" to activate
	tell application "System Events" to tell application process "Screen Sharing"
		set originalWindowCount to (count of windows)
	end tell
	tell application "Screen Sharing"
		GetURL vncUrl
	end tell
	tell application "System Events"
		tell application process "Screen Sharing"
			set tryCount to 100 # 10 seconds
			repeat until exists window "Screen Sharing"
				delay 0.1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					exit repeat
				end if
			end repeat
			tell window "Screen Sharing"
				click radio button 2 of radio group 1
				click button 2
			end tell
			set tryCount to 300 # 30 seconds
			repeat while (exists window "Screen Sharing") or ((count of windows) = originalWindowCount)
				delay 0.1
				set tryCount to tryCount - 1
				if tryCount = 0 then
					display dialog "Original window count = " & originalWindowCount & " but currently " & (count of windows)
					exit repeat
				end if
			end repeat
		end tell
		set visible of process "Screen Sharing" to false
	end tell
end run