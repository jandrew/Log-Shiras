#!perl
### Test that the module(s) load!(s)
use MooseX::Singleton;
no  MooseX::Singleton;
use 5.010;
use Test::Most;
use Test::More;
use Test::Moose;
use Capture::Tiny 0.12;
use YAML::Any;
use Carp;
use version 0.94;
use MooseX::Types::Moose;
use Moose::Exporter;
use YAML::Any;
use IO::Callback;
use MooseX::ShortCut::BuildInstance 0.003;
use lib 
	'../lib', 'lib', '../../../lib', 
	'../../Data-Walk-Extracted/lib',
	'../Data-Walk-Extracted/lib';
use Log::Shiras::Switchboard v0.013;
use MooseX::StrictConstructor;
use Data::Walk::Extracted 0.017;
use Data::Walk::Prune 0.011;
use Data::Walk::Clone 0.011;
use Data::Walk::Graft 0.013;
use Log::Shiras::Telephone 0.001;
use Log::Shiras::Switchboard 0.013;
use Test::Log::Shiras 0.009;
use Log::Shiras::Report 0.007;
use Log::Shiras::Report::ShirasFormat 0.007;
pass( "Test loading the modules in the package" );
done_testing();