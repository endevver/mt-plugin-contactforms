use ExtUtils::MakeMaker;

use YAML::Any qw(LoadFile);
my $file = "plugins/ContactForms/config.yaml";
my $version = LoadFile($file)->{version} ||
    die "No version found in $file";

WriteMakefile(
    NAME            => 'Contact Forms',
    VERSION         => $version,
    DISTNAME        => 'ContactForms',
);
