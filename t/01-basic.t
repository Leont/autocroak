#! perl

use strict;
use warnings;

use Test::More;

subtest basic => sub {
	use autocroak;
	eval {
		open my $fh, '<', 'nonexistent';
	};
	like($@, qr/No such/);
};

done_testing;
