({
    markChildQuestions : function(component) {
        
        var questions = component.get("v.questions");
        
        for (var i = 0; i < questions.length; i++) { 
        	for (var j = 0; j < questions[i].DefinedResponses.length; j++) { 
                if (questions[i].DefinedResponses[j].JumpToQuestionNumber) {
                	for (var k = 0; k < questions.length; k++) { 
                        if (questions[k].QuestionNumber === questions[i].DefinedResponses[j].JumpToQuestionNumber) {
                            questions[k].ChildQuestion = true;
                        }
                    }	    
                }
        	}

            
        }

        // If this question is a child question & JumpToAction == "CONTINUE"
        // then the next question is a child question
        // then check the chain of questions after...
        // While JumpToAction == "CONTINUE" it is also a child question
        debugger;
        for (var i = 0; i < questions.length; i++) { 
            if (questions[i].ChildQuestion === true && questions[i].JumpToAction === "CONTINUE") {
                var j = i;
                while (questions[j] && questions[j].JumpToAction === "CONTINUE") {
                    if (questions[j+1]) {
                        questions[j+1].ChildQuestion = true;
                    }
                    j++;
                }
            }
        }

        
        console.log(questions, "marked questions");
        
        return questions;
    },
    getFirstQuestion : function(component) {
        
        var questions = component.get("v.questions");
        
        for (var i = 0; i < questions.length; i++) { 
            if (questions[i].QuestionNumber === 1) {
                return questions[i];
            }
        }
	},
    getLastQuestion : function(component, answer) {
        
        var questions = component.get("v.questions");
        
        for (var i = 0; i < questions.length; i++) { 
            if (questions[i].QuestionId === answer.QuestionId) {
                return questions[i];
            }
        }
    },
    getNextQuestion : function(component) {
        
        var questions = component.get("v.questions"),
        	selectedResponse = component.get("v.selectedResponse"),
            nextQuestionNumber,
            nextQuestion;
debugger;
        if (selectedResponse.JumpToAction === "BRANCH" && selectedResponse.JumpToQuestionNumber) {
            
            // Check DefinedResponses selection
            nextQuestionNumber = selectedResponse.JumpToQuestionNumber;
            
            for (var i = 0; i < questions.length; i++) { 
                if (questions[i].QuestionNumber === selectedResponse.JumpToQuestionNumber) {
                    nextQuestion = questions[i];
                }
            }
            
        } else if (selectedResponse.JumpToAction !== "RETURN" && (selectedResponse.JumpToAction === "CONTINUE" || selectedResponse.JumpToQuestion === "CONTINUE" || !selectedResponse.JumpToQuestion)) {
            
            // Next question in sequence
            nextQuestionNumber = selectedResponse.QuestionNumber + 1;
            
            for (var i = 0; i < questions.length; i++) {
            	for (var j = 0; j < questions.length; j++) { 

                    // && !questions[j].ChildQuestion (removed 10/12)
                    if (questions[j].QuestionNumber === nextQuestionNumber && questions[j].Active) {
                        nextQuestion = questions[j];
                        break;
                    }
                }
                if (!nextQuestion) {
                	nextQuestionNumber++;    
                } else {
                	break;    
                }
            }
                
        } else {
            // RETURN
            // Next non-child question in sequence
            nextQuestionNumber = selectedResponse.QuestionNumber + 1;
            
            for (var i = 0; i < questions.length; i++) {
                for (var j = 0; j < questions.length; j++) { 
                    if (!questions[j].ChildQuestion && questions[j].QuestionNumber === nextQuestionNumber && questions[j].Active) {
                        nextQuestion = questions[j];
                        break;
                    }
                }
                if (!nextQuestion) {
                	nextQuestionNumber++;    
                } else {
                	break;    
                }
            }
            
        }
        
        if (!nextQuestion) {
            nextQuestion = {};
            nextQuestion.QuestionType = "end";
        }
        
        return nextQuestion
        
    },
    getQuestionType : function(question) {
        
        if (!question.QuestionType) {
            question.QuestionType = "Text";
        }

    	return question.QuestionType;
	},
    pushSelectedToQuestionsAnswered : function(component, event, helper) {
        
        var currentQuestion = currentQuestion = helper.getNextQuestion(component),
            selectedResponse = component.get("v.selectedResponse"),
        	answers = component.get("v.answers");
        if (!answers) {
            answers = [];
        }
        
    	answers.push(selectedResponse);
    	component.set("v.answers", answers);
        component.set("v.selectedResponse", "");
        console.log(component.get("v.answers", "answers"));
    },
    openDynamicQuestion : function(component, event, helper) {
        $A.createComponent(
            "c:PreviewSurveyTabletViewQuestion",
            {
                "currentQuestionQuestionType": component.get("v.currentQuestionQuestionType"),
                "currentQuestion": component.get("v.currentQuestion")
            },
            function(questionComponent){                
                if (component.isValid()) {
                    var body = component.get("v.body");
                    body.push(questionComponent);
                    component.set("v.body", body); 
                }
            }
        );
    },
    closeDynamicQuestion : function(component, event, helper) { 
        component.set("v.body", []); 
    },
    postAnswers : function(answers) {
        console.log("ANSWERS", answers);
        var formattedAnswers = [],
            thisAnswer;
        
        for (var i = 0; i < answers.length; i++) { 
            
            thisAnswer = {};
            thisAnswer.QuestionId = answers[i].QuestionId;
            thisAnswer.Answers = answers[i].Response; 		// Answers can be strings or arrays. 
            											// Due to new questions formats, changes may need to be made at the endpoint
            thisAnswer.TargetId = answers[i].TargetId; 	// TargetId is not populated through to survey test
            formattedAnswers.push(thisAnswer);
        }
        console.log("FORMATTED ANSWERS", formattedAnswers);
    }
})