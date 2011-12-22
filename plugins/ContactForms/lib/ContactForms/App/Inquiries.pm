package ContactForms::App::Inquiries;
use strict;

use base 'MT::App::Comments';
use MT;
use MT::Util qw( is_valid_email );

use ContactForms::Inquiry;

sub id { 'inquiries' }

sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->add_methods( "cf.post" => \&cf_post, );
    $app->{plugin_template_path} = '';
    $app->{template_dir}         = '';
    $app;
}

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_);
    $app->set_no_cache;
    $app->{default_mode} = 'post';
    my $q = $app->param;

    if ( my $blog_id = $q->param('blog_id') ) {
        if ( $blog_id ne int($blog_id) ) {
            die $app->translate("Invalid request");
        }
    }

    ## We don't really have a __mode parameter, because we have to
    ## use named submit buttons for Preview and Post. So we hack it.

    if (   $q->param('post')
        || $q->param('post_x')
        || $q->param('post.x') )
    {
        $app->mode('cf.post');
    }
    elsif ( $app->path_info =~ /captcha/ ) {
        $app->mode('generate_captcha');
    }
}

sub load_core_tags {
    return {};
}

sub cf_post {
    my $app = shift;
    my $q   = $app->param;

#    MT->log("Inquiry received");

    return $app->error( $app->translate("Invalid request") )
      if $app->request_method() ne 'POST';

    my $id   = $q->param('form_id');
    my $form = MT->model('contact_form')->load($id);

#    MT->log({ blog_id => $form->blog_id, message => "Processing inquiry for " . $form->name });

    return $app->error( 'Could not load form with ID of ' . $id ) unless $form;

    if ( my $banlist = MT->model('ipbanlist') ) {
        my $iter = $banlist->load_iter( { blog_id => $form->blog_id } );
        while ( my $ban = $iter->() ) {
            my $banned_ip = $ban->ip;
            if ( $app->remote_ip =~ /^$banned_ip/ ) {
                return $app->handle_error( $app->translate("Invalid request") );
            }
        }
    }

    my $blog = $app->model('blog')->load( $form->blog_id )
      or return $app->error(
        $app->translate( 'Can\'t load blog #[_1].', $form->blog_id ) );

    my $armor = $q->param('armor');
    if ( defined $armor ) {

        # For this to work, we must create a site path exactly like
        # <MTBlogSitePath> does.
        my $path = $blog->site_path;
        $path .= '/' unless $path =~ m!/$!;
        my $site_path_sha1 = MT::Util::perl_sha1_digest_hex($path);
        if ( $armor ne $site_path_sha1 ) {
            return $app->handle_error( $app->translate("Invalid request") );
        }
    }

    # Run all the Comment-throttling callbacks
    #    my $passed_filter
    #        = MT->run_callbacks( 'CommentThrottleFilter', $app, $form );

   #    $passed_filter
   #        || return $app->handle_error( $app->translate("_THROTTLED_COMMENT"),
   #        "403 Throttled" );

    my $cfg = $app->config;

    # Commented out because I don't know what it does
    #    if ( my $state = $q->param('comment_state') ) {
    #        require MT::Serialize;
    #        my $ser = MT::Serialize->new( $cfg->Serializer );
    #        $state = $ser->unserialize( pack 'H*', $state );
    #        $state = $$state;
    #        for my $f ( keys %$state ) {
    #            $q->param( $f, $state->{$f} );
    #        }
    #    }

    if ( $form->status == ContactForms::Form->CLOSED() ) {
        return $app->SUPER::handle_error(
            $app->translate(
                "I am sorry, but this contact form has been disabled.")
        );
    }

    my $text = $q->param('body') || '';
    $text =~ s/^\s+|\s+$//g;
    if ( $text eq '' ) {
        return $app->SUPER::handle_error(
            $app->translate("Inquiry text is required.") );
    }

    # validate session parameter
    if ( my $sid = $q->param('sid') ) {
        my ( $sess_obj, $commenter ) = $app->SUPER::_get_commenter_session();
        if ( $sess_obj && $commenter && ( $sess_obj->id eq $sid ) ) {

            # well, everything is okay
        }
        else {
            return $app->SUPER::handle_error(
                $app->translate(
                    "Your session has expired. Please sign in again to comment."
                )
            );
        }
    }

    my ( $inquiry, $commenter ) = _make_inquiry( $app, $form, $blog );
    return $app->SUPER::handle_error(
        $app->translate( "An error occurred: [_1]", $app->errstr() ) )
      unless $inquiry;

    #    my $remember = $q->param('bakecookie') || 0;
    #    $remember = 0 if $remember eq 'Forget Info';    # another value for '0'
    #    if ( $commenter && $remember ) {
    #        $app->_extend_commenter_session( Duration => "+1y" );
    #    }

    if ( ! $commenter && ! $form->allow_anonymous ) {
        return $app->SUPER::handle_error(
            $app->translate("Registration is required.") );
    }
    if (    #$blog->require_comment_emails() &&
        !$commenter && !(
               $inquiry->from_name
            && $inquiry->from_email
            && is_valid_email( $inquiry->from_email )
        )
      )
    {
        return $app->SUPER::handle_error(
            $app->translate("Name and email address are required.") );
    }
    if ( $blog->allow_unreg_comments() ) {
        $inquiry->from_email( $q->param('email') )
          unless $inquiry->from_email();
    }

    if ( $inquiry->from_email ) {
        if ( my $fixed = is_valid_email( $inquiry->from_email ) ) {
            $inquiry->from_email($fixed);
        }
        elsif ( $inquiry->from_email =~ /^[0-9A-F]{40}$/i ) {

            # It's a FOAF-style mbox hash; accept it if blog config says to.
            return $app->SUPER::handle_error("A real email address is required")
              if ( !$commenter );
        }
        else {
            return $app->SUPER::handle_error(
                $app->translate(
                    "Invalid email address '[_1]'",
                    $inquiry->from_email
                )
            );
        }
    }

    if (
        !$commenter
        && ( my $provider =
            MT->effective_captcha_provider( $blog->captcha_provider ) )
      )
    {
        unless ( $provider->validate_captcha($app) ) {
            return $app->SUPER::handle_error(
                $app->translate("Text entered was wrong.  Try again.") );
        }
    }
    $inquiry = eval_inquiry( $app, $blog, $commenter, $inquiry, $form );

    # not sure i need this since I don't support preview
    #    return $app->preview('pending') unless $inquiry;

    $app->user($commenter);

    $form->reply_count(
        ContactForms::Inquiry->count( { form_id => $form->id } ) );
    $form->save or MT->log( { message => $form->errstr } );

    if ( $form->send_autoreply ) {
        _send_inquiry_autoreply( $app, $form, $inquiry, $commenter );
    }

    my @subscribers = split( /,/, $form->subscribers );
    foreach my $s (@subscribers) {
        MT->log(
            { message => "Notification about new inquiry send to " . $s } );
        _send_inquiry_notification( $app, $form, $inquiry, $s );
    }

    my $tmpl;
    $tmpl =
      MT->model('template')->load( { type => 'inquiry_response', blog_id => $blog->id } )
      or $tmpl =
      MT->model('template')->load( { type => 'inquiry_response', blog_id => 0 } );
    unless ($tmpl) {
        MT->log(
            {
                blog_id => $blog->id,
                message => "Could not load the Contact Form Response template."
            }
        );
        return $app->redirect( $blog->site_url );
    }
    my $ctx = $tmpl->context;
    $tmpl->param(
        {
            'body_class'                    => 'mt-comment-confirmation',
            'contactform_response_template' => 1,
        }
    );
    $ctx->stash( 'contactform', $form );
    $ctx->stash( 'reply',       $inquiry );
    $ctx->stash( 'blog',        $app->blog );
    $ctx->stash( 'commenter',   $commenter ) if $commenter;
    my $html = $tmpl->output();
    $html = $tmpl->errstr unless defined $html;
    return $html;
}

sub eval_inquiry {
    my $app = shift;
    my ( $blog, $commenter, $inquiry, $form ) = @_;

    if (   $commenter
        && ( $commenter->type == MT::Author::COMMENTER() )
        && (
            $commenter->commenter_status( $blog->id ) == MT::Author::BLOCKED() )
      )
    {
        return undef;
    }
    return $inquiry;
}

sub _make_inquiry {
    my ( $app, $form, $blog ) = @_;
    my $q = $app->param;

    my $nick  = $q->param('name');
    my $email = $q->param('email');

    MT->log( { message => "1: nick: $nick, email: $email" } );

    my ( $sess_obj, $commenter );
    if ( $blog->accepts_registered_comments ) {
        ( $sess_obj, $commenter ) = $app->SUPER::_get_commenter_session();
    }
    if ( $commenter && ( 'do_reply' ne $app->mode ) ) {
        if ( MT::Author::AUTHOR() == $commenter->type ) {
            if ( $blog->commenter_authenticators !~ /MovableType/ ) {
                $commenter = undef;
            }
            else {
                unless (
                    $app->SUPER::_check_commenter_author( $commenter, $blog->id ) )
                {
                    $app->error( $app->translate('Permission denied.') );
                    return ( undef, undef );
                }
            }
        }
    }
    if ($commenter) {
        $nick = $commenter->nickname()
          || $app->translate('Registered User');
        $email = $commenter->email();
    }
    MT->log( { message => "2: nick: $nick, email: $email" } );

    my $inquiry = MT->model('contact_form_inquiry')->new;
    $inquiry->blog_id( $app->blog->id );
    $inquiry->form_id( $form->id );
    $inquiry->subject( $q->param('subject') );
    $inquiry->text( $q->param('body') );
    $inquiry->status( MT->model('contact_form_inquiry')->UNREAD() );
    if ($commenter) {
        $inquiry->from_author( $commenter->id );
    }
    $inquiry->from_name($nick);
    $inquiry->from_email($email);
    $inquiry->junk_status(0);
    
    $inquiry->load_meta_fields();
    
    # TODO - save structured data
    my @fields = MT->model('contact_form_field')->load( { form_id => $form->id }, );
    my @submitted_fields;
    foreach my $f (@fields) {
        unless ( $f->basename eq 'subject' || $f->basename eq 'body' ) {
            my $value;
            if ($f->type eq 'checkbox') {
                my $beacon = $q->param( $f->basename . '_beacon' );
                $value = ( $q->param($f->basename) ? $q->param($f->basename) : $beacon );
            } else {
                $value = $q->param( $f->basename );
            }
            $inquiry->meta('formfield.'.$f->basename,$value);

            push @submitted_fields,
              {
                label => $f->label,
                value => $value,
              };

        }
    }

    $inquiry->save
      or return $app->error( 'Could not save inquiry: ' . $inquiry->errstr );

    $inquiry->{__fields} = \@submitted_fields;

    # TODO - Send through junk filters
    #    MT->log({message => "About to send inquiry through junk filters"});
    _post_junk_filter($app,$inquiry);

    # TODO - Save inquiry again

    return ( $inquiry, $commenter );
}

sub _post_junk_filter {
    my $app = shift;
    my ($inquiry) = @_;

    # Score with junk filters as if this were a comment;
    # if it scores as junk, set state of post to 'review'
    my $comment = $app->model('comment')->new;

    my $user = $app->user;
    if ($user) {
        $comment->author( $user->nickname || $user->name );
        $comment->email( $user->email );
    }
    else {
        $comment->author( $inquiry->from_name );
        $comment->email( $inquiry->from_email );
    }
    $comment->ip( $app->remote_ip );
    $comment->blog_id( $inquiry->blog_id );

    my $text = $inquiry->subject || "";
    $text .= "\n"
      . ( MT->apply_text_filters( $inquiry->text || '', ['__default__'] ) );

    # Include text from any custom fields that were assigned too
    my $fields = $inquiry->{__fields};
    foreach (@$fields) {
        $text .= "\n" . $_->{value} if defined $_;
    }

    $comment->text($text);

    # Assign visible status by default if entry status is
    # set to release
    my $status = $inquiry->status;

    require MT::JunkFilter;
    MT::JunkFilter->filter($comment);
    if ( $comment->is_junk ) {

        # forcibly set to review
        $status = ContactForms::Inquiry::JUNK();
    }

    if ( defined $status ) {
        $inquiry->status($status);
        my $log = $comment->junk_log;
        $inquiry->junk_log($log)
          if defined $log;
    }

    return;
}

sub _send_inquiry_autoreply {
    my $app = shift;
    my ( $form, $inquiry, $commenter, $static ) = @_;
    my $cfg = $app->config;

    my $blog = $app->blog;

    my $token = $app->make_magic_token;

    my $subject =
      ( $form->autoreply_subject && $form->autoreply_subject ne '' )
      ? $form->autoreply_subject
      : $app->translate('Thank you for contacting us');
    my $param = {
        blog           => $blog,
        author         => $commenter,
        form_name      => $form->title,
        from_name      => $inquiry->from_name,
        from_email     => $inquiry->from_email,
        autoreply_text => $form->autoreply_text,
    };

    #    local MT->instance->{component} = 'ContactForms';
    my $body = MT->build_email( 'inquiry_confirm.tmpl', $param );

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
        id => 'inquiry_confirm',
        To => $inquiry->from_email,
        $from_addr ? ( From       => $from_addr ) : (),
        $reply_to  ? ( 'Reply-To' => $reply_to )  : (),
        Subject => $subject,
    );
    my $charset = $cfg->MailEncoding || $cfg->PublishCharset;
    $head{'Content-Type'} = qq(text/plain; charset="$charset");

    ## Save it in session to purge later
    require MT::Session;
    my $sess = MT::Session->new;
    $sess->id($token);
    $sess->kind('CR');    # CR == Commenter Registration
    $sess->email( $inquiry->from_email );
    $sess->name('contactform_autoreply');
    $sess->start(time);
    $sess->save;

    MT::Mail->send( \%head, $body )
      or die MT::Mail->errstr();
}

sub _send_inquiry_notification {
    my $app = shift;

    MT->log( { message => "Sending inquiry notification..." } );
    my ( $form, $inquiry, $subscriber ) = @_;
    my $fields = $inquiry->{__fields};
    my $cfg    = $app->config;
    my $blog   = $app->blog;
    my $token  = $app->make_magic_token;

    my $link = $app->base
      . $app->uri(
        mode => 'cf.list_inquiries',
        args => {
            blog_id => $blog->id,
            form_id => $form->id,
        }
      )
      . "#reply-"
      . $inquiry->id;
    my $subject = $app->translate('A new inquiry has been received');
    my $param   = {
        blog       => $blog,
        form_name  => $form->title,
        from_name  => $inquiry->from_name,
        from_email => $inquiry->from_email,
        reply_text => $inquiry->text,
        fields     => $fields,
        reply_link => $link,
    };

    #    local MT->instance->{component} = 'ContactForms';
    my $body = MT->build_email( 'inquiry_notification.tmpl', $param );

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
        id => 'inquiry_notification',
        To => $subscriber,
        $from_addr ? ( From       => $from_addr ) : (),
        $reply_to  ? ( 'Reply-To' => $reply_to )  : (),
        Subject => $subject,
    );
    my $charset = $cfg->MailEncoding || $cfg->PublishCharset;
    $head{'Content-Type'} = qq(text/plain; charset="$charset");

    ## Save it in session to purge later
    require MT::Session;
    my $sess = MT::Session->new;
    $sess->id($token);
    $sess->kind('CR');    # CR == Commenter Registration
    $sess->email( $inquiry->from_email );
    $sess->name('contactform_inquiry_notify');
    $sess->start(time);
    $sess->save;

    MT::Mail->send( \%head, $body )
      or die MT::Mail->errstr();
}

1;
