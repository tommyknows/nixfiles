if test (count $argv) -ne 1
    echo "Usage: update-gh-token <token>"
    return 1
end
security add-generic-password -a "$USER" -s "GitHub Token" -U -w $argv[1]
set -Ux GITHUB_TOKEN (security find-generic-password -a "$USER" -s "GitHub Token" -w)
