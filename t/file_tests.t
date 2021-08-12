#! perl

use strict;
use warnings;

use Test::More;
use Errno 'ENOENT';

use FindBin;
use File::Temp;
use lib "$FindBin::Bin/lib";
use AutocroakTestUtils;

use Fcntl;

subtest enotdir => sub {
    use autocroak allow => { -e => ENOENT };

    my ($tfh, $tpath) = File::Temp::tempfile( CLEANUP => 1 );

    my $enotdir  = AutocroakTestUtils::get_errno_string('ENOTDIR');

    eval { -e "$tpath/notthere" };
    my $err = $@;

    like( $err, qr<-e> );
    like( $err, qr<\Q$enotdir\E> );
};

subtest no_error => sub {
    use autocroak allow => { -e => ENOENT };

    my $tdir = File::Temp::tempdir( CLEANUP => 1 );

    ok( (-e $tdir), 'exists == success' );

    ok( !(-e "$tdir/notthere"), 'nonexistence isn’t an error' );
};

done_testing;
