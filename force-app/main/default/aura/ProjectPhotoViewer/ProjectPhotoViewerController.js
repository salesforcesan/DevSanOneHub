({
    onInit: function(cmp, evt, h){
        h.init(cmp);
    },

    onToggleFilter: function(cmp, evt, h){
        h.toggleFilter(cmp, evt);
    },

    onFilterChanged: function(cmp, evt, h){
        h.filterChanged(cmp,evt);
    },

    onFilterClear: function(cmp, evt, h){
        h.filterClear(cmp);
    },

    onLoadNextPage: function(cmp, evt, h){
        h.loadNextPage(cmp, evt);
    },

    onShowMore: function(cmp, evt, h){
        h.showMore(cmp);
    },

})