package ContactForms::FieldTypes;

use strict;
use MT::Util qw(dirify);

sub field_yes_no {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my $html  = <<EOH;
    <div id="field-$fid">
      <label for="$fid">$label</label>
      <label><input type="radio" id="${fid}_yes" name="$fid" value="yes" /> Yes</label>
      <label><input type="radio" id="${fid}_no" name="$fid" value="no" /> No</label>
    </div>
EOH
    return $html;
}

sub field_text {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my $html  = <<EOH;
    <div id="field-$fid">
      <label for="$fid">$label</label>
      <input id="$fid" name="$fid" size="30" value="" />
    </div>
EOH
    return $html;
}

sub field_textarea {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my $rows  = $options->{rows} || 15;
    my $cols  = $options->{cols} || 50;
    my $html  = <<EOH;
    <div id="field-$fid">
      <label for="$fid">$label</label>
      <textarea id="$fid" name="$fid" rows="$rows" cols="$cols"></textarea>
    </div>
EOH
    return $html;
}

sub field_select {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my @opts  = split( /,/, $options->{values} );
    my $html  = <<EOH;
    <div id="field-$fid">
      <label for="$fid">$label</label>
      <select id="$fid" name="$fid">
EOH
    foreach (@opts) {
        $html .= "        <option>$_</option>\n";
    }
    $html .= <<EOH;
      </select>
    </div>
EOH
    return $html;
}

sub field_radio {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my @opts  = split( /,/, $options->{values} );
    my $html  = <<EOH;
    <div id="field-$fid">
      <label>$label</label>
EOH
    foreach (@opts) {
        my $d = dirify($_);
        $html .=
"<label><input type=\"radio\" name=\"$d\" value=\"$d\" /> $_</label>\n";
    }
    $html .= <<EOH;
      </select>
    </div>
EOH
    return $html;
}

sub field_checkbox {
    my ( $field, $options ) = @_;
    my $fid   = $field->basename;
    my $label = $field->label;
    my $html  = <<EOH;
    <div id="field-$fid">
      <input type="checkbox" id="$fid" name="$fid" value="1" />
      <label for="$fid">$label</label>
    </div>
EOH
    return $html;
}

1;
