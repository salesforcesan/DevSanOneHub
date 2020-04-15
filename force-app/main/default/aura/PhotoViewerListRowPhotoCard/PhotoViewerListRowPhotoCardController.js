({
    onInit: function(cmp, evt, h){
        h.init(cmp);
    },

    onImageLoaded: function(cmp, evt, h){
        h.imageLoaded(cmp, evt);
    },

    onPhotoClicked: function(cmp, evt, h){
        evt.preventDefault();
        evt.stopPropagation();
        h.photoClicked(cmp, evt);
    },

    onPhotoChanged: function(cmp, evt, h){
        h.photoChanged(cmp);
    },

    onMarkFavorite: function(cmp, evt, h){
        h.markFavorite(cmp, evt);
    },

    onMarkUserFavorite: function(cmp, evt, h){
        h.markUserFavorite(cmp, evt);
    },

    onQC: function(cmp, evt, h){
        h.qc(cmp,evt);
    },

    onMarkTarget: function(cmp, evt, h){
        h.markTarget(cmp, evt);
    },

    onRender: function(cmp, evt, h){
        h.render(cmp);
    },

})