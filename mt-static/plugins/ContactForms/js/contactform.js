function buildFieldTypeList() {
    var html = '';
    for (key in options) {
        html += '<option value="' + key + '">' + options[key]['label'] + "</option>";
    }
    return html;
};

function onEditFieldClick() {
    var li = $(this).parents('li');
    var label = li.find('.label').html();
    var type = li.find('.type').html();
    li.find('.edit input[name="field-label"]').val( label );
    li.find('.edit select[name="type"]').val( type );
    li.find('.view').hide();
    li.find('.edit').show();
}

function onSaveFieldClick() {
    var li = $(this).parents('li');
    var label = li.find('.edit input').val();
    var type = li.find('.edit select').val();
    li.find('.view .label').html( label );
    li.find('.view .type').html( type );

    var idx = li.attr('idx');
    _fields[ idx ].label = label;
    _fields[ idx ].type  = type;

    if ( options[ type ]['meta'] ) {
        var opts = new Array();
        _fields[ idx ].options = {};
        for (var key in options[type]['meta']) {
            var value = li.find('.field-option-' + key).val();
            var cmd = '_fields[ '+idx+' ].options.'+key+'="'+value+'"';
            eval( cmd );
        }
    }

    li.find('.edit').hide();
    li.find('.view').show();
}

function onDeleteFieldClick() {
    var li = $(this).parents('li');
    li.addClass('removed');
    _fields[ li.attr('idx') ].removed = 1;
}

function buildFieldList() {
    for (var i=0;i<_fields.length;i++) {
   	    var html = buildFieldHTML(_fields[i], i);
	    $('#field-list-container').append(html);
    }
};

function buildFieldHTML( f, i ) {
    var html = '';
    html += '<li class="pkg field-list-item" idx="'+i+'">';
    html += '<div class="view">';
    html += '<span class="label">'+f.label+'</span>';
    html += '<span class="type">'+f.type+'</span>';
    html += '<span class="actions">';
    html += '<a href="javascript: void(0);" title="Edit Field"><img src="' + StaticURI + 'plugins/ContactForms/images/pencil.png" /></a>';
    if (f.removable == 1) {
	    html += '<a href="javascript: void(0);" title="Delete Field"><img src="' + StaticURI + 'plugins/ContactForms/images/delete.png" /></a>';
    }
    html += '</span>';
    html += '</div>'; 
    html += '<div class="edit">';
    html += '<label>Field Label: <input type="text" name="field-label" class="edit-label" /></label>';
    html += '<label>Field Type: <select name="type">' + fieldTypeList + '</select></label>';
    html += '<span class="actions">';
    html += '<div class="field-options"><a href="javascript: void(0);" title="Edit Options" class="edit-options"><img src="' + StaticURI + 'plugins/ContactForms/images/actionmenu.jpeg" /></a><div class="field-options-form"></div></div>';
	html += '<a href="javascript: void(0);" title="Save Field" class="save-field"><img src="' + StaticURI + 'plugins/ContactForms/images/accept.png" /></a>';
    html += '</span>';
    html += '</div>';
    html += '</li>';

    var dom = $(html);
    if (!options[ f.type ]['meta']) {
        dom.find('.field-options').hide();
    }
    dom.find('a[title="Edit Field"]').click( onEditFieldClick );
    dom.find('a[title="Delete Field"]').click( onDeleteFieldClick );
    dom.find('a[title="Save Field"]').click( onSaveFieldClick );
    dom.find('a[title="Edit Options"]').click( onEditOptionsClick );
    dom.find('select[name="type"]').change( onTypeChange );
    return dom;
};

function renderTypeOptions( e, type ) {
    var expanded = e.hasClass('expanded');
    var html = '';
    for (key in options[type]['meta']) {
        html += options[type]['meta'][key]['html'] + "<br/>";
    }
    if (html != '') {
        e.parent().show();
        e.html( html );
        for (key in options[type]['meta']) {
            var idx = e.parents('li').attr('idx');
            var v;
            var cmd = 'v = _fields[ '+idx+' ].options.'+key+';';
            eval( cmd );
            e.find('.field-option-'+key).val( v );
        }
    } else {
        e.parent().hide();
    }
    e.attr('class','field-options-form type-' + type + (expanded ? ' expanded' : ''));
};

function onTypeChange() {
    var type = $(this).val();
    var li = $(this).parents('li');
    var form = li.find('.field-options-form');
    renderTypeOptions( form, type );
};

function onEditOptionsClick() {
    var li = $(this).parents('li');
    var form = li.find('.field-options-form');
    if (form.hasClass('expanded')) {
        li.find('.field-options-form').hide();
        form.removeClass('expanded');
    } else {
        var type = li.find('.edit select[name="type"]').val();
        if (form.html() == '' || !form.hasClass('type-'+type)) {
            renderTypeOptions( form, type ); 
        }
        form.show();
        form.addClass('expanded');
    }
}

function onAddFieldClick() {
    var field = { 
        'label':'New Field', 
        'basename':'',
        'type':'text', 
        'order':_fields.length, 
        'removable':1,
        'removed':0,
        'new':1 
    };
    _fields.push(field);
    var html = buildFieldHTML(field, _fields.length - 1);
    $('#field-list-container').append( html );
    html.find('.view').hide();
    html.find('.edit').show();
};

function toggleSendAutoReply() {
    if ($('#send_autoreply').attr('checked')) {
        $('#autoreply').show();
    } else {
        $('#autoreply').hide();
    }
    return true;
};

function onFieldTypeChange() {
    var type = $('#field_type').val();
    var html = '';
    for (key in options[type]['meta']) {
        html += options[type]['meta'][key]['html'] + "&nbsp;&nbsp;";
    }
    if (html) {
        $('#field_options-field .field-content').html(html);
        $('#field_options-field').show();
    } else {
        $('#field_options-field .field-content').html('');
        $('#field_options-field').hide();
    }
};

/**
 * Concatenates the values of a variable into an easily readable string
 * by Matt Hackett [scriptnode.com]
 * @param {Object} x The variable to debug
 * @param {Number} max The maximum number of recursions allowed (keep low, around 5 for HTML elements to prevent errors) [default: 10]
 * @param {String} sep The separator to use between [default: a single space ' ']
 * @param {Number} l The current level deep (amount of recursion). Do not use this parameter: it's for the function's own use
 */
function print_r(x, max, sep, l) {
    l = l || 0;
    max = max || 10;
    sep = sep || ' ';
    if (l > max) {
        return "[WARNING: Too much recursion]\n";
    }
    var
    i,
    r = '',
    t = typeof x,
    tab = '';
    if (x === null) {
        r += "(null)\n";
    } else if (t == 'object') {
        l++;
        for (i = 0; i < l; i++) {
            tab += sep;
        }
        if (x && x.length) {
            t = 'array';
        }
        r += '(' + t + ") :\n";
        for (i in x) {
            try {
                r += tab + '[' + i + '] : ' + print_r(x[i], max, sep, (l + 1));
            } catch(e) {
                return "[ERROR: " + e + "]\n";
            }
        }
    } else {

        if (t == 'string') {
            if (x == '') {
                x = '(empty)';
            }
        }

        r += '(' + t + ') ' + x + "\n";

    }
    return r;
};

var fieldTypeList;
$(document).ready( function() {
    fieldTypeList = buildFieldTypeList();
    buildFieldList();
    $('a[title="Add Field"]').click( onAddFieldClick );
    $('#field-list-container').disableSelection();
    $('#field-list-container').sortable({
        placeholder: 'ui-state-highlight',
        axis: 'y',
        items: 'li',
        opacity: '0.5',
        stop: function(event,ui) {
            $('#field-list-container li').each( function() {
/*
            for (var i = 0; i < listOrder.length; i++) {
                _fields[i].order = listOrder[i];
            }
*/
            });
        }
    });
});
