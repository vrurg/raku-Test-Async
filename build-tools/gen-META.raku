#!/usr/bin/env raku

use lib <lib>;
use META6;
use Test::Async;

my $m = META6.new(
    name           => 'Test::Async',
    description    => 'Thread-safe testing framework',
    version        => Test::Async.^ver,
    perl-version   => Version.new('6.d'),
    depends        => [],
    # test-depends   => <Test::META>,
    build-depends  => <META6 p6doc Pod::To::Markdown>,
    tags           => <TESTING ASYNC>,
    authors        => ['Vadim Belman <vrurg@cpan.org>'],
    auth           => 'github:vrurg',
    source-url     => 'git://github.com/vrurg/raku-Test-Async.git',
    support        => META6::Support.new(
        source          => 'https://github.com/vrurg/raku-Test-Async.git',
    ),
    provides => {
        'Test::Async'                            => 'lib/Test/Async.rakumod',
        'Test::Async::Aggregator'                => 'lib/Test/Async/Aggregator.rakumod',
        'Test::Async::Base'                      => 'lib/Test/Async/Base.rakumod',
        'Test::Async::Decl'                      => 'lib/Test/Async/Decl.rakumod',
        'Test::Async::Event'                     => 'lib/Test/Async/Event.rakumod',
        'Test::Async::Job'                       => 'lib/Test/Async/Job.rakumod',
        'Test::Async::JobMgr'                    => 'lib/Test/Async/JobMgr.rakumod',
        'Test::Async::Hub'                       => 'lib/Test/Async/Hub.rakumod',
        'Test::Async::Reporter'                  => 'lib/Test/Async/Reporter.rakumod',
        'Test::Async::Result'                    => 'lib/Test/Async/Result.rakumod',
        'Test::Async::TestTool'                  => 'lib/Test/Async/TestTool.rakumod',
        'Test::Async::Utils'                     => 'lib/Test/Async/Utils.rakumod',
        'Test::Async::X'                         => 'lib/Test/Async/X.rakumod',
        'Test::Async::Metamodel::BundleHOW'      => 'lib/Test/Async/Metamodel/BundleHOW.rakumod',
        'Test::Async::Metamodel::BundleClassHOW' => 'lib/Test/Async/Metamodel/BundleClassHOW.rakumod',
        'Test::Async::Metamodel::HubHOW'         => 'lib/Test/Async/Metamodel/HubHOW.rakumod',
        'Test::Async::Metamodel::ReporterHOW'    => 'lib/Test/Async/Metamodel/ReporterHOW.rakumod',
        'Test::Async::Reporter::TAP'             => 'lib/Test/Async/Reporter/TAP.rakumod',
    },
    license        => 'Artistic-2.0',
    production     => True,
);

print $m.to-json;

#my $m = META6.new(file => './META6.json');
#$m<version description> = v0.0.2, 'Work with Perl 6 META files even better';
#spurt('./META6.json', $m.to-json);
