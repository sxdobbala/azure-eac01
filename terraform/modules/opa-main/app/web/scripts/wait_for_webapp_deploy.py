#!/usr/bin/env python3
import argparse
import re
import time
from itertools import islice


def follow(file, wait_seconds, timeout):
    # https://stackoverflow.com/questions/12523044/how-can-i-tail-a-log-file-in-python/54263201#54263201
    # Edit: Reading multiple lines at once and adding longer wait time in between reads
    """ Yield each line from a file as they are written. """
    line = ''
    timeout_over = time.time() + timeout

    while True:
        lines = file.readlines()
        if lines is not None:
            for tmp_line in lines:
                line += tmp_line
                if line.endswith("\n"):
                    yield line
                    line = ''

        if time.time() > timeout_over:
            raise Exception('Timed out')
        else:
            time.sleep(wait_seconds)


def wait_for_webapp_deploy(webapp_name, log_file, poll, timeout):
    """ Wait for webapp deployment completion message in logs """
    p = re.compile(
        f'^.+Deployment of web application archive .+{webapp_name}.war] has finished.+$')

    with open(log_file, 'r') as file:
        file.seek(0, 2)  # Seek end of file

        for line in follow(file, poll, timeout):
            m = p.match(line)
            if m:
                print('Match found: ', m.group())
                break


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Wait for webapp deployment completion message in logs")
    parser.add_argument(
        "--webapp_name", help="Name of the webapp being deployed", required="true")
    parser.add_argument(
        "--log_file", help="Path of the tomcat log file", required="true")
    parser.add_argument(
        "--poll", type=int, help="Number of seconds to wait before looking for new log entries", required="true")
    parser.add_argument(
        "--timeout", type=int, help="Maximum number of seconds to wait for deployment completion message", required="true")
    args = parser.parse_args()
    wait_for_webapp_deploy(
        args.webapp_name, args.log_file, args.poll, args.timeout)
