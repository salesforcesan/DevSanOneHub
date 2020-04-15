({
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },    
    
    init: function(component){
        var payload,
            self = this,
            psId = component.get('v.recordId');
        
        function doResponse(cmp, result){
            var str =  JSON.stringify(result);
            component.set('v.projectId', result.ProjectId);
            console.log('result: ' + str);
            console.log('ProjectId: ' + component.get('v.projectId'));
        }

        payload = {
            'action': 'GetProjectService',
            'callback': doResponse,
            'query': {
                'projServiceId': psId
            }
        };

        self._dispatch(self, component, payload);
    },
    
    closeActionDialog: function(projectId) {
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                 var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

                var navEvent = $A.get("e.force:navigateToURL");
                navEvent.setParams({
                    "url": "/one/one.app#/sObject/" + projectId + "/view?slideDevName=services&v=" + Date.now()
                });
                navEvent.fire();
            }), 2000
        );
    },
    
    DeleteService : function(component, event, helper) {
        
        var self = self = this;
        
        function doResponse(cmp, result){
            self._msgBox(component, 'success', 'Service has been successfully deleted.');
            self.closeActionDialog(component.get('v.projectId'));
        }

        var payload = {
            action: 'deleteProjectServiceApex',
            query: {
                'projectServiceId': component.get("v.recordId")
            },
            callback: doResponse
        };
        self._dispatch(self, component, payload);
        
    },
    _dispatch: function(self, cmp, payload) {
        var request, errors, state;
        self._showSpinner(cmp);

        function handleResponse(response) {
            state = response.getState();
            if (!cmp.isValid()) {
                self._msgBox(cmp, 'error', 'The component is out of scope.');
                return;
            }
            if (state === 'SUCCESS') {
                if (!!payload.callback) {
                    payload.callback(cmp, response.getReturnValue());
                }
                self._hideSpinner(cmp);
                return;
            }

            switch (state) {
                case 'ERROR':
                    errors = response.getError();
                    if (!!errors && !!errors[0] && !!errors[0].message) {
                        self._msgBox(cmp,'error', errors[0].message);
                    } else {
                        self._msgBox(cmp,'error', 'The system run into an unknown error.');
                    }
                    break;
                case 'INCOMPLETE':
                    self._msgBox(cmp,'error', 'The system run into an incomplete state.');
                    break;
                default:
                    self._msgBox(cmp,'error', 'The system run into an unknown state.');
                    break;
            }
            self._hideSpinner(cmp);
        }

        try {
            request = cmp.get('c.' + payload.action);
            request.setParams(payload.query);
            request.setCallback(this, handleResponse);
            $A.enqueueAction(request);
        } catch (ex) {
            console.log(ex);
            self._msgBox(cmp,'error', ex.getMessage());
        }
    },
    
    _showSpinner: function(cmp) {
        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    _hideSpinner: function(cmp) {
        var spinner = cmp.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    _msgBox: function(cmp, type, msg) {
        var notify = cmp.find('notification');
        notify.show(msg, type,true, 5000);
    }    
})