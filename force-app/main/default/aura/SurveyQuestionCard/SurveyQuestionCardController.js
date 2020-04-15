({
    slideInCard: function(cmp, e, h) {
        h.slideInCard(cmp, e, h);
        e.stopPropagation();
    },
    slideOutCard: function(cmp, e, h) {
        h.slideOutCard(cmp, e, h);
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
    onOptionalChange: function(component, event, helper){
        helper.slideOutCard(component, event);
        var question = component.get("v.question");        
        var projectServiceQuestionId = question.ProjectServiceQuestionId;
        var optionalQuestionCheckBox = component.find("OptionalQuestion");
        
        helper.updateOptionalChange(component, event, projectServiceQuestionId, optionalQuestionCheckBox.get("v.value"));
        
    },
    onCanRemoveChange: function(component, event, helper){
        helper.slideOutCard(component, event);
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
})