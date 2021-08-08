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

subtest success => sub {
	use autocroak;

	my ($tfh, $tpath) = File::Temp::tempfile( CLEANUP => 1 );

	sysopen my $fh, $tpath, Fcntl::O_RDONLY;

	my @stat1 = stat $tfh;
	my @stat2 = stat $fh;

	is( "@stat1", "@stat2" );
};

subtest basic => sub {
	use autocroak;
	my $enoent = AutocroakTestUtils::get_errno_string('ENOENT');
	eval {
		sysopen my $fh, 'nonexistent', Fcntl::O_RDONLY;
	};
	my $err = $@;
	like( $err, qr<sysopen> );
	like( $err, qr<\Q$enoent\E> );
};

subtest allow => sub {
	use autocroak allow => { sysopen => ENOENT };
	my $ret = eval {
		sysopen my $fh, 'nonexistent', Fcntl::O_RDONLY;
	};
	is($@, '');
	is($!+0, ENOENT);
	is($ret, undef);
};

done_testing;
