# Returns the master datapack path (.../.minecraft/datapacks)
export def dpath []: nothing -> string { 'C:/Users/globb/AppData/Roaming/.minecraft/datapacks' }

# Syncs all worlds' datapacks with their './datapacks/dpsync.six'
export def sync [
    --fresh (-F),
    --only (-o): list<string>,
    --except (-e): list<string>,
    --this (-t)
]: nothing -> nothing {
    let only = if $this { [(pwd | path basename)] } else { $only };
    glob /Users/globb/AppData/Roaming/.minecraft/saves/*/datapacks/dpsync.txt -D |
    par-each {|world|
        print $"(ansi yb)[($world | path dirname -n 2 | path basename)](ansi reset)"
        cd ($world | path dirname) 
        let syncpacks = open 'dpsync.txt' | lines
        $syncpacks |
        par-each {|packname|
            let sat_only: bool = ($only == null) or ($only | where {$in == $packname} | is-not-empty)
            let sat_except: bool = ($except == null) or ($except | where {$in == $packname} | is-empty)
            if not ($sat_only and $sat_except) {
                return
            }
            let is_tester = $packname | str starts-with "#";
            let packname = if ($is_tester) {$packname | str substring 1..} else {$packname};
            let dp_path = dpath | path join $packname;
            print $"(ansi g)> (ansi wb)($packname)(ansi reset)"
            # get current branch:
            let branch = do { 
                if ($dp_path | path exists) and ($dp_path | path join '.git' | path exists) {
                    cd $dp_path
                    ^git branch --show-current
                } else {
                    "main"
                }
            }
            if $fresh and ($packname | path type) == dir {
                rm -rfp $packname
            }
            if ($packname | path type) == dir {
                cd $packname
                # if already on correct branch:
                if $branch == (^git branch --show-current) {
                    ^git reset --hard
                    ^git pull
                } else {
                    ^git fetch --all
                    ^git switch -C $branch --track $"origin/($branch)"
                    ^git pull
                    # delete all other branches:
                    ^git branch | lines |
                    each { str substring 2.. | str trim } |
                    where { $in != $branch } |
                    each { ^git branch -D $in }
                }
            } else {
                if ($is_tester) {
                    ^git clone $dp_path -l --no-hardlinks
                } else {
                    ^gh repo clone $"sixslimemc/($packname)" -- -b $branch
                }
            }
        }
        # remove datapacks not in dpsync.txt file:
        glob ./*/pack.mcmeta -D | each { path dirname | path basename } |
        where { ($in | path join ".git" | path type) == dir} |
        par-each {|worldpack|
            if ($syncpacks | all {($in != $worldpack) and ($in != $"#($worldpack)")}) {
                print $"(ansi r)X (ansi wb)($worldpack)(ansi reset)"
                rm -rfp $worldpack
            }
        }
    }
    
    return
}

export def go [
    message?: string,
    --all(-a)
    ]: nothing -> nothing {
    use gg.nu
    let action = {
        do -i {gg all ($message | default "DP GO!")}
        do -i {^git push}
    }
    if $all {
        ls (dpath) -f | where type == dir | get name | par-each {cd $in; do $action}
        sync
    } else {
        do $action
        sync -o [(pwd | path basename)]
    }
}

export def "cd master" --env [pack?: string]: nothing -> nothing {
    cd (dpath)
    if ($pack != null) and ($pack | path exists) {
        cd $pack
    } else {
        ls | get name
    }
}

export def "world" [
    index?: int,
    --all (-a),
    --list (-l),
    --sync-file (-s),

] nothing -> nothing or nothing -> list<string> {
    let worlds: list<string> = ls C:/Users/globb/AppData/Roaming/.minecraft/saves |
    where type == dir |
    get name |
    where {$all or ($in | path join "datapacks/dpsync.txt" | path type) == file}
    if $list {
        return $worlds | each {$in | path basename}
    }
    let sync_path: string = if $index != null {
        $worlds | get $index
    } else {
        $worlds | get ($worlds | each {$in | path basename} | input list -if)
    } |
    path join "datapacks/dpsync.txt"
    if not ($sync_path | path exists) {
        touch $sync_path
    }
    if $sync_file {
        ^code $sync_path
    } else {
        ^code ($sync_path | path dirname)
    }
}

export def create [
    name: string,
    --private (-p),
    --test (-t),
] nothing -> nothing {
    cd (dpath)
    let dir_path = $name;
    ^gh repo clone sixslimemc/_datapack_template $dir_path
    cd $dir_path
    nu ./make.nu $name
    rm -rfp .git
    rm -fp ./make.nu
    print $"> Created local datapack ($name) in directory ($dir_path)"
    ^git init
    ^git add -A
    ^git commit -m "init"
    if $test { return }
    ^gh repo create $"sixslimemc/($name)" (if $private {"--private"} else {"--public"}) --source=. --remote=origin --push --description="(WIP)"
    print $"> Created repository sixslimemc/($name)."
}

export def deprecate [version: int]: nothing -> nothing {
    use gg.nu
    gg all
    ^git push
    let remote_url: string = ^git remote get-url
    if not ($remote_url | str starts-with "https://github.com/") {
        print "Git remote is not a github repo"
        return
    }
    let repo: table = $remote_url | parse "https://github.com/{user}/{name}.git"
    ^gh repo rename $"($repo.name)__legacy($version)"
}
