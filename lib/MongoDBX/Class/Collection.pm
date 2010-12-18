package MongoDBX::Class::Collection;

use Moose;
use namespace::autoclean;

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

	my $cursor = MongoDBX::Class::Cursor->new(
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
	my ($orig, $self, $orig_query, $fields) = @_;

	my $query = {};

	if ($orig_query && ref $orig_query eq 'SCALAR') {
		$query->{_id} = MongoDB::OID->new(value => $orig_query);
	} elsif ($orig_query && ref $orig_query eq 'MongoDB::OID') {
		$query->{_id} = $orig_query;
	}

	return $self->$orig($query, $fields);
};

around 'batch_insert' => sub {
	my ($orig, $self, $docs, $opts) = @_;

	foreach (@$docs) {
		foreach my $attr (keys %$_) {
			if (ref $_->{$attr} && $_->{$attr}->does('MongoDBX::Class::Document')) {
				$_->{$attr} = { '$ref' => $_->{$attr}->_collection->name, '$id' => $_->{$attr}->_id };
			} elsif (ref $_->{$attr} && $_->{$attr}->does('MongoDBX::Class::EmbeddedDocument')) {
				my $hash = {};
				foreach my $ha (keys %{$_->{attr}}) {
					next if $ha =~ m!^_!;
					$hash->{$ha} = $_->{attr}->{$ha};
				}
				$_->{$attr} = $hash;
			}
		}
	}

	if ($opts && ref $opts eq 'HASH' && $opts->{safe}) {
		return map { $self->find_one($_) } $self->$orig($docs, $opts);
	} else {
		return $self->$orig($docs, $opts);
	}
};

around 'ensure_index' => sub {
	my ($orig, $self, $keys, $options) = @_;

	if ($keys && ref $keys eq 'ARRAY') {
		$keys = Tie::IxHash->new(@$keys);
	}

	return $self->$orig($keys, $options);
};

__PACKAGE__->meta->make_immutable;
