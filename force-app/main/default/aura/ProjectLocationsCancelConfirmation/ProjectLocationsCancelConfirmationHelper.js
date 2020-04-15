({
    'EVENTS': {
        'CANCEL': 'cancelLocationEvent',
        'CLOSE_DIALOG': 'closeDialogEvent'
    },
    
    cancel: function(cmp, evt) {
        cmp.getEvent(this.EVENTS.CLOSE_DIALOG)
        .fire();
    },
    
    submit: function(cmp, evt) {
        var value = {
            'reason': cmp.find('reason').get('v.value'),
            'comment': cmp.find('comment').get('v.value')
        };
        
        
        if (!value.reason) {
            this._notify(cmp, 'Please select a valid cancel reason.', 'error');
            return;
        }
        
        if (value.reason.toLowerCase() == 'other' && !value.comment) {
            this._notify(cmp, 'Comment is required for reason: Other', 'error');
            return;
        }
        
        var event = cmp.getEvent(this.EVENTS.CANCEL);
        event.setParams({
            'id': cmp.get('v.dialogId'),
            'context': value
        });
        event.fire();
        this.cancel(cmp, evt);
    },
    
    _notify: function(cmp, msg, type) {
        cmp.find('notification').show(msg, type);
    }
})