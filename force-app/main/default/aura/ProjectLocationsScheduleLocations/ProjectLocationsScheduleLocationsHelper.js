({
    AppSettings: {
        'Events': {
            'ActionRequestAppEvent': 'e.c:ActionRequestAppEvent',
            'CloseDialogEvent': 'closeDialogEvent'
        },
        Routes: {
            'ScheduleLocations': 'ProjectLocations/modify/scheduleLocations'
        }
    },
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },

    onInit: function(cmp, evt) {
        var locations = cmp.get('v.locations') || [];
        var mapFunc = $A.util.getBooleanValue(cmp.get('v.searchByOneHubId')) ?
            function(e) {
                return [e.num, e.name].join(' ');
            } : function(e) {
                return e.num;
            };
        locations = locations.map(mapFunc);
        cmp.set('v.locationString', locations.join('<br/>'));
    },

    _dispatch: function(cmp, payload) {
        var action = cmp.getEvent('onRemoteRequest');
        action.setParams(payload);
        action.fire();
    },

    scheduleLocations: function(cmp, evt) {
        var data = cmp.get('v.locations').map(function(e) {
            return e.id;
        });
        var message = {
            'route': this.AppSettings.Routes.ScheduleLocations,
            'parameters': {
                'projectId': cmp.get('v.projectId'),
                'locations': data,
                'scheduleDate': this._translateDate(cmp.get('v.selDate'))
            }
        };
        cmp.find('busyIndicator').show();
        this._dispatch(cmp, message);
    },

    _translateDate: function(dt) {
        var arr = dt.split('/');
        if (arr.length === 3) {
            return [arr[2], arr[0], arr[1]].join('-');
        }
        return dt;
    },

    cancel: function(cmp) {
        var event = cmp.getEvent(this.AppSettings.Events.CloseDialogEvent);
        event.fire();
    },

    onSuccess: function(cmp, evt) {
        var self = this;
        if (!this._isMyEvent(evt)) {
            return;
        }

        function ok() {
            cmp.find('busyIndicator').hide();
            var result = evt.getParam('value');
            self._notify(cmp, result.message, result.state);
        }

        this._asyncCall(cmp, ok, 3000);
    },

    _isMyEvent: function(evt) {
        return (evt.getParam('route') === this.AppSettings.Routes.ScheduleLocations) ? 1 : 0;
    },

    _asyncCall: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 200;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback();
            }
        }), duration);
    },

    onError: function(cmp, evt) {
        if (!this._isMyEvent(evt)) {
            return;
        }
        this._notify(cmp, evt.getParam('error'), this.NOTIFICATION_TYPES.ERROR);
        cmp.find('busyIndicator').hide();
    },

    selectDate: function(cmp, evt) {
        var date = evt.getParam('context');
        cmp.set('v.selDate', [date.getMonth() + 1, date.getDate(), date.getFullYear()].join('/'));
    },

    _notify: function(cmp, msg, type) {
        cmp.find('notification').show(msg, type);
    }
})