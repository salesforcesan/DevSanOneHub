({
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },
    REASON_NONE: '-- select --',

    init: function(component){
        var payload,
            self = this,
            psId = component.get('v.recordId');
        
        function doResponse(cmp, result){
            var service = {
                'title': result.title,
                'status': result.status,
                'reason': '',
                'comment': ''
            },
            reasons = result.reasons || [];
            reasons.unshift(self.REASON_NONE);
            cmp.set('v.projectId', result.projectId);
            cmp.set('v.service', service);
            cmp.set('v.cancelReasons',reasons);
        }

        payload = {
            'action': 'GetCancelServiceDataset',
            'callback': doResponse,
            'query': {
                'projectServiceId': psId
            }
        };

        self._dispatch(self, component, payload);
    },

    _closeActionDialog: function(projectId) {
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

    cancelService: function(component, event, helper) {
        var payload,
            self = this,
            service = component.get('v.service'),
            projectServiceId = component.get("v.recordId");

        if(!service.reason || service.reason === self.REASON_NONE){
            self._msgBox(component,'error', 'A valid reason must be selected.');
            return;
        }

        function doResponse(cmp, result){
            self._msgBox(cmp, 'success', 'Service has been successfully canceled.');
            self._closeActionDialog(cmp.get('v.projectId'));
        }

        payload = {
            action: 'CancelProjectService',
            query: {
                'psId': component.get("v.recordId"),
                'reason': service.reason,
                'comment': service.comment
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
                self._msgBox(cmp, 'error', 'Component is out of scope.');
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
                        self._msgBox(cmp,'error', 'System has run into an unknown error. Contact Support.');
                    }
                    break;
                case 'INCOMPLETE':
                    self._msgBox(cmp,'error', 'System has run into an incomplete state. Contact Support.');
                    break;
                default:
                    self._msgBox(cmp,'error', 'System has run into an unknown state. Contact Support.');
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