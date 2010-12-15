package Mongofy::Database;

use Moose;
use namespace::autoclean;
use Mongofy::Collection;

extends 'MongoDB::Database';

override 'get_collection' => sub {
	Mongofy::Collection->new(_database => shift, name => shift);
};

__PACKAGE__->meta->make_immutable;
