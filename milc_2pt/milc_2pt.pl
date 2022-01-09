#!/usr/bin/perl

## ======================================================= ##
## ================== PARAMETERS INPUT =================== ##
## ======================================================= ##

### check params num ###
$num_args = $#ARGV + 1;
if ($num_args != 4) { #check 输入参数是否为4，如果不是，则直接中断pl
   exit;
}

$quark_list="-0.0695"; # mass of "u:c" quarks
@quark_mass=split(/:/,$quark_list);


### Input Params ###
$conf=$ARGV[0];
$prefix=$ARGV[1];
$n_src=$ARGV[2];
$it0=$ARGV[3];

$calculateMeson=1; # 1 means do the contracting

## ======================================================= ##
## ================= CONFIGURATION INFO ================== ##
## ======================================================= ##
$ns=24; 
$nt=64;
$clover=1.05088;
$t_seq=($nt)/$n_src;#多个source是放在t轴上，因此每次source横跨了t轴t_seq的范围


$cfg_file="/dssg/home/acct-phyww/phyww/configurations/milc/a12m310/l2464f211b600m0102m0509m635a.hyp.${conf}";
$cfg_type="SCIDAC";
$mg_layout="3 3 3 2";  ## multi-grid layout


## ======================================================= ##
## ===================== XML FILE HEAD =================== ##
## ======================================================= ##

print <<"EOF";
<?xml version="1.0"?>
<chroma>
<annotation>
Hadron 2pt input
</annotation>
<Param> 
  <InlineMeasurements>
EOF

## ======================================================= ##
## ===================== APE SMEARING ==================== ##
## ======================================================= ##
$HYP=0; # 这个等于 0 ，所以没做 HYP smearing
if($HYP>0)
{
print <<"EOF";
    <elem>
      <Name>LINK_SMEAR</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>5</version>
        <LinkSmearingType>HYP_SMEAR</LinkSmearingType>
        <alpha1>0.75</alpha1>
        <alpha2>0.6</alpha2>
        <alpha3>0.3</alpha3>
        <num_smear>1</num_smear>
        <no_smear_dir>-1</no_smear_dir>              
        <BlkMax>100</BlkMax>
        <BlkAccu>1.0e-5</BlkAccu>
      </Param>
      <NamedObject>
        <gauge_id>$gauge_id</gauge_id>
        <linksmear_id>APE_gauge_field</linksmear_id>
      </NamedObject>
    </elem>      
EOF
$gauge_id="APE_gauge_field";
}

## ======================================================= ##
## ===================== GAUGE FIXING ==================== ##
## ======================================================= ##

### for wall source ###
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
for($i=0; $i<=$#quark_mass; $i++) # start from 1 because 0 and 1 are same (u and d)
{
  $quark_mass=@quark_mass[$i];
  $quark_mom_x=0;
  $quark_mom_y=0;
  $quark_mom_z=0;

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
             <t_srce> 0 0 0 $it0</t_srce>
             <grid> $ns $ns $ns $t_seq </grid>
             <ini_mom> 0 0 0 0</ini_mom>
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
          <gauge_id>$gauge_id</gauge_id>
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
             <t_srce> 0 0 0 $it0 </t_srce>
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
          <gauge_id>$gauge_id</gauge_id>
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
$it=$it0;
print <<"EOF";
    <elem>
      <Name>QPROPADD_cohen</Name>
      <Frequency>1</Frequency>
      <NamedObject>
        <j_decay>3</j_decay>
        <tA>$it $it</tA>
        <factorA>0.0</factorA>
        <propA>sh_source_dummy</propA>
        <tB>$it $it</tB>
        <factorB>1.0</factorB>
        <propB>sh_source_ori</propB>
        <propApB>shell_source_0</propApB>
      </NamedObject>
    </elem>
EOF


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
          <MaxIter>500</MaxIter>
          <Residual>3e-6</Residual>
          <ExternalSubspace>true</ExternalSubspace>
          <SubspaceId>cpu_multigrid_m$quark_mass</SubspaceId>
          <RsdToleranceFactor>1.5</RsdToleranceFactor>
          <Levels>2</Levels>
          <Blocking>
            <elem>${mg_layout}</elem>
            <elem>2 2 2 1</elem>
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
      <source_id>shell_source_0</source_id>
      <prop_id>prop_m${quark_mass}_p${quark_mom_z}.src0</prop_id>
    </NamedObject>
  </elem>

EOF


## ======================================================= ##
## ================== ADD PROP TOGETHER ================== ##
## ======================================================= ##


if($n_src==1)
{
  $prop_sum="prop_m${quark_mass}_p${quark_mom_z}.src0";
}


## ======================================================= ##
## ==================== ERASE SOURCES ==================== ##
## ======================================================= ##

### erase the sticked source after making props ###

print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>shell_source_0</object_id>
        </NamedObject>
    </elem>

EOF


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

EOF


## ======================================================= ##
## ================== ERASE PROPAGATOR =================== ##
## ======================================================= ##

### sink smearing will use prop to make smeared prop, so some useless prop can be erased ###
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

} # end of loop $i in @quark_mass

## ======================================================= ##
## =================== 2pt contracting =================== ##
## ======================================================= ##

if($calculateMeson>0)
{
$u_mass=@quark_mass[0];

print <<"EOF";
    <elem>
        <annotation>
            Demo test
        </annotation>
        <Name>DEMO</Name>
        <Param>
            <mom_s1_p1> 0 0 0 0 </mom_s1_p1>
            <it0>0</it0>
            <tseq>$t_seq</tseq>
            <nsr>$n_src</nsr>
            <src>0 0 0 0</src>
            <cfg_serial>${conf}</cfg_serial>
            <file_name>${prefix}demo_${conf}_pion_it_${it0}_p_0.dat.iog</file_name>
        </Param>
        <NamedObject>
            <gauge_id>$gauge_id</gauge_id>
            <s1_props_1><elem>prop_m${u_mass}_p0.sum_sp</elem></s1_props_1>
        </NamedObject>
    </elem>       

EOF


}# end calculate meson



## ======================================================= ##
## ================== ERASE PROPAGATOR =================== ##
## ======================================================= ##

for($i=0; $i<=$#quark_mass; $i++) # start from 1 because 0 and 1 are same (u and d)
{
  $quark_mass=@quark_mass[$i];
  $quark_mom_x=0;
  $quark_mom_y=0;
  $quark_mom_z=0;

print <<"EOF";
    <elem>
        <Name>ERASE_NAMED_OBJECT</Name>
        <Frequency>1</Frequency>
        <NamedObject>
            <object_id>prop_m${quark_mass}_p${quark_mom_z}.sum_sp</object_id>
        </NamedObject>
    </elem>

EOF
}  # end loop @used_quarks_mass


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