export def all [desc: string = '-']: {
    git add -A;
    git commit -am $desc;
}
