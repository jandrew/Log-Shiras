#!perl
#########1 Test that the modules load!  4#########5#########6#########7#########8#########9
### Test that the module(s) load!(s)
use	Test::More;
BEGIN{ use_ok( Test::Pod, qw( 1.48 ) ) };
BEGIN{ use_ok( TAP::Formatter::Console ) };
BEGIN{ use_ok( TAP::Harness ) };
BEGIN{ use_ok( TAP::Parser::Aggregator ) };
BEGIN{ use_ok( version ) };
BEGIN{ use_ok( Test::Moose ) };
BEGIN{ use_ok( MooseX::ShortCut::BuildInstance, 1.044 ) };
BEGIN{ use_ok( Data::Walk::Extracted, 0.028 ) };
BEGIN{ use_ok( Data::Walk::Prune, 0.028 ) };
BEGIN{ use_ok( Data::Walk::Clone, 0.028 ) };
BEGIN{ use_ok( Data::Walk::Graft, 0.028 ) };
BEGIN{ use_ok( Data::Walk::Print, 0.028 ) };
use	lib '../lib', 'lib';
BEGIN{ use_ok( Log::Shiras, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Test2, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Types, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Unhide, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Switchboard, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Telephone, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::LogSpace, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::TapPrint, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::TapWarn, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Report, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Report::CSVFile, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Report::Test2Note, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Report::Stdout, 0.029 ) };
BEGIN{ use_ok( Log::Shiras::Report::MetaMessage, 0.029 ) };
done_testing();