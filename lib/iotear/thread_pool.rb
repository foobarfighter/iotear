require 'thread'

class ThreadPool
  attr_reader :threads, :mutex, :cv

  DEFAULT_THREAD_PREFIX = "threadpool"
  DEFAULT_BLOCK_ON_EXHAUST = false

  # Safely creates a thread pool of *thread_count* threads.
  #
  #   * options[:thread_prefix] = Optionally passed to create a cutom thread name prefix.  Passed as Thread.current[:name]
  #     If no thread_prefix then DEFAULT_THREAD_PREFIX is used.
  #   * options[:block_on_exhaust] = Optionally passed to tell the ThreadPool to create a new thread if all other threads
  #     are busy.  If true, then no more threads are created.  If false, then a new thread is spawned to handle the task.
  #     By default, this is set to DEFAULT_BLOCK_ON_EXHAUST.

  def initialize(thread_count, options = {})
    @threads ||= []
    @thread_data ||= {}

    main_mutex = Mutex.new
    main_cv = ConditionVariable.new

    @mutex = Mutex.new
    @cv = ConditionVariable.new

    # Serially wait for each thread to spawn
    main_mutex.synchronize do

      (1..thread_count).each do |i|
        @threads << Thread.new do
          # Lock owner for spawned thread to wait on
          @mutex.synchronize do
            # Wait until main thread has released it's lock before spawning
            main_mutex.synchronize do
              # Initialize data that will be available to main thread
              Thread.current[:name] = (options[:thread_prefix] || DEFAULT_THREAD_PREFIX) + i.to_s
              # Signal main thread that it's ok spawn
              main_cv.signal
            end
            # Put spawned thread into waiting state
            @cv.wait(@mutex)
          end

          Thread.current[:task]
          Thread.current[:args]
        end
        # Ensures that main thread won't run until it receives a signal that it's ok
        main_cv.wait(main_mutex)
      end

      # There is a race condition that can exist when the last thread spawned may not
      # be waiting by the time the main thread gets here.  Is there a better way to do this?
      until @threads[@threads.size-1].status == "sleep"
        sleep 0.010
      end
    end
  end

  def process(*args, &block)
#    mutex.synchronize do
#
#      Thread.current[:task] = block
#      Thread.current[:args] = args
#    end

    yield unless block.nil?
  end

  private
  def find_next_ready_thread
    
  end
end
