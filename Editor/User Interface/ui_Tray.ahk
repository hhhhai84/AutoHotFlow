﻿

if A_IsCompiled
{
	menu, tray, NoStandard
}
else
{

	
}
initializeTrayBar()

;Help! I want that the menu are renamed when the language changes.
initializeTrayBar()
{
	global
	;~ try menu,tray,deleteall
	
	menu, tray, add,  Show
	menu, tray, Default, Show
	Tray_OldShowName=Show

	menu, tray, add, ui_Menu_MenuStart
	menu, tray, rename, ui_Menu_MenuStart,% lang("Run")

	menu, tray, add, ui_Menu_Enable
	menu, tray, rename, ui_Menu_Enable,% lang("Enable")

	menu, tray, add, Exit
	menu, tray, rename, Exit,% lang("Exit")

	menu tray,icon,Icons\disabled.ico
}

goto,JumpOverTrayStuff



Show:
ui_showgui()

return

JumpOverTrayStuff:
temp= ;Do nothing