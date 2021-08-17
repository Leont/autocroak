package TestUtils;

use strict;
use warnings;

use Errno;
use Carp;

sub get_errno_string {
    my $name = shift;

    my $cr = Errno->can($name) or croak "Bad errno name: $name";

    local $! = $cr->();
    return "$!";
}

1;
