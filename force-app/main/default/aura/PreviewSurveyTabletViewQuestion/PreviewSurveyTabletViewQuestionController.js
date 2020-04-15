({
	doInit : function(component, event, helper) {

        var currentQuestion = component.get("v.currentQuestion");

        helper.pop
        if (currentQuestion.Optional) {
        	//helper.assignCommonResponse(currentQuestion);
            helper.setSelectedResponse(component, event, helper, true);
        }

        console.log(currentQuestion, "currentQuestion in Question Controller")

    },
	inputChange : function(component, event, helper) {
    	
        helper.setSelectedResponse(component, event, helper);
    } 
})