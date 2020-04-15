({
    init: function(cmp){
        this._initSuperUser(cmp);
    },

    _initSuperUser: function(cmp){
        var usage = cmp.get('v.usage');
        var superUser = usage != 'Retailer' && usage != 'Community Viewer';
        cmp.set('v.isSuperuser', superUser);
    },

    idChanged: function(cmp, evt){
        this._showBusy(cmp);
        this._destroyBody(cmp);
        this._async(cmp, this._createBody, 250);
    },

    _destroyBody: function(cmp){
        var body = cmp.get('v.chatterBody') || [];
        body.forEach(function(kid){
            kid.destroy();
        });
        cmp.set('v.chatterBody',[]);
    },

    _createBody:function(cmp){
        var id = cmp.get('v.id');
        var self = this;
        var isSuperuser = cmp.get('v.isSuperuser');
        var arrCmp = [];
        if(isSuperuser){
            arrCmp.push(['forceChatter:publisher', {'context':'RECORD','recordId': id}]);
       }
       arrCmp.push(['forceChatter:feed', {'type': 'Record', subjectId: id}]);
        $A.createComponents(arrCmp,
        function(components, status, msgs){
            var body = [];
            for(var i=0; i < components.length; i++){
                body.push(components[i]);
            }
            cmp.set('v.chatterBody', body);
            self._hideBusy(cmp);
        });
    },

     _showBusy: function(cmp){
        cmp.set('v.showBusy',true);
    },

    _hideBusy: function(cmp){
        cmp.set('v.showBusy',false);
    },
})