package Gentoo::Portage::Overlay;

use strict;
use warnings;
use Cwd qw/abs_path/;

sub new {
	my ($class, $opts) = @_;
	
	my $self = bless { %{ $opts || {} } }, $class;
	return $self;
}

sub path {
	my ($self) = @_;
	
	return abs_path($self->{path});
}

sub has_ebuild {
	my ($self, $ebuild) = @_;
	
	return -d sprintf("%s/%s", $self->path, $ebuild);
}

1;
