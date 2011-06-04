package App::Mver;

use strict;
use warnings;

use Pod::Usage;
use Pod::Find qw(pod_where);

our $VERSION = '0.04';

sub run {
    @_ or usage();
    usage(2) if $_[0] eq '-h' or $_[0] eq '--help';

    mver($_) for @_;
}

sub mver {
    my $arg = shift;
    $arg =~ s{-}{::}g;

    my $is_loaded = eval "use $arg;1";
    print "$arg: ";
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
        }
        else {
            print 'installed, but $VERSION is not defined';
        }
    }
    print $/;
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
__END__

=head1 NAME

App::Mver - just print modules' $VERSION

=head1 DESCRIPTION

For those, who are sick of

    perl -MLong::Module::Name -le'print Long::Module::Name->VERSION'

=head1 SYNOPSIS

    mver Module::Name

    mver Module-Name

=head1 AUTHOR

Alexey Surikov E<lt>ksuri@cpan.orgE<gt>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
