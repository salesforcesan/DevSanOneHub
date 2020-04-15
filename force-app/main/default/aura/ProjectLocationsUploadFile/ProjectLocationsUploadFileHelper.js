// @flow
({
    AppSettings: {
        'Events': {
            'ActionRequestAppEvent': 'e.c:ActionRequestAppEvent',
            'CloseDialogEvent': 'closeDialogEvent',
            'FileLoaded': 'uploadFileLoadedEventHandler'
        },
        'Routes': {
            'AddLocations': 'ProjectLocations/add/uploadFile',
            'FindLocations': 'Locations/search/uploadFile'
        },
        'SupportedFileTypes': [
            '.csv', '.txt'
        ]
    },
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },

    onInit: function(cmp) {
        var cols = [{
            'name': 'id',
            'type': 'text',
            'id': 'uid',
            'label': 'Unique Id',
            'width': '300px'
        }];
        if ($A.util.getBooleanValue(cmp.get('v.showSchedule'))) {
            cols.push({
                'name': 'schedule',
                'type': 'text',
                'id': 'schedule',
                'label': 'Schedule Date'
            });
        }
        cols = cols.concat([{
            'name': 'num',
            'type': 'text',
            'id': 'num',
            'label': 'Location #'
        }, {
            'name': 'desc',
            'type': 'text',
            'id': 'desc',
            'label': 'Location'
        }, {
            'name': 'status',
            'type': 'text',
            'id': 'status',
            'label': 'Status',
            'width': '100px'
        }]);
        cmp.set('v.columns', cols);
        cmp.set('v.useGuid', this._isSearchByOneHubId(cmp) ? '1' : '0');
    },

    add: function(cmp) {
        var message, data, selItems, locations, status,
            projectId = cmp.get('v.projectId'),
            showSchedule = $A.util.getBooleanValue(cmp.get('v.showSchedule')),
            table = cmp.find('dataTable');

        if (!table) {
            this._notify(cmp, 'Please click "Upload File" button to select a file.',
                this.NOTIFICATION_TYPES.ERROR);
            return;
        }

        table.assignSelectedValue();
        locations = table.get('v.value').filter(function(loc) {
            status = loc.status.toLowerCase();
            return status.indexOf('valid') !== -1 && status.indexOf('invalid') === -1;
        });

        if (locations.length === 0) {
            this._notify(cmp, 'Please select valid locations to upload.', this.NOTIFICATION_TYPES.ERROR);
            return;
        }
        if (!projectId) {
            this._notify(cmp, 'The project id is required when adding locations.');
            return;
        }

        data = showSchedule ? locations.map(function(e) {
            return {
                'uid': e.uid,
                'schedule': e.schedule
            };
        }) : locations.map(function(e) {
            return {
                'uid': e.uid
            }
        });

        var guidSelector = cmp.find("guidSelector");
        var useGuid = guidSelector.get("v.value");

        message = {
            'route': this.AppSettings.Routes.AddLocations,
            'parameters': {
                'projectId': projectId,
                'useGuid': useGuid,
                'locations': data
            }
        };
        this._showSpinner(cmp);
        this._dispatch(cmp, message);
    },

    selectFile: function(cmp, evt) {
        var inputFile = cmp.find('inputFile').getElement();
        //console.log('inputFile++++' + inputFile);
        cmp.set('v.locationChanged', false);
        inputFile.click();
    },

    onChangeFile: function(cmp, evt) {
        
        var fileName, file = evt.currentTarget.files[0],
            arr = [];
        if (!file) {
            return;
        }
        fileName = file.name;
        if (!this.AppSettings.SupportedFileTypes.some(function(tp) {
                return (fileName || '').toLowerCase().indexOf(tp) !== -1;
            })) {
            this._notify(cmp, 'The upload file type is invalid. The CSV and Text files are supported. The file extension must be either .csv or .txt', 'error');
            return;
        }
        arr.push(file.name);
        arr.push(file.type);
        arr.push(Math.ceil(file.size / 1024) + 'KB');
        cmp.set('v.selFile', arr.join(' - '));
        this._initLocations(cmp, file);
    },

    _initLocations: function(cmp, file) {
        var locations, cols, self = this,
            showSchedule = $A.util.getBooleanValue(cmp.get('v.showSchedule')),
            reader = new FileReader();

        function fileLoadHandler(cmp) {
            var me = self,
                locations = (reader.result || '').split(/\n|\r|\r\n/g);

            locations = locations.filter(function(e) {
                return (e || '').length > 0;
            }).map(function(loc) {
                cols = loc.split(',');
                if (showSchedule && cols.length > 1) {
                    return {
                        'uid': cols[0],
                        'schedule': cols[1],
                        'id': '',
                        'num': '',
                        'selected': false,
                        'desc': '',
                        'status': self._genStatusHtml('info', 'processing')
                    };
                }
                return {
                    'uid': cols[0],
                    'id': '',
                    'num': '',
                    'selected': false,
                    'desc': '',
                    'status': self._genStatusHtml('info', 'processing')
                }
            });

            cmp.set('v.locations', locations);
            cmp.set('v.locationChanged', true);
        }

        function readFile(cmp) {
            reader.onload = function() {
                fileLoadHandler(cmp);
            }
            reader.onerror = function() {
                self._hideSpinner(cmp);
                self._notify(cmp, reader.error, self.NOTIFICATION_TYPES.ERROR);
            };
            reader.readAsText(file);
        }

        this._showSpinner(cmp);
        this._asyncCall(cmp, readFile, 500);
    },

    _genStatusHtml: function(msgType, status) {
        return ['<span class="slds-badge slds-theme--', msgType, ' oh-badge">', status, '</span>'].join('');
    },

    handleLocationChanged: function(cmp, evt) {
        if ($A.util.getBooleanValue(cmp.get('v.locationChanged'))) {
            this._setData(cmp, cmp.get('v.locations'));
            this._checkLocations(cmp);
        }
    },

    _checkLocations: function(cmp) {

        var guidSelector = cmp.find("guidSelector");
        var useGuid = guidSelector.get("v.value");

        var message = {
            'route': this.AppSettings.Routes.FindLocations,
            'parameters': {
                'projectId': cmp.get('v.projectId'),
                'useGuid': useGuid,
                'locations': cmp.get('v.locations').map(function(e) {
                    return e.uid;
                })
            }
        };

        this._dispatch(cmp, message);
    },

    closeDialog: function(cmp) {
        var event = cmp.getEvent(this.AppSettings.Events.CloseDialogEvent);
        event.fire();
    },

    onSuccess: function(cmp, evt) {
        var route = evt.getParam('route');
        switch (route) {
            case this.AppSettings.Routes.FindLocations:
                this._handleSearchResult(cmp, evt);
                break;
            case this.AppSettings.Routes.AddLocations:
                this._handleAddLocations(cmp, evt);
                break;
        }
    },

    _getPredicate: function(cmp) {
        return (this._isSearchByOneHubId(cmp)) ? function(uid, result) {
            return uid === result.uid.toUpperCase();
        } : function(num, result) {
            return num === result.num;
        };
    },

    _handleAddLocations: function(cmp, evt) {
        var locations = this._getData(cmp),
            response = evt.getParam('value'),
            self = this,
            uid,
            items,
            color,
            result = response.data || [];
        var predicate = this._getPredicate(cmp);

        locations.forEach(function(loc) {
            uid = loc.uid.toUpperCase();
            items = result.filter(function(r) {
                return predicate(uid, r);
            });
            if (items.length > 0) {
                switch (items[0].status) {
                    case 'added':
                        color = 'success';
                        break;
                    case 'invalid':
                        color = 'error';
                        break;
                    case 'duplicated':
                        color = 'warning';
                        break;
                    default:
                        color = 'info';
                        break;
                }
                loc.status = self._genStatusHtml(color, items[0].status);
            }
        });

        this._setData(cmp, locations);
        this._hideSpinner(cmp);
        this._notify(cmp, response.message, response.state);
    },

    _isInterestedEvent: function(evt) {
        return [
            this.AppSettings.Routes.FindLocations,
            this.AppSettings.Routes.AddLocations
        ].indexOf(evt.getParam('route')) !== -1;
    },

    _handleSearchResult: function(cmp, evt) {
        var items, uid, value = evt.getParam('value') || {},
            self = this,
            locations = this._getData(cmp),
            results = value['locations'] || [],
            exclusions = value['exclusions'] || [];
        var predicate = this._getPredicate(cmp);

        function gStatus(id) {
            return exclusions.some(function(s) {
                return predicate(id, s);
            }) ? self._genStatusHtml('warning', 'Duplicated') : self._genStatusHtml('success', 'Valid');
        }


        locations.forEach(function(e) {
            uid = e.uid.toUpperCase();
            items = results.filter(function(r) {
                return predicate(uid, r);
            });
            if (items.length > 0) {
                e.id = items[0].id;
                e.num = items[0].num;
                e.desc = items[0].desc;
                e.status = gStatus(uid);
            } else {
                items = exclusions.filter(function(r) {
                    return predicate(uid, r);
                })
                if (items.length > 0) {
                    e.id = items[0].id,
                        e.desc = items[0].desc;
                    e.status = self._genStatusHtml('warning', 'duplicate');
                } else {
                    e.desc = 'Id is invalid.';
                    e.status = self._genStatusHtml('error', 'Invalid');
                }
            }
        });

        this._setData(cmp, locations);
        cmp.set('v.locationChanged', false);
        this._hideSpinner(cmp);
    },

    onError: function(cmp, evt) {
        var error;
        if (this._isInterestedEvent(evt)) {
            error = evt.getParam('error') || 'An unknown error happended.';
            this._notify(cmp, error, this.NOTIFICATION_TYPES.ERROR);
            this._hideSpinner(cmp);
        }
    },

    _dispatch: function(cmp, payload) {
        var action = cmp.getEvent('onRemoteRequest');
        action.setParams(payload);
        action.fire();
    },

    _showSpinner: function(cmp) {
        cmp.find('busyIndicator').show();
    },

    _hideSpinner: function(cmp) {
        cmp.find('busyIndicator').hide();
    },

    _getData: function(cmp) {
        return cmp.find('dataTable').get('v.data');
    },

    _setData: function(cmp, data) {
        cmp.find('dataTable') && cmp.find('dataTable').set('v.data', data);
    },


    _notify: function(cmp, msg, type) {
        cmp.find('notification').show(msg, type);
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

    _isSearchByOneHubId: function(cmp) {
        return $A.util.getBooleanValue(cmp.get('v.searchByOneHubId'));
    }
})