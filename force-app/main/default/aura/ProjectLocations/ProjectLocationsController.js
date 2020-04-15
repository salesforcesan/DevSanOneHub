({
        onInit: function(cmp, evt, helper) {
            helper.init(cmp, evt);
        },

        toggleLocationList: function(component, event, helper) {
            helper.toggleLocationList(component, event);
        },

        clickSelectAll: function(cmp, evt, helper) {
            helper.handleSelectAll(cmp);
        },

        onDataGridLinkCellClicked: function(cmp, evt, helper) {
            helper.gotoProjectLocationDetail(cmp, evt);
        },

        onDataGridSelectRowChanged: function(cmp, evt, helper) {
            helper.handleCheckOneLocationEvent(cmp, evt);
        },

        clickSelectOne: function(cmp, evt, helper) {
            helper.handleSelectOne(cmp);
        },

        onClickRefreshJobs: function(cmp, evt, helper) {
            helper.handleRefreshJobs(cmp, evt);
        },

        onClickRemoveSelected: function(cmp, evt, helper) {
            helper.handleRemoveSelected(cmp);
        },

        onClickRemoveAll: function(cmp, evt, helper) {
            helper.handleRemoveAll(cmp, evt);
        },

        onClickReAttempt: function(cmp, evt, helper) {
            helper.handleReAttempt(cmp, evt);
        },
    
        onClickCancelSelected: function(cmp, evt, helper) {
            helper.handleCancelSelected(cmp, evt);
        },

        onCancelLocationEvent: function(cmp, evt, helper) {
            helper.handleCancelLocationEvent(cmp, evt);
        },

        onClickCreateJobs: function(cmp, evt, helper) {
            helper.handleCreateJobs(cmp, evt);
        },

        onClickAddLocationsButton: function(cmp, evt, helper) {
            helper.onClickAddLocationsButton(cmp, evt);
        },

        selectAddLocationOption: function(cmp, evt, helper) {
            helper.selectAddLocationOption(cmp, evt);
        },

        onBlurSearchKeyword: function(cmp, evt, helper) {
            helper.searchKeyword(cmp, evt);
        },

        onClickFilter: function(cmp, evt, helper) {
            helper.filterLocations(cmp, evt);
        },

        onClickClearFilter: function(cmp, evt, helper) {
            helper.clearFilter(cmp, evt);
        },

        onClickScheduleLocations: function(cmp, evt, helper) {
            helper.handleScheduleLocations(cmp, evt, helper);
        },

        onClickScheduleLocationsInBulk: function(cmp, evt, helper) {
            helper.handleScheduleLocationsInBulk(cmp, evt);
        },        

        onClickExportJobs: function(cmp, evt, helper) {
            helper.handleExportJobs(cmp, evt);
        },

        onDataGridRendered: function(cmp, evt, helper) {
            helper.onDataGridRendered(cmp, evt);
        },

        handleCheckOneLocationEvent: function(cmp, evt, helper) {
            helper.handleCheckOneLocationEvent(cmp, evt);
        },

        handleShowSpinnerEvent: function(cmp, evt, helper) {
            helper.handleShowSpinnerEvent(cmp, evt);
        },

        onMessageBoxEvent: function(cmp, evt, helper) {
            helper.handleMessageBoxEvent(cmp, evt);
        },

        onRemoteRequest: function(cmp, evt, helper) {
            var route = evt.getParam('route'),
                params = evt.getParam('parameters');
            helper.doRemoteRequest(cmp, route, params);
        },

        onEndImportJobs: function(cmp, evt, helper){
            helper.endImportJobs(cmp,evt);
        },

        /* App Event subscription */
        subscribeRemoteActionSuccessAppEvent: function(cmp, evt, helper) {
            helper.onSuccessAppEvent(cmp, evt);
        },

        subscribeRemoteActionErrorAppEvent: function(cmp, evt, helper) {
            helper.onErrorAppEvent(cmp, evt);
        }
    }