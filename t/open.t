#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal 'exception';
use Errno 'ENOENT';

subtest basic => sub {
	use autocroak;
	my $ex = exception {
		open my $fh, '<', 'nonexistent';
	};
	like $ex, qr/Could not open file 'nonexistent' with mode '<': No such/;
};

subtest allow => sub {
	use autocroak allow => { open => ENOENT };
	my $ex = exception {
		is(open(my $fh, '<', 'nonexistent'), undef);
	};
	is($ex, undef);
	is($!+0, ENOENT);
};

done_testing;
