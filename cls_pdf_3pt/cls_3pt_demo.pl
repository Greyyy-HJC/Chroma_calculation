#!/usr/bin/perl

## ======================================================= ##
## ================== PARAMETERS INPUT =================== ##
## ======================================================= ##

### check params num ###
$num_args = $#ARGV + 1;
if ($num_args != 4) { #check 输入参数是否为4，如果不是，则直接中断pl
   exit;
}

$quark_list="-0.352494893492851"; # mass of "u" quarks
@quark_mass=split(/:/,$quark_list);

$mom_list="7";
@mom=split(/:/,$mom_list);


### Input Params ###
$conf=$ARGV[0];
$prefix=$ARGV[1];
$n_src=$ARGV[2];
$it0=$ARGV[3];

$sink_list="7:8:9:10:11:13:15";
@sink=split(/:/,$sink_list); ## sequential source, tsep, length should be same as nsrc
$links_max = 20; # largest z
$links_dir = 2; # the direction of the links. set it to -1 to calculate all the spacial directions.

$calculateMeson=1; # 1 means do the contracting

## ======================================================= ##
## ================= CONFIGURATION INFO ================== ##
## ======================================================= ##
$ns=48; 
$nt=128;
$clover=1.82487;

$t_seq=($nt-2*$it0)/$n_src; #多个source是放在t轴上，因此每次source横跨了t轴t_seq的范围 # here is open edge


$cfg_file="/dssg/home/acct-phyww/phyww/configurations/cls/N203/N203r000/cnfg/N203r000n${conf}";
$cfg_type="CERN";
$mg_layout="3 3 3 4";  ## multi-grid layout


## ======================================================= ##
## ===================== XML FILE HEAD =================== ##
## ======================================================= ##

print <<"EOF";
<?xml version="1.0"?>
<chroma>
<annotation>
Hadron 3pt input
</annotation>
<Param> 
  <InlineMeasurements>
EOF

## ======================================================= ##
## ===================== APE SMEARING ==================== ##
## ======================================================= ##

print <<"EOF";
    <elem>
      <Name>LINK_SMEAR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>2</version>
        <LinkSmearingType>APE_SMEAR</LinkSmearingType>
        <link_smear_fact>2.5</link_smear_fact>
        <link_smear_num>2</link_smear_num>
        <no_smear_dir>3</no_smear_dir>  
        <BlkMax>100</BlkMax>
        <BlkAccu>1.0e-5</BlkAccu>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <linksmear_id>link_gauge_field</linksmear_id>
      </NamedObject>
    </elem> 
EOF

$link_id="link_gauge_field";

## ======================================================= ##
## ===================== GAUGE FIXING ==================== ##
## ======================================================= ##

# print <<"EOF";

#   <elem>
#       <!-- Coulomb gauge fix -->
#       <Name>COULOMB_GAUGEFIX</Name>
#       <Frequency>1</Frequency>
#       <Param>
#         <version>1</version>
#         <GFAccu>1.0e-6</GFAccu>
#         <GFMax>200</GFMax>
#         <OrDo>false</OrDo>
#         <OrPara>1.0</OrPara>
#         <j_decay>3</j_decay>
#       </Param>
#       <NamedObject>
#         <gauge_id>default_gauge_field</gauge_id>
#         <gfix_id>column_cfg</gfix_id>
#         <gauge_rot_id>gauge_rot</gauge_rot_id>
#       </NamedObject>
#     </elem>

# EOF
# $gauge_id="column_cfg";


$gauge_id="default_gauge_field";


## ======================================================= ##
## ===================== MAKE SOURCE ===================== ##
## ======================================================= ##

### source is related to momentum ###
for($i=0; $i<=$#quark_mass; $i++) 
{
  $quark_mass=@quark_mass[$i];

  for($j=0; $j<=$#mom; $j++) 
  {
    $quark_mom_x=0;
    $quark_mom_y=0;
    $quark_mom_z=@mom[$j];

    $mom_sm_para=$quark_mom_z/2; ## the momentum smearing parameter;

    $mom_had = ""; ## for HADRON_SPECTRUM_v2

    for($m=0; $m<=$quark_mom_z; $m ++){
      $m_se = 505050 - $m;
      $mom_had.="$m_se ";
    }

### three space directions will be integrated when making source ###
print << "EOF"; 
      <elem>
    <annotation>
      Generate the grid source. Should use the smeared gauge field.
    </annotation>      
        <Name>MAKE_SOURCE</Name>
        <Frequency>1</Frequency>
        <Param>
          <version>6</version>
          <Source>
             <version>1</version>
             <SourceType>MOM_GRID_SOURCE</SourceType>
             <j_decay>3</j_decay>
             <t_srce> 24 24 24 $it0</t_srce>
             <grid> $ns $ns $ns $t_seq </grid>
             <ini_mom> 0 0 0 0</ini_mom>
             <SmearingParam>
                <wvf_kind>MOM_GAUSSIAN</wvf_kind>
                <wvf_param>6</wvf_param> 
                <wvfIntPar>72</wvfIntPar>
                <mom>0 0 $mom_sm_para 0</mom>
                <no_smear_dir>3</no_smear_dir>
              </SmearingParam>       
          </Source>
        </Param>
        <NamedObject>
          <gauge_id>$link_id</gauge_id>
          <source_id>sh_source_ori</source_id>
        </NamedObject>
      </elem>

      <elem>
    <annotation>
      Generate the dummy source as a container for chroma elements
    </annotation>      
        <Name>MAKE_SOURCE</Name>
        <Frequency>1</Frequency>
        <Param>
          <version>6</version>
          <Source>
             <version>1</version>
             <SourceType>SHELL_SOURCE</SourceType>
             <j_decay>3</j_decay>
             <t_srce> 24 24 24 $it0 </t_srce>
             <SmearingParam>
               <wvf_kind>GAUGE_INV_GAUSSIAN</wvf_kind>
               <wvf_param>0</wvf_param>
               <wvfIntPar>0</wvfIntPar>
               <mom>0 0 0 0</mom>
               <no_smear_dir>3</no_smear_dir>
             </SmearingParam>
          </Source>
        </Param>
        <NamedObject>
          <gauge_id>$link_id</gauge_id>
          <source_id>sh_source_dummy</source_id>
        </NamedObject>
      </elem>

EOF


## ======================================================= ##
## ===================== STICK SOURCE ==================== ##
## ======================================================= ##

### QPROPADD_cohen is used to stick sources or props ###
### each source should be sticked with the dummy source for using ###
### if you have many sources in t direction, then you need to do QPROPADD_cohen for source and dummy source many times ###
for( $id = 0; $id < $n_src; $id ++ )
{
  $it=$it0+$id*$t_seq;
  
print <<"EOF";
      <elem>
        <Name>QPROPADD_cohen</Name>
        <Frequency>1</Frequency>
        <NamedObject>
          <j_decay>3</j_decay>
          <tA>0 0</tA>
          <factorA>0.0</factorA>
          <propA>sh_source_dummy</propA>
          <tB>$it $it</tB>
          <factorB>1.0</factorB>
          <propB>sh_source_ori</propB>
          <propApB>shell_source_$id</propApB>
        </NamedObject>
      </elem>
EOF
}


## ======================================================= ##
## ==================== ERASE SOURCES ==================== ##
## ======================================================= ##

### now that you've sticked the source and dummy source as a new one, you can erase the former if they are not needed any more ###


print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>sh_source_ori</object_id>
        </NamedObject>
    </elem>

    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>sh_source_dummy</object_id>
        </NamedObject>
    </elem>
EOF



## ======================================================= ##
## =================== MAKE PROPAGATOR =================== ##
## ======================================================= ##

for( $id = 0; $id < $n_src; $id ++ )
{
  $it=$it0+$id*$t_seq;

print <<"EOF";
  <elem>
    <Name>PROPAGATOR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>10</version>
        <quarkSpinType>FULL</quarkSpinType>
        <obsvP>true</obsvP>
        <numRetries>1</numRetries>
          <FermionAction>
          <FermAct>UNPRECONDITIONED_CLOVER</FermAct>
          <Mass>$quark_mass</Mass>
          <clovCoeff>$clover</clovCoeff>
          <FermionBC>
            <FermBC>SIMPLE_FERMBC</FermBC>
            <boundary>1 1 1 -1</boundary>
          </FermionBC>
        </FermionAction>
        <InvertParam>
          <invType>QOP_CLOVER_MULTIGRID_INVERTER</invType>
          <Mass>$quark_mass</Mass>
          <Clover>${clover}</Clover>
          <MaxIter>50</MaxIter>
          <Residual>3e-6</Residual>
          <ExternalSubspace>true</ExternalSubspace>
          <SubspaceId>cpu_multigrid_m$quark_mass</SubspaceId>
          <RsdToleranceFactor>1.5</RsdToleranceFactor>
          <Levels>2</Levels>
          <Blocking>
            <elem>${mg_layout}</elem>
            <elem>2 2 2 2</elem>
          </Blocking>
          <NumNullVecs>24 36</NumNullVecs>
          <NumExtraVecs>0 0</NumExtraVecs>
          <NullResidual>0.4 0.4</NullResidual>
          <NullMaxIter>100 100</NullMaxIter>
          <NullConvergence>0.1 0.1</NullConvergence>
          <Underrelax>1.0 1.0</Underrelax>
          <NumPreHits>0 0</NumPreHits>
          <NumPostHits>4 4</NumPostHits>
          <CoarseMaxIter>12 12</CoarseMaxIter>
          <CoarseResidual>0.1 0.1</CoarseResidual>
        </InvertParam>
    </Param>
    <NamedObject>
      <gauge_id>$gauge_id</gauge_id>
      <source_id>shell_source_$id</source_id>
      <prop_id>prop_m${quark_mass}_p${quark_mom_z}.src$id</prop_id>
    </NamedObject>
  </elem>

EOF


## ======================================================= ##
## ================== ADD PROP TOGETHER ================== ##
## ======================================================= ##

if ($id>0){
    if ($id==1){
        $prop_sum="prop_src0+src1";
        $prop_A="prop_m${quark_mass}_p${quark_mom_z}.src0"
    }
    else{
        $prop_A=$prop_sum;
        $prop_sum.="+src$id";
    }
    $cut_tA1=$it0;  $cut_tA2=$it-1;
    $cut_tB1=$it;   $cut_tB2=$it+$t_seq-1;
    if($cut_tA2<0) {$cut_tA2=$cut_tA2+$nt;}
    if($cut_tB2>=$nt) {$cut_tB2=$cut_tB2-$nt;}

print <<"EOF";
    <elem>
      <Name>QPROPADD_cohen</Name>
      <Frequency>1</Frequency>
      <NamedObject>
        <j_decay>3</j_decay>
        <tA>$cut_tA1 $cut_tA2</tA>
        <factorA>1.0</factorA>
        <propA>${prop_A}</propA>
        <tB>$cut_tB1 $cut_tB2</tB>
        <factorB>1.0</factorB>
        <propB>prop_m${quark_mass}_p${quark_mom_z}.src$id</propB>
        <propApB>${prop_sum}</propApB>
      </NamedObject>
    </elem>

    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>$prop_A</object_id>
        </NamedObject>
    </elem>
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>prop_m${quark_mass}_p${quark_mom_z}.src$id</object_id>
        </NamedObject>
    </elem>

EOF
}


} ## for loop of id stop here

if($n_src==1)
{
  $prop_sum="prop_m${quark_mass}_p${quark_mom_z}.src0";
}


## ======================================================= ##
## ==================== ERASE SOURCES ==================== ##
## ======================================================= ##

### erase the sticked source after making props ###

for( $id = 0; $id < $n_src; $id ++ )
{
  $it=$it0+$id*$t_seq;
print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>shell_source_$id</object_id>
        </NamedObject>
    </elem>

EOF
}


## ======================================================= ##
## ==================== SINK SMEARING ==================== ##
## ======================================================= ##


print <<"EOF";
    <elem>
      <Name>SINK_SMEAR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>5</version>
        <Sink>
          <version>1</version>
          <SinkType>POINT_SINK</SinkType>
          <j_decay>3</j_decay>
        </Sink>
      </Param>
      <NamedObject>
        <gauge_id>$gauge_id</gauge_id>
        <prop_id>${prop_sum}</prop_id> 
        <smeared_prop_id>prop_m${quark_mass}_p${quark_mom_z}.sum_sp</smeared_prop_id>
      </NamedObject>
    </elem>

    <elem>
      <Name>SINK_SMEAR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>5</version>
        <Sink>
          <version>1</version>
          <SinkType>SHELL_SINK</SinkType>
          <j_decay>3</j_decay>
          <SmearingParam>
            <wvf_kind>MOM_GAUSSIAN</wvf_kind>
            <wvf_param>6</wvf_param>
            <wvfIntPar>72</wvfIntPar>
            <no_smear_dir>3</no_smear_dir>
            <mom>0 0 $mom_sm_para 0</mom>
          </SmearingParam>
          <Displacement>
            <version>1</version>
            <DisplacementType>NONE</DisplacementType>
          </Displacement>
        </Sink>
      </Param>
      <NamedObject>
        <gauge_id>$link_id</gauge_id>
        <prop_id>${prop_sum}</prop_id>
        <smeared_prop_id>prop_m${quark_mass}_p${quark_mom_z}.sum_ss</smeared_prop_id>
      </NamedObject>
    </elem>

EOF



## ======================================================= ##
## =================== 2pt contracting =================== ##
## ======================================================= ##


print <<"EOF";
    <elem>
      <annotation>
        Compute the hadron spectrum.
        This version is a clone of the one below, however the xml output is
        written within the same chroma output file
      </annotation>
      <Name>HADRON_SPECTRUM_v2</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>1</version>
        <hadron_list>200505</hadron_list>
        <mom_list>${mom_had}</mom_list>
        <prj_type>0</prj_type>
        <cfg_serial>${conf}</cfg_serial>
        <avg_equiv_mom>false</avg_equiv_mom>
        <time_rev>false</time_rev>
        <translate>false</translate>
        </Param>
      <NamedObject>
        <gauge_id>$gauge_id</gauge_id>
      <sink_pairs>
            <elem>
                <first_id>prop_m${quark_mass}_p${quark_mom_z}.sum_sp</first_id>
                <second_id>prop_m${quark_mass}_p${quark_mom_z}.sum_sp</second_id>
            </elem>
            <elem>
                <first_id>prop_m${quark_mass}_p${quark_mom_z}.sum_ss</first_id>
                <second_id>prop_m${quark_mass}_p${quark_mom_z}.sum_ss</second_id>
            </elem>
        </sink_pairs>
      </NamedObject>
        <output>${prefix}hadspec2_${conf}_src${it0}_p$quark_mom_z.dat.iog</output>
    </elem>


EOF



## ======================================================= ##
## ================== ERASE PROPAGATOR =================== ##
## ======================================================= ##

### sink smearing will use prop to make smeared prop, so some useless prop can be erased ###
### 3pt needs one unsmeared prop for building block, this prop should not be erased ###

# print <<"EOF";
#   <elem>
#     <Name>ERASE_NAMED_OBJECT</Name>
#     <Frequency>1</Frequency>
#     <NamedObject>
#         <object_id>${prop_sum}</object_id>
#     </NamedObject>
#   </elem>

# EOF


## ======================================================= ##
## ================= SEQUENTIAL SOURCE =================== ##
## ======================================================= ##

for($k=0; $k<=$#sink; $k++) 
  {
    $seq_1 = @sink[$k]+32;
    $seq_2 = $seq_1+32;
    $seq_sink="$seq_1 $seq_2";
    $t_sep = @sink[$k];


print <<"EOF";
    <elem>
      <Name>SEQSOURCE_FAST</Name>
      <SmearedProps>true</SmearedProps>
      <multi_tSinks>${seq_sink}</multi_tSinks>
      <Frequency>1</Frequency>
      <Param>
        <version>2</version>
        <SeqSource>
          <version>1</version>
          <SeqSourceType>NUCL_ISO_UNPOL_NONREL</SeqSourceType>
          <j_decay>3</j_decay>
          <t_sink>0</t_sink>
          <sink_mom>0 0 $quark_mom_z</sink_mom>
        </SeqSource>
      </Param>
      <PropSink>
        <version>5</version>
        <Sink>
          <version>2</version>
          <SinkType>SHELL_SINK</SinkType>
          <j_decay>3</j_decay>
          <SmearingParam>
            <wvf_kind>MOM_GAUSSIAN</wvf_kind>
            <wvf_param> 6 </wvf_param>
            <wvfIntPar> 72 </wvfIntPar>
            <no_smear_dir>3</no_smear_dir>
            <mom>0 0 ${mom_sm_para} 0</mom>
          </SmearingParam>
          <Displacement>
            <version>1</version>
            <DisplacementType>NONE</DisplacementType>
          </Displacement>
        </Sink>
      </PropSink>         
      <NamedObject>
        <prop_ids>
              
          <elem>prop_m${quark_mass}_p${quark_mom_z}.sum_ss</elem>

        </prop_ids>
        <seqsource_id>

EOF
for( $id = 0; $id < $n_src; $id = $id + 1 ){
print <<"EOF";        
          <elem>seqsrc.NUCL_ISO_UNPOL_NONREL.m${quark_mass}.id${id}</elem>
EOF
}
print <<"EOF";

        </seqsource_id>
        <gauge_id>$link_id</gauge_id>
      </NamedObject>
   </elem>

EOF


## ======================================================= ##
## ================== COMBINE SEQSOURCE ================== ##
## ======================================================= ##

for( $id = 1; $id < $n_src; $id = $id + 1 ){
   if ($id==1){
       $seq_src_A="seqsrc.NUCL_ISO_UNPOL_NONREL.m${quark_mass}.id0";
       $seq_src_sum="seqsrc_src0+src1";
   }
   else{
       $seq_src_A=$seq_src_sum;
       $seq_src_sum.="+src$id";
   }
print <<"EOF";
    <elem>
        <Name>QPROPADD_cohen</Name>
        <Frequency>1</Frequency>
        <NamedObject>
         <factorA>1.0</factorA>
         <propA>${seq_src_A}</propA>
         <factorB>1.0</factorB>
         <propB>seqsrc.NUCL_ISO_UNPOL_NONREL.m${quark_mass}.id$id</propB>
         <propApB>${seq_src_sum}</propApB>
        </NamedObject>
    </elem>
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>${seq_src_A}</object_id>
        </NamedObject>
    </elem>
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>seqsrc.NUCL_ISO_UNPOL_NONREL.m${quark_mass}.id$id</object_id>
        </NamedObject>
    </elem>
      
EOF
}
if($n_src==1){${seq_src_sum}="seqsrc.NUCL_ISO_UNPOL_NONREL.m${quark_mass}.id0";}




## ======================================================= ##
## =============== SEQUENTIAL PROPAGATOR ================= ##
## ======================================================= ##

print <<"EOF";   
  <elem>
      <Name>PROPAGATOR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>10</version>
        <quarkSpinType>FULL</quarkSpinType>
        <obsvP>true</obsvP>
        <numRetries>1</numRetries>
          <FermionAction>
          <FermAct>UNPRECONDITIONED_CLOVER</FermAct>
          <Mass>$quark_mass</Mass>
          <clovCoeff>$clover</clovCoeff>
          <FermionBC>
            <FermBC>SIMPLE_FERMBC</FermBC>
            <boundary>1 1 1 -1</boundary>
          </FermionBC>
        </FermionAction>
        <InvertParam>
          <invType>QOP_CLOVER_MULTIGRID_INVERTER</invType>
          <Mass>$quark_mass</Mass>
          <Clover>${clover}</Clover>
          <MaxIter>50</MaxIter>
          <Residual>3e-6</Residual>
          <ExternalSubspace>true</ExternalSubspace>
          <SubspaceId>cpu_multigrid_m$quark_mass</SubspaceId>
          <RsdToleranceFactor>1.5</RsdToleranceFactor>
          <Levels>2</Levels>
          <Blocking>
            <elem>${mg_layout}</elem>
            <elem>2 2 2 2</elem>
          </Blocking>
          <NumNullVecs>24 36</NumNullVecs>
          <NumExtraVecs>0 0</NumExtraVecs>
          <NullResidual>0.4 0.4</NullResidual>
          <NullMaxIter>100 100</NullMaxIter>
          <NullConvergence>0.1 0.1</NullConvergence>
          <Underrelax>1.0 1.0</Underrelax>
          <NumPreHits>0 0</NumPreHits>
          <NumPostHits>4 4</NumPostHits>
          <CoarseMaxIter>12 12</CoarseMaxIter>
          <CoarseResidual>0.1 0.1</CoarseResidual>
        </InvertParam>
    </Param>
      <NamedObject>
        <gauge_id>$gauge_id</gauge_id>
        <source_id>${seq_src_sum}</source_id>
        <prop_id>seqprop_NUCL_ISO_UNPOL_NONREL.m${quark_mass}</prop_id>
      </NamedObject>
  </elem>

EOF


## ======================================================= ##
## =================== ERASE SEQSOURCE =================== ##
## ======================================================= ##



print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>${seq_src_sum}</object_id>
        </NamedObject>
    </elem>

EOF




## ======================================================= ##
## ===================== CONTRACTING ===================== ##
## ======================================================= ##

print <<"EOF";
   <elem>
      <annotation>
       "a_0" just indicates the \Gamma =1; therefore the output gamma is the corret ones int eh chroma gamma index
      </annotation>
      <Name>BUILDING_BLOCKS_IOG</Name>
      <Frequency>1</Frequency>
      <Param>
       <version>6</version>
       <cfg_serial>${conf}</cfg_serial>
       <use_sink_offset>false</use_sink_offset>
       <mom2_max> 0 </mom2_max>
       <links_max> $links_max </links_max>
       <links_dir> $links_dir </links_dir>
       <canonical>false</canonical>
       <time_reverse>false</time_reverse>
       <translate>false</translate>
       <conserved>false</conserved>
      </Param>
      <BuildingBlocks>
       <OutFileName>${prefix}3pt_${conf}.NUCL_src${it0}_NONREL_APE_t${t_sep}_p0.out</OutFileName>
       <GaugeId>$link_id</GaugeId>
       <FrwdPropId>${prop_sum}</FrwdPropId>
       <BkwdProps>
         <elem>
           <BkwdPropId>seqprop_NUCL_ISO_UNPOL_NONREL.m${quark_mass}</BkwdPropId>
           <BkwdPropG5Format>G5_B_G5</BkwdPropG5Format>
           <GammaInsertion>0</GammaInsertion>
           <Flavor>U</Flavor>
           <BBFileNamePattern>${prefix}3pt_${conf}.NUCL_src${it0}_tsep${t_sep}_p${quark_mom_z}.iog</BBFileNamePattern>
         </elem>
       </BkwdProps>
      </BuildingBlocks>
      <xml_file>${prefix}3pt_${conf}.NUCL_src${it0}_tsep${t_sep}_p${quark_mom_z}.xml</xml_file>
    </elem>
EOF






## ======================================================= ##
## ================= ERASE SEQPROPAGATOR ================= ##
## ======================================================= ##

### erase sequential props ###

print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>seqprop_NUCL_ISO_UNPOL_NONREL.m${quark_mass}</object_id>
        </NamedObject>
    </elem>
EOF


  } ### end loop of t_seq

  } ## end of loop $j in mom
} ### end of loop $i in quark_mass ###



## ======================================================= ##
## ================== ERASE PROPAGATOR =================== ##
## ======================================================= ##

print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>prop_m${quark_mass}_p${quark_mom_z}.sum_sp</object_id>
        </NamedObject>
    </elem>

EOF

print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>prop_m${quark_mass}_p${quark_mom_z}.sum_ss</object_id>
        </NamedObject>
    </elem>

EOF

## ======================================================= ##
## ================== ERASE PROPAGATOR =================== ##
## ======================================================= ##

### 3pt needs one unsmeared prop for building block, this prop should not be erased ###

print <<"EOF";
  <elem>
    <Name>ERASE_NAMED_OBJECT</Name>
    <Frequency>1</Frequency>
    <NamedObject>
        <object_id>${prop_sum}</object_id>
    </NamedObject>
  </elem>

EOF




## ======================================================= ##
## =============== OTHER NEEDED COMPLEMENT =============== ##
## ======================================================= ##

print <<"EOF";

  </InlineMeasurements>
    <nrow>$ns $ns $ns $nt</nrow>
</Param>

  <RNG>
    <Seed>	
      <elem>11</elem>
      <elem>11</elem>
      <elem>11</elem>
      <elem>0</elem>
    </Seed>
  </RNG>

  <Cfg>
    <cfg_type>${cfg_type}</cfg_type>
    <cfg_file>$cfg_file</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>

</chroma>
EOF

## ======================================================= ##
## ==================== XML FILE END ===================== ##
## ======================================================= ##
