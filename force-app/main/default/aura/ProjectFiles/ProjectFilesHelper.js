({
    MAX_FILE_SIZE: 4500000, 
    CHUNK_SIZE: 950000,
    doInit : function(component, event, helper) {
        var projectId = component.get("v.projectId")
        var spinner = component.find("spinner"); 
        $A.util.removeClass(spinner, "slds-hide");
        //component.set("v.uploadedFile", "");
        var action = component.get("c.getProjectFiles");
        action.setParams({
            "projectId": projectId
        });
        var self = this;
        action.setCallback(self, function(response) {
            var result = JSON.parse(response.getReturnValue());
            if(result.State  !== "SUCCESS") {
                self.showToast(result.Message, 'error', 'sticky');
            }
            else{
                component.set("v.projectFileList", result.Data);
            }
            $A.util.addClass(spinner, "slds-hide");
            component.set("v.uploadedFile",'');
            component.find('file').getElement().value=''            
        });
        $A.enqueueAction(action);
    },
    fileUploadHandler: function(component,event) {   
	   	var fileInput = component.find("file").getElement();
    	var file = fileInput.files[0];
        if (file.size > this.MAX_FILE_SIZE) {
            alert('File is too large. Maximum supported file size is 4MB.\n');
    	    return;
        }
        
        var spinner = component.find("spinner"); 
        $A.util.removeClass(spinner, "slds-hide");
        //component.find("file").set("v.value", file.name);
        var fr = new FileReader();
        var self = this;
        fr.onload = $A.getCallback(function() {
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

            fileContents = fileContents.substring(dataStart);
       
    	    self.upload(component, file, fileContents);
        });
        fr.readAsDataURL(file);
        
    },
        
    upload: function(component, psc, fileContents) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        this.uploadChunk(component, psc, fileContents, fromPos, toPos, '');   
    },
     
    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId) {
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);

        action.setParams({
            parentId: component.get("v.projectId"),
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId
        });
       	console.log('******* attachId' + attachId);
        var self = this;
        action.setCallback(this, function(a) {
            attachId = a.getReturnValue();
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);    
            
            if (fromPos < toPos) {
            	self.uploadChunk(component, file, fileContents, fromPos, toPos, attachId);  
				console.log('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
            }
            else{
                component.set("v.uploadedFile", "");
                self.showToast('File saved', 'success');
                self.doInit(component);
            }
        });
            
        $A.enqueueAction(action); 
    },
    
    deleteFile: function(component) {
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");      
        var action = component.get("c.deleteProjectFile", []);
        action.setParams({
            "attachmentId": component.get("v.deleteAttachmentId"),
            "projectId": component.get("v.projectId")
        });
        var self = this;
        action.setCallback(self, function(response) {
            var result = JSON.parse(response.getReturnValue());
            if(result.State  !== "SUCCESS") {
                self.showToast(result.Message, 'error', 'sticky');
            }
            else{
                self.showToast('File deleted', 'success','sticky');
                component.set("v.projectFileList", result.Data);
            }
            $A.util.addClass(spinner, "slds-hide");
            component.set("v.deleteAttachmentId", '');  
        });
        $A.enqueueAction(action);
    },
    showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    openMessageBox : function(component, event, helper) {
        var prompt = component.find('messageBox');
        prompt && prompt.show({
            id: 'deleteFile',
            title: 'Delete File',
            body: '<p>Are you sure that you want to delete the file?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },
    handleMessageBoxEvent: function(component, event) {
        var result = {
            id: event.getParam('id'),
            value: event.getParam('context')
        };
        if (result.id === 'deleteFile' && result.value == 1) {
            this.deleteFile(component);
        }
    }
})