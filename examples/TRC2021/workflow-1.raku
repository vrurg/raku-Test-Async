use v6;
use Test;

my @p;
for ^3 -> $i {
    @p.push: start {
        throws-like {
            die "oki";
        }, X::AdHoc, "tested $i";
    }
}

await @p;
