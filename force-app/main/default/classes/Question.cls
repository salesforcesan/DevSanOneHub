/** Class: question
    *  Retrieves the question information and puts it in the question object
    */      
    public class Question
    {
        public String   name                   {get; set;}
        public String   id                     {get; set;}
        public String   questionId             {get; set;}
        public String   question               {get; set;}
        public String   answer                 {get; set;}
        public Date     dateanswer             {get; set;}
        public String   orderNumber            {get; set;}
        public String   choices                {get; set;}
        public String   selectedOption         {get;set;}
        public List<String> selectedOptions    {get;set;}
        public List<SelectOption> singleOptions{get; set;}
        public List<SelectOption> multiOptions {get; set;}
        public Boolean  required               {get; set;}
        public String   questionType           {get; set;}    
        public String   surveyName             {get; set;}
        public String   renderFreeText         {get; set;}
        public String   renderNumber           {get; set;}
        public String   renderDate             {get; set;}
        public String   renderFile             {get; set;}      
        public String   renderSelectRadio      {get; set;}
        public String   renderSelectCheckboxes {get; set;} 
        public String   renderSelectRow        {get; set;}
        public List<String> responses          {get; set;}
        public String   singleOptionsForChart  {get; set;}
        public String   qResultsForChart       {get; set;} 
        public List<String> strList            {get; set;} // The question's option as a list of string
        public List<Integer> resultsCounts     {get; set;} // The count of each response to a question's choices
        public List<SelectOption> rowOptions   {get; set;}
        public boolean  noData                 {get; set;}
        public string imageName             {get; set;}  
        transient public Blob imageBody     {get; set;}  
        
        public question() 
        {
        
        }
          
      
      /** Fills up the question object
       *  param:    Survey_Question__c 
       */     
     public question(ProjectServiceQuestion__c sq, string answerText) 
     {
         name = sq.Name;
         id = sq.Id;
         questionId = sq.Question__c;
         answer = answerText;
         question = sq.QuestionText__c;
         system.debug('Question: ' + question + ' - Answer: ' + answer);
         orderNumber = String.valueOf(sq.QuestionNumber__c);
         required = false;
         questionType = sq.QuestionType__c;
         singleOptionsForChart = ' ';
         selectedOption = '';
         selectedOptions = new List<String>();
         renderSelectCheckboxes='false';
         renderFreeText='false';
         renderNumber='false';
         renderDate='false';
         renderFile='false';        
         renderSelectRow = 'false';
         renderSelectRadio='false';        
            
         if (questionType=='Yes/No'){
            choices = 'Yes\nNo';
            renderSelectRadio='true';
            singleOptions = stringToSelectOptions(choices);
            if (answer != '' && answer!= null)
            {
              selectedOption = getselectedoption(choices, answer);
            }
            selectedOptions = new List<String>();                               
          }
         else if (questionType=='Multi-Select List'){        
              choices = getchoices(sq.Question__c);
              renderSelectCheckboxes='true';
              multiOptions = stringToSelectOptions(choices);
              selectedOption = '';
              selectedOptions = new List<String>(); 
              if (answer != '' && answer!= null)
              {
                  selectedOptions = getselectedoptions(choices, answer);
              }
              
          }
         else if (questionType=='Single-Select List'){   
              choices = getchoices(sq.Question__c);
              rowOptions = stringToSelectOptions(choices);
              renderSelectRow = 'true';
              if (answer != '' && answer!= null)
              {
                  selectedOption = getselectedoption(choices, answer);
              }
              selectedOptions = new List<String>();     
          }
         else if (questionType=='Text'){
              renderFreeText='true';
              choices='';
          }
         else if (questionType=='Number'){
              renderNumber='true';
              choices='';
          }
         else if (questionType=='Date'){
              renderDate='true';
              if (answer != '' && answer!= null)
              {
                  dateanswer = Date.ValueOf(answer);
              }
              choices='';
          }
         else if (questionType=='Photo'){
              renderFile='true';
              choices='';
          }
          
     }
     
    
     /** Splits up the string as given by the user and adds each option
      *  to a list to be displayed as option on the Visualforce page
      *  param: str   String as submitted by the user
      *  returns the List of SelectOption for the visualforce page
     */  
     private List<SelectOption> stringToSelectOptions(String str)
     {
         if (str == '')
         {
             return new List<SelectOption>();
         }
         strList = str.split('\n');
          
         List<SelectOption> returnVal = new List<SelectOption>();
         Integer i = 0;
         for(String s: strList){
             if (s!='') {    
                 if (s != 'null' && s!= null) {
                     String sBis = s.replace(' ', '%20');
                     singleOptionsForChart += s.trim()+'|';
                     
                     /*RSC2012-02-20
                     String st = s.replace (' ', '&nbsp;');
                     returnVal.add(new SelectOption(String.valueOf(i),st));
                     */
                     returnVal.add(new SelectOption(s,s));
                     System.debug('*****VALUES: ' + s);
                 }
             }
         }
         singleOptionsForChart = singleOptionsForChart.substring(0, singleOptionsForChart.length()-1);
         return returnVal;
     } 

     private string getchoices(Id qstnId)
     {
         string choices = '';
        
         List<QuestionDefinedResponse__c> qdr = [Select Id, DefinedResponseText__c, DefinedResponseOrder__c from QuestionDefinedResponse__c
                                        where Question__c =: qstnId Order by DefinedResponseOrder__c];
                                        
         for (QuestionDefinedResponse__c dr : qdr)
         {
             choices = choices + dr.DefinedResponseText__c + '\n';
            
         }
         return choices;
    
     }
     
     private string getselectedoption(string options, string answer)
     {
         List<string> optionList = options.split('\n');
         
         for(String option: optionList){
             if (option.toLowerCase() == answer.toLowerCase())       
             {
                 return option;
             }
         
         }

         return '';         
     
     }
     private List<string> getselectedoptions(string options, string answer)
     {
         string optionsString = '';

         List<string> optionList = options.split('\n');
         
         List<string> answers = answer.split('@@@');
         
         for(string ans: answers)
         {
             for(String option: optionList){
                 
                 if (option.toLowerCase() == ans.toLowerCase())       
                 {
                     optionsString = optionsString + option + '@@@';
                     break;
                 }
             }
         }
         
         if (optionsString != '' && optionsString != null)
         {
             return optionsString.left(optionsString.length() - 3).split('@@@');
         }
         
         return new List<string>();
     
     }
     
    
   }