({
    HttpRequest: {
        'className': 'PhotoRequest',
        'methods': {
            'UPDATE': 'modify'
        }
    },

    init: function(cmp) {
        cmp.set('v.invalidPhoto', this.InvalidImage);
        cmp.set('v.isInit', true);
        this._refreshTitle(cmp);
    },

    render: function(cmp){
        if(cmp.get('v.isInit')){
            cmp.set('v.isInit', false);
            this.photoChanged(cmp);
        }
    },

    _isSuperUser: function(cmp) {
        var usage = cmp.get('v.usage');
        return usage != 'Retailer' && usage != 'Community Viewer';
    },

    _refreshTitle: function(cmp) {
        var photo = cmp.get('v.photo');
        var isSuperUser = this._isSuperUser(cmp);

        if (isSuperUser) {
            cmp.set(
                'v.favoriteTitle', photo.favorite == 1
                ? 'Unmark favorite'
                : 'Mark Favorite');
            cmp.set(
                'v.userFavoriteTitle', photo.userFavorite == 1
                ? 'User Favorite' : '');
            cmp.set(
                'v.qcTitle', photo.qc == 0
                ? 'Quality Not Checked'
                : 'Quality Checked');
            cmp.set(
                'v.qcClass', photo.qc == 0
                ? ''
                : 'checked');
            cmp.set(
                'v.favoriteClass', photo.favorite == 1
                ? 'checked'
                : '');
            cmp.set(
                'v.userFavoriteClass', photo.userFavorite == 1
                ? 'checked'
                : '');
        } else {
            cmp.set('v.favoriteTitle', 'Favorite Photo');
            cmp.set(
                'v.qcTitle', photo.qc == 1
                ? 'invisible to the client'
                : 'published photo');
            cmp.set(
                'v.qcClass', photo.qc == 0
                ? ''
                : 'checked');
            cmp.set(
                'v.favoriteClass', photo.favorite == 1
                ? 'checked'
                : '');
            cmp.set('v.userFavoriteTitle', photo.userFavorite == 1
                ? 'Unmark my favorite photo' : 'Mark my favorite photo');
            cmp.set('v.userFavoriteClass', photo.userFavorite == 1
                ? 'checked' : '');
        }
        cmp.set(
            'v.dupClass', photo.duplicated == 1
            ? 'oh-duplicated'
            : '');
        cmp.set('v.isSuperUser', isSuperUser);
    },

    imageLoaded: function(cmp, evt) {
        var source = evt.target
        var target = cmp.find('photoImage').getElement();
        if (!!target) {
            target.src = source.src;
        }
    },

    photoClicked: function(cmp) {
        var photo = cmp.get('v.photo');

        if (!!photo.export) {
            this._dispatch(cmp, 'onPhotoClick');
        } else {
            this._dispatch(cmp, 'onShowPhotoDetail');
        }
    },

    photoChanged: function(cmp) {
       var photo = cmp.get('v.photo') || {};
        if (photo.id === '-1') {
            return;
        }
        if (!!photo.selected) {
            this._showSelectOverlay(cmp);
        } else if (!!photo.detail || !!photo.selectable) {
            this._showOverlay(cmp);
        } else {
            this._hideOverlay(cmp);
        }
    },

    qc: function(cmp, evt) {
        this._showBusy(cmp);
        this._async(cmp, this._qcHandler, 250);
    },

    _qcHandler: function(cmp) {
        var photo = cmp.get('v.photo');

        this.getDispatcher(cmp).className(this.HttpRequest.className).action(this.HttpRequest.methods.UPDATE).body({
            'id': photo.id,
            'qc': photo.qc == 0
                ? 1
                : 0
        }).onSuccess(this._markFavoriteResponseHandler).onError(this._errorHandler).run();
    },


    markTarget: function(cmp, evt) {
        var target = cmp.get('v.markTarget'),
            photo = cmp.get('v.photo');
        if (target.id != photo.id) {
            return;
        }
        photo.favorite = target.favorite;
        photo.qc = target.qc;
        cmp.set('v.photo', photo);
        this._refreshTitle(cmp);
    },

    markUserFavorite: function(cmp, evt){
        this._showBusy(cmp);
        this._async(cmp, this._markUserFaoriteHandler, 250);
    },

    _markUserFaoriteHandler: function(cmp) {
        var photo = cmp.get('v.photo');

        this.getDispatcher(cmp)
            .className(this.HttpRequest.className)
            .action(this.HttpRequest.methods.UPDATE).body(
                {
                    'id': photo.id,
                    'usage': cmp.get('v.usage'),
                    'favorite': photo.userFavorite == 0
                    ? 1 
                    : 0
            })
            .onSuccess(this._markFavoriteResponseHandler)
            .onError(this._markFavoriteError).run();
    },

    markFavorite: function(cmp, evt) {
        this._showBusy(cmp);
        this._async(cmp, this._markFavoriteHandler, 250);
    },

    _markFavoriteHandler: function(cmp) {
        var photo = cmp.get('v.photo');

        this.getDispatcher(cmp).className(this.HttpRequest.className).action(this.HttpRequest.methods.UPDATE).body({
            'id': photo.id,
            'usage': cmp.get('v.usage'),
            'favorite': photo.favorite == 0
                ? 1
                : 0
        }).onSuccess(this._markFavoriteResponseHandler).onError(this._markFavoriteError).run();
    },

    _markFavoriteError: function(cmp , err){
        this._hideBusy(cmp);
        this.onDismissableError(cmp, err);
    },

    _markFavoriteResponseHandler: function(cmp, response) {
        this._hideBusy(cmp);
        var photo = cmp.get('v.photo');
        photo.favorite = response.favorite;
        photo.qc = response.qc;
        photo.userFavorite = response.userFavorite;
        cmp.set('v.photo', photo);
        this._refreshTitle(cmp);
    },

    _errorHandler: function(cmp, err) {
        this._hideBusy(cmp);
        this.onError(cmp, err);
    },

    _showOverlay: function(cmp) {
        this._addOverlayClasses(cmp, ['shown']);
        this._removeClasses(cmp, ['oh-green']);
    },

    _hideOverlay: function(cmp) {
        this._removeClasses(cmp, ['oh-green', 'shown']);
    },

    _showSelectOverlay: function(cmp) {
        this._addOverlayClasses(cmp, ['oh-green', 'shown']);
    },

    _addOverlayClasses: function(cmp, classes) {
        try{
            var classList = this._getClassListToken(cmp, 'overLayDiv');
            if (!classList) {
                return;
            }
            classes.forEach(function(cls) {
                if (!classList.contains(cls)) {
                    classList.add(cls);
                }
            });
        } catch(ex){
            console.log(ex);
        }
    },

    _removeClasses: function(cmp, classes) {
        try{
            var classList = this._getClassListToken(cmp, 'overLayDiv');
            if (!classList) {
                return;
            }
            classes.forEach(function(cls) {
                if (classList.contains(cls)) {
                    classList.remove(cls);
                }
            })
        }
        catch(ex){
            console.log(ex);
        }
    },

    _getClassListToken: function(cmp, auraId) {
        var target = cmp.find(auraId).getElement();
        return !!target
            ? target.classList
            : [];
    },

    _dispatch: function(cmp, eventName) {
        var msg = cmp.getEvent(eventName);
        var photoContainer = cmp.find('photoContainer').getElement();
        msg.setParams({
            context: {
                photo: cmp.get('v.photo'),
                left: photoContainer.offsetLeft
            }
        });
        msg.fire();
    },

    _showBusy: function(cmp) {
        cmp.set('v.showBusy', true);
    },

    _hideBusy: function(cmp) {
        cmp.set('v.showBusy', false);
    }
})