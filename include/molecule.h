// 
// File:   molecule.h
// Author: ruehle
//
// Created on April 12, 2007, 4:07 PM
//

#ifndef _MOLECULE_H
#define	_MOLECULE_H

#include <vector>
#include <map>
#include <string>
#include <assert.h>
#include "topologyitem.h"
#include "bead.h"
using namespace std;

class Interaction;


/**
    \brief information about molecules

    The Molecule class stores which beads belong to a molecule.
    The organization of beads into molecules is needed for the CG mapping.

    \todo sort atoms in molecule

*/
class Molecule : public TopologyItem
{
public:            
    /// get the molecule ID
    int getId() const { return _id; }
    
    /// get the name of the molecule
    const string &getName() const { return _name; }
    
    /// set the name of the molecule
    void setName(const string &name) {  _name=name; }
    
    /// Add a bead to the molecule
    void AddBead(Bead *bead, const string &name);
    /// get the id of a bead in the molecule
    Bead *getBead(int bead) { return _beads[bead]; }
    int getBeadId(int bead) { return _beads[bead]->getId(); }
    int getBeadIdByName(const string &name) { return _beads[getBeadByName(name)]->getId(); }
    
    /// get the number of beads in the molecule
    int BeadCount() const { return _beads.size(); }
    
    /// find a bead by it's name
    int getBeadByName(const string &name);
    string getBeadName(int bead) {return _bead_names[bead]; }

    /// Add an interaction to the molecule
    void AddInteraction(Interaction *ic) { _interactions.push_back(ic);
        }

    vector<Interaction *> Interactions() { return _interactions; }

private:
    // maps a name to a bead id
    map<string, int> _beadmap;
   vector<Interaction*> _interactions;
     
    // id of the molecules
    int _id;
    
    // name of the molecule
    string _name;
    // the beads in the molecule
    vector<Bead *> _beads;
    vector<string> _bead_names;
    
    /// constructor
    Molecule(Topology *parent, int id, string name)
        : _id(id), _name(name), TopologyItem(parent)
    {}

    friend class Topology;
};

#endif	/* _Molecule_H */

