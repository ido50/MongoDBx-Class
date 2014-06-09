package MongoDBx::Class::DocumentBase;

# ABSTRACT: Base role for documents and embedded documents

our $VERSION = "1.040000";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;
use Carp;
use Scalar::Util qw/blessed/;

=head1 NAME

MongoDBx::Class::DocumentBase - Base role for documents and embedded documents

=head1 SYNOPSIS

	# used internally

=head1 DESCRIPTION

C<MongoDBx::Class::DocumentBase> is a base L<role|Moose::Role> providing both
regular documents (L<MongoDBx::Class::Document>) and embedded documents
(L<MongoDBx::Class::EmbeddedDocument>) with common attributes and methods.

=head1 ATTRIBUTES

The following attributes are provided:

=head2 _collection

The L<MongoDBx::Class::Collection> object representing the MongoDB collection
in which the document is stored. This is a required attribute.

=head2 _class

A string. The name of the document class of this document. This is a required
attribute.

=cut

has '_collection' => (is => 'ro', isa => 'MongoDBx::Class::Collection', required => 1);

has '_class' => (is => 'ro', isa => 'Str', required => 1);

=head1 OBJECT METHODS

The following object methods are provided:

=head2 TO_JSON()

Creates a JSON representation of the object. The methods' name is for compatibility
with modules from the L<JSON> family, who expect this method to exist when
encountering objects during serialization.

=cut

sub TO_JSON {
	my $self = shift;

	my %json = map { my $val = $self->$_; $_ => $self->_jsonify_val($val) } $self->_attributes;

	%json = map { $_ => $json{$_} } grep { defined $json{$_} } keys %json;

	$json{_class} = $self->_class;

	return \%json;
}

=head1 INTERNAL METHODS

The following methods are only to be used internally.

=head2 _database()

Convenience method, shortcut for C<< $doc->_collection->_database >>.

=cut

sub _database {
	shift->_collection->_database;
}

=head2 _connection()

Convenience method, shortcut for C<< $doc->_database->_connection >>.

=cut

sub _connection {
	shift->_database->_connection;
}

=head2 _attributes()

Returns a list of names of all attributes the document object has, minus
'_collection' and '_class', sorted alphabetically.

=cut

sub _attributes {
	my @names;
	foreach (shift->meta->get_all_attributes) {
		next if $_->name =~ m/^_(class|collection)$/;
		if ($_->{isa} =~ m/MongoDBx::Class::CoercedReference/ || ($_->documentation && $_->documentation eq 'MongoDBx::Class::EmbeddedDocument')) {
			my $name = $_->name;
			$name =~ s/^_//;
			push(@names, $name);
		} else {
			push(@names, $_->name);
		}
	}

	return sort @names;
}

sub _jsonify_val {
	my ($self, $val) = @_;

	if (blessed $val) {
		if (blessed $val eq 'DateTime') {
			return DateTime::Format::W3CDTF->format_datetime($val);
		} else {
			return $val->TO_JSON;
		}
	} elsif (ref $val && ref $val eq 'ARRAY') {
		my @array;
		foreach my $item (@$val) {
			push(@array, $self->_jsonify_val($item));
		}
		return \@array;
	} elsif (ref $val && ref $val eq 'HASH') {
		my $hash = {};
		foreach my $key (keys %$val) {
			$hash->{$_} = $self->_jsonify_val($val->{$key});
		}
		return $hash;
	}

	return $val;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::DocumentBase

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class::Moose>, L<MongoDBx::Class::EmbeddedDocument>.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
