class KillWaitingThread {
  public KillWaitingThread() {
  }

  public static void main(String[] argv) {
    Object monitor = new Object();

    WaiterRunnable runner = new WaiterRunnable();
    Thread thread = new Thread(runner);
    thread.start();

    try {
      Thread.sleep(1000);
      System.out.println(thread.getState());
      synchronized (runner) {
        runner.notify();
        runner.kill();
      }
      thread.join();
    } catch (InterruptedException e) {
      System.out.println(e);
    }
  }
}