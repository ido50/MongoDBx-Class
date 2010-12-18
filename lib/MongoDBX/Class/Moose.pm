package MongoDBX::Class::Moose;

use Moose ();
use Moose::Exporter;

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

1;
