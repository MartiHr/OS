# gpt special
#!/bin/bash

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 [options] -jar jarfile [args]"
    exit 1
fi

java_opts=""
d_props=""
jar_seen=0
jar_file=""
main_args=""
after_jar_file=0

for arg in "$@"; do
    if [[ $jar_seen -eq 0 ]]; then
        if [[ "$arg" == "-jar" ]]; then
            jar_seen=1
            java_opts="$java_opts -jar"
        elif [[ "$arg" == -D* ]]; then
            # -D преди -jar — част от java_opts
            java_opts="$java_opts $arg"
        else
            # друга опция — пак java_opts
            java_opts="$java_opts $arg"
        fi
    elif [[ $jar_seen -eq 1 && $after_jar_file -eq 0 ]]; then
        # това е jar файлът
        jar_file="$arg"
        after_jar_file=1
    else
        # вече сме след jar файла
        if [[ "$arg" == -D* ]]; then
            # -D опции след jar — трябва да се преместят преди jar
            d_props="$d_props $arg"
        else
            # истински аргументи за програмата
            main_args="$main_args $arg"
        fi
    fi
done

# стартираме java по правилния начин
exec java $java_opts $d_props "$jar_file" $main_args
