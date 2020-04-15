({
    doInit: function(cmp,e,h){
    },
    dragStartHandler: function(cmp, e, h) {  
        e.stopPropagation();
        e.currentTarget.style.opacity = 0.4; 
        var startId = e.target.id;
        cmp.set("v.startId", startId);  
        if($A.util.isEmpty(startId)) {
            return;
        }
    },
    dragOverHandler: function(cmp, e, h) {
        window.addEventListener( "mousemove", h.handleDragMove(e), true );
        e.preventDefault();
        e.stopPropagation();
        
        if(e.target.id === cmp.get('v.startId') || e.currentTarget.id.includes('_ghost'))
        {
            return;
        };
        
        var ghostcomponents = document.querySelectorAll(".ghost");
        Array.prototype.forEach.call(ghostcomponents, function(cmpghost) {
            if (!$A.util.hasClass(cmpghost, 'slds-hide')) {
                $A.util.addClass(cmpghost, 'slds-hide');
            }
        });
        
        let parentcomponents = document.querySelectorAll('.oh-parent');
        Array.prototype.forEach.call(parentcomponents, function(elem){
            $A.util.removeClass(elem, 'oh-parent');
        });

        let ghost = document.getElementById(e.currentTarget.id + '_ghost');
        $A.util.removeClass(ghost, 'slds-hide');//|| parent
        
        if (e.currentTarget.classList.contains('parent') && !e.currentTarget.classList.contains('ghost')) { // == "parent" ) {
            e.currentTarget.classList.add('oh-parent');
            //$A.util.addClass(ghost, 'slds-hide');
        }
        if (e.currentTarget.classList.contains('ghost') || e.target.classList.contains('ghost')) { // == "parent" ) {
            if (e.currentTarget.previousSibling.classList.contains('parent')) {
            	e.currentTarget.previousSibling.classList.remove('oh-parent');
            //$A.util.addClass(ghost, 'slds-hide');
            }
        }
        
        
    }, 
    dropHandler: function(cmp, e, h) {
        e.preventDefault();
        e.stopPropagation();
        var startId = cmp.get("v.startId");

        if(!$A.util.isEmpty(startId)) {
            var source = startId.split('_');
  			var sourceId = source[0];
            var sourceParentId = source[1];
            var question = cmp.get('v.question');           
            let droptargetid = e.target.id ? e.target.id:e.currentTarget.id;           
            var target = droptargetid.split('_');
            var targetId = target[0];
            var targetParentId = target[1];

            cmp.set("v.parentId", droptargetid);
            
            var actionType;
            
            if (!droptargetid.includes('_ghost')) {
                actionType = 'reparent';
            }
            else {
                if (sourceParentId == targetParentId || !targetParentId )
                    actionType = 'reorder';
                else {
                    actionType = 'reparent';
                    targetId = targetParentId;
                }                
            }
            
            var dragChangeEvent = cmp.getEvent("dragChange");
            dragChangeEvent.setParams({
                'targetId': targetId,
                'sourceId': sourceId,
                'actionType': actionType
            });
            dragChangeEvent.fire();
        } else {
          h.dragEndGhost(cmp, e, h);   
        }
        
    }, 
    dragEndHandler: function(cmp, e, h) {
        e.stopPropagation();
        e.preventDefault(); 
        h.dragEndGhost(cmp, e, h); 
    },
    
    handleShowResponses: function(cmp, e, h) { 
        var responses = [];
        var questions = cmp.get('v.question');
        var target = e.currentTarget.id;
        var targetSplit = target.split('_');
        var targetId = targetSplit[0];
        var responsesQuestion = questions.filter(item => item.ProjectServiceQuestionId === targetId);
        var questionTitle = responsesQuestion[0].QuestionText;
            responses = responsesQuestion[0].DefinedResponses;
        
        var showResponsesEvent = cmp.getEvent("DefinedResponsesPopover");
        showResponsesEvent.setParams({
            'responses': responses,
            'questionTitle':  questionTitle
        });
        showResponsesEvent.fire();   
    },
   
    
})