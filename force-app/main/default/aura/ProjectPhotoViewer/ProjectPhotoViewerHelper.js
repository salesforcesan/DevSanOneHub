({
    HttpRequest: {
        'className': 'ProjectPhotoViewerRequest',
        'methods': {
            'GET': 'get',
            'FILTER': 'filter'
        }
    },

    DummyImage: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',

    init: function(cmp) {
        this._showBusy(cmp);
        this._initFilterToggle(cmp);
        this._initProject(cmp);
        this._initPhotos(cmp);
        var usage = cmp.get('v.usage');
        usage == 'Project Builder' ? cmp.set('v.usagePB', true) : cmp.set('v.usagePB', false);
    },

    showMore: function(cmp) {
        this._setAction(cmp, 'showmore');
        this._async(cmp, this._nextPageRequestHandler, 250);
    },

    _setPhotoViewListAction: function(cmp, action) {
        cmp.find('photoList').set('v.action', action);
    },

    _nextPageRequestHandler: function(cmp) {
        var context = cmp.get('v.filter') || {};
        var body = {};
        var appState = this._getAppState(cmp);

        Object.keys(context).forEach(function(k) {
            body[k] = context[k];
        });

        body['projectId'] = cmp.get('v.projectId');
        body['usage'] = cmp.get('v.usage');
        body['noneOverrideCursor'] = cmp.get('v.noneOverrideCursor');
        body['overrideCursor'] = cmp.get('v.overrideCursor');
        body['page'] = appState['page'] + 1;
        body['action'] = cmp.get('v.action');

        function onCallback(cmp, response) {
            appState['page'] = appState['page'] + 1;
            this._photosResponseHandler(cmp, response, appState);
        }

        this.getDispatcher(cmp).className(this.HttpRequest.className).action(this.HttpRequest.methods.FILTER).body(body).onSuccess(onCallback).onError(this._errHandler).run();
    },

    _initProject: function(cmp) {
        var appState = this._getAppState(cmp);
        appState['projectCount'] = 1;
        appState['projectId'] = cmp.get('v.projectId');
        appState['namespace'] = '_';
        appState['page'] = 0;
        appState['action'] = 'init';
        appState['usage'] = cmp.get('v.usage');
        appState['lookupSize'] = '50';
        appState['accountId'] = '';
        this._setAppState(cmp, appState);
    },

    _isInit: function(cmp) {
        if (!cmp.get('v.isInit')) {
            cmp.set('v.isInit', false);
            return 1;
        }
        return 0;
    },

    _initPhotos: function(cmp) {
        var projectId = cmp.get('v.projectId');
        this._setAction(cmp, 'filter');

        this.getDispatcher(cmp).className(this.HttpRequest.className).action(this.HttpRequest.methods.GET).body({'projectId': projectId, 'usage': cmp.get('v.usage'), 'overrideCursor': 0, 'noneOverrideCursor': 0}).onSuccess(this._photosGetResponseHandler).onError(this._errHandler).run();
    },

    _photosGetResponseHandler: function(cmp, response) {
        var res = response || {};
        var appState = this._getAppState(cmp);

        this._hideBusy(cmp);
        this._setPhotoCursors(cmp, res.noneOverrideCursor, res.overrideCursor);
        this._setAction(cmp, 'get');

        appState['namespace'] = res.namespace || '';
        appState['chainType'] = res.chainType || '';
        appState['lookupSize'] = (res.lookupSize || 50) + '';
        appState['page'] = 0;
        appState['maxExports'] = res.maxExports || 50;
        appState['maxFavorites'] = res.maxFavorites || 10;
        appState['accountId'] = res.accountId || '';
        cmp.set('v.communityUrl', res.communityUrl);

        this._photosResponseHandler(cmp, res, appState);
    },

    _setAction: function(cmp, action) {
        cmp.set('v.action', action);
    },

    _isFitlerAction: function(cmp) {
        return cmp.get('v.action') == 'filter';
    },

    _isShowMoreAction: function(cmp) {
        return cmp.get('v.action') == 'showmore';
    },

    _setPhotoCursors: function(cmp, noneOverrideCursor, overrideCursor) {
        cmp.set('v.noneOverrideCursor', noneOverrideCursor || 0);
        cmp.set('v.overrideCursor', overrideCursor || 0);
    },

    _photosResponseHandler: function(cmp, response, appState) {
        this._hideBusy(cmp);
        var photos = this._isShowMoreAction(cmp)
                ? (appState['photos'] || [])
                : [],
            response = response || {};

        (response.photos || []).forEach(function(p) {
            photos.push({
                id: p[0],
                url: p[1],
                title: p[2],
                favorite: p[3],
                qc: p[4],
                duplicated: p[5],
                userFavorite: p[6],
            });
        });

        this._setPhotoCursors(cmp, response.noneOverrideCursor, response.overrideCursor);
        cmp.set('v.hasMore', response.hasMore == 1);
        
        var action = cmp.get('v.action');
        appState['action'] = action;
        appState['photos'] = photos;
        this._setPhotoViewListAction(cmp, action);
        this._setAppState(cmp, appState);

        var filter = cmp.get('v.filterPlaceholder');
        if(!!filter && filter.length > 0){
            filter[0].set('v.appState', appState);
        } else {
            $A.createComponent("c:PhotoViewerFilter",{
                appState: appState
            }, function(cmpFilter){
                cmp.set('v.filterPlaceholder', cmpFilter);
            });
        }
    },

    _initFilterToggle: function(cmp) {
        var appState = this._getAppState(cmp) || {};
        appState['filterToggleState'] = !!cmp.get('v.expandFilter');
        this._setAppState(cmp, appState);
    },

    toggleFilter: function(cmp, evt) {
        var appState = this._getAppState(cmp);
        appState.filterToggleState = !appState.filterToggleState;
        console.log(JSON.stringify(appState));
        this._setAppState(cmp, appState);
    },

    filterChanged: function(cmp, evt) {
        var context = evt.getParam('context') || {};
        cmp.set('v.filter', context);
        
        if(this._isFilterEmpty(context)){
            cmp.set('v.showCount', false);
            var appState = this._getAppState(cmp);
            appState.photos = [];
            this._setAppState(cmp, appState);
            return;
        }

        this._showBusy(cmp);
        this._setAction(cmp, 'filter');
        this._resetForNonProjectBuilder(cmp);
        this._resetPhotos(cmp);
        this._async(cmp, this._filterChangedHandler, 250);
    },

    filterClear: function(cmp){
        this._flushPhotos(cmp);
        cmp.set('v.showCount', false);
    },

    _resetForNonProjectBuilder: function(cmp) {
        if (cmp.get('v.usage') == 'Project Builder') {
            return;
        }
        var filter = cmp.get('v.filter');
        cmp.set('v.projectId', filter['projectId']);
    },

    _resetPhotos: function(cmp) {
        var appState = this._getAppState(cmp);
        var dummy = this.DummyImage;
        var photos = []
        for (var i = 0; i < 20; i++) {
            photos.push({id: i, url: dummy, favorite: 0, qc: 0, duplicated: 0});
        }

        this._setPhotoCursors(cmp, 0, 0);
        appState['page'] = 0;
        appState['action'] = cmp.get('v.action');
        appState.projectId = cmp.get('v.projectId');
        appState.photos = photos;
        this._setAppState(cmp, appState);
    },

    _flushPhotos: function(cmp) {
        var appState = this._getAppState(cmp);
        this._setPhotoCursors(cmp, 0, 0);
        appState['page'] = 0;
        appState['action'] = cmp.get('v.action');
        appState.projectId = cmp.get('v.projectId');
        appState.photos = [];
        this._setAppState(cmp, appState);
    },

    _isFilterEmpty: function(context){
        var keys = Object.keys(context);
        
        for(var i=0; i < keys.length; i++){
            if(!!context[keys[i]]){
                return false;
            }
        }
        return true;
    },

    _filterChangedHandler: function(cmp) {
        var context = cmp.get('v.filter');
        var usage = cmp.get('v.usage');
        var body = {};

        Object.keys(context).forEach(function(k) {
            body[k] = context[k];
        });

        if (usage == 'Project Builder') {
            body['projectId'] = cmp.get('v.projectId');
        }
        body['usage'] = usage;
        body['action'] = cmp.get('v.action');

        function onResponse(cmp, response) {
            cmp.set('v.showCount', true);
            this._photosResponseHandler(cmp, response, this._getAppState(cmp));
        }

        this.getDispatcher(cmp).className(this.HttpRequest.className).action(this.HttpRequest.methods.FILTER).body(body).onSuccess(onResponse).onError(this._errHandler).run();
    },

    _errHandler: function(cmp, err) {
        this._hideBusy(cmp);
        this.onError(cmp, err);
    },

    _showBusy: function(cmp) {
        cmp.set('v.showBusy', true);
    },

    _hideBusy: function(cmp) {
        cmp.set('v.showBusy', false);
    },

    _getAppState: function(cmp) {
        return cmp.get('v.appState');
    },

    _setAppState: function(cmp, appState) {
        cmp.set('v.appState', appState);
    }
})