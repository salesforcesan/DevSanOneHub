({
    LoadMethod: function(component, psID) {
        var self = this;
        self.showSpinner(component);

        component.set("v.securityelements", "ProjectService__c.Delete,ProjectService__c.Edit,ProjectService__c.Cancel,ProjectService__c.BundledCancel");

        var uploadManual = component.find("uploadManualDiv");

        var action = component.get("c.GetProjectService");
        action.setParams({
            "projServiceId": psID
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (!component.isValid()) {
                self._msgBox('error', 'The component is out of scope.');
                return;
            }
            self.hideSpinner(component);
            if (state === 'SUCCESS') {
                component.set("v.service", response.getReturnValue());
                component.set("v.serviceLoaded", true);
                component.set("v.AttachmentIDs", '');
                component.set("v.DeleteAttachmentIDs", '');
                return;
            }

            if (state === 'ERROR') {
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    self._msgBox('error', errors[0].message);
                } else {
                    self._msgBox('error', 'The system runs into an error.');
                }
                return;
            }
            self._msgBox('error', 'The system runs into an error. Please refresh the component.');

        });
        $A.enqueueAction(action);
    },

    createProjectServiceComponent: function(cmp) {
        var psID = cmp.get("v.recordId");
        cmp.set('v.editorPlaceholder',[]);

        $A.createComponent(
            "force:recordEdit", {
                "aura:id": "projectservice_edit",
                "id": "projectservice_edit",
                "recordId": psID
            },
            function(newComponent) {
                cmp.set('v.editorPlaceholder', [newComponent]);
            }
        );
    },

    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type, autoHide, 500);
    },

    handleSaveSuccess: function(component) {
        console.log('heloo1++++++++++++++++++++++++++++++');
        this.saveButtonClicked(component);
    },

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type,
            "mode": type === 'error' ? 'sticky' : 'dismissible',
            "duration": 3000
        });
        toastEvent.fire();
    },
    DeleteAttachmentHandler: function(component, psaID) {
        var self = this;
        var spinner = component.find("Spinner");
        $A.util.removeClass(spinner, "slds-hide");

        var action = component.get("c.DeleteAttachmentHandlerEvt");
        action.setParams({
            "psaRecordID": psaID
        });

        action.setCallback(this, function(response) {
            if(!component.isValid()){
                console.log('--project service instruction component run out of scope--');
                return;
            }
            
            if (response.getState() === "SUCCESS") {
                //console.log( "~~ return after save ~~" );                                    
                //debugger;

                if (response.getReturnValue().isSuccess) {
                    component.set("v.service", response.getReturnValue());
                }
                self._msgBox(
                    response.getReturnValue().isSuccess ? 'success' : 'error',
                    response.getReturnValue().message
                );

            } else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    self._msgBox('error', errors[0].message);
                } else {
                    self._msgBox('error', 'The system runs into an error.');
                }
            }
            $A.util.addClass(spinner, "slds-hide");
        });

        $A.enqueueAction(action);
    },
    deleteProjectService: function(component) {
        //debugger;
        var spinner = component.find("Spinner");
        $A.util.removeClass(spinner, "slds-hide");
        //console.log(component.get("v.recordId"));
        //console.log(component.get("v.service").RecordID);

        var projectServiceId = component.get("v.service.RecordID");
        var action = component.get("c.deleteProjectServiceApex");
        action.setParams({
            "projectServiceId": projectServiceId
        });
        action.setCallback(this, function(response) {
            if(!component.isValid()){
                console.log('--project service instruction component run out of scope--');
                return;
            }
            if (response.getState() === "SUCCESS") {
                var responseWrapper = JSON.parse(response.getReturnValue());
                if (responseWrapper.State === 'SUCCESS') {
                    this.showToast('Delete Service', responseWrapper.Message, 'SUCCESS');
                }
                //var result = JSON.parse(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    FileUploadHandler: function(component, event) {
        var MAX_FILE_SIZE = 4500000;
        var CHUNK_SIZE = 450000;
        var spinner = component.find("Spinner");
        $A.util.removeClass(spinner, "slds-hide");

        //debugger;
        var attmntIDval = component.get("v.AttachmentIDs");
        if (typeof attmntIDval == 'undefined') {
            attmntIDval = '';
        }

        //console.log(event.target.id + '_________'+ event.target.value);
        var mydiv = document.getElementById(event.target.id);
        //console.log(mydiv);
        var recordID = mydiv.getAttribute("data-id");
        //console.log(recordID);

        var psID = component.get("v.recordId");
        var self = this;

        //debugger;
        if (component.find("file") != undefined && component.find("file").length != undefined) {
            var fileLength = component.find("file").length;
            var fileInputs = component.find("file");

            fileInputs.forEach(function(entry) {
                var fileInput = entry.getElement();

                if (fileInput != null) {
                    if (fileInput.id == event.target.id) {
                        var file = fileInput.files[0];
                        //debugger;


                        if (file.size > MAX_FILE_SIZE) {
                            alert('File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' +
                                'Selected file size: ' + file.size);
                            $A.util.addClass(spinner, "slds-hide");
                            return false;
                        }

                        var fr = new FileReader();
                        var psc = [];

                        fr.readAsDataURL(file);

                        fr.onload = function() {

                            var fileContents = fr.result;
                            var base64Mark = 'base64,';
                            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                            fileContents = fileContents.substring(dataStart);
                            //console.log('!!!!!   fileContents '+fileContents);

                            psc[0] = file.name;
                            psc[1] = file.type;
                            psc[2] = ''; //encodeURIComponent(fileContents)'';
                            psc[3] = fileInput["id"];
                            psc[4] = recordID;

                            //console.log('!!!!!   !   psc  '+psc);            
                            //console.log('!!!!!   JSON.stringify(psc)  '+JSON.stringify(psc));

                            self.upload(component, psc, fileContents);
                        };
                    }
                }

            });
        } else {
            $A.util.addClass(spinner, "slds-hide");
        }
    },

    upload: function(component, psc, fileContents) {
        //debugger;
        var fromPos = 0;
        var CHUNK_SIZE = 450000;
        var toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
        this.uploadChunk(component, psc, fileContents, fromPos, toPos, '');
    },

    uploadChunk: function(component, psc, fileContents, fromPos, toPos, attachId) {
        var spinner = component.find("Spinner");
        //debugger;
        var self = this;
        var CHUNK_SIZE = 450000;
        var chunk = fileContents.substring(fromPos, toPos);
        var action = component.get("c.SaveAttachments");

        var psID = component.get("v.recordId");

        action.setParams({
            "psId": psID,
            "PhotoAttributes": JSON.stringify(psc),
            "attachmentID": attachId,
            "base64Data": encodeURIComponent(chunk)
        });

        action.setCallback(this, function(response) {
            if(!component.isValid()){
                console.log('--project service instruction component run out of scope--');
                return;
            }

            if (response.getState() === "SUCCESS") {
                //debugger;
                attachId = response.getReturnValue();
                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
                if (fromPos < toPos) {
                    self.uploadChunk(component, psc, fileContents, fromPos, toPos, attachId);
                } else {
                    var attmntIDval = component.get("v.AttachmentIDs");
                    if (typeof attmntIDval == 'undefined') {
                        attmntIDval = attachId;
                    } else {
                        attmntIDval = attmntIDval + "," + attachId;
                    }
                    component.set("v.AttachmentIDs", attmntIDval);

                    /*
                    var JobManualAttrID = component.get("v.JobManualAttrID");
                    if(JobManualAttrID==psc[3] ){
                        component.set("v.JobManualUploaded", "true")
                    }
                    */


                    var x = document.getElementById(psc[3]).parentElement;
                    if (x.lastChild.innerText == "") {
                        var el_span = document.createElement('span');
                        el_span.setAttribute('style', 'background-color:#009E60;color:white;');
                        x.appendChild(el_span);
                        el_span.appendChild(document.createTextNode(" Upload successfull ! Pending Save..."));
                    }
                    $A.util.addClass(spinner, "slds-hide");
                }
            } else {

                var er = response.getError();
                console.log(response);
                console.log(er[0]);
                console.log((er[0]).pageErrors[0].message);
                //console.log((er[0])[0].message);
                
                this.showToast('Attachment Error', (er[0]).pageErrors[0].message, 'error');
                $A.util.addClass(spinner, "slds-hide");
            }
        });

        $A.enqueueAction(action);
    },
    saveButtonClicked: function(component) {
        console.log('save2++++++++++++++++++++++++++++++');
        var psID = component.get("v.recordId");
        var psObj = component.get("v.service");
        var jsonPSObj = JSON.stringify(psObj);
        var spinner = component.find("Spinner");

        var attmntIDval = component.get("v.AttachmentIDs");
        console.log('attmntIDval++++++++++++' + attmntIDval);

        var DelAttmntIDval = component.get("v.DeleteAttachmentIDs");
        console.log('DelAttmntIDval+++++++++++++' + DelAttmntIDval);

        if (typeof DelAttmntIDval == 'undefined') {
            DelAttmntIDval = '';
        }
        console.log('jsonPSObj++++++++++++++++++' + jsonPSObj);
        var action = component.get("c.SaveProjServiceDetails");
        action.setParams({
            "projectServiceId": psID,
            "ProjServValues": jsonPSObj,
            "attmntIDval": attmntIDval,
            "DelAttmntIDval": DelAttmntIDval
        });

        var self = this;
        self.showSpinner(component);
        //debugger;
        action.setCallback(this, function(response) {
            if(!component.isValid()){
                console.log('--project service instruction component run out of scope--');
                return;
            }

            if (response.getState() === "SUCCESS") {
                //console.log( "~~ return after save ~~" );                                           

                if (response.getReturnValue().isSuccess) {
                    //  var data = JSON.parse(response.getReturnValue());
                    //  console.log("The Data:++++++++++++++++++++++++ ", data);
                    component.set("v.service", response.getReturnValue());
                    //console.log(json.parse(response.getReturnValue()));
                    component.set("v.AttachmentIDs", '');
                    component.set("v.DeleteAttachmentIDs", '');

                    self.createProjectServiceComponent(component);

                    self.async(component, function(cmp) {
                        self.hideSpinner(component);
                        self.LoadMethod(cmp, psID);
                        self._msgBox('success', 'Successfully saved service changes.');
                    }, 250);
                }

            } else if (response.getState() === "ERROR") {
                console.log('~~'+response.getError());
                $A.util.addClass(spinner, "slds-hide");
                var er = response.getError();
                console.log('~eee~'+er);
                console.log('~rrrr~'+er[0]);
                this.showToast('Attachment Error', (er[0]).pageErrors[0].message, 'error');

            }
            $A.util.addClass(spinner, "slds-hide");

        });
        $A.enqueueAction(action);

    },
    MarkAttachmentForDelete: function(component, psaID) {
        //debugger;
        var spinner = component.find("Spinner");
        $A.util.removeClass(spinner, "slds-hide");

        var temp = component.get("v.DeleteAttachmentIDs");
        temp = temp + ',' + psaID;
        component.set("v.DeleteAttachmentIDs", temp);

        /*
        var temp = document.getElementById(psaID);
        document.getElementById(psaID).innerHTML = ' Marked for deletion!! ';
        */
        var x = document.getElementById(psaID).parentElement;

        if (x.lastChild.innerText == "") {
            var el_span = document.createElement('span');
            el_span.setAttribute('style', 'background-color:#ED2939;color:white;');
            x.appendChild(el_span);
            el_span.appendChild(document.createTextNode(" Marked for deletion ! Pending Save... "));
        }
        /*
        var x = document.getElementById(psaID).parentElement;        
        x.appendChild( document.createTextNode(" Marked for deletion. Pending Save. "));
        */

        $A.util.addClass(spinner, "slds-hide");
    },

    async: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 200;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },

    showSpinner: function(cmp) {
        var spinner = cmp.find("Spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(cmp) {
        var spinner = cmp.find("Spinner");
        $A.util.addClass(spinner, "slds-hide");
    },

    _msgBox: function(msgType, msg) {
        var evt = $A.get('e.force:showToast');
        evt.setParams({
            message: msg,
            type: msgType,
            mode: msgType === 'error' ? 'sticky' : 'dismissible'
        });
        evt.fire();
    }

})