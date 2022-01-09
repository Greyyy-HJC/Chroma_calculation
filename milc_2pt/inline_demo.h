// -*- C++ -*-
// $Id: inline_tmdwf.h, v1.1 2020-05-02: quasiDA for pseduoscalar and vectors $
/*! \file
 * \brief Inline construction of pion-decay two-point correlators
 *
 * Calculates the two-point correlator of the pseudoscalar meson corresponding
 * to leptonic decay by temporal-axial current.
 */

#ifndef __inline_DEMO_h__
#define __inline_DEMO_h__

#include "chromabase.h"
#include "meas/inline/abs_inline_measurement.h"
#include "util/ft/sftmom.h"

namespace Chroma 
{ 
  /*! \ingroup inlinedemo */
  namespace InlineDEMOEnv 
  {
    extern const std::string name;
    bool registerAll();
  }

  //! Parameter structure
  /*! \ingroup inlinedemo */
  struct InlineDEMOParams 
  {
    // Default constructor
    InlineDEMOParams(void);
    // Construct from XML
    InlineDEMOParams(XMLReader& xml_in, const std::string& path);
    // Write out the configuration of the parameters
    void write(XMLWriter& xml_out, const std::string& path);

    // How often should I be called during a gauge evolution?
    unsigned long frequency;

    // Holds the non-lattice parameters
    struct Param_t
    {
      multi1d<int>     mom_s1_p1 ;   /*<! momentum at sink*/

      int  it0;
      int  tseq;
      int  nsr;
      multi1d<int> src;  /*!< source position */
      std::string  file_name;          /*!< bb output file name pattern */
      int  cfg_serial;          /*!< the configuration serial number */
      
    } param;

    // Holds the names of the lattice objects
    struct NamedObject_t
    {
      std::string  gauge_id;           /*!< Input gauge field */
      multi1d<std::string> s1_props_1;  /*!< List of propagator pairs to contract */
    } named_obj;

    std::string xml_file;  // Alternate XML file pattern
  }; // end of struct InlinePionDAParams


  //! Inline measurement of hadron spectrum
  /*! \ingroup inlinehadron */
  class InlineDEMO : public AbsInlineMeasurement 
  {
  public:
    // Default destructor
    ~InlineDEMO() {}
    // Constructor from param struct: copies param struct
    InlineDEMO(const InlineDEMOParams& p) : params(p) {}
    // Copy constructor
    InlineDEMO(const InlineDEMO& p) : params(p.params) {}

    // Getter for measurement frequency
    unsigned long getFrequency() const {return params.frequency;}

    //! Sets up the XML and invokes func, which does the acual work
    void operator()( const unsigned long update_no, XMLWriter& xml_out); 

  protected:
    //! Does the actual work
    void func(const unsigned long update_no, XMLWriter& xml_out); 

  private:
    //! The parameter structure; holds names of props, gauge field, XML, etc.
    InlineDEMOParams params;
  }; // end of class InlineDEMO

}; // end of namespace Chroma

#endif
