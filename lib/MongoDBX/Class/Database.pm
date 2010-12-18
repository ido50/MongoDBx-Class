package MongoDBX::Class::Database;

use Moose;
use namespace::autoclean;

extends 'MongoDB::Database';

override 'get_collection' => sub {
	MongoDBX::Class::Collection->new(_database => shift, name => shift);
};

__PACKAGE__->meta->make_immutable;
