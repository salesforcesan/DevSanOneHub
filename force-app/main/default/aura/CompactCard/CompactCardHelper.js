({
    titleClicked: function(cmp){
        var evtClick = cmp.getEvent('compactCardTitleClicked');
        evtClick.setParams({
            context: cmp.get('v.id')
        });
        console.log('---title clicked----');
        evtClick.fire();
    }
})