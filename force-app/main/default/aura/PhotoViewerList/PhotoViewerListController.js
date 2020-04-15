({
    onInit: function(cmp, evt, h) {
        h.init(cmp);
    },

    onPhotosChanged: function(cmp, evt, h) {
        h.photosChanged(cmp);
    },

    onBeginExport: function(cmp, evt, h) {
        h.beginExport(cmp, evt);
    },

    onCancelExport: function(cmp, evt, h) {
        h.cancelExport(cmp, evt);
    },

    onPhotoClick: function(cmp, evt, h) {
        h.photoClick(cmp, evt);
    },

    onGenerateZip: function(cmp, evt, h) {
        h.generateZip(cmp, evt);
    },

    onExportToPPT: function(cmp, evt, h){
        h.exportToPPT(cmp);
    },

    onShowMore: function(cmp, evt, h) {
        h.showMore(cmp, evt);
    },

    onExportOnePhoto: function(cmp, evt, h) {
        h.exportOnePhoto(cmp, evt);
    },

    onRunPptxConversion: function(cmp, evt, h){
        h.runPptxConversion(cmp);
    },

    onDestroy: function(cmp, evt, h) {
        h.destroy(cmp, evt);
    },

    onPptxExportCompleted: function(cmp, evt, h){
        h.pptxExportCompleted(cmp, evt);
    }
})