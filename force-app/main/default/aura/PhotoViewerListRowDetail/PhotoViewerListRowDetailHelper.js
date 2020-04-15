({  
    init: function(cmp){
        var msg = $A.get('e.c:PhotoDetailPeerCloseNotification');
        msg.setParams({
            id: cmp.get('v.id')
        });
        msg.fire();
        this._initSuperUser(cmp);
    },

    _initSuperUser: function(cmp){
        var usage = cmp.get('v.usage');
        var superUser = usage != 'Retailer' && usage != 'Community Viewer';
        cmp.set('v.isSuperuser', superUser);
    },


    selectTab: function(cmp, evt){
        var tabId = evt.getSource().get('v.id');
        var target = cmp.find(tabId);
        
        if(!!target){
            target.set('v.id', cmp.get('v.id'));
        }
    },


    close: function(cmp) {
        var msg = cmp.getEvent('onClosePhotoDetail');
        msg.setParams({
            context: cmp.get('v.id')
        });
        msg.fire();
    },

    idChanged: function(cmp){
        var photoId = cmp.get('v.id');
        var selectTabId = cmp.find('photoTabset').get('v.selectedTabId');

        if(!$A.util.isEmpty(photoId)){
            switch(selectTabId){
                case 'photoDetail':
                    cmp.find('photoDetail')
                    .set('v.id', photoId);
                break;
                case 'photoChatter':
                    cmp.find('photoChatter')
                    .set('v.id', photoId);
                break;
            }
        }
    },

    peerCloseNotified: function(cmp, evt){
        var photoId = evt.getParam('id'),
            currentId = cmp.get('v.id');
        
        if($A.util.isEmpty(photoId) || photoId === currentId){
            return;
        }
        this.close(cmp);
    }

})