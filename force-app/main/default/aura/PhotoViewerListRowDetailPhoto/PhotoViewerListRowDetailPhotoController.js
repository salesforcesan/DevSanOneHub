({
    onIdChanged: function(cmp, evt, h){
        h.idChanged(cmp);
    },

    onMarkFavorite: function(cmp, evt, h){
        h.markFavorite(cmp,evt);
    },

    onExport: function(cmp, evt, h){
        h.export(cmp, evt);
    },

    onShowMore: function(cmp, evt, h){
        h.showMore(cmp);
    },

    onInit: function(cmp, evt, h){
        h.init(cmp);
    },

})