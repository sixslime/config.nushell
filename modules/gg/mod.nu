
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

def doPush []: nothing -> record<remote: string, status: oneof<bool, record>> {
    let branch = ^git branch --no-color --show-current;
    let upstream = ^git rev-parse --abbrev-ref --symbolic-full-name @{u};
    let diffCode = ^git diff --quiet | complete | get exit_code;
    print -e $"Pushing to '($upstream)'...";
    let completion = ^git push | complete;
    let status = if ($completion.exit_code == 0) { true } else { $completion };
    {
        remote: $upstream,
        status: $status,
    }
}
export def wp [...message: string] {
    if (w -p ...$message)
}
