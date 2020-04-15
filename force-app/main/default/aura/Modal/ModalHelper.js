({
  configureModal: function(component, event, helper) {

    //window.supressHeader();
    //var someId = document.querySelector("#someId");
    //console.log(someId, "someId");

    // Set title (modal properties)
    var modalProperties = event.getParam("modalProperties");
    console.log(modalProperties, "modalProperties");
    component.set("v.modalProperties", modalProperties);

    // Set header
      if (modalProperties.showHeader) {
          component.set("v.showHeader", modalProperties.showHeader);
      }  
      
    // Set size
    if (modalProperties.size == "large") {
      var modal = component.find("modaldialog");
      $A.util.addClass(modal, "slds-modal--large");
    } else {
      var modal = component.find("modaldialog");
      $A.util.removeClass(modal, "slds-modal--large");
    }

    // Set offset
    if (modalProperties.offsetFromHeader == true) {
      var modal = component.find("modaldialog");
      $A.util.addClass(modal, "header-offset");
    } else {
      var modal = component.find("modaldialog");
      $A.util.removeClass(modal, "header-offset");
    }
    
  },
  toggleClass: function(component, componentId, className) {
    var modal = component.find(componentId);
    $A.util.removeClass(modal, className + 'hide');
    $A.util.addClass(modal, className + 'open');
  },
  toggleClassInverse: function(component, componentId, className) {
    var modal = component.find(componentId);
    $A.util.addClass(modal, className + 'hide');
    $A.util.removeClass(modal, className + 'open');
  },

  loadComponent: function(component, event, helper) {
    var modalComponentName = event.getParam("modalComponentName"),
      modalComponentProperties = event.getParam("modalComponentProperties");
    console.log(modalComponentProperties, "modalComponentProperties");
    $A.createComponent(
      modalComponentName,
      modalComponentProperties,
      function(newComponent, status, errorMessage) {
        //Add the new button to the body array
        if (status === "SUCCESS") {
          component.set("v.body"
, new Array(newComponent));
        } else if (status === "INCOMPLETE") {
          console.log("No response from server or client is offline.");
          // Show offline error
        } else if (status === "ERROR") {
          console.log("Error: " + errorMessage);
          // Show error message
        }
      }
    );
  }
})