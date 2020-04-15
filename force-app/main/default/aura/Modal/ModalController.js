({
  doInit: function(component) {

    // Force the modal not to slip under the header
    /*
    var windowSize = window.innerHeight,
        maxHeightModal = windowSize - 180; // This is a hack: header size * 2
    component.set("v.modalMaxHeight", maxHeightModal);
    */
    // style="{! 'max-height:' + v.modalMaxHeight + 'px;'}"
    // <aura:attribute name="modalMaxHeight" type="String"/>
    // 
  },
  showModal: function(component, event, helper) {
    // On of many vain attempts at overrriding the Saleforce header
    /*
        var header = document.getElementById("someId");
        console.log(header, "header");
        $A.util.addClass(header, "main-header");
    */
    // Override Salesforce header
    component.set("v.zindex", "0");

    //Toggle CSS styles for opening Modal
    helper.configureModal(component, event, helper);
    helper.loadComponent(component, event, helper);
    helper.toggleClass(component, 'backdrop', 'slds-backdrop--');
    helper.toggleClass(component, 'modaldialog', 'slds-fade-in-');
  },
  hideModal: function(component, event, helper) {

    // Override Salesforce header
    component.set("v.zindex", "5");

    //Toggle CSS styles for hiding Modal
    helper.toggleClassInverse(component, 'backdrop', 'slds-backdrop--');
    helper.toggleClassInverse(component, 'modaldialog', 'slds-fade-in-');
    component.set("v.body", []);
  },

  destoryCmp: function(component, event, helper) {
    component.destroy();
    console.log('destroy model fired');
  },
})