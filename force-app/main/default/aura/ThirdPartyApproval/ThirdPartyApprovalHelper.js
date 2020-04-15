({
    
    DIALOG_DEFINITIONS: {
        
        'REJECT_WORKERS': {
            'id': 'dlgrejecteworkers',
            'component': 'c:ThirdPartyRejectionConfiormation',
            'size': 'medium',
            'title': 'Reject Selected  3 PL Workers',
            'brand': 'error'
        }
    },
    
    JobAttemptWorkerList : function(component,event) {
        
        
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        
        var action = component.get('c.fetch3PLAgencyPendingApprovalList');
        // pass the all selected record's Id's to apex method 
        action.setParams({
            "userId": userId
        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(state);
                if (response.getReturnValue() != '') {
                    
                    component.set('v.jobattemptWorkers', response.getReturnValue());
                    
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    renderRejectionDialog:function(component, event, helper)
    {
        
        this._renderDialog(component, this.DIALOG_DEFINITIONS.REJECT_WORKERS, {
            
        });
    },
    _renderDialog: function(root, dialogDefinition, params) {
        var dlg = root.find('modalDialog'),
            self = this,
            args = (!!params) ? this._cloneObject(params) : {};
        args['dialogId'] = dialogDefinition.id;
        Object.keys(dialogDefinition)
        .forEach(function(k){
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
        var isSuccess = msgType === 'success' ? true : false;
        e.set('v.hideCloseButton', isSuccess);
        e.show(msg, msgType, isSuccess);
    },
    _cloneObject: function(obj) {
        var t = {};
        for (var nm in obj) {
            t[nm] = obj[nm];
        }
        return t;
    },
    
    pendingRequestslist:function(component,event,data) {
        var whichbutton = event.getSource().getLocalId();
        console.log('hello which button::'+ whichbutton);
        var Requeststatus ='';
        var RequestComments ='';
        if(whichbutton =="approve")
        { 
            Requeststatus ="Approve";
            RequestComments ="Please Approve all the Requests";
            
        }
        else
        {
            
            Requeststatus ="Reject"
            var val = event.getParam('context');
            
            RequestComments = val.comment.toString();
        }
        
        
        
        var selctedRec = [];
        
        for (var i = 0; i < data.length; i++){
            selctedRec.push(data[i].Id); 
            //alert("You selected: " + data[i].Id);
        }
        
        var action = component.get("c.pending3PLRequests");
        
        action.setParams({
            "jawList": selctedRec,
            "reqComments":RequestComments,
            "approverReqStatus":Requeststatus
            
        });
        action.setCallback(this, function(response){
            var state =  response.getState();
            console.log('s=' +state)
            if(state == "SUCCESS")
            {
                var self= this;
                
                $A.get("e.force:refreshView").fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type" : "success",
                    "message": "Successfully " + Requeststatus + " "+ " all the Requests"
                });
                toastEvent.fire();
                
                return;
                // console.log("Successfully approved..");
            }else if (state=="ERROR") {
                var self= this;
                setTimeout($A.getCallback(() => self.JobAttemptWorkerList(component, event)), 5000);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type" : "error",
                    "message": "" + action.getError()[0].message
                });
                toastEvent.fire();
                return;
                
                
                
            }
        });
        $A.enqueueAction(action);
    },
    
    
    
    sortData: function(cmp, fieldName, sortDirection) {
        var data = cmp.get("v.jobattemptWorkers");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.jobattemptWorkers", data);
    },
    sortBy: function(field, reverse, primer) {
        var key = primer ?
            function(x) {
                return primer(x[field])
            } :
        function(x) {
            return x[field]
        };
        reverse = !reverse ? 1 : -1;
        return function(a, b) {
            return a = key(a) ? key(a) : '',
                b = key(b) ? key(b) : '',
                reverse * ((a > b) - (b > a));
        }
    },
    
    
})