
export def w [--push (-p), ...message: string]: nothing -> record<branch: string, s_hash: string, message: string, changes: list<string>, pushed: bool> {
    ^git add -A;
    let changes = ^git status --short | lines;
    let message = if ($message | is-empty) {
        $message | str join ' '
    } else {
        '-'
    };
    let branch = ^git branch --no-color --show-current;
    ^git commit -qam $message;
    let shortHash = ^git rev-parse HEAD;
    if $push {
        ^git push;
    };
    {
        branch: $branch,
        s_hash: $shortHash,
        message: $message,
        changes: $changes,
        pushed: $push,
    }
}
