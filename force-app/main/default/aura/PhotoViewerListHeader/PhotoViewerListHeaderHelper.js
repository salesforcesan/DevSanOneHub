({
    exportImages: function(cmp){
        var state = !cmp.get('v.exportImages');
        cmp.set('v.exportImages', state);

        var msg = cmp.getEvent('onBeginExport');
        msg.fire();
    },

    generateZip: function(cmp){
        var msg = cmp.getEvent('onGenerateZip');
        msg.fire();
    },

    exportToPPT: function(cmp){
        var msg = cmp.getEvent('onExportToPPTRequest');
        msg.fire();
    },

    emailSelected: function(cmp){

    },

    cancel: function(cmp){
        var state = !cmp.get('v.exportImages');
        cmp.set('v.exportImages', state);
        var msg = cmp.getEvent('onCancelExport');
        msg.fire();
    }

})