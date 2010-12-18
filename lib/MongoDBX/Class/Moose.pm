package MongoDBX::Class::Moose;

# ABSTRACT: Extends Moose with common relationships for MongoDBX::Class documents

use Moose ();
use Moose::Exporter;

=head1 NAME

MongoDBX::Class::Moose - Extends Moose with common relationships for MongoDBX::Class documents

=cut

Moose::Exporter->setup_import_methods(
	with_meta => [ 'belongs_to', 'has_many', 'has_one' ],
	also      => 'Moose',
);

sub belongs_to {
	my ($meta, $name, %opts) = @_;

	$opts{is} = 'rw';
	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBX::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_attribute( '_'.$name => %opts );
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;
		return $self->$attr->load;
	});
}

sub has_many {
	my ($meta, $name, %opts) = @_;

	$opts{is} = 'rw';
	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBX::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_method($name => sub {
		my $self = shift;

		my $coll_name = $coll eq '<same>' ? $self->_collection->name : $coll;

		return $self->_collection->_database->get_collection($coll_name)->find({ $ref.'.$id' => $self->_id });
	});
}

sub has_one {
	my ($meta, $name, %opts) = @_;

	$opts{is} = 'rw';
	$opts{coll} ||= '<same>';
	$opts{isa} = 'MongoDBX::Class::Reference';

	my $ref = delete $opts{ref};
	my $coll = delete $opts{coll};

	$meta->add_attribute( '_'.$name => %opts );
	$meta->add_method($name => sub {
		my $self = shift;

		my $attr = '_'.$name;
		return $self->$attr->load;
	});
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-MongoDBX::Class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBX::Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBX::Class::Moose

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

1;
