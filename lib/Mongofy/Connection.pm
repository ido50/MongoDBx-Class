package Mongofy::Connection;

use Moose;
use namespace::autoclean;
use Mongofy::Database;

extends 'MongoDB::Connection';

override 'get_database' => sub {
	Mongofy::Database->new(_connection => shift, name => shift);
};

__PACKAGE__->meta->make_immutable;
