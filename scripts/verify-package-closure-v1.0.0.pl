#!/usr/bin/env perl
use strict;
use warnings;

# Validate package closure against the pinned source's generated metadata.
# This executes only in the GitHub-hosted build preparation phase; it does not
# compile a firmware image.  Simple conditional dependencies are evaluated
# from the final Kconfig file so that package options such as tar's ACL support
# cannot leave an unselected runtime library until the package build.
my $enable_missing = @ARGV && $ARGV[0] eq '--enable-missing' ? shift @ARGV : 0;
my ($source_dir, $config_file, $seed_file) = @ARGV;
die "usage: $0 SOURCE_DIR CONFIG_FILE REQUIRED_PACKAGES_FILE\n"
    unless defined $seed_file;

unshift @INC, "$source_dir/scripts";
require metadata;
metadata::parse_package_metadata("$source_dir/tmp/.packageinfo")
    or die "cannot parse $source_dir/tmp/.packageinfo\n";

open my $config_fh, '<', $config_file or die "cannot read $config_file: $!\n";
my (%enabled, %symbols);
my @config_lines;
while (my $line = <$config_fh>) {
    push @config_lines, $line;
    if ($line =~ /^CONFIG_([^=]+)=(?:y|m)$/) {
        $symbols{$1} = 1;
        $enabled{$1} = 1 if $1 =~ /^PACKAGE_(.+)$/;
    }
}
close $config_fh;

open my $seed_fh, '<', $seed_file or die "cannot read $seed_file: $!\n";
my @seeds;
while (my $line = <$seed_fh>) {
    chomp $line;
    $line =~ s/\s+#.*$//;
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    die "invalid package name in $seed_file: $line\n"
        unless $line =~ /^[A-Za-z0-9][A-Za-z0-9+_.-]*$/;
    push @seeds, $line;
}
close $seed_fh;

my (%seen, %parent, @queue, @missing, @virtual);
for my $seed (@seeds) {
    die "required package $seed is absent from pinned package metadata\n"
        unless exists $metadata::package{$seed};
    push @queue, $seed;
    $parent{$seed} = 'required package set';
}

# Required roots alone are not enough: OpenWrt default packages can expose
# conditionally-enabled shared-library dependencies as well.  Traverse every
# selected package that has metadata after the final defconfig pass.
for my $selected (sort keys %enabled) {
    next unless exists $metadata::package{$selected};
    push @queue, $selected;
    $parent{$selected} //= 'final Kconfig selection';
}

while (my $name = shift @queue) {
    next if $seen{$name}++;
    if (!$enabled{$name}) {
        push @missing, $name;
    }
    my $package = $metadata::package{$name};
    next unless $package;
    for my $dependency (@{$package->{depends} || []}) {
        my $child;
        if ($dependency =~ /^\+([A-Za-z0-9][A-Za-z0-9+_.-]*)$/) {
            $child = $1;
        } elsif ($dependency =~ /^([A-Za-z0-9][A-Za-z0-9+_.-]*)$/) {
            # A bare metadata entry is a mandatory package dependency.  For
            # example, the OpenWrt xz utility package requires its xz-utils
            # meta package even though that edge has no leading '+'.
            $child = $1;
        } elsif ($dependency =~ /^\+(!?)([A-Za-z0-9_]+):([A-Za-z0-9][A-Za-z0-9+_.-]*)$/) {
            my ($negated, $condition, $candidate) = ($1, $2, $3);
            my $condition_enabled = $symbols{$condition} ? 1 : 0;
            next if $negated ? $condition_enabled : !$condition_enabled;
            $child = $candidate;
        } else {
            # Complex expressions are deliberately left to OpenWrt's own
            # resolver; all simple CONFIG_SYMBOL:package edges are checked.
            next;
        }
        if (!exists $metadata::package{$child}) {
            push @virtual, $child;
            next;
        }
        $parent{$child} //= $name;
        push @queue, $child;
    }
}

my @resolved = sort keys %seen;
print "DoorNet2-V1.0.0 resolved package closure entries: " . scalar(@resolved) . "\n";
print "Closure virtual providers: " . join(', ', sort keys %{ { map { $_ => 1 } @virtual } }) . "\n"
    if @virtual;
if ($enable_missing && @missing) {
    # Kconfig does not automatically select every dependency expressed only
    # in package metadata.  Materialize the deterministic closure after the
    # final defconfig pass, then run this tool again as a read-only gate.
    my %materialize = map { $_ => 1 } @missing;
    open my $append_fh, '>', $config_file
        or die "cannot update $config_file: $!\n";
    for my $line (@config_lines) {
        next if $line =~ /^CONFIG_PACKAGE_([^=]+)=/ && $materialize{$1};
        next if $line =~ /^# CONFIG_PACKAGE_(.+) is not set$/ && $materialize{$1};
        print {$append_fh} $line;
    }
    for my $name (sort @missing) {
        print {$append_fh} "CONFIG_PACKAGE_${name}=y\n";
    }
    close $append_fh or die "cannot close $config_file: $!\n";
    print "DoorNet2-V1.0.0 materialized " . scalar(@missing)
        . " missing closure selections; re-validating is required.\n";
    exit 0;
}
if (@missing) {
    print STDERR "DoorNet2-V1.0.0 missing selected package closure entries:\n";
    for my $name (sort @missing) {
        print STDERR "  $name (required by $parent{$name})\n";
    }
    exit 1;
}
print "DoorNet2-V1.0.0 package closure precheck: PASS\n";
