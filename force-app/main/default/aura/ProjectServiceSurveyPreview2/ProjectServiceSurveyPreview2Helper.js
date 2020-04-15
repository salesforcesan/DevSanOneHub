({
	 handleEventResponseSelected: function(cmp, e, h) {
        var responseId = e.getParam("responseId");
		var currentQuestion = cmp.get('v.currentQuestion');
        var qId = currentQuestion.ID;
        var qNum = currentQuestion.QuestionNumber;
        var questions = cmp.get('v.questions');
        switch (responseId) {
            case 'next':
                this.setDidAnswer(cmp, e, questions, qId);
                this.setNextQuestion(cmp, e, questions, qNum);
                this.checkTarget(cmp, e, questions);
                break;
                
            case 'previous':
                var answeredQuestions = questions.filter(item => item.QuestionNumber < qNum  && item.DidAnswer == true);
                var previousQuestion = answeredQuestions[answeredQuestions.length - 1];     
                //if go back clears the previous will answer rules that were met
                questions.forEach(function(item) { 
                   if(item.ParentID == previousQuestion.ID) { 
                      item.WillAnswer = false;
                      item.DidAnswer = false;
                   };
                   return item;
                });
                cmp.set('v.currentQuestion', previousQuestion);          
                break;
                
            default:
                questions.forEach(function(item) {
                    if(!$A.util.isEmpty(item.ServiceQuestionRuleList) && item.ParentID == qId) {
                        item.ServiceQuestionRuleList.forEach(function(rule) { 
                         if(rule.SqValue == responseId){ item.WillAnswer = true; }
                       }) 
                    }
                    return item;
                }); 
                this.setDidAnswer(cmp, e, questions, qId);
                this.setNextQuestion(cmp, e, questions, qNum);
                this.checkTarget(cmp, e, questions);
                break;
    	}
    },
    
    setNextQuestion: function(cmp, e, questions, qNum) {
        var nextQuestion = questions.find(item => item.QuestionNumber > qNum  && item.WillAnswer == true);
        if(!nextQuestion) {
          cmp.set('v.isLastQuestion', true);
        }
        cmp.set('v.currentQuestion', nextQuestion);                 
    },
    
    setDidAnswer: function(cmp, e, questions, qId) {
   		var qIndex = questions.findIndex(item => item.ProjectServiceQuestionId == qId);
        questions[qIndex].DidAnswer = true;
    },
    
    checkTarget: function(cmp, e, questions) {
       var newCurrent = cmp.get('v.currentQuestion');
        if(!$A.util.isEmpty(newCurrent)) {
           if(newCurrent.QuestionType == 'Group') {
          	  this.setNextQuestion(cmp, e, questions, newCurrent.QuestionNumber);
       		}
        }
    },
 
})