package machine.external;

import sys.thread.Lock;
import sys.thread.Thread;

class Timer {
    public static function create(intQueue:Array<Int>, lock:Lock, intervalSec:Float = 0.5, vector:Int = 4) {
        return () -> {
            while (true) {
                Sys.sleep(intervalSec);
                lock.wait();
                intQueue.push(vector);
                lock.release();

                if (Thread.readMessage(false) != null) {
                    return;
                }
            }
        }
    }
}
