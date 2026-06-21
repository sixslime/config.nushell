export def all [
    desc: string = '-',
    --push (-p),
]: {
    ^git add -A;
    ^git commit -am $desc;
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