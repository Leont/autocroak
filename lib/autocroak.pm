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

# ABSTRACT: Replace functions with ones that succeed or die with lexical scope

=head1 SYNOPSIS

 use autocroak;
 
 open(my $fh, '<', $filename); # No need to check!
 print "Hello World"; # No need to check either

=head1 DESCRIPTION

The autocroak pragma provides a convenient way to replace functions that normally return false on failure with equivalents that throw an exception on failure.

The autocroak pragma has lexical scope, meaning that functions and subroutines altered with autodie will only change their behaviour until the end of the enclosing block, file, or eval.

Note: B<This is an early release, the exception messages as well as types will likely change in the future, do not depend on this yet>.
