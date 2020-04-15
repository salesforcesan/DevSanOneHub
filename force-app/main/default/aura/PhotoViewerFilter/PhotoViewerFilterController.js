({
    onInit: function(cmp, evt, h) {
        h.init(cmp);
    },

    onRender: function(cmp, evt, h) {
        h.afterRender(cmp, evt);
    },

    onFilterChanged: function(cmp, evt, h) {
        h.filterChanged(cmp, evt);
    },

    onCheckboxChanged: function(cmp, evt, h) {
        h.checkboxChanged(cmp, evt);
    },

    onAppStateChanged: function(cmp, evt, h) {
        h.appStateChanged(cmp, evt);
    },

    onDropdownChanged: function(cmp, evt, h) {
        h.dropdownChanged(cmp, evt);
    },
    
    onchangeQuestion: function(cmp, evt, h) {
        h.checkQuestionAI(cmp, evt);
    },

    onStateChanged: function(cmp, evt, h) {
        h.stateChanged(cmp, evt);
    },

    onShowFavoritePhotos: function(cmp, evt, h) {
        h.showFavoritePhotos(cmp, evt);
    },

    onShowUserFavoritePhotos: function(cmp, evt, h){
        h.showUserFavoritePhotos(cmp, evt);
    },

    onShowDuplicatedPhotos: function(cmp, evt, h) {
        h.showDuplicatedPhotos(cmp, evt);
    },
    
    onShowUnmatched: function(cmp, evt, h) {
        h.showUnmatchedPhotos(cmp, evt);
    },

    onStartDateChanged: function(cmp, evt, h) {
        h.startDateChanged(cmp, evt);
    },

    onEndDateChanged: function(cmp, evt, h) {
        h.endDateChanged(cmp, evt);
    },

    onCityChanged: function(cmp, evt, h) {
        h.cityChanged(cmp, evt);
    },

    onApplyFilter: function(cmp, evt, h){
        h.applyFilter(cmp, evt);
    },

    onClearFilter: function(cmp, evt, h){
        h.clearFilter(cmp, evt);
    },

    onAdvanceClick: function(cmp, evt, h){
        h.advanceClick(cmp);
    },
    
    toggleFilters : function(cmp, evt, helper) {
        var toggleFilters = cmp.find("filtersPB");
        $A.util.toggleClass(toggleFilters, "oh-hide");
    },
})