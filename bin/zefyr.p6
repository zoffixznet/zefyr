#!/usr/bin/env perl6
use v6.d.PREVIEW;
use WWW;

constant ECO_API = 'https://modules.perl6.org/.json';

class Zefyr {
    method top100 {
        my @modules = jget(ECO_API)<dists>.sort(-*<stars>).grep({
            Date.new(.<date_updated>) after Date.today.earlier: :4months
        })»<name>.grep(none |<p6doc panda v5>, /^ "Inline::"/).head: 100;

        say "Installing @modules[]";
        my $outdir = 'output'.IO.mkdir.self;

        my role ModuleNamer[$name] { method Module-Name { $name } }
        my @results = @modules.map: -> $module {
            start {
                with run :out, :err, <zef --serial --debug install>, $module {
                    my $out = .out.slurp: :close;
                    $outdir.add($module.subst: :g, /\W+/, '-').spurt:
                        "ERR: {.err.slurp: :close}\n\n-----\n\nOUT: $out\n";
                    $out
                }
            } does ModuleNamer[$module]
        }

        say "Started {+@results} Promises. Awaiting results";
        while @results {
            await Promise.anyof: @results;
            my @ready = @results.grep: *.so;
            @results .= grep: none @ready;
            for @ready {
                say .Module-Name ~ ': ', .status ~~ Kept
                    ?? <SUCCEEDED!  FAILED!>[.result.contains: 'FAILED']
                    !! "died with {.cause}";
            }
        }
    }
}

sub MAIN (:$top100) {
    Zefyr.new.top100;
}
