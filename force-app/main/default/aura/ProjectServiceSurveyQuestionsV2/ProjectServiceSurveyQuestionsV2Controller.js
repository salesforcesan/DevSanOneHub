({	
    doInit: function(component, event, helper) {
        
        //component.set("v.securityelements", "ProjectServiceQuestions__c.Edit,ProjectServiceQuestions__c.Active");
        
        helper.getProjectService(component);
        helper.getServiceQuestions(component);
        helper.getUISecurityInformation(component);
        helper.getMultiListCheck(component);
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
                console.log('psQID event: ',question.ProjectServiceQuestionId);
                helper.removeSurveyQuestionConfirm(cmp, event, question.ProjectServiceQuestionId);
                break;
            case 'uploadTargets':
                helper.showUploadTargetModal(cmp, event, question );
                break;    
                
        }
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
    handleEditServiceQuestion: function(cmp, event, helper) {
        var question = event.getParam("question");
        cmp.set("v.question", question);
        
        helper.async(cmp, function(cmp) {
            cmp.find('modalDialog').close();
        });
        
        
        helper.editServiceQuestion(cmp);
        
    },   
    handleServiceQuestionRule:function(cmp, event, helper)
    {
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
    showEditQuestionModal: function(component, event, helper) {
        
        var questions = component.get("v.questions");
        var recordid = event.target.id;
        
        helper.showEditQuestionModal(component, questions, recordid);        
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
    showPreviewSurveyModal: function(component, event, helper) {
        
        var servicename = component.get("v.servicename"),
            //questions = component.get("v.questions"),
            questions = component.get("v.notflattenquestions"),
            userevent = $A.get("e.c:EventDisplayModal");        
        
        userevent.setParams({
            "modalProperties": {
                "title": "Preview Survey",
                "size": "",
                "showHeader": "false"
            },
            "modalComponentName": "c:ProjectServiceSurveyPreview2",
            "modalComponentProperties": {
                "questions": questions,
                "servicename": servicename
            }
        });
        userevent.fire();
        
    },   
    
    exportSurvey: function(component, event, helper) {
        
        // Save as ProjectId_ProjectServiceTitle
        var projectService = component.get("v.projectservice"),
            questions = component.get("v.notflattenquestions"),
            filenamePrefix = "Project_" + projectService.ProjectNumber + "_" + projectService.ServiceTitle,
            fileContent = helper.buildNonFlatSurvey(questions, component, helper);
        helper.exportFile(filenamePrefix, fileContent);
    },
    
    closeResponses: function(component, event, helper) {
        component.set('v.showResponses', false);
        component.set('v.responses', []);
        component.set('v.questionTitle', []);
    },
    
    onAddTargetEvent: function(component, event, helper) {
        helper.async(component, function(component) {
            component.find('modalDialog').close();
        });
        
		helper.onAddTarget(component,event);
    }
})