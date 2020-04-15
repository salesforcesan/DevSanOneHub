({
    doInit: function(component, event, helper) {
        
        component.set("v.securityelements", "ProjectServiceQuestions__c.Edit,ProjectServiceQuestions__c.Active,ProjectServiceQuestions__c.Remove,ProjectServiceQuestions__c.TestSurvey");
        helper.getProjectServiceQuestions(component, helper);
        helper.getProjectService(component);
        var projectServiceId = component.get("v.recordId");
        helper.getTargets(component, event, projectServiceId);
        
        console.log(component.get("v.questions"), "QUESTIONS");
   
        console.log('--- psq init---');
        console.log(component.get("v.recordId"));  
        
    },
    toggleAccAll: function(component, event, helper) {
        console.log('toggle button clicked');
        var acc = document.querySelectorAll('.oh-accordion'), i;
        for (var i = 0; i < acc.length; i++) {
            acc[i].nextElementSibling.classList.toggle("oh-panel-show");
        }
    },
    onMessageBoxEvent: function(component, evt, helper) {
	    helper.handleMessageBoxEvent(component, evt);
    },
    showAddQuestionModal: function(component, event, helper) {
        
        helper.showAddQuestionModal(component);
    	return;
    },
    showEditQuestionModal: function(component, event, helper) {
        
        var questions = component.get("v.questions");
        var recordid = event.target.id;
    	helper.showEditQuestionModal(component, questions, recordid);        
        
        
    },
    showPreviewSurveyModal: function(component, event, helper) {
        
        var servicename = component.get("v.servicename"),
        	questions = component.get("v.questions"),
            userevent = $A.get("e.c:EventDisplayModal");
        
        console.log(servicename, "SERVICENAME");
        
        userevent.setParams({
            "modalProperties": {
                "title": "Preview Survey",
                "size": "",
                "showHeader": "false"
            },
            "modalComponentName": "c:PreviewSurveyTabletView",
            "modalComponentProperties": {
                "questions": questions,
                "servicename": servicename
            }
        });
        userevent.fire();
        
    },     
    removeProjectServiceQuestion: function(component, event, helper) {
        
        var projectservicequestionid = event.target.id;
        component.set("v.removepsqid", projectservicequestionid)
        helper.openMessageBox(component, event, helper);
    },
    handleAddNewQuestion: function(cmp, event, helper) {
        event.stopPropagation();
        var questionId = event.getParam("questionId");
        var recordId = event.getParam("recordId");
        
        helper.async(cmp, function(cmp) {
          cmp.find('modalDialog').close();
        });
        
        
        cmp.set("v.questionId", questionId);
        cmp.set("v.recordId", recordId);
        
        helper.addCustomQuestion(cmp);
    },
    handleEditSurveyQuestion: function(cmp, event, helper) {
        
        var question = event.getParam("question");
        cmp.set("v.question", question);
        
        helper.async(cmp, function(cmp){
          cmp.find('modalDialog').close();
        });
        
        
        helper.editProjectServiceQuestion(cmp);
    },    
    handleQuestionActiveChange: function(cmp, event, helper) {
        
        helper.saveQuestionActiveChange(cmp);
        
    },
    openSurveyPreviewmodal : function(component, event, helper) {
        var questions = component.get("v.questions"),
            userevent = $A.get("e.c:EventDisplayModal");
        userevent.setParams({
            "modalProperties": {
                "title": "Survey Preview",
                "size": "large"
            },
            "modalComponentName": "c:SurveyPreview",
            "modalComponentProperties": {
                "questions": questions
            }
        });
        userevent.fire();
    },
    exportSurvey: function(component, event, helper) {
        console.log(component.get("v.questions"), "<-- QUESTIONS");
        console.log(component.get("v.projectservice"), "<-- projectservice");
        
        
         
        // Save as ProjectId_ProjectServiceTitle
        var projectService = component.get("v.projectservice"),
            questions = component.get("v.questions"),
        	filenamePrefix = "Project_" + projectService.ProjectNumber + "_" + projectService.ServiceTitle,
            fileContent = helper.buildFlatSurvey(questions, component, helper);
        
        helper.exportFile(filenamePrefix, fileContent);
    },

    // oh-3392 question optional support
    onOptionChanged: function(component, event, helper){
        helper.handleOptionChangeEvent(component, event);
    },

    showSpinner: function(component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible: true });
        evt.fire();
    },
    hideSpinner: function(component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible: false });
        evt.fire();
    }

})