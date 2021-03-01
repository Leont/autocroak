package autocroak;

use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

sub import {
	$^H |= 0x020000;
	$^H{autocroak} = 1;
}

sub unimport {
	$^H |= 0x020000;
	delete $^H{autocroak};
}

1;

# ABSTRACT: BLABLABLAB
