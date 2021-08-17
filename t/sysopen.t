#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
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
	my $err = exception {
		sysopen my $fh, 'nonexistent', Fcntl::O_RDONLY;
	};
	like( $err, qr<sysopen> );
	like( $err, qr<\Q$enoent\E> );
};

subtest allow => sub {
	use autocroak allow => { sysopen => ENOENT };
	my $ex = exception {
		my $ret = sysopen my $fh, 'nonexistent', Fcntl::O_RDONLY;
		is($ret, undef);
	};
	is($ex, undef);
	is($!+0, ENOENT);
};

done_testing;
