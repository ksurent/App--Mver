use inc::Module::Install;

all_from 'lib/App/Mver.pm';
requires 'Pod::Parser';
recommends 'Module::CoreList';
install_script 'mver';

WriteAll;
