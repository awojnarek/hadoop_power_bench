#!/usr/bin/env ruby

# You can use this script to help benchmark Hadoop on IBM Power. 
# You may want to modify some of the variables below, to fit your
# needs as well as your hadoop environment.
#
# You can use the activate_smt function to test and baseline run-
# -ning your workload on different SMT settings.

#############
# Varibales #
#############

Architecture = %x[uname -i].strip
Date         = %x[date +"%m/%d/%y %H:%M:%S"].strip
Output_File  = "#{Date}_run.csv"
Hadoop_Dir   = "/root/hadoop-2.7.3"
Save_Dir     = "#{Hadoop_Dir}/save"

#############
# Functions #
#############
def activate_smt(smt)
  begin

    %x[ppc64_cpu --smt=#{smt}]

  rescue => msg 
    printf "error in activate_smt => #{msg}\n"
    exit 1
  end
end

def benchmark_teracopy(*smt)
  begin

    results = Hash.new { |h,k| h[k] = {} }
    %x[rm -r #{Hadoop_Dir}/out 2>/dev/null] 
    %x[rm -r /tmp/hadoop-root/* 2>/dev/null]
    result = %x[JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el time #{Hadoop_Dir}/bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar terasort tests/100m out 2>&1]

    # Write our results to file
    open("#{Save_Dir}/debug_smt_off.out", 'a') { |f|
      f.puts "#{result}\n"
    }

    results_array = result.split("\n")
    elapsed = results_array.grep(/elapsed/).grep(/system/).join(" ").split(" ").grep(/elapsed/).join(" ").gsub("elapsed","")
    seconds = 0

    if elapsed =~ /:/
      if elapsed.split(":").count == 2
        seconds = elapsed.split(":").last.to_i
        minutes = elapsed.split(":").first.to_i
        seconds = seconds + (minutes * 60)
      end
    end

    smt = smt.join("")

    return "#{Date},#{seconds},#{smt}"

  rescue => msg
    printf "Error in benchmark_teracopy => #{msg}\n"
    exit 1
  end
end

########
# Main #
########

if Architecture == "ppc64le"

  # Run tests for Power Linux"
  printf "*Running benchmarks for Power Linux*\n"
  
  result = benchmark_teracopy("off")

  # Write our results to file
  open("#{Save_Dir}/smtoff.csv", 'a') { |f|
    f.puts "#{result}"
  }
 
end 
