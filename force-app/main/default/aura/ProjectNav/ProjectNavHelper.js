({
    setCurrentPage: function(component, event, helper) {

        helper.clearTabs();
        event.currentTarget.className += " current-page";

    },
    initProjectContext: function(component, event, helper) {
        var inititalContext = "detail";
        component.set("v.projectContext", inititalContext);
        helper.clearTabs();
        helper.setTab(component, inititalContext);

    },
    clearTabs: function() {
        var elems = document.querySelectorAll(".menu-item");
        [].forEach.call(elems, function(el) {
            el.classList.remove("current-page");
        });
    },
    setTab: function(component, tab) {
        var servicesTab = component.find(tab);
        //console.log(servicesTab.getGlobalId, "<<< servicesTab");
        $A.util.addClass(servicesTab, 'current-page');
    },

    statusChanged: function(cmp) {
        var status = cmp.get('v.projectStatus');
        var rules = ['In Progress', 'Ended', 'Closed', 'Canceled'];
        cmp.set(
            'v.showPhotoViewer', rules.indexOf(status) !== -1
            ? true
            : false);
    }
})