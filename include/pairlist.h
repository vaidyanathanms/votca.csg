/* 
 * File:   pairlist.h
 * Author: ruehle
 *
 * Created on March 4, 2009, 1:45 PM
 */

#ifndef _PAIRLIST_H
#define	_PAIRLIST_H

#include <list>
#include <map>

template<typename element_type, typename pair_type>
class PairList {
public:
    PairList() {}
    ~PairList() { Cleanup(); }
              
    //void Generate(BeadList *list1, BeadList *list2 = NULL);    
    void AddPair(pair_type *p);
    
    typedef typename std::list<pair_type *>::iterator iterator;
    typedef typename std::map<element_type, pair_type*> partners;
    
    iterator begin() { return _pairs.begin(); }
    iterator end() { return _pairs.end(); }
    typename list<pair_type*>::size_type size() { return _pairs.size(); }    
    pair_type *front() { return _pairs.front(); }
    pair_type *back() { return _pairs.back(); }    
    bool empty() { return _pairs.empty(); }
    
    void Cleanup();
    
    pair_type *FindPair(element_type e1, element_type e2);
    
    partners *FindPartners(element_type e1);

    typedef element_type element_t;
    typedef pair_type pair_t;

protected:
    list<pair_type *> _pairs;
      
    map< element_type , map<element_type, pair_type *> > _pair_map;
    
};

template<typename element_type, typename pair_type>
inline void PairList<element_type, pair_type>::AddPair(pair_type *p)
{
    _pair_map[ p->first ][ p->second ] = p;
     /// \todo check if unique    
    _pairs.push_back(p);    
}


template<typename element_type, typename pair_type>
inline void PairList<element_type, pair_type>::Cleanup()
{
    for(iterator iter = _pairs.begin(); iter!=_pairs.end(); ++iter)
        delete *iter;
    _pairs.clear();
}

template<typename element_type, typename pair_type>
inline pair_type *PairList<element_type, pair_type>::FindPair(element_type e1, element_type e2)
{
    typename std::map< element_type , map< element_type, pair_type * > >::iterator iter1;    
    iter1 = _pair_map.find(e1);
    if(iter1==_pair_map.end()) return NULL;
    
    //typename map<element_type, pair_type *>::iterator iter2;    
    typename partners::iterator iter2;    
    iter2 = iter1->second.find(e2);
    if(iter2 == iter1->second.end()) return NULL;
    
    return iter2->second;
}

template<typename element_type, typename pair_type>
typename PairList<element_type, pair_type>::partners *PairList<element_type, pair_type>::FindPartners(element_type e1)
{
    typename partners::iterator iter;
    if((iter=_pair_map.find(e1)) == _pair_map.end())
        return NULL;
    return iter;
}


#endif	/* _PAIRLIST_H */

