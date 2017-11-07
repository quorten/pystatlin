#!/bin/python3
import argparse
import sys
parser = argparse.ArgumentParser(
    prog='pysh',
    description='Python shell interpreter')
parser.add_argument(
    '-c',
    dest='commands',
    nargs=1,
    help='execute the commands given on the command line')
args = parser.parse_args()
if args.commands is not None:
    exec(args.commands[0])
else:
    exec(sys.stdin.read())
