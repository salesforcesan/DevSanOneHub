({
    'ShowSelectProjectTypeDialogSetting': {
        'id': 'dlgSelectProjectType',
        'component': 'c:SelectProjectTypeModal',
        'size': 'x-medium',
        'title': 'Select Project Type'
    },     
    showSelectProjectTypeModal: function(cmp, questions, recordId){
        this._renderDialog(cmp, this.ShowSelectProjectTypeDialogSetting,{
            
        });
    },    
    getProjectStatuses: function(cmp) {
        var action = cmp.get("c.getProjectSummary", []);
        var self = this;
        action.setCallback(self, function(result) {
            console.log(result.getReturnValue(), "Project status counts");
            var stats = result.getReturnValue();
            stats = JSON.parse(stats);
            cmp.set("v.statuses", stats);            
        });
        $A.enqueueAction(action);
	},
    toggleFilters: function(cmp, event, helper, filterId) {
        // Get the current filters
        var filters = {},
            thisFilter;
        
        // Toggle the filter in the filters object
        if (filters[thisFilter.id]) {
            filters[thisFilter.id] = false;
        } else {
            filters[thisFilter.id] = true;
        }
        
        cmp.set("v.filters", filters);
        
        // Publish the filters     
		var appEvent = $A.get("e.c:ProjectStatusFiltersChanged");
        appEvent.setParams({ "projectStatusFilters" : cmp.get("v.filters") });
        appEvent.fire();
    },
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        var self = this;
        action.setCallback(self, function(result) {
            cmp.set("v.ns", result.getReturnValue());            
        });
        $A.enqueueAction(action);
	},
    toggleClass: function(cmp,cmpId,className) {
		var modal = cmp.find(cmpId);
		$A.util.removeClass(modal,className+'hide');
		$A.util.addClass(modal,className+'open');
	},    
    clearSelections : function() {
        var elems = document.querySelectorAll(".psbar-button");
        [].forEach.call(elems, function(el) {
            el.classList.remove("psbar-button_on");
        });    
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
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type, autoHide, duration);
    },
    
    
})