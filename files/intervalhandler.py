#!/command/with-contenv /usr/bin/python3
import psutil
import os
import time
import re
import random
import signal


def get_process_id(process_name: str) -> int:
    for process in psutil.process_iter():
        if process.name() == process_name:
            return process.pid
    return -1


def parse_intervals(intervals: list) -> list:
    new_intervals = []
    for interval in intervals:
        res = re.findall(r"(^\d+)([smhd])$", interval)
        if not res:
            print("[Intervalhandler error]: Invalid interval format: " + interval)
            exit(1)
        else:
            interval = int(res[0][0])
            if res[0][1] == "m":
                interval = interval * 60
            elif res[0][1] == "h":
                interval = interval * 3600
            elif res[0][1] == "d":
                interval = interval * 86400
            if interval < 300:
                interval = 300
            new_intervals.append(interval)
    if len(new_intervals) > 1 and new_intervals[0] >= new_intervals[1]:
        print(
            "[Intervalhandler error]: Invalid interval range: start interval is greater than or equal to end interval! Exiting."
        )
        exit(1)
    return new_intervals


def signal_handler(sig, frame):
    exit(0)


def main():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGQUIT, signal_handler)
    process_id = get_process_id("hide.me")
    while process_id == -1:
        time.sleep(5)
        process_id = get_process_id("hide.me")
    interval = os.getenv("HIDEME_INTERVAL")
    if interval:
        interval = interval.strip()
        random.seed()
        if "-" in interval:
            intervals = [inval.strip() for inval in interval.split("-")]
            if len(intervals) > 2:
                print(
                    "[Intervalhandler error]: Invalid interval format: too many dashes! Exiting."
                )
                exit(1)
            intervals = parse_intervals(intervals)
        else:
            intervals = parse_intervals([interval])
        if len(intervals) == 1:
            interval = intervals[0]
            while True:
                time.sleep(interval)
                process_id = get_process_id("hide.me")
                if process_id != -1:
                    os.kill(process_id, signal.SIGUSR1)
                else:
                    print("[Intervalhandler error]: No hide.me process found, exiting.")
                    exit(1)
        else:
            while True:
                sleeptime = random.randint(intervals[0], intervals[1])
                time.sleep(sleeptime)
                process_id = get_process_id("hide.me")
                if process_id != -1:
                    os.kill(process_id, signal.SIGUSR1)
                else:
                    print("[Intervalhandler error]: No hide.me process found, exiting.")
                    exit(1)
    else:
        print("[Intervalhandler]: Interval not set, nothing to do...")
        exit(0)


if __name__ == "__main__":
    main()
