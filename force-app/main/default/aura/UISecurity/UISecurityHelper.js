({
    applySecurity: function(component) {
        var self = this;
        
        function retry(cmp) {
            self.applySecurity(cmp);
        }
        
        if (!component.get('v.loaded')) {
            console.log('UI Security Information not loaded yet. Retrying security!!');
            //self._async(component, retry, 250);
            var id = window.setTimeout(
                $A.getCallback(function() {
                    window.clearTimeout(id);
                    //self.applySecurity(component);
                    self.getUISecurityInformation(component);
                }), 1500
            );
            return;
        } else {
            
            console.log ('---- Applying UI Security -----');
        }
        
        
        var hiddenelements = component.get("v.hiddenelements") || 0;
        var editableelements = component.get("v.editableelements") || 0;
        var securityelements = component.get("v.securityelements") || '';
        if (!securityelements) {
            return;
        }
        
        var searray = securityelements.split(",") || [];
        searray.forEach(function(auraId) {
            var components = component.getConcreteComponent().find(auraId);
            if (!!components) {
                var items = Array.isArray(components) ? components : [components];
                if (!!hiddenelements) {
                    self.handleHidddenFieldsLogic(items, hiddenelements[auraId]);
                }
                if (!!editableelements) {
                    self.handleEditFieldsLogic(items, editableelements[auraId]);
                }
            }
        });
    },
    
    getUISecurityInformation: function(component) {
        
        var message;
        var messageTitle;
        
        var recordid = component.get("v.recordId");
        
        if (recordid == null || typeof recordid === 'undefined')  
            return;
        
        
        component.set('v.loaded', false);
        var action = component.get("c.getUISecurityInformationApex", []);
        action.setParams({
            "recordid": recordid
        });
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            var oldsecuritymessage = component.get("v.uisecuritymessage");
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                component.set("v.hiddenelements", responseWrapper.Data["HiddenElements"]);
                component.set("v.editableelements", responseWrapper.Data["EditableElements"]);
                component.set("v.projectelements", responseWrapper.Data["ProjectElements"]);
                component.set("v.uisecuritymessage", responseWrapper.Message);
                component.set("v.projecttitle", responseWrapper.Data["ProjectElements"]["OperationsTitle"]);
                component.set('v.loaded', true);
                console.log(' ---- UI Security Info Loaded successfully!! ---');
                if (responseWrapper.Message == '') //No locking message from server
                {
                    //There was an ui security message and now it has cleared
                    if (oldsecuritymessage != null &&
                        oldsecuritymessage.length > 0) {
                        //Refresh the view so all the security will be reloaded and reapplied
                        //for all the components
                        self.showRefreshToast('Process completed', 'Process successfully completed. Page will now reload and re-apply security.');
                        
                        
                        
                        var id = window.setTimeout(
                            $A.getCallback(function() {
                                window.clearTimeout(id);
                                var appEvent = $A.get("e.c:EventProjectRefresh");
                                appEvent.fire();
                                $A.get('e.force:refreshView').fire();
                            }), 1000
                        );
                        
                    } else {
                        var projectstatus = responseWrapper.Data["ProjectElements"]["Status"];
                        //Check if the project status is >= launched
                        if (projectstatus == 'Launched' || projectstatus == 'In Progress' || projectstatus == 'Ended') {
                            var oldpendingchanges = component.get("v.pendingchanges");
                            var pendingchanges = (responseWrapper.Data["ProjectElements"]["PendingChanges"] === 'True' ||
                                                  responseWrapper.Data["ProjectElements"]["PendingChanges"] === 'true');
                            var releasependingchangesrequest = (responseWrapper.Data["ProjectElements"]["ReleasePendingChangesRequest"] === 'True' ||
                                                                responseWrapper.Data["ProjectElements"]["ReleasePendingChangesRequest"] === 'true');
                            
                            // If there is a change in pending status
                            if (pendingchanges != oldpendingchanges) {
                                component.set("v.pendingchanges", pendingchanges);
                                component.set("v.releasependingchangesrequest", releasependingchangesrequest);
                                
                                
                            }
                            
                            
                            var oldoocfchanges = component.get("v.oocfchanges");
                            var oocfchanges = (responseWrapper.Data["ProjectElements"]["OOCFChanges"] === 'True' ||
                                               responseWrapper.Data["ProjectElements"]["OOCFChanges"] === 'true');
                            var oocfchangesrequest = (responseWrapper.Data["ProjectElements"]["OOCFChangesRequest"] === 'True' ||
                                                      responseWrapper.Data["ProjectElements"]["OOCFChangesRequest"] === 'true');
                            
                            // If there is a change in oocf status
                            if (oocfchanges != oldoocfchanges) {
                                component.set("v.oocfchanges", oocfchanges);
                                component.set("v.oocfchangesrequest", oocfchangesrequest);
                                
                            }
                            
                            
                            
                            
                            var id = window.setTimeout(
                                $A.getCallback(function() {
                                    window.clearTimeout(id);
                                    self.getUISecurityInformation(component);
                                }), 15000
                            );
                        }
                    }
                } else //Locking message from server
                {
                    var id = window.setTimeout(
                        $A.getCallback(function() {
                            window.clearTimeout(id);
                            self.getUISecurityInformation(component);
                        }), 15000
                    );
                }
            } else {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
            }
        });
        $A.enqueueAction(action);
    },
    showRefreshToast: function(title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message
        });
        toastEvent.fire();
    },
    
    handleHidddenFieldsLogic: function(components, isHidden) {
        if (isHidden) {
            components.forEach(function(cmp) {
                if ($A.util.hasClass(cmp, 'show')) {
                    $A.util.removeClass(cmp, 'show');
                }
                if (!$A.util.hasClass(cmp, 'hide')) {
                    $A.util.addClass(cmp, 'hide');
                }
            });
        } else {
            components.forEach(function(cmp) {
                if ($A.util.hasClass(cmp, 'hide')) {
                    $A.util.removeClass(cmp, 'hide');
                }
                if (!$A.util.hasClass(cmp, 'show')) {
                    $A.util.addClass(cmp, 'show');
                }
            });
        }
    },
    
    handleEditFieldsLogic: function(components, isEdit) {
        if (isEdit) {
            components.forEach(function(cmp) {
                if ($A.util.hasClass(cmp, 'readonly')) {
                    $A.util.removeClass(cmp, 'readonly');
                }
                if (!$A.util.hasClass(cmp, 'notreadonly')) {
                    $A.util.addClass(cmp, 'notreadonly');
                }
            });
        }
    },
    
    _async: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 500;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },
})