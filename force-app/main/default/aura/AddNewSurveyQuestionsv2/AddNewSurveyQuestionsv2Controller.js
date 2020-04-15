({
	doInit: function(cmp, event, helper) {

        cmp.set("v.questiontext", ''); 
        cmp.set("v.questiontype", ''); 
        cmp.set("v.targetquestion", ''); 
	},
    addNewQuestion: function(cmp, event, helper) {
    	var questionid = event.target.id;
        var recordId = cmp.get("v.recordId");
        var addNewQuestionEvent = cmp.getEvent("addNewQuestion");        
       	addNewQuestionEvent.setParams({ "questionId" : questionid, "recordId" : recordId });
       	addNewQuestionEvent.fire();
        
    },
    handleSurveyQuestionFilterChanged: function(cmp, event, helper) {
        var questiontext = event.getParam("questionText");
        var questiontype = event.getParam("questionType");
        var targetquestion = event.getParam("targetQuestion");

        cmp.set("v.questiontext", questiontext); 
        cmp.set("v.questiontype", questiontype); 
        cmp.set("v.targetquestion", targetquestion); 
        
        helper.getQuestions(cmp);
        
    },
    toggleAcc : function(component, event, helper) {
        var acc = document.querySelectorAll('.accordion'), i;
        for (var i = 0; i < acc.length; i ++) {
        	acc[i].classlist.toggle("active");
          	acc[i].nextElementSibling.classList.toggle("show"); 
        }
    },
    
    expandAll : function(component, event, helper) {
        var acc = document.querySelectorAll('.responses'), i;
        for (var i = 0; i < acc.length; i ++) {
        	acc[i].nextElementSibling.classList.toggle("show"); 
        }
    }
})