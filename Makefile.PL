use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Exporter::NoWork',
    VERSION_FROM      => 'lib/Exporter/NoWork.pm', # finds $VERSION
    PREREQ_PM         => {
        'Attribute::Handlers' => 0.0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Exporter/NoWork.pm', # retrieve abstract from module
       AUTHOR         => 'Ben Morrow <Exporter-NoWork@morrow.me.uk>') : ()),
);
