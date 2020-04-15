({
    AppSettings: {
        'CloseDialogEvent': 'closeDialogEvent',
        'SupportedFileTypes': [
            '.csv', '.txt'
        ],
        'Actions': {
            'Rollback': 'rollbackImportJobs',
            'GetChunkSize': 'getChunkSize',
            'GetSettings': 'getJobImportSettings',
            'UploadStart': 'uploadStart',
            'ImportJobs': 'importJobs',
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
            'onSuccess': function(self, cmp, response) {
                cmp.set('v.chunkSize', response.chunkSize);
                cmp.set('v.titles', response.importColumnTitles);
            }
        });
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
        this._initJobs(cmp, evt, file);
    },

    _initJobs: function(cmp, evt, file) {
        var jobs, cols, self = this,
            reader = new FileReader();

        function checkHeader(hdr) {
            if (hdr.length !== 12) {
                throw new Error('The job import file should have 12 required columns.');
            }
        }

        function fileLoadHandler(cmp, evt) {
            try {
                jobs = self._parseCSVFile(self, reader.result);
                self._importJobs(self, cmp, jobs);
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

    _importJobs: function(self, cmp, jobs) {
        var onRequest = cmp.getEvent('importJobRequest');
        onRequest.setParams({
            'context': jobs
        });
        onRequest.fire();
    },

    _parseCSVFile: function(self, content) {
        var jobs = (content || '').split(/\n|\r|\r\n/g);
        if (!jobs || jobs.length === 0) {
            throw new Error('There are no jobs in the file for importing jobs.');
        }

        var pattern = new RegExp('"', 'g');

        return jobs.filter(function(e) {
            return (e || '').length > 0 && e.split(',').length > 4;
        }).map(function(job) {
            return job.split(',')
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

    _fireEndImportJobEvent: function(cmp) {
        var endImport = cmp.getEvent('endImportJob');
        endImport.fire();
    },

    _handleImportJobSuccess: function(self, cmp, response) {
        var channel = self._nextChannel(cmp);
        cmp.set('v.channelOpened', true);

        if (!channel.data) {
            self._hideSpinner(cmp);
            self._notify(cmp, 'The job import request has been queued for processing successfully.', 'success');
            
            var id = window.setTimeout(
                $A.getCallback(function() {
                    window.clearTimeout(id);
                    self._fireEndImportJobEvent(cmp);
                }), 2000
            );            
            return;
        }

        self.dispatch(cmp, {
            'action': self.AppSettings.Actions.ImportJobs,
            'data': {
                'request': JSON.stringify({
                    'ProjectId': cmp.get("v.projectId"),
                    'Jobs': channel.data,
                    'StartImport': 0,
                    'EndImport': channel.endOfChunk
                })
            },
            'onSuccess': self._handleImportJobSuccess,
            'onError': self._handleImportJobError
        });

    },

    _handleImportJobError: function(self, cmp, error) {
        self._hideSpinner(cmp);
        self._resetInputFile(cmp);

        if (cmp.get('v.channelOpened') == true) {
            self.dispatch(cmp, {
                'action': self.AppSettings.Actions.Rollback,
                'data': {
                    'projectId': cmp.set('v.projectId')
                },
                'onSuccess': function(self, cmp, action, reponse) {}
            });
        }

        self._notify(cmp, error, 'error');
    },

    _checkHeader: function(cmp, columns) {
        var titles = (cmp.get('v.titles') || '').split(','),
        cols = (columns || '').split(',');
        if(cols.length !== titles.length){
            return 0;
        }
        for(var i = 0; i++; i < cols.lenth){
            if (titles[i].toLowerCase() !== cols[i].toLowerCase()){
                return 0;
            }
        }

        return 1;
    },

    //entry point to handle import job button event
    onImportJobRequest: function(cmp, evt) {
        var channel, cursor, jobs = evt.getParam('context') || [];
        if(!this._checkHeader(cmp, jobs.shift())){
            this._hideSpinner(cmp);
            this._notify(cmp, 'The job import file is invalid.','error');
            return;
        }

        this._resetChannel(cmp);
        this._chunkJobs(cmp, jobs);
        channel = this._nextChannel(cmp);
        if (!channel.data) { return; }

        this.dispatch(cmp, {
            'action': this.AppSettings.Actions.ImportJobs,
            'data': {
                'request': JSON.stringify({
                    'ProjectId': cmp.get("v.projectId"),
                    'Jobs': channel.data,
                    'StartImport': 1,
                    'EndImport': channel.endOfChunk
                })
            },
            'onSuccess': this._handleImportJobSuccess,
            'onError': this._handleImportJobError
        });
    },

    _chunkJobs: function(cmp, jobs) {
        var i,
            cursor,
            chunkSize = this._getChunkSize(cmp),
            channels = [],
            blocks = Math.ceil(jobs.length / chunkSize);

        for (i = 0; i < blocks; i++) {
            cursor = i * chunkSize;
            channels.push(jobs.slice(cursor, cursor + chunkSize));
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