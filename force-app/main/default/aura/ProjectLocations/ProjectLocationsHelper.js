({
    EXPORT_INDEX: 0,
    EXPORT_JOB_URL: '/apex/{namespace}JobExporter?id={projectId}',
    MESSAGES: {
        'RemoveLocations': 'The selected location(s) will be deleted. If you are sure, please click the "continue" button, otherwise close or cancel the action.'
    },
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },
    DIALOG_DEFINITIONS: {
        'SELECT_OPTIONS': {
            'id': 'dlgSelectOptions',
            'component': 'c:ProjectLocationsAdditionOption',
            'size': 'medium',
            'title': 'Add Locations'
        },
       
        'PASTE_LIST': {
            'id': 'dlgPasteList',
            'component': 'c:ProjectLocationsPasteList',
            'size': 'x-medium',
            'title': 'Add List of Locations'
        },
        'SEARCH_LOCATIONS': {
            'id': 'dlgSearchLocations',
            'component': 'c:ProjectLocationsSearchLocations',
            'size': 'x-medium',
            'title': 'Add Locations by Search and Filter'
        },
        'SCHEDULE_LOCATIONS': {
            'id': 'dlgScheduleLocations',
            'component': 'c:ProjectLocationsScheduleLocations',
            'size': 'x-medium',
            'title': 'Set Schedule Date'
        },
        'SCHEDULE_LOCATIONS_INBULK': {
            'id': 'dlgBulkScheduleLocations',
            'component': 'c:BulkImporter',
            'size': 'medium',
            'title': 'Bulk Update Locations',
            'pageInstruction': 'Import a file by clicking on the Import button. Please note that the supported date formats are YYYY-MM-dd and MM/dd/YYYY.',
            'importRequestService': "LocationImportRequestService",
            'attachmentName': "%import_locations%",
            'jobName': "Import Locations"
        },
        'UPLOAD_FILE': {
            'id': 'dlgUploadFile',
            'component': 'c:ProjectLocationsUploadFile',
            'size': 'x-medium',
            'title': 'Project Locations Upload'
        },
        'CANCEL_LOCATIONS': {
            'id': 'dlgCancelLocations',
            'component': 'c:ProjectLocationsCancelConfirmation',
            'size': 'medium',
            'title': 'Cancel Selected Locations',
            'brand': 'error'
        }
    },

    ADDLOCATIONS_OPTIONS: {
        'UPLOAD_FILE': 'uploadFile',
        'PASTE_LIST': 'pasteList',
        'SEARCH_LOCATIONS': 'searchLocations'
    },

    AppSettings: {
        'Events': {
            'RemoteActionRequest': 'e.c:ActionRequestAppEvent'
        },
        'Actions': {
            'CancelLocations': 'cancelLocations'
        },
        'Routes': {
            'SearchKeyword': 'ProjectLocations/search',
            'FilterProjectLocations': 'ProjectLocations/filter',
            'GetSettings': 'ProjectLocationSettings/get',
            'RemoveLocations': 'ProjectLocations/remove',
            'RemoveAllLocations': 'ProjectLocations/remove',
            'RemoveOneLocation': 'ProjectLocations/remove',
            'CreateJobs': 'Jobs/add',
            'AddProjectLocations': 'ProjectLocations/add',
            'AddProjectLocationsByPasteList': 'ProjectLocations/add/pasteList',
            'AddProjectLocationsByUploadFile': 'ProjectLocations/add/uploadFile',
            'ScheduleLocations': 'ProjectLocations/modify/scheduleLocations',
            'CancelLocations': 'ProjectLocations/modify/cancelLocations',
            'ReattemptLocations': 'ProjectLocations/modify/reattemptLocations'
        }
    },

    UISettings: {
        'CREATE_JOB': 'ProjectLocation__c.CreateJob',
        'ADD': 'ProjectLocation__c.Add',
        'DELETE': 'ProjectLocation__c.Delete',
        'CANCEL': 'ProjectLocation__c.Cancel',
        'REATTEMPT': 'ProjectLocation__c.ReAttempt',
        'IMPORT_LOCATION': 'ProjectLocation__c.ImportLocation',
        'SET_SCHEDULE': 'ProjectLocation__c.SetSchedule'
    },

    afterRender: function(cmp) {
        this._showSpinner(cmp, 1);
    },

    //View Related
    init: function(cmp, evt) {
        // this._initDataGrid(cmp);
        this._initFilter(cmp);
        this._initLocations(cmp);
        this._initUiSecurity(cmp);

    },

    _initUiSecurity: function(cmp) {
        cmp.set('v.securityelements', [
            this.UISettings.CANCEL,
            this.UISettings.CREATE_JOB,
            this.UISettings.IMPORT_LOCATION,
            this.UISettings.SET_SCHEDULE,
            this.UISettings.DELETE,
            this.UISettings.ADD,
            this.UISettings.REATTEMPT
        ].join(','));
    },

    _initDataGrid: function(cmp) {
        var cols = [{
            'name': 'num',
            'type': 'link',
            'label': 'Location #',
            'id': 'num'
        }, {
            'name': 'name',
            'type': 'text',
            'label': 'Name',
            'id': 'name'
        }, {
            'name': 'city',
            'type': 'text',
            'label': 'City',
            'id': 'city'
        }, {
            'name': 'state',
            'type': 'text',
            'label': 'State',
            'id': 'state'
        }];
        if (cmp.get('v.showSchedule')) {
            cols.push({
                'name': 'schedule',
                'type': 'text',
                'label': 'Schedule Date',
                'id': 'schedule'
            });
        }
        cols.push({
            'name': 'status',
            'type': 'text',
            'label': 'Status',
            'id': 'status',
        });

        cmp.find('locationGrid').set('v.columns', cols);
    },

    _initLocations: function(cmp) {
        this.doRemoteRequest(
            cmp,
            this.AppSettings.Routes.SearchKeyword, {
                'projectId': cmp.get('v.projectId'),
                'keyword': ''
            }
        );

    },

    _initFilter: function(cmp) {
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.GetSettings, {
                'projectId': cmp.get('v.projectId')
            }
        );
    },

    toggleLocationList: function(cmp, evt) {
        var self = this,
            locCmp,
            locations,
            values,
            showCard = !this._isCardVisible(cmp);
        this._showSpinner(cmp, 1);

        if (showCard) {
            locCmp = cmp.find('locationGrid');
            locations = locCmp.get('v.data');
            locCmp.assignSelectedValue();
            values = locCmp.get('v.value');

            if (values.length > 0) {
                locations.forEach(function(loc) {
                    if (values.some(function(s) {
                            return s.id === loc.id;
                        })) {
                        loc.selected = true;
                    } else {
                        loc.selected = false;
                    }
                });
            } else {
                locations.forEach(function(loc) {
                    loc.selected = false;
                });
            }
        } else {
            locations = cmp.find('locationCard').get('v.data');
        }

        cmp.set('v.showCard', showCard);
        this._asyncCall(cmp, function() {
            if (showCard) {
                cmp.find('locationCard').set('v.data', locations);
                self._showSpinner(cmp, 0);
            } else {
                self._initDataGrid(cmp);
                cmp.find('locationGrid').set('v.data', locations);
            }
            cmp.set('v.pageCount', locations.length);
        });
    },

    _isCardVisible: function(cmp) {
        return $A.util.getBooleanValue(cmp.get('v.showCard'));
    },

    clearFilter: function(cmp, evt) {
        var locCmp = this._getLocationComponent(cmp);
        locCmp.set('v.data', []);
        cmp.set('v.pageCount', 0);
        this._setSelectAll(cmp, false);
        window.scrollTo(0, 0);
    },

    onDataGridRendered: function(cmp, evt) {
        this._showSpinner(cmp, 0);
    },

    handleSelectAll: function(cmp) {
        var showCard = $A.util.getBooleanValue(cmp.get('v.showCard')),
            selectAll = cmp.find('chkSelectAll').get('v.checked'),
            child = (showCard) ? cmp.find('locationCard') : cmp.find('locationGrid'),
            locations = child.get('v.data');

        locations.forEach(function(e) {
            e.selected = selectAll;
        });
        child.set('v.data', locations);
    },

    handleCheckOneLocationEvent: function(cmp, evt) {
        if (this._isSelectAllChecked(cmp)) {
            this._setSelectAll(cmp, false);
        }
    },

    _setSelectAll: function(cmp, value) {
        cmp.find('chkSelectAll').set('v.checked', value);
    },

    handleScheduleLocations: function(cmp, evt) {
        var child = this._getLocationComponent(cmp);
        var locations = child.get('v.data')
            .filter(function(e) {
                return e.selected === true;
            });

        if (locations.length === 0) {
            this._notify(cmp, 'The locations need to be selected when scheduling the locations', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        this._renderDialog(cmp, this.DIALOG_DEFINITIONS.SCHEDULE_LOCATIONS, {
            'projectId': cmp.get('v.projectId'),
            'locations': locations,
            'searchByOneHubId': this._isSearchByOneHubId(cmp),
            'startDate': cmp.get('v.startDate'),
            'endDate': cmp.get('v.endDate')
        });
    },

    handleScheduleLocationsInBulk: function(cmp, evt) {

        this._renderDialog(cmp, this.DIALOG_DEFINITIONS.SCHEDULE_LOCATIONS_INBULK, {
            'projectId': cmp.get('v.projectId'),
            'startDate': cmp.get('v.startDate'),
            'endDate': cmp.get('v.endDate')
        });
    },

    handleMessageBoxEvent: function(cmp, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'removeLocations' && result.value === 1) {
            this._removeSelectedLocations(cmp);
            return;
        }

        if (result.id === 'reAttempt' && result.value === 1) {
            this._reattemptSelectedLocations(cmp);
            return;
        }

        if (result.id === 'removeAll' && result.value === 1) {
            this._removeAllLocations(cmp);
            return;
        }
        if (result.id === 'removeOneLocation') {
            if (0 === result.value) {
                if (this._isCardVisible(cmp)) {
                    this._getLocationComponent(cmp).unSelectCurrentCard(cmp.get('v.locationIdToRemove'));
                }
                cmp.set('v.locationIdToRemove', '');
            } else {
                this._removeOneLocation(cmp);
            }
        }
        if (result.id === 'createJobsBatch' || result.id === 'removeLocationsBatch') {
            window.location.reload();
        }
    },

    _removeOneLocation: function(cmp) {
        var locations = [cmp.get('v.locationIdToRemove')];

        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.RemoveOneLocation, {
                'projectId': cmp.get('v.projectId'),
                'locations': locations
            }
        );
    },

    _removeSelectedLocations: function(cmp) {
        var locations = this._getSelLocations(cmp);
        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.RemoveLocations, {
                'projectId': cmp.get('v.projectId'),
                'locations': locations
            }
        );
    },

    _reattemptSelectedLocations: function(cmp) {
        var locations = this._getSelLocations(cmp, function(loc) {
            return loc.status != 'Canceled';
        });
        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.ReattemptLocations, {
                'action': 'reattemptLocations',
                'projectId': cmp.get('v.projectId'),
                'locations': locations
            }
        );
    },

    _removeAllLocations: function(cmp) {
        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.RemoveAllLocations, {
                'projectId': cmp.get('v.projectId'),
                'action': 'removeAll'
            }
        );
    },

    _getSelLocations: function(cmp, predicate) {
        var locCmp = this._getLocationComponent(cmp);
        var locations = !!predicate ? locCmp.get('v.data').filter(predicate) : locCmp.get('v.data');
        if (this._isSelectAllChecked(cmp)) {
            return locations.map(function(l) {
                return l.id;
            });
        }
        if (this._isCardVisible(cmp)) {
            return locations.filter(function(l) {
                    return l.selected === true;
                })
                .map(function(l) {
                    return l.id;
                });
        }
        locCmp.assignSelectedValue();
        locations = !!predicate ? locCmp.get('v.value').filter(predicate) : locCmp.get('v.value');
        return locations.map(function(l) {
            return l.id;
        });
    },

    handleRemoveSelected: function(cmp) {
        var hasLocations,
            locCmp = this._getLocationComponent(cmp);

        if (this._isSelectAllChecked(cmp)) {
            if (this._isCardVisible(cmp)) {
                hasLocations = locCmp.get('v.data').length > 0;
            } else {
                locCmp.assignSelectedValue();
                hasLocations = locCmp.get('v.value').length > 0;
            }
        } else {
            if (this._isCardVisible(cmp)) {
                hasLocations = locCmp.get('v.data')
                    .some(function(l) {
                        return l.selected === true;
                    });
            } else {
                locCmp.assignSelectedValue();
                hasLocations = locCmp.get('v.value').length > 0;
            }
        }
        if (!hasLocations) {
            this._notify(cmp, 'There are no locations selected to remove.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }

        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'removeLocations',
            title: 'Remove Selected Locations',
            body: '<p>Are you sure that you want to remove the selected locations from the project?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });

    },

    handleRemoveAll: function(cmp, evt) {
        var totalCount = parseInt(cmp.get("v.rowCount"));
        if (!totalCount || totalCount < 1) {
            this._notify(cmp, 'There are no locations to remove.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'removeAll',
            title: 'Remove All Locations',
            body: '<p>Are you sure that you want to remove all the locations from the project?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },

    handleReAttempt: function(cmp, evt) {

        var locations = this._getSelLocations(cmp, function(loc) {
         
              return loc.status != 'Canceled';
          
        });
        if (locations.length === 0) {
            this._notify(cmp, 'There are no valid locations selected to reattempt.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'reAttempt',
            title: 'Reattempt Selected Locations',
            body: '<p>Are you sure that you want to reattempt selected locations?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },

    handleCancelLocationEvent: function(cmp, evt) {
        var locations = this._getSelLocations(cmp, function(loc) {
            return loc.status !== 'Canceled';
        });
        if (locations.length === 0) {
            this._notify(cmp, 'There are no active project locations to cancel.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var val = evt.getParam('context');

        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.CancelLocations, {
                'action': 'cancelLocations',
                'projectId': cmp.get('v.projectId'),
                'locations': locations,
                'reason': val.reason || '',
                'comment': val.comment || ''
            }
        );
    },

    handleCancelSelected: function(cmp, evt) {
        var hasLocations,
            locCmp = this._getLocationComponent(cmp),
            predicate = function(loc) {
                return loc.status !== 'Canceled';
            };

        if (this._isSelectAllChecked(cmp)) {
            hasLocations = locCmp.get('v.data').filter(predicate).length > 0;
        } else {
            if (this._isCardVisible(cmp)) {
                hasLocations = locCmp.get('v.data').filter(predicate)
                    .some(function(l) {
                        return l.selected === true;
                    });
            } else {
                locCmp.assignSelectedValue();
                hasLocations = locCmp.get('v.value').filter(predicate).length > 0;
            }

        }
        if (!hasLocations) {
            this._notify(cmp, 'There are no active locations selected to cancel.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }

        this._renderDialog(cmp, this.DIALOG_DEFINITIONS.CANCEL_LOCATIONS, {
            'reasons': cmp.get('v.cancelReasons')
        });
    },

    _getLocationComponent: function(cmp) {
        return (this._isCardVisible(cmp)) ? cmp.find('locationCard') : cmp.find('locationGrid');
    },

    handleRefreshJobs: function(cmp, evt) {
        this._showSpinner(cmp, 1);
        this.doRemoteRequest(cmp,
            this.AppSettings.Routes.SearchKeyword, {
                'projectId': cmp.get('v.projectId'),
                'keyword': ''
            }
        );
    },

    handleCreateJobs: function(cmp, evt) {
        var message, rowCount = cmp.get('v.rowCount') || 0;
        if (rowCount < 1) {
            this._notify(cmp, 'Please add locations to the project before creating jobs.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        this._showSpinner(cmp, 1);
        this.doRemoteRequest(
            cmp,
            this.AppSettings.Routes.CreateJobs, {
                'projectId': cmp.get('v.projectId')
            }
        );
    },

    _isSelectAllChecked: function(cmp) {
        var chkAll = cmp.find('chkSelectAll');
        return $A.util.getBooleanValue(chkAll.get('v.checked'));
    },

    _showSpinner: function(cmp, shown) {
        var spinner = cmp.find('busyIndicator');
        if (!!shown) {
            spinner.show();
        } else {
            spinner.hide();
        }
    },

    _asyncCall: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 200;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },

    _notify: function(cmp, msg, msgType) {
        var e = cmp.find('notification');
        var isSuccess = msgType === 'success' ? true : false;
        e.set('v.hideCloseButton', isSuccess);
        e.show(msg, msgType, isSuccess);
    },

    gotoProjectLocationDetail: function(cmp, evt) {
        var param = evt.getParam('context'),
            r = param.record || {};
        if (!r.id) {
            return;
        }

        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": r.id
        });
        navEvt.fire();
    },


    handleShowSpinnerEvent: function(cmp, evt) {
        var context = evt.getParam('context') || {};
        this._showSpinner(cmp, !!context.show ? 1 : 0);
    },

    onClickAddLocationsButton: function(cmp, evt) {
        this._renderDialog(cmp, this.DIALOG_DEFINITIONS.SELECT_OPTIONS);
    },

    selectAddLocationOption: function(cmp, evt) {
        var option = evt.getParam('id');
        var showSchedule = $A.util.getBooleanValue(cmp.get('v.showSchedule'));
        var searchByOneHubId = this._isSearchByOneHubId(cmp);
        var hasAccount = $A.util.getBooleanValue(cmp.get('v.hasAccount'));

        switch (option) {
            case this.ADDLOCATIONS_OPTIONS.UPLOAD_FILE:
                this._renderDialog(cmp, this.DIALOG_DEFINITIONS.UPLOAD_FILE, {
                    'showSchedule': showSchedule,
                    'searchByOneHubId': searchByOneHubId,
                    'guidSelectorDisabled': !hasAccount
                });
                break;
            case this.ADDLOCATIONS_OPTIONS.PASTE_LIST:
                this._renderDialog(cmp, this.DIALOG_DEFINITIONS.PASTE_LIST, {
                    'showSchedule': showSchedule,
                    'searchByOneHubId': searchByOneHubId,
                    'guidSelectorDisabled': !hasAccount
                });
                break;
            case this.ADDLOCATIONS_OPTIONS.SEARCH_LOCATIONS:
                this._renderDialog(cmp, this.DIALOG_DEFINITIONS.SEARCH_LOCATIONS, {
                    'searchByOneHubId': searchByOneHubId,
                    'guidSelectorDisabled': !hasAccount
                });
                break;
            default:
                break;
        }
    },

    _renderDialog: function(root, dialogDefinition, params) {
        var dlg = root.find('modalDialog'),
            self = this,
            args = (!!params) ? this._cloneObject(params) : {};
        args['dialogId'] = dialogDefinition.id;
        args['projectId'] = root.get('v.projectId');
        args['parentId'] = root.get('v.projectId');
        Object.keys(dialogDefinition)
        .forEach(function(k){
            args[k] = dialogDefinition[k];
        });

        $A.createComponent(dialogDefinition.component, args,
            function(cmp, status, errMsg) {
                if ('SUCCESS' === status) {
                    dlg.set('v.title', dialogDefinition.title);
                    dlg.set('v.size', dialogDefinition.size);
                    dlg.set('v.brand', dialogDefinition.brand || '');
                    dlg.set('v.body', cmp);
                    dlg.show();
                } else if ('ERROR' === status) {
                    self._notify(root, errMsg, self.NOTIFICATION_TYPES.ERROR);
                }
            });
    },

    doRemoteRequest: function(cmp, route, parameters) {
        var gateway = cmp.find('projectLocationGateway'),
            eventId = gateway.get('v.id');
        gateway.onRemoteRequest(eventId, route, parameters);
    },

    /* app event handler */
    onSuccessAppEvent: function(cmp, evt) {
        var skipSpinnerLogic = 0,
            subscribers = cmp.get('v.subscribers') || [],
            route = evt.getParam('route');

        try {
            switch (route) {
                case this.AppSettings.Routes.SearchKeyword:
                case this.AppSettings.Routes.FilterProjectLocations:
                    this._renderLocations(cmp, evt);
                    break;
                case this.AppSettings.Routes.AddProjectLocations:
                case this.AppSettings.Routes.AddProjectLocationsByPasteList:
                case this.AppSettings.Routes.AddProjectLocationsByUploadFile:
                    this._renderAddLocations(cmp);
                    break;
                case this.AppSettings.Routes.ScheduleLocations:
                    this._renderScheduleLocations(cmp, evt);
                    break;
                case this.AppSettings.Routes.CancelLocations:
                    this._renderCancelLocations(cmp, evt);
                    skipSpinnerLogic = 1;
                    break;
                case this.AppSettings.Routes.ReattemptLocations:
                    this._handleReattemptSuccess(cmp, evt);
                    break;
                case this.AppSettings.Routes.CreateJobs:
                    this._handleCreateJobsSuccess(cmp, evt);
                    break;
                case this.AppSettings.Routes.RemoveLocations:
                case this.AppSettings.Routes.RemoveAllLocations:
                    this._renderRemoveLocations(cmp, evt);
                    skipSpinnerLogic = 1;
                    break;
                case this.AppSettings.Routes.GetSettings:
                    this._renderUISettings(cmp, evt);
                    break;
            }

        } catch (ex) {
            console.log(ex);
        }!skipSpinnerLogic && this._showSpinner(cmp, 0);
        subscribers.forEach(function(sub) {
            if (sub.route === route) {
                sub.callback(cmp);
            }
        });
        cmp.set('v.subscribers', subscribers.filter(function(sub) {
            return sub.route !== route;
        }));
    },

    _handleCreateJobsSuccess: function(cmp, evt) {
        var response = evt.getParam('value');
        var actionId = response.data === 'isBatchJob' ? 'createJobsBatch' : 'createJobs';
        this._msgboxForResponse(cmp, {
            'message': response.message || 'The jobs are created successfully.',
            'severity': response.state || this.NOTIFICATION_TYPES.SUCCESS,
            'id': actionId,
            'title': 'Create Jobs'
        });

        cmp.set('v.canCreateJob', false);
    },

    _handleReattemptSuccess: function(cmp, evt) {
        var response = evt.getParam('value');
        var actionId = 'reattempt';
        this._msgboxForResponse(cmp, {
            'message': response.message || 'Reattempts for the selected locations have been scheduled successfully.',
            'severity': response.state || this.NOTIFICATION_TYPES.SUCCESS,
            'id': actionId,
            'title': 'Create Reattempts'
        });
        cmp.find('locationFilter').dispatchLocationFilterAction();
    },

    endImportJobs: function(cmp, evt) {
        this._asyncCall(cmp, function(cmp) {
            window.location.reload();
        }, 1000);         
    },

    convertArrayOfObjectsToCSV: function(cmp, response) {
        var csvStringResult, counter, keys, columnDivider, lineDivider, Header;
        if (response == null || !response.length) {
            return null;
        }
        var row, rec, field;
        var columnDivider = ',';
        var keys = ['Service', 'ServiceTitle', 'Location', 'State', 'City', 'LocationNumber', 'Banner', 'JobName', 'NumberOfWorkers', 'JobStartDate', 'JobStartTime', 'PurchaseAmount'];
        var Header = ['Project Service', 'Service Title', 'Project Location',
            'State', 'City', 'Location Number', 'Banner', 'Job', 'Number Of Workers',
            'Job Start Date', 'Job Start Time', 'Purchase Amount'
        ];
        csvStringResult = [];
        csvStringResult.push('"' + Header.join('","') + '"');
        for (var i = 0; i < response.length; i++) {
            rec = response[i];
            row = keys.map(function(k) {
                field = rec[k] + '';
                return ['"', field.indexOf('"') !== -1 ? field.replace('"', '\"') : field, '"'].join('');
            });
            csvStringResult.push(row.join(columnDivider));
        }

        return csvStringResult;
    },

    _msgboxForResponse: function(cmp, option) {
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: option.id,
            title: option.title,
            body: ['<p>', option.message, '</p>'].join(''),
            positiveLabel: 'Ok',
            negativeLabel: 'No',
            hideNegative: true,
            severity: option.severity
        });
    },

    _renderRemoveLocations: function(cmp, evt) {
        var actionId, self = this,
            response = evt.getParam('value');
        if (response.data === 'isBatchJob') {
            this._showSpinner(cmp, 0);
            actionId = 'removeLocationsBatch';
            self._msgboxForResponse(cmp, {
                'id': 'removeLocationsBatch',
                'title': 'Remove Jobs',
                'message': response.message || 'The reponse message is not identified.',
                'severity': response.state || this.NOTIFICATION_TYPES.SUCCESS
            });
            return;
        }

        this._subscribe(cmp, this.AppSettings.Routes.FilterProjectLocations, function(cmp) {
            self._notify(cmp, response.message || 'The selected locations are removed successfully.', self.NOTIFICATION_TYPES.SUCCESS);
        });
        cmp.find('locationFilter').dispatchLocationFilterAction();
    },

    _renderAddLocations: function(cmp) {
        var self = this;

        function callback() {
            self._initLocations(cmp);
            cmp.set('v.canCreateJob', true);
        }
        this._asyncCall(cmp, callback, 1000);
    },

    _renderLocations: function(cmp, evt) {
        var value = evt.getParam('value') || {},
            child = this._getLocationComponent(cmp);
        this._setSelectAll(cmp, false);
        var data = value.data || [];
        cmp.set('v.pageCount', data.length);
        cmp.set('v.rowCount', value.rowCount || 0);
        child.set('v.data', this._mapLocations(data));
    },

    _renderUISettings: function(cmp, evt) {
        var value = evt.getParam('value'),
            project = value.project

        cmp.set('v.cancelReasons', value.cancelReasons || []);        
        cmp.set('v.startDate', this._parseDate(project.startDate));
        cmp.set('v.endDate', this._parseDate(project.endDate));
        cmp.set('v.hasAccount', project.hasAccount ===1);
        cmp.set('v.canSchedule', project.canSchedule === 1);
        cmp.set('v.showSchedule', project.showSchedule === 1);
        cmp.set('v.canCreateJob', project.batchJob === 0 ? true : false);
        cmp.set('v.canAddLocation', project.canAddLocation === 1);
        cmp.set('v.searchByOneHubId', project.searchByOneHubId === 1);
        cmp.set('v.locationReportUrl', project.locationReportUrl);
        cmp.set('v.locked', project.locked === 1);
        cmp.set('v.ProjNumberOfDays',project.NumberOfDays);
    },

    _renderScheduleLocations: function(cmp, evt) {
        var self = this;
        this._setSelectAll(cmp, false);
        this._asyncCall(cmp, function(cmp) {
            cmp.find('locationFilter').dispatchLocationFilterAction();
            self._showSpinner(cmp, 0);
        }, 10);
    },

    _renderCancelLocations: function(cmp, evt) {
        var self = this,
            response = evt.getParam('value');
        this._subscribe(cmp, this.AppSettings.Routes.FilterProjectLocations, function(cmp) {
            self._notify(cmp, response.message || 'The selected locations are cancelled successfully.', response.state);
        });
        cmp.find('locationFilter').dispatchLocationFilterAction();
    },


    onErrorAppEvent: function(cmp, evt) {
        if (this._isInterestedErrorAppEvent(evt)) {
            this._showSpinner(cmp, 0);
            var id = evt.getParam('id');
            var error = evt.getParam('error');
            var route = evt.getParam('route');
            switch (route) {
                case this.AppSettings.Routes.CreateJobs:
                    this._msgboxForResponse(cmp, {
                        'id': 'createJobs',
                        'title': 'Create Jobs',
                        'message': error,
                        'severity': this.NOTIFICATION_TYPES.ERROR,
                    });
                    break;
                case this.AppSettings.Routes.RemoveLocations:
                    if (id === 'removeOneLocation') {
                        if (this._isCardVisible(cmp)) {
                            this._getLocationComponent(cmp).unSelectCurrentCard(cmp.get('v.locationIdToRemove'));
                        }
                        cmp.set('v.locationIdToRemove', '');
                    }
                default:
                    this._notify(cmp, error, this.NOTIFICATION_TYPES.ERROR);
            }
        }
    },

    _isInterestedErrorAppEvent: function(evt) {
        var route = evt.getParam('route'),
            routes = [
                this.AppSettings.Routes.SearchKeyword,
                this.AppSettings.Routes.FilterProjectLocations,
                this.AppSettings.Routes.CreateJobs,
                this.AppSettings.Routes.RemoveLocations,
                this.AppSettings.Routes.CancelLocations,
                this.AppSettings.Routes.GetSettings,
            ];
        return routes.indexOf(route) !== -1;
    },

    _mapLocations: function(locations) {
        var p, self = this;
        return locations.map(function(e) {
            p = self._cloneObject(e);
            p['selected'] = false;
            p['__class'] = self._calculateStatusStyle(p['status']);
            p['schedule'] = self._transformDate(p['schedule']);
            return p;
        });
    },

    _calculateStatusStyle: function(status) {
        var style = '';
        switch (status) {
            case 'Job Created':
                style = 'slds-theme--success';
                break;
            case 'Canceled':
                style = 'slds-theme--warning';
                break;
            case 'Failed':
                style = 'slds-theme--error';
                break;
        }
        return style;
    },

    _parseDate: function(dt) {
        var arr = (dt || '').split('-');
        if (arr.length === 3) {
            return new Date(arr[0], arr[1] - 1, arr[2]);
        }
        return dt;
    },

    _transformDate: function(dt) {
        var arr = (dt || '').split('-');
        if (arr.length === 3) {
            return [arr[1], arr[2], arr[0]].join('/');
        }
        return dt;
    },

    _cloneObject: function(obj) {
        var t = {};
        for (var nm in obj) {
            t[nm] = obj[nm];
        }
        return t;
    },

    _isSearchByOneHubId: function(cmp) {
        return $A.util.getBooleanValue(cmp.get('v.searchByOneHubId'));
    },
    
    showToast: function(title, msg, type) {
        var evt = $A.get('e.force:showToast');
        evt.setParams({
            title: title,
            message: msg,
            type: type,
            mode: type === 'error' ? 'sticky' : 'dismissible'
        });
        evt.fire();
    },

    _subscribe: function(cmp, route, callback) {
        var subscribers = cmp.get('v.subscribers') || [];
        subscribers.push({
            'route': route,
            'callback': callback
        });
        cmp.set('v.subscribers', subscribers);
    }
})