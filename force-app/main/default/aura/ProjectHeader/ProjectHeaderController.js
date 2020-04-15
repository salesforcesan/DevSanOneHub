({
	doInit : function(component) {        
        
        console.log("In Projectheader DoInit");     
        component.set("v.securityelements","Project__c.Delete,Project__c.Cancel,Project__c.Clone,Project__c.Submit,Project__c.Edit,Project__c.ReleaseChanges");       
	},
    projectTags : function(component) {
        
        var action = component.get("c.getProjectTags");
        action.setParams({
            projectID : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                component.set("v.projectTags", a.getReturnValue());
            } 
            else if (a.getState() === "ERROR") {
                $A.log("Errors", a.getError());
            }
        });
        $A.enqueueAction(action);
        
    }, 
    submitForApprovalButtonClicked:function(component,event, helper) {        
       helper.openSubmitModalforVF(component);
    },
    deleteButtonClicked : function(component, event, helper) {         
        helper.openDeleteModal(component,event,helper);
    },
    cancelButtonClicked : function(component, event, helper) {         
        helper.openCancelModal(component,event,helper);
    },
    editButtonClicked : function(component, event, helper) { 
        helper.cEditProject(component, event, helper);
    },
    cloneButtonClicked : function(component, event, helper) { 
        helper.cCloneProject(component, event, helper);
    },
    releasechangesButtonClicked : function(component, event, helper) { 
        helper.openReleaseChangesModal(component,event,helper);
    },
    releaseoocfButtonClicked : function(component, event, helper) { 
        helper.openOOCFModal(component,event,helper);
    },
    handleConfirm: function(component, event, helper) {
        
        var confirmKey = event.getParam("confirmEventKey");
        console.log(confirmKey, "confirmKey");
        if (confirmKey === "deleteProject") {
            
            console.log("deleteProject event!");
            helper.cDeleteProject(component, event, helper);                
        } else if (confirmKey === "releaseProjectChanges") {
            
            console.log("releaseProjectChanges event!");
            helper.cReleaseProjectChanges(component, event, helper);
            
        }
        
    },
    updateComponent : function(component, event, helper){
        helper.refreshProject(component,event,helper);
        //helper.getUISecurityInformation(component);
    },
    onMessageBoxEvent: function(component,event,helper){
        var result={id:event.getParam('id'),
                    value:event.getParam('context')
                   };
        if(result.id==='deleteProjects' && result.value===1){
        	helper.cDeleteProject(component,event,helper);
        }
        else if (result.id==='releaseChanges' && result.value===1)
        {
            console.log("releaseProjectChanges event!");
            helper.cReleaseProjectChanges(component, event, helper);
        }
 		else if (result.id==='oocf' && result.value===1) {
            
            console.log("oocf event!");
            helper.cReleaseOOCF(component, event, helper);
            
        }        
    },
	GenerateJobManualHandler : function(component, event, helper){
        helper.GenerateJobManualHandler(component,event,helper);
    }    
    /*
	toggleDropdown : function(component, event, helper) {
              var dropdown = component.find('dropHeader');
              $A.util.toggleClass(dropdown,'slds-is-open');
     
    },
    
    hideDropdown : function(component, event, helper)
        {
            setTimeout(function(){
              var hidedrop = component.find('dropHeader');
              $A.util.removeClass(hidedrop,'slds-is-open');
            }, 200);
             component.find("dropHeader").getElement().blur();
        
    }
 	*/
    
})