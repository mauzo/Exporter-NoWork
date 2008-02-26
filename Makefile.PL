use 5.006;

use inc::Module::Install;

name            'Exporter-NoWork';
license         'perl';
all_from        'lib/Exporter/NoWork.pm';

requires        'Attribute::Handlers' => 0;

auto_install;
WriteAll;
