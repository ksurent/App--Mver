use inc::Module::Install;

all_from 'lib/App/Mver.pm';
requires 'Pod::Parser';
install_script 'mver';

WriteAll;
