
export def in [directories: glob, action: closure] {
    glob $directories -F -d 1 | par-each {cd $in; do $action}
}

export def ncd --env [index: int] nothing -> nothing {
    let target = ls | get name | get $index
    cd $target
}

export alias h = cd
export alias i = ls