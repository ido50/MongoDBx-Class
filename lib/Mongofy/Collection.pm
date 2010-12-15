package Mongofy::Collection;

use Moose;
use namespace::autoclean;
use Carp;

extends 'MongoDB::Collection';

=head1 OBJECT METHODS

=head2 find( \%query, [ \%attrs ] )

=head2 query( \%query, [ \%attrs ] )

=head2 search( \%query, [ \%attrs ] )

=cut

override 'find' => sub {
	my ($self, $query, $attrs) = @_;

	# old school options - these should be set with MongoDB::Cursor methods
	my ($limit, $skip, $sort_by) = @{ $attrs || {} }{qw/limit skip sort_by/};

	$limit ||= 0;
	$skip||= 0;

	my $q = {};
	if ($sort_by) {
		$q->{'query'} = $query;
		$q->{'orderby'} = $sort_by;
	} else {
		$q = $query ? $query : {};
	}

	my $cursor = Mongofy::Cursor->new(
		_connection => $self->_database->_connection,
		_ns => $self->full_name, 
		_query => $q, 
		_limit => $limit, 
		_skip => $skip
	);

	$cursor->_init;

	return $cursor;
};

sub search {
	shift->find(@_);
}

around 'find_one' => sub {
	my ($orig, $self, $query, $fields) = @_;

	$query ||= {};

	if (ref $query eq 'SCALAR') {
		$query->{_id} = MongoDB::OID->new(value => $query);
	} elsif (ref $query eq 'MongoDB::OID') {
		$query->{_id} = $query;
	}

	return $self->$orig($query, $fields);
};

around 'insert' => sub {
	my ($orig, $self) = (shift, shift);

	my $id = $self->$orig(@_);

	return $self->find_one($id) if $id;
	return;
};

around 'batch_insert' => sub {
	my ($orig, $self) = (shift, shift);

	return map { $self->find_one($_) } $self->$orig(@_);
};

around 'ensure_index' => sub {
	my ($orig, $self, $keys, $options) = @_;

	if ($keys && ref $keys eq 'ARRAY') {
		$keys = Tie::IxHash->new(@$keys);
	}

	return $self->$orig($keys, $options);
};

__PACKAGE__->meta->make_immutable;
