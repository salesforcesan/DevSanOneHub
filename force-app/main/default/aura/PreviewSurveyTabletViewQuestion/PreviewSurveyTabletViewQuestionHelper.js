({
	setSelectedResponse : function(component, event, helper, setBlank) {
    	var currentQuestion = component.get("v.currentQuestion"),
            response = helper.assignCommonResponse(currentQuestion),
            selectedResponse, responseExists, responseText, responseId;
        
        if (setBlank) {
            
            component.set("v.selectedResponse", response);

        } else if (currentQuestion.QuestionType == "Single-Select List") {
            helper.clearOtherSelections(event.target.id);
            for (var i = 0; i < currentQuestion.DefinedResponses.length; i++) { 
                if (currentQuestion.DefinedResponses[i].DefinedResponseId === event.target.id) {
                    response.Response = currentQuestion.DefinedResponses[i].DefinedResponseText;
                    response.ResponseId = currentQuestion.DefinedResponses[i].DefinedResponseId;
                    response.JumpToQuestionNumber = currentQuestion.DefinedResponses[i].JumpToQuestionNumber;
                    response.JumpToQuestion = currentQuestion.DefinedResponses[i].JumpToQuestion;
                }
            }
        } else if (currentQuestion.QuestionType == "Multi-Select List") {
            // get existing response
            selectedResponse = component.get("v.selectedResponse");
            response.Response = selectedResponse.Response;
        	if (!response.Response) { response.Response = []; }
            responseExists = false;
            for (var i = 0; i < response.Response.length; i++) { 
                if (response.Response[i].ResponseId === event.target.id) {
                    response.Response.splice(i, 1);
                    responseExists = true;
                }
            }
            if (!responseExists) {
                for (var i = 0; i < currentQuestion.DefinedResponses.length; i++) { 
                	if (currentQuestion.DefinedResponses[i].DefinedResponseId === event.target.id) {
                        responseText = currentQuestion.DefinedResponses[i].DefinedResponseText;
                        responseId = currentQuestion.DefinedResponses[i].DefinedResponseId;
                    	response.Response.push({
                            "Response" : responseText,
                            "ResponseId" : responseId
                        });
                    }
                }
            }
            if (response.Response.length === 0) {
                response.Response = null;
            }
            //console.log("Multi-Select List response", response.Response);
        } else {
            if (event.target.value) {
                response.Response = event.target.value ? event.target.value : '';
            } else {
                // Hack for attachment / photo buttons
                response.Response = event.target.parentElement.value ? event.target.parentElement.value : '';
            }
        }
        
        if (currentQuestion.QuestionType == "Number") {
            //console.log(response.Response < currentQuestion.MinValue, "response.Response");
         	if (isNaN(response.Response) || parseInt(response.Response) < parseInt(currentQuestion.MinValue)  || parseInt(response.Response) > parseInt(currentQuestion.MaxValue)) {
            	component.set("v.error", "out_of_range");
                
            } else {
                component.set("v.selectedResponse", response);
        		//console.log(response, "THIS RESPONSE");
                component.set("v.error", "");
            }
        } else {
            component.set("v.selectedResponse", response);
        }
        	
        //console.log(response, "THIS RESPONSE");
        helper.fireEventResponseSelected(component);
        
    },
    clearOtherSelections : function(id) {
        
        var allSelections = document.querySelectorAll("input[type=radio]");
        for (var i = 0; i < allSelections.length; i++) {
            if (allSelections[i].id != id) {
            	allSelections[i].checked = false;    
            }
        }
    },
    assignCommonResponse : function(question) {
        console.log("QUESTION", question);
        var response = {};
        response.QuestionId = question.QuestionId;
        response.QuestionNumber = question.QuestionNumber;
        response.QuestionType = question.QuestionType;
        response.JumpToAction = question.JumpToAction;
            
        return response;
    },
    fireEventResponseSelected : function(component) {
        
        var appEvent = $A.get("e.c:EventResponseSelected"),
            selectedResponse = component.get("v.selectedResponse");
        appEvent.setParams({ "selectedResponse" : selectedResponse });
        appEvent.fire();
    }
})