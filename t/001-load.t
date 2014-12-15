#!perl
### Test that the module(s) load!(s)
use Test::More;
use MooseX::Singleton;
no  MooseX::Singleton;
use MooseX::ShortCut::BuildInstance 0.008;
use Data::Walk::Extracted 0.024;
use Data::Walk::Prune 0.024;
use Data::Walk::Clone 0.024;
use Data::Walk::Graft 0.024;
use Data::Walk::Print 0.024;
use lib 
	'../lib', 'lib';
use Log::Shiras::Types 0.018;
use Log::Shiras::Switchboard 0.018;
use Log::Shiras::Telephone 0.018;
use Log::Shiras::TapPrint 0.018;
use Log::Shiras::TapWarn 0.018;
use Test::Log::Shiras 0.018;
use Log::Shiras::Report 0.018;
use Log::Shiras::Report::ShirasFormat 0.018;
use Log::Shiras::Report::TieFile 0.018;
pass( "Test loading the modules in the package" );
done_testing();