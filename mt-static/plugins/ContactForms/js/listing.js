var tableSelect;
$(document).ready( function() {
    tableSelect = new TC.TableSelect( "contact_form_inquiry-listing-table" );
    tableSelect.rowSelect = true;
    $('#select-all-checkbox').change( function() {
        var e = $(this);
        tableSelect.select( e[0] );
    });
    $('a[title="Reply"]').click( function() {
        var tr = $(this).parents('.inquiry-wrapper');
        var id = tr.attr('inquiry_id');
        var form_id = tr.attr('form_id');
        var date_formatted = tr.find('.date').html();
        var from = tr.find('.author').html();
        var form_name = tr.find('.inq-actions a').html();
        var text = tr.find('.inq-body').html();
        $('#replyDialog').dialog('option', 'buttons', { 
            'Send':function(e) {
                var content = $('#reply-body').val();
                tr.addClass('sending');
                $('#reply-body').val("");
                $.post(script_url, { 
                      '__mode': "cf.send_response",
                      'blog_id':blog_id,
	                  'reply_id':id,
	                  'text':content,
                      'magic_token':magic_token,
                    },
                    function(data){
                        tr.removeClass('read').removeClass('sending').addClass('replied');
                        return true;
                    }, 
                    "json");
                $("#replyDialog").dialog("close");
            },
            'Cancel':function() { 
                $("#replyDialog").dialog("close"); 
            } 
        });
        $("#replyDialog .comment-date").html(date_formatted);
        $("#replyDialog .commenter-name").html(from);
        $("#replyDialog .entry-title").html(form_name);
        $("#replyDialog .comment-body").html(text);
        $("#replyDialog").dialog("open");
        return false;
    });
    $('a[title="Delete"]').click( function() {
        var r = confirm("Are you sure you want to delete this inquiry?");
        if (!r) { return false; }
        var tr = $(this).parents('.inquiry-wrapper');
        var id = tr.attr('inquiry_id');
        var form_id = tr.attr('form_id');
        $(this).html('<img src="'+static_uri+'images/indicator.white.gif" width="16" height="16" />');
        $.post(script_url, {
            '__mode': "cf.del_inquiry",
            'blog_id':blog_id,
            'form_id':form_id,
	        'json':1,
            'magic_token':magic_token,
            'id':id
            },
            function(data){
                tr.find('td').fadeOut('fast', function() { tr.slideUp(); } );
            }, 
            "json");
        return false;
    });
    $('a[title="Toggle Flag"]').click( function() {
        var link = $(this);
        var tr = $(this).parents('.inquiry-wrapper');
        var id = tr.attr('inquiry_id');
        var form_id = tr.attr('form_id');
        tr.addClass('flagging').removeClass('flagged');
        $.post(script_url, {
            '__mode': "cf.toggle_flag",
            'blog_id':blog_id,
            'magic_token':magic_token,
            'id':id
            },
            function(data){
                var total = $('#inquiry-total-flagged').html();
                tr.removeClass('flagging');
                if (data.flagged) {
                    tr.addClass('flagged');
                    $('#inquiry-total-flagged').html( String( Number(total) + 1 ) );
                } else {
                    tr.removeClass('flagged');
                    $('#inquiry-total-flagged').html( String( Number(total) - 1 ) );
                }
            }, 
            "json");
        return false;
    });

    $('.inq-body').each( function () {
        if ($(this).height() == 92) {
            $(this).hover( function() { 
                $(this).find('.inq-more').slideDown(100);
            },function() {
                $(this).find('.inq-more').slideUp(100);
            });
        }
    });
    $('.inq-more a').click( function() {
        var p = $(this).parent().parent();
        if ($(this).hasClass('expanded')) {
            $(this).removeClass('expanded');
            $(this).html('show more');
            p.animate({
                'max-height':92
            },'slow',function() { 
            });
        } else {
            $(this).addClass('expanded');
            $(this).html('show less');
            p.animate({
                'max-height':2000
            },'slow',function() { 
                var h = p.height();
                p.height( h );
                p.css({ 'max-height':h });
            });
        }
    });
    $("#replyDialog").dialog({
        modal: true,
        width: 660,
        height: 495,
        dialogClass: "mt",
        open: function () { $(this).parents('.ui-dialog').wrapInner( '<div class="ui-dialog-inner"></div>' ); },
        autoOpen: false
    });
});