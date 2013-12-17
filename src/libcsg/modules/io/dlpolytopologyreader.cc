/*
 * Copyright 2009-2013 The VOTCA Development Team (http://www.votca.org)
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
#include <iomanip>
#include <fstream>
#include <boost/regex.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/filesystem/convenience.hpp> 
#include <votca/tools/getline.h>

#ifndef HAVE_NO_CONFIG
#include <votca_config.h>
#endif

#include "dlpolytopologyreader.h"

namespace votca { namespace csg {

bool DLPOLYTopologyReader::ReadTopology(string file, Topology &top)
{
    static int  mavecs=0;
    static int  mpbct=0;
    static int  matoms=0;
    static int  natoms=0;
    static bool hasVs=false;
    static bool hasFs=false;

    BoundaryCondition::eBoxtype pbc_type=BoundaryCondition::typeAuto;

    std::ifstream fl;
    boost::filesystem::path filepath(file.c_str());
    boost::cmatch matches;

    string filename,stre,line;

    // use regular expressions for reading ambiguous directives (where more than one keyword allowed)

    stre="([\\w\\s#]+)+(\\d+)";

    boost::regex re_int;

    // re_int is set as a case-insensitive regexp
    re_int.assign(stre, boost::regex_constants::icase);

#ifdef DEBUG
    // checking if the regexp is fine - only need to do once, for debugging
    try {
      // re_int is set as a case-insensitive regexp
      re_int.assign(stre, boost::regex_constants::icase);
    }
    catch (boost::regex_error &erre) {
      throw std::runtime_error("\""+stre+"\" is not a valid regular expression: \""+erre.what()+"\"");
    }
#endif

    // TODO: fix residue naming / assignment - DL_POLY has no means to recognise residues!
    Residue *res = top.CreateResidue("no");

    if ( boost::filesystem::basename(filepath).size() == 0 ) {
      if (filepath.parent_path().string().size() == 0) {
        filename="FIELD"; // DL_POLY uses fixed file names in current/working directory
      } else {
	filename=filepath.parent_path().string() + "/FIELD";
      }
    } else {
      filename=file;
    }

    fl.open(filename.c_str());

    if (!fl.is_open()){
      throw std::runtime_error("could not open dlpoly file " + filename + " (topology)");
    } else {

      getline(fl, line); //title
      getline(fl, line); //unit line

      int nmol_types;

      getline(fl, line);     // "MOLECules or MOLECular species/types #" - may contain a few words!
      boost::to_upper(line); // allow user not to bother about the case
      if (line.substr(0,5) != "MOLEC")
          throw std::runtime_error("unexpected line in dlpoly file " + filename + ", expected 'MOLEC<ULES>' but got: " + line.substr(0,5));

      if (boost::regex_match(line.c_str(), matches, re_int)) {

#ifdef DEBUG
	// matches[0] contains the original string.  
	// matches[i] contains a sub_match object for each subexpression
	
	for (int i = 0; i < matches.size(); i++) {
	  // sub_match::first and sub_match::second are iterators that
	  // refer to the first and one past the last chars of the
	  // matching subexpression
	  string match(matches[i].first, matches[i].second);
	  cout << "\tmatches[" << i << "] = '" << match << "'" << endl;
	}
#endif

	string match1(matches[1].first, matches[1].second);
	string match2(matches[matches.size()-1].first, matches[matches.size()-1].second);

	nmol_types = atoi(match2.c_str());

	cout << "Read from FIELD: '" << match1 << "' - " << nmol_types << endl;
      }
      else {
	throw std::runtime_error("The regexp '" + stre + "' does not match '" + line + "'");
      }

      string mol_name;

      int id=0;
      for (int nmol_type=0;nmol_type<nmol_types; nmol_type++){

        getline(fl, mol_name); //molecule name might incl. spaces - so why not allow???
	//boost::erase_all(mol_name, " ");

        Molecule *mi = top.CreateMolecule(mol_name);
        fl >> line; boost::to_upper(line); // allow user not to bother about the case

        if (line.substr(0,6) != "NUMMOL")
          throw std::runtime_error("unexpected line in dlpoly file " + filename + ", expected 'NUMMOLS' but got: '" + line.substr(0,6) + "'");

	int nreplica;
	fl >> nreplica;

	cout << "Read from FIELD: '" << mol_name << "' - '" << line << "' - " << nreplica << endl;

	getline(fl, line); //rest of NUMMOLs line

	fl >> line; boost::to_upper(line);

        if (line != "ATOMS")
          throw std::runtime_error("unexpected line in dlpoly file " + filename + ", expected 'ATOMS' but got: '" + line + "'");

	fl >> natoms;

	cout << "Read from FIELD: '" << line << "' - " << natoms << endl;

	//read molecule
	int id_map[natoms];
	for (int i=0;i<natoms;){//i is altered in repeater loop
	  string beadtype;
	  fl >> beadtype;
	  BeadType *type = top.GetOrCreateBeadType(beadtype);
	  double mass;
	  fl >> mass;
	  double charge;
	  fl >> charge;

          getline(fl,line); //rest of the atom line

          Tokenizer tok(line, " \t");
	  vector<string> fields;
	  tok.ToVector(fields);

	  int repeater=1;
	  if (fields.size() > 1) repeater=boost::lexical_cast<int>(fields[0]);

	  for(int j=0;j<repeater;j++){

	    string beadname = beadtype + "#" + boost::lexical_cast<string>(i+1);
	    Bead *bead = top.CreateBead(1, beadname, type, res->getId(), mass, charge);

            stringstream nm;
            nm << bead->getResnr() + 1 << ":" <<  top.getResidue(bead->getResnr())->getName() << ":" << bead->getName();
            mi->AddBead(bead, nm.str());
	    id_map[i]=bead->getId();
	    i++;
	    //cout << "Atom identification in maps '" << nm.str() << "'" << endl;
	  }
	  matoms += repeater;
	}

	while (line != "FINISH"){
	  if ((line == "BONDS")||(line == "ANGLES")||(line == "DIHEDRALS")) {
	    string type = line;
	    int count;
	    fl >> count;
	    for (int i=0;i<count;i++){
	      fl >> line; //bond/angle/dih type not used
	      int ids[4];
              Interaction *ic;
	      fl >> ids[0]; fl>>ids[1];
	      if (type == "BONDS"){
	        ic = new IBond(id_map[ids[0]-1],id_map[ids[1]-1]); // -1 due to fortran vs c 
	      } else if (type == "ANGLES"){
		fl >> ids[2];
	        ic = new IAngle(id_map[ids[0]-1],id_map[ids[1]-1],id_map[ids[2]-1]); // -1 due to fortran vs c 
	      } else if (type == "DIHEDRALS"){
		fl >> ids[2]; fl >> ids[3];
	        ic = new IDihedral(id_map[ids[0]-1],id_map[ids[1]-1],id_map[ids[2]-1],id_map[ids[3]-1]); // -1 due to fortran vs c 
	      }
              ic->setGroup(type);
              ic->setIndex(i);
              ic->setMolecule(mi->getId());
              top.AddBondedInteraction(ic);
              mi->AddInteraction(ic);
	      getline(fl,line);
	    }
	  }
	  fl >> line; boost::to_upper(line);
	  if (fl.eof())
            throw std::runtime_error("unexpected end of dlpoly file " + filename + " while scanning for 'FINISH'");
	}

	cout << "Read from FIELD: '" << line << "' - done with '" << mol_name << "'" << endl;

	getline(fl, line); //rest of the FINISH line

	//replicate molecule
	for (int replica=1;replica<nreplica;replica++){
          Molecule *mi_replica = top.CreateMolecule(mol_name);
	  for(int i=0;i<mi->BeadCount();i++){
	    Bead *bead=mi->getBead(i);
	    BeadType *type = top.GetOrCreateBeadType(bead->Type()->getName());
	    string beadname=mi->getBeadName(i);
	    Bead *bead_replica = top.CreateBead(1, bead->getName(), type, res->getId(), bead->getM(), bead->getQ());
	    mi_replica->AddBead(bead_replica,beadname);
	  }
	  InteractionContainer ics=mi->Interactions();
          for(vector<Interaction *>::iterator ic=ics.begin(); ic!=ics.end(); ++ic) {
            Interaction *ic_replica;

	    //TODO: change if beads are not continous anymore - ???

	    int offset = mi_replica->getBead(0)->getId() - mi->getBead(0)->getId();
	    if ((*ic)->BeadCount() == 2) {
	      ic_replica = new IBond((*ic)->getBeadId(0)+offset,(*ic)->getBeadId(1)+offset);
	    } else if ((*ic)->BeadCount() == 3) {
	      ic_replica = new IAngle((*ic)->getBeadId(0)+offset,(*ic)->getBeadId(1)+offset,(*ic)->getBeadId(2)+offset);
	    } else if ((*ic)->BeadCount() == 4) {
	      ic_replica = new IDihedral((*ic)->getBeadId(0)+offset,(*ic)->getBeadId(1)+offset,(*ic)->getBeadId(2)+offset,(*ic)->getBeadId(3)+offset);
	    }
            ic_replica->setGroup((*ic)->getGroup());
            ic_replica->setIndex((*ic)->getIndex());
            ic_replica->setMolecule(mi_replica->getId());
            top.AddBondedInteraction(ic_replica);
            mi_replica->AddInteraction(ic_replica);
	  }
	}
      }
      top.RebuildExclusions();
    }

    getline(fl, line); //is "close" found?

    if(line=="close") {
      cout << "Read from FIELD: '" << line << "' - done with topology" << endl;
    }
#ifdef DEBUG
    else {
      cout << "Read from FIELD: 'EOF' - done with topology (directive 'close' not read!)" << endl;
    }
#endif

    //we don't need the rest
    fl.close();

    if ( boost::filesystem::basename(filepath).size() == 0 ) {
      if (filepath.parent_path().string().size() == 0) {
        filename="CONFIG";
      } else {
	filename=filepath.parent_path().string() + "/CONFIG";
      }
    } else {
      filename=filepath.parent_path().string()+boost::filesystem::basename(filepath)+".dlpc";
      cout << "NOTE: Explicit dlpoly FIELD (topology) filename given '" << file << "', so trying to read boundary conditions from CONFIG file named '" << filename << "'" << endl;
      //cout << "NOTE: Explicit dlpoly topology filename given, so no CONFIG will be openend and no boundary conditions will set in the topology." << endl;
      //return true;
    }

    fl.open(filename.c_str());

    if(fl.is_open()) {
      string line;

      getline(fl, line); //title
      cout << "Read from CONFIG: '" << line << "' - header" << endl;

      getline(fl, line); // 2nd header line
      cout << "Read from CONFIG: '" << line << "' - directives line" << endl;

      Tokenizer tok(line, " \t");
      vector<string> fields;
      tok.ToVector(fields);
      //tok.ConvertToVector<string>(fields);

      mavecs = boost::lexical_cast<int>(fields[0]);
      mpbct  = boost::lexical_cast<int>(fields[1]);
      natoms = boost::lexical_cast<int>(fields[2]);

      hasVs = (mavecs > 0); // 1 or 2 => in DL_POLY frame velocity vector follows coords for each atom/bead
      hasFs = (mavecs > 1); // 2      => in DL_POLY frame force vector follows velocities for each atom/bead

      top.SetHasVel(hasVs);
      top.SetHasForce(hasFs);

      if(natoms != matoms)
#ifdef DEBUG
	cout << "Number of atoms/beads in CONFIG (initial frame) & FIELD differ: " << natoms << " =?= " << matoms << endl;
#else
	throw std::runtime_error("Number of atoms/beads in CONFIG (initial frame) & FIELD differ");
#endif

      vec box_vectors[3];
      for (int i=0;i<3;i++){ // read 3 box lines
        getline(fl, line);

#ifdef DEBUG
	cout << "Read from CONFIG: '" << line << "' - box vector # " << i+1 << " (Angs)" << endl;
#endif

        if(fl.eof())
          throw std::runtime_error("unexpected end of file in dlpoly file " + filename +", when reading box vector"  +
              boost::lexical_cast<string>(i));

        Tokenizer tok(line, " \t");
        vector<double> fields;
        tok.ConvertToVector<double>(fields);
        box_vectors[i]=vec(fields[0],fields[1],fields[2]);

#ifdef DEBUG
	cout << "Read from CONFIG: '" << fixed << setprecision(10) << setw(20) << fields[0] << setw(20) << fields[1] << setw(20) << fields[2] << "' - box vector # " << i+1 << " (Angs)" << endl;
#endif
      }
      matrix box(box_vectors[0],box_vectors[1],box_vectors[2]);

      if(mpbct == 0) {
	pbc_type=BoundaryCondition::typeOpen;
      }
      else if(mpbct == 1 || mpbct == 2 ) {
	pbc_type=BoundaryCondition::typeOrthorhombic;
      }
      else if(mpbct == 3) {
	pbc_type=BoundaryCondition::typeTriclinic;
      }

      top.setBox(box,pbc_type);

      fl.close();

#ifdef DEBUG
      cout << "Read from CONFIG: box/cell matrix - done with boundaries" << endl << endl;
#endif
    }
    else {
      cout << "NOTE: Could not open dlpoly file " << filename << ", so no PBC set in topology - assuming 'open box'" << endl;
    }

    return true;
}

}}

