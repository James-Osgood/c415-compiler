"""
Author: James Osgood

Call with a list of integers representing .pal files to test those files
using the pal compiler program. Appends results to the tests.log file.

Example usage:
$> python runner.py 0 1 2
# Runs the 0.pal, 1.pal, and 2.pal files.
$> python runner.py --all
# Runs all the .pal test files (not implemented yet).

"""

from argparse import ArgumentParser
from subprocess import call
from datetime import datetime

LOG_NAME = 'tests.log'
PAL_PATH = '../pal'

def _all_tests(test_list):
    print 'not implemented yet ...'

def _run_tests(test_list):
    output_msg = '----------------------\n'\
                 'DATE: %s\n'\
                 'TIME: %s\n'\
                 'TEST: %d.pal\n'\
                 '----------------------\n'
    test_path = '%d.pal'
    output_log = open(LOG_NAME, 'a+')
    
    for test_index in test_list:
        start_datetime = datetime.today()
        start_date = start_datetime.date().isoformat()
        start_time = start_datetime.time().isoformat()
        
        output_log = open(LOG_NAME, 'a+')
        output_log.write(output_msg % (start_date, start_time, test_index))
        output_log.close() # so the file is written to in the correct order
        
        output_log = open(LOG_NAME, 'a+')
        call([PAL_PATH, test_path % test_index], stdout = output_log)
        output_log.close()

def _get_cmdline_args():
    dscrp_txt = 'run *.pal test programs'
    help_name_txt = 'a name of an [0-9].pal test'
    help_all_txt = 'run all *.pal tests (default: false) (NOT YET IMPLEMENTED)'
    
    parser = ArgumentParser(description = dscrp_txt)
    parser.add_argument('test_names',
                        metavar = 'T',
                        type = int,
                        nargs = '*',
                        help = help_name_txt)
    parser.add_argument('--all',
                        dest = 'do_tests',
                        const = _all_tests,
                        default = _run_tests,
                        nargs = '?',
                        help = help_all_txt)
    
    return parser
    
if __name__ == '__main__':
    valid_indices = range(0, 10)
    test_runner = _get_cmdline_args().parse_args()
    test_indices = test_runner.test_names
    
    for test_index in test_indices:
        if test_index not in valid_indices:
            print 'Test index %d not at valid index [0-9]' % test_index
            exit()
    
    test_runner.do_tests(test_runner.test_names)