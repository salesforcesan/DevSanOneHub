({
 	handleDragMove: function(e){
        
 			var edgeSize = 250;
        	var timer = null;
            // Get the viewport-relative coordinates of the dragmove event.
            var viewportY = e.clientY;
 
            var viewportHeight = document.documentElement.clientHeight;

            var edgeTop = edgeSize;
            var isInTopEdge = ( viewportY < edgeTop );
        
			//not in the top edge don't run the rest of the code
            if (!isInTopEdge) {
                clearTimeout( timer );
                return;
            }

            var documentHeight = Math.max(
                document.body.scrollHeight,
                document.body.offsetHeight,
                document.body.clientHeight,
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight,
                document.documentElement.clientHeight
            );
 
            var maxScrollY = ( documentHeight - viewportHeight );

            (function checkForWindowScroll() {
                clearTimeout( timer );
                if ( adjustWindowScroll() ) {        
                    timer = setTimeout( checkForWindowScroll, 30 );
                }
            })();
 
            // Adjust the window scroll based on the user's mouse position. Returns True
            // or False depending on whether or not the window scroll was changed.
            function adjustWindowScroll() {
 
                var currentScrollY = window.pageYOffset;
                var canScrollUp = ( currentScrollY > 0 );
                var nextScrollY = currentScrollY;
 
                var maxStep = 50;
 
                if ( isInTopEdge && canScrollUp ) {
 
                    var intensity = ( ( edgeTop - viewportY ) / edgeSize );
                    nextScrollY = ( nextScrollY - ( maxStep * intensity ));// );


                 var currentScrollX = window.pageXOffset;
                 nextScrollY = Math.max( 0, Math.min( maxScrollY, nextScrollY ) );
 
                if (nextScrollY !== currentScrollY ) {
                    window.scrollTo( currentScrollX, nextScrollY );
                    return( true );
                } else {
                    return( false );
                }
 
            }
        }
    },
    
    dragEndGhost: function(cmp, e, h) {
        e.currentTarget.style.opacity = 1;
        
        var ghostcomponents = document.getElementsByClassName("ghost");
        Array.prototype.forEach.call(ghostcomponents, function(cmpghost) {
            if (!$A.util.hasClass(cmpghost, 'slds-hide')) {
                $A.util.addClass(cmpghost, 'slds-hide');
            }
        });

   		let parentcomponents = document.querySelectorAll('.oh-parent');
        Array.prototype.forEach.call(parentcomponents, function(elem){
            $A.util.removeClass(elem, 'oh-parent');
        });  
        window.removeEventListener( "mousemove", this.handleDragMove(e), false );       
    },
    
    msgBox: function(cmp, e, type, msg) {
        var notice = $A.get('e.force:showToast');

        notice.setParams({
            'mode': type === 'error' ? 'sticky' : 'dismissible',
            'type': type,
            'message': msg
        });
        notice.fire();
    },
    
})