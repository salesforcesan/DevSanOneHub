({
	helperMethod : function() {
		
	},
    Init:function(component, event, helper){
        var questions = component.get("v.questions");
        console.log('edit questions: ', questions);
         var hiddenElement = component.get("v.hiddenElement"); 
         if(!!hiddenElement && hiddenElement["ProjectServiceQuestions__c.NoReadonly"])
            {
               
                component.set("v.securityDisabled", true);         
            }
            else
            {
                   component.set("v.securityDisabled", false);  
            }
       	
		var psqid = component.get("v.recordid"); 
        if(questions[0].isProjectService === true) {
            component.set('v.isProjectService', true);
        }
        var question = questions.filter(item => item.ProjectServiceQuestionId === psqid);
        component.set("v.question",question[0]);
       /* for (var i = 0; i < questions.length; i++) { 
            var question = questions[i];
            if (question.ProjectServiceQuestionId === psqid)
            {
               
            }
        } */
    },
    getAILabelOptions: function(component, event, helper) {
    	var action = component.get('c.getAILabelOptions') ;
        var question = component.get('v.question'); 
        console.log('question: ', question);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                if(!($A.util.isEmpty(response.getReturnValue()))){
                    var rw = response.getReturnValue();
                    rw.forEach(item => item.Selected = item.Id === question.AILabelId ? true : false);
                    console.log('Get option model ', rw);
                    component.set("v.options",rw);    
                }             
            }
          
            if (state === 'ERROR') {
                console.log('error');
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    //self._msgBox('error', errors[0].message);
                } 
            }
            //  self._msgBox('error', 'The system runs into an error. Please refresh the component.');
            
        });
        $A.enqueueAction(action);
    },
    clone: function(q){
        var obj = {};
        Object.keys(q).forEach(function(k){
            obj[k] = q[k];
        });
        return obj;
    },
    
    isempty:function(component,inputValue,message)
    {
        var isemptycheck;
        if(inputValue === "" ||inputValue === null)
            {
  
                 this.showError(component,message)
                 return isemptycheck = true;
                
            }
            else
            {
                return isemptycheck = false;
            }
    },
    showError:function(component,message){
       var self = this;
          self.showToast(message,'error');
        
    },
    
    showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
    	toastEvent.fire();
  },         
       
})