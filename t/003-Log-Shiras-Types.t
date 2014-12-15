#!perl
#######  High level Test File for Log::Shiras::Types  #######

use Test::More;
use lib '../lib', 'lib';
use Log::Shiras::Types 0.018 qw(
			posInt
			elevenArray
			elevenInt
			jsonfile
			yamlfile
);
my			$Scite_Testing = ( -e 't' ) ? 't/' : '' ;
### <where> - testing posInt ...
my  		@posIntArray = qw(
				1
				999999
				0
				-0
			);
my  		@notposIntArray = qw(
				-1
				-999999
				1.1
				999.00000000000000001
			);
map{									
ok			is_posInt( $_ ),			"Correct -posInt- test ( $_ )",
} 			@posIntArray;
map{
ok			!is_posInt( $_ ),			"Not a -posInt- test ( $_ )",
} 			@notposIntArray;

### <where> - testing elevenArray ...
my  		@elevenArrayArray = (
				[ 0, 1, 2, 3, ],
				[ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ],
				[],
			);
my  		@notelevenArrayArray = (
				[ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ],
			);
map{									
ok			is_elevenArray( $_ ),		"Correct -elevenArray- test with -" . 
											scalar( @$_ ) . "- elements",
} 			@elevenArrayArray;
map{
ok			!is_elevenArray( $_ ),		"Bad -elevenArray- test with -" .
											scalar( @$_ ) . "- elements",
} 			@notelevenArrayArray;

### <where> - testing elevenInt ...
my  		@elevenIntArray = qw(
				1
				11
				0
			);
my  		@notelevenIntArray = qw(
				-1
				12
				1.1
			);
map{									
ok			is_elevenInt( $_ ),			"Correct -elevenInt- test ( $_ )",
} 			@elevenIntArray;
map{
ok			!is_elevenInt( $_ ),		"Not an -elevenInt- test ( $_ )",
} 			@notelevenIntArray;

### <where> - testing jsonfile ...
my  		@jsonfileArray = qw(
				test_files/config.json
			);
my  		@notjsonfileArray = qw(
				config.json test_files/configII.json
			);
map{									
ok			is_jsonfile( $Scite_Testing . $_ ),
									"Correct -jsonfile- test ( $_ )",
} 			@jsonfileArray;
map{
ok			!is_jsonfile( $Scite_Testing . $_ ),
									"Not a -jsonfile- test ( $_ )",
} 			@notjsonfileArray;

### <where> - testing yamlfile ...
my  		@yamlfileArray = qw(
				test_files/config.yml test_files/configII.yml
			);
my  		@notyamlfileArray = qw(
				config.yml 
			);
map{									
ok			is_yamlfile( $Scite_Testing . $_ ),
									"Correct -yamlfile- test ( $_ )",
} 			@yamlfileArray;
map{
ok			!is_yamlfile( $Scite_Testing . $_ ),
									"Not a -yamlfile- test ( $_ )",
} 			@notyamlfileArray;
explain									"... Done Testing";
done_testing;