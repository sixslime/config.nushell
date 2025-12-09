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
