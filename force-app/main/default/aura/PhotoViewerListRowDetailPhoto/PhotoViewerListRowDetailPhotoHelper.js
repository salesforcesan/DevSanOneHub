({
    HttpRequest: {
        'className': 'PhotoRequest',
        'methods': {
            'GET': 'get',
            'UPDATE': 'modify',
        }
    },

    init: function(cmp){
        cmp.set('v.invalidPhoto', this.InvalidImage);
    },

    idChanged: function(cmp){
        this._showBusy(cmp);
        this._async(cmp, this._idChangedHandler, 250);
    },

    _initFavoriteLink: function(cmp){
        var isSuperUser = this._isSuperUser(cmp);
        var photo = cmp.get('v.photo');
        var title;

        if(isSuperUser){
            title = photo.favorite == 1 ? 'Unmark Favorite' : 'Mark Favorite';
        } else {
            title = photo.favorite == 1 ? 'Favorite': 'Unfavorite';
        }

        cmp.set('v.isSuperUser', isSuperUser);
        cmp.set('v.favoriteTitle', title);
    },

    _isSuperUser: function(cmp){
        var usage = cmp.get('v.usage');
        return usage != 'Retailer' && usage != 'Community Viewer';
    },  

    _calculateFormClass:function(cmp){
        var el = document.querySelector('div.photo-container');
        cmp.set('v.formClass', el.clientWidth < 1000 ? 'oh-narrow-form' : 'oh-form');

    },
    
    _idChangedHandler: function(cmp){
        this._calculateFormClass(cmp);
        this.getDispatcher(cmp)
            .className(this.HttpRequest.className)
            .action(this.HttpRequest.methods.GET)
            .body({
                'id': cmp.get('v.id')
            })
            .onSuccess(this._getPhotoDetailResponseHandler)
            .onError(this._errorHandler)
            .run();
    },

    _getPhotoDetailResponseHandler: function(cmp, response){
        this._hideBusy(cmp);
        cmp.set('v.photo', response || {});
        this._initFavoriteLink(cmp);
    },

    _errorHandler: function(cmp, err){
        this._hideBusy(cmp);
        this.onError(cmp, err);
    },

    _showBusy: function(cmp){
        cmp.set('v.showBusy',true);
    },

    _hideBusy: function(cmp){
        cmp.set('v.showBusy',false);
    },

    markFavorite: function(cmp, evt){
        this._showBusy(cmp);
        this._async(cmp, this._markFavoriteHandler, 250);
    },

    _markFavoriteHandler: function(cmp){
        this.getDispatcher(cmp)
            .className(this.HttpRequest.className)
            .action(this.HttpRequest.methods.UPDATE)
            .body({
                'id': cmp.get('v.id'),
                'favorite': cmp.get('v.photo').favorite == 1 ? '0' : '1'
            })
            .onSuccess(this._markFavoriteResonseHandler)
            .onError(this._errorHandler)
            .run();
    },

    _markFavoriteResonseHandler: function(cmp, response){
        this._hideBusy(cmp);
        var photo = response || {};
        cmp.set('v.photo', photo);
        var msg = cmp.getEvent('onMarkFavoriteEventRaised');
        msg.setParams({
            context: photo
        });
        msg.fire();
    },

    export: function(cmp, evt){
        var msg = cmp.getEvent('onExportOnePhoto');
        msg.setParams({
            context: cmp.get('v.id')
        });
        msg.fire();
    },

    showMore: function(cmp){
        cmp.set('v.showMore', !cmp.get('v.showMore'));
    },

})