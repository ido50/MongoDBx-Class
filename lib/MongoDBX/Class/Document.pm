package MongoDBX::Class::Document;

use Moose::Role;
use namespace::autoclean;

has '_id' => (is => 'ro', isa => 'MongoDB::OID', required => 1);

has '_collection' => (is => 'ro', isa => 'MongoDBX::Class::Collection', required => 1);

sub id {
	shift->_id->to_string;
}

sub oid {
	shift->id;
}

1;
