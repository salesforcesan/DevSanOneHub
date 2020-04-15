({   
    doInit : function(component, event, helper) {
        debugger;		    
        component.set("v.questions", helper.markChildQuestions(component));
        component.set("v.currentQuestion", helper.getFirstQuestion(component));
        component.set("v.currentQuestionQuestionType", helper.getQuestionType(component.get("v.currentQuestion")));
        console.log('questions in test: ', component.get('v.questions'));
        
        helper.closeDynamicQuestion(component, event, helper);
        helper.openDynamicQuestion(component, event, helper);
        
    },
    returnToLastQuestion : function(component, event, helper) {
    	    	
    	var answers = component.get("v.answers"),
    		lastAnswer,
    		lastQuestion;
    
    	lastAnswer = answers.pop();
    	lastQuestion = helper.getLastQuestion(component, lastAnswer);
   
        if (answers.length === 0) {
    		answers = null;
    	}
    
    	component.set("v.answers", answers);
    	component.set("v.currentQuestion", lastQuestion);
    	component.set("v.currentQuestionQuestionType", helper.getQuestionType(lastQuestion));
        component.set("v.selectedResponse", null);
        
        helper.closeDynamicQuestion(component, event, helper);
        helper.openDynamicQuestion(component, event, helper);
	},
 	continueSurvey : function(component, event, helper) {
    	
    	var selectedResponse = component.get("v.selectedResponse"),
            currentQuestion = helper.getNextQuestion(component);
        
    	helper.pushSelectedToQuestionsAnswered(component, event, helper);
    	
    	component.set("v.currentQuestion", currentQuestion);
    	component.set("v.currentQuestionQuestionType", helper.getQuestionType(currentQuestion));
        
        helper.closeDynamicQuestion(component, event, helper);
        helper.openDynamicQuestion(component, event, helper);
	},
    endSurvey : function(component, event, helper) {
        
        component.set("v.currentQuestionQuestionType", "submitted");
        helper.postAnswers(component.get("v.answers"));
        component.set("v.answers", null);
    },
    handleEventResponseSelected : function(component, event, helper) {
    
        var selectedResponse = event.getParam("selectedResponse");
        component.set("v.selectedResponse", selectedResponse);
    } 
})