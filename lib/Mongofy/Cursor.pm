package Mongofy::Cursor;

use Moose;
use namespace::autoclean;
use Carp;

extends 'MongoDB::Cursor';

around 'next' => sub {
	my ($orig, $self) = (shift, shift);

	my $object = $self->$orig || return;

	# expand the object
	return $self->expand($object);
};

__PACKAGE__->meta->make_immutable;
