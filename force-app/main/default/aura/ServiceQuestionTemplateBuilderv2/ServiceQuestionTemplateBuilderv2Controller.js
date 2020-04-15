({	
  doInit: function(component, event, helper) {
      if (component.get("v.recordId") == null) {
          component.set("v.recordId","a16110000013SdsAAE");
      }  
      
      helper.getServiceQuestions(component);
      component.set('v.responses', []);
      
      helper.getMultiListCheck(component);
  },

  handleOpenModalsFromCard: function(cmp, event, helper) {
    var question = event.getParam("question");
    var context = event.getParam("context");
    var squestionId = question.ProjectServiceQuestionId;
      cmp.set('v.pserviceQuestionId',squestionId);
    var parentsquestionId = question.ParentID;
      switch(context){
          case 'rules':
              helper.showServiceQuestionRuleModal(cmp, event, question );
              break;
          case 'question':
              helper.showEditQuestionModal(cmp, event, question );
              break;
	      case 'delete':
              helper.removeSurveyQuestionConfirm(cmp, event, question.ProjectServiceQuestionId)
              break;
      }
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
        
  onRefreshQuestionsEvent: function(cmp, event, helper) {
      helper.getServiceQuestions(cmp, event, helper);    
  },

  onDragChanged: function(cmp, event, helper) {
      helper.dragChangedEvent(cmp, event, helper);    
  },
  
  handleDefinedResponses: function(cmp, event, helper) {
      helper.handleDefinedResponses(cmp, event, helper);    
  },
  showAddQuestionModal: function(component, event, helper) {
      
      helper.showAddQuestionModal(component);
      return;
        
    },
    onMessageBoxEvent: function(component, event, helper) {
        helper.handleMessageBoxEvent(component, event);
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
    
  handleServiceQuestionRule:function(cmp, event, helper) {
      var sqID = event.getParam("ServiceQuestionId");
      var psquestionId = event.getParam("parentServiceQuestionId");      
      var operatorval = event.getParam("operator");      
      var definedReponses = event.getParam("definedReponses");      
      
      cmp.set("v.serviceQuestionId", sqID);
      cmp.set("v.pserviceQuestionId", psquestionId);
      cmp.set("v.operator", operatorval);
      cmp.set("v.definedResponses", definedReponses);
            
      helper.async(cmp, function(cmp) {
          cmp.find('modalDialog').close();
      });
      
      helper.addServiceQuestionrule(cmp);      
  },
  
  
  handleQuestionChanges: function(cmp, event, helper) {
      
      helper.saveQuestionChanges(cmp);
      
  },
  handleClose:function(component, event, helper){      
      helper.getServiceQuestions(component);
  },
  toggleAccAll: function(component, event, helper) {
      var acc = document.querySelectorAll('.accordionv2'),i;
      for (var i = 0; i < acc.length; i++) {
          acc[i].nextElementSibling.classList.toggle("show-responses");
          
      }
  },
  closeResponses: function(component, event, helper) {
    component.set('v.showResponses', false);
    component.set('v.responses', []);
    component.set('v.questionTitle', []);
  }
 })