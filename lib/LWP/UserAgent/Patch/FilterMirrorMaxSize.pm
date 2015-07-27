package LWP::UserAgent::Patch::FilterMirrorMaxSize;

use 5.010001;
use strict;
no warnings;

use HTTP::Response;
use Module::Patch 0.12 qw();
use base qw(Module::Patch);

# DATE
# VERSION

our %config;

my $p_mirror = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my ($self, $url, $file) = @_;
    my $limit = $config{-size};
    die __PACKAGE__ . ": please specify max size" unless defined $limit;

    my $size = (-s $file);
    if ($size && $size > $limit) {
        say "mirror($url, $file): local size ($size) > limit ($limit), skipping"
            if $config{-verbose};
        return HTTP::Response->new(304);
    }

    # perform HEAD request to find out the size
    my $resp = $self->head($url);

    {
        last unless $resp->is_success;
        last unless defined(my $len = $resp->header("Content-Length"));
        if ($len > $limit) {
            say "mirror($url, $file): remote size ($len) > limit ($limit), skipping"
                if $config{-verbose};
            return HTTP::Response->new(304);
        }
    }

    return $orig->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -size => {
                schema => 'int*',
            },
            -verbose => {
                schema  => 'bool*',
                default => 0,
            },
        },
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\.[01].+/,
                sub_name => 'mirror',
                code => $p_mirror,
            },
        ],
    };
}

1;
# ABSTRACT: Dont' mirror() files larger than a certain size

=head1 SYNOPSIS

 use LWP::UserAgent::Patch::FilterMirrorMaxSize -size => 10*1024*1024;
 # use LWP::UserAgent's mirror() as usual

To use with CPAN::Mini command-line script:

 % PERL5OPT="-MLWP::UserAgent::Patch::FilterMirrorMaxSize=-size,10485760,-verbose,1" minicpan -l /cpan -r http://mirrors.kernel.org/cpan/


=head1 DESCRIPTION

If size is larger than the limit, the patch's wrapper method will return a dummy
304 (not modified) response object. This trick should work on at least some
applications (like with L<CPAN::Mini>, which I originally wrote this patch
module for), but it might not :-)


=head1 SEE ALSO

L<http://blogs.perl.org/users/steven_haryanto/2014/06/skipping-large-files-when-mirroring-your-mini-cpan.html>

=cut
