({
    updatePreview : function(component, event, helper) {
        alert('this works somehow');
        //controller="TreeSampleController" 
        //var action = component.get("c.getData");
        //action.setCallback(this, function(response){
            //var state = response.getState();
            //if (component.isValid() && state === "SUCCESS"){
               // component.set("v.questions", JSON.parse(response.getReturnValue()));
                //console.log('questions on tree=' + component.get("v.questions"));                                
                var data = component.get("v.questions");
        		if(data!=null){                    
                
               	var obj = data.filter(d=>d.JumpToAction==='BRANCH');
                obj.forEach(cValue =>{                    
                    cValue.DefinedResponses.forEach(function(dr,indx,drArr){
                        if(dr.JumpToQuestion!='RETURN'){                        
                        var axq = [];
                        dr.AllowedJumpToQuestions.forEach(ajq=>{                            
                            if(ajq.Text!='RETURN'){
                             	var n = data.find(x=>x.QuestionId===ajq.Text);
                            	if(n!=null)
	                            {		
    	                            axq.push({"QuestionNumber":n.QuestionNumber, "QuestionText":n.QuestionText});
                    				axq.push({"IsBranchQuestion":true});
            	                }
                            }
                        });
                        //console.log(axq);
                        if(axq.length>0)
                            drArr[indx].FollowUpQuestions = axq;
                        }
                    });                 
                });                                
                	component.set("v.questions", data);
					console.log('Preview Updated=' + JSON.stringify(data));
				}	
            //}
            //else
             //   console.log(response);
        //});
        //$A.enqueueAction(action);
    },
	updateSurveyPreview : function(component,event,helper) {
         class previewElement{
            constructor(rank,text,type,number) {    
                this.rank = rank;
                this.text = text;
                this.type = type;
                this.number = number;
            }
        };
        
        class surveyProcessor{
            constructor(questions)
            { 
                this.indent = 1;
                this.preview = []; 
                this.questions = questions; 
                this.currentQuestion = null;
            }
        };
        
        surveyProcessor.prototype.processSurvey = function (){	
            this.questions.forEach(this.processQuestion, this);
            return this.preview;
        };
		surveyProcessor.prototype.processQuestion = function (question, indent){   
            console.log(question, this.questions);             
            if((question.Active != false) && (!question.parents || (question.parents.includes(this.currentQuestion.QuestionNumber) && this.indent > 1)))
            { 
                this.currentQuestion = question;
                this.preview.push(new previewElement(this.indent, question.QuestionText, "question", question.QuestionNumber));
                if(question.JumpToAction === "BRANCH")
                {
                    question.DefinedResponses.forEach(function(dr){                       
                        if(dr.Active != false)
                        {                                                                               
                            this.preview.push(new previewElement(++this.indent, dr.DefinedResponseText, "definedResponse", 0));                                
                            if(dr.JumpToQuestion != "RETURN")
                            {   
                                this.questions.slice(dr.JumpToQuestionNumber-1).some(function(continueQuestion){                                   
                                    if(!continueQuestion.parents || continueQuestion.parents.includes(question.QuestionNumber))
                                    {   
                                        continueQuestion.parents = [].concat(continueQuestion.parents, question.parents, [question.QuestionNumber]);
                                        this.indent += 1;
                                        this.processQuestion(continueQuestion);
                                        this.currentQuestion = question;
                                        this.indent -= 1;                                                
                                        return continueQuestion.JumpToAction != "CONTINUE";
                                    }
                                }, this);                            
                            }
                        }
                        this.indent -= 1;  
                    }, this);
                }
            }
        }
        component.set("v.previewElements", new surveyProcessor(component.get("v.questions")).processSurvey());
        console.log('Preview Updated!!');
	}
})