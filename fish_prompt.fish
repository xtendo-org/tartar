# tartar begins

function prompt_long_pwd --description 'Print the current working directory'
    set -l maybe_pwd (echo $PWD | sed -e "s|^$HOME|~|")
    if echo $maybe_pwd | grep -q "^~/code/"
        echo $maybe_pwd | sed -e "s|^~/code/||"
    else
        if echo $maybe_pwd | grep -q "^~/work/"
            echo $maybe_pwd | sed -e "s|^~/work/||"
        else
            echo $maybe_pwd
        end
    end
end

set -g tartar_bg NONE

function tartar_prompt_open
    echo -n (set_color -b $argv[1])(set_color $argv[2]) ''
    set tartar_bg $argv[1]
end

function tartar_prompt_transition
    # argv 1: new background color
    # argv 2: new foreground color
    echo -n '' (set_color -b $argv[1])(set_color $tartar_bg)\uE0B0(set_color $argv[2]) ''
    set tartar_bg $argv[1]
end

function tartar_prompt_close
    echo -n '' (set_color -b normal)(set_color $tartar_bg)\uE0B0(set_color normal) ''
end
function fish_prompt
    set previous $status

    if [ -z $TARTAR_HOST_BG ]; set TARTAR_HOST_BG blue; end
    if [ -z $TARTAR_HOST_FG ]; set TARTAR_HOST_FG white; end
    if [ -z $TARTAR_PATH_BG ]; set TARTAR_PATH_BG black; end
    if [ -z $TARTAR_PATH_FG ]; set TARTAR_PATH_FG white; end

    # previous command return value and hostname
    if [ $previous != 0 ]
        tartar_prompt_open red white
        echo -n $previous
        tartar_prompt_transition blue white
        echo -n (hostname)
    else
        tartar_prompt_open blue white
        echo -n (hostname)
    end

    # pyenv
    if [ $PYENV_VIRTUAL_ENV ];
        tartar_prompt_transition magenta white
        echo -n (basename $PYENV_VIRTUAL_ENV);
    end

    # path
    tartar_prompt_transition $TARTAR_PATH_BG $TARTAR_PATH_FG
    echo -n (prompt_long_pwd)

    # git
    set -l git_dir (git rev-parse --git-dir 2> /dev/null)
    if test -n "$git_dir"
        set -l branch (git branch 2> /dev/null | grep -e '\* ' | sed 's/^..\(.*\)/\1/')
        if test "$branch" = 'master' -o "$branch" = "main"
            set branch ''
        end
        set -l git_status (git status -s 2> /dev/null | grep -v "^??")
        if test -n "$git_status"
            set git_color yellow
        else
            set git_color green
        end
        set -l git_ahead (git rev-list origin/master.. 2> /dev/null | wc -l | tr -d '[:space:]')
        if git status -s 2> /dev/null | grep -q "^??"
            set git_untracked "+"
        end
        if [ "$git_ahead" != 0 ]
            set git_str " $git_ahead"
        end
        set git_stash (git stash list | wc -l)
        if [ $git_stash = 0 ]
            set git_stash
        end
        tartar_prompt_transition $git_color white
        echo -n $git_stash $branch $git_untracked $git_str
    end

    # current jobs
    set -l current_jobs (jobs | grep -v /usr/bin/fish | grep -v autojump | wc -l | tr -d '[:space:]')
    if [ "$current_jobs" != 0 ]
        tartar_prompt_transition red white
        echo -n $current_jobs
    end

    tartar_prompt_close
end
