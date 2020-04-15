({
    onExportImages: function(cmp, evt, h){
        h.exportImages(cmp);
    },

    onGenerateZip: function(cmp, evt, h){
        h.generateZip(cmp);
    },

    onExportToPPT: function(cmp, evt, h){
        h.exportToPPT(cmp);
    },

    onEmailSelected: function(cmp, evt, h){
        h.emailSelected(cmp);
    },

    onCancel: function(cmp, evt ,h){
        h.cancel(cmp);
    }
})