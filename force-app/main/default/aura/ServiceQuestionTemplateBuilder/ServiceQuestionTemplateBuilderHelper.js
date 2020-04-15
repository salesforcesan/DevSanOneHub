({
    
  'AddQuestionDialogSetting': {
    'id': 'dlgAddQuestion',
    'component': 'c:AddSurveyQuestionModal',
    'size': 'x-medium',
    'title': 'Add Survey Question'
  },
  'EditQuestionDialogSetting': {
    'id': 'dlgEditQuestion',
    'component': 'c:EditSurveyQuestionModal',
    'size': 'medium',
    'title': 'Edit Survey Question'
  },
  getService: function(component) {
    var message;
    var messageTitle;
    var serviceid = component.get("v.recordId");

    var action = component.get("c.getServiceApex", []);
    action.setParams({
      "serviceid": serviceid
    });
    console.log(action);
    var self = this;
    action.setCallback(self, function(result) {
      var state = result.getState();
      messageTitle = 'Server Message';
      message = '';
      if (state === "SUCCESS") {

        var service = JSON.parse(result.getReturnValue());

        component.set("v.service", service);
        component.set("v.servicename", service.ServiceName);
        component.set("v.servicetitle", service.ServiceTitle);
           component.set("v.surveyTemplateVersion", service.SurveyTemplateVersion);
      } else {

        console.log(result.getError());

        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;

        this._notify(component, message, 'error');


      }

    });
    $A.enqueueAction(action);
  },
  getServiceQuestions: function(component) {

    var message;
    var messageTitle;
    var serviceid =  component.get("v.recordId");

    var action = component.get("c.getServiceQuestionsApex", []);
    action.setParams({
      "serviceid": serviceid
    });
    console.log(action);
    var self = this;
    action.setCallback(self, function(result) {
      var state = result.getState();
      messageTitle = 'Server Message';
      message = '';
      if (state === "SUCCESS") {
        var responseWrapper = JSON.parse(result.getReturnValue());
        var questions = responseWrapper.Data;
        component.set("v.questions", questions);
      } else {
        console.log(result.getError());

        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;

        this.showToast(messageTitle, message, 'error');


      }

    });
    $A.enqueueAction(action);
  },
  editServiceQuestion: function(component) {

    var message;
    var messageTitle;
    var spinner = component.find("spinner");  
	$A.util.removeClass(spinner, "slds-hide");
      
    var question = JSON.stringify(component.get("v.question"));  

    var action = component.get("c.saveServiceQuestion", []);      
    action.setParams({
        "questionWrapperInput": question});
    console.log(action);  
    var self = this;
    action.setCallback(self, function(result) {
        
	  $A.util.addClass(spinner, "slds-hide");
        
      var state = result.getState();
      messageTitle = 'Server Message';
      message = '';
      if (state === "SUCCESS") {

        message = "Sucessfully saved question changes";  	
        this.showToast(messageTitle, message, 'success');

        var responseWrapper = JSON.parse(result.getReturnValue());
        var questions = responseWrapper.Data;
        component.set("v.questions", questions);
      } 
      else 
      {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;

        this.showToast(messageTitle, message, 'error');
      }
    });
    $A.enqueueAction(action);
  },   
  addServiceQuestion: function(component) {
      
    var message;
    var messageTitle;
    var spinner = component.find("spinner");  
	$A.util.removeClass(spinner, "slds-hide");
      

    var serviceid = component.get("v.recordId");
    var questionid = component.get("v.questionId");

    var action = component.get("c.addServiceQuestion", []);
    action.setParams({
      "serviceid": serviceid,
      "questionid": questionid
    });
    console.log(action);
    var self = this;
    action.setCallback(self, function(result) {
      var state = result.getState();
      messageTitle = 'Server Message';
      message = '';
	  $A.util.addClass(spinner, "slds-hide");
      if (state === "SUCCESS") {

        message = "Sucessfully added the question";  	
        this.showToast(messageTitle, message, 'success');

        var responseWrapper = JSON.parse(result.getReturnValue());
        var questions = responseWrapper.Data;
        component.set("v.questions", questions);
      } 
      else 
      {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;

        this.showToast(messageTitle, message, 'error');
      }
    });
    $A.enqueueAction(action);
  },
  removeServiceQuestion: function(component, servicequestionid) {

    var message;
    var messageTitle;
    var spinner = component.find("spinner");  
	$A.util.removeClass(spinner, "slds-hide");      

    var action = component.get("c.deleteServiceQuestion", []);
    action.setParams({
      "servicequestionid": servicequestionid
    });
    console.log(action);
    var self = this;
    action.setCallback(self, function(result) {
      
      var state = result.getState();
	  $A.util.addClass(spinner, "slds-hide");        

      messageTitle = 'Server Message';

      if (state === "SUCCESS") 
      {
        message = "Sucessfully removed the question";  	
        this.showToast(messageTitle, message, 'success');
      	var responseWrapper = JSON.parse(result.getReturnValue());
        var questions = responseWrapper.Data;
        component.set("v.questions", questions);
      } 
        else {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;
        this.showToast(messageTitle, message, 'error');
        
      }

    });
    $A.enqueueAction(action);
  },
  saveQuestionChanges: function(component) {
      
    var message;
    var messageTitle;
    var spinner = component.find("spinner");  
	$A.util.removeClass(spinner, "slds-hide");      
      

    var questions = JSON.stringify(component.get("v.questions"));

    var action = component.get("c.saveServiceQuestionsChanges", []);

    action.setParams({
      "questionListWrapperInput": questions
    });
    console.log(action);
    var self = this;

    action.setCallback(self, function(result) {

      $A.util.addClass(spinner, "slds-hide");              
      var state = result.getState();
      messageTitle = 'Server Message';

      if (state === "SUCCESS") {
        message = 'Changes saved successfully.';
        this.showToast(messageTitle, message, 'success');
      } else {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;
        this.showToast(messageTitle, message, 'error');
        self.getServiceQuestions(component);
      }
    });
    $A.enqueueAction(action);
  },
  showEditQuestionModal: function(cmp, questions, recordId){
    this._renderDialog(cmp, this.EditQuestionDialogSetting,{
      'recordid': recordId,
      'questions': questions
    });
  },

  showAddQuestionModal: function(cmp) {
    this._renderDialog(cmp, this.AddQuestionDialogSetting, {'recordId': cmp.get('v.recordId')});
  },

  showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
    	toastEvent.fire();
  },    
  _notify: function(cmp, msg, type, autoHide, duration) {
    cmp.find('notification').show(msg, type, autoHide, duration);
  },
  _renderDialog: function(root, dialogDefinition, params) {
    var dlg = root.find('modalDialog'),
    	self = this,
   	args = (!!params) ? this._cloneObject(params) : {};
    args['dialogId'] = dialogDefinition.id;

    $A.createComponent(dialogDefinition.component, args,
      function(cmp, status, errMsg) {
        if ('SUCCESS' === status) {
          dlg.set('v.title', dialogDefinition.title);
          dlg.set('v.size', dialogDefinition.size);
          dlg.set('v.brand', dialogDefinition.brand || '');
          dlg.set('v.body', cmp);
          dlg.show();
        } else if ('ERROR' === status) {
          self._notify(root, errMsg, self.NOTIFICATION_TYPES.ERROR);
        }
      });
  },
  _cloneObject: function(obj) {
    var t = {};
    for (var nm in obj) {
      t[nm] = obj[nm];
    }
    return t;
  },
  async: function(cmp, callback, duration) {
    if (!callback) {
      return;
    }
    duration = duration || 250;
    var id = window.setTimeout($A.getCallback(function() {
      window.clearTimeout(id);
      if (cmp.isValid()) {
        callback(cmp);
      }
    }), duration);
  }
})