#!/bin/sh

fifo="/tmp/panel-fifo"

# Creates a new fifo every time the script gets run
[ -e "$fifo" ] && rm "$fifo"
mkfifo "$fifo"

[ -z "$(pgrep -f 'bspc subscribe report')"] && bspc subscribe report >> "$fifo" &

# Modules
xtitle -s -t 128 -f'%T%s\n' >> "$fifo" &
xclock -s -d 1000 -f'%C' >> "$fifo" &
xip >> "$fifo" &
#$HOME/.scripts/get-volume.sh >> "$fifo" &

COLOR_DEFAULT=#f7f6dc
COLOR_FOCUSED=$COLOR_DEFAULT
COLOR_ACTIVE=$COLOR_DEFAULT
COLOR_WARNING=#ff0000
COLOR_INACTIVE=#42403c
COLOR_DEFAULT_BACKGROUND=#000000
COLOR_FOCUSED_BACKGROUND=$COLOR_INACTIVE
COLOR_WARNING_BACKGROUND=$COLOR_DEFAULT

#FONT="roboto-8:bold"
#FONT="basiercircle-10:medium"
#FONT2="inconsolata-10:bold"
FONT="mononoki-8"
P="%{O20}"

# WMHDMI-1:oI:oII:OIII:oIV:fV:fVI:fVII:fVIII:fIX:fX:LT:TT:G

PANEL_GEOMETRY=$(xrandr --current | grep -w "connected primary" | cut -d ' ' -f 4 | sed -E 's/x[^\+]*/x42/')

while true
do
    if read line; then
        case $line in
            %T*)
                title="%{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND}${line#'%T'}"
                ;;
            %C*)
                clock="%{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND}${line#'%C'}"
                ;;
            %IPV4*)
                ipv4="%{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND}${line#'%IPV4'}"
                ;;
            %IPV6*)
                ipv6="%{F$COLOR_WARNING}%{B$COLOR_WARNING_BACKGROUND}${line#'%IPV6'}"
                ;;
            %VOLUME*)
                volume="%{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND}${line#'%VOLUME'}"
                ;;
            W*)
                wm=""
                IFS=':' read -ra WM <<< "${line#'WM'}"
                #wm="${wm}%{F${FG}}%{B${BG}}%{A:bspc monitor -f ${name}:} ${name} %{A}%{B-}%{F-}"
                for x in "${WM[@]}"; do
                    case $x in
                        M*|m*) # Active
                            wm=" ${x:1} $wm %{F$COLOR_ACTIVE}%{B$COLOR_DEFAULT_BACKGROUND}"
                            ;;
                        # m*) # Inactive
                        #     wm="$wm %{F$COLOR_INACTIVE}%{B$COLOR_DEFAULT_BACKGROUND} %{A:bspc monitor -f ${x:1}:}${x:1}%{A}"
#                            ;;
                        O*|F*) # Focused and free focused
                            wm="$wm %{F$COLOR_FOCUSED}%{B$COLOR_FOCUSED_BACKGROUND} ${x:1}"
                            ;;
                        o*) # Active
                            wm="$wm %{F$COLOR_ACTIVE}%{B$COLOR_DEFAULT_BACKGROUND} ${x:1}"
                            ;;
                        f*) # Inactive
                            wm="$wm %{F$COLOR_INACTIVE}%{B$COLOR_DEFAULT_BACKGROUND} %{A:bspc desktop -f ${x:1}:}${x:1}%{A}"
                            ;;
                        U*|u*) # Urgent focused and unfocused
                            wm="$wm %{F$COLOR_WARNING}%{B$COLOR_WARNING_BACKGROUND} ${x:1}"
                            ;;
                        T*) # Node state
                            wm="$wm %{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND} ${x:1}"
                            ;;
                        L*) # Node state
                            wm="$wm %{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND} ${x:1}"
                            ;;
                        G*) # Node state
                            wm="$wm %{F$COLOR_DEFAULT}%{B$COLOR_DEFAULT_BACKGROUND} ${x:1}"
                            ;;
                    esac
                done
        esac
        echo "%{T1}%{l}$P$wm %{c}$title%{r}%{T2}$volume$ipv6$ipv4$P$clock$P"
    fi
done < "$fifo" | lemonbar -p -b -g $PANEL_GEOMETRY -f $FONT -o 0 -a 32

echo "---END---"

# Only use the exit triggers when there are not more bars left.
# Lets overlapping bars still work after a other one was closed.

# TODO removed this because panel was not shutting down
#if [[ -z "$(pidof lemonbar)" ]]; then
    pkill -f xtitle
    pkill -f xclock
    pkill -f xip

     # TODO check if the 'bspc subscribe' must be unsubscribed to
    bspc config bottom_padding 0
#fi
