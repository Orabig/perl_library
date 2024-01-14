

# Compute the array of distances between nodes
# with Floyd–Warshall algorithm
# Input is the NEXT graph defined as : { 0 -> [1,2], 1->[0,3], ...} (0 is connected to 1 and 2, ...)
# Returns DIST matrix : DIST->[0]->[3]=DIST->[3]->[0]=2
# Algorithm complexity : N^3
sub buildDistanceMap {
    my ($NEXT) = @_;
    my $N = scalar keys %$NEXT; # Number of IDs
    my $DIST = [];
    for (1..$N) {
        my @a = (9999) x $N;
        push @$DIST, \@a;
    }
    my @edges = keys %$NEXT;
    foreach (@edges) {
        $DIST->[$_]->[$_]=0;
        my $neibs = $NEXT->{$_};
        foreach my $neib (@$neibs) {
            $DIST->[$_]->[$neib]=$DIST->[$neib]->[$_]=1;
        }
    }
    # print_elapsed(); Above initialisation takes less than 2ms
    foreach my $k (@edges) {
        foreach my $i (@edges) {
            foreach my $j (@edges) {
                next if $i > $j; # Only valid if graph is not oriented
                my $sum = $DIST->[$i]->[$k] + $DIST->[$k]->[$j];
                if ($DIST->[$i]->[$j] > $sum) {
                    $DIST->[$i]->[$j] = $DIST->[$j]->[$i] = $sum;
                }
                
            }
        }
    }
    return $DIST;
}





# Compute the array of distances between nodes (Incremental version)
# with Floyd–Warshall algorithm
# Input :
#   EDGES : list of SORTED indices of the graph (integers)
#   NEXT : graph defined as : { 0 -> [1,2], 1->[0,3], ...} (0 is connected to 1 and 2, ...)
# Returns DIST matrix : DIST->[0]->[3]=DIST->[3]->[0]=2
# This function can be called several time, and will stop in the
# middle of the computation is the timeout is exceeded.
# Second Parameter is a state reference
#  stateRef -> undefined : never called
#  stateRef -> (int) : function called at least once. Init of DIST is done
#  stateRef -> 0.666 : computation of DIST is done
# Typical usage :
#  my $state; # distanceComputationState
#  my @EDGES = sort { $a <=> $b } keys %$NEXT;
#  my $DISTANCE = [];
#  my $timeout = 1.000; # seconds
#  for (some loop) {
#      (...)
#      print "Done" if incrementalBuildDistanceMap(\@EDGES,$NEXT,$DISTANCE, \$state, $timeout);
#  }
sub incrementalBuildDistanceMap {
    my ($EDGES,$NEXT,$DIST,$stateRef,$timeout) = @_;
    return if defined $$stateRef and $$stateRef == 0.666;
    use Time::HiRes qw(time);
    my $LIMIT = time() + $timeout;
    unless (defined $$stateRef) {
        my $N = scalar keys %$NEXT; # Number of IDs
        for (1..$N) {
            my @a = (999999) x $N;
            push @$DIST, \@a;
        }
        foreach (@$EDGES) {
            $DIST->[$_]->[$_]=0;
            my $neibs = $NEXT->{$_};
            foreach my $neib (@$neibs) {
                $DIST->[$_]->[$neib]=$DIST->[$neib]->[$_]=1;
            }
        }
    }
    # print_elapsed(); Above initialisation takes less than 2ms
    $$stateRef = $$EDGES[0]-1 unless defined $$stateRef;
    foreach my $k (@$EDGES) {
        next if $k <= $$stateRef;
        return 0 if time() > $LIMIT; # Timeout
        foreach my $i (@$EDGES) {
            foreach my $j (@$EDGES) {
                next if $i > $j; # Only valid if graph is not oriented
                my $sum = $DIST->[$i]->[$k] + $DIST->[$k]->[$j];
                if ($DIST->[$i]->[$j] > $sum) {
                    $DIST->[$i]->[$j] = $DIST->[$j]->[$i] = $sum;
                }
            }
        }
        $$stateRef = $k;
    }
    $$stateRef = 0.666;
    return 1;
}
