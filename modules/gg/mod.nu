
export def w [--push (-p), ...message: string]: nothing -> oneof<record<changes: list<string>, message: string, branch: string,  hash: string>, nothing> {
    ^git add -A;
    let changes = ^git status --short | lines;
    let message = if not ($message | is-empty) {
        $message | str join ' '
    } else {
        '-'
    };
    let branch = ^git branch --no-color --show-current;
    if ($changes | is-empty) {
        print -e $"No changes to commit. \(($branch))";
        return null;
    };
    print -e $"Committing to ($branch)...";
    ^git commit -qam $message;
    let shortHash = ^git rev-parse --short HEAD;
    {
        branch: $branch,
        hash: $shortHash,
        message: $message,
        changes: $changes,
    }
    | if $push {
        insert push (doPush)
    } else { $in }
}

def doPush []: nothing -> oneof<record, record<remote: string, diff: list<string>, summary: string>> {
    let branch = ^git branch --no-color --show-current;
    let upstream = ^git rev-parse --abbrev-ref --symbolic-full-name @{u};
    let diffCode = ^git diff $branch $upstream --quiet | complete | get exit_code;
    if $diffCode == 0 {
        print -e $"No differences to push. \(($branch) == ($upstream))";
        return null;
    };
    let diff = ^git diff $branch $upstream --stat --no-color | lines | do {
        {
            changes: ($in | slice ..(-2)),
            summary: ($in | last),
        }
    };
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
