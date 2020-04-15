({
    doInit : function(component, event, helper) {
        component.set("v.securityelements", "ProjectService__c.Delete");
	},
    goToProjectServiceOverview : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "overview");
    },
    goToProjectServiceInstructions : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "instructions");
    },
    goToProjectServiceTools : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "tools");
    },
    goToProjectServiceCertifications : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "certifications");
    },
    goToProjectServiceTargets : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "targets");
    },
    goToProjectServiceSurvey : function(component, event, helper) {
        helper.goToProjectService(component, event, helper, "survey");
    }
})