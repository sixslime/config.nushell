# Returns the master datapack path (.../.minecraft/datapacks)
export def dpath []: nothing -> string { 'C:/Users/globb/AppData/Roaming/.minecraft/datapacks' }

# Syncs all worlds' datapacks with their './datapacks/dpsync.six'
export def sync []: nothing -> nothing {
    glob /Users/globb/AppData/Roaming/.minecraft/saves/*/datapacks/dpsync.txt -D |
    par-each {|world|
        print $"(ansi yb)[($world | path dirname -n 2 | path basename)](ansi reset)"
        cd ($world | path dirname) 
        let syncpacks = open 'dpsync.txt' | lines
        $syncpacks |
        par-each {|packname|
            print $"(ansi g)> (ansi wb)($packname)(ansi reset)"
            # get current branch:
            let branch = do { 
                let thisdp = dpath | path join $packname
                if ($thisdp | path exists) and ($thisdp | path join '.git' | path exists) {
                    cd $thisdp
                    ^git branch --show-current
                } else {
                    "main"
                }
            }
            if ($packname | path exists) and (($packname | path type) == dir) {
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
                ^gh repo clone $"sixslimemc/($packname)" -- -b $branch
            }
        }
        # remove datapacks not in dpsync.txt file:
        glob ./*/pack.mcmeta -D | each { path dirname | path basename } |
        where { ($in | path join ".git" | path type) == dir} |
        par-each {|worldpack|
            if ($syncpacks | all {$in != $worldpack}) {
                print $"(ansi r)X (ansi wb)($worldpack)(ansi reset)"
                rm -rfp $worldpack
            }
        }
    }
    
    return
}

export def go []: nothing -> nothing {
    use gg.nu
    sync
    gg all
}

export def "cd master" --env [pack?: string]: nothing -> nothing {
    cd (dpath)
    if ($pack != null) and ($pack | path exists) {
        cd $pack
    } else {
        ls | get name
    }
}
export def "cd world" --env [world?: string]: nothing -> nothing {
    cd C:/Users/globb/AppData/Roaming/.minecraft/saves
    if ($world != null) and ($world | path exists) {
        cd $"($world)/datapacks"
    } else {
        ls | get name
    }
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