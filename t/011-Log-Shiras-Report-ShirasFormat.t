#!perl
#######  Test File for Log-Shiras-Report-ACMEFormat  #######
use Test::Most;
use lib '../lib', 'lib';
BEGIN{
	#~ $ENV{ Smart_Comments } = '### #### #####';
}
use Log::Shiras::Report::ShirasFormat 0.007;

SKIP: {
	skip( "Log::Shiras::Report::ShirasFormat not written yet", 1 );
	ok 1, "Dummy Test";
}
explain 								"...Test Done";
done_testing();