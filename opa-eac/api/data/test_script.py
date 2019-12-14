#!/usr/bin/env python3
import argparse

parser = argparse.ArgumentParser(description="Test python script with params")
parser.add_argument("test_param", type=str, help="Test parameter")
args = parser.parse_args()
print(args.test_param)
