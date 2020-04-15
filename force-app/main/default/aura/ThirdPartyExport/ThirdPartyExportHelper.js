({
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },
    DIALOG_DEFINITIONS: {
        'IMPORT_3PL': {
            'id': 'dlgBulk3PLWorkers',
            'component': 'c:BulkImporter',
            'size': 'medium',
            'title': 'Bulk Import 3PL Workers',
            'pageInstruction': 'Import a file by clicking on the Import button.',
            'importRequestService': "JobattemptWorkerImportRequestService",
            'attachmentName': "%import_jobattemptworker%",
            'jobName': "Import Jobattempt Worker"
        },
    },
    onInt: function(component, event, helper)
    {
        
        this._getReportUrl(component, event, helper);
        
    },
   
    _getLoggedInUser3PlAgency: function(component, event, helper)
    {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        
        var action = component.get("c.getLoggedInUserThirdPartyAgency");
        action.setParams({
            loggedInuserId : userId,
        });
           action.setCallback(this, function(response) {
            var self =this;
             var state = response.getState();
            if (state == 'SUCCESS') 
            {
               if(!$A.util.isEmpty(response.getReturnValue()))
                {
                   // system.debug(response.getReturnValue());
                  // console.log(response.getReturnValue());
                   // alert(response.getReturnValue());
                    
                    component.set('v.ParentId', response.getReturnValue());
                    
                }
            }
            else
            {
               var errorMsg = action.getError()[0].message;
            //console.log(errorMsg);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                type: 'error',
                message: errorMsg
            });
             toastEvent.fire();
                
            }
           
        });
        $A.enqueueAction(action);
        
    },
    endImportJobs: function(cmp, evt) {
        
        this._asyncCall(cmp, function(cmp) {
            window.location.reload();
        }, 1000);
        
        var childCmp = component.find("modalDialog")
        childCmp.close();
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
    
    _getReportUrl : function(component, event, helper) {
        
        var action = component.get("c.getThirdPartyAgencyReportUrl");
        action.setParams({
            jobAttemptWorkerId : component.get("v.recordId"),
        });
        
        
        action.setCallback(this, function(response) {
            var self =this;
            
            if(!$A.util.isEmpty(response.getReturnValue()))
            {
                component.set('v.thirdPartyReportURL', response.getReturnValue());
            }
            
        });
        $A.enqueueAction(action);
        
        
    },
    
    _jobAttemptWorkerReport: function(component,reportUrl)
    {
        $A.get("e.force:navigateToURL").setParams({ 
            "url":  reportUrl,
        }).fire();
        
        
        
    },
    import3PLWorkers:function(component, event,helper)
    {
        var loggedInuserParentId = component.get('v.ParentId');
        //alert(user3plAccounts);
      
        if($A.util.isEmpty(loggedInuserParentId) || loggedInuserParentId == 'undefined' )
        {
           var errorMsg ="Logged in user's ThirdParty Agency is Missing";
           var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                type: 'error',
                message: errorMsg
            });
             toastEvent.fire();
            return;
         
        }
        
          
        this._renderDialog(component, this.DIALOG_DEFINITIONS.IMPORT_3PL, {
            parentId:loggedInuserParentId,
        });
       
    },
    
    _renderDialog: function(root, dialogDefinition, params) {
        var dlg = root.find('modalDialog'),
            self = this,
            //project = root.get('v.project'),
            args = (!!params) ? this._cloneObject(params) : {};
        args['dialogId'] = dialogDefinition.id;
        // args['parentId'] = root.get("v.recordId");
        Object.keys(dialogDefinition)
        .forEach(function(k) {
            args[k] = dialogDefinition[k];
        });
        
        $A.createComponent(dialogDefinition.component, args,
                           function(cmp, status, errMsg) {
                               if ('SUCCESS' === status) {
                                   dlg.set('v.title', dialogDefinition.title);
                                   dlg.set('v.size', dialogDefinition.size);
                                   dlg.set('v.brand', dialogDefinition.brand || '');
                                   dlg.set('v.body', cmp);
                                   dlg.show();
                               } else if ('ERROR' === status) {
                                   self._notify(root, errMsg, self.NOTIFICATION_TYPES.ERROR);
                               }
                           });
    },
    _notify: function(cmp, msg, msgType) {
        var e = cmp.find('notification');
        e.set('v.message', msg);
        e.set('v.type', msgType);
        e.set('v.visible', true);
    },
    _cloneObject: function(o) {
        var ret = {};
        for (var nm in o) {
            ret[nm] = o[nm];
        }
        return ret;
    },
    
    
    
})