#!perl
#######  Test File for Log-Shiras-Report-TieFile  #######
use Test::Most;
use lib '../lib', 'lib';
BEGIN{
	#~ $ENV{ Smart_Comments } = '### #### #####';
}
use Log::Shiras::Report::TieFile 0.007;

SKIP: {
	skip( "Log::Shiras::Report::TieFile not written yet", 1 );
	ok 1, "Dummy Test";
}
explain 								"...Test Done";
done_testing();