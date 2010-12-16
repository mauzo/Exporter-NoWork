use 5.006;

use inc::Module::Install;

name            'Exporter-NoWork';
license         'perl';
all_from        'lib/Exporter/NoWork.pm';

requires        'Attribute::Handlers'   => '0.80';
requires        'Test::More'            => '0.61';
requires        'Test::Exports'         => 0;

auto_install;
WriteAll;
