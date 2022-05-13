package machine.external;

import sys.thread.Thread;

class Timer {
    public static function create(intRequire:() -> Void, intervalSec:Float = 0.5) {
        return () -> {
            while (true) {
                Sys.sleep(intervalSec);
                intRequire();

                if (Thread.readMessage(false) != null) {
                    return;
                }
            }
        }
    }
}
