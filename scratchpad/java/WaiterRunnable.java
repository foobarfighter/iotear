public class WaiterRunnable implements Runnable {
  private boolean shouldKill;

  public WaiterRunnable() {
    shouldKill = false;
  }

  public void run() {
    synchronized (this) {
      try {
        while (!shouldKill) {
          System.out.println("about to wait");
          wait();
          System.out.println("done waiting");
        }
        System.out.println("killed");        
      } catch (InterruptedException
        e) {
        System.out.println(e);
      }
    }
  }

  public synchronized void kill() {
    shouldKill = true;
    notify();
  }
}