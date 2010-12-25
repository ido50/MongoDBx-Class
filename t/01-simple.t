#!perl -T

use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 12;
use MongoDBx::Class;

my $dbx = MongoDBx::Class->new(namespace => 'Schema');
ok($dbx, 'Got a proper MongoDBx::Class object');

is(scalar(keys %{$dbx->doc_classes}), 5, 'successfully loaded schema');

SKIP: {
	eval { $dbx->connect };

	skip "Can't connect to MongoDB server", 10 if $@;

	$dbx->conn->safe(1);
	is($dbx->conn->safe, 1, "Using safe operations by default");

	my $db = $dbx->conn->get_database('mongodbx_class_test');
	my $novels_coll = $db->get_collection('novels');
	
	my $novel = $novels_coll->insert({
		_class => 'Novel',
		title => 'The Valley of Fear',
		year => 1914,
		author => {
			first_name => 'Arthur',
			middle_name => 'Conan',
			last_name => 'Doyle',
		},
		tags => [
			{ category => 'mystery', subcategory => 'thriller' },
			{ category => 'mystery', subcategory => 'detective' },
			{ category => 'crime', subcategory => 'fiction' },
		],
	});

	is(ref($novel->_id), 'MongoDB::OID', 'document successfully inserted');

	is($novel->author->name, 'Arthur Conan Doyle', 'embedded document works');

	my $synopsis = $db->synopsis->insert({
		_class => 'Synopsis',
		novel => $novel,
		text => "The Valley of Fear is the final Sherlock Holmes novel by Sir Arthur Conan Doyle. The story was first published in the Strand Magazine between September 1914 and May 1915. The first book edition was published in New York on 27 February 1915.",
	});

	is(ref($synopsis->_id), 'MongoDB::OID', 'successfully created a synopsis');
	is($synopsis->novel->_id, $novel->_id, 'reference from synopsis to novel correct');

	my @reviews = $db->get_collection('reviews')->batch_insert([
		{
			_class => 'Review',
			novel => $novel,
			reviewer => 'Some Guy',
			text => 'I really liked it!',
			score => 5,
		}, 
		{
			_class => 'Review',
			novel => $novel,
			reviewer => 'Some Other Guy',
			text => 'It was okay.',
			score => 3,
		}, 
		{
			_class => 'Review',
			novel => $novel,
			reviewer => 'Totally Different Guy',
			text => 'Man, that just sucked!',
			score => 1,
		}
	]);

	is(scalar(@reviews), 3, 'successfully created three reviews');

	my ($total_score, $avg_score) = (0, 0);
	foreach (@reviews) {
		$total_score += $_->score || 0;
	}
	$avg_score = $total_score / scalar(@reviews);
	is($avg_score, 3, 'average score correct');

	$novel->update({ year => 1915 });

	my $found_novel = $db->novels->find_one({ _id => MongoDB::OID->new(value => $novel->id) });
	is($found_novel->reviews->count, 3, 'joins_many works correctly');
	is($found_novel->year, 1915, "novel's year successfully changed");

	$novel->delete;

	my $novels = $db->novels->find({ title => 'The Valley of Fear' });
	is($novels->count, 0, 'Novel successfully removed');
}

done_testing();
