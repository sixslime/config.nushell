export alias 6conf = ^start ($nu.config-path | path dirname)
export def 6help [term: string] { help --find $term | select name category usage }