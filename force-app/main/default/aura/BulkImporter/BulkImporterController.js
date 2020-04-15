({
    onInit: function(cmp, evt, helper){
        helper.init(cmp);
    },

    onSelectFile: function(cmp, evt, helper) {
        helper.selectFile(cmp, evt);
    },

    onChangeFile: function(cmp, evt, helper) {
        helper.onChangeFile(cmp, evt);
    },

    onImportData: function(cmp, evt, helper){
        helper.onImportRequest(cmp, evt);
    },

    onCancel: function(cmp, evt, helper) {
        helper.closeDialog(cmp);
    }
})