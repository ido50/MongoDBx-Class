package MongoDBX::Class::Reference;

use Moose;
use namespace::autoclean;

with 'MongoDBX::Class::EmbeddedDocument';

has 'ref_coll' => (is => 'rw', isa => 'Str', required => 1);

has 'ref_id' => (is => 'rw', isa => 'MongoDB::OID', required => 1);

sub load {
	my $self = shift;

	return $self->_collection->_database->get_collection($self->ref_coll)->find_one($self->ref_id);
}

__PACKAGE__->meta->make_immutable;
