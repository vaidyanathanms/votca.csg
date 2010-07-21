/* 
 * Copyright 2009 The VOTCA Development Team (http://www.votca.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include <iostream>
#include "pdbtopologyreader.h"

namespace gmx {
#ifndef GMX4DEV
   extern "C" {
#endif
        #include <statutil.h>
        #include <typedefs.h>
        #include <smalloc.h>
        #include <confio.h>
        #include <vec.h>
        #include <copyrite.h>
        #include <statutil.h>
        #include <tpxio.h>
#ifndef GMX4DEV
    }
#endif
    // this one is needed because of bool is defined in one of the headers included by gmx
    #undef bool
}

#define snew2(ptr,nelem) (ptr)=(gmx::rvec*)gmx::save_calloc(#ptr,__FILE__,__LINE__,\
                        (nelem),sizeof(*(ptr)))


namespace votca { namespace csg {

bool PDBTopologyReader::ReadTopology(string file, Topology &top)
{
    char title[512];
    gmx::rvec *x, *v;
    gmx::matrix box;
    int ePBC;
    gmx::t_atoms atoms;
    
    //snew(atoms,1);
    gmx::get_stx_coordnum((char*)file.c_str(),&(atoms.nr));
    init_t_atoms(&atoms,atoms.nr,TRUE);
    snew2(x,atoms.nr);
    snew2(v,atoms.nr);
    fprintf(stderr,"\nReading structure file\n");

    gmx::read_stx_conf((char*)file.c_str(), title,&atoms,
                          x,NULL,&ePBC,box);
    Residue *res = top.CreateResidue("no");
    // read the atoms
    for(int i=0; i < atoms.nr; i++) {
        gmx::t_atom *a;
        a = &(atoms.atom[i]);
        BeadType *type = top.GetOrCreateBeadType("no");
        top.CreateBead(1, *(atoms.atomname[i]), type, res->getId(), a->m, a->q);  
        //cout << *(gtp.atoms.atomname[i]) << " residue: " << a->resnr << endl;
    }
   
    return true;
}

}}