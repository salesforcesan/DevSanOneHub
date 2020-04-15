({
	doInit : function(cmp, e, h) {
        var questions = cmp.get("v.questions");
        var activeQuestions = questions.filter(item => item.Active != false);
        var target = activeQuestions.find(item => item.QuestionType == 'Group');
        activeQuestions.map(function(item){
            if(!$A.util.isEmpty(target)){
                if(item.ParentID == target.ID ) {
                    item.ParentID = target.ParentID;
                    if(!$A.util.isEmpty(target.ServiceQuestionRuleList)){
                        item.ServiceQuestionRuleList = target.ServiceQuestionRuleList;
                    }
                } 
            }
            if($A.util.isEmpty(item.ServiceQuestionRuleList)){
              item.WillAnswer = true;   
            } else {
              item.WillAnswer = false;
            }
            item.DidAnswer = false;
            return item;
        });
        
        var currentQuestion = activeQuestions.find(item => item.QuestionNumber == 1);
        currentQuestion.DidAnswer = true;       
        cmp.set("v.currentQuestion", currentQuestion);
        cmp.set('v.questions', activeQuestions);
        if(currentQuestion.QuestionType == 'Group') {
            cmp.set('v.startNumber', 2);
            this.setNextQuestion(cmp, e, activeQuestions, currentQuestion.QuestionNumber);
        }
	},
    
    handleEventResponseSelected: function(cmp, e, h) {
        var responseId = e.getParam("responseId");
        h.handleEventResponseSelected(cmp, e, h);
    }, 
    submitSurveyHandler: function(cmp, e, h) {
        //close model event to fire 
    },
})