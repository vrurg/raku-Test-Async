use v6;
use Test;

for ^3 -> $i {
    throws-like {
        die "oki";
    }, X::AdHoc, "tested $i";
}
