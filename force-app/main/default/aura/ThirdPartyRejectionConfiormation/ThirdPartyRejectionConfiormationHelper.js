({
    'EVENTS': {
        'CANCEL': 'rejectionworkerEvent',
        'CLOSE_DIALOG': 'closeDialogEvent'
    },
    
    cancel: function(cmp, evt) {
        cmp.getEvent(this.EVENTS.CLOSE_DIALOG)
        .fire();
    },
    
    submit: function(cmp, evt) {
        var value = {
          'comment': cmp.find('comment').get('v.value')
        };
        
        
       
        
        if (!value.comment) {
            this._notify(cmp, 'Comment is required ', 'error');
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