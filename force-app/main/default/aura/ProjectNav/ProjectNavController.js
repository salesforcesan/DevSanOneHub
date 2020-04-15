({
    init: function(component, event, helper) {
        helper.initProjectContext(component, event, helper);
    },
    toggleNav: function(component, event, helper) {
        var navWidth = document.querySelectorAll('.navWrap'),
            i;
        var navBtn = document.querySelectorAll('.closebtn'),
            i;
        var navText = document.querySelectorAll('.nav-text'),
            i;
        for (var i = 0; i < navText.length; i++) {
            navText[i].classList.toggle("gone");
        }
        for (var i = 0; i < navWidth.length; i++) {
            navWidth[i].classList.toggle("small");
        }
        for (var i = 0; i < navBtn.length; i++) {
            navBtn[i].classList.toggle("change");
        }
    },
    navTo: function(component, event, helper) {

        component.set("v.projectContext", event.currentTarget.id);
        helper.setCurrentPage(component, event, helper, event.currentTarget.id);
    },

    onStatusChanged: function(cmp, evt, h) {
        h.statusChanged(cmp);
    }
})