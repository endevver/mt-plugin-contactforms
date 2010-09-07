package ContactForms::ContextHandlers;

use strict;

sub mod_md5 {
    my ($str, $val, $ctx) = @_;
    require Digest::MD5;
    return Digest::MD5::md5_hex($str);
}

sub tag_contact_form_script {
    my ($ctx) = @_;
    my $cfg = $ctx->{config};
    return $cfg->ContactFormScript;
}

sub tag_blog_id_hack {
    my $blog = MT->instance->blog;
    return $blog->id if $blog;
}

sub tag_template_exists {
    my ( $ctx, $args, $cond ) = @_;
    my $id    = $args->{id};
    my $scope = $args->{scope} || 'any';
    my $terms = { type => $id, };
    my $blog  = MT->instance->blog;
    if ( $scope eq 'blog' && $blog ) {
        $terms->{blog_id} = $blog->id;
    }
    elsif ( $scope eq 'system' ) {
        $terms->{blog_id} = 0;
    }
    my $tmpl = MT->model('template')->load($terms);
    return $tmpl ? 1 : 0;
}

###########################################################################

=head2 mt:ContactForm

This template tag is a block, or container tag that establishes a 
context containing a contact form corresponding to the given ID. This tag
is required in order to use virtually every other Contact Form plugin
template tag.

B<Attributes:>

=over 4

=item * id (required)

The ID of the contact form being loaded.

=back

=for tags plugin, block, container, contact form

=cut

sub tag_contact_form {
    my ( $ctx, $args, $cond ) = @_;
    my $id = $args->{id};
    my $title = $args->{title};
    
    my $form = MT->model('contact_form')->load($id);
    $form = MT->model('contact_form')->load( { title => $title, blog_id => $ctx->stash('blog')->id }) if !$form;
    return $ctx->error('No contact form could be located') unless $form;
    local $ctx->{__stash}->{'contactform'} = $form;
    defined( my $out .= $ctx->slurp( $args, $cond ) ) or return;
    return $out;
}

###########################################################################

=head2 mt:ContactFormFields

This template tag must be invoked within the context of a contact form. 
This tag is used to then look over each of the fields associated with the 
current contact form in context, in the order chosen by the user who created
or last edited the form. 

This template tag takes no arguments.

B<Attributes:>

None.

=for tags plugin, block, container, contact form, loop

=cut

sub tag_form_fields {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    my @fields = $form->fields;
    my $out    = '';
    foreach my $f (@fields) {
        local $ctx->{__stash}->{'formfield'} = $f;
        defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
    }
    return $out;
}

###########################################################################

=head2 mt:ContactFormFieldValueLoop

This template tag is a container tag that loops over the current form 
field list of allowable values. This is used for example in conjunction
with a pull-down menu or radio button to iterate over each menu option or
radio button respectively.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form

=cut

sub tag_value_loop {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    my @values = $field->values;
    my $out    = '';
    foreach my $v (@values) {
        local $ctx->{__stash}->{'formfieldvalue'} = $v;
        defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
    }
    return $out;
}

###########################################################################

=head2 mt:ContactFormFieldValue

This template tag is a container tag that outputs the current value in
context set by invoking the C<ContactFormFieldValueLoop> tag.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form

=cut

sub tag_field_value {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $ctx->stash('formfieldvalue');
}

###########################################################################

=head2 mt:ContactFormFieldLabel

This template tag outputs the label of the form field currently in
context. This tag must be invoked within the context of a C<ContactFormFields>
loop.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form

=cut

sub tag_field_label {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->label;
}

###########################################################################

=head2 mt:ContactFormFieldHint

This template tag outputs the hint text of the form field currently in
context. This tag must be invoked within the context of a C<ContactFormFields>
loop.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form

=cut

sub tag_field_hint {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->hint;
}

###########################################################################

=head2 mt:IfContactFormOpen

This template tag is a container tag whose contents will only be evaluated
and output if the current contact form in context has a status of "open."
As it is a conditional tag, this tag can also be used in conjunction with
the C<mt:else> tag.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form, conditional

=cut

sub tag_is_open {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    return $form->status == ContactForms::Form->OPEN();
}

###########################################################################

=head2 mt:IfContactFormFieldRequired

This template tag is a container tag whose contents will only be evaluated
and output if the current contact form field in context is a required 
field. As it is a conditional tag, this tag can also be used in conjunction 
with the C<mt:else> tag.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form, conditional

=cut

sub tag_is_required {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->required ? 1 : 0;
}

###########################################################################

=head2 mt:ShowContactFormFieldLabel

This template tag is a container tag whose contents will only be evaluated
and output if the current contact form field in context has a preference to 
display the label of the field. As it is a conditional tag, this tag can 
also be used in conjunction with the C<mt:else> tag.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form, conditional

=cut

sub tag_show_label {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->show_label ? 1 : 0;
}

###########################################################################

=head2 mt:ShowContactFormFieldHint

This template tag is a container tag whose contents will only be evaluated
and output if the current contact form field in context has a preference to 
display the hint text of the field. As it is a conditional tag, this tag 
can also be used in conjunction with the C<mt:else> tag.

B<Attributes:>

None.

=back

=for tags plugin, block, container, contact form, conditional

=cut

sub tag_show_hint {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->show_hint ? 1 : 0;
}

###########################################################################

=head2 mt:ContactFormFieldType

This template tag is a function tag that outputs the field type of the form
field currently in context. 

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_field_type {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->type;
}

###########################################################################

=head2 mt:ContactFormFieldBasename

The immutable basename for a contract form field.

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_field_basename {
    my ( $ctx, $args, $cond ) = @_;
    my $field = $ctx->stash('formfield');
    return _no_field_context($ctx) unless ($field);
    return $field->basename;
}

###########################################################################

=head2 mt:ContactFormID

This template tag is a function tag that outputs the ID of the current 
contact form in context.

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_form_id {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    return $form->id;
}

###########################################################################

=head2 mt:ContactFormResponseText

This template tag is a function tag that outputs the text of the message
that will be displayed to the user immediately following a contact form
submission. This tag is used almost exclusively by the system template with
a name of "Contact From Response."

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_responsetext {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    return $form->confirmation_text;
}

###########################################################################

=head2 mt:ContactFormAutoReplyText

This template tag is a function tag that outputs the text/message that will
be sent to the user automaticcaly via email after a contact form submission.

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_autoreplytext {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    return $form->autoreply_text;
}

###########################################################################

=head2 mt:ContactFormName

This template tag is a function tag that outputs the name/title of the 
current contact form in context.

B<Attributes:>

None.

=back

=for tags plugin, function, contact form

=cut

sub tag_form_name {
    my ( $ctx, $args, $cond ) = @_;
    my $form = $ctx->stash('contactform');
    return _no_form_context($ctx) unless ($form);
    return $form->title;
}

###########################################################################

=head2 mt:ContactFormHTML

This template tag is a function tag that outputs the HTML of the contact 
form designated by the user. The HTML returned by this tag is determined
by processing the System or Local (preferred) system template with the
name of "Contact Form." If you wish to customize the output of this tag,
one should look for and edit one of those templates.

B<Attributes:>

=over 4

=item * id (optional)

The ID of the contact form whose HTML you want to generate. If omitted, then
the tag will default to using the first contact form created for the
current blog.

=back

=for tags plugin, function, contact form

=cut

sub tag_contact_form_html {
    my ( $ctx, $args, $cond ) = @_;
    my $id   = $args->{id};
    my $blog = $ctx->stash('blog');
    my $form;
    if ($id) {
        $form = MT->model('contact_form')->load($id)
          or return $ctx->error(
            MT->translate(
                "Could not load Contact Form with id of [_1].", $id
            )
          );
    }
    else {
        $form = MT->model('contact_form')->load( { blog_id => $blog->id },
            { sort => 'created_on', direction => 'descend', limit => 1, } );
        $id = $form->id;
    }
    return '' unless ($form);

    # TODO - blog context required!
    my $tmpl;
    $tmpl =
      MT->model('template')->load( { type => 'contact_form', blog_id => $blog->id } )
      or $tmpl = MT->model('template')->load( { type => 'contact_form', blog_id => 0 } );
    unless ($tmpl) {
        return $ctx->error(
            MT->translate(
                "Could not load MT::Template for blog [_1].", $blog->id
            )
        );
    }
    $tmpl->param( {} );
    $tmpl->context->stash( 'contactform', $form );
    $tmpl->context->stash( 'blog',        $blog );
    my $html = $tmpl->output();
    $html = $tmpl->errstr unless defined $html;
    return $html;
}

1;
