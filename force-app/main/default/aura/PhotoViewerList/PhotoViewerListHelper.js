({
    HttpRequest: {
        'className': 'PhotoRequest',
        'methods': {
            'FILTER': 'filter'
        }
    },

    USAGES: {
        ProjectBuilder: 'Project Builder',
        Retailer: 'Retailer',
        CommunityViewer: 'Community Viewer',
        InternalUser: 'Internal User'
    },

    _default_padding: 200,
    _word_exporter_url: '/apex/{namespace}PhotoViewerWordExporter?images=',

    init: function(cmp) {
        var self = this;
        var func = this.photosChanged;

        function shouldResize(cmp) {
            if (self._getExportFlag(cmp) == '1') {
                return 0;
            }
            var containerWidth = cmp.get('v.containerWidth');
            var width = self._getContainerWidth(cmp);
            if (Math.abs(width - containerWidth) < 20) {
                return 0;
            }
            return 1;
        }

        cmp.onresize = $A.getCallback(function() {
            if (!shouldResize.call(self, cmp)) {
                return;
            }

            var timeoutId = cmp.get('v.timeoutId');
            if (!!timeoutId) {
                window.clearTimeout(timeoutId);
            }
            timeoutId = window.setTimeout($A.getCallback(function() {
                cmp.set('v.action', 'filter');
                func.call(self, cmp);
            }), 250);
            cmp.set('v.timeoutId', timeoutId);
        });

        window.addEventListener('resize', cmp.onresize);
    },

    destroy: function(cmp, evt) {
        if (!!cmp.onresize) {
            window.removeEventListener('resize', cmp.onresize);
        }
    },

    _getContainerWidth: function(cmp) {
        var container = document.querySelector('.photo-viewer-list-container');
        var width = window.innerWidth - this._getPadding(cmp);
        if (!!container.clientWidth) {
            width = container.clientWidth;
        }
        return width;
    },

    _getPadding: function(cmp) {
        return cmp.get('v.padding') || this._default_padding;
    },

    beginExport: function(cmp, evt) {
        cmp.set('v.action', 'export');
        this._setExportFlag(cmp, 1);
        this._resetExportCount(cmp);
        this._updatePhotoListSet(cmp, 1, 1, 0);
    },

    _setExportFlag: function(cmp, yes) {
        var el = cmp.find('photoViewList').getElement();
        el.setAttribute('data-export', yes);
    },

    _getExportFlag: function(cmp) {
        var el = cmp.find('photoViewList').getElement();
        return el.getAttribute('data-export');
    },

    _resetExportCount: function(cmp) {
        cmp.set('v.exportSelectCount', cmp.get('v.maxExports'));
    },

    _getNextComponentId: function(cmp) {
        var id = cmp.get('v.nextId') + 1;
        cmp.set('v.nextId', id);

        return id;
    },

    _updatePhotoListSet: function(cmp, exported, selectable, selected) {
        var photoList;
        var photoListSet = cmp.get('v.photoListSet');
        var instances = cmp.get('v.photoLists');
        var count = cmp.get('v.exportSelectCount');


        for (var i = 0; i < photoListSet.length; i++) {
            photoList = photoListSet[i];
            for (var j = 0; j < photoList.length; j++) {
                photoList[j].export = exported;
                photoList[j].selectable = selectable;
                photoList[j].selected = selected;
            }
            instances[i].set('v.photos', photoList);
            instances[i].set('v.exportSelectCount', count);
        }
        cmp.set('v.photoListSet', photoListSet);
        cmp.set('v.photoLists', instances);
    },

    cancelExport: function(cmp, evt) {
        cmp.set('v.action', 'export');
        this._setExportFlag(cmp, 0);
        this._resetExportCount(cmp);
        this._updatePhotoListSet(cmp, 0, 0, 0);
        this._updatePhotoListRowCanSelectCounts(cmp);
    },

    showMore: function(cmp, evt) {
        cmp.set('v.showMoreBusy', true);
        
        this._async(cmp, function(cmp){
            var msg = cmp.getEvent('onShowMoreRequest');
            msg.fire();
        });
    },

    photoClick: function(cmp, evt) {
        var maxCount = cmp.get('v.maxExports');
        var count = this._getSelectedPhotos(cmp).length;
        cmp.set('v.exportSelectCount', maxCount - count);        
        this._updatePhotoListRowCanSelectCounts(cmp);
    },

    _updatePhotoListRowCanSelectCounts: function(cmp) {
        var count = cmp.get('v.exportSelectCount');
        var components = cmp.get('v.photoLists') || [];
        components.forEach(function(c) {
            c.set('v.exportSelectCount', count);
        });
        cmp.set('v.photoLists', components);
    },

    _getSelectedPhotos: function(cmp) {
        var result = [];
        (cmp.get('v.photoListSet') || []).forEach(function(set) {
            set.forEach(function(p) {
                if (!!p.selected) {
                    result.push(p);
                }
            });
        });
        return result;
    },

    photosChanged: function(cmp) {
        var photos = cmp.get('v.photos') || [],
            action = cmp.get('v.action');

        if (photos.length === 0) {
            cmp.set('v.photoListSet', []);
            cmp.set('v.photoLists', []);
            return;
        }

        switch (action) {
            case 'get':
            case 'filter':
                this._filterRenderHandler(cmp);
                break;
            case 'showmore':
                this._showmoreRenderHandler(cmp);
        }
    },

    _filterRenderHandler: function(cmp) {
        var photos = cmp.get('v.photos');
        cmp.set('v.currentPhotoCount', photos.length);
        cmp.set('v.nextId', 0);

        this._destroyComponents(cmp);

        var containerWidth = this._getContainerWidth(cmp);
        var colSize = this._calculateColSize(cmp, containerWidth);
        cmp.set('v.colSize', colSize);
        cmp.set('v.containerWidth', containerWidth);

        var photoListSet = this._shapePhotos(photos, colSize);
        cmp.set('v.photoListSet', photoListSet);
        this._renderPhotos(cmp);
    },

    _showmoreRenderHandler: function(cmp) {
        var obj = this._getObject(cmp);
        cmp.set('v.showMoreBusy', false);
        if (obj.photos.length == obj.currentCount) {
            return;
        }
        if (obj.empty) {
            return;
        }
        cmp.set('v.currentPhotoCount', obj.photos.length);

        var lastList = obj.listSet[obj.listSet.length - 1];
        if (this._hasEmptyPhoto(lastList)) {
            obj.instances.pop().destroy();
            cmp.set('v.photoLists', obj.instances);
            obj.listSet.pop();
        }
        var colSize = cmp.get('v.colSize');
        var listSet = this._shapePhotos(obj.photos, colSize);
        cmp.set('v.photoListSet', listSet);
        this._renderShowMorePhotos(cmp);
    },

    _hasEmptyPhoto: function(list) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === '-1') {
                return true;
            }
        }
        return false;
    },

    _getObject: function(cmp) {
        var listSet = cmp.get('v.photoListSet') || [];
        var photoInstances = cmp.get('v.photoLists') || [];
        var photos = cmp.get('v.photos') || [];
        var count = cmp.get('v.currentPhotoCount');

        return {
            'empty': (listSet.length === 0 || photoInstances.length === 0)
                ? 1
                : 0,
            'photos': photos,
            'currentCount': count,
            'listSet': listSet,
            'instances': photoInstances
        };
    },

    _destroyComponents: function(cmp) {
        (cmp.get('v.photoLists') || []).forEach(function(cmpList) {
            cmpList.destroy();
        });
        cmp.set('v.photoLists', []);
    },

    _renderShowMorePhotos: function(cmp) {
        var obj = this._getObject(cmp);

        function callback(instances, status, messages) {
            instances.forEach(function(instance) {
                obj.instances.push(instance);
            });
            cmp.set('v.photoLists', obj.instances);
        }

        var componentDefs = [];
        var exportSelectCount = cmp.get('v.exportSelectCount');
        var photoHeight = cmp.get('v.photoHeight');
        var photoWidth = cmp.get('v.photoWidth');
        var usage = cmp.get('v.usage');

        for (var i = obj.instances.length; i < obj.listSet.length; i++) {
            componentDefs.push([
                'c:PhotoViewerListRow', {
                    'id': this._getNextComponentId(cmp),
                    'usage': usage,
                    'exportSelectCount': exportSelectCount,
                    'photoHeight': photoHeight,
                    'photoWidth': photoWidth,
                    'photos': obj.listSet[i]
                }
            ]);
        }
        $A.createComponents(componentDefs, callback);
    },

    _renderPhotos: function(cmp) {
        var photoListSet = cmp.get('v.photoListSet') || [];
        var action = cmp.get('v.action');

        function callback(instances, status, messages) {
            cmp.set('v.photoLists', instances);
        }

        var componentDefs = [];
        var exportSelectCount = cmp.get('v.exportSelectCount');
        var photoHeight = cmp.get('v.photoHeight');
        var photoWidth = cmp.get('v.photoWidth');
        var usage = cmp.get('v.usage');

        for (var i = 0; i < photoListSet.length; i++) {

            componentDefs.push([
                'c:PhotoViewerListRow', {
                    'id': this._getNextComponentId(cmp),
                    'usage': usage,
                    'exportSelectCount': exportSelectCount,
                    'photoHeight': photoHeight,
                    'photoWidth': photoWidth,
                    'photos': photoListSet[i]
                }
            ]);
        }
        $A.createComponents(componentDefs, callback);
    },

    _calculateColSize: function(cmp, viewPointWidth) {
        var photoWidth = (cmp.get('v.photoWidth') || 100) + 16;

        return Math.floor(viewPointWidth / photoWidth) || 1;
    },

    _shapePhotos: function(photos, colSize) {
        var photoList = [],
            photo,
            pos = 0,
            photoListSet = [],
            photos = photos || [];


        for (var i = 0; i < photos.length; i++) {
            if (pos++ < colSize) {
                photoList.push(this._argumentPhoto(photos[i]));
            } else {
                photoListSet.push(photoList);
                photoList = [this._argumentPhoto(photos[i])];
                pos = 1;
            }
        }
        if (photoList.length > 0) {
            if (photoList.length < colSize) {
                for (var i = photoList.length; i < colSize; i++) {
                    photoList.push({
                        'id': '-1',
                        'url': '',
                        'title': '',
                        'favorite': 0,
                        'userFavorite': 0,
                        'qc': 0,
                        'dulicated': 0,
                        'selected': 0,
                        'export': 0,
                        'detail': 0,
                        'selectable': 0,
                        'error': 0,
                        'message': '',
                    });
                }
            }
            photoListSet.push(photoList);
        }
        return photoListSet;
    },

    _argumentPhoto: function(photo) {

        return {
            'id': photo.id,
            'url': photo.url,
            'title': photo.title,
            'favorite': photo.favorite,
            'userFavorite': photo.userFavorite,
            'qc': photo.qc,
            'duplicated': photo.duplicated || 0,
            'selected': 0,
            'export': 0,
            'detail': 0,
            'selectable': 0,
            'error': photo.error,
            'message': photo.message,
        };
    },

    exportToPPT: function(cmp){
        var photos  = this._getSelectedPhotos(cmp);
        if (photos.length === 0){
            this.onDismissableError(cmp, 'No photos selected to export.');
            return;
        }
        var ids = photos.map(function(p){
            return p.id;
        });


        cmp.set("v.exporting",true);
        cmp.set("v.pptxPhotos",[]);

        this.getDispatcher(cmp)
        .className(this.HttpRequest.className)
        .action(this.HttpRequest.methods.FILTER)
        .body({ids: ids})
        .onSuccess(this._getImagesResponseHandler)
        .onError(this._getImagesErrorHandler)
        //.onFinally(onFinally)
        .run();
    },

    pptxExportCompleted: function(cmp, evt){
        var context = evt.getParam('context');
        cmp.set('v.exporting',false);

        if(context.status == 1){
            this.onDismissableSuccess(cmp, context.message);
        } else {
            this.onDismissableError(cmp, context.message);
        }
    },

    _getImagesResponseHandler: function(cmp, records){
        var images = records || [];
        
        if (images.length === 0){
            this.onDismissableError(cmp,'No images found for the selected photos.');
            return;
        }

        this._toPptxPhotos(cmp, images);
    },

    _toPptxPhotos: function(cmp, photos){
        var t;
        var data = photos.map(function(p){
            t = {};
            Object.keys(p).forEach(function(key){
                t[key] = p[key];
            });
            t['dataUrl'] = '';
            if (!!t.url){
                t.url = t.url1;
            }
            return t;
        });

        cmp.set("v.pptxPhotos", data);
    },


    _getImagesErrorHandler: function(cmp, error){
        this.onDismissableError(cmp, error);
    },

    generateZip: function(cmp, evt) {
        var photos = this._getSelectedPhotos(cmp);
        if (photos.length === 0){
            this.onDismissableError(cmp, 'No photos selected to export.');
            return;
        }
        var ids = photos.map(function(p){return p.id;});
        var url = this._getExporterUrl(cmp, ids.join(','));
        this._genZip(cmp, url);
    },

    _genZip: function(cmp, url) {
        var link = document.createElement('a');
        link.download = 'photoviewer.docx';
        link.href = url;
        link.target = '__blank';

        document.body.appendChild(link);
        link.click();
        cmp.set("v.exporting",true);
        function onCallback(cmp) {
            document.body.removeChild(link);
            cmp.set("v.exporting",false);
        }

        this._async(cmp, onCallback, 500);
    },

    _getExporterUrl: function(cmp, ids) {
        if(this._isCommunitySite(cmp)){
            return [
                cmp.get('v.communityUrl'),
                this._word_exporter_url.replace('{namespace}', cmp.get('v.namespace')),
                ids
            ].join('');
        }

        return [
            window.location.protocol,
            '//',
            window.location.host,
            this._word_exporter_url.replace('{namespace}', cmp.get('v.namespace')),
            ids
        ].join('')
    },

    exportOnePhoto: function(cmp, evt) {
        var url = this._getExporterUrl(cmp, evt.getParam('context'));
        this._setExportFlag(cmp, 1);
        this._genZip(cmp, url);
        this._async(cmp, function(cmp) {
            this._setExportFlag(cmp, 0);
        }, 1500);
    },

    _isCommunitySite: function(cmp) {
        var usage = cmp.get('v.usage');
        return [this.USAGES.CommunityViewer, this.USAGES.Retailer].indexOf(usage) !== -1;
    }
})