package Mongofy::Collection;

use Moose;
use namespace::autoclean;
use Tie::IxHash;
use Carp;

has 'name' => (is => 'ro', isa => 'Str', required => 1);

has 'db' => (is => 'ro', isa => 'MongoDB::Database', required => 1);

has 'coll' => (is => 'ro', isa => 'MongoDB::Collection', lazy_build => 1);

=head1 METHODS

=head2 find( \%query, [ \%attrs ] )

=head2 query( \%query, [ \%attrs ] )

=head2 search( \%query, [ \%attrs ] )

=cut

sub find {
	my ($self, $query, $attrs) = @_;

	croak "You must provide a query hash-ref to search according to."
		unless $query;

	croak "Query must be a hash-ref."
		unless ref $query eq 'HASH';

	carp "Ignoring non-hashref query attributes."
		if $attrs && ref $attrs ne 'HASH';

	return Mongofy::Cursor->new(cursor => $self->coll->find($query, $attrs));
}

sub query {
	shift->find(@_);
}

sub search {
	shift->find(@_);
}

=head2 find_one( \%query | $id, [ \%attrs ] ] )

=cut

sub find_one {
	my ($self, $query, $attrs) = @_;

	croak "You must provide a query hash-ref or ID to search according to."
		unless $query;

	if (ref $query eq 'SCALAR') {
		$query->{_id} = MongoDB::OID->new(value => $query);
	} elsif (ref $query eq 'MongoDB::OID') {
		$query->{_id} = $query;
	}

	my $fields = $attrs && ref $attr eq 'HASH' ? delete $attrs->{fields} : {};

	return $self->find($query, $attrs)->limit(-1)->fields($fields)->next;
}

=head2 insert( \%object, \%options )

=cut

sub insert {
	my ($self, $object, $options) = @_;

	my ($id) = $self->batch_insert([$object], $options);

	return $self->find_one($id) if $id;

	return;
}


=head2 batch_insert( \@objects, \%options )

=cut

sub batch_insert {
	my ($self, $objects, $options) = @_;

	return map { $self->find_one($_) } $self->coll->batch_insert($objects, $options);
}

=head2 update( \%criteria, \%objects, [ \%options ] )

=cut

sub update {
	shift->coll->update(@_);
}

=head2 remove( [ \%query, [ \%options ] ] )

=cut

sub remove {
	shift->coll->remove(@_);
}

=head2 ensure_index( \%keys | \@keys, [ \%options ] )

=cut

sub ensure_index {
	my ($self, $keys, $options) = @_;

	if ($keys && ref $keys eq 'ARRAY') {
		$keys = Tie::IxHash->new(@$keys);
	}

	return $self->coll->ensure_index($keys, $options);
}

=head2 count( [ \%query ] )

=cut

sub count {
	shift->coll->count(@_);
}

=head2 get_indexes()

=cut

sub get_indexes {
	shift->coll->get_indexes(@_);
}

=head2 drop_indexes()

=cut

sub drop_indexes {
	shift->coll->drop_indexes(@_);
}

=head2 drop_index( $index_name )

=cut

sub drop_index {
	shift->coll->drop_index(@_);
}

=head2 drop()

=cut

sub drop {
	shift->coll->drop(@_);
}

=head1 INTERNAL METHODS

=head2 _build_coll

=cut

sub _build_coll {
	my $self = shift;

	return $self->db->get_collection($self->name);
}

__PACKAGE__->meta->make_immutable;
