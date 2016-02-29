#!/usr/bin/env perl

my $blanked = 0;
open (IN, "xscreensaver-command -display \":0\" -watch |");
while (<IN>) {
    if (m/^(BLANK|LOCK)/) {
        if (!$blanked) {
            #system "touch /tmp/screentest";
            system "ssh-add -D";
            $blanked = 1;
        }
    } elsif (m/^UNBLANK/) {
        #system "sound-on";
        $blanked = 0;
    }
}

