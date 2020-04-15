({
  init: function(component, event, helper) {
    //{
    //    menuId : "overview",
    //    classId : "fa-handshake-o",
    //    menuLabel : "Service Overview"
    //},
    var menuItems = [

      {
        menuId: "instructions",
        classId: "fa-file-text",
        menuLabel: "Service Details"
      }, {
        menuId: "tools",
        classId: "fa-wrench",
        menuLabel: "Tools"
      }, {
        menuId: "certifications",
        classId: "fa-certificate",
        menuLabel: "Certifications"
      }, {
        menuId: "targets",
        classId: "fa-bullseye",
        menuLabel: "Targets"
      }, {
        menuId: "survey",
        classId: "fa-list-alt",
        menuLabel: "Survey"
      }
    ];
    component.set("v.menuItems", menuItems);
    helper.setProjectServiceContext(component);
  },

  navTo: function(component, event, helper) {
    event.preventDefault();
    event.stopPropagation();
    component.set("v.projectServiceContext", event.currentTarget.id);

    // Set correct tab on the menu
    var elems = document.querySelectorAll(".menu-item");
    [].forEach.call(elems, function(el) {
      el.classList.remove("current-page");
    });
    event.currentTarget.className += " current-page";

    // Fire event
    var userevent = component.getEvent("changeProjectServiceContext");
    userevent.setParams({
      "context": event.currentTarget.id
    });
    userevent.fire();

  },

  goBackToProject: function(component, event, helper) {
    var gobackRequest = component.getEvent('gobackToProject');
    gobackRequest.setParams({
      id: 'gobackToProject'
    });
    gobackRequest.fire();

  },
  
  closeNav: function(component, event, helper) {
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
  }
})