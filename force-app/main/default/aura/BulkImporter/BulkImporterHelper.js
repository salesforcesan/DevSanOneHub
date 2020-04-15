({
    AppSettings: {
        'CloseDialogEvent': 'closeDialogEvent',
        'SupportedFileTypes': [
            '.csv', '.txt'
        ],
        'Actions': {
            'Rollback': 'rollbackImportData',
            'GetChunkSize': 'getChunkSize',
            'GetSettings': 'getImportSettings',
            'UploadStart': 'uploadStart',
            'ImportData': 'importData',
            'UploadFinish': 'uploadEnd'
        }
    },
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },
    
    init: function(cmp) {
        this.dispatch(cmp, {
            'action': this.AppSettings.Actions.GetSettings,
            'data': {
                'query': JSON.stringify(this._newQuery(cmp, [],0,0))
            },
            'onSuccess': function(cmp, response) {
                cmp.set('v.chunkSize', response.chunkSize);
                cmp.set('v.titles', response.importColumnTitles);
            }
        });
    },
    
    _newQuery: function(cmp, data, startImport, endImport) {
        return {
            'ParentId': cmp.get("v.parentId"),
            'Data': data || [],
            'StartImport': startImport || 0,
            'EndImport': endImport || 0,
            'ServiceName': cmp.get('v.importRequestService'),
            'AttachmentName': cmp.get('v.attachmentName'),
            'JobName': cmp.get('v.jobName')
        };
    },
    
    _getChunkSize: function(cmp) {
        var size = cmp.get('v.chunkSize');
        return !!size ? parseInt(size) : 5000;
    },
    
    _getInputFile: function(cmp) {
        return cmp.find('inputFile').getElement();
    },
    
    _resetInputFile: function(cmp) {
        var inputFile = cmp.find('inputFile').getElement();
        inputFile.value = '';
    },
    
    selectFile: function(cmp, evt) {
        this._getInputFile(cmp).click();
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
        this._initData(cmp, evt, file);
    },
    
    _initData: function(cmp, evt, file) {
        var data, cols, self = this,
            reader = new FileReader();
        
        function fileLoadHandler(cmp, evt) {
            try {
                data = self._parseCSVFile(self, reader.result);
                self._importData(self, cmp, data);
            } catch (err) {
                self._notify(cmp, err.message, self.NOTIFICATION_TYPES.ERROR);
                self._hideSpinner(cmp);
                self._resetInputFile(cmp);
            }
        }
        
        function readFile(cmp) {
            var self = this;
            reader.onload = function() {
                fileLoadHandler(cmp);
            }
            reader.onerror = function() {
                self._hideSpinner(cmp);
                self._notify(cmp, reader.error, self.NOTIFICATION_TYPES.ERROR);
            };
            reader.readAsText(file);
        }
        
        self._showSpinner(cmp);
        self._asyncCall(cmp, readFile, 10);
    },
    
    _importData: function(self, cmp, data) {
        var onRequest = cmp.getEvent('importDataRequest');
        onRequest.setParams({
            'context': data
        });
        onRequest.fire();
    },
    
    _parseCSVFile: function(self, content) {
        var data = (content || '').split(/\n|\r|\r\n/g);
        if (!data || data.length === 0) {
            throw new Error('There are no data in the file for importing data.');
        }
        
        var pattern = new RegExp('"', 'g');
        
        return data.filter(function(e) {
            return (e || '').length > 0 && e.split(',').length > 1;
        }).map(function(row) {
            return row.split(',')
            .map(function(c) {
                return !!c && c.indexOf('"') !== -1 ? c.replace(pattern, '') : c;
            }).join(',');
        });
    },
    
    _showSpinner: function(cmp) {
        cmp.find('busyIndicator').show();
    },
    
    _hideSpinner: function(cmp) {
        cmp.find('busyIndicator').hide();
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
    
    closeDialog: function(cmp) {
        var event = cmp.getEvent(this.AppSettings.CloseDialogEvent);
        event.fire();
    },
    
    _fireEndImportDataEvent: function(cmp) {
        var endImport = cmp.getEvent('endImportData');
        endImport.setParams({
            'context': cmp.get('v.importRequestService')
        });
        endImport.fire();
    },
    
    _handleImportSuccess: function(cmp, response) {
        var self = this;
        var channel = self._nextChannel(cmp);
        cmp.set('v.channelOpened', true);
        
        if (!channel.data) {
            self._hideSpinner(cmp);
            self._notify(cmp, 'The data import request has been queued for processing successfully.', 'success');
            self._fireEndImportDataEvent(cmp);
            return;
        }
        
        self.dispatch(cmp, {
            'action': self.AppSettings.Actions.ImportData,
            'data': {
                'query': JSON.stringify(
                    self._newQuery(cmp, channel.data, 0, channel.endOfChunk))
            },
            'onSuccess': self._handleImportSuccess,
            'onError': self._handleImportError
        });
        
    },
    
    _handleImportError: function(cmp, error) {
        var self = this;
        self._hideSpinner(cmp);
        self._resetInputFile(cmp);
        
        if (cmp.get('v.channelOpened') == true) {
            self.dispatch(cmp, {
                'action': self.AppSettings.Actions.Rollback,
                'data': {
                    'query': JSON.stringify(
                        self._newQuery(cmp, [], 0,0)
                    )
                },
                'onSuccess': function(cmp, reponse, action) {}
            });
        }
        
        self._notify(cmp, error, 'error');
    },
    
    _checkHeader: function(cmp, columns) {
        var titles = (cmp.get('v.titles') || '').split(','),
            cols = (columns || '').split(',');
        if (cols.length !== titles.length) {
            return 0;
        }
        for (var i = 0; i++; i < cols.lenth) {
            if (titles[i].toLowerCase() !== cols[i].toLowerCase()) {
                return 0;
            }
        }
        
        return 1;
    },
    
    //entry point to handle import job button event
    onImportRequest: function(cmp, evt) {
        var channel, cursor, data = evt.getParam('context') || [];
        if (!this._checkHeader(cmp, data.shift())) {
            this._hideSpinner(cmp);
            this._notify(cmp, 'The import file is invalid.', 'error');
            return;
        }
        
        this._resetChannel(cmp);
        this._chunkData(cmp, data);
        channel = this._nextChannel(cmp);
        if (!channel.data) { return; }
        
        this.dispatch(cmp, {
            'action': this.AppSettings.Actions.ImportData,
            'data': {
                'query': JSON.stringify(
                    this._newQuery(cmp, channel.data, 1, channel.endOfChunk)
                )
            },
            'onSuccess': this._handleImportSuccess,
            'onError': this._handleImportError
        });
    },
    
    _chunkData: function(cmp, data) {
        var i,
            cursor,
            chunkSize = this._getChunkSize(cmp),
            channels = [],
            blocks = Math.ceil(data.length / chunkSize);
        
        for (i = 0; i < blocks; i++) {
            cursor = i * chunkSize;
            channels.push(data.slice(cursor, cursor + chunkSize));
        }
        cmp.set('v.channels', channels);
    },
    
    _nextChannel: function(cmp) {
        var channels = cmp.get('v.channels') || [],
            chunk = channels.shift();
        cmp.set('v.channels', channels);
        return {
            data: chunk,
            endOfChunk: channels.length === 0 ? 1 : 0
        };
    },
    
    _resetChannel: function(cmp) {
        cmp.set('v.channels', []);
        cmp.set('v.channelOpened', false);
    },
    
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type, autoHide, duration);
    }
})