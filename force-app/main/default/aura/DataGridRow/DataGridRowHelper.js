({
  afterRender: function(cmp) {
    this._initColumns(cmp);
  },

  _initColumns: function(cmp) {
    var obj, components, icons, fields = cmp.get('v.fields'),
      record = cmp.get('v.record') || {},
      cols = fields.map(function(f) {
        obj = {};
        Object.keys(f).forEach(function(nm) {
          obj[nm] = f[nm];
        });
        obj['__value'] = record[f.id] || '';
        obj['__parent'] = record;
        obj['__selected'] = record.__selected;
        switch (f.type) {
          case 'button':
            obj['__ui'] = 'c:DataGridButtonCell';
            break;
          case 'link':
            obj['__ui'] = 'c:DataGridLinkCell';
            break;
          case 'icon':
            obj['__ui'] = 'c:DataGridIconCell';
            (f.map || []).filter(function(icon) {
              return icon.value == record[f.id];
            }).forEach(function(icon) {
              obj['__class'] = ['fa fa-icon', icon.color, icon.icon].join(' ');
            });
            break;
          case 'checkbox':
            obj['__ui'] = 'c:DataGridCheckboxCell';
            break;
          default:
            obj['__ui'] = 'c:DataGridTextCell'
            break;
        }
        return obj;
      });

    components = cols.map(function(c) {
      return [c['__ui'], { 'field': c }];
    });

    $A.createComponents(components, function(cmps, status, messages) {
      if (status === 'SUCCESS') {
        cmp.set('v.components', cmps);
        cmp.set('v.body', cmps);
      } else {
        console.log(messages);
      }
    });
  },

  rerender: function(cmp) {
    var items, rec, field, firstTime = $A.util.getBooleanValue(cmp.get('v.firstTime'));
    if (firstTime) {
      cmp.set('v.firstTime', false);
      return;
    }
    rec = cmp.get('v.record');
    items = cmp.get('v.components');
    items.forEach(function(c) {
      field = c.get('v.field');
      field['__selected'] = rec['__selected'];
      field['__value'] = rec[field.id] || '';
      field['__parent'] = rec;
      (field.map || []).filter(function(icon) {
        return icon.value == rec[field.id];
      }).forEach(function(icon) {
        field['__class'] = ['fa fa-icon', icon.color, icon.icon].join(' ');
      });
      c.set('v.field', field);
    });
  },
})