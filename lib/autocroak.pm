package autocroak;

use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

sub import {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	$^H{autocroak} = 1;
	for my $op (keys %{ $args{allow} }) {
		my $key = "autocroak_\U$op";
		my @allows = ref $args{allow}{$op} ? @{ $args{allow}{$op} } : $args{allow}{$op};
		for my $value (@allows) {
			vec($^H{$key}, $value, 1) = 1;
		}
	}
}

sub unimport {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	delete $^H{autocroak};

	for my $op (keys %{ $args{disallow} }) {
		my $key = "autocroak_\U$op";
		my @disallows = ref $args{disallow}{$op} ? @{ $args{disallow}{$op} } : $args{disallow}{$op};
		for my $value (@disallows) {
			vec($^H{$key}, $value, 1) = 0;
		}
		delete $^H{$key} if $^H{$key} =~ / ^ \0* $ /x;
	}
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

Optionally you can pass it an allow hash listing errors that are allowed for certain op:

 use autocroak allow => { unlink => ENOENT };

Note: B<This is an early release, the exception messages as well as types will likely change in the future, do not depend on this yet>.

=head2 Supported keywords:

=over 4

=item * open

=item * sysopen

=item * close

=item * system

=item * print

=item * flock

=item * truncate

=item * exec

=item * fork

=item * fcntl

=item * binmode

=item * ioctl

=item * pipe

=item * kill

=item * bind

=item * connect

=item * listen

=item * setsockopt

=item * accept

=item * getsockopt

=item * shutdown

=item * sockpair

=item * read

=item * recv

=item * sysread

=item * syswrite

=item * stat

=item * chdir

=item * chown

=item * chroot

=item * unlink

=item * chmod

=item * utime

=item * rename

=item * link

=item * symlink

=item * readlink

=item * mkdir

=item * rmdir

=item * opendir

=item * closedir

=item * do

=item * dbmopen

=item * dbmclose

=item * gethostbyaddr

=item * getnetbyaddr

=item * msgctl

=item * msgget

=item * msgrcv

=item * msgsnd

=item * semctl

=item * semget

=item * semop

=item * shmctl

=item * shmget

=item * shmread

=back
