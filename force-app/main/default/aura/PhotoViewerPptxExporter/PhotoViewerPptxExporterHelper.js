({
    init: function(cmp){
        var self = this;
        
        function onMessage(evt){
            self.onReceive(cmp, evt.data);
        }

        window.addEventListener('message', onMessage, false);
        cmp.set('v.onMessageFn', onMessage);
    },

    componentUnmount: function(cmp){
       window.removeEventListener('message', cmp.get('v.onMessageFn'), false);
    },

    onReceive: function(cmp, payload){
        var evt = cmp.getEvent('pptxExportCompleted');
        var shouldFire = false;

        switch(payload.name){
            case 'oh-export-photos-done':
                evt.setParams({
                    context: {
                        status: 1,
                        message: payload.value,
                    }
                });
                shouldFire = true;
                break;
            case 'oh-export-photos-has-error':
                evt.setParams({
                    context: {
                        status: 0,
                        message: payload.value,
                    }
                })
                shouldFire = true;
                break;            
       }
       shouldFire && evt.fire();
    },


    photosChanged: function(cmp){
        var photos = cmp.get('v.photos') || [];
        if (photos.length === 0) {return;}
        var frame = document.querySelector('#pptxExporter');
        var payload = {
            name: 'oh-export-photos',
            value: this._toCleanArray(photos),
        };
        
        frame.contentWindow.postMessage(payload, "*");
    },

    _toCleanArray: function(photos){
        var data = [];
        photos.forEach(function(p){
            var o = {};
            Object.keys(p).forEach(function(k){
                o[k] = p[k];
            });
            data.push(o);
        });
        return data;
    }
})