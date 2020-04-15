({
    onInit: function(cmp, evt, h){
        h.init(cmp);
    },

    onSelectTab: function(cmp, evt, h){
        h.selectTab(cmp, evt);
    },

    onClose: function(cmp, evt, h){
        evt.preventDefault();
        evt.stopPropagation();
        h.close(cmp);
    },

    onIdChanged: function(cmp, evt, h){
        h.idChanged(cmp);
    },

    onPeerCloseNotified: function(cmp, evt, h){
        h.peerCloseNotified(cmp, evt);
    }
})