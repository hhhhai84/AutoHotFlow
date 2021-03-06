﻿
;initialise with empty objects

InstanceIDList:=Object()
r_RunningCounter=0
r_RunningThreadCounter=0
r_RunsBlocked:=false
MaximumCountOfParallelInstances:=100
executionSpeed=1 ;The smaller the value the faster

ToTriggerList:=Object()

r_Trigger(ElementID,Execution_Parameters="")
{
	global
	
	;~ Logger("a3","Passing r_Trigger() function")
	
	if r_RunsBlocked
		return
	
	if (InstanceIDList.MaxIndex()>MaximumCountOfParallelInstances)
	{
		Logger("f1","Already " MaximumCountOfParallelInstances "Instances are running. Skipping execution")
		return
	}
	
	local ToTrigger:=Object()
	ToTrigger["ElementID"]:=ElementID
	ToTrigger["Execution_Parameters"]:=Execution_Parameters
	ToTriggerList.push(ToTrigger)
	
	SetTimer,r_TriggerNow,-10
	
	
}

r_TriggerNow()
{
	global
	local ToTrigger
	local ElementID
	;~ Logger("a3","Passing r_TriggerNow() function")
	if r_RunsBlocked
		return
	
	Loop
	{
		ToTrigger:=ToTriggerList.pop()
		if isobject(ToTrigger)
		{
			ElementID:=ToTrigger["ElementID"]
			
			Logger("f1",%ElementID%type " '" %ElementID%name "': Trigger executes")
			r_startRun(ToTrigger["Execution_Parameters"])
		}
		else
			break
	}
	
}


;Starts a new instance
r_startRun(Execution_Parameters="")
{
	global
	
	local temp
	local tempID
	;~ Logger("a3","Passing r_startRun() function")
	if r_RunsBlocked
		return
	
	logger("f1","Starting new instance")
	
	
	if (nowrunning=true) ;If the flow is already running.
	{
		;Consider the execution policy setting
		if SettingFlowExecutionPolicy=stop ;Stop current instance and start a new one
		{
			logger("f1","An instance already exists. Old execution stopped to launch the new one.")
			gosub r_escapeRunNoBlock
			SetTimer,r_WaitUntilStoppedAndThenStart,50
			return
		}
		else if SettingFlowExecutionPolicy=wait ;Wait until the current instance has finished
		{
			logger("f2","An instance already exists. Execution will wait.")
			temp= ;Do nothing. In the run loop will only the first instance be considered
		}
		else if SettingFlowExecutionPolicy=skip ;Skip the execution
		{
			logger("f1","An instance already exists. Execution skipped.")
			return
		}
		else if SettingFlowExecutionPolicy=parallel ;Execute multiple instancec parallel
		{
			if (InstanceIDList.MaxIndex()>MaximumCountOfParallelInstances)
			{
				logger("f1","An instance already exists. This execution should run parallel, but already " MaximumCountOfParallelInstances " are running. Execution skipped.")
				return
			}
			else
				logger("f2","An instance already exists. This execution is going to run parallel.")
			
			
			
		}
		
	}
	
	Critical on ;This code generates one instance. it should not be interrupted. (especially if a new instance should be created)
	r_RunningCounter++
	r_RunningThreadCounter++
	
	
	
	InstanceIDList.insert("Instance_" r_RunningCounter) ;Insert a new Instance
	Instance_%r_RunningCounter%_RunningCounter=1 ;Counter that is incremented every time a new element is going to run
	Instance_%r_RunningCounter%_RunningElements:=Object() ;Create an object for the instance containing the running elements
	Instance_%r_RunningCounter%_RunningElements.insert(r_RunningThreadCounter "_trigger_" Instance_%r_RunningCounter%_RunningCounter) ;A flow is always launched from trigger
	Instance_%r_RunningCounter%_LocalVariables:=Object() ;Create an object for the instance containing the running elements
	Instance_%r_RunningCounter%_Thread_%r_RunningThreadCounter%_Variables:=Object() ;Create an object for the instance containing the running elements
	
	;MsgBox %ThisExecution_CallingFlow%
	;MsgBox %ThisExecution_InstanceIDOfCallingFlow%
	;MsgBox %ThisExecution_WhetherToReturVariables%
	;MsgBox %ThisExecution_ElementIDInInstanceOfCallingFlow%
	;if an other flow has called this flow. Those variables will be needed to get the variables from the other flow, inform it when this flow has finished and send the variables back.
	if isobject(Execution_Parameters)
	{
		
		;~ MsgBox % strobj(Execution_Parameters)
		Instance_%r_RunningCounter%_CallingFlow:=Execution_Parameters["SendingFlow"]
		Instance_%r_RunningCounter%_ElementIDInCallingFLow:=Execution_Parameters["CallerElementID"]
		Instance_%r_RunningCounter%_InstanceIDOfCallingFlow:=Execution_Parameters["CallerInstanceID"]
		Instance_%r_RunningCounter%_ThreadIDOfCallingFlow:=Execution_Parameters["CallerThreadID"]
		Instance_%r_RunningCounter%_ElementIDInInstanceOfCallingFlow:=Execution_Parameters["CallerElementIDInInstance"]
		Instance_%r_RunningCounter%_WhetherToReturVariables:=Execution_Parameters["WhetherToReturVariables"]
		
		;~ MsgBox % Execution_Parameters["localVariables"] "`n`n" strobj(Execution_Parameters)
		
		;Import variables if the trigger provides some variables or if an other flow has called this flow.
		if isobject(Execution_Parameters["localVariables"])
			v_ImportLocalVariablesFromObject(r_RunningCounter,Execution_Parameters["localVariables"])
		else
			v_ImportLocalVariablesFromString(r_RunningCounter,Execution_Parameters["localVariables"])
		
		if isobject(Execution_Parameters["threadVariables"])
		{
			v_ImportThreadVariablesFromObject(r_RunningCounter,r_RunningThreadCounter,Execution_Parameters["ThreadVariables"])
		}
		else
			v_ImportThreadVariablesFromString(r_RunningCounter,r_RunningThreadCounter,Execution_Parameters["ThreadVariables"])
		
		logger("f2","Instance " r_RunningCounter ": the flow was called by " Execution_Parameters["CallingFlow"])
	}
	
	
	v_setVariable(r_RunningCounter,r_RunningThreadCounter,"a_triggertime",a_now,"Date",c_SetBuiltInVar) ;Set the triggertime variable
	
	;set some variables for correct  visual appearance of the trigger
	if (triggerrunning<=0)
			triggerrunning=1
		else
			triggerrunning++
	Instance_%r_RunningCounter%_%r_RunningThreadCounter%_trigger_1_finishedRunning:=true 
	Instance_%r_RunningCounter%_%r_RunningThreadCounter%_trigger_1_result=normal
	
	
	if (nowRunning!=true) ;if not already running, execute the r_run() function. of not the currently running r_run function will find that new thread
	{
		nowRunning:=true
		stopRun:=false
		
		r_TellThatFlowIsStarted() ;Tell manager that flow has started. Also replace some text in the GUI buttons.
		Critical off
		UI_draw()
		r_run()
		
	}
	runNeedToRedraw:=true
	
	Critical off
	
	UI_draw()

	;Hotkey,esc,r_escapeRun,on
	
	
	

	
}

r_run()
{
	global
	local temp
	
	;~ Logger("a3","Passing r_run() function")
	nextrun: ;endless loop until no elements to execute left
	;~ Logger("a3","Passing nextrun label")
	FlowLastActivity:=a_now

	;lower the priority. This would make any interrupted ahk threads finish. (like redraw)
	thread, Priority, -100
	Thread, Interrupt, 0,0

	
	goingToRunIDs:=Object() ;contains the Element IDs with instance ID that are going to run now
	runNeedToRedraw:=false
	
	;The previous running elements are shown pink for a certain time
	for count, tempID in allElements
	{
		;The elements that have been running shortly before have a negative number that will be incremented until 0
		if (%tempID%running<0)
		{
			
			%tempID%running++
			if (%tempID%running=0)
				runNeedToRedraw:=true
		}
	}
	

	
	;MsgBox
	ElementsThatHaveFinished:=Object() ;Contains all elements that have finished right now
	InstancesThatHaveFinished:=Object() ;Contains all instances that have finishd right now
	;Go through all running instances. Find elements that are still running. Find elements that have finished and prepare connected elements to run. 
	for index1, tempInstanceID in InstanceIDList ;Go through all instances
	{
		if (SettingFlowExecutionPolicy="wait" && index1!=1) ;If execution policy allows only one running instance and others have to wait
			break
			
		
		
		
		tempCountOfRunningElementsInInstance=0 ;Empty the counter of running elements in the current instance. If the number will remain 0 the instance will be removed
		;MsgBox tempInstanceID %tempInstanceID%
		;Go through all running elements of the instance
		for index2, tempRunningElement in %tempInstanceID%_RunningElements
		{
			
			StringSplit, tempRunningElement,tempRunningElement,_ 
			; tempRunningElement1 = thread id
			; tempRunningElement2 = Element id
			; tempRunningElement3 = Element id in the instance
			
			;MsgBox %tempInstanceID%_%tempThreadID%_%tempRunningElement%_FinishedRunning = true ?
			if (%tempInstanceID%_%tempRunningElement%_FinishedRunning=true) ;If the element has finished
			{
				
				;mark the element that it has recently run by setting a negative number. It will be drawn pink. If several instances are running only decrement the number. Needed for correct visual appearance of the elements
				%tempRunningElement2%running--
				if (%tempRunningElement2%running=0)
					%tempRunningElement2%running=-10
				
				;Insert the element that has finished to the list
				ElementsThatHaveFinished.Insert(tempInstanceID "_"  tempRunningElement)
				
				
				runNeedToRedraw:=true
				
				;MsgBox, %tempRunningElement% finished running
				
				;Find elements that are connected to the finished element and prepare them to run
				
				tempConnectionsToRun:=object()
				for index1, element in allElements
				{
					
					if %element%Type=Connection
					{
						;MsgBox % "connection found " %element%from "  " tempRunningElement1 "  " %element%ConnectionType "  " %tempInstanceID%_%tempThreadID%_%tempRunningElement%_result
						tempTo:=%element%to
						tempFrom:=%element%from
						
						;~ MsgBox % %tempfrom%type "`n" %tempTo%type "`n" %element%ConnectionType "`n" %tempInstanceID%_%tempRunningElement%_result "`n" %element%frompart
						;If the connection starts on the currend finised element and the elements finished with the same result that is assigned to the connection
						if (%element%from=tempRunningElement2 && ( %element%ConnectionType=%tempInstanceID%_%tempRunningElement%_result || (%tempfrom%type="loop" && %element%ConnectionType = "normal" && ((%tempInstanceID%_%tempRunningElement%_result = "normalHead" && %element%frompart ="Head") || (%tempInstanceID%_%tempRunningElement%_result = "normalTail") && %element%frompart ="Tail")  )) && %tempTo%subtype!="")
						{
							tempConnectionsToRun.Insert(element)
							
							

							
							;MsgBox % "going to run hinzugefügt "  tempInstanceID "_"  %element%to "_" %tempInstanceID%_RunningCounter
							
						}
						
						
						
						
					}
					
				}
				
				if tempConnectionsToRun.maxindex()>1
				{
					tempRunCopyOfThreadVariables:=%tempInstanceID%_Thread_%tempRunningElement1%_Variables.Clone()
				}
				
				tempConnectionCountToRun:=0
				for, index, RunElement in tempConnectionsToRun
				{
					tempTo:=%RunElement%to
					tempFrom:=%RunElement%from
					
					if (tempConnectionCountToRun>0)
					{
						r_RunningThreadCounter++
						tempThreadIDToRun :=r_RunningThreadCounter
						%tempInstanceID%_Thread_%tempThreadIDToRun%_Variables:=tempRunCopyOfThreadVariables.Clone()
						;~ MsgBox tempInstanceID %tempInstanceID% `n r_RunningThreadCounter %r_RunningThreadCounter% `n tempRunningElement1 %tempRunningElement1%
						;~ MsgBox % StrObj(%tempInstanceID%_Thread_%tempRunningElement1%_Variables)
						;~ MsgBox % StrObj(%tempInstanceID%_Thread_%r_RunningThreadCounter%_Variables)
					}
					else
						tempThreadIDToRun:=tempRunningElement1
					
					%tempInstanceID%_RunningCounter++
					tempCountOfRunningElementsInInstance++
					
					if %tempFrom%type=Loop ;restore previous loop vars (if any) when leaving a loop
					{
						if (%RunElement%frompart="Tail" or %RunElement%ConnectionType = "exception") ;either normal leaving or exception
							PrepareLeavingALoop(tempInstanceID,tempThreadIDToRun,tempFrom)
						
					}
					
					tempRunSkipCurrentRun:=false
					;Insert the element that is on the end of the connection to the list
					if (%tempTo%type="Loop")
					{
						if %RunElement%toPart = Head ;Save previous loop vars (if any) when entering a loop and write the information which loop was enetered
						{
							;~ MsgBox % tempTo "`n" strobj(%tempInstanceID%_Thread_%tempThreadIDToRun%_Variables) 
							PrepareEnteringALoop(tempInstanceID,tempThreadIDToRun,tempTo)
							
						}
						else if (%RunElement%toPart = "Tail" or %RunElement%toPart = "break") ;When entering a tail of the loop, check whether is was last on the head of the same loop
						{
							temp:=%tempInstanceID%_Thread_%tempThreadIDToRun%_Variables[c_loopVarsName]
							;~ MsgBox % strobj(%tempInstanceID%_Thread_%tempThreadIDToRun%_Variables)
							if (tempTo != temp["CurrentLoop"])
							{
								logger("f0","Error! " tempInstanceID ": " lang("The end of a loop was entered, but this loop was not the current one.")  " " lang("Current thread was closed"))
								;~ MsgBox, 16, % lang("Error"),% lang("The end of a loop was entered, but this loop was not the current one.")  "`n" lang("Current thread will be closed") 
								tempRunSkipCurrentRun:=true
							}
						}
					}
					if (tempRunSkipCurrentRun != true)
					{
						%tempInstanceID%_%tempRunningElement%_FoundNextElement:=true
						;~ MsgBox %tempInstanceID%_%tempRunningElement%_FoundNextElement
						goingToRunIDs.insert(tempInstanceID "_" tempThreadIDToRun "_" tempTo "_" %tempInstanceID%_RunningCounter "_" %RunElement%toPart)
						tempConnectionCountToRun++
					}
				}
				
				
			}
			else
			{
				
				
				;MsgBox, %tempRunningElement% still running
				tempCountOfRunningElementsInInstance++
				
			}
			
			
			
			
		
		}
		
		if (tempCountOfRunningElementsInInstance=0) ;Prepare to remove the instance, because no elements are running and thus the instance has finished
		{
			;MsgBox %tempInstanceID% was added to the list of instances that have finished
			InstancesThatHaveFinished.Insert(tempInstanceID)
			
		}
		
	}
	
	
	;Remove the elements that have finished running from the instance
	for index, tempElement in ElementsThatHaveFinished
	{
		StringSplit,tempElement,tempElement,_
		; tempElement1 = word "instance"
		; tempElement2 = instance id
		; tempElement3 = thread id
		; tempElement4 = element id
		; tempElement5 = element id in the instance
		
		logger("f2","Instance " tempElement2 ": " %tempElement4%type " '" %tempElement4%name "' has finished with result " %tempElement%_result)
		
		if (%tempElement%_FoundNextElement!=true)
		{
			if (%tempElement%_result="exception" and %tempElement%_reason!="")
			{
				;~ %tempElement%_FoundNextElement
				MsgBox, 16, % lang("Error"),% lang("%1% '%2%' ended with an error",lang(%tempElement4%type),%tempElement4%name) ":`n" %tempElement%_reason "`n`n" lang("Current thread was closed") 
				;~ MsgBox % %tempElement%_reason
			}
		}
		
		;MsgBox, element %tempElement% has finished and will be removed
		for index2, tempRunningElement in Instance_%tempElement2%_RunningElements
		{
			if (tempRunningElement=tempElement3 "_" tempElement4 "_" tempElement5)
			{
				
				
				runNeedToRedraw:=true
				Instance_%tempElement2%_RunningElements.Remove(index2)
				break
			}
		}
		
	}
	
	;Remove the instance that have finished from the list of instances
	for index, tempFinishedInstanceID in InstancesThatHaveFinished
	{
		logger("fa","Instance " tempFinishedInstanceID ": has finished")
		;MsgBox, instance %tempFinishedInstanceID% has finished and will be removed
		for index1, tempInstanceID in InstanceIDList
		{
			if (tempFinishedInstanceID=tempInstanceID)
			{
				
				;Do some actions
				;MsgBox % tempFinishedInstanceID "-" %tempFinishedInstanceID%_InstanceOfCallingFlow
				;MsgBox % %tempFinishedInstanceID%_CallingFlow
				;MsgBox % %tempFinishedInstanceID%_ElementIDInInstanceOfCallingFlow
				;If the now finished instance was called by another flows that waits for a reply
				if (%tempFinishedInstanceID%_InstanceIDOfCallingFlow!="" and %tempFinishedInstanceID%_CallingFlow!="" and %tempFinishedInstanceID%_ElementIDInInstanceOfCallingFlow!="")
				{
					
					;If the calling flow wants to receive the variables
					
					if %tempFinishedInstanceID%_WhetherToReturVariables
					{
						
						tempLocalVarsToSend:=%tempFinishedInstanceID%_LocalVariables.clone()
						;~ MsgBox % "dfs " %tempFinishedInstanceID%_WhetherToReturVariables "`n" strobj(tempLocalVarsToSend)
					}
					else
						tempLocalVarsToSend=
					
					;Tell the other flow that this instance has finished and eventually return the variables
					;~ MsgBox % "callinglfow" %tempFinishedInstanceID%_CallingFlow
					com_SendCommand({function: "CalledFlowHasFinished", flowName: flowName, localVariables: tempLocalVarsToSend,ThreadVariables: "",CallerElementID: %tempFinishedInstanceID%_ElementIDInCallingFlow,CallerInstanceID: %tempFinishedInstanceID%_InstanceIDOfCallingFlow, CallerElementIDInInstance: %tempFinishedInstanceID%_ElementIDInInstanceOfCallingFlow, CallerThreadID: %tempFinishedInstanceID%_ThreadIDOfCallingFlow},"editor",%tempFinishedInstanceID%_CallingFlow) ;Send the command to the other flow.
					
				}
				
				;Clean to free memory
				InstanceIDList.Remove(index1)
				Instance_%tempFinishedInstanceID%_LocalVariables=""
				break
			}
		}
			
	}
	

	;Loop through the elements that are going to run
	for index3, runElement in goingToRunIDs
	{
		
		
		StringSplit, runElement,runElement,_ ;a word like Instance_1_action2_3
		; runElement1 = word "instance"
		; runElement2 = instance id
		; runElement3 = thread
		; runElement4 = element id
		; runElement5 = element id in the instance
		;Insert the element to the list of running elements of the instance
		Instance_%runElement2%_RunningElements.insert(runElement3 "_" runElement4 "_" runElement5)
		
		logger("a2","Instance " runElement2 ": " lang(%runElement4%type) " '" %runElement4%name "' is going to run")
		
		
		;set some variables for correct visual appearance of the element
		if (%runElement4%running<=0)
			%runElement4%running=1
		else
			%runElement4%running++
			
		
		runNeedToRedraw:=true
		
	}
	
	if (runNeedToRedraw=true) ;Draw before the elements are actually executed
	{
		
		UI_draw()
		thread, Priority, -100
	}
	

	
	for index3, runElement in goingToRunIDs
	{
		if stopRun=true
			break
		
		
		
		StringSplit, runElement,runElement,_ ;a word like Instance_1_action2_3
		; runElement1 = word "instance"
		; runElement2 = instance id
		; runElement3 = Thread id
		; runElement4 = element id
		; runElement5 = element id in the instance
		; runElement6 = part of the element (only with a loop element)
		
		;Start the elements that are marked as going to run
		tempElementType:=%runElement4%Type
		tempElementSubType:=%runElement4%subType
		
		
		logger("f1","Instance " runElement2 ": Starting " lang(%runElement4%type) " '" %runElement4%name "' now")
		Instance_%runElement2%_%runElement3%_%runElement4%_%runElement5%_finishedRunning:=false
		
		;~ MsgBox executing: %runElement%
		if %runElement4%type=loop
			run%tempElementType%%tempElementSubType%(runElement2,runElement3,runElement4,runElement5,runElement6) ;Execute the element
		else
			run%tempElementType%%tempElementSubType%(runElement2,runElement3,runElement4,runElement5) ;Execute the element
		
		
	}
	
	;Detect whether the instance list is empty
	tempTheInstanceListIsNotEmpty=0
	for index1, tempInstanceID in InstanceIDList
	{
		tempTheInstanceListIsNotEmpty++
		break
	}
	;Detect whether there is no instance running anymore
	;ToolTip(tempTheInstanceListIsNotEmpty)
	if (tempTheInstanceListIsNotEmpty=0)
	{
		;ToolTip("Fertig")
		logger("a2","No instances running. Flow is going to stop.")
		stopRun:=true
	}
	
	
	
	;Stop running if needed, else execute this soon again
	if (stopRun=true)
		goto,stopRunning 
	else
		SetTimer,nextRun,-%executionSpeed%,-100
	return
	
	;Stop running
	stopRunning:
	Critical on
	logger("f1a1","Stopping flow.")
	SetTimer,r_unblockRuns,-1000
	SetTimer,nextRun,off
	;Delete all running tags after finishing run
	for index1, element in allElements
	{
		tempstopfunctionname:="stop" %element%type %element%subtype
		%tempstopfunctionname%(element)
		%element%running:=0
	}
	
	
	
	InstanceIDList:=Object() ;Remove all Instances
	
	
	ui_draw()

	nowRunning:=false
	r_TellThatFlowIsStopped()
	
	critical off
	return
}
goto,jumpOverExcapeRunLabel

r_unblockRuns:
r_RunsBlocked:=false
return

r_startRun:
r_startRun()
return

r_escapeRunNoBlock:
r_escapeRun:
r_TellThatFlowIsStopping()
logger("f1a1","User is stopping flow. Blocking executions for 1 second.")

stopRun:=true
if (a_thislabel!="r_escapeRunNoBlock")
	r_RunsBlocked:=true
;Hotkey,esc,off
return

;This timer is used when the a new instance starts and the execution policy says that the old instance has to be stopped
r_WaitUntilStoppedAndThenStart:
if (nowrunning!=true)
{
	logger("f1a1","Starting the waiting instance.")
	r_startRun()
	settimer,r_WaitUntilStoppedAndThenStart,off
}
return

;Those three functions tell the manager about the current status of the flow, set the right text in the GUI elements, and change the icon
r_TellThatFlowIsStopped()
{
	global
	try Menu MyMenu,Rename,% lang("Stopping"),% lang("Run") ;Show run when stopping
	try Menu MyMenu,Rename,% lang("Stop"),% lang("Run")
	try menu, tray, rename, % lang("Stopping"),% lang("Run")
	try menu, tray, rename, % lang("Stop"),% lang("Run")
	com_SendCommand({function: "ReportStatus",status: "stopped"},"manager") ;Send the command to the Manager.
	
	if (triggersEnabled=true)
		menu tray,icon,Icons\enabled.ico
	else 
		menu tray,icon,Icons\disabled.ico
}

r_TellThatFlowIsStarted()
{
	global
	try Menu MyMenu,Rename,% lang("Run"),% lang("Stop")  ;Show Stop when running
	try Menu MyMenu,Rename,% lang("Stopping"),% lang("Stop")
	try menu, tray, rename, % lang("Run"),% lang("Stop")
	try menu, tray, rename, % lang("Stopping"),% lang("Stop")
	com_SendCommand({function: "ReportStatus",status: "running"},"manager") ;Send the command to the Manager.
	menu tray,icon,Icons\running.ico
}

r_TellThatFlowIsStopping()
{
	global
	try Menu MyMenu,Rename,% lang("Run"),% lang("Stopping") ;Show Stopping
	try Menu MyMenu,Rename,% lang("Stop"),% lang("Stopping")
	try menu, tray, rename, % lang("Run"),% lang("Stopping")
	try menu, tray, rename, % lang("Stop"),% lang("Stopping")
	com_SendCommand({function: "ReportStatus",status: "stopping"},"manager") ;Send the command to the Manager.
	
}
jumpOverExcapeRunLabel:
sleep,1