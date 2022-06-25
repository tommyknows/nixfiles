set -l workdir "~/Documents/work"

if ! set -q $argv[1]
    cd $workdir
end

set repo $argv[1]
set dir $workdir/$repo
if [ ! -d $dir ] 
    if ! s $repo
        return
    end
else 
    cd $dir
end

set branch $argv[2]
if [ -z $branch ] 
    set branch (default_branch)
end

c $branch $argv[3]
