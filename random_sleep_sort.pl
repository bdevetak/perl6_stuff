# ------------------------------------------------------------
# 
# Basic Random Sleep Sort:
# ========================
# For each element in the list create
# a thread that will sleep random amount of time and after
# that push the element to the channel. Then, if elements in
# the channel are not sorted, repeat again. So, basically it
# repeats sleep-shuffle until the list is sorted. This is the
# second most inefficient sorting algorithms I know of.
#
# Asymmetric Random Sleep Sort:
# ============================
# The basic idea is the same as with random sleep sort, except
# we have thread number throttling, so there is a limit to the
# number of threads at any given point in time. This means that
# only N items at a time are random-sleep-shuffled. The effect
# of that is that items can move forward in the list for arbitrary
# number of positions, but when moving backwards, they can
# move only N places per iteration, where N is the throttling
# limit for number of threads. Depending on the initial
# distribution of elements, the asymmetric random sleep sort
# can finish the sorting faster or slower than basic random
# sleep sort, but the fact that its performance depends on
# initial distribution of elements makes it worse than basic
# random sleep sort. This is the worst sorting algorithm I know of.
#
# Perl6 Operator for Asymmetric Random Sleep Sort:
# ===============================================
# It is very easy to wrap this up into an operator
# using perl6 meta features and make a nice threading
# operator (which can be used for other, actually
# useful, tasks). The operator works like this:
#
#       my @items   = (1,5,2,6,9);
#       my $channel = Channel.new;
#       my $atatime = 5;
#
#       @items[$atatime]~>:code({
#           my $sleep_time = (1..@items.elems).pick;
#           sleep $sleep_time;
#           $channel.send($_) };
#       })
#
# What this operator does is: for each element in @items, create
# a tread and execute following block of code. In addition,
# throttle the threading by not spawning more than $atatime threads
# at a time.
# And the block of code is passed as a closure with a ref to
# the channel.

sub postcircumfix:<[ ]~\>>(@worklist, $atatime, :$code) {
    my @tasks;
    for @worklist -> $item {
        @tasks.push(start { $code($item) });
        if (@tasks == $atatime) {
            await Promise.anyof(@tasks);  # <- wait untill at least one slot gets free
            @tasks .= grep({ !$_ });      # <- filter for unfinished
        }
    }
    await Promise.allof(@tasks);
}

# MAIN:
my @a = (23, 14, 1);
my $MAX_SLEEP_TIME = @a.elems;
my $atatime = 2;

my $sorted = [<=] @a;

while (! $sorted ) {

    my $channel = Channel.new;

    @a[$atatime]~>:code({

        my $sleep_time = (1..$MAX_SLEEP_TIME).pick;
        sleep $sleep_time;
        $channel.send($_);

    });

    $channel.close;
    @a = @$channel;
    say "Got: [" ~ @a.join(",") ~ "]";
    
    $sorted = [<=] @a;
        
}
say "[" ~ @a.join(",") ~ "]" ~ " - Finally sorted!";
