﻿iniAllActions.="Recycle_file|" ;Add this action to list of all actions on initialisation

runActionRecycle_file(InstanceID,ThreadID,ElementID,ElementIDInInstance)
{
	global
	
	local tempPath:=% v_replaceVariables(InstanceID,ThreadID,%ElementID%file)
	if  DllCall("Shlwapi.dll\PathIsRelative","Str",tempPath)
		tempPath:=SettingWorkingDir "\" tempPath
	
	FileRecycle,% tempPath
	if ErrorLevel
	{
		logger("f0","Instance " InstanceID " - " %ElementID%type " '" %ElementID%name "': Error! File '" tempPath "' not recycled.")
		MarkThatElementHasFinishedRunning(InstanceID,ThreadID,ElementID,ElementIDInInstance,"exception",lang("File '%1%' not recycled",tempPath))
		return
	}
	
	MarkThatElementHasFinishedRunning(InstanceID,ThreadID,ElementID,ElementIDInInstance,"normal")
	return
}
getNameActionRecycle_file()
{
	return lang("Recycle_file")
}
getCategoryActionRecycle_file()
{
	return lang("Files")
}

getParametersActionRecycle_file()
{
	global
	
	parametersToEdit:=Object()
	parametersToEdit.push({type: "Label", label: lang("Select file")})
	parametersToEdit.push({type: "File", id: "file", label: lang("Select a file")})

	return parametersToEdit
}

GenerateNameActionRecycle_file(ID)
{
	global
	;MsgBox % %ID%text_to_show
	
	
	return lang("Recycle_file") " " GUISettingsOfElement%ID%file ": " GUISettingsOfElement%ID%text
	
}

CheckSettingsActionRecycle_file(ID)
{
	
	
}
