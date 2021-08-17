#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Errno 'ENOENT';

use FindBin;
use File::Temp;
use lib "$FindBin::Bin/lib";
use TestUtils;

subtest enotdir => sub {
	use autocroak allow => { -e => ENOENT };

	my ($tfh, $tpath) = File::Temp::tempfile( CLEANUP => 1 );

	my $enotdir  = TestUtils::get_errno_string('ENOTDIR');

	my $err = exception { -e "$tpath/notthere" };

	like( $err, qr<-e> );
	like( $err, qr<\Q$enotdir\E> );
};

subtest no_error => sub {
	use autocroak allow => { -e => ENOENT };

	my $tdir = File::Temp::tempdir( CLEANUP => 1 );

	is(exception { ok( (-e $tdir), 'exists == success' ) }, undef);

	is(exception { ok( !(-e "$tdir/notthere"), 'nonexistence isn’t an error' ) }, undef);
};

done_testing;
