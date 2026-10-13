
export def w [--push (-p), ...message: string]: nothing -> oneof<record<branch: string, s_hash: string, message: string, changes: list<string>>, nothing> {
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
        s_hash: $shortHash,
        message: $message,
        changes: $changes,
    }
    | if $push {
        let upstream = ^git rev-parse --abbrev-ref --symbolic-full-name @{u};
        print -e $"Pushing to '($upstream)'...";
        let completion = ^git push | complete;
        let status = if ($completion.exit_code == 0) { true } else { $completion };
        $in | insert push {
            remote: $upstream,
            status: $status,
        }
    } else { $in }
}

export alias wp = w -p
