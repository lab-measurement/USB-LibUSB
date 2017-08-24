#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use experimental 'signatures';
use JSON::XS;
use File::Slurper 'read_binary';
use File::Find;
use autodie qw/:all/;

system(qw/perl Makefile.PL/);

my $meta_json = decode_json(read_binary('MYMETA.json'));
my $version = $meta_json->{version};

if ($version !~ /^(?<major>[0-9])\.(?<minor>[0-9]{2})$/) {
    die "version $version is invalid";
}

my $major = $+{major};
my $minor = $+{minor};

printf("current version number: %d.%02d\n", $major, $minor);

if ($minor == 99) {
    $minor = 0;
    ++$major;
}
else {
    ++$minor;
}

my $new_version = sprintf("%d.%02d", $major, $minor);
say "new version number: $new_version";

# Replace 'our $VERSION = ...' in .pm files

for my $module (find_modules()) {
    my $source = read_binary($module);
    $source =~ s/^our \$VERSION = \K'$version'/'${new_version}'/m;
    write_file($module, $source);
}


# Git tag & commit
system('git', 'commit', '-am', "update version $version -> $new_version");
system('git', 'tag', '-a', "v$new_version", '-m', "version $new_version");





sub write_file ($filename, $content) {
    open my $fh, ">", $filename;
    print {$fh} $content;
    close $fh;
}

sub find_modules {
    my @files;
    File::Find::find(
    {
        wanted => sub { -f $_ && /\.pm$/ and push @files, $_ },
        no_chdir => 1
    },
    'lib'
        );
    say "modules: @files";
    return @files;
}
