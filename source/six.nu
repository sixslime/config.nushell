export alias 6conf = cd $"($nu.config-path | path dirname)/source"
export def 6help [term: string] { help --find $term | select name category usage }
