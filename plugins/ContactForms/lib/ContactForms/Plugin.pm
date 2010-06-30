package ContactForms::Plugin;

use strict;
use JSON;
use MT::Util
  qw(format_ts relative_date dirify ts2iso is_valid_email html_text_transform);

sub init_request {
    my $cb     = shift;
    my $plugin = $cb->plugin;
    my ($app)  = @_;
    return if $app->id ne 'cms';
    return if $app->mode eq 'refresh_all_templates';
    if ( $app->blog ) {
        my $r  = $app->registry('template_sets');
        my $ts = $app->blog->template_set;
        if ( ref( $r->{$ts}->{'templates'} ) eq 'HASH' ) {
            $r->{$ts}->{'templates'}->{'system'}->{'inquiry_response'} =
              { label => 'Contact Form Response', };
            $r->{$ts}->{'templates'}->{'system'}->{'contact_form'} =
              { label => 'Contact Form', };
        }
    }
    return 1;
}

sub init_filters {
    my $app = MT::App->instance;
    return unless (ref $app eq 'MT::App::CMS' && $app->mode eq 'cf.list_inquiries' && $app->blog);
    my @forms = MT->model('contact_form')->load({ blog_id => $app->blog->id });
    my $i = 0;
    my $filters = {
        'contact_form_inquiry' => {
            'all' => {
                label   => 'All Inquiries',
                order   => $i++,
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{blog_id} = $app->blog->id;
                },
            },
            'unread' => {
                label   => 'Unread Inquiries',
                order   => $i++,
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{status}  = MT->model('contact_form_inquiry')->UNREAD();
                    $terms->{blog_id} = $app->blog->id;
                },
            },
            'flagged' => {
                label   => 'Flagged Inquiries',
                order   => $i++,
                handler => sub {
                    my ( $terms, $args ) = @_;
                    $terms->{flagged} = 1;
                    $terms->{blog_id} = $app->blog->id;
                },
            },
        }
    };
    foreach my $f (@forms) {
        $filters->{'contact_form_inquiry'}->{ 'form_' . $f->id } = {
            label   => $f->title,
            order   => $i++,
            handler => sub {
                my ( $terms, $args ) = @_;
                $terms->{form_id} = $f->id;
                $terms->{blog_id} = $f->blog_id;
            },
        };
    }
    return $filters;
}

sub type_forms {
    my $app = shift;
    my ( $field_id, $field, $value ) = @_;
    my $out;
    my @forms =
      MT->model('contact_form')
      ->load( { blog_id => $app->blog->id }, { sort => 'title' } );
    if ( $#forms < 0 ) {
        return
'<p>You have not created a contact form in this blog yet. <a href="?__mode=cf.list_forms&blog_id='
          . $app->blog->id
          . '">Create one now</a></p>';
    }
    $out .= "      <select name=\"$field_id\">\n";
    $out .=
        "        <option value=\"0\" "
      . ( 0 == $value ? " selected" : "" )
      . ">None Selected</option>\n";
    foreach (@forms) {
        $out .=
            "        <option value=\""
          . $_->id . "\" "
          . ( $value == $_->id ? " selected" : "" ) . ">"
          . $_->title
          . "</option>\n";
    }
    $out .= "      </select>\n";
    return $out;
}

sub send_response {
    my $app = shift;
    my $q   = $app->{query};
    my $reply =
      MT->model('contact_form_inquiry')->load( $q->param('reply_id') );
    my $form  = $reply->form;
    my $cfg   = $app->config;
    my $blog  = $app->blog;
    my $token = $app->make_magic_token;

    my $subject        = $app->translate( 'Re: ' . $reply->subject );
    my $ts             = $reply->created_on;
    my $date_format    = MT::App::CMS::LISTING_DATE_FORMAT();
    my $date_formatted = format_ts( $date_format, $ts, $app->blog,
        $app->user ? $app->user->preferred_language : undef );
    my $param = {
        blog          => $blog,
        form_name     => $form->title,
        from_name     => $reply->from_name,
        from_email    => $reply->from_email,
        response_text => $q->param('text'),
        inquiry_text  => $reply->text,
        inquiry_date  => $date_formatted,
    };
    my $body = MT->build_email( 'email/reply.tmpl', $param );

    require MT::Mail;
    my $from_addr;
    my $reply_to;
    if ( $form->reply_to ) {
        $reply_to = $form->reply_to;
    }
    else {
        $from_addr = $form->from;
    }
    $from_addr = undef if $from_addr && !is_valid_email($from_addr);
    $reply_to  = undef if $reply_to  && !is_valid_email($reply_to);

    my %head = (
        id  => 'reply',
        To  => $reply->from_email,
        Bcc => $form->subscribers,
        $from_addr ? ( 'From'     => $from_addr ) : (),
        $reply_to  ? ( 'Reply-To' => $reply_to )  : (),
        Subject => $subject,
    );

    my $charset = $cfg->MailEncoding || $cfg->PublishCharset;
    $head{'Content-Type'} = qq(text/plain; charset="$charset");

    ## Save it in session to purge later
    require MT::Session;
    my $sess = MT::Session->new;
    $sess->id($token);
    $sess->kind('CFR');    # CR == Commenter Registration
    $sess->email( $reply->from_email );
    $sess->name('contactform_response');
    $sess->start(time);
    $sess->save;

    my $sent = MT::Mail->send( \%head, $body )
      or die MT::Mail->errstr();
    $reply->status( MT->model('contact_form_inquiry')->REPLIED() );
    $reply->save;
    return _send_json_response( $app,
        { sent => $sent, status => $reply->status } );
}

sub install_tmpl {
    my $app = shift;
    my $q   = $app->{query};
    my $tid = $q->param('template');
    my $system;
    $system = MT->model('template')->load( { type => $tid, blog_id => 0 } );
    if ($system) {
        MT->log(
            {
                blog_id => $app->blog->id,
                message => "Installing the template: " . $system->name
            }
        );
        my $tmpl = MT->model('template')->new;
        $tmpl->blog_id( $app->blog->id );
        $tmpl->type( $system->type );
        $tmpl->name( $system->name );
        $tmpl->text( $system->text );
        $tmpl->save;
    }
    return _send_json_response( $app, { success => $system ? 1 : 0 } );
}

sub edit_form {
    my $app    = shift;
    my $q      = $app->{query};
    my $plugin = MT->component('ContactForms');
    my $form           = MT->model('contact_form')->load( $q->param('id') );
    my $tmpl           = $plugin->load_tmpl('edit_form.tmpl');
    my $options_struct = _load_options();
    my $fields_struct  = _load_fields($form);
    my $param          = {
        blog_id           => $form->blog_id,
        form_id           => $form->id,
        title             => $form->title,
        from              => $form->from,
        reply_to          => $form->reply_to,
        subscribers       => $form->subscribers,
        allow_anon        => $form->allow_anonymous,
        form_status       => $form->status,
        send_autoreply    => $form->send_autoreply,
        autoreply_subject => $form->autoreply_subject,
        autoreply_text    => $form->autoreply_text,
        confirmation_text => $form->confirmation_text,
        options_js        => to_json($options_struct),
        fields_js         => to_json($fields_struct),
    };
    return $app->build_page( $tmpl, $param );
}

sub save_form {
    my $app    = shift;
    my $q      = $app->{query};
    my $plugin = MT->component('ContactForms');
    my $form;
    my $new = 0;
    my $id = $q->param('id') || 0;
    unless ( $form = MT->model('contact_form')->load( { id => $id } ) ) {
        $form = MT->model('contact_form')->new;
        $form->blog_id( $app->blog->id );
        $new = 1;
    }
    $form->title( $q->param('title') );
    $form->from( $q->param('from') );
    $form->reply_to( $q->param('reply_to') );
    $form->status( $q->param('form_status') );
    $form->subscribers( $q->param('subscribers') );
    $form->allow_anonymous( $q->param('allow_anon')    ? 1 : 0 );
    $form->send_autoreply( $q->param('send_autoreply') ? 1 : 0 );
    $form->autoreply_subject( $q->param('autoreply_subject') );
    $form->autoreply_text( $q->param('autoreply_text') );
    $form->confirmation_text( $q->param('confirmation_text') );
    $form->save
      or return _send_json_response( $app, { error => $form->errstr } );
    my $json = $q->param('fields');
    my $fields = from_json( $json );

    foreach my $f (@$fields) {
        my $field;
        $f->{'options'} ||= {};
        if ( $f->{removed} ) {
            $field =
              MT->model('contact_form_field')
              ->remove( { id => $f->{id}, form_id => $form->id } );
            next;
        }
        if ( $f->{new} ) {
            $field = MT->model('contact_form_field')->new;
            $field->form_id( $form->id );
        }
        else {
            $field = MT->model('contact_form_field')->load( $f->{id} );
            unless ($field) {
                MT->log("Field #".$f->{id}." not found. Skipping.");
                next;
            }
        }
        my $basename;
        if ($f->{basename} && $f->{basename} ne '') {
            $basename = $f->{basename};
        } else {
            $basename = dirify( $f->{label} );
        }
        $field->label( $f->{label} );
        $field->basename( $basename );
        $field->type( $f->{type} );
        $field->order( $f->{order} );
        $field->removable( $f->{removable} );
        $field->options( to_json( $f->{options} ) );
        $field->save
          or return _send_json_response( $app, { error => $field->errstr } );
    }
    return $new
      ? _send_json_response( $app, { status => 1, form_id => $form->id } )
      : list_forms($app);
}

sub show_form {
    my $app    = shift;
    my $q      = $app->{query};
    my $plugin = MT->component('ContactForms');
    my $tmpl   = $plugin->load_tmpl('show_form.tmpl');
    my $form   = MT->model('contact_form')->load( $q->param('id') );
    my $param  = {
        blog_id   => $app->blog->id,
        form_id   => $form->id,
        form_html => $form->as_html(),
    };
    return $app->build_page( $tmpl, $param );
}

sub show_inquiry {
    my $app     = shift;
    my $q       = $app->{query};
    my $plugin  = MT->component('ContactForms');
    my $tmpl    = $plugin->load_tmpl('view_inquiry.tmpl');
    my $obj     = MT->model('contact_form_inquiry')->load( $q->param('id') );
    unless ($obj) {
        return $app->error("The inquiry you are attempting to view could not be found. Perhaps it has been deleted, or the URL you entered is incorrect.");
    }
    $obj->load_meta_fields();

    my $form    = $obj->form();
    my $ts      = $obj->{created_on};

    $obj->status( MT->model('contact_form_inquiry')->READ() );
    $obj->save;

    my @fields =
      MT->model('contact_form_field')->load( { form_id => $obj->form_id },
        { sort => 'order', direction => 'ascend' } );
    my $values = [];
    my $count = 0;
    our ($subject_label,$body_label);
    foreach my $f (@fields) {
        if ( $f->basename eq 'body' || $f->basename eq 'subject' ) {
            my $var = $f->basename . '_label';
            no strict 'refs';
            ${$var} = $f->label;
        } else {
            my $v = $obj->meta('formfield.'.$f->basename);
            my $val = $v ? $v : '';
            push @$values,
              {
                  '__first__' => $count == 0,
                  '__last__'  => $count == ($#fields - 2),
                  '__even__'  => $count % 2 == 0,
                  '__odd__'   => $count % 2 == 1,
                  '__count__' => $count,
                  'label'     => $f->label,
                  'value'     => $val,
              };
            $count++;
        }
    }
    my $param   = {
        blog_id       => $app->blog->id,
        form_id       => $form->id,
        form_html     => $form->as_html(),
        id            => $obj->id,
        from          => $obj->from_name,
        from_email    => $obj->from_email,
        status        => $obj->status,
        flagged       => $obj->flagged,
        subject       => $obj->subject,
        subject_label => $subject_label,
        body          => $obj->text,
        body_label    => $body_label,
        form          => $form->title,
        field_loop    => $values,
        return_args   => MT::Util::encode_url('__mode=cf.list_inquiries&blog_id='.$app->blog->id),
        date          => relative_date( $obj->created_on, time ),
    };
    return $app->build_page( $tmpl, $param );
}

sub create_form {
    my $app    = shift;
    my $q      = $app->{query};
    my $plugin = MT->component('ContactForms');
    my $step   = $q->param('step');
    my $tmpl   = $plugin->load_tmpl('create_form.tmpl');
    my $struct = _load_options();
    my $param  = {
        blog_id    => $app->blog->id,
        options_js => to_json($struct),
    };
    return $app->build_page( $tmpl, $param );
}

sub list_forms {
    my $app   = shift;
    my $q     = $app->{query};
    my %param = @_;

    my $code = sub {
        my ( $obj, $row ) = @_;
        $row->{'id'}        = $obj->id;
        $row->{'title'}     = $obj->title;
        $row->{'inquiries'} = $obj->reply_count;
        my $ts = $row->{created_on};
        $row->{'date'} = relative_date( $ts, time );
    };

    my %terms = (
        #        author_id => $app->user->id,
        blog_id => $app->blog->id
    );

    my %args = (
        sort      => 'created_on',
        direction => 'descend',
    );

    my %params = ( form_deleted => $q->param('form_deleted') ? 1 : 0 );

    my $plugin = MT->component('ContactForms');

    $app->listing(
        {
            type           => 'contact_form',    # the ID of the object in the registry
            terms          => \%terms,
            args           => \%args,
            listing_screen => 1,
            code           => $code,
            template       => $plugin->load_tmpl('list_forms.tmpl'),
            params         => \%params,
        }
    );
}

sub list_inquiries {
    my $app   = shift;
    my $q     = $app->{query};
    my %param = @_;

    my $code = sub {
        my ( $obj, $row ) = @_;
        my $form = $obj->form;
        $row->{'id'}         = $obj->id;
        $row->{'from'}       = $obj->from_name;
        $row->{'from_email'} = $obj->from_email;
        $row->{'subject'}    = $obj->subject;
        $row->{'status'}     = $obj->status;
        $row->{'flagged'}    = $obj->flagged;
        $row->{'form'}       = $form->title;
        $row->{'form_id'}    = $obj->form_id;
        my $ts = $row->{created_on};
        $row->{'date'} = relative_date( $ts, time );
    };

    my %terms =
      ( 'status' => { 'not' => MT->model('contact_form_inquiry')->JUNK() }, );

    my $clause = ' = cf_reply_form_id';
    my %args   = (
        sort      => 'created_on',
        direction => 'descend',
        join => MT->model('contact_form')->join_on( undef, { id => \$clause } ),
    );

    my %params = (
        deleted => $q->param('deleted') ? 1 : 0,
        status  => $q->param('status'),
        flagged => $q->param('flagged'),
        flagged_total => MT->model('contact_form_inquiry')
          ->count( { blog_id => $app->blog->id, 'flagged' => 1 } ),
        unread_total => MT->model('contact_form_inquiry')->count(
            {
                blog_id  => $app->blog->id,
                'status' => MT->model('contact_form_inquiry')->UNREAD()
            }
        ),
        total => MT->model('contact_form_inquiry')->count(
            {
                blog_id => $app->blog->id,
                'status' =>
                  { 'not' => MT->model('contact_form_inquiry')->JUNK() }
            }
        ),
    );
    if ( my $form_id = $q->param('form_id') ) {
        my $form = MT->model('contact_form')->load($form_id);
        $terms{form_id}    = $form_id;
        $params{form_id}   = $form_id;
        $params{form_name} = $form ? $form->title : "Contact Form Deleted";
    }

    my $plugin = MT->component('ContactForms');

    $app->listing(
        {
            type =>
              'contact_form_inquiry',    # the ID of the object in the registry
            terms          => \%terms,
            args           => \%args,
            listing_screen => 1,
            code           => $code,
            template       => $plugin->load_tmpl('list_inquiries.tmpl'),
            params         => \%params,
        }
    );
}

sub del_form {
    my ($app) = @_;
    $app->validate_magic or return;
    my @forms = $app->param('id');
    for my $form_id (@forms) {
        my $form = MT->model('contact_form')->load($form_id) or next;
        $form->remove;
    }
    $app->add_return_arg( form_deleted => 1 );
    $app->call_return;
}

sub get_inquiry {
    my $app           = shift;
    my $q             = $app->{query};
    my $id            = $q->param('id');
    my $r             = MT->model('contact_form_inquiry')->load($id);
    my $former_status = $r->status();
    $r->status( MT->model('contact_form_inquiry')->READ() );
    $r->save;
    $r->{column_values}->{text} =~
      s!(^|\s)(https?://\S+)!$1<a target="_blank" href="$2">$2</a>!gs;
    $r->{column_values}->{text} =~
s!(https?://){0}(www\.\w+\.\w+)!<a target="_blank" href="http://$2">$2</a>!gs;
    my $form = $r->form;
    my @fields =
      MT->model('contact_form_field')->load( { form_id => $r->form_id },
        { sort => 'order', direction => 'ascend' } );
    my @values;

    foreach my $f (@fields) {
        unless ( $f->basename eq 'body' || $f->basename eq 'subject' ) {
            my $v = $r->meta('formfield.'.$f->basename);
            my $val = $v ? $v : '';
            push @values,
              {
                label => $f->label,
                val   => $val,
              };
        }
    }

    my ( $date_format, $datetime_format );
    $date_format     = MT::App::CMS::LISTING_DATE_FORMAT();
    $datetime_format = MT::App::CMS::LISTING_DATETIME_FORMAT();

    my $ts             = $r->created_on;
    my $date_formatted = format_ts( $date_format, $ts, $app->blog,
        $app->user ? $app->user->preferred_language : undef );
    my $time_formatted = format_ts( $datetime_format, $ts, $app->blog,
        $app->user ? $app->user->preferred_language : undef );

    return _send_json_response(
        $app,
        {
            id                 => $r->id,
            form_id            => $r->form_id,
            form_name          => $form->title,
            subject            => $r->subject,
            from               => $r->from_name,
            from_email         => $r->from_email,
            date               => ts2iso( $r->created_on ),
            date_formatted     => $date_formatted,
            datetime_formatted => $time_formatted,
            flagged            => $r->flagged,
            status             => $r->status,
            former_status      => $former_status,
            text               => html_text_transform( $r->text ),
            fields             => \@values,
        }
    );
}

sub toggle_flagged {
    my $app = shift;
    my $q   = $app->{query};
    my $id  = $app->param('id');
    my $i   = MT->model('contact_form_inquiry')->load($id);
    $i->flagged( !$i->flagged );
    $i->save;
    return _send_json_response(
        $app,
        {
            id      => $i->id,
            flagged => $i->flagged,
        }
    );
}

sub itemset_flag {
    my $app       = shift;
    my $q         = $app->{query};
    my @inquiries = $app->param('id');
    for my $id (@inquiries) {
        my $i = MT->model('contact_form_inquiry')->load($id);
        $i->flagged(1);
        $i->save;
    }
    $app->add_return_arg( flagged => 'yes' );
    $app->call_return;
}

sub itemset_junk {
    my $app       = shift;
    my $q         = $app->{query};
    my @inquiries = $app->param('id');
    for my $id (@inquiries) {
        my $i = MT->model('contact_form_inquiry')->load($id);
        $i->status( MT->model('contact_form_inquiry')->JUNK() );
        $i->save;
    }
    $app->add_return_arg( status => 'junk' );
    $app->call_return;
}

sub itemset_mark_read {
    my $app       = shift;
    my $q         = $app->{query};
    my @inquiries = $app->param('id');
    for my $id (@inquiries) {
        my $i = MT->model('contact_form_inquiry')->load($id);
        $i->status( MT->model('contact_form_inquiry')->READ() );
        $i->save;
    }
    $app->add_return_arg( status => 'read' );
    $app->call_return;
}

sub itemset_mark_unread {
    my $app       = shift;
    my $q         = $app->{query};
    my @inquiries = $app->param('id');
    for my $id (@inquiries) {
        my $i = MT->model('contact_form_inquiry')->load($id);
        $i->status( MT->model('contact_form_inquiry')->UNREAD() );
        $i->save;
    }
    $app->add_return_arg( status => 'unread' );
    $app->call_return;
}

sub itemset_unflag {
    my $app       = shift;
    my $q         = $app->{query};
    my @inquiries = $app->param('id');
    for my $id (@inquiries) {
        my $i = MT->model('contact_form_inquiry')->load($id);
        $i->flagged(0);
        $i->save;
    }
    $app->add_return_arg( flagged => 'no' );
    $app->call_return;
}

sub delete_inquiry {
    my $app       = shift;
    my $q         = $app->{query};
    my $id        = $q->param('id');
    my @inquiries = $app->param('id');
    for my $i_id (@inquiries) {
        MT->model('contact_form_inquiry')
          ->remove( { id => $i_id, blog_id => $app->blog->id } );
    }
    if ( $q->param('json') ) {
        return _send_json_response( $app, { deleted => 1, } );
    }
    $app->add_return_arg( deleted => 1 );
    $app->call_return;
}

sub load_custom_fields {
    return {
        contact_form => {
            label      => 'Contact Form',
            no_default => 1,
            order      => 501,
            column_def => 'integer',
            field_html => sub {
                my $app  = MT->instance;
                my $blog = $app->blog;
                my $html =
'<select name="<mt:var name="field_name">" id="<mt:var name="field_id">">';
                $html .=
'<option value="" <mt:if name="field_value" eq=""> selected="selected"</mt:if>>None Selected</option>';
                my @forms =
                  MT->model('contact_form')->load( { blog_id => $blog->id } );
                foreach my $f (@forms) {
                    $html .=
                        '<option value="'
                      . $f->id
                      . '"<mt:if name="field_value" eq="'
                      . $f->id
                      . '"> selected="selected"</mt:if>>';
                    $html .= $f->title . '</option>';
                }
                $html .= '</select>';
                return $html;
            },
            field_html_params => sub {
                my ( $key, $tmpl_key, $tmpl_param ) = @_;
                my $app     = MT->instance;
                my $blog    = $app->blog;
                my $form_id = $tmpl_param->{value} || undef;
                if ($form_id) {

                    # load Form?
                }
            },
        },
    };
}

sub custom_field_params {
    my ( $key, $tmpl_key, $tmpl_param ) = @_;
    my $app  = MT->instance;
    my $blog = $app->blog;
}

sub xfrm_split_pane {
    my ( $cb, $app, $html_ref ) = @_;
    $$html_ref =~
s{(<table id="contact_form_inquiry-listing-table")}{<div id="MySplitter"><div id="TopPane">$1}m;

    my $bottom = <<EOH;
</div> <!-- this closes the #TopPane element inserted by a callback -->
<div id="BottomPane">
  <div id="inquiry-header" class="pkg">
    <div id="inquiry-main" class="inquiry-props">
      <label>Subject:</label><div id="inquiry-subject" class="prop"></div>
      <label>From:</label><div id="inquiry-from" class="prop"></div>
      <label>Date:</label><div id="inquiry-date" class="prop"></div>
    </div>
    <div id="inquiry-extra" class="inquiry-props">
    </div>
    <button id="button-reply" class="reply-button" onclick="return sendReply(viewed);">Reply</button>
    <button id="button-delete" class="reply-button" onclick="return deleteInquiry(viewed);">Delete</button>
    <button id="button-flag" class="reply-button" onclick="return toggleFlagInquiry(viewed);"></button>
  </div>
  <div id="inquiry-text">
  </div>
</div>
</div> <!-- this closes the #MySplitter element inserted by a callback -->
EOH
    $$html_ref =~ s{(</table>)}{</table>$bottom}m;

    return 1;
}

sub _send_json_response {
    my ( $app, $result ) = @_;
    my $json = to_json($result);
    $app->send_http_header("");
    $app->print($json);
    return $app->{no_print_body} = 1;
    return undef;
}

sub _load_fields {
    my $form = shift;
    my @fields =
      MT->model('contact_form_field')->load( { form_id => $form->id },
        { sort => 'order', direction => 'ascend' } );

    my @struct;
    foreach my $f (@fields) {
        my $options = ($f->options && $f->options ne '') ? $f->options : '{}';
        my $s = {
            label     => $f->label,
            basename  => $f->basename,
            type      => $f->type,
            order     => $f->order,
            removable => $f->removable,
            options   => from_json( $options ),
            id        => $f->id,
            new       => 0,
            removed   => 0,
        };
        push @struct, $s;
    }
    return \@struct;
}

sub _load_options {
    my $plugin  = MT->component('ContactForms');
    my $options = $plugin->registry('contact_form_field_types');
    my $struct;

    foreach my $key ( sort keys %$options ) {
        my $opt = $options->{$key};
        $struct->{$key}->{'label'} = &{ $opt->{'label'} };
        foreach ( keys %{ $opt->{'options'} } ) {
            $struct->{$key}->{'meta'}->{$_}->{'html'} =
                '<label>'
              . &{ $opt->{'options'}->{$_}->{'label'} } . ': '
              . '<input class="field-option-'
              . $_ . '" '
              . 'type="'
              . $opt->{'options'}->{$_}->{'type'} . '" '
              . 'name="ovalue['
              . $_
              . ']" value="" size="'
              . $opt->{'options'}->{$_}->{'size'}
              .'" /></label>';
        }
    }

    foreach my $key ( keys %$options ) {
        my $opt = $options->{$key};
        foreach ( keys %{ $opt->{'options'} } ) {
            $struct->{$key}->{$_} =
                '<label>' 
              . $_
              . ': <input class="field-option-'
              . $_
              . '" type="'
              . $opt->{'options'}->{$_}
              . '" name="ovalue['
              . $_
              . ']" value="" size="6" /></label>';
        }
    }
    return $struct;
}

sub _no_form_context {
    my $ctx = shift;
    my $tag = lc $ctx->stash('tag');
    return $ctx->error(
        MT->translate(
            "You used an [_1] tag without a contact form context set up.",
            "MT$tag"
        )
    );
}

sub _no_field_context {
    my $ctx = shift;
    my $tag = lc $ctx->stash('tag');
    return $ctx->error(
        MT->translate(
            "You used an [_1] tag without a contact form field context set up.",
            "MT$tag"
        )
    );
}

1;
