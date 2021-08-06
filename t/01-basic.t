#! perl

use strict;
use warnings;

use Test::More;
use Errno 'ENOENT';

subtest basic => sub {
	use autocroak;
	eval {
		open my $fh, '<', 'nonexistent';
	};
	like $@, qr/Could not open file 'nonexistent' with mode <: No such/;
};

subtest allow => sub {
	use autocroak allow => { open => ENOENT };
	my $ret = eval {
		open my $fh, '<', 'nonexistent';
	};
	is($@, '');
	is($!+0, ENOENT);
	is($ret, undef);
};

done_testing;
