#!/usr/bin/env python3

# Copyright (c) 2022 Augusto Fraga Giachero
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the “Software”), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#!/usr/bin/env python3

import sys
import argparse

argp = argparse.ArgumentParser(description="Calculate parameters for Silabs Si57x oscilator or the output frequency from the parameters provided.")
argp.add_argument("--fxtal", type=float, help="Internal crystal frequency in hertz [defaut = 114.285e6]", default=114.285e6)

group_calc_fout = argp.add_argument_group(title="Calculate FOUT from registers")
group_calc_fout.add_argument("--rfreq", type=str, help="Raw RFREQ register value in hexadecimal")
group_calc_fout.add_argument("--hsdiv", type=str, help="Raw HSDIV register value in hexadecimal")
group_calc_fout.add_argument("--n1", type=str, help="Raw N1 register value in hexadecimal")

group_calc_params = argp.add_argument_group(title="Calculate registers from FOUT")
group_calc_params.add_argument("--fout", type=float, help="Output frequency in hertz")

args = argp.parse_args()

def si570_calc_fout(rfreq, hsdiv, n1, fxtal):
    if (n1 > 1 and (n1 % 2) == 1):
        n1 = n1 + 1
    return (fxtal * rfreq * 2**-28) / (hsdiv * n1)

def si570_calc_divs(fout, fxtal):
    hsdivs = [11, 9, 7, 6, 5, 4]
    freq_err_best = 1e9
    rfreq_best = None
    hsdiv_best = None
    n1_best = None
    for hsdiv in hsdivs:
        n1_divs = [1]
        n1_divs.extend(range(2, 129, 2))
        for n1 in n1_divs:
            rfreq = int((fout * hsdiv * n1 * 2**28) / fxtal)
            fdco = (rfreq * fxtal) * 2**-28
            if(fdco < 4.85e9 or fdco > 5.67e9):
                continue
            else:
                freq_err_now = abs(fout - (fdco / (hsdiv * n1)))
                if (freq_err_now < freq_err_best):
                    rfreq_best = rfreq
                    hsdiv_best = hsdiv
                    n1_best = n1
    return (rfreq_best, hsdiv_best, n1_best)

if args.fout == None:
    if args.rfreq == None or args.hsdiv == None or args.n1 == None:
        print("Invalid arguments: if --fout is not specified, --rfreq, --hsdiv and --n1 should be specified", file=sys.stderr)
        exit(1)
    else:
        rfreq = int(args.rfreq, 16)
        hsdiv = int(args.hsdiv, 16)
        n1 = int(args.n1, 16)
        fout = si570_calc_fout(rfreq, hsdiv + 4, n1, args.fxtal)
        print("FOUT = {} Hz".format(fout))
else:
    if args.rfreq != None or args.hsdiv != None or args.n1 != None:
        print("Invalid arguments: if --fout is specified, --rfreq, --hsdiv and --n1 can not be used", file=sys.stderr)
        exit(1)
    else:
        rfreq, hsdiv, n1 = si570_calc_divs(args.fout, args.fxtal)
        if rfreq == None or hsdiv == None or n1 == None:
            print("FOUT out of range!", file=sys.stderr)
            exit(2)
        else:
            print("RFREQ = 0x{:010x}".format(rfreq))
            print("HSDIV = 0x{:01x}".format(hsdiv - 4))
            print("N1 = 0x{:02x}".format(n1))
