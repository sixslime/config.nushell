export def all [
    desc: string = '-',
    --push (-p),
    --recursive (-r),
]: {
    if $recursive {
        ^git submodule foreach --recursive $"nu -c 'do -i {^git add -A; ^git commit -am \"('[submodule] ' + $desc)\"}; if ($push) {^git push}'";
    }
    do -i {
        ^git add -A;
        ^git commit -am $desc;
    }
    if $push {
        ^git push
    }
}

export def chmod [
    file: string,
    mod: string = "+x",
]: {
    ^git update-index --add --chmod=($mod) $file;
}