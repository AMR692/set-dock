#!/usr/bin/osascript

-- Applications will be added in the order they appear in this list.
-- Use full POSIX pathnames
-- Any application that is not installed will be skipped and not added to the Dock.
set ApplicationsToAdd to {"/Applications/App Store.app", ¬
	"/Applications/BBEdit.app", ¬
	"/Applications/Google Chrome.app", ¬
	"/Applications/FaceTime.app", ¬
	"/Applications/Safari.app", ¬
	"/Applications/Script Editor.app", ¬
	"/Applications/System Preferences.app", ¬
	"/System/Applications/System Preferences.app"}

-- This is a list of folders (full POSIX pathnames) that will be added to the right side
-- of the Dock. Again, use full POSIX pathnames
set FoldersToAdd to {POSIX path of (path to applications folder), POSIX path of (path to downloads folder)}

(* *** No need to change anything beneath this line *** *)
try
	set BackupFileLocation to ((path to preferences folder as string) & "com.apple.dock.plist.bak") as alias
	set BackupExists to true
on error
	set BackupExists to false
end try

try
	if BackupExists then
		set request to button returned of (display dialog "This script will REPLACE the Dock icons with the default " & (name of me) & " set. Proceed with caution!" buttons {"Restore from backup", "Cancel", "OK"} cancel button "Cancel" default button "OK" with icon caution with title (name of me))
	else
		set request to button returned of (display dialog "This script will REPLACE the Dock icons with the default " & (name of me) & " set. Proceed with caution!" buttons {"Cancel", "OK"} cancel button "Cancel" default button "OK" with icon caution with title (name of me))
	end if
on error
	return
end try

try
	do shell script "cat /dev/null" with administrator privileges
on error
	return
end try

if request is "Restore from backup" then
	do shell script "mv ~/Library/Preferences/com.apple.dock.plist.bak ~/Library/Preferences/com.apple.dock.plist"
	do shell script "pkill cfprefsd" with administrator privileges
	do shell script "pkill Dock" with administrator privileges
	return
end if

-- create backup of old Dock
do shell script "cp ~/Library/Preferences/com.apple.dock.plist ~/Library/Preferences/com.apple.dock.plist.bak"

-- remove all icons from Dock
do shell script "defaults write com.apple.dock persistent-apps -array '{}'"
do shell script "defaults write com.apple.dock persistent-others -array '{}'"

set ApplicationsAvailable to {}
repeat with i in ApplicationsToAdd
	tell application "System Events"
		if file i exists then
			-- cribbed from https://stackoverflow.com/questions/59614341/add-terminal-to-dock-persistent-apps-with-default-write-with-foreign-language-ma
			-- https://developer.apple.com/documentation/devicemanagement/dock was helpful too
			set ApplicationsAvailable to ApplicationsAvailable & {("'<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>" & i & "</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'") as string}
		end if
	end tell
end repeat

repeat with i in ApplicationsAvailable
	do shell script "defaults write com.apple.dock persistent-apps -array-add " & (i as string)
end repeat

repeat with i in FoldersToAdd
	do shell script "defaults write com.apple.dock persistent-others -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>" & i & "</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'"
end repeat

do shell script "pkill cfprefsd" with administrator privileges
do shell script "pkill Dock" with administrator privileges