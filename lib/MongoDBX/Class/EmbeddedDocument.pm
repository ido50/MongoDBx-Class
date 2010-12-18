package MongoDBX::Class::EmbeddedDocument;

use Moose::Role;
use namespace::autoclean;

has '_collection' => (is => 'ro', isa => 'MongoDBX::Class::Collection', required => 1);

1;
