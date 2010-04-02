# (C) 2009 Byrne Reese, iThemes LLC. All Rights Reserved.
# This code cannot be redistributed without permission from
# the copyright holders.

package ContactForms::FormField;

use strict;

use base qw( MT::Object );
use MT::Util qw( dirify );

__PACKAGE__->install_properties(
    {
        column_defs => {
            'id'         => 'integer not null auto_increment',
            'form_id'    => 'integer not null',
            'type'       => 'string(50) not null',
            'basename'   => 'string(50) not null',
            'label'      => 'string(50) not null',
            'hint'       => 'string(255)',
            'options'    => 'text',
            'removable'  => 'smallint not null',
            'order'      => 'smallint not null',
            'show_label' => 'smallint not null',
            'show_hint'  => 'smallint not null',
            'required'   => 'smallint not null',
        },
        indexes  => { form_id => 1, },
        defaults => {
            show_label => 1,
            show_hint  => 0,
            required   => 0,
            removable  => 1,
        },
        datasource  => 'cf_field',
        primary_key => 'id',
        class_type  => 'contact_form_field',
    }
);

sub key {
    my $field = shift;
    return dirify( $field->label );
}

sub option {
    my $field   = shift;
    my ($name)  = @_;
    my $options = $field->{__fieldopts};
    unless ($options) {
        require JSON;
        my $opts =
          $field->{column_values}->{options}
          ? JSON::jsonToObj( $field->column_values->{options} )
          : [];
        my $a = {};
        foreach (@$opts) {
            my @keys = keys(%$_);
            my $key  = $keys[0];
            my $val  = $_->{$key};
            $options->{$key} = $val;
        }
        $field->{__fieldopts} = $options;
    }
    return $options->{$name};
}

sub values {
    my $field = shift;
    return split( /,/, $field->option('values') );
}

1;
