({
    USAGES: {
        ProjectBuilder: 'Project Builder',
        Retailer: 'Retailer',
        CommunityViewer: 'Community Viewer',
        InternalUser: 'Internal User'
    },

    HttpRequest: {
        'ProjectService': 'ProjectServiceRequest',
        'Target': 'TargetRequest',
        'Question': 'ProjectServiceQuestionRequest',
        'methods': {
            'FILTER': 'filter'
        }
    },

    init: function(cmp) {
        this._initFilter(cmp);
    },

    _initFilter: function(cmp) {
        cmp.set('v.filter', this._getDefaultFilter());
        this.appStateChanged(cmp, null);
    },

    _getDefaultFilter: function() {
        return {
            accountId: '',
            projectId: '',
            projectNumber: '',
            serviceId: '',
            questionId: '',
            locationId: '',
            programId: '',
            targetId: '',
            startDate: '',
            endDate: '',
            state: '',
            city: '',
            favorite: 0,
            userFavorite: 0,
            duplicated: 0,
            unclassified: null
        };
    },

    cityChanged: function(cmp, evt) {
        function onCityChange(cmp) {
            var filter = this._getFilter(cmp);
            filter.city = cmp.get('v.city');
            this._setFilterWithoutChangeEvent(cmp, filter);
            this._filterChangeHandler(cmp);
        }
        if (!cmp.get('v.skipCityChanged')) {
            this._debounce(cmp, onCityChange, 250);
        }
    },

    filterChanged: function(cmp, evt) {
        if (!cmp.get('v.loaded')) {
            cmp.set('v.loaded', true);
            return;
        }

        this._debounce(cmp, this._filterChangeHandler, 250);
    },

    _filterChangeHandler: function(cmp) {
        var appState = this._getAppState(cmp);
        switch (appState.usage) {
            case this.USAGES.ProjectBuilder:
                this._filterChangedForProjectBuilder(cmp);
                break;
            case this.USAGES.InternalUser:
                this._filterChangedForInternalUser(cmp);
                break;
            default:
                this._filterChangedForCommunity(cmp);
        }
    },

    afterRender: function(cmp, evt) {
        if (!!cmp.get('v.lookupReady')) {
            return;
        }
        cmp.set('v.lookupReady', true);
        var appState = this._getAppState(cmp);
        switch (appState.usage) {
            case this.USAGES.ProjectBuilder:
                this._filterChangedForProjectBuilder(cmp);
                break;
            case this.USAGES.InternalUser:
                this._initProgramLookup(cmp, appState.namespace, '');
                this._initLocationLookup(cmp, {
                    accountId: '',
                    projectId: '',
                    usage: appState.usage,
                    namespace: appState.namespace
                });
                break;
            default:
                this._initProgramLookup(cmp, appState.namespace, '');
                this._initLocationLookup(cmp, {
                    accountId: appState.accountId,
                    projectId: '',
                    usage: appState.usage,
                    namespace: appState.namespace
                });
        }
    },

    _filterChangedForProjectBuilder: function(cmp) {
        var filter = this._getFilter(cmp);

        filter.projectId = cmp.get('v.currentProjectId');
        this._fireFilterChange(cmp, filter);
    },

    _filterChangedForCommunity: function(cmp) {
        var currentProjectId = cmp.get('v.currentProjectId'),
            filter = this._getFilter(cmp);

        if (currentProjectId !== filter.projectId) {
            this._projectIdChanged(cmp, filter.projectId);
            filter.serviceId = '';
            filter.targetId = '';
            filter.questionId = '';
            filter.unclassified = null;
        }

        this._fireFilterChange(cmp, filter);
    },

    _filterChangedForInternalUser: function(cmp) {
        var currentProjectId = cmp.get('v.currentProjectId'),
            currentAccountId = cmp.get('v.currentAccountId'),
            filter = this._getFilter(cmp);

        if (filter.accountId !== currentAccountId) {
            this._accountIdChanged(cmp, filter);
            this._fireFilterChange(cmp, filter);
            return;
        }

        //todo: need to handle id, num and currentdi condition
        var who = this._checkWhichProjectLookMutated(currentProjectId, filter.projectId, filter.projectNumber);
        switch (who) {
            case 'pId':
                filter.projectNumber = '';
                this._handleProjectLookupImpact(cmp, filter, filter.projectId);
                this._projectIdChanged(cmp, filter.projectId);
                break;
            case 'pNum':
                filter.projectId = '';
                this._handleProjectLookupImpact(cmp, filter, filter.projectNumber);
                this._projectIdChanged(cmp, filter.projectNumber);
                break;
            case 'curId':
                filter.projectId = '';
                filter.projectNumber = '';
                this._handleProjectLookupImpact(cmp, filter, '');
                this._projectIdChanged(cmp, '');
                break;
        }
        this._fireFilterChange(cmp, filter);
    },

    _checkWhichProjectLookMutated: function(curId, pId, pNum) {
        if (!!pId && !!pNum) {
            if (pId !== curId) {
                return 'pId';
            }
            if (pNum !== curId) {
                return 'pNum';
            }
        } else {
            if (!!pId) {
                return pId !== curId ? 'pId' : '';
            }
            if (!!pNum) {
                return pNum !== curId ? 'pNum' : '';
            }
        }

        if (!!curId) {
            return 'curId';
        }
        return '';
    },

    _handleProjectLookupImpact: function(cmp, filter, projectIdValue) {
        filter.serviceId = '';
        filter.targetId = '';
        filter.questionId = '';
        filter.unclassified = null;
        this._setFilterWithoutChangeEvent(cmp, filter);
    },

    _accountIdChanged: function(cmp, filter) {
        cmp.set('v.currentAccountId', filter.accountId);
        filter.projectId = '';
        filter.projectNumber = '';
        filter.serviceId = '';
        filter.targetId = '';
        filter.questionId = '';
        filter.locationId = '';
        filter.chainId = '';
        filter.programId = '';
        filter.state = '';
        filter.city = '';
        filter.unclassified = null;
        this._setFilterWithoutChangeEvent(cmp, filter);
        this._projectIdChanged(cmp, '');
        this._resetCityWithoutChangeEvent(cmp);
    },

    _resetCityWithoutChangeEvent: function(cmp) {
        cmp.set('v.skipCityChanged', true);
        cmp.set('v.city', '');
        this._async(cmp, function(cmp) {
            cmp.set('v.skipCityChanged', false);
        });
    },

    _setFilterWithoutChangeEvent: function(cmp, filter) {
        cmp.set('v.loaded', false);
        cmp.set('v.filter', filter);
        this._async(cmp, function(cmp) {
            cmp.set('v.loaded', true);
        }, 10);
    },

    _projectIdChanged: function(cmp, newProjectId) {
        cmp.set('v.currentProjectId', newProjectId || '');
        this._resetProjectBasedLookups(cmp);
    },

    _fireFilterChange: function(cmp, filter) {
        var msg = cmp.getEvent('onFilterChanged'),
            source = cmp.get('v.filterChangeSource'),
            context = {};

        this._handleFilterSideEffectOnSearchButton(cmp, filter);

        if (source !== 'search') {

            if (this._isSearchDisabled(cmp)) {
                this._fireClearFilterEvent(cmp);
            }
            return;
        }

        cmp.set('v.filterChangeSource', '');

        Object.keys(filter).forEach(function(key) {
            context[key] = filter[key];
        });

        if (!!filter.projectNumber) {
            context['projectId'] = filter.projectNumber;
        }

        msg.setParams({ context: context });
        msg.fire();
    },

    _isSearchDisabled: function(cmp) {
        return cmp.get('v.btnSearchDisabled');
    },

    _handleFilterSideEffectOnSearchButton: function(cmp, filter) {
        var keys = Object.keys(filter),
            appState = this._getAppState(cmp);
        var isProjectBuilder = appState.usage === this.USAGES.ProjectBuilder;
        var disabled = true;

        function checkToSkipProjectId(field) {
            return isProjectBuilder && field === 'projectId';
        }

        for (var i = 0; i < keys.length; i++) {
            if (!!filter[keys[i]]) {
                if (checkToSkipProjectId(keys[i])) { continue; }
                disabled = false;
                break;
            }
        }
        cmp.set('v.btnSearchDisabled', disabled);
    },

    checkboxChanged: function(cmp, evt) {
        this.filterChanged(cmp, evt);
    },

    showUserFavoritePhotos: function(cmp, evt){
        this._async(cmp, this._showUserFavoritePhotosHandler, 0);
    },

    _showUserFavoritePhotosHandler: function(cmp){
        var filter = cmp.get('v.filter');
        filter.userFavorite = !!cmp.find('chkUserFavorite').get('v.checked') ?
            1 :
            0;
        cmp.set('v.filter', filter);
    },

    showFavoritePhotos: function(cmp, evt) {
        this._async(cmp, this._showFavoritePhotosHandler, 0);
    },

    _showFavoritePhotosHandler: function(cmp) {
        var filter = cmp.get('v.filter');
        filter.favorite = !!cmp.find('chkFavorite').get('v.checked') ?
            1 :
            0;
        cmp.set('v.filter', filter);
    },
    
    showUnmatchedPhotos: function(cmp, evt) {
        this._async(cmp, this._showUnmatchedPhotosHandler, 0);
    },
     _showUnmatchedPhotosHandler: function(cmp){
        var filter = cmp.get('v.filter');
        filter.unclassified = !!cmp.find('unclassified').get('v.checked') ?
            1 :
            0;
        cmp.set('v.filter', filter);
         console.log('filters', cmp.get('v.filter').unclassified);
    },

    showDuplicatedPhotos: function(cmp, evt) {

        function handler(cmp) {
            var filter = cmp.get('v.filter');
            filter.duplicated = !!cmp.find('chkDuplicated').get('v.checked') ?
                1 :
                0;
            cmp.set('v.filter', filter);
        }
        this._async(cmp, handler, 0);
    },

    dropdownChanged: function(cmp, evt) {
        var context = evt.getParam('context');
        if (context.id == 'serviceId') {
            this._serviceIdChanged(cmp, evt);
        }
    },
    
    dropdownQuestion: function(cmp, evt) {
  		var val = component.find('questionSelect').get('v.value');
        if(!val || $A.util.isEmpty(val)){ return; }
        console.log('val: ', val);

    },
    
    _serviceIdChanged: function(cmp, evt) {
        var filter = cmp.get('v.filter');
        if (!filter.serviceId) {
            cmp.set('v.questions', []);
            cmp.set('v.targets', []);
            filter.questionId = '';
            filter.targetId = '';
            cmp.set('v.filter', filter);
        } else {
            this._initQuestions(cmp, filter.serviceId);
            this._initTargets(cmp, filter.serviceId);
        }
    },

    _initTargets: function(cmp, serviceId) {
        this.getDispatcher(cmp)
        .className(this.HttpRequest.Target)
        .action(this.HttpRequest.methods.FILTER)
        .body({ serviceId: serviceId })
        .onSuccess(this._targetResponseHandler)
        .run();
    },

    _targetResponseHandler: function(cmp, response) {
        var targets = (response || []).map(function(e) {
            return { key: e[0], value: e[1] };
        });
        cmp.set('v.targets', targets);
    },

    _initQuestions: function(cmp, serviceId) {
        this.getDispatcher(cmp)
        .className(this.HttpRequest.Question)
        .action(this.HttpRequest.methods.FILTER)
        .body({ serviceId: serviceId })
        .onSuccess(this._questionResponseHandler)
        .run();
    },

    _questionResponseHandler: function(cmp, response) {
        var obj = {
            'key': '',
            'value': '',
            'ai': ''
        };
        var questions = (response || []).map(function(e) {
            obj.key = e[0];
            obj.value = e[1];
            e.length > 2 ? obj.ai = e[2] : obj.ai = null;
            return obj;
        });
        cmp.set('v.questions', questions);

    },

    appStateChanged: function(cmp, evt) {
        var appState = cmp.get('v.appState') || {},
            namespace = appState.namespace;

        if (namespace === '_' || appState['action'] === 'showmore' || appState['action'] === 'filter') {
            return;
        }

        var projectId = appState.projectId,
            chainType = appState.chainType,
            currentProjectId = cmp.get('v.currentProjectId');

        if (appState.usage === this.USAGES.ProjectBuilder && $A.util.isEmpty(projectId) || (!!projectId && currentProjectId == projectId)) {
            return;
        }

        cmp.set('v.currentProjectId', projectId);
        this._resetProjectBasedLookups(cmp);
    },

    _resetProjectBasedLookups: function(cmp) {
        var projectId = cmp.get('v.currentProjectId');
        var appState = this._getAppState(cmp);

        this._initServices(cmp, appState.namespace, projectId, appState.usage);

        function setFilter(cmp) {
            this._initProjectLookup(cmp, appState.namespace, appState.usage, appState.accountId);

            this._initRepLookup(cmp, appState);

            this._initLocationLookup(cmp, {
                namespace: appState.namespace,
                projectId: projectId,
                usage: appState.usage,
                accountId: appState.accountId
            });

            this._initProgramLookup(cmp, appState.namespace, appState.accountId);
        }

        this._async(cmp, setFilter);
    },

    stateChanged: function(cmp, evt) {
        var filter = cmp.get('v.filter');
        filter.city = '';
        cmp.set('v.filter', filter);
        this._resetCityWithoutChangeEvent(cmp);
        this._handleFilterSideEffectOnSearchButton(cmp, filter);
    },

    _initServices: function(cmp, namespace, projectId, usage) {

        var uiService = cmp.find('serviceId');

        if (this._isEmpty(projectId)) {
            cmp.set('v.services', []);
            cmp.set('v.questions', []);
            cmp.set('v.targets', []);
            return;
        }

        this.getDispatcher(cmp)
        .className(this.HttpRequest.ProjectService)
        .action(this.HttpRequest.methods.FILTER)
        .body({ 'projectId': projectId, 'usage': usage })
        .onSuccess(this._serviceFilterResponseHandler)
        .run();

    },

    _serviceFilterResponseHandler: function(cmp, response) {
        var services = (response || []).map(function(e) {
            return { 'key': e[0], 'value': e[1] };
        });
        cmp.set('v.services', services);
    },

    _initProjectLookup: function(cmp, namespace, usage, accountId) {
        if (usage === this.USAGES.ProjectBuilder) {
            return;
        }

        var projectLookup = cmp.find('projectId');
        projectLookup.set('v.object', namespace + 'Project__c');
        var pF = this._buildProjectFilter(cmp, namespace, usage, accountId);
        if (!!pF) {
            projectLookup.set('v.filter', pF);
        }
        projectLookup.set('v.subtitleField', namespace + 'ProjectNumber__c');

        if (usage === this.USAGES.InternalUser) {
            var projectNumberLookup = cmp.find('projectNumber');
            projectNumberLookup.set('v.object', namespace + 'Project__c');
            projectNumberLookup.set('v.searchField', namespace + 'ProjectNumber__c');
            var pF = this._buildProjectFilter(cmp, namespace, usage, accountId);
            if (!!pF) {
                projectNumberLookup.set('v.filter', pF);
            }
            projectNumberLookup.set('v.subtitleField', 'Name');
        }
    },

    _buildProjectFilter: function(cmp, namespace, usage, accountId) {
        switch (usage) {
            case this.USAGES.Retailer:
                return namespace + 'RetailerAccount__c = \'' + accountId + '\'';
                break;
            case this.USAGES.CommunityViewer:
                return [
                    'Id IN (SELECT', namespace + 'Project__c FROM',
                    namespace + 'ProjectAccount__c WHERE',
                    namespace + 'Account__c = \'' + accountId + '\')'
                ].join(' ');
                break;
            case this.USAGES.InternalUser:
                accountId = cmp.get('v.currentAccountId');
                if (!!accountId) {
                    return [
                        'Id IN (SELECT', namespace + 'Project__c FROM',
                        namespace + 'ProjectAccount__c WHERE',
                        namespace + 'Account__c = \'' + accountId + '\')'
                    ].join(' ');
                }
                break;
        }
        return '';
    },

    _initProgramLookup: function(cmp, namespace, accountId) {
        var appState = this._getAppState(cmp);
        var lookup = cmp.find('programId');

        if (appState.usage == this.USAGES.ProjectBuilder) {
            return;
        }
        if (!lookup) {
            return;
        }
        lookup.set('v.object', namespace + 'Program__c');
        if (appState.usage != this.USAGES.InternalUser && !!accountId) {
            lookup.set('v.filter', namespace + 'RetailerAccount__c = \'' + accountId + '\'');
        }
    },

    _buildCityFilter: function(cmp, namespace, projectId) {
        var pF = this._buildFilter(namespace, projectId, 'Location__c', 'ProjectLocation__c');

        var state = cmp.get('v.filter').state || '';
        if (!!state) {
            if (!!pF) {
                pF = pF.substr(0, pF.length - 1) + ' AND ' + namespace + 'State__c = \'' + state + '\')';
            } else {
                pF = namespace + 'State__c = \'' + state + '\'';
            }

        }
        return pF;
    },
/*
    _initChainLookup: function(cmp, options) {
        var chainLookup = cmp.find('chainId');
        var filter = [
                options.namespace + 'Type__c=\'',
                options.chainType,
                '\''
            ].join(''),
            nonEmployeeFilter = this._getNonEmployeePredicate(options),
            accountFilter = this._getAccountPredicate(options);
        if (!!accountFilter) {
            filter = [filter, nonEmployeeFilter, accountFilter].join(' AND ');
        } else {
            filter = [filter, nonEmployeeFilter].join(' AND ');
        }

        chainLookup.set('v.object', options.namespace + 'Location__c');
        chainLookup.set('v.filter', filter);
    },*/

    _getAccountPredicate: function(options) {
        return ((options.usage == this.USAGES.Retailer) && !!options.accountId) ?
            ['(', options.namespace, 'RetailerAccount__c = \'', options.accountId, '\')'].join('') :
            '';
    },

    _getNonEmployeePredicate: function(options) {
        return [
            '(NOT ',
            'Name',
            ' LIKE \'%-%-%,%\')'
        ].join('');
    },

    _initRepLookup: function(cmp, appState) {
        var filter = ['Id IN (SELECT ', appState.namespace, 'ReportedContact__c From ', appState.namespace, 'JobAttempt__c)'].join('');
        cmp.set('v.repFilter', filter);
    },

    _initLocationLookup: function(cmp, options) {
        var locationLookup = cmp.find('locationId');
        var accountFilter = this._getAccountPredicate(options);
        var nonEmployeeFilter = this._getNonEmployeePredicate(options);

        if (this._isEmpty(options.projectId)) {
            if (!!accountFilter) {
                locationLookup.set('v.filter', [nonEmployeeFilter, accountFilter].join(' AND '));
            } else {
                locationLookup.set('v.filter', nonEmployeeFilter);
            }

        } else {
            var pF = this._buildFilter(options.namespace, options.projectId, 'Location__c', 'ProjectLocation__c');
            if (!!pF) {
                locationLookup.set('v.filter', pF);
            }
        }
        locationLookup.set('v.searchField', options.namespace + 'Title__c');
        locationLookup.set('v.object', options.namespace + 'Location__c');
    },

    _isEmpty: function(val) {
        return $A.util.isEmpty(val);
    },

    _buildFilter: function(namespace, projectId, selectField, recordType) {
        if (!projectId) {
            return '';
        }

        return [
            'Id IN (SELECT', namespace + selectField,
            'FROM',
            namespace + recordType,
            'WHERE',
            namespace + 'Project__c',
            '=',
            '\'' + projectId + '\')'
        ].join(' ');
    },

    _getFilter: function(cmp) {
        return cmp.get('v.filter') || {};
    },

    _getAppState: function(cmp) {
        return cmp.get('v.appState') || {};
    },

    startDateChanged: function(cmp, evt) {
        this._handleReportedDateChanged(cmp, evt, 'startDate');
    },

    endDateChanged: function(cmp, evt) {
        this._handleReportedDateChanged(cmp, evt, 'endDate');
    },

    applyFilter: function(cmp, evt) {
        var filter = this._getFilter(cmp);
        cmp.set('v.filterChangeSource', 'search');
        this._fireFilterChange(cmp, filter);
    },

    clearFilter: function(cmp, evt) {
        var filter = this._getDefaultFilter();
        cmp.set('v.filterChangeSource', '');
        cmp.set('v.btnSearchDisabled', true);
        cmp.set('v.filter', filter);
        cmp.set('v.city', '');
        cmp.set('v.startDate', '');
        cmp.set('v.endDate', '');

        this._setProperty(cmp, 'chkDuplicated', 'v.checked', false);
        this._setProperty(cmp, 'chkFavorite', 'v.checked', false);
        this._setProperty(cmp, 'chkUserFavorite','v.checked', false);
        this._setProperty(cmp, 'startDate', 'v.displayDate', '');
        this._setProperty(cmp, 'endDate', 'v.displayDate', '');
        this._fireClearFilterEvent(cmp);
    },

    _setProperty: function(cmp, auraId, propName, value) {
        var target = cmp.find(auraId);
        !!target && target.set(propName, value);
    },

    advanceClick: function(cmp) {
        cmp.set('v.isAdvancedSearch', !cmp.get('v.isAdvancedSearch'));
    },

    _fireClearFilterEvent: function(cmp) {
        var evt = cmp.getEvent('onFilterClear');
        evt.fire();
    },

    _handleReportedDateChanged: function(cmp, evt, filterName) {
        var filter = this._getFilter(cmp),
            prevDate = filter[filterName] || '',
            nextDate = evt.getParam('value') || '';

        if (prevDate === nextDate) {
            return;
        }

        filter[filterName] = nextDate;
        cmp.set('v.filter', filter);
    },

    _isInternalUser: function(usage) {
        return this.USAGES.InternalUser === usage;
    },

    _isProjectBuilder: function(usage) {
        return this.USAGES.ProjectBuilder === usage;
    },

    _isCommunityUser: function(usage) {
        return this.USAGES.CommunityViewer === usage;
    },

    _isCommunityRetailer: function(usage) {
        return this.USAGES.Retailer === usage;
    },
    checkQuestionAI: function(cmp, evt) {
        var filter = cmp.get('v.filter');
        var questions = cmp.get('v.questions');
        var selectedAI = questions.find(item => item.key === filter.questionId);
        console.log('selected ai', selectedAI);
        if ($A.util.isEmpty(selectedAI)) { return; }
        if (!$A.util.isEmpty(selectedAI.ai)) {
            cmp.set('v.showUnmatchedCheckbox', true);
            filter.unclassified = 0;
            cmp.set('v.filter', filter);
        } else {
            cmp.set('v.showUnmatchedCheckbox', false);
        }
        console.log('selected ai', selectedAI);
        var val = evt.getSource().get("v.value");
        console.log('val: ', val);
    }
})