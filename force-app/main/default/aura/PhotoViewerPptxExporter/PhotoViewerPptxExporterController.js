({
    onInit: function(cmp, evt, h){
        h.init(cmp);
    },

    onPhotosChanged: function(cmp, evt, h){
        h.photosChanged(cmp);
    },

    onComponentUnmount: function(cmp, evt, h){
        h.componentUnmount(cmp);
    }

})