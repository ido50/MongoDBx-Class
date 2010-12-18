package MongoDBX::Class::Collection;

# ABSTRACT: A MongoDBX::Class collection object

use Moose;
use namespace::autoclean;

extends 'MongoDB::Collection';

=head1 NAME

MongoDBX::Class::Collection - A MongoDBX::Class collection object

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

	$opts ||= {};
	$opts->{safe} = 1 if $self->_database->_connection->safe && !defined $opts->{safe};

	foreach (@$docs) {
		foreach my $attr (keys %$_) {
			if (ref $_->{$attr} && $_->{$attr}->does('MongoDBX::Class::Document')) {
				$_->{$attr} = { '$ref' => $_->{$attr}->_collection->name, '$id' => $_->{$attr}->_id };
			} elsif (ref $_->{$attr} && $_->{$attr}->does('MongoDBX::Class::EmbeddedDocument')) {
				my $hash = {};
				foreach my $ha (keys %{$_->{attr}}) {
					next if $ha eq '_collection';
					$hash->{$ha} = $_->{attr}->{$ha};
				}
				$_->{$attr} = $hash;
			}
		}
	}

	if ($opts->{safe}) {
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

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class::Collection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBX::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBX::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBX::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBX::Class/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
