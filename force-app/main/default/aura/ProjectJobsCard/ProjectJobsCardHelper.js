({
  AppSettings: {
    'Events': {
      'RemoteActionRequest': 'e.c:ActionRequestAppEvent'
    },
    'Methods': {
      'DeleteJob': {
        'id': 'deleteJobs',
        'name': 'deleteJobs'
      },
    }
  },


  checkOne: function(cmp, evt) {
    var checkOneEvent = cmp.getEvent('checkOneJobEvent');
    checkOneEvent.fire();
  },

  checkAll: function(cmp, evt) {

    var jobs = cmp.get('v.jobs');
    jobs.forEach(function(e) {

      e.selected = true;
    });
    cmp.set('v.jobs', jobs);
  },
  jobDetails: function(cmp, evt) {

    var myId = evt.currentTarget.getAttribute('data-id');
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({

      "recordId": myId
    });
    navEvt.fire();

  },

  deleteCurrentJob: function(cmp, evt) {
    var card, event = cmp.getEvent('removeOneJobEvent');
    var id = evt.currentTarget.getAttribute('data-id');
    if (!id) {
      return;
    }
    var card = this._getCurrentCard(cmp, id);
    card && card.classList.add('card-select');
    console.log(card);

    event.setParams({
      'id': 'removeOneJobEvent',
      'context': id
    });
    event.fire();
  },


  unSelectCurrentCard: function(cmp, evt) {
    var card, params = evt.getParam('arguments');
    if (!params.id) {
      return;
    }
    card = this._getCurrentCard(cmp, params.id);
    card && card.classList.remove('card-select');
  },

  _getCurrentCard: function(cmp, id) {
    var container = cmp.find('cardContainer').getElement();
    return container.querySelector(['article[data-id="', id, '"'].join(''));
  },

  _publishAppEvent: function(message) {
    var appEvent = $A.get(this.AppSettings.Events.RemoteActionRequest);
    appEvent.setParams(message);
    appEvent.fire();
  },
  _showSpinner: function(cmp, shown) {
    var evt = cmp.getEvent('showSpinnerEvent');
    evt.setParams({
      'context': {
        'show': shown
      }
    });
    evt.fire();
  }
})