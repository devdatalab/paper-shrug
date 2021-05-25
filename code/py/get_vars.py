# write a list of variable names to a text file
import sys
import re

arglist = ' '.join(sys.argv[1:])

from optparse import OptionParser

def parse_options():
    
    # create option parser
    parser = OptionParser()
    
    # require a variable list
    parser.add_option('-v', '--varlist', dest='varlist',
                      help='list of vars to write/expand', metavar='pc11_pca_tot_p ec13_s[1-70]')
    
    # require an output file
    parser.add_option('-o', '--output_path', dest='output_path',
                      help='name of output file for expanded varlist', metavar='/scratch/pn/outfile.txt')

    # parse command line
    (options, args) = parser.parse_args()
    
    # crash if no input path specified
    if not options.output_path or not options.varlist:
        parser.print_help()
        sys.exit(1)

    return options

options = parse_options()

# open the output file for writing
with open(options.output_path, 'w') as f:
        
    # loop over the variable list
    vars = str.split(options.varlist)
    for var in vars:
    
        # if this var needs expanding
        if '[' in var:
    
            # get the components of the variable expansion
            m = re.match("(.*)\[([0-9]+)-([0-9]+)\](.*)", var)
            prefix = m.group(1)
            start_num = m.group(2)
            end_num = m.group(3)
            suffix = m.group(4)

            # loop over the range and write the different pieces into the output file
            for i in range(int(start_num), int(end_num) + 1):
                print(prefix + str(i) + suffix, file=f)
    
        # otherwise, just write it to the output file
        else:
            print(var, file=f)
