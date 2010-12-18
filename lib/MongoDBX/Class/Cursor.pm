package MongoDBX::Class::Cursor;

use Moose;
use namespace::autoclean;

extends 'MongoDB::Cursor';

around 'next' => sub {
	my ($orig, $self) = (shift, shift);

	my $doc = $self->$orig || return;

	return $self->_connection->expand($self->_ns, $doc);
};

__PACKAGE__->meta->make_immutable;
