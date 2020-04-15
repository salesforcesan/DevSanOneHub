({
    helperMethod : function() {
        
    },
    Init:function(component, event, helper){
        var questions = component.get("v.questions");
        var psqid = component.get("v.recordid"); 
        var question = questions.filter(item => item.ProjectServiceQuestionId === psqid);
        component.set("v.question", question[0]);
        /* for (var i = 0; i < questions.length; i++) { 
            var question = questions[i];
            if (question.ProjectServiceQuestionId === psqid)
            {
                component.set("v.question",this.clone(question));
                //console.log('SR: ' + component.get("v.question").ServiceQuestionRule.SqOperator)
            }
        }*/
        component.set('v.selectedValue', question[0].AILabelId);
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
                    // self._msgBox('error', errors[0].message);
                } 
            }
            //  self._msgBox('error', 'The system runs into an error. Please refresh the component.');
            
        });
        $A.enqueueAction(action);
    },
    
    getServiceQuestionRule:function(component, event, helper)
    {
        var self = this;
        // self.showSpinner(component);
        var serviceQuestionId = component.get("v.recordid");
        var action = component.get("c.GetServiceQuestionRule");
        action.setParams({
            "serviceQuestionId": serviceQuestionId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (!component.isValid()) {
                console.log('not sucess');
                // self._msgBox('error', 'The component is out of scope.');
                return;
            }
            //self.hideSpinner(component);
            if (state === 'SUCCESS') {
                if(!($A.util.isEmpty(response.getReturnValue()))){
                    var responseWrapper = JSON.parse(response.getReturnValue());
                    console.log('Get SQL Rule');
                    component.set("v.ServicequestionRule",responseWrapper);
                    
                }
                return;
                
            }
            
            if (state === 'ERROR') {
                console.log('error');
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    // self._msgBox('error', errors[0].message);
                } else {
                    //  self._msgBox('error', 'The system runs into an error.');
                }
                return;
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
            "type": type,            
        });
        toastEvent.fire();
    },  
    
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type,autoHide, duration, true);
    },
       
    
})