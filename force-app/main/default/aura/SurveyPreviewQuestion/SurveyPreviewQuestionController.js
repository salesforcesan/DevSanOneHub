({
	doInit: function(component, event, helper) {
        
        var questionNumber = parseInt(component.get("v.questionNumber")),
            questions = component.get("v.questions"),
            question;
        
        // If there is a questionNumber, find the question, and set question
        if (questionNumber) {
			question = questions.filter(function( obj ) {
              return obj.QuestionNumber == questionNumber;
            });
            component.set("v.question", question[0]);
        }
		
	}
})