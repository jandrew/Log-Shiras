#!perl
#########1 Test for good POD  3#########4#########5#########6#########7#########8#########9
### Test that the pod files run
use Test2::Bundle::Extended qw( !meta );
use Test2::Plugin::UTF8;
plan( 17 );
use Test::Pod 1.48;
my	$up		= '../';
for my $next ( <*> ){
	if( ($next eq 't') and -d $next ){
		note "Found the t directory - must be using prove";
		$up	= '';
		last;
	}
}
pod_file_ok( $up . 	'README.pod',
						"The README file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras.pm',
						"The Log::Shiras file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Unhide.pm',
						"The Log::Shiras::Unhide file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Test2.pm',
						"The Log::Shiras::Test2 file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Types.pm',
						"The Log::Shiras::Types file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Switchboard.pm',
						"The Log::Shiras::Switchboard file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Telephone.pm',
						"The Log::Shiras::Telephone file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/LogSpace.pm',
						"The Log::Shiras::LogSpace file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/TapPrint.pm',
						"The Log::Shiras::TapPrint file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/TapWarn.pm',
						"The Log::Shiras::TapWarn file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report.pm',
						"The Log::Shiras::Report file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/CSVFile.pm',
						"The Log::Shiras::Report::CSVFile file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/Test2Note.pm',
						"The Log::Shiras::Report::Test2Note file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/Test2Diag.pm',
						"The Log::Shiras::Report::Test2Diag file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/Stdout.pm',
						"The Log::Shiras::Report::Stdout file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/MetaMessage.pm',
						"The Log::Shiras::Report::MetaMessage file has good POD" );
pod_file_ok( $up . 	'lib/Log/Shiras/Report/PostgreSQL.pm',
						"The Log::Shiras::Report::PostgreSQL file has good POD" );