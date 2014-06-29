package LWP::UserAgent::Patch::FilterMirror;

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

# DATE
# VERSION

our %config;

my $p_mirror = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my ($self, $url, $file) = @_;
    die __PACKAGE__ . ": please specify filter code" unless $config{filter};
    return unless $config{filter}->($url, $file);
    return $orig->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            filter => {
                schema => 'code*',
            },
        },
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\.0.+/,
                sub_name => 'mirror',
                code => $p_mirror,
            },
        ],
    };
}

1;
# ABSTRACT: Add filtering for mirror()

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::FilterMirror -filter => sub { ... };
 # use LWP::UserAgent's mirror() as usual
 # ...

=cut
