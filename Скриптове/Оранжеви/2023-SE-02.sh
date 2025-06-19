#!/bin/bash

# Проверка за поне 2 аргумента
if (( $# < 2 )); then
    echo "Usage: $0 <duration_seconds> <command> [args...]"
    exit 1
fi

# Първи аргумент трябва да е число (брой секунди)
duration=$1
echo "$duration" | grep -Eq '^[0-9]+$'
if [[ $? -ne 0 ]]; then
    echo "The first argument must be an integer (duration in seconds)."
    exit 2
fi

# Изваждаме първия аргумент и взимаме останалото като команда
shift
command=$1
shift
args=("$@")

# Стартираме измерването
start_time=$(date +%s.%N)
end_time=$(echo "$start_time + $duration" | bc)

count=0
total_runtime=0

while :; do
    current_time=$(date +%s.%N)
    # Проверка дали имаме време за още едно изпълнение
    if (( $(echo "$current_time >= $end_time" | bc -l) )); then
        break
    fi

    # Измерване времето за изпълнение на командата
    run_start=$(date +%s.%N)
    "$command" "${args[@]}"
    run_end=$(date +%s.%N)

    # Изчисляваме времето за текущото изпълнение
    runtime=$(echo "$run_end - $run_start" | bc)
    total_runtime=$(echo "$total_runtime + $runtime" | bc)
    ((count++))
done

# Окончателно време (в случай че командата продължи след крайното време)
final_time=$(date +%s.%N)
total_duration=$(echo "$final_time - $start_time" | bc)

# Изчисляване на средното време (ако count > 0)
if (( count > 0 )); then
    avg_runtime=$(echo "scale=2; $total_runtime / $count" | bc)
else
    avg_runtime=0
fi

# Извеждане на резултата
printf "Ran the command '%s %s' %d times for %.2f seconds.\n" "$command" "${args[*]}" "$count" "$total_duration"
printf "Average runtime: %.2f seconds.\n" "$avg_runtime"
