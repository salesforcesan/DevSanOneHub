({

    showPhotoDetail: function(cmp, evt){
        var context = evt.getParam('context');
        var photo = context.photo, left = context.left;
        this._changePhotos(cmp, photo.id, 1);
        cmp.set('v.selPhoto', photo);
        this._showArrow(cmp, left);

    },

    photoClick: function(cmp, evt){
        var context = evt.getParam('context');
        var photo = context.photo;
        var photos = cmp.get('v.photos') || [];
        var canSelectCount = cmp.get('v.exportSelectCount');
        if(!photo.selected && canSelectCount < 1){
            this.onError(cmp, 'The maximum of the selected photos has been reached.');
            return;
        }

        photos.forEach(function(p){
            p.selected = (p.id == photo.id) ? (!p.selected ? 1 : 0) : p.selected;
        });
        cmp.set('v.photos',photos);
    },

    closePhotoDetail: function(cmp, evt){
        this._hideArrow(cmp);
        var id = evt.getParam('context');
        this._changePhotos(cmp, id, 0);
        cmp.set('v.selPhoto', null);
    },


    _changePhotos: function(cmp, id, selected){
        var photos = cmp.get('v.photos') || [];
        photos.forEach(function(p){
            p.detail = (p.id === id) ? selected : 0;
        });
        cmp.set('v.photos',photos);
    },

    _showArrow: function(cmp, left){
        var arrow = cmp.find('arrow');
        arrow.getElement().style.left = (left + 40) + 'px';
        $A.util.removeClass(arrow, 'hide');
    },

    _hideArrow: function(cmp){
      var arrow = cmp.find('arrow');
      $A.util.addClass(arrow, 'hide');  
    },

    markFavoriteEventRaised: function(cmp, evt){
        var photo = evt.getParam('context');
        var photos = cmp.get('v.photos') || [];

        for(var i=0; i < photos.length; i++){
            if(photos[i].id == photo.id){
                photos[i].favorite = photo.favorite;
                break;
            }
        }
        cmp.set('v.photos', photos);
        cmp.set('v.markTarget', photos[i]);
    }

})