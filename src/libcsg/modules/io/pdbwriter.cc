// 
// File:   pdbwriter.cc
// Author: ruehle
//
// Created on April 19, 2007, 3:22 PM
//

#include <stdio.h>
#include <string>
#include "pdbwriter.h"

using namespace std;

void PDBWriter::Open(string file, bool bAppend)
{
    _out = fopen(file.c_str(), bAppend ? "at" : "wt");
}

void PDBWriter::Close()
{
    fclose(_out);
}

void PDBWriter::Write(Topology *conf)
{
    Topology *top = conf;
    fprintf(_out, "MODEL     %4d\n", conf->getStep());
    for(BeadContainer::iterator iter=conf->Beads().begin();
    iter!=conf->Beads().end(); ++iter) {
        Bead *bi = *iter;
        vec r = bi->getPos();
        fprintf(_out,
                "ATOM  %5d %4s %3s %1s%4d    %8.3f%8.3f%8.3f%6.2f%6.2f\n",
                (bi->getId()+1)%100000,   // atom serial number
                bi->getName().c_str(),  // atom name
                top->getResidue(bi->getResnr())->getName().c_str(), // residue name
                " ", // chain identifier 1 char
                bi->getResnr()+1, // residue sequence number
                10.*r.x(), 10.*r.y(), 10.*r.z(),
                bi->getQ(), bi->getM());  // is this correct??
          
        if(bi->getSymmetry()>=2) {
           vec ru = 0.1*bi->getU() + r;
       
            fprintf(_out,
                "HETATM%5d %4s %3s %1s%4d    %8.3f%8.3f%8.4f%6.2f%6.2f\n",
                bi->getId()+1,   // atom serial number
                bi->getName().c_str(),  // atom name
                "REU", // residue name
                " ", // chain identifier 1 char
                bi->getResnr()+1, // residue sequence number
                10.*ru.x(), 10.*ru.y(), 10.*ru.z(),
                0., 0.);  // is this correct??
        }
        if(bi->getSymmetry()>=3) {
           vec rv = 0.1*bi->getV() + r;
            fprintf(_out,
                "HETATM%5d %4s %3s %1s%4d    %8.3f%8.3f%8.4f%6.2f%6.2f\n",
                bi->getId()+1,   // atom serial number
                bi->getName().c_str(),  // atom name
                "REV", // residue name
                " ", // chain identifier 1 char
                bi->getResnr()+1, // residue sequence number
                10.*rv.x(), 10.*rv.y(), 10.*rv.z(),
                0.,0.);  // is this correct??  /**/
        }
   }
    fprintf(_out, "ENDMDL\n");
    fflush(_out);
}
