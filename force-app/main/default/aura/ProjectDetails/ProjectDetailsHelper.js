({
    getProjectDetails: function(component, projID) {
         var message;
        var messageTitle;
       
        this.showSpinner(component);

        var action = component.get("c.GetProjectWithAttributes");
        action.setParams({
            "recordId": projID
        });
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            if (state === "SUCCESS") {
                component.set("v.project", result.getReturnValue());
            } else {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
				//$A.util.toggleClass(spinner, "slds-hide");
                $A.util.addClass(spinner, "slds-hide");
                self.showToast(messageTitle, message, 'error');
            }
            self._asyncCall(
                component,
                function(cmp) {
                    self.hideSpinner(cmp);
                }, 300
            );

        });
        $A.enqueueAction(action);
    },
    saveProject: function(component) {

        var message;
        var messageTitle;
        var projectwrapper = JSON.stringify(component.get("v.project"));
        //console.log('PWrapper: ' + projectwrapper );
        var ProjAttributeList = component.get("v.project.ProjAttributeList");
        //console.log('ProjAttributeList: ' + ProjAttributeList + '  '+ProjAttributeList.length+ '  ');
        var isErrored = false;
        var errorMsg = '';
        for (var key in ProjAttributeList) {
            var obj = ProjAttributeList[key];
            if (obj['isRequired'] == true && (obj['AttributeValue'] == '' || obj['AttributeValue'] == 'Select')) {
                errorMsg = errorMsg + obj['AttributeName'] + " is required.\n";
                isErrored = true;
            }

        }

        if (isErrored) {
            //alert(errorMsg);
            this.showToast("Custom Attributes", errorMsg, 'error');
            return false;
        }

        var spinner = component.find("projectDetailsSpinner");
        $A.util.removeClass(spinner, "slds-hide");


        var action = component.get("c.saveProjectAttributesApex", []);
        action.setParams({ "stringprojectwrapper": projectwrapper });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = 'Successfully saved project changes. ';
            if (state === "SUCCESS") {

                //TODO:temp fix - breaks in managed package wihtout this if
                setTimeout(function() {
                    if (!!component.find("project_edit").get("e.recordSave")) {
                        component.find("project_edit").get("e.recordSave").fire();
                    } else {
                        self.showToast(messageTitle, message, 'success');
                    }
                    $A.util.addClass(spinner, "slds-hide");
                }, 1500);

            } else {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;

                self.showToast(messageTitle, message, 'error');
                $A.util.addClass(spinner, "slds-hide");
            }



        });
        $A.enqueueAction(action);
    },
    handleSaveSuccess: function(component) {

        var spinner = component.find("projectDetailsSpinner");
        var messageTitle = 'Server message';
        var message = 'Successfully saved project changes. ';
        $A.util.addClass(spinner, "slds-hide");
        this.showToast(messageTitle, message, 'success');
        this.notifyProjectUpdate(component);

        var projID = component.get("v.ProjectId");
        var action = component.get("c.GetProject");
        action.setParams({ "recordId": projID });
        var self = this;
        action.setCallback(self, function(result) {
            debugger;
            var state = result.getState();
            if (state === "SUCCESS") {
                var project = result.getReturnValue();
                if (project.ApexJobName != "") {
                    window.location.reload();
                }
            }

        });
        $A.enqueueAction(action);
    },

    showSpinner: function(cmp) {
        var spinner = cmp.find("projectDetailsSpinner");
        //$A.util.toggleClass(spinner, "slds-hide");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(cmp) {
        var spinner = cmp.find("projectDetailsSpinner");
        //$A.util.toggleClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-hide");
    },

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    navigate: function(component, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        $A.util.addClass(component.find("projectDetailsSpinner"), "slds-hide");
        urlEvent.fire();
    },
    notifyProjectUpdate: function(component) {
        var action = component.get("c.GetProject");
        var projectId = component.get("v.project.Id");
        action.setParams({
            "recordId": projectId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var updatedProject = response.getReturnValue();
                //component.set("v.project",updatedProject);
                var appEvent = $A.get("e.c:EventProjectRefresh");
                appEvent.setParams({ "project": updatedProject });
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    _asyncCall: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 200;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },
})