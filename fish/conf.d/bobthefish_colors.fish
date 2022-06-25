function bobthefish_colors -S -d 'Define a custom bobthefish color scheme'
    # Colors taken from vim-material-monokai
    set red        e73c50
    set orange     fd9720
    set yellow     e6db74
    set green      a6e22e
    set lightgrey  575b61
    set purple     ae81ff
    set blue       82B1FF
    set black      263238

    __bobthefish_colors default

    set -x color_k8s_testing     $orange  $black
    set -x color_k8s_production  red      white   --italic

    set -x color_repo        $green   $black
    set -x color_repo_dirty  $red     white
    set -x color_repo_staged $orange  $black

    set -x color_path                   $lightgrey  white
    set -x color_path_basename          $lightgrey  white  --bold
    set -x color_path_nowrite           $red        white
    set -x color_path_nowrite_basename  $red        white  --bold

    set -x color_vi_mode_insert   $green   $black  --bold
    set -x color_vi_mode_default  $purple  $black  --bold
    set -x color_vi_mode_visual   $orange  $black  --bold

    set -x color_initial_segment_exit  white  $red    --bold
    set -x color_initial_segment_su    white  $green  --bold
    set -x color_initial_segment_jobs  white  $blue   --bold
end
