# (C) 2009 Byrne Reese, iThemes LLC. All Rights Reserved.
# This code cannot be redistributed without permission from
# the copyright holders.

package ContactForms::Form;

use strict;

use base qw( MT::Object );

__PACKAGE__->install_properties(
    {
        column_defs => {
            'id'                => 'integer not null auto_increment',
            'blog_id'           => 'integer not null',
            'title'             => 'string(255) not null',
            'from'              => 'string(255) not null',
            'reply_to'          => 'string(255) not null',
            'reply_count'       => 'integer not null',
            'allow_anonymous'   => 'smallint not null',
            'status'            => 'smallint not null',
            'subscribers'       => 'text',
            'send_autoreply'    => 'smallint not null',
            'autoreply_subject' => 'string(100)',
            'autoreply_text'    => 'text',
            'confirmation_text' => 'text',
        },
        indexes => {
            created_on  => 1,
            modified_on => 1,
        },
        defaults => {
            reply_count     => 0,
            allow_anonymous => 1,
        },
        audit         => 1,
        datasource    => 'cf_form',
        primary_key   => 'id',
        class_type    => 'contact_form',
        child_classes => [ 'ContactForms::Inquiry', 'ContactForms::FormField' ],
    }
);

sub OPEN ()   { 1 }
sub CLOSED () { 2 }

use Exporter;
*import = \&Exporter::import;
use vars qw( @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw( OPEN CLOSED );
%EXPORT_TAGS = ( constants => [qw(OPEN CLOSED)] );

sub remove {
    my $form = shift;
    if ( ref $form ) {
        $form->remove_children( { key => 'form_id' } ) or return;
    }
    $form->SUPER::remove(@_);
}

sub fields {
    my $form   = shift;
    my @fields = $form->{__formfields};
    unless ($#fields) {
        @fields = MT->model('contact_form_field')->load( { form_id => $form->id },
            { sort => 'order', direction => 'ascend' } )
          or return $form->error(
            MT->translate(
                "Load of form fields for form '[_1]' failed: [_2]", $form->id,
                $form->errstr
            )
          );
        $form->{__formfields} = @fields;
    }
    return @fields;
}

sub as_html {
    my $form   = shift;
    my $app    = MT->instance;
    my $html   = '';
    my $cgi    = MT->config('CGIPath') . MT->config('AdminScript');
    my $static = File::Spec->catfile(
        MT->config('StaticWebPath'), 'plugins',
        'ContactForms',              'js',
        'blog.js'
    );
    my $blog_id = $app->blog->id;
    my $form_id = $form->id;
    $html .= <<EOH;
<script type="text/javascript" src="$static"></script>
<div id="contactform">
  <div id="comment-greeting"></div>
  <form method="post" action="$cgi" id="contact-form" name="contact_form">
    <input type="hidden" name="__mode" value="cf.submit_reply" />
    <input type="hidden" name="blog_id" value="$blog_id" />
    <input type="hidden" name="form_id" value="$form_id" />
    <fieldset id="from">
      <div id="field-from-name">  
        <label for="name">Name</label>  
        <input id="name" name="name" size="30" value="" />  
      </div> 
      <div id="field-from-email">  
        <label for="email">Email</label>  
        <input id="email" name="email" size="30" value="" />  
      </div> 
    </fieldset>
    <fieldset id="fields">
EOH
    require JSON;
    my @fields = MT->model('contact_form_field')->load( { form_id => $form->id },
        { sort => 'order', direction => 'ascend' } );
    my $types = MT->registry('contact_form_field_types');

    foreach my $f (@fields) {
        my $code = $types->{ $f->type }->{handler};
        my $func = MT->handler_to_coderef($code);
        my $opts = $f->options ? JSON::from_json( $f->options ) : {};
        my $a    = {};
        foreach (keys %$opts) {
            my $key = $_;
            my $val = $opts->{$key};
            $a->{$key} = $val;
        }
        $html .= $func->( $f, $a );
    }
    $html .= <<EOH;
    </fieldset>
    <div id="comments-open-captcha"></div>
    <div id="contactform-footer">
      <input type="submit" accesskey="s" name="post" id="contactform-submit" value="Submit" />
    </div>
  </form>
</div>
<script type="text/javascript">
cfContactFormOnLoad();
</script>

EOH
    return $html;
}

1;
