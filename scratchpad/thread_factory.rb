require 'thread'

class ThreadFactory
  @@computation_mutex = Mutex.new
  @@computation_map = {}

  def self.computation_map
    @@computation_map
  end

  # This is a thread safe operation that is gauranteed to only return when the child thread is
  # waiting and ready to rock.
  def self.create_computation_thread(mutex, cv, options)
    main_mutex = Mutex.new
    main_cv = ConditionVariable.new

    thread = nil
    main_mutex.synchronize {
      thread = Thread.new(options[:run_seconds], @@computation_map) do |run_seconds, map|
        mutex.synchronize {
          main_mutex.synchronize {
            main_cv.signal
          }
          cv.wait(mutex)
          # Report in order how the threads were executed
          puts "Running #{Thread.current[:name]}..."
        }

        run_until = Time.now.to_f + run_seconds.to_f

        i = 0
        while Time.now.to_f < run_until
          i += 1
        end

        @@computation_mutex.synchronize {
          map[Thread.current[:name]] = i
        }
      end
      main_cv.wait(main_mutex)
    }
    thread
  end

  def self.create_thread_name(type)
    @@thread_map ||= {}
    @@thread_map[type] ||= 0
    @@thread_map[type] += 1

    "#{type}#{@@thread_map[type]}"
  end

  def self.create(type_sym, mutex, cv, args)
    thread_name = create_thread_name(type_sym)
    thread = self.send("create_#{type_sym}_thread", mutex, cv, args)
    thread[:name] = thread_name
    puts "Created #{type_sym.to_s} thread (#{thread_name})"
    thread
  end
end