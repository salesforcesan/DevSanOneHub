({   
    togglePreview : function(component, event, helper) {
        
        $A.util.toggleClass(component.find("panel"), "drawer-hide");          
        
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
            
            var previousElement = null;
            var indent = 1;
            var tree = [];
            var parent = tree;
            this.preview.forEach( 
                function(element)
                {
                    if(element.type == 'question')
                    {
                        //element.text = 'Q' + element.number +': ' + element.text
                        element.QuestionNumber = element.number;
                    }
                    
                    if(element.rank == indent)
                    {
                        if(!parent.children)
                        {
                            parent.children = [];
                        }
                        parent.children.push(element);
                        element.parent = parent;
                        previousElement = element;
                        
                    }
                    else if (element.rank > indent)
                    {
                        if(!previousElement.children)
                        {
                            previousElement.children = [];
                        }
                        indent = element.rank;
                        previousElement.children.push(element);
                        element.parent = previousElement;
                        parent = previousElement;
                        previousElement = element;
                    }
                        else if (element.rank < indent)
                        {
                            for (i = indent; i > element.rank; i--) {                            
                                parent = parent.parent;                           
                            }
                            parent.children.push(element);
                            element.parent = parent;
                            previousElement = element;
                            indent = element.rank;
                        }                    
                }            
            )            
            
            component.set("v.tree", tree);
            
            return this.preview;
        };
        
        surveyProcessor.prototype.processQuestion = function (question){   
            
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
                                    if(dr.JumpToQuestion == continueQuestion.QuestionId || !continueQuestion.parents || continueQuestion.parents.includes(question.QuestionNumber))
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
                            this.indent -= 1;
                        }                          
                    }, this);
                }
            }
        }
        
        component.set("v.previewElements", new surveyProcessor(component.get("v.questions")).processSurvey());
        
        
        
        
        
        
        
        
        
        
        
    }
})