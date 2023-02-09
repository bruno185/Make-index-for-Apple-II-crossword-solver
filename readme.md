# Index for Apple II Croosword Solver
This a Dephi program producing index files for Apple II Croosword Solver
You can fin my Apple II Croosword Solver program here : 
https://github.com/bruno185/Apple-II-crossword-solver

## Use
Launch program.

Clic first button to generate a WORDS file (16 chars for each word).

Clic second button to create indexes. It can take some minutes. The progam might seem crashed, but it is not. Just wait.

Then copy file to a ProDOS disk image (32 Mb) with CiderPress or AppleCommander. 

*.ind file don't need to be copied to the ProDOS disk image. You can delete them. They may be used in a future version. 

Important  : Index files end with Px (x being de number from 1 to 4). You must create 4 directories on ProDOS disk image (P1 to P4) and copy the corresponding files. See disk image in Apple-II-crossword-solver disk image repository as example.

## Technics
I use Delphi Community Edition, latest version.
*.ind are uncompressed version of other files.
Commpression is run lngth encoding.

This is an example of today's technology at the service of the technology of 40 years ago (that of the Apple II)