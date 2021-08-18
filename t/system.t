#! perl

use strict;
use warnings;

use Test::More;

use File::Temp;
use Config;

use FindBin;
use lib "$FindBin::Bin/lib";

use AutocroakTestUtils;

subtest nonzero_exit => sub {
    use autocroak;

    eval { system $^X, -e => 'exit 22'; };
    my $err = $@;
    like( $err, qr<22>, 'nonzero exit code shows' );
};

subtest signal => sub {
    skip "$^O doesn’t seem to play nicely with signal-based tests.", 1 if !_is_safe_to_test_with_signals();
    use autocroak;

    eval { system $^X, -e => 'kill "QUIT", $$'; };
    my $err = $@;
    like( $err, qr<QUIT>i, 'signal is in error' );
};

subtest failure_to_start => sub {
    use autocroak;

    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    my $enoent = AutocroakTestUtils::get_errno_string('ENOENT');

    eval {
        local $SIG{'__WARN__'} = sub {};
        system "$dir/hahaha";
    };
    my $err = $@;
    like( $err, qr<\Q$enoent\E>, 'ENOENT string is in error when path doesn’t exist' );
};

subtest success => sub {
    use autocroak;

    my $got = system $^X, -e => 'exit 0';

    is( $got, 0, 'zero return' );
};

done_testing;

#----------------------------------------------------------------------

sub _is_safe_to_test_with_signals {
    return $Config{'d_fork'};
}
