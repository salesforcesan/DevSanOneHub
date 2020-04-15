({   getInvoiceInfo : function(component, event, invoice) {
    this.showSpinner(component);
   var recordId = component.get("v.recordId");

    
    if (recordId != undefined && recordId != ''){
        var action = component.get("c.getInvoiceInfoApex");
        action.setParams({
            'invoiceId': recordId
        });
        
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){ 
                var res = JSON.parse(response.getReturnValue());
                if(!$A.util.isEmpty(res)) {            
                    if (res[0].Status != 'Created'){
                        component.set("v.showSaveInvoice", false);   
                    }
                    component.set("v.invoiceInfo", res[0]);   
                }   
            } else if (state === 'ERROR'){
                this.errorMessage(component, 'Error', response);
            }
        });
        $A.enqueueAction(action);
    }
}, 
  getActiveGroupedInvoices : function(component, event, invoice) {
      this.showSpinner(component);
      //var initialRows = component.get('v.initialRows');
      var action = component.get("c.getActiveGroupedInvoicesApex");
      action.setCallback(this, function(response){
          this.hideSpinner(component);
          var state = response.getState();
          if(state === 'SUCCESS'){ 
              var res = JSON.parse(response.getReturnValue());
              if(!$A.util.isEmpty(res)) {
                  res.map(item => item.Selected = false);
                  component.set("v.availableGroupedInvoices", res);   
              }   
          } else if (state === 'ERROR'){
              this.errorMessage(component, 'Error', response);
          }
      });
      $A.enqueueAction(action);
      
  },
  getNameSpace: function(cmp) {
      var action = cmp.get("c.getNamespaceApex");
      action.setCallback(this, function(response) {
          if($A.util.isEmpty(response.getReturnValue())){
              cmp.set("v.ns", ''); 
          } else {
              cmp.set("v.ns", response.getReturnValue()); 
              console.log('ns: ', response.getReturnValue());
          }
          
      });
      $A.enqueueAction(action);
  },
  getInvoices : function(component, event, helper) {
      this.showSpinner(component);
      
      var allAvailable = component.get('v.availableGroupedInvoices');
      var action = component.get("c.GetGroupedProjectInvoicesApex");
      
      var serachList = component.get('v.SearchWrapper');                
      var serach = serachList[0];
      var invoice = serach.InvoiceId;
      
      action.setParams({
          'groupedInvoiceId': serach.InvoiceId,
      });
      
      action.setCallback(this, function(response){
          this.hideSpinner(component);
          var state = response.getState();
          if(state === 'SUCCESS'){  
              var res = JSON.parse(response.getReturnValue());
              var sObjectName = '';
              if(!$A.util.isEmpty(res)) {
                  var current = [];
                  var currentIds = [];
                  var allInvoices = [];
                  
                  
                  
                  res.forEach(function(item) {
                      
                      if ((sObjectName == '')){ sObjectName = item.sObjectAPIName; }
                      
                      if(item.GroupedProjectInvoice === invoice) {
                          currentIds.push(item.Id);
                          current.push(item);
                      } else{
                          allInvoices.push(item);
                      }
                      return item;
                  });
                  if(!$A.util.isEmpty(current)){
                      current.forEach(item => allInvoices.unshift(item));
                  };
                  
                  allAvailable.forEach(item => item.Id === invoice ? item.Selected = true : item.Selected = false); 
                  allInvoices.forEach(item => item.recordLink = '/'+ item.ProjectId);
                 
                  
                  component.set('v.sObjectName', sObjectName);
                  component.set('v.availableGroupedInvoices', allAvailable);
                  component.set('v.selectedGroup', invoice);                    
                  component.set("v.invoices", allInvoices);
                  
                  component.set("v.filterData", allInvoices);
                  
                  console.log(JSON.stringify(allInvoices));
                  
                  if(!$A.util.isEmpty(currentIds)){
                      console.log('current: ', current);
                      component.set('v.selectedInvoices', current);
                      component.set('v.initialGroupedCount', currentIds.length);    
                      component.set('v.selectedRows', currentIds);
                      component.set('v.selectedRowsCount', currentIds.length);
                  }
                  
                  console.log('selected default', component.get('v.selectedRows'));
                  
              }  else {
                  component.set('v.selectedGroup', '');
                  component.set("v.invoices", null);
                  component.set("v.filterData", null);
              }         
          } else if (state === 'ERROR'){
              this.errorMessage(component, 'Error', response);
          }
      });
      $A.enqueueAction(action);
  }, 
  
  manageGroupInvoice : function(component, event, helper) {
      
      var invoices = component.get("v.invoices");        
      var groupInvoiceType = component.get("v.groupInvoiceType"); 
      
      if ((invoices == null) || (invoices.length == 0 && groupInvoiceType == 'New')){          
         var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({                
              message: "No invoice available for grouping.",
              type: "error"
          });
          toastEvent.fire();
          this.hideSpinner(component);
          return;
      }
      
      
      if (invoices.length == 0){          
          helper.openMessageBox(component, event, helper);
          return;
      }

      
      if (invoices.length == 1){
          
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({                
              message: "Cannot create or save a group invoice with less than 2 invoices.",
              type: "error"
          });
          toastEvent.fire();
          this.hideSpinner(component);
          return;
      } 
      
    
      var action = component.get("c.manageGroupInvoice");
      var recordId = component.get("v.recordId");
      var groupInvoiceType = component.get("v.groupInvoiceType");
 
      this.showSpinner(component);
      
      if (groupInvoiceType === 'New'){
          recordId = '';
      }
      
      action.setParams({
          'invoiceId': recordId,
          'groupedInvoiceIds': JSON.stringify(invoices),
      });
      
      action.setCallback(this, function(response){
          this.hideSpinner(component);
          var state = response.getState();
          
          if(state === 'SUCCESS'){  
              this.showToast('Success','You successfully grouped the invoices','success' );    
              var res = response.getReturnValue();
              if(res != ''){
                  var navEvt = $A.get("e.force:navigateToSObject");
                  navEvt.setParams({
                      "recordId": res
                  });
                  navEvt.fire();
              }
              
          } else if (state === 'ERROR'){
              
              this.errorMessage(component, 'Error', response);
          }
      });
      $A.enqueueAction(action);
      
      this.getInvoices(component, event, helper); 
      
  },
  
 
  updateGroupInvoice : function(component, event, helper) {
      
      this.showSpinner(component);
      
      var invoices = component.get("v.invoices");        
      
      var action = component.get("c.manageGroupInvoice");
      var recordId = component.get("v.recordId");
      var groupInvoiceType = component.get("v.groupInvoiceType");
      
      if (groupInvoiceType === 'New'){
          recordId = '';
      }
      
      action.setParams({
          'invoiceId': recordId,
          'groupedInvoiceIds': JSON.stringify(invoices),
      });
      
      action.setCallback(this, function(response){
          this.hideSpinner(component);
          var state = response.getState();
          
          
          if(state === 'SUCCESS'){  
              this.showToast('Success','You successfully grouped the invoices','success' );    
              var res = response.getReturnValue();
             
              var homeEvent = $A.get("e.force:navigateToObjectHome");
              homeEvent.setParams({
                  "scope": component.get('v.sObjectName')
              });
              homeEvent.fire();
              
          } else if (state === 'ERROR'){
              this.errorMessage(component, 'Error', response);
          }
      });
      $A.enqueueAction(action);
      
      this.getInvoices(component, event, helper); 
     
  },
 
  
  updateGroupedInvoice : function(component, event, invoiceIds, groupedId) {
      this.showSpinner(component);
      
      var action = component.get("c.getInvoicesApex");
      action.setParams({
          'invoiceIds':invoiceIds,
          'groupedInvoiceId': groupedId,
      });
      action.setCallback(this, function(response){
          this.hideSpinner(component);
          var state = response.getState();
          if(state === 'SUCCESS'){  
              this.showToast('Success','You successfully grouped the invoices','success' ); 
              //this.getInvoices(component, event, groupedId);
              this._navigateHandler(component, groupedId);
              //this._closeActionDialog(component);
          } else if (state === 'ERROR'){
              this.errorMessage(component, 'Error', response);
          }
      });
      $A.enqueueAction(action);
      
      
  },
  
  showToast : function(title, message, type) {
      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
          "message": message,
          "type": type
      });
      toastEvent.fire();
  },
  
  errorMessage: function(cmp, messageTitle, response) {
      var message;
      console.log(response.getError());
      var errors = response.getError();
      if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
      if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;
      
      this.showToast(messageTitle, message, 'error');  
  },
  
  
  sortData: function (cmp, fieldName, sortDirection, invoices) {
      var reverse = sortDirection !== 'asc';
      invoices.sort(this.sortBy(fieldName, reverse))
      return invoices;
  },
  
  sortBy: function (field, reverse, primer) {
      var key = primer ?
          function(x) {return primer(x[field])} :
      function(x) {return x[field]};
      reverse = !reverse ? 1 : -1;
      return function (a, b) {
          return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
      }
  },
  
  showSpinner: function(component) {
      var spinner = component.find("lilspin");
      $A.util.removeClass(spinner, "slds-hide");
  },
  
  hideSpinner: function(component) {
      var spinner = component.find("lilspin");
      $A.util.addClass(spinner, "slds-hide");
  },
  
  _closeActionDialog: function(cmp) {
      var dismissActionPanel = $A.get("e.force:closeQuickAction");
      dismissActionPanel.fire();
  },
  _navigateHandler: function(cmp, recordId) {
      var ns = cmp.get('v.ns');
      var navService = cmp.find("navService");
      // Sets the route to /lightning/o/Account/home
      navService.navigate({
          type: 'standard__recordPage',
          attributes: {
              objectApiName: ns + 'ProjectInvoice__c',
              recordId: recordId,
              actionName: 'view'
          }
      }, true); 
  },
  createGroupedInvoice: function(cmp, event){
      var ns = cmp.get('v.ns');
      var groupedInvoice = $A.get("e.force:createRecord");
      if($A.util.isEmpty(ns)) {
          groupedInvoice.setParams({
              "entityApiName": "ProjectInvoice__c",
              "defaultFieldValues": {
                  'IsGroupedInvoice__c' : true,
                  'Status__c' : 'Created',
                  'Description__c' : 'My New Grouped Invoice Description'
              }
          });   
      } else {
          groupedInvoice.setParams({
              "entityApiName": "CMKOneHub__ProjectInvoice__c",
              "defaultFieldValues": {
                  'CMKOneHub__IsGroupedInvoice__c' : true,
                  'CMKOneHub__Status__c' : 'Created',
                  'CMKOneHub__Description__c' : 'My New Grouped Invoice Description'
              }
          });  
      }
      
      groupedInvoice.fire();
  },
  toggleFilter: function(cmp, e, helper) {
      var filters = cmp.find('filters');
      var arrow = cmp.find('arrowDownTop');
      var elem = filters.getElement();
      var arrowElem = arrow.getElement();
      this.collapsedTest(elem, arrowElem); 
  },expandSection: function(elem, arrowElem) {
      var sectionHeight = elem.scrollHeight;
      elem.style.height = sectionHeight + 'px';
      elem.style.transform = 'translateY(10px)';
      arrowElem.style.transform = 'rotate(0deg)';
      elem.style.overflow = 'hidden';
      elem.style.opacity = 1;
      
      
      setTimeout(function(){
          elem.style.overflow = 'visible';
          elem.style.height = 'auto';
          elem.setAttribute('data-collapsed', 'false');
      }, 420);
  },
  collapseSection: function(elem, arrowElem) {
      
      var sectionHeight = elem.scrollHeight;
      var elementTransition = elem.style.transition;
      elem.style.transition = '';
      requestAnimationFrame(function() {
          elem.style.height = sectionHeight + 'px';
          elem.style.transition = elementTransition;
          
          requestAnimationFrame(function() {
              elem.style.height = 0 + 'px';
              elem.style.transform = 'translateY(0px)';
              
              arrowElem != null ? arrowElem.style.transform = 'rotate(-90deg)' : '';
              elem.style.opacity = 0;
          });
      });
      
      elem.setAttribute('data-collapsed', 'true');
  },
  
  collapsedTest: function(elem, arrowElem, helper) {
      
      var isCollapsed = elem.getAttribute('data-collapsed') === 'true';
      elem.style.overflow = 'hidden';
      if (isCollapsed) {
          this.expandSection(elem, arrowElem);
      } else {
          this.collapseSection(elem, arrowElem);
      }    
  },
  handleSearch: function(component, event, helper) {
      let search = component.find("search").get("v.value");
      //const data = component.get('v.filterData');
      
      const data = component.get('v.invoices');
      
      if (!search || search == '') {
          
          component.set('v.invoices', data);
          this.getInvoices(component, event, helper); 
          
      }
      else{
          const filterByValue = (array, string) => 
              array.filter(values =>
                           Object.keys(values).some(item => values[item] != null && values[item].toString().toLowerCase().includes(string.toLowerCase())
                                                   ));
          
          var filteredList = filterByValue(data, search);            
          component.set('v.invoices', filteredList); 
      }
  },
  openMessageBox: function(component, event, helper) {
        var projectAccount = component.get("v.projectAccount");
        var self = this;
        
        var bodyText='';
        var prompt = component.find('messageBox');                
        
 
            bodyText =  'Removing all project invoice will delete the grouped invoice<p>Are you sure that you want to remove all project invoice?</p>'; 
            prompt && prompt.show({
                id: 'updateProjectInvoice',
                title: 'Delete Grouped Invoice',
                body: bodyText,
                positiveLabel: 'Confirm',
                negativeLabel: 'No',
                severity: 'error'
        	});
        
    },
    handleMessageBoxEvent: function(component, evt, helper) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'updateProjectInvoice' && result.value == 1) {
            this.updateGroupInvoice(component, evt, helper);
        }

    },
 })