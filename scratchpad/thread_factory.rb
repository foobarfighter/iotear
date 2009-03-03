require 'thread'

class ThreadFactory
  @@mutex = Mutex.new
  @@computation_map = {}

  def self.computation_map
    @@computation_map
  end

  def self.create_file_writer_thread(name, options)
    Thread.new do
      Thread.stop
      file = "/tmp/blah.txt"

      File.delete(file) if File.exists?(file)
      File.open file, "w" do |f|
        while Time.now.to_i < options[:run_until] do
          f << '.' * options[:buffer_size]
        end
      end
    end
  end

  def self.create_computation_thread(name, options)
    Thread.new(name, options[:run_seconds], @@computation_map) do |n, run_seconds, map|
      Thread.current[:name] = n
      Thread.stop
     
      run_until = Time.now.to_f + run_seconds.to_f

      i = 0
      while Time.now.to_f < run_until
        i += 1
      end
      @@mutex.synchronize do
        map[Thread.current[:name]] = i
      end
    end
  end

  def self.create_thread_name(type)
    @@thread_map ||= {}
    @@thread_map[type] ||= 0
    @@thread_map[type] += 1

    "#{type}#{@@thread_map[type]}"
  end

  def self.create(type_sym, args)
    thread_name = create_thread_name(type_sym)
    thread = self.send("create_#{type_sym}_thread", thread_name, args)
    sleep 0.1
    puts "Spawning #{type_sym.to_s} thread (#{thread_name})"
    thread
  end
end