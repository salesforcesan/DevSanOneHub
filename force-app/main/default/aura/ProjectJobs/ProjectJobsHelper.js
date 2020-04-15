({
    UISettings: {
        'DELETE': 'Job__c.Delete',
        'CANCEL': 'Job__c.Cancel',
        'BUNDLECANCEL': 'Job__c.BundledCancel',
        'REATTEMPT': 'Job__c.Reattempt',
        'BUNDLEREATTEMPT': 'Job__c.BundledReattempt'
    },
    MESSAGES: {
        'BATCH': 'Successfully submitted the request to delete the Jobs'
    },
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },
    DIALOG_DEFINITIONS: {
        'IMPORT_JOBS': {
            'id': 'dlgBulkScheduleJobs',
            'component': 'c:BulkImporter',
            'size': 'medium',
            'title': 'Bulk Import Jobs',
            'pageInstruction': 'Import a file by clicking on the Import button , please note that the supported date formats are YYYY-MM-dd and MM/dd/YYYY.',
            'importRequestService': "JobImportRequestService",
            'attachmentName': "%import_jobs%",
            'jobName': "Import Jobs"
        },
    },
    AppSettings: {
        'Events': {
            'RemoteActionRequest': 'e.c:ActionRequestAppEvent'
        },
        'Methods': {
            'JobSearchKeyword': {
                'id': 'searchProjectJobsByKeyword',
                'name': 'searchProjectJobsByKeyword'
            },
            'LoadFilterDropDowns': {
                'id': 'populateJobFilterDropDowns',
                'name': 'populateJobFilterDropDowns'
            },
            'FilterProjectJobs': {
                'id': 'filterJobs',
                'name': 'filterJobs'
            },
            'DeleteJob': {
                'id': 'deleteJobs',
                'name': 'deleteJobs'
            },
            'DeleteOneJob': {
                'id': 'removeOneJob',
                'name': 'deleteJobs'
            },
            'RemoveAllJobs': {
                'id': 'deleteAllJobsByProject',
                'name': 'deleteAllJobsByProject'
            },
        }
    },

    _dispatch: function(cmp, id, action, parameters) {
        var proxy = cmp.find('projectJobActionProxy');
        proxy.onRemoteRequest(id, action, parameters);
    },

    afterRender: function(cmp) {
        this._showSpinner(cmp, 1);

    },

    reloadJobs: function(cmp, msg) {
        //this._subscribe(cmp, self.AppSettings.Methods.FilterProjectJobs.id, function(cmp) {
        //this._notify(cmp, msg, self.NOTIFICATION_TYPES.SUCCESS);
        //});    
        this._showSpinner(cmp, 1);
        cmp.find('manageJobFilter').dispatchJobFilterAction();
        this._notify(cmp, msg, this.NOTIFICATION_TYPES.SUCCESS);
        this._showSpinner(cmp, 0);
    },

    init: function(cmp, evt) {
        //cmp.set("v.recordId",cmp.get('v.project.Id'));    
        //cmp.set("v.securityelements","ProjectJobs__c.Cancel,ProjectJobs__c.ReAttempt");              
        //this._initJobs(cmp);
        //this._initFilter(cmp); 
        //this.afterRender();
        this._initJobs(cmp);
        this._initFilter(cmp);
        this._initSecurity(cmp);
    },
    _initSecurity: function(cmp) {
        cmp.set("v.securityelements", "Job__c.BundledCancel,Job__c.Delete,Job__c.Cancel,Job__c.Reattempt,Job__c.BundledReattempt,Job__c.ImportJob");
    },

    _initJobs: function(cmp) {
        var id = this._getProjectId(cmp);
        if (!id) {
            return;
        }
        this._dispatch(
            cmp,
            this.AppSettings.Methods.JobSearchKeyword.id,
            this.AppSettings.Methods.JobSearchKeyword.name, {
                'query': {
                    'projectId': id,

                }
            }
        );
    },

    _getProjectId: function(cmp) {
        var project = cmp.get('v.project');
        return !!project && !!project.Id ? project.Id : 0;
    },

    _initFilter: function(cmp) {
        var id = this._getProjectId(cmp);
        if (!id) {
            return;
        }
        this._dispatch(
            cmp,
            this.AppSettings.Methods.LoadFilterDropDowns.id,
            this.AppSettings.Methods.LoadFilterDropDowns.name, {
                'query': {
                    'projectId': id
                }
            }
        );
    },

    _isCardVisible: function(cmp) {

        return $A.util.getBooleanValue(cmp.get('v.showCard'));
    },

    handleCheckOneJobEvent: function(cmp, evt) {
        if (this._isSelectAllChecked(cmp)) {
            cmp.find('chkSelectAll').set('v.checked', false);
        }
    },

    handleRemoveAll: function(cmp, evt) {
        var totalCount = cmp.get("v.rowCount");
        if (totalCount < 1) {
            this._notify(cmp, 'There are no Jobs to remove.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'removeAll',
            title: 'Remove All Jobs',
            body: '<p>Are you sure that you want to remove all the jobs from the project?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },
    handleSelectAll: function(cmp) {

        var showCard = $A.util.getBooleanValue(cmp.get('v.showCard')),
            selectAll = cmp.find('chkSelectAll').get('v.checked'),
            jobs = cmp.get('v.jobs');

        jobs.forEach(function(e) {
            e.selected = selectAll;
        });
        cmp.set('v.jobs', jobs);
    },


    _getJobComponent: function(cmp) {
        return (this._isCardVisible(cmp)) ? cmp.find('jobCard') : null;
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

    _notify: function(cmp, msg, msgType) {
        var e = cmp.find('notification');
        e.set('v.message', msg);
        e.set('v.type', msgType);
        e.set('v.visible', true);
    },

    handleShowSpinnerEvent: function(cmp, evt) {
        var context = evt.getParam('context') || {};
        this._showSpinner(cmp, !!context.show ? 1 : 0);
    },

    onAppSuccess: function(cmp, evt) {
        console.log('evt' + evt);
        var skipSpinnerLogic = 0;
        var subscribers = cmp.get('v.subscribers') || [];
        var route = evt.getParam('id');

        try {
            switch (route) {
                case this.AppSettings.Methods.JobSearchKeyword.id:
                case this.AppSettings.Methods.FilterProjectJobs.id:
                    this._renderJobs(cmp, evt);
                    break;

                case this.AppSettings.Methods.DeleteJob.id:
                    //case this.AppSettings.Methods.DeleteOneJob.id:
                    this._renderRemoveJobs(cmp, evt);
                    skipSpinnerLogic = 1;
                    break;
                case this.AppSettings.Methods.LoadFilterDropDowns.id:
                    this._renderFilter(cmp, evt);
                    break;
                case this.AppSettings.Methods.RemoveAllJobs.id:
                    this._renderDeleteAllJobs(cmp, evt);
                    skipSpinnerLogic = 1;
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

    _renderJobs: function(cmp, evt) {

        var value = evt.getParam('value') || [];
        this._setSelectAll(cmp, false);
        cmp.set('v.pageCount', value.data.length);
        cmp.set('v.rowCount', value.rowCount);
        cmp.set('v.jobs', this._mapJobs(value.data));

    },
    _setSelectAll: function(cmp, value) {
        cmp.find('chkSelectAll').set('v.checked', value);
    },

    _subscribe: function(cmp, route, callback) {
        var subscribers = cmp.get('v.subscribers') || [];
        subscribers.push({
            'route': route,
            'callback': callback
        });
        cmp.set('v.subscribers', subscribers);
    },
    _renderFilter: function(cmp, evt) {
        var filter = cmp.find('manageJobFilter'),
            value = evt.getParam('value');
        filter.set('v.services', value.services || []);
        filter.set('v.exeCompanies', value.executionCompany || []);
        filter.set('v.jobStatues', value.jobStatus || []);
        filter.set('v.jobCompleted', value.completed || []);
        filter.set('v.exceptionReasons', value.exceptionReasons || []);
        cmp.set('v.namespace', value.namespace || '');
        cmp.set('v.exportJobReportUrl', value.exportJobReportUrl || '#');

    },

    _renderDeleteAllJobs: function(cmp, evt) {
        var self = this;
        //response = evt.getParam('value');
        var response = evt.getParam('value');
        var json = JSON.parse(response);
        var message = json["Message"];
        var state = json["State"];
        console.log(state);

        if (message == this.MESSAGES.BATCH) {
            this._notify(cmp, message || 'All jobs  removed successfully.', this.NOTIFICATION_TYPES.SUCCESS);
            window.location.reload();
        } else {

            this._subscribe(cmp, self.AppSettings.Methods.FilterProjectJobs.id, function(cmp) {
                self._notify(cmp, message || 'All Jobs are removed successfully.', self.NOTIFICATION_TYPES.SUCCESS);
            });
            cmp.find('manageJobFilter').dispatchJobFilterAction();


        }


    },

    _renderRemoveJobs: function(cmp, evt) {
        var self = this;
        var response = evt.getParam('value');
        var json = JSON.parse(response);
        var message = json["Message"];
        var state = json["State"];
        this._subscribe(cmp, self.AppSettings.Methods.FilterProjectJobs.id, function(cmp) {
            self._notify(cmp, message || 'The selected Jobs are removed successfully.', self.NOTIFICATION_TYPES.SUCCESS);
        });
        cmp.find('manageJobFilter').dispatchJobFilterAction();
        // var state = event.getParam("state");
        /* var jobCmp = this._getJobComponent(cmp);
         var jobs = jobCmp.get('v.jobs').filter(function(job) {
           return job.selected !== true;
         }).map(function(job) {
           return self._cloneObject(job);
         });
         // console.log('jobs length'+ jobs.length);
         cmp.find('chkSelectAll').set('v.checked', false);
         cmp.set('v.rowCount', jobs.length);
         jobCmp.set('v.jobs', jobs); */



        //this._notify(cmp, message || 'selected jobs  removed successfully.', this.NOTIFICATION_TYPES.SUCCESS);
    },

    onAppError: function(cmp, evt) {
        self = this;
        var errorMessage = evt.getParam('error');
        var route = evt.getParam('id');
        this._showSpinner(cmp, 0);
        if (this._isInterestedErrorAppEvent(evt)) {
            switch (route) {
                case this.AppSettings.Methods.DeleteJob.id:
                case this.AppSettings.Methods.JobSearchKeyword.id:
                case this.AppSettings.Methods.LoadFilterDropDowns.id:
                case this.AppSettings.Methods.FilterProjectJobs.id:
                case this.AppSettings.Methods.RemoveAllJobs.id:
                    this._notify(cmp, errorMessage, this.NOTIFICATION_TYPES.ERROR);
                    break;

            }
        }
    },

    _isInterestedErrorAppEvent: function(evt) {
        var route = evt.getParam('id'),
            routes = [
                this.AppSettings.Methods.JobSearchKeyword.id,
                this.AppSettings.Methods.LoadFilterDropDowns.id,
                this.AppSettings.Methods.FilterProjectJobs.id,
                this.AppSettings.Methods.DeleteJob.id,
                this.AppSettings.Methods.RemoveAllJobs.id

            ];
        return routes.indexOf(route) !== -1;
    },


    showToast: function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    _mapJobs: function(jobs) {
        var p, self = this;
        return jobs.map(function(e) {
            p = self._cloneObject(e);
            p['selected'] = false;
            return p;
        });
    },

    _cloneObject: function(o) {
        var ret = {};
        for (var nm in o) {
            ret[nm] = o[nm];
        }
        return ret;
    },

    deletedConfirmJobs: function(cmp) {
        var jobs = this._getJobs(cmp);
        var project = cmp.get('v.project');
        var projectId = project.Id;
        this._showSpinner(cmp, 1);
        this._dispatch(
            cmp,
            this.AppSettings.Methods.DeleteJob.id,
            this.AppSettings.Methods.DeleteJob.name, {
                'query': {
                    'projectId': projectId,
                    'jobs': jobs
                }
            }
        );
    },

    handleMessageBoxEvent: function(cmp, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        console.log('result Id' + result.id);
        //console.log('result value'+result.value);
        if (result.id === 'deleteJobs' && result.value === 1) {
            this.deletedConfirmJobs(cmp);
            return;

        }
        if (result.id === 'removeAll' && result.value === 1) {
            this._removeAllJobs(cmp);
            return;
        }

        if (result.id === 'removeOneJob') {
            if (0 === result.value) {
                if (this._isCardVisible(cmp)) {
                    this._getJobComponent(cmp).unSelectCurrentCard(cmp.get('v.jobIdToRemove'));
                }
                cmp.set('v.jobIdToRemove', '');
            } else {
                this._removeOneJob(cmp);
            }
        }
    },
    _removeAllJobs: function(cmp) {
        var project = cmp.get('v.project');
        var projectId = project.Id;
        this._showSpinner(cmp, 1);
        this._dispatch(
            cmp,
            this.AppSettings.Methods.RemoveAllJobs.id,
            this.AppSettings.Methods.RemoveAllJobs.name, {
                'query': {
                    'projectId': projectId
                }
            }
        );
    },

    _removeOneJob: function(cmp) {
        var jobs = [cmp.get('v.jobIdToRemove')];
        var project = cmp.get('v.project');
        var projectId = project.Id;
        this._showSpinner(cmp, 1);
        this._dispatch(
            cmp,
            this.AppSettings.Methods.DeleteOneJob.id,
            this.AppSettings.Methods.DeleteOneJob.name, {
                'query': {
                    'projectId': projectId,
                    'jobs': jobs
                }
            }
        );
    },

    handleDeleteSelected: function(cmp) {
        var jobs = this._getJobs(cmp);
        if (jobs.length === 0) {
            this._notify(cmp, 'There are no Jobs selected to remove.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'deleteJobs',
            title: 'Remove Selected Jobs',
            body: '<p>Are you sure that you want to remove the selected Jobs from the project?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },

    _getJobs: function(cmp) {
        var message, jobs, jobCmp;
        jobCmp = this._getJobComponent(cmp);
        if (this._isSelectAllChecked(cmp)) {
            jobs = cmp.get('v.jobs').map(function(j) {
                return j.Id;
            });
        } else {
            jobs = cmp.get('v.jobs')
                .filter(function(j) {
                    return j.selected === true;
                })
                .map(function(j) {
                    return j.Id;
                });
        }

        return jobs;

    },
    handleDeleteOneJob: function(cmp, evt) {
        var jobId = evt.getParam('context');
        if (evt.getParam('id') !== 'removeOneJobEvent' || !jobId) {
            return;
        }
        cmp.set('v.jobIdToRemove', jobId);
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'removeOneJob',
            title: 'Remove Current Job',
            body: '<p>Are you sure that you want to remove the current Job from the project?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },

    handleRemoveSelected: function(cmp) {
        var message, jobs;

        if (this._isSelectAllChecked(cmp)) {
            jobs = cmp.get('v.jobs').map(function(l) {
                return l.Id;
            });
        } else {
            jobs = cmp.get('v.jobs')
                .filter(function(l) {
                    return l.selected === true;
                })
                .map(function(l) {
                    return l.Id;
                });
        }
        if (jobs.length === 0) {
            this._notify(cmp, 'There are no jobs selected to Cancel.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        var userevent = $A.get("e.c:EventDisplayModal");
        userevent.setParams({
            "modalComponentName": "c:JobCancel",
            "modalProperties": {
                "title": "Cancel Jobs",
                "height": "400px",
                "width": "600px",
                "offsetFromHeader": "false"
            },
            "modalComponentProperties": {
                "jobIds": jobs
            }
        });
        userevent.fire();


    },
    handleReAttemptSelected: function(cmp, evt) {

        console.log('get source');
        var reattemptId = evt.target.id;

        var canReAttempt, message, jobs;
        var project = cmp.get('v.project');
        var renderedJobs = cmp.get('v.jobs');

        if (this._isSelectAllChecked(cmp)) {
            canReAttempt = renderedJobs.filter(l => (l.NumberOfWorkers > 0 || !l.IsSingleRep)).map(l => l.Id);
            jobs = renderedJobs.filter(l => l.NumberOfWorkers === 1 && l.IsSingleRep).map(l => l.Id);
        } else {
            canReAttempt = renderedJobs.filter(l => (l.selected && l.NumberOfWorkers > 0 && !l.IsSingleRep)).map(l => l.Id);
            jobs = renderedJobs.filter(l => (l.selected && l.NumberOfWorkers === 1 && l.IsSingleRep)).map(l => l.Id);
        }

        if (canReAttempt.length > 0) {
            this._notify(cmp, 'Only Single Day and Single Rep projects can be reattempted', this.NOTIFICATION_TYPES.WARNING);
            return;
        }

        if (jobs.length === 0) {
            this._notify(cmp, 'There are no jobs selected to reattempt.', this.NOTIFICATION_TYPES.WARNING);
            return;
        }
        //v.project.IsReAttemptDateRequired
        if (project.IsReAttemptDateRequired) {
            this._openModalforAttempts(jobs, project);
            //console.log(jobs);
        } else {
            console.log('reattemptWithOutCalendar');
            this._createAttempts(cmp, jobs);
        }

    },

    _isSelectAllChecked: function(cmp) {
        var chkAll = cmp.find('chkSelectAll');
        return $A.util.getBooleanValue(chkAll.get('v.checked'));
    },

    _asyncCall: function(cmp, callback) {
        if (!callback) {
            return;
        }
        var id = window.setTimeout($A.getCallback(function() {
            if (cmp.isValid()) {
                callback();
            }
        }), 500);
    },
    _openModalforAttempts: function(jobs, project) {
        var userevent = $A.get("e.c:EventDisplayModal");
        userevent.setParams({
            "modalProperties": {
                "title": "ReAttempt Jobs",
                "height": "400px",
                "width": "600px",
                "offsetFromHeader": "false"
            },
            "modalComponentName": "c:ProjectJobsReAttempt",
            "modalComponentProperties": {
                "selectedJobIds": jobs,
                "project": project
            }
        });
        userevent.fire();
    },
    _createAttempts: function(cmp, jobs) {

        var action = cmp.get("c.CreateJobAttempts");
        action.setParams({
            jobIdList: JSON.stringify(jobs),
            scheduledDate: null
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state=' + state);
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(response.getReturnValue());
                console.log(responseWrapper);
                if (responseWrapper.State === "ERROR") {
                    this._notify(cmp, responseWrapper.Message, this.NOTIFICATION_TYPES.ERROR);
                } else {
                    this._notify(cmp, responseWrapper.Message, this.NOTIFICATION_TYPES.SUCCESS);
                }
            } else if (state === "INCOMPLETE") {
                this._notify(cmp, "Unknown Exception Occurred", this.NOTIFICATION_TYPES.ERROR);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log('errors=' + errors[0]);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this._notify(cmp, errors[0].message, this.NOTIFICATION_TYPES.ERROR);
                    }
                } else {
                    this._notify(cmp, "Unhandled Exception occurred:\r\nContact Administrator", this.NOTIFICATION_TYPES.ERROR);
                }
            }
        });
        $A.enqueueAction(action);
    },
    importJobs: function(cmp, evt) {
        var project = cmp.get('v.project');
        this._renderDialog(cmp, this.DIALOG_DEFINITIONS.IMPORT_JOBS, {
            'projectId': project.Id
        });
    },

    endImportJobs: function(cmp, evt){
        this._asyncCall(cmp, function(cmp){
            window.location.reload();
        }, 1000);
    },

    _renderDialog: function(root, dialogDefinition, params) {
        var dlg = root.find('modalDialog'),
            self = this,
            project = root.get('v.project'),
            args = (!!params) ? this._cloneObject(params) : {};
        args['dialogId'] = dialogDefinition.id;
        args['projectId'] = project.Id;
        args['parentId'] = project.Id;
        Object.keys(dialogDefinition)
            .forEach(function(k) {
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
})