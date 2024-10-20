# Makes it easy to toggle between $EDITOR and the terminal/shell
function __ctrl-z.fish -d "Keybind function for ctrl+z.fish. Not meant to be called directly"

    if not builtin jobs --quiet
        set -l reset (set_color normal)
        set -l color_command (set_color $fish_color_command)
        # https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#cursor-controls
        printf "\x1b[0G" # Move cursor to the start of the line (0'th column).
        printf "\x1b[2K" # Clear the current line, to erase the leftover (partial) prompt.
        printf "%shint%s: this keybind only does something, if there are >= 1 background %sjobs%s ;)\n" \
            (set_color cyan) $reset \
            $color_command $reset

        return 1
    end

    # TODO: What if there is more that one job? Pick the latest, or use fzf to pick?
    # builtin jobs | read job group cpu state command
    set -l n_jobs_before (builtin jobs | count)

    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    set -l job_id 1
    if test $n_jobs_before -gt 1; and command -q gum
        set -l job_id_color $magenta
        set -l cwd_color $yellow
        set -l cpu_color $cyan
        set -l command_color (set_color $fish_color_command)
        set -l pgid_color (set_color white)
        set -l etime_color $blue
        # --border-label="$(set_color --dim)┤$reset $(set_color blue)ctrl-z.fish$reset $(set_color --dim)├$reset" \
        set -l fzf_opts --ansi --height=~40% \
            --header="$job_id_color<id>$reset | $pgid_color<pgid>$reset $cpu_color<cpu>$reset $green<sta$(set_color normal)$(set_color red)te>$reset $etime_color<etime>$reset $cwd_color<cwd>$reset | $command_color<command>$reset" \
            --border-label=" $(set_color blue)ctrl-z.fish$reset " \
            --cycle \
            --no-info \
            --color=label:italic \
            --prompt="select which job to bring into the foreground > " \
            --bind="ctrl-z:close"

        # TODO: bind ctrl+c to send kill -p to the process
        # --bind="ctrl-c:execute-silent(kill -p {1})+refresh-preview"

        builtin jobs \
            | tail +1 \
            | while read job pgid cpu state command
            set -l state_color $red
            if test $state = running
                set state_color $green
            end

            set -l cwd (path resolve /proc/$pgid/cwd | string replace --regex "^$HOME/" "~/")
            set -l etime (command ps --pid $pgid --format etime= | string trim)

            printf '%s%2s%s   | %s%s%s  %s%s%s   %s%s%s  %s%s%s  %s%s%s | %s%s\n' \
                $job_id_color $job $reset \
                $pgid_color $pgid $reset \
                $cpu_color $cpu $reset \
                $state_color $state $reset \
                $etime_color $etime $reset \
                $cwd_color $cwd $reset \
                (printf (echo $command | fish_indent --ansi)) $reset

        end | fzf $fzf_opts | string match --regex --groups-only '^\s*(\d+)' | read job_id
        if test $pipestatus[-3] -eq 130 # see `man fzf` for status codes
            # User pressed esc or ctrl-z
            return
        end
    end

    fg %$job_id 2>/dev/null

    set -l n_jobs_after (builtin jobs | count)
    if test $n_jobs_before -eq $n_jobs_after
        # Only emit if sending job back to background, and not exiting the program
        emit ctrl_z_to_bg $command
    end

    commandline --function repaint
end

# function __ctrl+z.fish::listener::hint_putting_in_foreground --on-event ctrl_z_to_bg -a command
#     set -l reset (set_color normal)
#     set -l blue (set_color blue)

#     printf "\n%s><>%s press %sctrl+z%s to put the top background job (%s%s) in the foreground.\n" \
#         $blue $reset \
#         $blue $reset \
#         (printf (printf $command | fish_indent --ansi)) $reset
# end

# function __ctrl+z.fish::listener::cargo_check --on-event ctrl_z_to_bg -a command
#     test -f Cargo.toml; or return 0
#     cargo check
# end

# function __ctrl+z.fish::listener::git_status --on-event ctrl_z_to_bg -a command
#     # fg is a blocking call
#     # When it returns, it would be nice to show some contextial information
#     if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
#         command git status
#     end

#     # if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
#     #     set --query __ctrl_z_prev_git_status_modified
#     #     or set -g __ctrl_z_prev_git_status_modified (command git ls-files --modified)
#     #     set -l __ctrl_z_git_status_modified (command git ls-files --modified)
#     #     # Check if the two arrays are equal
#     #     set -l equal 1
#     #     # If the two arrays do not have the same length, then they are not equal
#     #     test (count $__ctrl_z_prev_git_status_modified) -ne (count $__ctrl_z_git_status_modified); and set equal 0
#     #     # If they have the same length, then check if they have the same elements
#     #     if test $equal -eq 1
#     #         for i in (seq (count $__ctrl_z_prev_git_status_modified))
#     #             if test $__ctrl_z_prev_git_status_modified[$i] != $__ctrl_z_git_status_modified[$i]
#     #                 set equal 0
#     #                 break
#     #             end
#     #         endthe
#     #     end

#     #     if test $equal -eq 0
#     #         command git status
#     #         set -g __ctrl_z_prev_git_status_modified $__ctrl_z_git_status_modified
#     #     end
#     # else
#     #     ls
#     # end
# end
if test $fish_key_bindings = fish_vi_key_bindings
    bind --mode insert \cz '__ctrl-z.fish; commandline --function repaint'
else
    bind \cz '__ctrl-z.fish; commandline --function repaint'
end
# bind \cz '__ctrl-z.fish'
