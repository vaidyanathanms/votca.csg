// 
// File:   xmltopologyreader.cc
// Author: victor
//
// Created on 14. April 2008, 13:35
//

#include <iostream>
#include <fstream>
#include <boost/lexical_cast.hpp>
#include <stdio.h>
#include "xmltopologyreader.h"

bool XMLTopologyReader::ReadTopology(string filename, Topology &top)
{ 
    xmlDocPtr doc;
    xmlNodePtr node;
    
    _top = &top;
    
    doc = xmlParseFile(filename.c_str());
    if(doc == NULL) 
        throw "Error on open xml bead map: " + filename;
    
    node = xmlDocGetRootElement(doc);
    
    if(node == NULL) {
        xmlFreeDoc(doc);
        throw "Error, empty xml document: " + filename;
    }
    
    if(xmlStrcmp(node->name, (const xmlChar *) "topology")) {
        xmlFreeDoc(doc);
        xmlCleanupParser();
        throw "Error, wrong root node in " + filename;
    }           
    
    ParseTopology(node);
    
    xmlFreeDoc(doc);
    xmlCleanupParser();
    
    return true;
}

void XMLTopologyReader::ReadTopolFile(string file)
{
    TopologyReader *reader;
    reader = TopReaderFactory().Create(file);
    if(!reader)
        throw file + ": unknown topology format";
    
    reader->ReadTopology(file, *_top);
    
    delete reader;
}

void XMLTopologyReader::ParseTopology(xmlNodePtr node)
{
    xmlChar *attr =  xmlGetProp(node, (const xmlChar *)"base");
    if(attr) {
        ReadTopolFile((const char *)attr);
        xmlFree(attr);
    }
    
    for(node = node->xmlChildrenNode; node != NULL; node = node->next) {
        if(!xmlStrcmp(node->name, (const xmlChar *) "molecules"))
            ParseMolecules(node);
    }     
}

void XMLTopologyReader::ParseMolecules(xmlNodePtr node)
{
    for(node = node->xmlChildrenNode; node != NULL; node = node->next) {
        if(!xmlStrcmp(node->name, (const xmlChar *) "clear")) {
            _top->ClearMoleculeList();
        }
        if(!xmlStrcmp(node->name, (const xmlChar *) "rename")) {
            char *molname = (char *) xmlGetProp(node, (const xmlChar *)"name");
            char *range = (char *) xmlGetProp(node, (const xmlChar *)"range");
            if(molname && range) {
                _top->RenameMolecules(range, molname);
                xmlFree(molname);
                xmlFree(range);
            }
            else
                throw string("invalid name tag");               
        }
        if(!xmlStrcmp(node->name, (const xmlChar *) "define")) {
            char *molname = (char *) xmlGetProp(node, (const xmlChar *)"name");
            char *first = (char *) xmlGetProp(node, (const xmlChar *)"first");
            char *nbeads = (char *) xmlGetProp(node, (const xmlChar *)"nbeads");
            char *nmols = (char *) xmlGetProp(node, (const xmlChar *)"nmols");
            if(molname && first && nbeads && nmols) {
                _top->CreateMoleculesByRange(molname,
                        boost::lexical_cast<int>(first),
                        boost::lexical_cast<int>(nbeads),
                        boost::lexical_cast<int>(nmols));
                xmlFree(molname);
                xmlFree(first);
                xmlFree(nbeads);
                xmlFree(nmols);
            }
            else
                throw string("invalid name tag");               
        }
    }         
}
