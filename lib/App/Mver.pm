package App::Mver;

use strict;
use version;
use warnings;

use ExtUtils::MakeMaker;

our $VERSION = '0.07';

my $module_corelist = eval 'require Module::CoreList; 1';
my $lwp_useragent   = eval 'require LWP::Simple; 1';
my $json_any        = eval 'use JSON::Any; 1';
my $can_do_requests = $lwp_useragent && $json_any;

sub run {
    my($modules, $opts) = @_;

    $can_do_requests = 0 if $opts->{'no-internet'};

    mver($_) for @$modules;
}

sub mver {
    my $arg = shift;
    $arg =~ s{-}{::}g;

    print "$arg: ";
    if(lc $arg eq 'perl') {
        require Config;
        print $Config::Config{version};
    }
    else {
        my $file = MM->_installed_file_for_module($arg);
        if(defined $file) {
            my $version = version->parse(MM->parse_version($file));
            if($version) {
                $version = version->parse($version);
                print $version;

                if($module_corelist and is_core($arg)) {
                    print ' (core module)';
                }
            }
            else {
                print 'installed, but $VERSION is not defined';
            }

            if($can_do_requests) {
                my $latest = get_latest_version($arg);
                if($latest and $latest <= $version) {
                    print ' (latest)';
                }
                else {
                    print " (latest: $latest)";
                }
            }
        }
        else {
            print 'not installed';
        }
    }
    print $/;
}

sub is_core {
    my $arg = shift;

    my($found_in_core) = Module::CoreList->find_modules(qr/^\Q$arg\E$/, $]);

    !!$found_in_core;
}

sub get_latest_version {
    my $arg = shift;

    my $json     = LWP::Simple::get("http://api.metacpan.org/module/$arg") or return;
    my $response = eval { JSON::Any->from_json($json) } or return;

    if($response->{status} eq 'latest') {
        return version->parse($response->{version});
    }

    return;
}

1;

__END__

=head1 NAME

App::Mver - just print modules' C<$VERSION> (and some other stuff)

=head1 DESCRIPTION

For those, who are sick of

    perl -MLong::Module::Name -le'print Long::Module::Name->VERSION'

The main purpose of this simple stupid tool is to save you some typing.

It will report you the following things (some of them require command line arguments):

=over 4

=item your installed version of the given module(s)

=item whether or not your current version is the last one available on CPAN

=item whether or not the module is included in Perl distribution

=back

=head1 SEE ALSO

L<mver>

=head1 AUTHOR

Alexey Surikov E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
