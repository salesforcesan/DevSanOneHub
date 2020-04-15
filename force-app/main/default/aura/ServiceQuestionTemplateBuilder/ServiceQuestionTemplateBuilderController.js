({
  doInit: function(component, event, helper) {
	
    if (component.get("v.recordId") == null)  
    {
        component.set("v.recordId","a16110000013SdsAAE");
    }

    helper.getServiceQuestions(component);
    helper.getService(component);

    console.log('--- tsq init---');
    console.log(component.get("v.recordId"));  

  },
  showAddQuestionModal: function(component, event, helper) {

    helper.showAddQuestionModal(component);
    return;
      
      
    /*  
    var recordId = component.get("v.recordId");  
    var userevent = $A.get("e.c:EventDisplayModal");
    userevent.setParams({
      "modalProperties": {
        "title": "Add Service Question",
        "size": "large"
      },
      "modalComponentName": "c:AddSurveyQuestionModal",
      "modalComponentProperties": {
        "recordId": recordId
      }
    });
    userevent.fire();
    */
      
      
  },
  removeServiceQuestion: function(component, event, helper) {

    var servicequestionid = event.target.id;
    helper.removeServiceQuestion(component, servicequestionid);

  },
  handleAddNewQuestion: function(cmp, event, helper) {
    var questionId = event.getParam("questionId");
    var recordId = event.getParam("recordId");
      
    helper.async(cmp, function(cmp) {
        cmp.find('modalDialog').close();
    });
      

    cmp.set("v.questionId", questionId);
    cmp.set("v.recordId", recordId);

    helper.addServiceQuestion(cmp);

  },
  handleEditServiceQuestion: function(cmp, event, helper) {
    var question = event.getParam("question");
    cmp.set("v.question", question);
      
    console.log('Edit returned!!');  
      
    helper.async(cmp, function(cmp) {
        cmp.find('modalDialog').close();
    });
      

    helper.editServiceQuestion(cmp);

  },    
  showEditQuestionModal: function(component, event, helper) {

    var questions = component.get("v.questions");
    var recordid = event.target.id;
      
  	helper.showEditQuestionModal(component, questions, recordid);        
      
	/*

    var userevent = $A.get("e.c:EventDisplayModal");
    userevent.setParams({
      "modalProperties": {
        "title": "Edit Survey Question",
        "size": "small"
      },
      "modalComponentName": "c:EditSurveyQuestionModal",
      "modalComponentProperties": {
        "questions": questions,
        "recordid": recordid
      }
    });
    userevent.fire();
    */
      
  },
  handleQuestionChanges: function(cmp, event, helper) {
    
  	helper.saveQuestionChanges(cmp);

  },
  toggleAccAll: function(component, event, helper) {
    var acc = document.querySelectorAll('.accordion'),i;
    for (var i = 0; i < acc.length; i++) {
      acc[i].nextElementSibling.classList.toggle("show-responses");
      
    }
  }
})