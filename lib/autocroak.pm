package autocroak;

use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

my %key_for = (
	pipe          => 'PIPE_OP',
	getsockopt    => 'GSOCKOPT',
	setsockopt    => 'SSOCKOPT',
	opendir       => 'OPEN_DIR',
	do            => 'DOFILE',
	gethostbyaddr => 'GHBYADDR',
	getnetbyaddr  => 'GNBYADDR',

	-R => 'FTRREAD',
	-W => 'FTRWRITE',
	-X => 'FTREXEC',
	-r => 'FTEREAD',
	-w => 'FTEWRITE',
	-x => 'FTEEXEC',

	-e => "FTIS",
	-s => "FTSIZE",
	-M => "FTMTIME",
	-C => "FTCTIME",
	-A => "FTATIME",

	-O => "FTROWNED",
	-o => "FTEOWNED",
	-z => "FTZERO",
	-S => "FTSOCK",
	-c => "FTCHR",
	-b => "FTBLK",
	-f => "FTFILE",
	-d => "FTDIR",
	-p => "FTPIPE",
	-u => "FTSUID",
	-g => "FTSGID",
	-k => "FTSVTX",

	-l => "FTLINK",
	-t => "FTTTY",
	-T => "FTTEXT",
	-B => "FTBINARY",
);

sub import {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	$^H{"autocroak/enabled"} = 1;

	for my $op_name (keys %{ $args{allow} }) {
		my $op_key = $key_for{$op_name} // uc $op_name;
		my $key = "autocroak/$op_key";
		$^H{$key} //= '';
		my $values = $args{allow}{$op_name};
		for my $value (ref $values ? @{ $values } : $values) {
			vec($^H{$key}, $value, 1) = 1;
		}
	}
}

sub unimport {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	delete $^H{$_} for grep m{^autocroak/}, keys %^H;
}

1;

# ABSTRACT: Replace functions with ones that succeed or die with lexical scope

=head1 SYNOPSIS

 use autocroak;

 open(my $fh, '<', $filename); # No need to check!
 print "Hello World"; # No need to check either

=head1 DESCRIPTION

The autocroak pragma provides a convenient way to replace functions that normally return false on failure with equivalents that throw an exception on failure.

The autocroak pragma has lexical scope, meaning that functions and subroutines altered with autocroak will only change their behaviour until the end of the enclosing block, file, or eval.

Optionally you can pass it an allow hash listing errors that are allowed for certain op:

 use autocroak allow => { unlink => ENOENT };

Note: B<This is an early release, the exception messages as well as types may change in the future, do not depend on this yet>.

=head2 Supported keywords:

=over 4

=item * accept

=item * bind

=item * binmode

=item * chdir

=item * chmod

=item * chown

=item * chroot

=item * close

=item * closedir

=item * connect

=item * dbmclose

=item * dbmopen

=item * exec

=item * fcntl

=item * flock

=item * fork

=item * gethostbyaddr

=item * getnetbyaddr

=item * getsockopt

=item * ioctl

=item * kill

=item * link

=item * listen

=item * mkdir

=item * msgctl

=item * msgget

=item * msgrcv

=item * msgsnd

=item * open

=item * opendir

=item * pipe

=item * print

=item * read

=item * readlink

=item * recv

=item * rename

=item * rmdir

=item * select

=item * semctl

=item * semget

=item * semop

=item * setsockopt

=item * shmctl

=item * shmget

=item * shmread

=item * shutdown

=item * sockpair

=item * stat

=item * symlink

=item * sysopen

=item * sysread

=item * system

=item * syswrite

=item * truncate

=item * unlink

=item * utime

=item * C<-A>

=item * C<-B>

=item * C<-b>

=item * C<-C>

=item * C<-c>

=item * C<-d>

=item * C<-e>

=item * C<-f>

=item * C<-g>

=item * C<-k>

=item * C<-l>

=item * C<-M>

=item * C<-O>

=item * C<-o>

=item * C<-p>

=item * C<-R>

=item * C<-r>

=item * C<-S>

=item * C<-s>

=item * C<-T>

=item * C<-t>

=item * C<-u>

=item * C<-W>

=item * C<-w>

=item * C<-X>

=item * C<-x>

=item * C<-z>

=back
