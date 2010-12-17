use Module::Build;

Module::Build->new(
    module_name     => "Exporter::NoWork",
    license         => "perl",
    requires        => {
        "Attribute::Handlers"   => "0.80",
    },
    build_requires  => {
        "Test::More"    => "0.61",
        "Test::Exports" => "1",
    },
)->create_build_script;
