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

#ifndef HAVE_NO_CONFIG
#include <votca_config.h>
#endif

#include <votca/csg/topologyreader.h>
#include "modules/io/esptopologyreader.h"
#include "modules/io/lammpsreader.h"
#include "modules/io/xmltopologyreader.h"

#ifdef GMX
#include "modules/io/gmxtopologyreader.h"
#include "modules/io/grotopologyreader.h"
#include "modules/io/pdbtopologyreader.h"
#endif

namespace votca { namespace csg {

void TopologyReader::RegisterPlugins(void)
{
    TopReaderFactory().Register<ESPTopologyReader>("esp");		
    TopReaderFactory().Register<XMLTopologyReader>("xml");
    TopReaderFactory().Register<LAMMPSReader>("dump");
#ifdef GMX
    TopReaderFactory().Register<GMXTopologyReader>("tpr");
    TopReaderFactory().Register<GROTopologyReader>("gro");
    TopReaderFactory().Register<PDBTopologyReader>("pdb");
#endif
}

}}
