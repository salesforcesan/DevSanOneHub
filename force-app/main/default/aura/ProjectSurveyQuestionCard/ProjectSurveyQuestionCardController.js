({
    doInit: function(component, event, helper){
 
    },
    slideInCard: function(cmp, e, h) {
        var surveyCard = cmp.find("surveyCard");
        $A.util.addClass(surveyCard, 'flip');
        $A.util.removeClass(surveyCard, 'flip-out');
        e.stopPropagation();
    },
    slideOutCard: function(cmp, e, h) {
        var surveyCard = cmp.find("surveyCard");
        $A.util.addClass(surveyCard, 'flip-out');
        $A.util.removeClass(surveyCard, 'flip');
        e.stopPropagation();
    }, 
    showEditQuestionModal: function(component, event, helper) {
        helper.showEditServiceQuestionModalHandler(component, event, 'question');       
    },
    showEditServiceQuestionModal: function(component, event, helper){        
        helper.showEditServiceQuestionModalHandler(component, event, 'rules');       
    },        
    removeSurveyQuestion: function(component, event, helper) {
        helper.showEditServiceQuestionModalHandler(component, event, 'delete');
    },
    uploadTargets: function(component, event, helper) {
        helper.showEditServiceQuestionModalHandler(component, event, 'uploadTargets');
    },
    onOptionalChange: function(component, event, helper){
        
        var question = component.get("v.question");        
        var projectServiceQuestionId = question.ProjectServiceQuestionId;
        var optionalQuestionCheckBox = component.find("OptionalQuestion");
        
        helper.updateOptionalChange(component, event, projectServiceQuestionId, optionalQuestionCheckBox.get("v.value"));
        
    },
    onCanRemoveChange: function(component, event, helper){
        
        var question = component.get("v.question");
        var projectServiceQuestionId = question.ProjectServiceQuestionId;
        var canRemoveQuestionCheckBox = component.find("CanRemoveQuestion");
        
        helper.updateCanRemoveChange(component, event, projectServiceQuestionId, canRemoveQuestionCheckBox.get("v.value"));        
    },
 	toggleException: function (component, event, helper) {
        helper.toggleToolTip(component, event, 'Exception');
    },
    toggleOptional: function (component, event, helper) {
        helper.toggleToolTip(component, event, 'Optional');
    },
    toggleCanRemove: function (component, event, helper) {
        helper.toggleToolTip(component, event, 'CanRemove');
    },
    onQuestionActiveChange: function(component, event, helper) {
        console.log('active change method');
        helper.saveQuestionActiveChange(component);
        
    },
})