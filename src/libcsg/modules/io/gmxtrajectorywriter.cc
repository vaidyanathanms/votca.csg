/* 
 * Copyright 2009-2011 The VOTCA Development Team (http://www.votca.org)
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


#include <string>
#include "gmxtrajectorywriter.h"

namespace votca { namespace csg {

void GMXTrajectoryWriter::Open(string file, bool bAppend)
{
#if GMX != 50
    set_program_name("VOTCA");
#endif

    //char c[1] = bAppend ? "a" : "w";
    _file = open_trx((char *)file.c_str(), "w");
}

void GMXTrajectoryWriter::Close()
{
    close_trx(_file);
}

void GMXTrajectoryWriter::Write(Topology *conf)
{
    static int step=0;   
    int N = conf->BeadCount();
    t_trxframe frame;
    rvec *x = new rvec[N];
    matrix box = conf->getBox();
    
    frame.natoms = N;
    frame.bTime = true;
    frame.time = conf->getTime();
    frame.bStep = true;
    frame.step = conf->getStep();;
    frame.x = x;
    frame.bTitle=false;
    frame.bLambda=false;
    frame.bAtoms=false;
    frame.bPrec=false;
    frame.bX = true;
    frame.bV=false;
    frame.bF=false;
    frame.bBox=true;

    for(int i=0; i<3; i++)
        for(int j=0; j<3; j++)
            frame.box[i][j] = box[i][j];
    
    
for(int i=0; i<N; ++i) {
        vec v = conf->getBead(i)->getPos();
        x[i][0] = v.getX();
        x[i][1] = v.getY();
        x[i][2] = v.getZ(); 
    }
        
#if GMX == 50
    write_trxframe(_file, &frame, NULL);
#elif GMX == 45
    write_trxframe(_file, &frame, NULL);
#elif GMX == 40
    write_trxframe(_file, &frame);
#else
#error Unsupported GMX version
#endif
    
    step++;
    delete[] x;
}

}}
