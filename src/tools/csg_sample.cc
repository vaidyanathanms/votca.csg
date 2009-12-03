// 
// File:   csample.cc
// Author: victor
//
// Created on 27. Dezember 2007, 23:04
//

#include <grotopologyreader.h>
#include <gmxtrajectoryreader.h>
#include <trajectorywriter.h>
#include <configuration.h>
#include <matrix.h>

/**
 *  This program does the conformation sampling
 */
int main(int argc, char** argv)
{
    GROTopologyReader topread;
    Topology top;
    Topology top_new;
    topread.ReadTopology("ppy.gro", top);
    cout << "I have " << top.BeadCount() << " beads, " << top.ResidueCount() 
         << " residues in " << top.MoleculeCount() << " molecules" << endl;
    top_new.Add(&top);
    top_new.Add(&top);

    Configuration conf(&top);
    Configuration conf_new(&top_new);
    conf.Initialize();
    conf_new.Initialize();
    GMXTrajectoryReader trajread;
    trajread.Open("ppy.gro");
    trajread.FirstFrame(conf);
    vec c=vec(0,0,0);
    for(int i=0; i<top.BeadCount(); i++) {
        c+=conf.getPos(i);
    }
    c=c/(double)top.BeadCount();
    for(int i=0; i<top.BeadCount(); i++) {
        conf.setPos(i, conf.getPos(i)-c);
    }
    TrajectoryWriter::RegisterWriterPlugins();
    TrajectoryWriter *writer = TrjWriterFactory().get("xtc");
    writer->Open("out.xtc");
    matrix M1, M2;
    for(double r=2; r>0.2; r-=0.1) {
    for(int n=0; n<1000; n++) {
        M1.RandomRotation();
        M2.RandomRotation();
        for(int i=0; i<top.BeadCount(); i++) {
            conf_new.setPos(i, M1*conf.getPos(i));
            conf_new.setPos(i+top.BeadCount(), M2*conf.getPos(i)+vec(r,0,0));        
        //conf.getPos(i);
        }
        writer->Write(&conf_new);
        writer->Close();
    }
    }
    cout << "done\n";
    return 0;
}

