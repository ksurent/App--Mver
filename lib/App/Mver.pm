package App::Mver;

use strict;
use warnings;

use Pod::Usage;
use Pod::Find qw(pod_where);
use Getopt::Long qw(GetOptionsFromArray);

our $VERSION = '0.06';

my $module_corelist = eval 'use Module::CoreList; 1';
my $lwp_useragent   = eval 'use LWP::Simple; 1';
my $json_any        = eval 'use JSON::Any; 1';
my $can_do_requests = $lwp_useragent && $json_any;

sub run {
    GetOptionsFromArray(
        \@_,
        \my %opts,
        'help|h',
        'no-internet|n',
    );
    my @modules = grep { not /^-/ } @_;

    @modules or usage();
    usage(2) if $opts{help};

    $can_do_requests = 0 if $opts{'no-internet'};

    mver($_) for @modules;
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
        my $is_loaded = eval "use $arg; 1";
        unless(defined $is_loaded) {
            if($@ =~ /^Can't locate/) {
                print 'not installed';
            }
            else {
                print 'installed, but contains error';
            }
        }
        else {
            my $version = $arg->VERSION;
            if(defined $version) {
                print $version;

                my $authority = eval "\$$arg\::AUTHORITY";
                if(defined $authority) {
                    print " ($authority)";
                }

                if($module_corelist and is_core($arg)) {
                    print ' (core module)';
                }
            }
            else {
                print 'installed, but $VERSION is not defined';
            }

            if($can_do_requests) {
                my $latest = get_latest_version($arg);
                if(defined $latest) {
                    if($latest eq $version) {
                        print ' (latest)';
                    }
                    else {
                        print " (latest: $latest)";
                    }
                }
            }
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
        return $response->{version};
    }

    return;
}

sub usage {
    pod2usage(
        -verbose => $_[0],
        -input   => pod_where(
            { -inc => 1 },
            __PACKAGE__,
        ),
    );
}

1;

__END__

=head1 NAME

App::Mver - just print modules' C<$VERSION> (and some other stuff)

=head1 DESCRIPTION

For those, who are sick of

    perl -MLong::Module::Name -le'print Long::Module::Name->VERSION'

=head1 SYNOPSIS

    mver Module::Name1 Module-Name2 Module::NameN

    mver perl # shortcut for perl -V:version

=head1 OPTIONS

=over 4

=item --no-internet (-n)

Disable MetaCPAN API querying.

=item --help (-h)

Show this message.

=back

=head1 AUTHOR

Alexey Surikov E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
