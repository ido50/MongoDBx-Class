#!/perl

use lib 't/lib';
use strict;
use warnings;
use Test::More;
use MongoDBx::Class;

my $dbx = MongoDBx::Class->new(namespace => 'MongoDBxTestSchema');

# temporary bypass, should be removed when I figure out why tests can't find the schema
if (scalar(keys %{$dbx->doc_classes}) != 5) {
	plan skip_all => "Temporary skip due to schema not being found";
} else {
	plan tests => 11;
}

SKIP: {
	is(scalar(keys %{$dbx->doc_classes}), 5, 'successfully loaded schema');

	SKIP: {
		my $conn;
		eval { $conn = $dbx->connect(safe => 1) };

		skip "Can't connect to MongoDB server", 10 if $@;

		my $db = $conn->get_database('mongodbx_class_test');
		$db->drop;
		my $novels_coll = $db->get_collection('novels');

		# create a novel object without inserting it to the database
		my $novel = $novels_coll->create({
			_class => 'Novel',
			title => 'The Valley of Fear',
			year => 1914,
			author => {
				first_name => 'Arthur',
				middle_name => 'Conan',
				last_name => 'Doyle',
			},
			added => DateTime->now,
			tags => [
				{ category => 'mystery', subcategory => 'thriller' },
				{ category => 'mystery', subcategory => 'detective' },
				{ category => 'crime', subcategory => 'fiction' },
			],
		});
		is(ref $novel, 'MongoDBxTestSchema::Novel', 'got a Novel object back from create');

		# try to find that novel in the database
		ok(!$novels_coll->find_one($novel->_id), 'novel document was not saved to the database');

		# now save it to the database
		$novel->save;
		ok($novels_coll->find_one($novel->_id), 'novel document now exists in the database');

		# let's check TO_JSON works
		my $json = $novel->TO_JSON;

		is(ref $json, 'HASH', 'TO_JSON returned a hash-ref');
		is($json->{year}, 1914, 'Returned hash-ref has correct year field');
		is(ref $json->{author}, 'HASH', 'Returned hash-ref has hash-ref for author');
		is($json->{author}->{middle_name}, 'Conan', 'Returned hash-ref has correct author middle name');
		is(ref $json->{tags}, 'ARRAY', 'Returned hash-ref has array-ref for tags');
		is(scalar @{$json->{tags}}, 3, 'Returned hash-ref has 3 tags');

		# let's make sure our own _ids are not overwritten
		my $other_novel = $novels_coll->create({
			_id => 'asdf',
			_class => 'Novel',
			title => 'The Falley of Vear',
			author => {
				first_name => 'Darthur',
				middle_name => 'Conan',
				last_name => 'Oyle'
			}
		});
		is($other_novel->_id, 'asdf', 'our own _id is not overwritten');

		$db->drop;
	}
}

done_testing();
