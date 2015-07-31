# -----------------------------------------------------------
# Random sleep sort: for each element in the list create a
# thread that will sleep random amount of time and after
# that push element to the channel. Then, if elements in the
# channel are not sorted, repeat afain.
# So far this is the most unefficient sorting algorithm I
# know of.
#
# In addition, use some perl6 operator features to make a
# nive threading operator:
#
#       my $channel = Channel.new;
#
#       @a{5}~~»:code({
#           rand.sleep;
#           $channel.send($_) };
#       })
#
# What this operator does is: foreach lelemt in @a, create
# a tread and execute following block of code. In addition,
# throttle the threading by not spawning more than 5 threads
# at a time.
# And the block of code is passed as a clojure with ref to
# the channel.

# just 4 elements since the sort can thake a loong time for more elements :)
my @a = (14,23,1,2);

sub postcircumfix:<{ }~~»>(@worklist, $atatime, :$code) {

    my @working;
    for @worklist -> $todo {
        @working.push(start { $code($todo) });
        next if @working < $atatime;

        await Promise.anyof(@working);

        @working .= grep(!*);
    }
    await Promise.allof(@working);
}

say "- " x 40;



my $sorted = [<=] @a;
say $sorted;
while (! $sorted ) {

    say "not sorted yet, play it again Sam.";

    my $channel = Channel.new;

    say "waiting on all threads to finish...";
    @a{5}~~»:code({
        rand.sleep;
        $channel.send($_) };
    );
    say "all threads done. Closing the channel...";
    $channel.close;

    say "Channel content:";

    @a = @$channel;
    for @a -> $x { say $x }

    $sorted = [<=] @a;
}
say "Finally sorted!";

