({
    setProjectServiceContext : function(component) {
        /*
        var sPageURL = decodeURIComponent(window.location.href);
        console.log(sPageURL, "<<< sPageURL");
        sPageURL = sPageURL.substring(sPageURL.search('slideDevName'));
        sPageURL = sPageURL.substring(13, sPageURL.indexOf('&'));
        console.log(sPageURL, "<<< sPageURL");
        component.set("v.projectServiceContext", sPageURL);
        
        var selectedTab = document.getElementById("sPageURL");
        console.log(selectedTab, "selectedTab");
        */
        //default to 
        component.set("v.projectServiceContext", 'instructions');
    }
})