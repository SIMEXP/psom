#!/usr/bin/env python
"""
This script starts a niak agent
"""
__author__ = 'poquirion'



import argparse
import os
import re
import sys
import subprocess

class Worker():
    def __init__(self, directory, worker_id):

        # only three types of worker
        if worker_id == 'manager':
            self.cmd = ['/bin/bash', '{0}/logs/tmp/psom_manager.sh'.format(directory, worker_id)]
            self.std_err = '{0}/logs/PIPE.err'.format(directory, worker_id)
            self.std_out = '{0}/logs/PIPE.out'.format(directory, worker_id)
            touch = ['PIPE.failed', 'PIPE.exit', 'PIPE.out']
            self.touch = ["{0}/logs/{1}".format(directory, t) for t in touch]
        elif worker_id == 'garbage':
            self.cmd = ['/bin/bash', '{0}/logs/tmp/psom_garbage.sh'.format(directory)]
            self.std_err = '{0}/logs/garbage/garbage.err'.format(directory)
            self.std_out = '{0}/logs/garbage/garbage.out'.format(directory)
            touch = ['garbage.failed', 'garbage.exit', 'garbage.out']
            self.touch = ["{0}/logs/garbage/{1}".format(directory, t) for t in touch]
        else:
            self.cmd =['/bin/bash', '{0}/logs/tmp/psom{1}.sh'.format(directory, worker_id)]
            self.std_err = '{0}/logs/worker/psom{1}/worker.err'.format(directory, worker_id)
            self.std_out = '{0}/logs/worker/psom{1}/worker.out'.format(directory, worker_id)
            touch = ['worker.failed', 'worker.exit', 'worker.out']
            self.touch = ["{0}/logs/worker/psom{1}/{2}".format(directory, worker_id, t) for t in touch]

    def start(self):

        #Start agent
        with open(self.std_out, 'w') as fout:
            with open(self.std_out, 'w') as ferr:
                print('execution {0}'.format(self.cmd))
                p = subprocess.Popen(self.cmd, stdout=fout, stderr=ferr)
                ret_code = p.wait()
                fout.flush()
                ferr.flush()

        # Let know manager that there was a problem
        if ret_code:
            print("Failure")
            for t in self.touch:
                print("touch {0}".format(t))
                os.mknod(t)


def main(args=None):

    if args is None:
        args = sys.argv[1:]

    parser = argparse.ArgumentParser(description='Start a PSOM worker')

    parser.add_argument("--directory", "-d", type=str, required=True, help='The PSOM output directory')

    # parser.add_argument("--input_dir", "-i", type=str, required=False, help='The PSOM input directory')

    parser.add_argument("--worker_id", "-w", type=str, required=True, help='The PSOM given worker id')

    parsed = parser.parse_args(args)

    # We force the working directory to be at the root of the output directory
    os.chdir("{0}/..".format(parsed.directory))

    w = Worker(parsed.directory, parsed.worker_id)

    w.start()


if __name__ == '__main__':
    # main(["-d", "/home/poquirion/simexp/test/result", "-w", "manager"])
    main()
