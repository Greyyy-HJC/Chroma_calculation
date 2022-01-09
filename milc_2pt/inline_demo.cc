// Some test functions for bi-current matrix element $
/*! \file
 * \brief Inline construction of pion-decay two-point correlators
 *
 * Calculates the two-point correlator of the pseudoscalar meson corresponding
 * to leptonic decay by temporal-axial current.
 *
 * v1.2 adds input of momentum using a list
 * v1.1 adds multiple-source location trickery
 */
 
#include "inline_demo.h"
#include "meas/inline/abs_inline_measurement_factory.h"
#include "util/ft/sftmom.h"
#include "util/info/proginfo.h"
#include "io/param_io.h"
#include "io/qprop_io.h"
#include "meas/inline/make_xml_file.h"
#include "meas/inline/io/named_objmap.h"
#include "meas/smear/no_quark_displacement.h"
#include "io_general_class.h"

namespace Chroma
{

//------------------------------------------------------------------------------
// Factory Registration

  // Environment in which the measurement lives (holds params and such)
  namespace InlineDEMOEnv
  {
    namespace
    {
      // Function to register with a factory
      AbsInlineMeasurement* createMeasurement( XMLReader& xml_in,
                                       const std::string& path )
      {
        return new InlineDEMO( InlineDEMOParams(xml_in, path) );
      }

      //! Local registration flag
      bool registered = false;
    }
    
    // The name of the measurement for the XML file
    const std::string name = "DEMO";

    //! Register all the factories
    bool registerAll()
    {
      bool success = true;
      if (!registered)
      {
        success &= TheInlineMeasurementFactory::Instance()
            .registerObject(name, createMeasurement);
        registered = true;
      }
      return success;
    }
  } // end namespace InlineDEMOEnv


//------------------------------------------------------------------------------
// Parameter reading, writing, handling

  //! Reader for parameters
  void read(             XMLReader& xml,
                 const std::string& path,
    InlineDEMOParams::Param_t& param )
  {
    XMLReader paramtop(xml, path);

//    read(paramtop, "mom", param.mom);
    read(paramtop, "mom_s1_p1", param.mom_s1_p1);
    read(paramtop, "file_name", param.file_name);
    read(paramtop, "cfg_serial", param.cfg_serial);
    read(paramtop, "nsr", param.nsr);
    read(paramtop, "it0", param.it0);
    read(paramtop, "tseq", param.tseq);
    read(paramtop, "src", param.src);
  }



  //! Writer for parameters
  void write(                  XMLWriter& xml,
                       const std::string& path,
    const InlineDEMOParams::Param_t& param )
  {
    push(xml, path);

//    write(xml, "mom", param.mom);
    write(xml, "mom_s1_p1", param.mom_s1_p1);
    write(xml, "file_name", param.file_name);
    write(xml, "cfg_serial", param.cfg_serial);
    write(xml, "nsr", param.nsr);
    write(xml, "it0", param.it0);
    write(xml, "tseq", param.tseq);
    write(xml, "src", param.src);
    pop(xml);
  }


  //! Named objects (gauge config, prop pairs) input
  void read(                   XMLReader& xml,
                       const std::string& path,
    InlineDEMOParams::NamedObject_t& input )
  {
    XMLReader inputtop(xml, path);

    read(inputtop, "gauge_id", input.gauge_id);
    read(inputtop, "s1_props_1", input.s1_props_1);
  }



  //! Named objects (gauge config, prop pairs) output
  void write(                        XMLWriter& xml,
                             const std::string& path,
    const InlineDEMOParams::NamedObject_t& input )
  {
    push(xml, path);

    write(xml, "gauge_id", input.gauge_id);
    write(xml, "s1_props_1", input.s1_props_1);

    pop(xml);
  }

  // Params default constructor
  InlineDEMOParams::InlineDEMOParams(void)
  {
    frequency = 0;
  }


  // Construct params from XML
  InlineDEMOParams::InlineDEMOParams( XMLReader& xml_in,
                                        const std::string& path )
  {
    try
    {
      XMLReader paramtop(xml_in, path);

      if (paramtop.count("Frequency") == 1)
        read(paramtop, "Frequency", frequency);
      else
        frequency = 1;

      // Read in the parameters
      read(paramtop, "Param", param);

      // Read in the output propagator/source configuration info
      read(paramtop, "NamedObject", named_obj);

      // Possible alternate XML file pattern
      if (paramtop.count("xml_file") != 0)
      {
        read(paramtop, "xml_file", xml_file);
      }
    }
    catch(const std::string& e)
    {
      QDPIO::cerr << __func__ << ": Caught Exception reading XML: "
                  << e << std::endl;
      QDP_abort(1);
    }
  }



  // Write out the parameters we constructed
  void InlineDEMOParams::write( XMLWriter& xml_out,
                             const std::string& path )
  {
    push(xml_out, path);

    Chroma::write(xml_out, "Param", param);
    Chroma::write(xml_out, "NamedObject", named_obj);
    QDP::write(xml_out, "xml_file", xml_file);

    pop(xml_out);
  }

//------------------------------------------------------------------------------
// Helper functions to read in pairs of propagators

  // Anonymous namespace for propagator-handling utilities
  namespace
  {
    //! Useful structure holding sink props
    struct SinkPropContainer_t
    {
      ForwardProp_t prop_header;
      std::string quark_propagator_id;
      Real Mass;

      multi1d<int> bc;

      std::string source_type;
      std::string source_disp_type;
      std::string sink_type;
      std::string sink_disp_type;
    };

    //! Read a sink prop
    void readSinkProp( SinkPropContainer_t& s,
                         const std::string& id )
    {
      try
      {
        // Try a cast to see if it succeeds
        const LatticePropagator& foo =
          TheNamedObjMap::Instance().getData<LatticePropagator>(id);

        // Snarf the data into a copy
        s.quark_propagator_id = id;

        // Snarf the prop info. This is will throw if the prop_id is not there
        XMLReader prop_file_xml, prop_record_xml;
        TheNamedObjMap::Instance().get(id).getFileXML(prop_file_xml);
        TheNamedObjMap::Instance().get(id).getRecordXML(prop_record_xml);

        // Try to invert this record XML into a ChromaProp struct
        // Also pull out the id of this source
        std::string xpath;
        read(prop_record_xml, "/SinkSmear", s.prop_header);

        xpath = "/SinkSmear/PropSource/Source/SourceType";
        read(prop_record_xml, xpath, s.source_type);
        xpath = "/SinkSmear/PropSource/Source/Displacement/DisplacementType";
        if (prop_record_xml.count(xpath) != 0)
          read(prop_record_xml, xpath, s.source_disp_type);
        else
          s.source_disp_type = NoQuarkDisplacementEnv::getName();
        
        xpath = "/SinkSmear/PropSink/Sink/SinkType";
        read(prop_record_xml, xpath, s.sink_type);
        xpath = "/SinkSmear/PropSink/Sink/Displacement/DisplacementType";
        if (prop_record_xml.count(xpath) != 0)
          read(prop_record_xml, xpath, s.sink_disp_type);
        else
          s.sink_disp_type = NoQuarkDisplacementEnv::getName();
      }
      catch( std::bad_cast )
      {
        QDPIO::cerr << InlineDEMOEnv::name << ": caught dynamic cast error"
                    << std::endl;
        //QDP_abort(1);
      }
      catch (const std::string& e)
      {
        QDPIO::cerr << InlineDEMOEnv::name << ": error message: " << e
                    << std::endl;
        //QDP_abort(1);
      }

      // Derived from input prop
      // Hunt around to find the mass
      // NOTE: This may be problematic in the future if actions are used with no
      // clear definition of a mass
      QDPIO::cout << "Try action and mass" << std::endl;
      s.Mass = getMass(s.prop_header.prop_header.fermact);

      // Only baryons care about boundaries
      // Try to find them. If not present, assume Dirichlet.
      // This turns off any attempt to time reverse which is the
      // only thing that the boundary conditions are affecting.
      s.bc.resize(Nd);
      s.bc = 0;

      try
      {
        s.bc = getFermActBoundary(s.prop_header.prop_header.fermact);
      }
      catch (const std::string& e)
      {
        QDPIO::cerr << InlineDEMOEnv::name
                    << ": caught exception. No BC found in these headers. "
                    << "Will assume dirichlet: " << e << std::endl;
      }

      QDPIO::cout << "FermAct = " << s.prop_header.prop_header.fermact.id << std::endl;
      QDPIO::cout << "Mass = " << s.Mass << std::endl;
    }
  } // end namespace

//------------------------------------------------------------------------------
// The real work is done here

  // Set up the XML and invoke func, which does the actual work
  void InlineDEMO::operator()( unsigned long update_no,
                                       XMLWriter& xml_out )
  {
    // If xml file not empty, then use alternate
    if (params.xml_file != "")
    {
      std::string xml_file = makeXMLFileName(params.xml_file, update_no);

      push(xml_out, "DEMO");
      write(xml_out, "update_no", update_no);
      write(xml_out, "xml_file", xml_file);
      pop(xml_out);

      XMLFileWriter xml(xml_file);
      func(update_no, xml);
    }
    else
    {
      func(update_no, xml_out);
    }
  }

  // Real work done here
  void InlineDEMO::func( unsigned long update_no,
                                 XMLWriter& xml_out)
  {
    START_CODE();

    StopWatch snoop;
    snoop.reset();
    snoop.start();

    // Grab gauge configuration
    multi1d<LatticeColorMatrix> U;
    XMLBufferWriter gauge_xml;
    try
    {
      // Try to get the gauge field.
      // If it doesn't exist, an exception will be thrown.
      U=TheNamedObjMap::Instance().getData< multi1d<LatticeColorMatrix> >(params.named_obj.gauge_id);
      TheNamedObjMap::Instance().get(params.named_obj.gauge_id).getRecordXML(gauge_xml);
    }
    catch(std::bad_cast)
    {
      // If the object exists and is of the wrong type we will land here
      QDPIO::cerr << InlineDEMOEnv::name << ": caught dynamic cast error"
                  << std::endl;
      QDP_abort(1);
    }
    catch (const std::string& e)
    {
      // If the object is not in the map we will land here
      QDPIO::cerr << InlineDEMOEnv::name << ": map call failed: " << e
                  << std::endl;
      QDP_abort(1);
    }
    // Bind gauge field reference to a local name
    const multi1d<LatticeColorMatrix>& u =
      TheNamedObjMap::Instance().getData< multi1d<LatticeColorMatrix> >(params.named_obj.gauge_id);

    // Boilerplate stuff to the output XML
    push(xml_out, "quasiDA");
    write(xml_out, "update_no", update_no);

    // Write some diagnostic junk about the lattice
    QDPIO::cout << "quasiDA matrix elements:" << std::endl;
    QDPIO::cout << std::endl << "     Gauge group: SU(" << Nc << ")" << std::endl;
    QDPIO::cout << "     volume: " << Layout::lattSize()[0];
    for (int i=1; i<Nd; ++i) {
      QDPIO::cout << " x " << Layout::lattSize()[i];
    }
    QDPIO::cout << std::endl;

    // Write info about the program
    proginfo(xml_out);

    // Write out the input
    params.write(xml_out, "Input");

    // Write out the config info
    write(xml_out, "Config_info", gauge_xml);

    // Calculate the plaquette. Why not? It's always fun!
    // MesPlq(xml_out, "Observables", u);

    // Keep an array of all the xml output buffers
    push(xml_out, "quasiDA_measurements");


    multi1d<SinkPropContainer_t> s1_props_1(params.named_obj.s1_props_1.size());

    for(int lnum=0; lnum < params.named_obj.s1_props_1.size(); ++lnum) readSinkProp(s1_props_1[lnum], params.named_obj.s1_props_1[lnum]);


    int j_decay = s1_props_1[0].prop_header.source_header.j_decay;

    SftMom *p_phases;  // Pointer for phases

/// set the phase.
    // Keep a copy of the phases with NO momenta
    QDPIO::cout << "J_decay=" << j_decay <<  std::endl;
    SftMom phases_nomom(0, true, j_decay);
    Set timeslice= phases_nomom.getSet();
    int tlen = Layout::lattSize()[j_decay];


/*  add the two phases -quarks;
 */      
    LatticeReal p_dot_x_1=0., p_dot_x_2=0.;
    for (int mu = 0, j=0; mu < Nd; ++mu) {
       const Real twopi = 6.283185307179586476925286;
       if (mu == j_decay) continue;
       p_dot_x_1 += (LatticeReal(Layout::latticeCoordinate(mu))-params.param.src[mu]) * twopi * Real(params.param.mom_s1_p1[j]) / Layout::lattSize()[mu];
       ++j;
    }
    LatticeComplex  phase1=cmplx(cos(p_dot_x_1),sin(p_dot_x_1));

    general_data_base res(params.param.file_name.c_str());

    int t0  = params.param.it0;
    int n_src = params.param.nsr;
    int tseq = n_src * params.param.tseq;

    QDPIO::cout << "phase over"  <<  std::endl;  

    res.add_dimension(dim_conf, 1, &params.param.cfg_serial);
    res.add_dimension(dim_t, tseq);
    res.add_dimension(dim_complex, 2);

    QDPIO::cout << "t0=" << t0 <<  std::endl;
	  QDPIO::cout << "n_src=" << n_src <<  std::endl;
	  QDPIO::cout << "t_seq=" << tseq <<  std::endl;
    QDPIO::cout << "dim over"  <<  std::endl;

    if(Layout::primaryNode()) res.initialize();

      const LatticePropagator& s1_sink_prop = phase1*TheNamedObjMap::Instance().getData<LatticePropagator>(s1_props_1[0].quark_propagator_id);
      const LatticePropagator& s1_anti_prop = phase1*TheNamedObjMap::Instance().getData<LatticePropagator>(s1_props_1[0].quark_propagator_id);
          
      LatticePropagator s1_sink_prop_af = s1_sink_prop;
      LatticePropagator s1_anti_sink_prop_af = Gamma(15) * s1_anti_prop * Gamma(15);
      LatticeComplex corr ;

    QDPIO::cout << "define over"  << std::endl;

        corr = trace(adj(s1_anti_sink_prop_af) * Gamma(15) * s1_sink_prop_af * Gamma(15));
        multi1d<DComplex> hsum = sumMulti(corr,timeslice);
        double real=0.,imag=0.;
        if(Layout::primaryNode())
        for (int t=0; t < tseq; ++t){
            real = hsum[t].elem().elem().elem().real();
            imag = hsum[t].elem().elem().elem().imag();
            res.data[2*t]=real;
            res.data[2*t+1]=imag;
        }

    QDPIO::cout << "trace over"  <<  std::endl;




  if(Layout::primaryNode()) res.save();
    pop(xml_out);  // Wilson_spectroscopy
    pop(xml_out);  // PionDA

    snoop.stop();
    QDPIO::cout << InlineDEMOEnv::name << ": total time = "
                << snoop.getTimeInSeconds()
                << " secs" << std::endl;

    QDPIO::cout << InlineDEMOEnv::name << ": ran successfully" << std::endl;

    END_CODE();
  } // end of InlinePionDA::func

}; // end of namespace Chroma

