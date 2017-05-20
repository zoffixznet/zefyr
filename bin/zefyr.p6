#!/usr/bin/env perl6
use v6.d.PREVIEW;
# use WWW;

constant ECO_API = 'https://modules.perl6.org/.json';

class Zefyr {
    method top100 {
        # my @modules = jget(ECO_API)<dists>.sort(-*<stars>).grep({
        #     try { Date.new(.<date_updated>) after Date.today.earlier: :4months }
        # })»<name>.grep(none |<p6doc panda v5>, /^ "Inline::"/).head: 100;

my @modules = <
007 Bailador zef Crust November JSON::Tiny DBIish BioPerl6 Yapsi GTK::Simple HTTP::UserAgent App::Mi6 Digest Electron Grammar::Debugger Frinfon Acme::Anguish Farabi6 App::GPTrixie Net::IRC::Bot MongoDB HTTP::Server::Async Slang::SQL List::Utils HTTP::Client Druid XML::Parser::Tiny Text::Markov ANTLR4 P6W HTTP::Server::Tiny Test::Mock LibraryMake Debugger::UI::CommandLine Sparrowdo Perl6::Parser SVG::Plot Terminal::Print Web::App::MVC Grammar::BNF JSON::RPC NCurses Net::Curl Perl6::Maven XML Digest::MD5 Template::Mojo Selenium::WebDriver JSON::Fast IRC::Client Getopt::Kinoko CoreHackers::Sourcery Test::Fuzz GraphQL Stats PKafka XML::Writer Math::Model MagickWand PDF::Grammar Template::Mustache IO::Socket::SSL C::Parser App::Pray HTTP::MultiPartParser WebSocket GlotIO App::InstallerMaker::WiX Data::Dump::Tree IO::Prompter BioInfo TelegramBot OpenSSL Flower SCGI Pod::To::HTML MessagePack Plosurin CSS::Grammar File::Find Clifford Data::Dump P6TCI App::MoarVM::HeapAnalyzer Spit WWW YAMLish Pekyll Acme::Meow mandelbrot Math::Vector Config::INI Term::ANSIColor Terminal::ANSIColor ABC Template6 App::jsonv Math::RungeKutta String::CRC32 Cache::Memcached>;

        say "Installing @modules[]";
        my $outdir = 'output'.IO.mkdir.self;

        my role ModuleNamer[$name] { method Module-Name { $name } }
        my @results = @modules.map: -> $module {
            start {
                with run :out, :err, <zef --serial --debug install>, $module {
                    my $out = .out.slurp-rest: :close;
                    $outdir.add($module.subst: :g, /\W+/, '-').spurt:
                          "ERR: {.err.slurp-rest: :close}\n\n-----\n\n"
                        ~ "OUT: $out\n";
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
