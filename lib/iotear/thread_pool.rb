require 'thread'

class ThreadPool
  attr_reader :threads, :thread_prefix, :waiters, :main_mutex, :main_cv

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
    process_options(options)

    @threads ||= []
    @waiters ||= []

    @main_mutex = Mutex.new
    @main_cv = ConditionVariable.new

    spawn_waiters(thread_count)
  end

  def process(*args, &block)
    waiter = nil
    if block_on_exhaust?
      while waiter.nil? do
        waiter = next_waiter
        Thread.pass
      end
    else
      waiter = next_waiter
      if waiter.nil?
        spawn_waiters(1, false)
        waiter = next_waiter
      end
    end

    waiter[:task] = block
    waiter[:task_args] = args

    waiter.run
    waiter
  end

  def join_all(timeout = nil)
    processors = nil
    main_mutex.synchronize do
      processors = threads - waiters
      processors.each do |thread|
        thread[:stop] = true
      end
      waiters.each do |thread|
        thread[:stop] = true
      end
    end
    (1..waiters.size).each do |i|
      process { true }
    end
    threads.each { |thread| thread.join(timeout) }    
  end

  def kill_all!
    @threads.each { |thread| Thread.kill(thread) }
    @threads = nil
    @waiters = nil
  end

  def waiting?
    main_mutex.synchronize do
      @waiters.size == 0
    end
  end

  def block_on_exhaust?
    @block_on_exhaust
  end

  protected

  def next_waiter
    main_mutex.synchronize do
      waiter = waiters.pop
    end
  end

  def spawn_waiters(thread_count = 1, run_forever = true)
    main_mutex.synchronize do
      (1..thread_count).each do |i|
        @threads << Thread.new do
          # Wait until main thread has released it's lock before spawning
          main_mutex.synchronize do
            # Initialize data that will be available to main thread
            Thread.current[:name] = (thread_prefix || DEFAULT_THREAD_PREFIX) + i.to_s
            # Signal main thread that it's ok spawn
            main_cv.signal
          end

          begin
            Thread.stop
            # TODO: Investigate a little more as to why Thread.current[:task] can be nil under JRuby when killing/joining
            Thread.current[:task].call(Thread.current[:task_args]) unless Thread.current[:task].nil?
            main_mutex.synchronize do
              run_forever = false if Thread.current[:stop] == true
              @waiters << Thread.current if run_forever
            end
          end while run_forever
        end

        # Ensures that main thread won't run until it receives a signal that it's ok
        main_cv.wait(main_mutex)
        @waiters << @threads.last
      end

      # There is a race condition that can exist when the last thread spawned may not
      # be waiting by the time the main thread gets here.  Is there a better way to do this?
      until @threads[@threads.size-1].status == "sleep"
        Thread.pass
      end
    end

    @waiters
  end

  private

  def process_options(options)
    @block_on_exhaust = options[:block_on_exhaust] || DEFAULT_BLOCK_ON_EXHAUST
    @thread_prefix = options[:thread_prefix] || DEFAULT_THREAD_PREFIX
  end

end
