# (C) 2009 Byrne Reese, iThemes LLC. All Rights Reserved.
# This code cannot be redistributed without permission from
# the copyright holders.

package ContactForms::Inquiry;

use strict;
use base qw( MT::Object MT::Taggable );

__PACKAGE__->install_properties(
    {
        column_defs => {
            'id'          => 'integer not null auto_increment',
            'blog_id'     => 'integer not null',
            'form_id'     => 'integer not null',
            'subject'     => 'string(255) not null',
            'text'        => 'text not null',
            'flagged'     => 'smallint not null',
            'status'      => 'smallint not null',
            'from_author' => 'integer',
            'from_email'  => 'string(255) not null',
            'from_name'   => 'string(255) not null',
            'junk_status' => 'smallint not null',
            'junk_log'    => 'string meta',
        },
        indexes => {
            created_on  => 1,
            modified_on => 1,
        },
        defaults => {
            flagged => 0,
            status  => 1,
        },
        meta          => 1,
        audit         => 1,
        datasource    => 'cf_reply',
        primary_key   => 'id',
        class_type    => 'contact_form_reply',
        child_classes => ['ContactForms::InquiryValue'],
    }
);

sub UNREAD ()  { 1 }
sub READ ()    { 2 }
sub REPLIED () { 3 }
sub JUNK ()    { 5 }

use Exporter;
*import = \&Exporter::import;
use vars qw( @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw( UNREAD READ REPLIED JUNK );
%EXPORT_TAGS = ( constants => [qw(READ UNREAD REPLIED JUNK)] );

sub is_junk {
    $_[0]->junk_status == JUNK;
}

sub is_not_junk {
    $_[0]->junk_status != JUNK;
}

sub form {
    my $inquiry = shift;
    my $form    = $inquiry->{__form};
    unless ($form) {
        my $form_id = $inquiry->form_id;
        return undef unless $form_id;
        require ContactForms::Form;
        $form = ContactForms::Form->load( $inquiry->form_id )
          or return $inquiry->error(
            MT->translate(
                "Load of form '[_1]' failed: [_2]", $form_id,
                ContactForms::Form->errstr
            )
          );
        $inquiry->{__form} = $form;
    }
    return $form;
}

# This is for compatibility with the junk filtering system.
sub entry {
    return undef;
}

sub author {
    my $inquiry = shift;
    if ( !@_ && $inquiry->commenter_id ) {
        require MT::Author;
        if ( my $auth = MT::Author->load( $inquiry->commenter_id ) ) {
            return $auth->nickname;
        }
    }
    return $inquiry->column( 'from_name', @_ );
}

sub remove {
    my $v = shift;
    if ( ref $v ) {
        $v->remove_children( { key => 'reply_id' } ) or return;
    }

#    my $form = $v->form;
#    $form->reply_count( ContactForms::Inquiry->count( { form_id => $form->id }));
#    $form->save;
    $v->SUPER::remove(@_);
}

sub load_meta_fields {
    my $self = shift;
    return if ($self->{'__meta_loaded'});
    my $iter = eval {
        require MT::Object;
        my $driver = MT::Object->driver;
        MT->model('contact_form_field')->load_iter({ form_id => $self->form_id });
    };
    return unless $iter;

    my ( %meta );
    while (my $field = $iter->()) {
        # install meta property
        my $types = MT->registry("contact_form_field_types");
        MT->log("Installing \$meta{'formfield.".$field->basename."'} = ".$types->{ $field->type }->{'meta_type'});
        $meta{'formfield.'.$field->basename} = $types->{ $field->type }->{'meta_type'};
    }
    if (%meta) {
        $self->install_meta({ column_defs => \%meta });
    }
    $self->{'__meta_loaded'} = 1;
}

1;
