import argparse
import errno
import glob
import os
import multiprocessing as mp
import subprocess
import shutil
import sys

import numpy as np
import netCDF4

from jug import TaskGenerator


def max_merge(n, m):
    """Returns a new array with values max(n, m), from arrays n and
    m of same shapes

    Args:
        n (np.array): input array
        m (np.array): comparison array

    Returns:
        np.array: max(n, m)
    """
    assert n.shape == m.shape
    assert len(n.shape) == 1
    return np.max((n, m), axis=0)


@TaskGenerator
def extract_max_streamflow(year, output_dir=None, drop_archives=False):
    result = None
    print("Extracting max streamflow from [{}]...".format(year))
    try:
        output_filepath = os.path.join(output_dir if output_dir is not None else str(year),
                                       "{}_max_streamflow.npy".format(year))
        filepaths = glob.glob(os.path.join(str(year), "*CHRTOUT*.comp"))  # select the right files

        try:
            subprocess.run(["datalad", "get", "{}/".format(year)], check=True)
        except Exception as exception:
            print("Failed to get content of [{}], retrying: ({}) {}".format(
                      year, type(exception), exception), file=sys.stderr)
            subprocess.run(["datalad", "get", "{}/".format(year)], check=True)

        # start by loading a first file
        n = np.array(netCDF4.Dataset(filepaths[0], "r").variables["streamflow"])
        # iterate over files (and print a nice tqdm progress bar)
        for filepath in filepaths[1:]:
            # load a new array
            m = np.array(netCDF4.Dataset(filepath, "r").variables["streamflow"])
            # `n` always holds the max value for each of the 2.7M rows across the files
            # seen so far
            n = max_merge(n, m)

        if drop_archives:
            subprocess.run(["datalad", "drop", "--nocheck", "{}/".format(year)], check=True)

        # save results. For instance if year = 2017
        # then it saves `n` in 2017/2019_max_streamflow.npy
        np.save(output_filepath, n)
        result = year
        print("Extracted max streamflow from [{}] to [{}]".format(year, output_filepath))
    except Exception as exception:
        print("Failed to extract max streamflow from [{}] to [{}]: ({}) {}".format(
                  year, output_filepath, type(exception), exception), file=sys.stderr)

    return result


parser = argparse.ArgumentParser()
parser.add_argument("--output", default=None)
parser.add_argument("--drop-after", default=False, action="store_true")
parser.add_argument("--start", default=0, type=int)
parser.add_argument("--end", default=0, type=int)

args = parser.parse_args()

# Get directories lists
years = [1993, 1994, 1995, 1996, 1997, 1998, 1999,
         2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
         2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018]

if args.end == 0:
    args.end = len(years)

years = years[args.start:args.end]

tasks = []

for year in years:
    task = extract_max_streamflow(year, args.output, args.drop_after)
    if task.can_load():
        task.load()
        if task.result is None and task.lock():
            task.invalidate()
            print("Invalidated task [{}]".format(year))
            task.unlock()
    tasks.append(task)
