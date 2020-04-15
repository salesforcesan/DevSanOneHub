({
	doInit: function(component, event, helper) {
        component.set("v.securityelements", "Project__c.Attachments");
		helper.doInit(component, event, helper);
	},
    prepareUpload: function(component, event, helper) {
        component.set("v.uploadedFile",'');
	},
    fileUploadHandler:function(component,event,helper){
        helper.fileUploadHandler(component,event);        
    },
    deleteFile: function(component, event, helper) {
        component.set("v.deleteAttachmentId",event.target.id);
        helper.openMessageBox(component, event, helper);
    },
    onMessageBoxEvent: function(component, event, helper) {
	    helper.handleMessageBoxEvent(component, event);
    }
    
})