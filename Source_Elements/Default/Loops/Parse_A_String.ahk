﻿;Always add this element class name to the global list
x_RegisterElementClass("Loop_Parse_A_String")

;Element type of the element
Element_getElementType_Loop_Parse_A_String()
{
	return "Loop"
}

;Name of the element
Element_getName_Loop_Parse_A_String()
{
	return lang("Parse_A_String")
}

;Category of the element
Element_getCategory_Loop_Parse_A_String()
{
	return lang("Variable")
}

;This function returns the package of the element.
;This is a reserved function for future releases,
;where it will be possible to install additional add-ons which provide more elements.
Element_getPackage_Loop_Parse_A_String()
{
	return "default"
}

;Minimum user experience to use this element.
;Elements which are complicated or rarely used by beginners should not be visible to them.
;This will help them to get started with AHF
Element_getElementLevel_Loop_Parse_A_String()
{
	;"Beginner" or "Advanced" or "Programmer"
	return "Beginner"
}

;Icon path which will be shown in the background of the element
Element_getIconPath_Loop_Parse_A_String()
{
}

;How stable is this element? Experimental elements will be marked and can be hidden by user.
Element_getStabilityLevel_Loop_Parse_A_String()
{
	;"Stable" or "Experimental"
	return "Stable"
}

;Returns an array of objects which describe all controls which will be shown in the element settings GUI
Element_getParametrizationDetails_Loop_Parse_A_String(Environment)
{
	parametersToEdit:=Object()
	
	
	parametersToEdit.push({type: "Label", label:  lang("Input string")})
	parametersToEdit.push({type: "Edit", id: "VarValue", default: "Hello real world, Hello virtual world", content: ["String", "Expression"], contentID: "Expression", ContentDefault: "String", WarnIfEmpty: true})
	parametersToEdit.push({type: "Label", label: lang("Delimiter characters")})
	parametersToEdit.push({type: "Edit", id: "Delimiters", default: ",", content: "String", WarnIfEmpty: true})
	parametersToEdit.push({type: "Label", label: lang("Omit characters")})
	parametersToEdit.push({type: "Edit", id: "OmitChars", default: "%a_space%%a_tab%", content: "String"})
	
	return parametersToEdit
}

;Returns the detailed name of the element. The name can vary depending on the parameters.
Element_GenerateName_Loop_Parse_A_String(Environment, ElementParameters)
{
	return lang("Parse_A_String") 
}

;Called every time the user changes any parameter.
;This function allows to check the integrity of the parameters. For example you can:
;- Disable options which are not available because of other options
;- Correct misconfiguration
Element_CheckSettings_Loop_Parse_A_String(Environment, ElementParameters)
{	
	
}


;Called when the element should execute.
;This is the most important function where you can code what the element acutally should do.
Element_run_Loop_Parse_A_String(Environment, ElementParameters)
{
	
	entryPoint := x_getEntryPoint(environment)
	
	if (entryPoint = "Head") ;Initialize loop
	{
		EvaluatedParameters:=x_AutoEvaluateParameters(Environment, ElementParameters)
		if (EvaluatedParameters._error)
		{
			x_finish(Environment, "exception", EvaluatedParameters._errorMessage) 
			return
		}
		
		CurrentList:=Object()
		loop,parse,% EvaluatedParameters.VarValue,% EvaluatedParameters.delimiters,% EvaluatedParameters.omitChars
		{
			Result.push(A_LoopField)
		}
		
		if (Result.haskey(1))
		{
			x_SetVariable(Environment, "A_LoopCurrentList", CurrentList, "loop", true)
			x_SetVariable(Environment, "A_Index", 1, "loop")
			
			x_SetVariable(Environment, "A_LoopField", CurrentList[1], "loop")
			
			x_finish(Environment, "head")
		}
		else
		{
			x_finish(Environment, "tail") ;Leave the loop
		}
	}
	else if (entryPoint = "Tail") ;Continue loop
	{
		CurrentList := x_GetVariable(Environment, "A_LoopCurrentList", true)
		index := x_GetVariable(Environment, "A_Index")
		index++
		
		if (CurrentList.haskey(index))
		{
			x_SetVariable(Environment, "A_Index", index, "loop")
			x_SetVariable(Environment, "A_LoopField", CurrentList[index], "loop")
			x_finish(Environment, "head") ;Continue with next iteration
		}
		else
		{
			x_finish(Environment, "tail") ;Leave the loop
		}
		
	}
	else if (entryPoint = "Break") ;Break loop
	{
		x_finish(Environment, "tail") ;Leave the loop
		
	}
	else
	{
		;This should never happen, but I suggest to keep this code for catching bugs in AHF.
		x_finish(Environment, "exception", lang("No information whether the connection leads into head or tail"))
	}
	
}


;Called when the execution of the element should be stopped.
;If the task in Element_run_...() takes more than several seconds, then it is up to you to make it stoppable.
Element_stop_Loop_Parse_A_String(Environment, ElementParameters)
{
}





