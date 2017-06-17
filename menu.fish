function menu -S 
    if test -z "$argv"
        return 1
    end

    function __menu_move_print -a row col
        set -e argv[1..2]
        printf "\x1b[$row;$col""f$argv"
    end

    function __menu_fullscreen
        switch "$argv"
            case --enter
                tput smcup
                stty -echo

            case --leave
                tput rmcup
                stty echo
        end
    end

    function __menu_draw_items -S -a row_index
        set -e argv[1]
        set -l before ""

        for i in (seq $item_count)
            set -l index_shortcut ""

            if test $show_index = true
              set index_shortcut ""(set_color --dim brblack)"[$i] "(set_color normal)""
            end

            if test "$multiple" = true
                if contains -- "$i" $menu_selected_index
                    set before "$checked_glyph "
                else
                    set before "$unchecked_glyph "
                end
            end

            if test "$i" = "$row_index"
                set -l glyph "$cursor_glyph"
                set -l item "$hover_item_style$argv[$i]$normal"

                __menu_move_print $i 1 "$glyph $index_shortcut$before$item"
            else
                set -l item "$argv[$i]"

                if contains -- "$i" $menu_selected_index
                    set item "$selected_item_style$argv[$i]$normal"
                end

                __menu_move_print $i 1 "  $index_shortcut$before$item"
            end
        end
    end

    set -l cursor_glyph ">"

    set -l checked_glyph "[x]"
    set -l unchecked_glyph "[ ]"

    set -l hover_item_style
    set -l selected_item_style
    set -l index_navigation true
    set -l show_index false

    set -l multiple "$menu_multiple_choice"
    set -l normal

    if test ! -z "$multiple" -a "$multiple" != false
        set multiple true
    end

    if test ! -z "$menu_cursor_glyph"
        set cursor_glyph "$menu_cursor_glyph"
    end

    if test ! -z "$menu_index_navigation"
      set index_navigation $menu_index_navigation
    end

    if test ! -z "$menu_show_index"
      set show_index $menu_show_index
    end

    if test ! -z "$menu_hover_item_style"
        set hover_item_style (set_color $menu_hover_item_style)
        set normal (set_color normal)
    end

    if test ! -z "$menu_selected_item_style"
        set selected_item_style (set_color $menu_selected_item_style)
        set normal (set_color normal)
    end

    if test ! -z "$menu_checked_glyph"
        set checked_glyph "$menu_checked_glyph"
    end

    if test ! -z "$menu_unchecked_glyph"
        set unchecked_glyph "$menu_unchecked_glyph"
    end

    set -l row_index 1

    if test ! -z "$menu_selected_index"
        set row_index "$menu_selected_index[-1]"
    end

    set menu_selected_index

    set -l item_count (count $argv)
    set -l row_number_regex '['(seq $item_count | string join '')']'

    tput civis
    stty -icanon -echo

    __menu_fullscreen --enter

    __menu_draw_items "$row_index" $argv

    function  __menu_end_session
      if test -z "$menu_selected_index"
          set menu_selected_index "$row_index"
      end

      __menu_fullscreen --leave
    end

    while true
        dd bs=1 count=1 ^ /dev/null | read -p "" -l c
      
        switch "$c"
            case "q"
              __menu_fullscreen --leave
              break

            case " "
                if test "$multiple" = true
                    if contains $row_index $menu_selected_index
                        set -e menu_selected_index[(contains --index "$row_index" $menu_selected_index)]
                    else
                        set menu_selected_index $menu_selected_index "$row_index"
                    end
                end

            case ""
                __menu_end_session
                break

            case "["
                dd bs=1 count=1 ^ /dev/null | read -p "" -l c

                switch "$c"
                    case A
                        set row_index (echo $row_index - 1 | bc)

                        if test "$row_index" -le 0
                            set row_index 1
                        end

                    case B
                        set row_index (echo $row_index + 1 | bc)

                        if test "$row_index" -ge "$item_count"
                            set row_index $item_count
                        end
                end
        end

        if test $index_navigation = true
          if string match -r $row_number_regex "$c" -q
            set row_index "$c"
          end
        end

        __menu_draw_items $row_index $argv
    end

    functions -e __menu_move_print __menu_fullscreen __menu_draw_items

    tput cvvis
end
