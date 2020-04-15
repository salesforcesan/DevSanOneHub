({
    doInit : function(component, event, helper) {
        var psID = component.get("v.recordId");
        helper.createProjectServiceComponent(component);
        helper.LoadMethod(component, psID); 
        
       
    },

    handleSaveSuccess : function(component, event, helper) {
        console.log('Iam handle Save success+++++++++++++++++++');
        
        //console.log('Insode console success!');
        var spnr = component.find("Spinner"); 
        $A.util.removeClass(spnr, "slds-hide");
        helper.handleSaveSuccess(component);     
        
    },
    JobTemplateChangeHandler: function(component,event) {
        //console.log(event.getSource().get('v.value'));
        //console.log(component.find("JobTemplate").get("v.value"));        
        
        var selected = event.getSource().get('v.value');
        //console.log('~~~'+selected);
        
        var uploadManual = component.find("uploadManualDiv");
        
        if(selected=='Custom Manual'){
            $A.util.removeClass(uploadManual, "slds-hide");
            //console.log('~~~'+'yes');
        }
        else{
            $A.util.addClass(uploadManual, "slds-hide");
            //console.log('~~~'+'no');
        }
    },
    CancelClicked : function(component, event, helper) {
        var psID = component.get("v.recordId");
        //console.log('PSOverViewC   -   psid  --' + psID);
        helper.LoadMethod(component, psID);  
    },
    PreviewManual : function(component, event, helper) {
        var psObj = component.get("v.service");        
        var vfOrigin = "https://" + window.location.hostname;        
        //console.log('-- psObj.JobManualUrl --' + psObj.JobManualUrl+' -- ' +vfOrigin);
        var temp=psObj.JobManualUrl;
        
        if(psObj.JobManualTemplate === 'Standard')
            temp = vfOrigin+psObj.JobManualUrl;
        
        window.open(temp);
    },
    DeleteAttachmentHandler : function(component, event, helper) {
        //debugger;
        //window.scrollTo(0, 0);
        //console.log('inside delete');      
        //console.log('~~~~~~'+event.target.id);
        var psaID = event.target.id;          
        helper.MarkAttachmentForDelete(component, psaID);              
    },
    deleteProjectService : function(component, event, helper) { 
        //debugger;

        var prompt = component.find('messageBox');
        prompt && prompt.show({
            id: 'deletePrjectService',
            title: 'Delete Project Service',
            body: '<p>Are you sure that you want to delete the service?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },
    handleConfirm: function(component, event, helper) {
        //debugger;
        var projectServiceId = component.get("v.service.recordId");
        var confirmKey = event.getParam("confirmEventKey");
        //console.log(confirmKey, "confirmKey");
        if (confirmKey === projectServiceId) {
            //console.log("deleteProjectservice event!");
            helper.deleteProjectService(component);
        } 
    },
    deleteProjectServiceHandler: function(component,event,helper){
        //debugger;
        var result = {
            id: event.getParam('id'),
            value: event.getParam('context')
        };
        if (event.getParam('id') === 'deletePrjectService' && result.value == 1) {
            helper.deleteProjectService(component);            
        }
        
        var navEvent = $A.get("e.force:navigateToURL");
        navEvent.setParams({
            "url": "/one/one.app#/sObject/"+component.get("v.service").ProjectId+"/view?slideDevName=services&v=" + Date.now()
        });
        navEvent.fire();        
    },
    showCancelModal:function(component,event,helper){
        var dlg = component.find('modalDialog'),
            self = this;
        var args = {};
        args['dialogId'] = 'dlgProjectServiceCancel';
        args['projectServiceId'] = component.get('v.service.Id');
        args['projectId'] = component.get('v.service.ProjectId');
        //debugger;
        $A.createComponent('c:ProjectServiceCancel', args, function(cmp, status, errMsg) {
            if ('SUCCESS' === status) {
                dlg.set('v.title', 'Cancel Project Service');
                dlg.set('v.size', 'small');
                dlg.set('v.brand', 'error');
                dlg.set('v.body', cmp);
                dlg.show();
            }
        });
    },
    FileUploadHandler:function(component,event,helper){
        var spnr = component.find("Spinner"); 
        $A.util.removeClass(spnr, "slds-hide");
        helper.FileUploadHandler(component,event);        
    },
    saveButtonClicked : function(component, event, helper) {
        var spnr = component.find("Spinner"); 
        $A.util.removeClass(spnr, "slds-hide");
       
        var cmps = component.get("v.editorPlaceholder") || [];
        if (cmps.length > 0 && !!cmps[0].get("e.recordSave")){
            cmps[0].get("e.recordSave").fire();
        }

       var st = setTimeout(function(){ 		
             if (!!spnr)  		
             {		
                 console.log('std save timer hide');		
                 $A.util.addClass(spnr, "slds-hide");   		
                 $A.get('e.force:refreshView').fire();		
             }		
         }, 3000);    
  },
})