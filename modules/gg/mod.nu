
export def w [--push (-p), ...message: string]: nothing -> oneof<record<branch: string, hash: string, message: string, diff: list<string>, summary: string>, nothing> {
    ^git add -A;
    let branch = ^git branch --no-color --show-current;
    let diff = getDiff '--staged' 'HEAD';
    if ($diff | is-empty) {
        print -e $"No changes to commit. \(($branch))";
        return null;
    };
    let message = if not ($message | is-empty) {
        $message | str join ' '
    } else {
        '-'
    };
    print -e $"Committing to ($branch)...";
    ^git commit -qam $message;
    let shortHash = ^git rev-parse --short HEAD;
    {
        branch: $branch,
        hash: $shortHash,
        message: $message,
        diff: $diff.changes,
        summary: $diff.summary,
    }
    | if $push {
        insert push (doPush)
    } else { $in }
}

def getDiff [from: string, to: string]: nothing -> oneof<nothing, record<changes: list<string>, summary: string>> {
    let diffOut = ^git diff $from $to --stat --no-color | lines;
    if ($diffOut | is-empty) { null } else {
        {
            changes: ($diffOut | slice ..(-2)),
            summary: ($diffOut | last),
        }
    }
}

def doPush []: nothing -> oneof<record, record<remote: string, diff: list<string>, summary: string>> {
    let branch = ^git branch --no-color --show-current;
    let upstream = ^git rev-parse --abbrev-ref --symbolic-full-name @{u};
    let diffCode = ^git diff $branch $upstream --quiet | complete | get exit_code;
    if $diffCode == 0 {
        print -e $"No differences to push. \(($branch) == ($upstream))";
        return null;
    };
    let diff = getDiff $branch $upstream;
    print -e $"Pushing ($branch) to ($upstream)...";
    let completion = ^git push | complete;
    if ($completion.exit_code == 0) {
        print -e "Push success.";
        {
            remote: $upstream,
            diff: $diff.changes,
            summary: $diff.summary,
        }
    } else {
        print -e "Push failed.";
        $completion
    }
}
export def wp [...message: string] {
    w -p ...$message | default {
        doPush;
    }
}
