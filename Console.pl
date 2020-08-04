# v 1.7.0    10/06/2020   Hung Duy
# Updates to cover real32 case 
#=========================================================================================================

#=========================================================================================================
#	Options
#=========================================================================================================
use Cwd;
use strict;
use warnings;
use Data::Dumper;
require XML::LibXML;
use File::Basename;
use Tk;
use File::Copy;

#=========================================================================================================
#	Modules
#=========================================================================================================


my $scriptFileName = basename $0;
my $scrptVrsion = "1.7.0";
my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
my $time = sprintf("%02d",${hour}).":".sprintf("%02d",${min}).":".sprintf("%02d", ${sec});
my $date = $mday."-".($mon+1)."-".($year+1900);	 
print "\n--------------------------------------------------------------\n";
print "\n$scriptFileName(v$scrptVrsion) Started at $time on $date ..\n\n";

####################################################################################################
#Globals Variables
#my $arxml = "";                        # Module ARXML file
#my $pavast = "";                        # Module PaVaSt file
#my $moduleArxml ="";                    # 
my %intTypes = ();                      # Format - {Data Element Name [lower Limit, Upper Limit]}	
my %arrayTypes = ();   
my %parmIntTypes = ();                  # Format - {Data Element Name [lower Limit, Upper Limit]}	
my %parmArrayTypes = ();                 
my %real32Types = ();                   # Format - {Data Element Name [lower Limit, Upper Limit]}   #########################################################
my %parmReal32Types = ();                                                                           #########################################################
my %linearCompuMethods = ();            # Hash to store compu-method details
my %unitShortNames = ();                # Hash to store unit details
my %runnableDetails = ();               # Hash to store unit details
my @boolDataElements = ();              # Array for Stores Boolean Data Elements
my @boolParmElements = ();              # Array for Stores Boolean Data Elements
my @dateElements = ();  		            # Array to store all data elements
my @providerPorts = ();  		            # Array to store Provider ports
my @receiverPorts = ();  		            # Array to store Receiver ports
my $option = "";
my $appSWCName="NameNotPresent";
my $ArRelease = "";
my $arrayDataType = "";
my $counti = 1;

my $ScriptPath = $0;
$ScriptPath =~ s/$scriptFileName$//;
my $pavast_new = "";
my $new_pavast = "";
my $dir = getcwd;

my $moduleArxml = "";
my $pavast =  "";
####################################################################################################

 $moduleArxml = get_first_file(".arxml");
 $pavast = get_first_file(".xml");
print "[INFO]: PaVaSt file to update is: $pavast.\n"; 
print "[INFO]: ARXML file to update is: $moduleArxml.\n";
ButRefStart_push();
MainLoop;

####################################################################################################		


####################################################################################################
#
# Parse arxml files : main function
#
####################################################################################################
sub get_first_file {
	my $ext = shift =~ s/.*\.//r;
	+(<*.$ext>)[0];
}
sub ButRefStart_push
 {
    $pavast_new = $pavast;
    $pavast_new =~ s{\.[^.]+$}{};            #Remove File extension    
    if(readModuleArxml($moduleArxml))
    {
      if(parsePaVaSt($pavast))
      {
	       print "[INFO]: Updated PaVaSt file generated and stored in $new_pavast. Please review file content.\n";
	    }
	    else
      {
	      print "[INFO]: Error while reading PaVaSt file. Please check file content.";
	    }
    }
    else
    {
      print "[INFO]: Error while reading Module ARXML file. Please check file content.";
    }	
    exit;
}
sub parsePaVaSt
{  
  my ($file) = $pavast;
  return 0 unless -f $file;
  return 0 unless $file =~ /.+\.xml$/;  
  my $parser = XML::LibXML->new();
  $parser->keep_blanks(0);
  my $document = $parser->parse_file($file); 
  my $element = $document->getDocumentElement(); 						
  my $comment = $document->createComment("Updated by ModifyPaVaSt_GUI.pl for DLL Generation with ECCo");
  $document->insertBefore($comment, $document->firstChild);	
  $element = modifyModulePaVaSt($element, $file);	    
  if($ArRelease eq "4.0")
  {
    print "[INFO]: ARXML 3.x not available\n";
  }
  else
  {
    $new_pavast = $pavast_new."_new.xml";
  }
  $document->toFile($new_pavast, 1);     
  #removeBlankLines($new_pavast);         # Remove blank lines present in the modified ARXML file
  return 1;
}

####################################################################################################
#
# Subroutine to Modify the PaVaSt file
#
####################################################################################################
######################################################################################################################################################################################################### 
sub modifyModulePaVaSt
{  
  my ($element, $file) = @_;     	
  print "\n ---------------------------------\n";
  print "[INFO]: Modifying Module PaVaSt file \n $file..\n";
  print "------------------------------------\n";	
  my $noOfIntegerTypes = 0;
  my $noOfBooleanTypes = 0;            
   
  #Create SW variable for each element
  my $compuMethod = ""; 

######################################################################################################################################################################################################### 
  #Handling Array Types
  foreach my $arrayType(keys %arrayTypes) 
  {
    print "Adding Data Element: $arrayType\n";	
    #get the data type
    my $dateType = (@{$arrayTypes{$arrayType}})[0];
    my $arraySize = (@{$arrayTypes{$arrayType}})[1];
     
    #Create W-DATA-CONSTR-REF 
    my $lowerLimit = (@{$arrayTypes{$arrayType}})[2];
    if($lowerLimit < 0) 
    {
      $lowerLimit *= -1 ;
      $lowerLimit = "_055".$lowerLimit; 
    }
    my $upperLimit = (@{$arrayTypes{$arrayType}})[3];
    $compuMethod = (@{$arrayTypes{$arrayType}})[4];
    my $dataContraints = "";
    if ($arrayDataType eq "real32")
    {
       $dataContraints = "DataConstrC_".$lowerLimit."_0560_".$upperLimit."_0560"; 
    }
    else
    {
        $dataContraints = "DataConstrC_".$lowerLimit."_".$upperLimit;
    }
    
    my $rteBuffer = "";
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$arrayType;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $arrayType."_RTE";
    } 
    elsif($option eq 'option3')
    {
      $rteBuffer = $arrayType;
    }
		else
		{
		  $rteBuffer = $arrayType."_RTE";
		}
		
		
    
    my $swVariable = XML::LibXML::Element->new("SW-VARIABLE");			                # Create SW-VARIABLE
    my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			                    # Create Short Name
    my $category = XML::LibXML::Element->new("CATEGORY");			                    # Create CATEGORY   
    my $swArraySize = XML::LibXML::Element->new("SW-ARRAYSIZE");			            # Create SW-ARRAYSIZE   
    my $arraySizeVF = XML::LibXML::Element->new("VF");                                  # <VF>ArraySize</VF>     
    my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	            # Create #SW-DATA-DEF-PROPS
    my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	            # SW-ADDR-METHOD-REF
    my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                  # SW-BASE-TYPE-REF
    my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");       # SW-CALIBRATION-ACCESS
    my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");              # SW-CODE-SYNTAX-REF
    my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");            # SW-COMPU-METHOD-REF
    my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");              # SW-DATA-CONSTR-REF
    my $swImplPolicy = XML::LibXML::Element->new("SW-IMPL-POLICY");                     # SW-IMPL-POLICY
    my $swVariableAccess = XML::LibXML::Element->new("SW-VARIABLE-ACCESS-IMPL-POLICY"); # SW-VARIABLE-ACCESS-IMPL-POLICY
    
    
    
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("VALUE");
    $arraySizeVF->appendText($arraySize);
    $swAddrMethodref->appendText("intRam");
    $swBaseTypeRef->appendText($dateType);		                              
    $swCalibrationAccess->appendText("READ-ONLY");
    $swCodeSyntaxRef->appendText("MsgA");                   
    $swCompuMethodRef->appendText($compuMethod);
    $swDataConstrRef->appendText($dataContraints);
    $swImplPolicy->appendText("MESSAGE");
    $swVariableAccess->appendText("OPTIMIZED");
          
              if ($counti==1){
        
                my $swDataCons = XML::LibXML::Element->new("SW-DATA-CONSTR");                       # Create SW-DATA-CONSTR
                my $shortNme1 = XML::LibXML::Element->new("SHORT-NAME");                            # Create Short Name
                my $swDataConsRule = XML::LibXML::Element->new("SW-DATA-CONSTR-RULE");              # Create SW-DATA-CONSTR-RULE 
                my $swInternalCons = XML::LibXML::Element->new("SW-INTERNAL-CONSTRS");  
#               my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT INTERVAL-TYPE=\"CLOSED\"");     # Create LOWER-LIMIT  
#               my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT INTERVAL-TYPE=\"CLOSED\"");      # UPPER-LIMIT    
                my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT");     # Create LOWER-LIMIT  
                my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT");      # UPPER-LIMIT    
                $Lowlim->setAttribute('INTERVAL-TYPE',"CLOSED");
                $Uplim->setAttribute('INTERVAL-TYPE',"CLOSED");
                
                $shortNme1->appendText('DataConstrC__0552147483648_0560_2147483647_0560');
                $Lowlim->appendText("-2147483648.0");
                $Uplim->appendText("2147483647.0");
                
                my @swDataConstr = $element->getElementsByTagName("SW-DATA-CONSTRS");
                $swDataConstr[0]->addChild($swDataCons);
                $swDataCons->addChild($shortNme1);
                $swDataCons->addChild($swDataConsRule);
                $swDataConsRule->addChild($swInternalCons);
                $swInternalCons->addChild($Lowlim);
                $swInternalCons->addChild($Uplim);
                
                $counti++;
        }

    
    
    
     
    #Update SW-VARIABLES section
    my @swVariables = $element->getElementsByTagName("SW-VARIABLES");     
    $swVariables[0]->addChild($swVariable);
    $swVariable->addChild($shortNme);
    $swVariable->addChild($category);
    $swVariable->addChild($swArraySize);
    $swArraySize->addChild($arraySizeVF);
    $swVariable->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swImplPolicy);
    $swDataDefProps->addChild($swVariableAccess); 

    if($arrayType ~~ @providerPorts)  
    {
      # Update SW-FEATURE-ELEMENTS section
      my $swVariableRefsArray = XML::LibXML::Element->new("SW-VARIABLE-REFS"); 				     # <SW-VARIABLE-REFS> 
			my $swVariableRefsFct = XML::LibXML::Element->new("SW-VARIABLE-REFS"); 			
      my $swVariableRefArray = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefArray->appendText($rteBuffer);
      my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
      my @swFeatureElementsArray = ($swFeaturesA[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefArray = $swFeatureElementsArray[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefArray)
      {
        $swFeatureSVarRefArray[0]->addChild($swVariableRefArray);       	
      }
      else
      {
			  $swFeatureElementsArray[0]->addChild($swVariableRefsFct);
			  $swVariableRefsFct->addChild($swVariableRefArray);
			}
      
           
      #Update Export Section
      my $swVariableRefExport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefExport->appendText($rteBuffer);
      my @swFeatureElementsExportsArray = ($swFeaturesA[0]->getElementsByTagName("SW-INTERFACE-EXPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefExportsArray = $swFeatureElementsExportsArray[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefExportsArray)
      {
        $swFeatureSVarRefExportsArray[0]->addChild($swVariableRefExport);   
      }   
      else
      {
        $swFeatureElementsExportsArray[0]->addChild($swVariableRefsArray);
        $swVariableRefsArray->addChild($swVariableRefExport);
      }
    }
    elsif($arrayType ~~ @receiverPorts)
    {
      #Update Import Section
      my $swVariableRefImport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefImport->appendText($rteBuffer);
      my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
      my $swVariableRefsArray = XML::LibXML::Element->new("SW-VARIABLE-REFS");
      my @swFeatureElementsImportArray = ($swFeaturesA[0]->getElementsByTagName("SW-INTERFACE-IMPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefImportsArray = $swFeatureElementsImportArray[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefImportsArray)
      {
        $swFeatureSVarRefImportsArray[0]->addChild($swVariableRefImport);   
      }   
      else
      {
        $swFeatureElementsImportArray[0]->addChild($swVariableRefsArray);
        $swVariableRefsArray->addChild($swVariableRefImport);
      }
    }
  }   
#########################################################################################################################################################################################################
  #Handling Parameter Array Types
  foreach my $arrayType(keys %parmArrayTypes) 
  {
    print "Adding Parameter Element: $arrayType\n";	
    #get the data type
    my $dateType = (@{$parmArrayTypes{$arrayType}})[0];
    my $arraySize = (@{$parmArrayTypes{$arrayType}})[1];
     
    #Create W-DATA-CONSTR-REF 
    my $lowerLimit = (@{$parmArrayTypes{$arrayType}})[2];
    if($lowerLimit < 0) 
    {
      $lowerLimit *= -1 ;
      $lowerLimit = "_055".$lowerLimit; 
    }
    my $upperLimit = (@{$parmArrayTypes{$arrayType}})[3];
    $compuMethod = (@{$parmArrayTypes{$arrayType}})[4];
    my $dataContraints = "";
    if ($arrayDataType eq "real32")
    {
       $dataContraints = "DataConstrC_".$lowerLimit."_0560_".$upperLimit."_0560"; 
    }
    else
    {
      $dataContraints = "DataConstrC_".$lowerLimit."_".$upperLimit;
    }

    my $rteBuffer = "";
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$arrayType;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $arrayType."_RTE";
    } 
    elsif($option eq 'option3')
    {
      $rteBuffer = $arrayType;
    }
    else
	  {
		  $rteBuffer = $arrayType."_RTE";
	  }
	  
    
    my $swCalprm = XML::LibXML::Element->new("SW-CALPRM");			                    # Create SW-CALPRM
    my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			                    # Create Short Name
    my $category = XML::LibXML::Element->new("CATEGORY");			                    # Create CATEGORY   
    my $swArraySize = XML::LibXML::Element->new("SW-ARRAYSIZE");			            # Create SW-ARRAYSIZE   
    my $arraySizeVF = XML::LibXML::Element->new("VF");                                  # <VF>ArraySize</VF>     
    my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	            # SW-ADDR-METHOD-REF
    my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	            # SW-ADDR-METHOD-REF
    my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                  # SW-BASE-TYPE-REF
    my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");       # SW-CALIBRATION-ACCESS
    my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");              # SW-CODE-SYNTAX-REF
    my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");            # SW-COMPU-METHOD-REF
    my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");              # SW-DATA-CONSTR-REF
    my $swRecordLayout = XML::LibXML::Element->new("SW-RECORD-LAYOUT-REF");             # SW-RECORD-LAYOUT-REF
     
     
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("VALUE");
    $arraySizeVF->appendText($arraySize);
    $swAddrMethodref->appendText("DataFast");
    $swBaseTypeRef->appendText($dateType);		                              
    $swCalibrationAccess->appendText("READ-WRITE");
    $swCodeSyntaxRef->appendText("Val");                   
    $swCompuMethodRef->appendText($compuMethod);
    $swDataConstrRef->appendText($dataContraints);
    my $swRecordLayoutName=getRecordLayout($dateType);
    $swRecordLayout->appendText($swRecordLayoutName);
       
         if ($counti==1){
        
                my $swDataCons = XML::LibXML::Element->new("SW-DATA-CONSTR");                       # Create SW-DATA-CONSTR
                my $shortNme1 = XML::LibXML::Element->new("SHORT-NAME");                            # Create Short Name
                my $swDataConsRule = XML::LibXML::Element->new("SW-DATA-CONSTR-RULE");              # Create SW-DATA-CONSTR-RULE 
                my $swInternalCons = XML::LibXML::Element->new("SW-INTERNAL-CONSTRS");  
#               my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT INTERVAL-TYPE=\"CLOSED\"");     # Create LOWER-LIMIT  
#               my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT INTERVAL-TYPE=\"CLOSED\"");      # UPPER-LIMIT    
                my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT");     # Create LOWER-LIMIT  
                my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT");      # UPPER-LIMIT   
                $Lowlim->setAttribute('INTERVAL-TYPE',"CLOSED");
                $Uplim->setAttribute('INTERVAL-TYPE',"CLOSED");
                $shortNme1->appendText('DataConstrC__0552147483648_0560_2147483647_0560');
                $Lowlim->appendText("-2147483648.0");
                $Uplim->appendText("2147483647.0");
                
                my @swDataConstr = $element->getElementsByTagName("SW-DATA-CONSTRS");
                $swDataConstr[0]->addChild($swDataCons);
                $swDataCons->addChild($shortNme1);
                $swDataCons->addChild($swDataConsRule);
                $swDataConsRule->addChild($swInternalCons);
                $swInternalCons->addChild($Lowlim);
                $swInternalCons->addChild($Uplim);
                
                $counti++;
        }

     
     
    #Update SW-CALPRM section
    my @swVariables = $element->getElementsByTagName("SW-CALPRMS");     
    $swVariables[0]->addChild($swCalprm);
    $swCalprm->addChild($shortNme);
    $swCalprm->addChild($category);
    $swCalprm->addChild($swArraySize);
    $swArraySize->addChild($arraySizeVF);
    $swCalprm->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swRecordLayout); 
	
	  # Update SW-INSTANCE section
	  my $swInstance = XML::LibXML::Element->new("SW-INSTANCE");		                            # Create SW-INSTANCE
	  my $shortName = XML::LibXML::Element->new("SHORT-NAME");			                        # Create SHORT-NAME
    my $catgory = XML::LibXML::Element->new("CATEGORY");			                            # Create CATEGORY 
	  my $swFeatureReference = XML::LibXML::Element->new("SW-FEATURE-REF");	                    # Create SW-FEATURE-REF
	  my $swInstancePropsVariants = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANTS");		# Create SW-INSTANCE-PROPS-VARIANTS             
	  my $swInsPropsVariant = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANT");		        # Create SW-INSTANCE-PROPS-VARIANT       
	  my $swAxisConts = XML::LibXML::Element->new("SW-AXIS-CONTS");		                        # Create SW-AXIS-CONTS
	  my $swAxisCont = XML::LibXML::Element->new("SW-AXIS-CONT");		                            # Create SW-AXIS-CONT
	  my $swAxisIndex = XML::LibXML::Element->new("SW-AXIS-INDEX");		                        # Create SW-AXIS-INDEX
	  my $swValuesCoded = XML::LibXML::Element->new("SW-VALUES-CODED");		                    # Create SW-VALUES-CODED
	  my $v = XML::LibXML::Element->new("V");		                         		                # Create Value Tag

	  # Update Node values
	  $shortName->appendText($rteBuffer);
    $catgory->appendText("VALUE");
	  $swFeatureReference->appendText($appSWCName);
	  $v->appendText("0");		                              
	  $swAxisIndex->appendText("0");
	
	  my @swVariablesP = $element->getElementsByTagName("SW-INSTANCE-TREE");     
    $swVariablesP[0]->addChild($swInstance);
    $swInstance->addChild($shortName);
    $swInstance->addChild($catgory);
    $swInstance->addChild($swFeatureReference);
    $swInstance->addChild($swInstancePropsVariants);
    $swInstancePropsVariants->addChild($swInsPropsVariant);
    $swInsPropsVariant->addChild($swAxisConts);
    $swAxisConts->addChild($swAxisCont);
    $swAxisCont->addChild($swAxisIndex);
    $swAxisCont->addChild($swValuesCoded);
    $swValuesCoded->addChild($v);
	 
	  # Update FCT values
	  my $swVariableRefsFct = XML::LibXML::Element->new("SW-CALPRM-REFS"); 			         # Create SW-CALPRM-REFS tag
    my $swVariableRefArray = XML::LibXML::Element->new("SW-CALPRM-REF");			         # Create SW-CALPRM-REF tag
    $swVariableRefArray->appendText($rteBuffer);
    my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
    my @swFeatureElementsArray = ($swFeaturesA[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
    my @swFeatureSVarRefArray = $swFeatureElementsArray[0]->getChildrenByTagName("SW-CALPRM-REFS");
    if(@swFeatureSVarRefArray)
    {
	    $swFeatureSVarRefArray[0]->addChild($swVariableRefArray);       	
    }
    else
    {
		  $swFeatureElementsArray[0]->addChild($swVariableRefsFct);
		  $swVariableRefsFct->addChild($swVariableRefArray);
	  }
  }
  ######################################################################################################################################################################################################### 
  #Handling Parameter real32 Types
  foreach my $real32Type(keys %parmReal32Types) 
  {
      print "Adding Integer Parameter Element: $real32Type\n";
    $compuMethod = (@{$parmReal32Types{$real32Type}})[3];  
         
    #get the data type
    my $dateType = (@{$parmReal32Types{$real32Type}})[0];
     
    #Create W-DATA-CONSTR-REF 
    my $lowerLimit = (@{$parmReal32Types{$real32Type}})[1];
    if($lowerLimit < 0) 
    { 
      $lowerLimit *= -1 ;
      $lowerLimit = "_055".$lowerLimit; 
    }
    my $upperLimit = (@{$parmReal32Types{$real32Type}})[2];
    my $dataContraintsreal = "DataConstrC_".$lowerLimit."_0560_".$upperLimit."_0560";     
    my $rteBuffer ="";
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$real32Type;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $real32Type."_RTE";
    }
    elsif($option eq 'option3')
    {
          $rteBuffer = $real32Type;
      }
      else
    {
        $rteBuffer = $real32Type."_RTE";
      }
    
      if ($counti==1){
    
            my $swDataCons = XML::LibXML::Element->new("SW-DATA-CONSTR");                       # Create SW-DATA-CONSTR
            my $shortNme1 = XML::LibXML::Element->new("SHORT-NAME");                            # Create Short Name
            my $swDataConsRule = XML::LibXML::Element->new("SW-DATA-CONSTR-RULE");              # Create SW-DATA-CONSTR-RULE 
            my $swInternalCons = XML::LibXML::Element->new("SW-INTERNAL-CONSTRS");  
#               my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT INTERVAL-TYPE=\"CLOSED\"");     # Create LOWER-LIMIT  
#               my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT INTERVAL-TYPE=\"CLOSED\"");      # UPPER-LIMIT    
                my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT");     # Create LOWER-LIMIT  
                my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT");      # UPPER-LIMIT   
                $Lowlim->setAttribute('INTERVAL-TYPE',"CLOSED");
                $Uplim->setAttribute('INTERVAL-TYPE',"CLOSED");
            $shortNme1->appendText('DataConstrC__0552147483648_0560_2147483647_0560');
            $Lowlim->appendText("-2147483648.0");
            $Uplim->appendText("2147483647.0");
            
            my @swDataConstr = $element->getElementsByTagName("SW-DATA-CONSTRS");
            $swDataConstr[0]->addChild($swDataCons);
            $swDataCons->addChild($shortNme1);
            $swDataCons->addChild($swDataConsRule);
            $swDataConsRule->addChild($swInternalCons);
            $swInternalCons->addChild($Lowlim);
            $swInternalCons->addChild($Uplim);
            
            $counti++;
    }

     
      my $swCalPrm = XML::LibXML::Element->new("SW-CALPRM");                                 # Create SW-CALPRM
      my $shortNme = XML::LibXML::Element->new("SHORT-NAME");                                # Create Short Name
      my $category = XML::LibXML::Element->new("CATEGORY");                              # Create CATEGORY     
      my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");               # Create #SW-DATA-DEF-PROPS
      my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");                 # SW-ADDR-METHOD-REF
      my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                   # SW-BASE-TYPE-REF
      my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");        # SW-CALIBRATION-ACCESS
      my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");               # SW-CODE-SYNTAX-REF
      my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");             # SW-COMPU-METHOD-REF
      my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");               # SW-DATA-CONSTR-REF
      my $swRecordLayout = XML::LibXML::Element->new("SW-RECORD-LAYOUT-REF");              # SW-RECORD-LAYOUT-REF
     
     
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("VALUE");
    $swAddrMethodref->appendText("DataFast");
    $swBaseTypeRef->appendText($dateType);                                    
    $swCalibrationAccess->appendText("READ-WRITE");
    $swCodeSyntaxRef->appendText("Val");                   
    $swCompuMethodRef->appendText($compuMethod);
    $swDataConstrRef->appendText($dataContraintsreal);
    my $swRecordLayoutName=getRecordLayout($dateType);
    $swRecordLayout->appendText($swRecordLayoutName);    
     
    #Update SW-CALPRM section
    my @swVariablesI = $element->getElementsByTagName("SW-CALPRMS");     
    $swVariablesI[0]->addChild($swCalPrm);
    $swCalPrm->addChild($shortNme);
    $swCalPrm->addChild($category);
    $swCalPrm->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swRecordLayout); 

      # Update SW-INSTANCE section
      my $swInstance = XML::LibXML::Element->new("SW-INSTANCE");                                     # Create SW-CALPRM
      my $shortName = XML::LibXML::Element->new("SHORT-NAME");                                   # Create SHORT-NAME            
    my $catgory = XML::LibXML::Element->new("CATEGORY");                                         # Create CATEGORY
      my $swFeatureReference = XML::LibXML::Element->new("SW-FEATURE-REF");                      # Create SW-FEATURE-REF    
      my $swInstancePropsVariants = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANTS");         # Create SW-INSTANCE-PROPS-VARIANTS
      my $swInsPropsVariant = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANT");                # Create SW-INSTANCE-PROPS-VARIANT       
      my $swAxisConts = XML::LibXML::Element->new("SW-AXIS-CONTS");                              # Create SW-AXIS-CONTS
      my $swAxisCont = XML::LibXML::Element->new("SW-AXIS-CONT");                                    # Create SW-AXIS-CONT
      my $swAxisIndex = XML::LibXML::Element->new("SW-AXIS-INDEX");                              # Create SW-AXIS-INDEX
      my $swValuesCoded = XML::LibXML::Element->new("SW-VALUES-CODED");                          # Create SW-VALUES-CODED                            
      my $v = XML::LibXML::Element->new("V");                                                        # Create VALUE tag
    
      # Update Node values
      $shortName->appendText($rteBuffer);
    $catgory->appendText("VALUE");
      $swFeatureReference->appendText($appSWCName);
      $v->appendText("0");                                    
      $swAxisIndex->appendText("0");

      my @swVariablesP = $element->getElementsByTagName("SW-INSTANCE-TREE");     
      $swVariablesP[0]->addChild($swInstance);
      $swInstance->addChild($shortName);
      $swInstance->addChild($catgory);
      $swInstance->addChild($swFeatureReference);
      $swInstance->addChild($swInstancePropsVariants);
      $swInstancePropsVariants->addChild($swInsPropsVariant);
      $swInsPropsVariant->addChild($swAxisConts);
      $swAxisConts->addChild($swAxisCont);
      $swAxisCont->addChild($swAxisIndex);
      $swAxisCont->addChild($swValuesCoded);
      $swValuesCoded->addChild($v);  
    
      #Update FCT
      my $swVariableRefsFct = XML::LibXML::Element->new("SW-CALPRM-REFS");                   # Create SW-CALPRM-REFS tag
    my $swVariableRefArray = XML::LibXML::Element->new("SW-CALPRM-REF");                     # Create SW-CALPRM-REF tag
    $swVariableRefArray->appendText($rteBuffer);
    my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
    my @swFeatureElementsArray = ($swFeaturesA[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
    my @swFeatureSVarRefArray = $swFeatureElementsArray[0]->getChildrenByTagName("SW-CALPRM-REFS");
    if(@swFeatureSVarRefArray)
    {
      $swFeatureSVarRefArray[0]->addChild($swVariableRefArray);         
    }
    else
    {
          $swFeatureElementsArray[0]->addChild($swVariableRefsFct);
          $swVariableRefsFct->addChild($swVariableRefArray);
      }  
  }
  ######################################################################################################################################################################################################### 
  #Handling real32 Types    
  foreach my $real32Type(keys %real32Types) 
  {
       print "Adding Data Element: $real32Type\n";
     $compuMethod = (@{$real32Types{$real32Type}})[3];  
         
     #get the data type
     my $dateType = (@{$real32Types{$real32Type}})[0];
     
     #Create W-DATA-CONSTR-REF 
     my $lowerLimit = (@{$real32Types{$real32Type}})[1];
     if($lowerLimit < 0) 
     { 
       $lowerLimit *= -1 ;
       $lowerLimit = "_055".$lowerLimit; 
     }
     my $upperLimit = (@{$real32Types{$real32Type}})[2];
     my $dataContraintsreal = "DataConstrC_".$lowerLimit."_0560_".$upperLimit."_0560";     
     my $rteBuffer ="";
     if($option eq 'option1')
     {
       $rteBuffer = "Rte_".$real32Type;    
     }
     elsif($option eq 'option2')
     {
       $rteBuffer = $real32Type."_RTE";
     }
     elsif($option eq 'option3')
     {
           $rteBuffer = $real32Type;
         }
         else
     {
           $rteBuffer = $real32Type."_RTE";
         }
     

        if ($counti==1){
    
            my $swDataCons = XML::LibXML::Element->new("SW-DATA-CONSTR");                       # Create SW-DATA-CONSTR
            my $shortNme1 = XML::LibXML::Element->new("SHORT-NAME");                            # Create Short Name
            my $swDataConsRule = XML::LibXML::Element->new("SW-DATA-CONSTR-RULE");              # Create SW-DATA-CONSTR-RULE 
            my $swInternalCons = XML::LibXML::Element->new("SW-INTERNAL-CONSTRS");  
#               my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT INTERVAL-TYPE=\"CLOSED\"");     # Create LOWER-LIMIT  
#               my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT INTERVAL-TYPE=\"CLOSED\"");      # UPPER-LIMIT    
                my $Lowlim = XML::LibXML::Element->new("LOWER-LIMIT");     # Create LOWER-LIMIT  
                my $Uplim = XML::LibXML::Element->new("UPPER-LIMIT");      # UPPER-LIMIT   
                $Lowlim->setAttribute('INTERVAL-TYPE',"CLOSED");
                $Uplim->setAttribute('INTERVAL-TYPE',"CLOSED");
            $shortNme1->appendText('DataConstrC__0552147483648_0560_2147483647_0560');
                $Lowlim->appendText("-2147483648.0");
                $Uplim->appendText("2147483647.0");
            
            my @swDataConstr = $element->getElementsByTagName("SW-DATA-CONSTRS");
            $swDataConstr[0]->addChild($swDataCons);
            $swDataCons->addChild($shortNme1);
            $swDataCons->addChild($swDataConsRule);
            $swDataConsRule->addChild($swInternalCons);
            $swInternalCons->addChild($Lowlim);
            $swInternalCons->addChild($Uplim);
            
            $counti++;
    }

    
     my $swVariable = XML::LibXML::Element->new("SW-VARIABLE");                              # Create SW-VARIABLE
     my $shortNme = XML::LibXML::Element->new("SHORT-NAME");                                   # Create Short Name
     my $category = XML::LibXML::Element->new("CATEGORY");                                   # Create CATEGORY     
     my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");                  # Create #SW-DATA-DEF-PROPS
     my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");              # SW-ADDR-METHOD-REF
     my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                  # SW-BASE-TYPE-REF
     my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");       # SW-CALIBRATION-ACCESS
     my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");              # SW-CODE-SYNTAX-REF
     my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");            # SW-COMPU-METHOD-REF
     my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");              # SW-DATA-CONSTR-REF
     my $swImplPolicy = XML::LibXML::Element->new("SW-IMPL-POLICY");                     # SW-IMPL-POLICY
     my $swVariableAccess = XML::LibXML::Element->new("SW-VARIABLE-ACCESS-IMPL-POLICY"); # SW-VARIABLE-ACCESS-IMPL-POLICY
     
     
     # Update Node values
     $shortNme->appendText($rteBuffer);
     $category->appendText("VALUE");
     $swAddrMethodref->appendText("intRam");
     $swBaseTypeRef->appendText($dateType);                                   
     $swCalibrationAccess->appendText("READ-ONLY");
     $swCodeSyntaxRef->appendText("Msg");                   #
     $swCompuMethodRef->appendText($compuMethod);
     $swDataConstrRef->appendText($dataContraintsreal);
     $swImplPolicy->appendText("MESSAGE");
     $swVariableAccess->appendText("OPTIMIZED");
     
     #Update SW-VARIABLES section
     my @swVariablesI = $element->getElementsByTagName("SW-VARIABLES");     
     $swVariablesI[0]->addChild($swVariable);
     $swVariable->addChild($shortNme);
     $swVariable->addChild($category);
     $swVariable->addChild($swDataDefProps);
     $swDataDefProps->addChild($swAddrMethodref);
     $swDataDefProps->addChild($swBaseTypeRef);
     $swDataDefProps->addChild($swCalibrationAccess);
     $swDataDefProps->addChild($swCodeSyntaxRef);
     $swDataDefProps->addChild($swCompuMethodRef);
     $swDataDefProps->addChild($swDataConstrRef);
     $swDataDefProps->addChild($swImplPolicy);
     $swDataDefProps->addChild($swVariableAccess);  
     
     # Update SW-FEATURE-ELEMENTS section
     if($real32Type ~~ @providerPorts)
     {
       my $swVariableRefs = XML::LibXML::Element->new("SW-VARIABLE-REFS");                 # <SW-VARIABLE-REFS> 
             my $swVariableRefsFct = XML::LibXML::Element->new("SW-VARIABLE-REFS");
       my $swVariableRef = XML::LibXML::Element->new("SW-VARIABLE-REF");                     # Create SW-VARIABLE-REF tag
       $swVariableRef->appendText($rteBuffer);
       my @swFeaturesI = ($element->getElementsByTagName("SW-FEATURE"));
       my @swFeatureElements = ($swFeaturesI[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
       my @swFeatureSVarRefI = $swFeatureElements[0]->getChildrenByTagName("SW-VARIABLE-REFS");
       if(@swFeatureSVarRefI)
       { 
         $swFeatureSVarRefI[0]->appendChild($swVariableRef);              
       }            
             else
             {
               $swFeatureElements[0]->addChild($swVariableRefsFct);
               $swVariableRefsFct->addChild($swVariableRef);               
             }
     
       #Update Export Section
       my $swVariableRefExport = XML::LibXML::Element->new("SW-VARIABLE-REF");                   # Create SW-VARIABLE-REF tag
       $swVariableRefExport->appendText($rteBuffer);
       my @swFeatureElementsExportsI = ($swFeaturesI[0]->getElementsByTagName("SW-INTERFACE-EXPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
       my @swFeatureSVarRefExportsI = $swFeatureElementsExportsI[0]->getChildrenByTagName("SW-VARIABLE-REFS");
       if(@swFeatureSVarRefExportsI)
       {
         $swFeatureSVarRefExportsI[0]->addChild($swVariableRefExport);   
       }
       else
       {
         $swFeatureElementsExportsI[0]->addChild($swVariableRefs);
         $swVariableRefs->addChild($swVariableRefExport);
       }          
    }
    elsif($real32Type ~~ @receiverPorts)
    {
      #Update Import Section
      my $swVariableRefImport = XML::LibXML::Element->new("SW-VARIABLE-REF");                    # Create SW-VARIABLE-REF tag
      $swVariableRefImport->appendText($rteBuffer);
      my @swFeaturesI = ($element->getElementsByTagName("SW-FEATURE"));
      my $swVariableRefs = XML::LibXML::Element->new("SW-VARIABLE-REFS");
      my @swFeatureElementsImportI = ($swFeaturesI[0]->getElementsByTagName("SW-INTERFACE-IMPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefImportI = $swFeatureElementsImportI[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefImportI)
      {
        $swFeatureSVarRefImportI[0]->addChild($swVariableRefImport);   
      }   
      else
      {
        $swFeatureElementsImportI[0]->addChild($swVariableRefs);
        $swVariableRefs->addChild($swVariableRefImport);
      }
    }    
  }
  #########################################################################################################################################################################################################  
  #Handling Parameter Integer Types
  foreach my $intType(keys %parmIntTypes) 
  {
	  print "Adding Integer Parameter Element: $intType\n";
    $compuMethod = (@{$parmIntTypes{$intType}})[3];  
		 
    #get the data type
    my $dateType = (@{$parmIntTypes{$intType}})[0];
     
    #Create W-DATA-CONSTR-REF 
    my $lowerLimit = (@{$parmIntTypes{$intType}})[1];
    if($lowerLimit < 0) 
    { 
      $lowerLimit *= -1 ;
      $lowerLimit = "_055".$lowerLimit; 
    }
    my $upperLimit = (@{$parmIntTypes{$intType}})[2];
    my $dataContraints = "DataConstrC_".$lowerLimit."_".$upperLimit;     
    my $rteBuffer ="";
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$intType;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $intType."_RTE";
    }
    elsif($option eq 'option3')
    {
		  $rteBuffer = $intType;
	  }
	  else
    {
	    $rteBuffer = $intType."_RTE";
	  }
     
	  my $swCalPrm = XML::LibXML::Element->new("SW-CALPRM");			                     # Create SW-CALPRM
	  my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			                     # Create Short Name
	  my $category = XML::LibXML::Element->new("CATEGORY");			                     # Create CATEGORY     
	  my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	             # Create #SW-DATA-DEF-PROPS
	  my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	             # SW-ADDR-METHOD-REF
	  my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                   # SW-BASE-TYPE-REF
	  my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");        # SW-CALIBRATION-ACCESS
	  my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");               # SW-CODE-SYNTAX-REF
	  my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");             # SW-COMPU-METHOD-REF
	  my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");               # SW-DATA-CONSTR-REF
	  my $swRecordLayout = XML::LibXML::Element->new("SW-RECORD-LAYOUT-REF");              # SW-RECORD-LAYOUT-REF
     
     
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("VALUE");
    $swAddrMethodref->appendText("DataFast");
    $swBaseTypeRef->appendText($dateType);		                              
    $swCalibrationAccess->appendText("READ-WRITE");
    $swCodeSyntaxRef->appendText("Val");                   
    $swCompuMethodRef->appendText($compuMethod);
    $swDataConstrRef->appendText($dataContraints);
    my $swRecordLayoutName=getRecordLayout($dateType);
    $swRecordLayout->appendText($swRecordLayoutName);    
     
    #Update SW-CALPRM section
    my @swVariablesI = $element->getElementsByTagName("SW-CALPRMS");     
    $swVariablesI[0]->addChild($swCalPrm);
    $swCalPrm->addChild($shortNme);
    $swCalPrm->addChild($category);
    $swCalPrm->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swRecordLayout); 

	  # Update SW-INSTANCE section
	  my $swInstance = XML::LibXML::Element->new("SW-INSTANCE");	                                 # Create SW-CALPRM
	  my $shortName = XML::LibXML::Element->new("SHORT-NAME");	                                 # Create SHORT-NAME	        
    my $catgory = XML::LibXML::Element->new("CATEGORY");		                                 # Create CATEGORY
	  my $swFeatureReference = XML::LibXML::Element->new("SW-FEATURE-REF");		                 # Create SW-FEATURE-REF    
	  my $swInstancePropsVariants = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANTS");	     # Create SW-INSTANCE-PROPS-VARIANTS
	  my $swInsPropsVariant = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANT");	             # Create SW-INSTANCE-PROPS-VARIANT       
	  my $swAxisConts = XML::LibXML::Element->new("SW-AXIS-CONTS");	                             # Create SW-AXIS-CONTS
	  my $swAxisCont = XML::LibXML::Element->new("SW-AXIS-CONT");	                                 # Create SW-AXIS-CONT
	  my $swAxisIndex = XML::LibXML::Element->new("SW-AXIS-INDEX");	                             # Create SW-AXIS-INDEX
	  my $swValuesCoded = XML::LibXML::Element->new("SW-VALUES-CODED");	                         # Create SW-VALUES-CODED                            
	  my $v = XML::LibXML::Element->new("V");	                                                     # Create VALUE tag
	
	  # Update Node values
	  $shortName->appendText($rteBuffer);
    $catgory->appendText("VALUE");
	  $swFeatureReference->appendText($appSWCName);
	  $v->appendText("0");		                              
	  $swAxisIndex->appendText("0");

	  my @swVariablesP = $element->getElementsByTagName("SW-INSTANCE-TREE");     
	  $swVariablesP[0]->addChild($swInstance);
	  $swInstance->addChild($shortName);
	  $swInstance->addChild($catgory);
	  $swInstance->addChild($swFeatureReference);
	  $swInstance->addChild($swInstancePropsVariants);
	  $swInstancePropsVariants->addChild($swInsPropsVariant);
	  $swInsPropsVariant->addChild($swAxisConts);
	  $swAxisConts->addChild($swAxisCont);
	  $swAxisCont->addChild($swAxisIndex);
	  $swAxisCont->addChild($swValuesCoded);
	  $swValuesCoded->addChild($v);	 
	
	  #Update FCT
	  my $swVariableRefsFct = XML::LibXML::Element->new("SW-CALPRM-REFS"); 			         # Create SW-CALPRM-REFS tag
    my $swVariableRefArray = XML::LibXML::Element->new("SW-CALPRM-REF");			         # Create SW-CALPRM-REF tag
    $swVariableRefArray->appendText($rteBuffer);
    my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
    my @swFeatureElementsArray = ($swFeaturesA[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
    my @swFeatureSVarRefArray = $swFeatureElementsArray[0]->getChildrenByTagName("SW-CALPRM-REFS");
    if(@swFeatureSVarRefArray)
    {
      $swFeatureSVarRefArray[0]->addChild($swVariableRefArray);       	
    }
    else
    {
		  $swFeatureElementsArray[0]->addChild($swVariableRefsFct);
		  $swVariableRefsFct->addChild($swVariableRefArray);
	  }  
  }
  #########################################################################################################################################################################################################
  #Handling Parameter Boolean types
  foreach my $boolType(@boolParmElements) 
  {
    print "Adding Parameter Element: $boolType\n";  
    my $dataContraints = "DataConstrC_0_1";
    my $rteBuffer = "";     
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$boolType;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $boolType."_RTE";
    } 
    elsif($option eq 'option3')
    {
		  $rteBuffer = $boolType;
	  }
	  else
    {
		  $rteBuffer = $boolType."_RTE";
	  }
    my $swCalPrm = XML::LibXML::Element->new("SW-CALPRM");			                   # Create SW-SW-CALPRM
    my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			                   # Create Short Name
    my $category = XML::LibXML::Element->new("CATEGORY");			                   # Create CATEGORY     
    my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	           # Create #SW-DATA-DEF-PROPS
    my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	           # SW-ADDR-METHOD-REF
    my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                 # SW-BASE-TYPE-REF
    my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");      # SW-CALIBRATION-ACCESS
    my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");             # SW-CODE-SYNTAX-REF
    my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");           # SW-COMPU-METHOD-REF
    my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");             # SW-DATA-CONSTR-REF
    my $swRecordLayout = XML::LibXML::Element->new("SW-RECORD-LAYOUT-REF");            # SW-RECORD-LAYOUT-REF
     
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("VALUE");
    $swAddrMethodref->appendText("DataFast");
    $swBaseTypeRef->appendText("bool");		                              
    $swCalibrationAccess->appendText("READ-WRITE");
    $swCodeSyntaxRef->appendText("Val");                   
    $swCompuMethodRef->appendText("B_TRUE");
    $swDataConstrRef->appendText($dataContraints);
    $swRecordLayout->appendText("RB_Val_Wu8");
     
    my @swVariablesB = $element->getElementsByTagName("SW-CALPRMS");     
    $swVariablesB[0]->addChild($swCalPrm);
    $swCalPrm->addChild($shortNme);
    $swCalPrm->addChild($category);
    $swCalPrm->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swRecordLayout);   
  
	  # Update SW-INSTANCE section
	  my $swInstance = XML::LibXML::Element->new("SW-INSTANCE");	                                  # Create SW-INSTANCE
	  my $shortName = XML::LibXML::Element->new("SHORT-NAME");			                          # Create SHORT-NAME
    my $catgory = XML::LibXML::Element->new("CATEGORY");			                              # Create CATEGORY  
	  my $swFeatureReference = XML::LibXML::Element->new("SW-FEATURE-REF");	                      # Create SW-FEATURE-REF
	  my $swInstancePropsVariants = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANTS");        # Create SW-INSTANCE-PROPS-VARIANTS
	  my $swInsPropsVariant = XML::LibXML::Element->new("SW-INSTANCE-PROPS-VARIANT");               # Create SW-INSTANCE-PROPS-VARIANT
	  my $swAxisConts = XML::LibXML::Element->new("SW-AXIS-CONTS");                                 # Create SW-AXIS-CONTS
	  my $swAxisCont = XML::LibXML::Element->new("SW-AXIS-CONT");                                   # Create SW-AXIS-CONT
	  my $swAxisIndex = XML::LibXML::Element->new("SW-AXIS-INDEX");                                 # Create SW-AXIS-INDEX
	  my $swValuesCoded = XML::LibXML::Element->new("SW-VALUES-CODED");                             # Create SW-VALUES-CODED
	  my $v = XML::LibXML::Element->new("V");

	  # Update Node values
	  $shortName->appendText($rteBuffer);
    $catgory->appendText("VALUE");
	  $swFeatureReference->appendText($appSWCName);
	  $v->appendText("0");		                              
	  $swAxisIndex->appendText("0");

	  my @swVariablesP = $element->getElementsByTagName("SW-INSTANCE-TREE");     
	  $swVariablesP[0]->addChild($swInstance);
	  $swInstance->addChild($shortName);
	  $swInstance->addChild($catgory);
	  $swInstance->addChild($swFeatureReference);
	  $swInstance->addChild($swInstancePropsVariants);
	  $swInstancePropsVariants->addChild($swInsPropsVariant);
	  $swInsPropsVariant->addChild($swAxisConts);
	  $swAxisConts->addChild($swAxisCont);
	  $swAxisCont->addChild($swAxisIndex);
	  $swAxisCont->addChild($swValuesCoded);
	  $swValuesCoded->addChild($v);
	
    #Update FCT
	  my $swVariableRefsFct = XML::LibXML::Element->new("SW-CALPRM-REFS"); 			              # Create SW-CALPRM-REFS tag
    my $swVariableRefArray = XML::LibXML::Element->new("SW-CALPRM-REF");			              # Create SW-CALPRM-REF tag
    $swVariableRefArray->appendText($rteBuffer);
    my @swFeaturesA = ($element->getElementsByTagName("SW-FEATURE"));
    my @swFeatureElementsArray = ($swFeaturesA[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
    my @swFeatureSVarRefArray = $swFeatureElementsArray[0]->getChildrenByTagName("SW-CALPRM-REFS");
    if(@swFeatureSVarRefArray)
    {
      $swFeatureSVarRefArray[0]->addChild($swVariableRefArray);       	
    }
    else
    {
		  $swFeatureElementsArray[0]->addChild($swVariableRefsFct);
		  $swVariableRefsFct->addChild($swVariableRefArray);
	  }
  }
#########################################################################################################################################################################################################  
  #Handling Integer Types    
  foreach my $intType(keys %intTypes) 
  {
	   print "Adding Data Element: $intType\n";
     $compuMethod = (@{$intTypes{$intType}})[3];  
		 
     #get the data type
     my $dateType = (@{$intTypes{$intType}})[0];
     
     #Create W-DATA-CONSTR-REF 
     my $lowerLimit = (@{$intTypes{$intType}})[1];
     if($lowerLimit < 0) 
     { 
       $lowerLimit *= -1 ;
       $lowerLimit = "_055".$lowerLimit; 
     }
     my $upperLimit = (@{$intTypes{$intType}})[2];
     my $dataContraints = "DataConstrC_".$lowerLimit."_".$upperLimit;     
     my $rteBuffer ="";
     if($option eq 'option1')
     {
       $rteBuffer = "Rte_".$intType;    
     }
     elsif($option eq 'option2')
     {
       $rteBuffer = $intType."_RTE";
     }
     elsif($option eq 'option3')
     {
		   $rteBuffer = $intType;
		 }
		 else
     {
		   $rteBuffer = $intType."_RTE";
		 }
     
     my $swVariable = XML::LibXML::Element->new("SW-VARIABLE");			                     # Create SW-VARIABLE
     my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			                       # Create Short Name
     my $category = XML::LibXML::Element->new("CATEGORY");			                         # Create CATEGORY     
     my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	               # Create #SW-DATA-DEF-PROPS
     my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	             # SW-ADDR-METHOD-REF
     my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                  # SW-BASE-TYPE-REF
     my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");       # SW-CALIBRATION-ACCESS
     my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");              # SW-CODE-SYNTAX-REF
     my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");            # SW-COMPU-METHOD-REF
     my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");              # SW-DATA-CONSTR-REF
     my $swImplPolicy = XML::LibXML::Element->new("SW-IMPL-POLICY");                     # SW-IMPL-POLICY
     my $swVariableAccess = XML::LibXML::Element->new("SW-VARIABLE-ACCESS-IMPL-POLICY"); # SW-VARIABLE-ACCESS-IMPL-POLICY
     
     
     # Update Node values
     $shortNme->appendText($rteBuffer);
     $category->appendText("VALUE");
     $swAddrMethodref->appendText("intRam");
     $swBaseTypeRef->appendText($dateType);		                              
     $swCalibrationAccess->appendText("READ-ONLY");
     $swCodeSyntaxRef->appendText("Msg");                   #
     $swCompuMethodRef->appendText($compuMethod);
     $swDataConstrRef->appendText($dataContraints);
     $swImplPolicy->appendText("MESSAGE");
     $swVariableAccess->appendText("OPTIMIZED");
     
     #Update SW-VARIABLES section
     my @swVariablesI = $element->getElementsByTagName("SW-VARIABLES");     
     $swVariablesI[0]->addChild($swVariable);
     $swVariable->addChild($shortNme);
     $swVariable->addChild($category);
     $swVariable->addChild($swDataDefProps);
     $swDataDefProps->addChild($swAddrMethodref);
     $swDataDefProps->addChild($swBaseTypeRef);
     $swDataDefProps->addChild($swCalibrationAccess);
     $swDataDefProps->addChild($swCodeSyntaxRef);
     $swDataDefProps->addChild($swCompuMethodRef);
     $swDataDefProps->addChild($swDataConstrRef);
     $swDataDefProps->addChild($swImplPolicy);
     $swDataDefProps->addChild($swVariableAccess);  
     
     # Update SW-FEATURE-ELEMENTS section
     if($intType ~~ @providerPorts)
     {
       my $swVariableRefs = XML::LibXML::Element->new("SW-VARIABLE-REFS"); 			       # <SW-VARIABLE-REFS> 
			 my $swVariableRefsFct = XML::LibXML::Element->new("SW-VARIABLE-REFS");
       my $swVariableRef = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
       $swVariableRef->appendText($rteBuffer);
       my @swFeaturesI = ($element->getElementsByTagName("SW-FEATURE"));
       my @swFeatureElements = ($swFeaturesI[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
       my @swFeatureSVarRefI = $swFeatureElements[0]->getChildrenByTagName("SW-VARIABLE-REFS");
       if(@swFeatureSVarRefI)
       { 
         $swFeatureSVarRefI[0]->appendChild($swVariableRef);              
       }            
			 else
			 {
			   $swFeatureElements[0]->addChild($swVariableRefsFct);
			   $swVariableRefsFct->addChild($swVariableRef);			   
			 }
     
       #Update Export Section
       my $swVariableRefExport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
       $swVariableRefExport->appendText($rteBuffer);
       my @swFeatureElementsExportsI = ($swFeaturesI[0]->getElementsByTagName("SW-INTERFACE-EXPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
       my @swFeatureSVarRefExportsI = $swFeatureElementsExportsI[0]->getChildrenByTagName("SW-VARIABLE-REFS");
       if(@swFeatureSVarRefExportsI)
       {
         $swFeatureSVarRefExportsI[0]->addChild($swVariableRefExport);   
       }
       else
       {
         $swFeatureElementsExportsI[0]->addChild($swVariableRefs);
         $swVariableRefs->addChild($swVariableRefExport);
       }          
    }
    elsif($intType ~~ @receiverPorts)
    {
      #Update Import Section
      my $swVariableRefImport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefImport->appendText($rteBuffer);
      my @swFeaturesI = ($element->getElementsByTagName("SW-FEATURE"));
      my $swVariableRefs = XML::LibXML::Element->new("SW-VARIABLE-REFS");
      my @swFeatureElementsImportI = ($swFeaturesI[0]->getElementsByTagName("SW-INTERFACE-IMPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefImportI = $swFeatureElementsImportI[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefImportI)
      {
        $swFeatureSVarRefImportI[0]->addChild($swVariableRefImport);   
      }   
      else
      {
        $swFeatureElementsImportI[0]->addChild($swVariableRefs);
        $swVariableRefs->addChild($swVariableRefImport);
      }
    }    
  }
#########################################################################################################################################################################################################
  #Handling Boolean types    
  foreach my $boolType(@boolDataElements) 
  {
    print "Adding Data Element: $boolType\n";  
    my $dataContraints = "DataConstrC_0_1";
    my $rteBuffer = "";     
    if($option eq 'option1')
    {
      $rteBuffer = "Rte_".$boolType;    
    }
    elsif($option eq 'option2')
    {
      $rteBuffer = $boolType."_RTE";
    } 
    elsif($option eq 'option3')
    {
		  $rteBuffer = $boolType;
		}
		else
    {
		  $rteBuffer = $boolType."_RTE";
		}
    my $swVariable = XML::LibXML::Element->new("SW-VARIABLE");			        # Create SW-VARIABLE
    my $shortNme = XML::LibXML::Element->new("SHORT-NAME");			        # Create Short Name
    my $category = XML::LibXML::Element->new("CATEGORY");			        # Create CATEGORY     
    my $swDataDefProps = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");	        # Create #SW-DATA-DEF-PROPS
    my $swAddrMethodref = XML::LibXML::Element->new("SW-ADDR-METHOD-REF");	        # SW-ADDR-METHOD-REF
    my $swBaseTypeRef = XML::LibXML::Element->new("SW-BASE-TYPE-REF");                 # SW-BASE-TYPE-REF
    my $swCalibrationAccess = XML::LibXML::Element->new("SW-CALIBRATION-ACCESS");      # SW-CALIBRATION-ACCESS
    my $swCodeSyntaxRef = XML::LibXML::Element->new("SW-CODE-SYNTAX-REF");             # SW-CODE-SYNTAX-REF
    my $swCompuMethodRef = XML::LibXML::Element->new("SW-COMPU-METHOD-REF");           # SW-COMPU-METHOD-REF
    my $swDataConstrRef = XML::LibXML::Element->new("SW-DATA-CONSTR-REF");             # SW-DATA-CONSTR-REF
    my $swImplPolicy = XML::LibXML::Element->new("SW-IMPL-POLICY");                    # SW-IMPL-POLICY
    my $swVariableAccess = XML::LibXML::Element->new("SW-VARIABLE-ACCESS-IMPL-POLICY"); # SW-VARIABLE-ACCESS-IMPL-POLICY
     
     
    # Update Node values
    $shortNme->appendText($rteBuffer);
    $category->appendText("BIT");
    $swAddrMethodref->appendText("intRam");
    $swBaseTypeRef->appendText("bool");		                              
    $swCalibrationAccess->appendText("READ-ONLY");
    $swCodeSyntaxRef->appendText("Msg");                   #
    $swCompuMethodRef->appendText("B_TRUE");
    $swDataConstrRef->appendText($dataContraints);
    $swImplPolicy->appendText("MESSAGE");
    $swVariableAccess->appendText("OPTIMIZED");
     
     
    my @swVariablesB = $element->getElementsByTagName("SW-VARIABLES");     
    $swVariablesB[0]->addChild($swVariable);
    $swVariable->addChild($shortNme);
    $swVariable->addChild($category);
    $swVariable->addChild($swDataDefProps);
    $swDataDefProps->addChild($swAddrMethodref);
    $swDataDefProps->addChild($swBaseTypeRef);
    $swDataDefProps->addChild($swCalibrationAccess);
    $swDataDefProps->addChild($swCodeSyntaxRef);
    $swDataDefProps->addChild($swCompuMethodRef);
    $swDataDefProps->addChild($swDataConstrRef);
    $swDataDefProps->addChild($swImplPolicy);
    $swDataDefProps->addChild($swVariableAccess);
     
    if($boolType ~~ @providerPorts)
    {
      # Update SW-FEATURE-ELEMENTS section
      my $swVariableRefsB = XML::LibXML::Element->new("SW-VARIABLE-REFS");
			my $swVariableRefsFct = XML::LibXML::Element->new("SW-VARIABLE-REFS");
      my $swVariableRefB = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefB->appendText($rteBuffer);
      my @swFeaturesB = ($element->getElementsByTagName("SW-FEATURE"));
      my @swFeatureElementsB = ($swFeaturesB[0]->getElementsByTagName("SW-FEATURE-OWNED-ELEMENTS"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefB = $swFeatureElementsB[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefB)
      {       
        $swFeatureSVarRefB[0]->addChild($swVariableRefB);       
      }
			else
			{
			  $swFeatureElementsB[0]->addChild($swVariableRefsFct);
			  $swVariableRefsFct->addChild($swVariableRefB);			   
			}
     
      #Update Export Section
      my $swVariableRefExport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefExport->appendText($rteBuffer);
      my @swFeatureElementsExportsB = ($swFeaturesB[0]->getElementsByTagName("SW-INTERFACE-EXPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefExportsB = $swFeatureElementsExportsB[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefExportsB)
      {
        $swFeatureSVarRefExportsB[0]->addChild($swVariableRefExport);   
       }     
       else
       {
         $swFeatureElementsExportsB[0]->addChild($swVariableRefsB);
         $swVariableRefsB->addChild($swVariableRefExport);
       } 
    }  
    elsif($boolType ~~ @receiverPorts)
    {
      #Update Import Section
      my $swVariableRefImport = XML::LibXML::Element->new("SW-VARIABLE-REF");			         # Create SW-VARIABLE-REF tag
      $swVariableRefImport->appendText($rteBuffer);
      my @swFeaturesB = ($element->getElementsByTagName("SW-FEATURE"));
      my $swVariableRefsB = XML::LibXML::Element->new("SW-VARIABLE-REFS");
      my @swFeatureElementsImportB = ($swFeaturesB[0]->getElementsByTagName("SW-INTERFACE-IMPORT"))[0]->getChildrenByTagName("SW-FEATURE-ELEMENTS"); 
      my @swFeatureSVarRefImportB = $swFeatureElementsImportB[0]->getChildrenByTagName("SW-VARIABLE-REFS");
      if(@swFeatureSVarRefImportB)
      {
        $swFeatureSVarRefImportB[0]->addChild($swVariableRefImport);   
      }   
      else
      {
        $swFeatureElementsImportB[0]->addChild($swVariableRefsB);
        $swVariableRefsB->addChild($swVariableRefImport);
      }
    }    	
  }  
  #########################################################################################################################################################################################################
  foreach my $compuMethod(keys %linearCompuMethods) 
  {	
	  print "Adding Compu Method: $compuMethod \n";	  
		my $cmNode = XML::LibXML::Element->new("SW-COMPU-METHOD");			        # Create SW-VARIABLE
    my $cmShortNameTag = XML::LibXML::Element->new("SHORT-NAME");			        # Create Short Name
    my $cmCategoryTag = XML::LibXML::Element->new("CATEGORY");	
		my $cmUnitTag = XML::LibXML::Element->new("SW-UNIT-REF");
		my $swCMPhysToInt = XML::LibXML::Element->new("SW-COMPU-PHYS-TO-INTERNAL");
		my $swCompuScales = XML::LibXML::Element->new("SW-COMPU-SCALES");
		my $swCompuScale = XML::LibXML::Element->new("SW-COMPU-SCALE");
		my $swCompuRationalCoeffs = XML::LibXML::Element->new("SW-COMPU-RATIONAL-COEFFS");
		my $swCompuNumerator = XML::LibXML::Element->new("SW-COMPU-NUMERATOR");
		my $swCompuNumVF1 = XML::LibXML::Element->new("VF");
		my $swCompuNumVF2 = XML::LibXML::Element->new("VF");
		my $swCompuDenominator = XML::LibXML::Element->new("SW-COMPU-DENOMINATOR");
		my $swCompuDenVF1 = XML::LibXML::Element->new("VF");
		my $swCompuDenVF2 = XML::LibXML::Element->new("VF");
		
		my $unit = (@{$linearCompuMethods{$compuMethod}})[0]; 
		my $numerator1 = (@{$linearCompuMethods{$compuMethod}})[1];
		my $numerator2 = (@{$linearCompuMethods{$compuMethod}})[2];
		my $denominator1 = (@{$linearCompuMethods{$compuMethod}})[3];		
			
		$cmShortNameTag->appendText($compuMethod);
		$cmCategoryTag->appendText('RAT_FUNC');
		$cmUnitTag->appendText($unit);
		$swCompuNumVF1->appendText($numerator1);
		$swCompuNumVF2->appendText($numerator2);
		$swCompuDenVF1->appendText($denominator1);
		$swCompuDenVF2->appendText('0');
			
		my @compuMethods = $element->getElementsByTagName("SW-COMPU-METHODS");
		$compuMethods[0]->addChild($cmNode);
		$cmNode->addChild($cmShortNameTag);
		$cmNode->addChild($cmCategoryTag);
		$cmNode->addChild($cmUnitTag);			
    $cmNode->addChild($swCMPhysToInt);	
    $swCMPhysToInt->addChild($swCompuScales);			
		$swCompuScales->addChild($swCompuScale);			
		$swCompuScale->addChild($swCompuRationalCoeffs);		
		$swCompuRationalCoeffs->addChild($swCompuNumerator);	
    $swCompuNumerator->addChild($swCompuNumVF1);	
    $swCompuNumerator->addChild($swCompuNumVF2);		
		$swCompuRationalCoeffs->addChild($swCompuDenominator);
		$swCompuDenominator->addChild($swCompuDenVF1);
	  $swCompuDenominator->addChild($swCompuDenVF2);		
	}	  
	
	foreach my $unit(keys %unitShortNames) 
  {
	  print "Adding Unit Short Name: $unit \n";	  
		my $unitNode = XML::LibXML::Element->new("SW-UNIT");			        # Create SW-VARIABLE
    my $unitShortNameNode = XML::LibXML::Element->new("SHORT-NAME");			        # Create Short Name
    my $unitDisplayNode = XML::LibXML::Element->new("SW-UNIT-DISPLAY");	
		my $unitSiUnitNode = XML::LibXML::Element->new("SI-UNIT");
		
		my $unitDisplayName = (@{$unitShortNames{$unit}})[0]; 			
		$unitShortNameNode->appendText($unit);
		$unitDisplayNode->appendText($unitDisplayName);
		$unitSiUnitNode->appendText("tbd");		
			
		my @units = $element->getElementsByTagName("SW-UNITS");
		$units[0]->addChild($unitNode);
		$unitNode->addChild($unitShortNameNode);
		$unitNode->addChild($unitDisplayNode);
		$unitNode->addChild($unitSiUnitNode);		     		
	}
  
  foreach my $runnable(keys %runnableDetails) 
  {
	  print "Adding Runnable: $runnable \n";	  
		my $swServiceNode = XML::LibXML::Element->new("SW-SERVICE");			        
    my $swServiceShortNameNode = XML::LibXML::Element->new("SHORT-NAME");			        
    my $swServiceCategory = XML::LibXML::Element->new("CATEGORY");	
		my $swServiceReturn = XML::LibXML::Element->new("SW-SERVICE-RETURN");
    my $swServiceReturnDDP = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");
    my $swServiceReturnDDPBaseType = XML::LibXML::Element->new("SW-BASE-TYPE-REF");
    
    
    my $swServiceArgs = XML::LibXML::Element->new("SW-SERVICE-ARGS");
    my $swServiceArg = XML::LibXML::Element->new("SW-SERVICE-ARG");
    my $swServiceArgSDDP = XML::LibXML::Element->new("SW-DATA-DEF-PROPS");
    my $swServiceArgSDDPSBTR = XML::LibXML::Element->new("SW-BASE-TYPE-REF");
    
    my $swServiceAESETS = XML::LibXML::Element->new("SW-SERVICE-ACCESSED-ELEMENT-SETS");
    my $swServiceAESET = XML::LibXML::Element->new("SW-SERVICE-ACCESSED-ELEMENT-SET");
    my $swServiceSWAVariables = XML::LibXML::Element->new("SW-ACCESSED-VARIABLES");
		
    
		#my $swServiceShortNameNode = (@{$runnableDetails{$runnable}})[0]; 			
		$swServiceShortNameNode->appendText("Rte_task_OsTask_".$runnable);
    $swServiceCategory->appendText("PROCESS");
		$swServiceReturnDDPBaseType->appendText("void");
    
    $swServiceArgSDDPSBTR->appendText("void");
    
    my @swSerives = $element->getElementsByTagName("SW-SERVICES");
		$swSerives[0]->addChild($swServiceNode);
		$swServiceNode->addChild($swServiceShortNameNode);
		$swServiceNode->addChild($swServiceCategory);
		$swServiceNode->addChild($swServiceReturn);
    $swServiceReturn->addChild($swServiceReturnDDP);  
    $swServiceReturnDDP->addChild($swServiceReturnDDPBaseType); 

    $swServiceNode->addChild($swServiceArgs);
    $swServiceArgs->addChild($swServiceArg);  
    $swServiceArg->addChild($swServiceArgSDDP); 
    $swServiceArgSDDP->addChild($swServiceArgSDDPSBTR);  
    
    $swServiceNode->addChild($swServiceAESETS);
    $swServiceAESETS->addChild($swServiceAESET);  
    $swServiceAESET->addChild($swServiceSWAVariables); 

    my @dataElements = @{$runnableDetails{$runnable}};
    foreach my $dataElelement(@dataElements)    
    { 	         
      my $swServiceSWAVariable = XML::LibXML::Element->new("SW-ACCESSED-VARIABLE");
      my $swServiceSWAVRef = XML::LibXML::Element->new("SW-VARIABLE-REF");
      my $swServiceSWAVUsage = XML::LibXML::Element->new("SW-VARIABLE-USAGE");
      my $swServiceSWAVAccessImpl = XML::LibXML::Element->new("SW-VARIABLE-ACCESS-IMPL");
      
      my $varusage="";
      if($dataElelement=~/^DSP_/)
      {
        $dataElelement=~ s/^(DSP_)//;
        $varusage="WRITE";
      }
      elsif($dataElelement=~/^DRP_/)
      {
        $dataElelement=~ s/^(DRP_)//;
        $varusage="READ";
      }
      else
      {
        print "[ERROR]: Var Usage Not deifned for $dataElelement\n";
      }
      # print "VariableName = $dataElelement\n";
      $swServiceSWAVRef->appendText($dataElelement);
      $swServiceSWAVUsage->appendText($varusage);
      $swServiceSWAVAccessImpl->appendText("OPTIMIZED");
      
      $swServiceSWAVariables->addChild($swServiceSWAVariable);       
      $swServiceSWAVariable->addChild($swServiceSWAVRef); 
      $swServiceSWAVariable->addChild($swServiceSWAVUsage); 
      $swServiceSWAVariable->addChild($swServiceSWAVAccessImpl);       
    }    
	}
	
  return $element;
} # modifyModuleARXML

####################################################################################################
#
# Subroutine to Read Adapter ARXML file
#
####################################################################################################

sub readModuleArxml
{
  my ($file) = @_;
  return 0 unless -f $file;
  return 0 unless $file =~ /.+\.arxml$/;
  print "\n------------------------------------------------\n";
  print "[INFO]: Parsing Module ARXML \n $file...\n";
  print "\n------------------------------------------------\n";
  my $parser = XML::LibXML->new();
  my $document = $parser->parse_file($file);
  my $element = $document->getDocumentElement();   

  
  if(($element->nodeName()) eq "AUTOSAR")
  {
	  #Get AR schema version
		if($element->getAttribute("xmlns") =~ m/3\.1\.\d$/)
    {
		  $ArRelease = "3.1";
		}
		elsif ($element->getAttribute("xmlns") =~ m/r4\.0$/) 
		{
		  $ArRelease = "4.0";
		}
		   else
    {
		  $ArRelease = "3.1"; #By default it is assumed as 3.1
		}
  }
  
  print "AR Version: $ArRelease \n";
  if($ArRelease eq "3.1")
	{
		#Classify Provider and Receiver port
		foreach my $providerPort($element->getElementsByTagName("P-PORT-PROTOTYPE")) 
		{
			my $providerPortName = ($providerPort->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
			$providerPortName=~ s/^P_//;    
			push(@providerPorts,$providerPortName);
		}
		
		foreach my $receiverPort($element->getElementsByTagName("R-PORT-PROTOTYPE")) 
		{
			my $receiverPortName = ($receiverPort->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
			$receiverPortName=~ s/^R_//;    
			push(@receiverPorts,$receiverPortName);
		}
		
		
		#Read all Data elements from Module ARXML file and store in an array
		foreach my $psaDataElements($element->getElementsByTagName("DATA-ELEMENTS")) 
		{
			my $psaType = (($psaDataElements->getElementsByTagName("DATA-ELEMENT-PROTOTYPE"))[0]->getChildrenByTagName("TYPE-TREF"))[0];
			
			#Array Type ########################################################################################################
			if($psaType->getAttribute("DEST") eq "ARRAY-TYPE")
			{
				#Extract Array Type Name
				my $arrayTypeName = $psaType->textContent;
				$arrayTypeName=~ s/.*\///;
				$arrayDataType = getDataType($arrayTypeName);      
				#Get Array size
				my $arrayDataElement = (($psaDataElements->getElementsByTagName("DATA-ELEMENT-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
				foreach my $psaArrayType($element->getElementsByTagName("ARRAY-TYPE"))
				{
				    if ($arrayDataType eq "real32")
				    {
    				      if((($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $arrayTypeName)
                            {
                            my $arraySize = (($psaArrayType->getChildrenByTagName("ELEMENT"))[0]->getChildrenByTagName("MAX-NUMBER-OF-ELEMENTS"))[0]->textContent;
                            my $arrayTypeTref = (($psaArrayType->getChildrenByTagName("ELEMENT"))[0]->getChildrenByTagName("TYPE-TREF"))[0]->textContent;
                            $arrayTypeTref=~ s/.*\///;
                            my @arrayProprties = ();
                            $arrayProprties[0] = $arrayDataType;
                            $arrayProprties[1] = $arraySize;
                            $arrayProprties[2] = defineLowerLimit($arrayDataType);
                            $arrayProprties[3] = defineUpperLimit($arrayDataType);                  
                            my $compuMethod = "OneToOne";        
                                foreach my $psaRealType($element->getElementsByTagName("REAL-TYPE"))
                                {                 
                                        if($arrayTypeTref eq (($psaRealType->getChildrenByTagName("SHORT-NAME"))[0]->textContent))
                                        {
                                           $compuMethod = ($psaRealType->getElementsByTagName("COMPU-METHOD-REF"))[0]->textContent;
                                            $compuMethod=~ s/.*\///;   
                                        }                                                                
                                }             
                            $arrayProprties[4] = $compuMethod;                        
                            push(@{ $arrayTypes{$arrayDataElement} }, @arrayProprties);                           
                            }  
				    }
				    else
				    {
    				    if((($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $arrayTypeName)
    					{
    						my $arraySize = (($psaArrayType->getChildrenByTagName("ELEMENT"))[0]->getChildrenByTagName("MAX-NUMBER-OF-ELEMENTS"))[0]->textContent;
    						my $arrayIntType = (($psaArrayType->getChildrenByTagName("ELEMENT"))[0]->getChildrenByTagName("TYPE-TREF"))[0]->textContent;
    						$arrayIntType=~ s/.*\///;
    						my @arrayProprties = ();
    						$arrayProprties[0] = $arrayDataType;
    						$arrayProprties[1] = $arraySize;
    						$arrayProprties[2] = getLowerLimit($element, $arrayIntType);
    						$arrayProprties[3] = getUpperLimit($element, $arrayIntType);	               
    						my $compuMethod = "OneToOne";
                             #print "Type Name: \n";						           
    						$arrayProprties[4] = $compuMethod;	                      
    						push(@{ $arrayTypes{$arrayDataElement} }, @arrayProprties);					          
    					}
				    }
					#else{ print "ERROR: Not an Array Check the module \n";}	
				}	   
			}    
			# INTEGER-TYPE
			if($psaType->getAttribute("DEST") eq "INTEGER-TYPE")
			{
				#Extract Integer Type Name
				my $intTypeName = $psaType->textContent;
				$intTypeName=~ s/.*\///;
				my $dataType = getDataType($intTypeName);      
				my $intDataElement = (($psaDataElements->getElementsByTagName("DATA-ELEMENT-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;			
				#Read the upper Limit
				foreach my $psaIntTypes($element->getElementsByTagName("INTEGER-TYPE"))
				{
					if((($psaIntTypes->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $intTypeName)
					{
						my @varProprties = ();
						$varProprties[0] = $dataType;
						$varProprties[1] = ($psaIntTypes->getChildrenByTagName("LOWER-LIMIT"))[0]->textContent;
						$varProprties[2] = ($psaIntTypes->getChildrenByTagName("UPPER-LIMIT"))[0]->textContent;
						my $compuMethod = "OneToOne";
						if($psaIntTypes->getElementsByTagName("COMPU-METHOD-REF"))
						{
							$compuMethod = ($psaIntTypes->getElementsByTagName("COMPU-METHOD-REF"))[0]->textContent;
							$compuMethod=~ s/.*\///;
						}          
						$varProprties[3] = $compuMethod;                    		    	
						push(@{$intTypes{$intDataElement} }, @varProprties);	          
					}							
				}	   
			}
			# REAL-TYPE
            if($psaType->getAttribute("DEST") eq "REAL-TYPE")
            {
                #Extract Real32 Type Name
                my $real32TypeName = $psaType->textContent;
                $real32TypeName=~ s/.*\///;
                my $dataType = getDataType($real32TypeName);      
                my $real32DataElement = (($psaDataElements->getElementsByTagName("DATA-ELEMENT-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
                #Read the upper Limit
                foreach my $psaReal32Types($element->getElementsByTagName("REAL-TYPE"))
                {
                    if((($psaReal32Types->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $real32TypeName)
                    {
                        my @varProprties = ();
                        $varProprties[0] = $dataType;
                        $varProprties[1] = defineLowerLimit($dataType);
                        $varProprties[2] = defineUpperLimit($dataType);
                        my $compuMethod = "OneToOne";
                        if($psaReal32Types->getElementsByTagName("COMPU-METHOD-REF"))
                        {
                            $compuMethod = ($psaReal32Types->getElementsByTagName("COMPU-METHOD-REF"))[0]->textContent;
                            $compuMethod=~ s/.*\///;
                        }          
                        $varProprties[3] = $compuMethod;                                    
                        push(@{$real32Types{$real32DataElement} }, @varProprties);              
                    }                           
                }  
            }                       
            
			# else BOOLEAN-TYPE
			elsif($psaType->getAttribute("DEST") eq "BOOLEAN-TYPE")
			{
				#Extract the Boolean Type Names	   
				my $boolDataElement = (($psaDataElements->getElementsByTagName("DATA-ELEMENT-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;      
				push (@boolDataElements,$boolDataElement); 
			}        
		} 
	}
#	elsif($ArRelease eq "4.0")
#	{
#    if($element->getElementsByTagName("APPLICATION-SW-COMPONENT-TYPE"))
#    {
#      $appSWCName = (($element->getElementsByTagName("APPLICATION-SW-COMPONENT-TYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
#    }
#    	
#		#Classify Provider and Receiver port
#		foreach my $providerPort($element->getElementsByTagName("P-PORT-PROTOTYPE")) 
#		{
#			my $providerPortName = ($providerPort->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
#			$providerPortName=~ s/^(PP_|P_)//;    
#			push(@providerPorts,$providerPortName);
#		}
#		
#		foreach my $receiverPort($element->getElementsByTagName("R-PORT-PROTOTYPE")) 
#		{
#			my $receiverPortName = ($receiverPort->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
#			$receiverPortName=~ s/^(RP_|R_)//;    
#			push(@receiverPorts,$receiverPortName);
#		}
#		
#		foreach my $psaDataElements($element->getElementsByTagName("DATA-ELEMENTS")) 
#		{
#			my $psaType = (($psaDataElements->getElementsByTagName("VARIABLE-DATA-PROTOTYPE"))[0]->getChildrenByTagName("TYPE-TREF"))[0];
#			#Array Type
#			if($psaType->getAttribute("DEST") eq "APPLICATION-ARRAY-DATA-TYPE")
#			{			  				
#				my $arrayTypeName = $psaType->textContent;
#				$arrayTypeName=~ s/.*\///;	
#				my $arrayDataElement = (($psaDataElements->getElementsByTagName("VARIABLE-DATA-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#				foreach my $psaArrayType($element->getElementsByTagName("APPLICATION-ARRAY-DATA-TYPE"))
#				{
#				  my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#					my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#					if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#					{
#					  #print "Parsing APPLICATION-ARRAY-DATA-TYPE ...... \n";					
#						my $arraySize = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("MAX-NUMBER-OF-ELEMENTS"))[0]->textContent;
#						my $appPrimDataType = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("TYPE-TREF"))[0]->textContent;
#						$appPrimDataType=~ s/.*\///;
#						my $compuMethod = "OneToOne";	
#						$compuMethod = getCompuMethod($element,$appPrimDataType);						
#						my $implDataType = getImplDataType($element,$appPrimDataType);		
#            my $arrayDataType = getArrayDataType($element,$implDataType);												
#            my $dataType = getDataTypeAR4($arrayDataType);						
#            my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#						my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#						my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);              					
#						my @arrayProprties = ();
#						$arrayProprties[0] = $dataType;
#						$arrayProprties[1] = $arraySize;
#						$arrayProprties[2] = $lowerLimit;
#						$arrayProprties[3] = $upperLimit;
#						$arrayProprties[4] = $compuMethod;	                      
#						push(@{$arrayTypes{$arrayDataElement} }, @arrayProprties);					          
#					}
#					#else{ print "ERROR: Not an Array Check the module \n";}	
#				}	   
#			} 
#			# IMPLEMENTATION-DATA-TYPE and ARRAY
#      if($psaType->getAttribute("DEST") eq "IMPLEMENTATION-DATA-TYPE")
#			{        
#				my $arrayTypeName = $psaType->textContent;
#				$arrayTypeName=~ s/.*\///;	
#				my $arrayDataElement = (($psaDataElements->getElementsByTagName("VARIABLE-DATA-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#				foreach my $psaArrayType($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
#				{
#				  my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#					my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#					if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#					{
#					  #print "Parsing IMPLEMENTATION-DATA-TYPE of ARRAY...... \n"; 
#						my $arraySize = (($psaArrayType->getElementsByTagName("IMPLEMENTATION-DATA-TYPE-ELEMENT"))[0]->getChildrenByTagName("ARRAY-SIZE"))[0]->textContent;
#						my $implDataType = (($psaArrayType->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0]->getChildrenByTagName("IMPLEMENTATION-DATA-TYPE-REF"))[0]->textContent;
#						$implDataType=~ s/.*\///;						
#						my $compuMethod = getCompuMethodImplType($element,$implDataType);	
#            my $arrayDataType = getArrayDataType($element,$implDataType);							
#						my $dataType="";
#						if($arrayDataType eq 'boolean')
#						{			
#              $dataType = 'bool';							
#						}
#            else						
#						{
#						  $dataType = getDataTypeAR4($arrayDataType);
#						}							
#            my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#						my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#						my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);            					
#						my @arrayProprties = ();
#						$arrayProprties[0] = $dataType;
#						$arrayProprties[1] = $arraySize;
#						$arrayProprties[2] = $lowerLimit;
#						$arrayProprties[3] = $upperLimit;
#						$arrayProprties[4] = $compuMethod;	                      
#						push(@{$arrayTypes{$arrayDataElement} }, @arrayProprties);					          
#					}
#					# IMPLEMENTATION-DATA-TYPE and VALUE
#          elsif(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "VALUE" ))
#					{
#            #print "Parsing IMPLEMENTATION-DATA-TYPE of VALUE...... \n"; 	
#					  my $intTypeName = getArrayDataType($element,$arrayTypeName);	
#						my $dataType = getDataTypeAR4($intTypeName);             	
#				    my $compuMethod = getCompuMethodImplType($element,$arrayTypeName);					
#						my $dataConstraintsRef = getDataConstrRef($element,$arrayTypeName);
#						my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#						my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);									
#				    my @varProprties = ();
#					  $varProprties[0] = $dataType;
#					  $varProprties[1] = $lowerLimit;
#					  $varProprties[2] = $upperLimit;	
#					  $varProprties[3] = $compuMethod;  						
#					  push(@{$intTypes{$arrayDataElement} }, @varProprties);	              
#				  }						
#				}	   
#			} 		
#			elsif($psaType->getAttribute("DEST") eq "APPLICATION-PRIMITIVE-DATA-TYPE")
#			{
#				#Extract Integer Type Name
#				my $implDataTypeName = $psaType->textContent;
#				$implDataTypeName=~ s/.*\///;		
#        my $intDataElement = (($psaDataElements->getElementsByTagName("VARIABLE-DATA-PROTOTYPE"))[0]->getChildrenByTagName("SHORT-NAME"))[0]->textContent;				
#				foreach my $appPrimitiveDataType($element->getElementsByTagName("APPLICATION-PRIMITIVE-DATA-TYPE"))
#				{				  			  
#				  my $appPrimitiveDataTypeNameRef = (($appPrimitiveDataType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#					my $appPrimitiveTypeCategory = (($appPrimitiveDataType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#				  if(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "VALUE" ))
#					{
#            #print "Parsing APPLICATION-PRIMITIVE-DATA-TYPE of VALUE...... \n";					
#				    my $compuMethod = getCompuMethod($element,$implDataTypeName);		
#            my $implDataType = getImplDataType($element,$implDataTypeName);	
#						my $intTypeName = getArrayDataType($element,$implDataType);						
#						my $dataType = getDataTypeAR4($intTypeName);   
#            my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#						my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#						my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef); 	
#				    my @varProprties = ();
#					  $varProprties[0] = $dataType;
#					  $varProprties[1] = $lowerLimit;
#					  $varProprties[2] = $upperLimit;	
#					  $varProprties[3] = $compuMethod;  						
#					  push(@{$intTypes{$intDataElement} }, @varProprties);	              
#				  }
#          elsif(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "BOOLEAN" ))
#					{					       
#				    push (@boolDataElements,$intDataElement);	              
#				  }						
#				}	   
#			}        
#		}	
#    
#    #Parameters ########################################################################################################
#    my @parameters = $element->getElementsByTagName("PARAMETERS");
#    if(@parameters)
#    {
#      foreach my $parameter($parameters[0]->getElementsByTagName("PARAMETER-DATA-PROTOTYPE"))
#      {
#        my $psaType = ($parameter->getChildrenByTagName("TYPE-TREF"))[0];
#
#        #Array Type ########################################################################################################
#        if($psaType->getAttribute("DEST") eq "APPLICATION-ARRAY-DATA-TYPE")
#        {			  				
#          my $arrayTypeName = $psaType->textContent;
#          $arrayTypeName=~ s/.*\///;	
#          my $arrayDataElement = ($parameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#          foreach my $psaArrayType($element->getElementsByTagName("APPLICATION-ARRAY-DATA-TYPE"))
#          {
#            my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#            {
#              #print "Parsing APPLICATION-ARRAY-DATA-TYPE ...... \n";					
#              my $arraySize = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("MAX-NUMBER-OF-ELEMENTS"))[0]->textContent;
#              my $appPrimDataType = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("TYPE-TREF"))[0]->textContent;
#              $appPrimDataType=~ s/.*\///;
#              my $compuMethod = "OneToOne";	
#              $compuMethod = getCompuMethod($element,$appPrimDataType);						
#              my $implDataType = getImplDataType($element,$appPrimDataType);		
#              my $arrayDataType = getArrayDataType($element,$implDataType);												
#              my $dataType = getDataTypeAR4($arrayDataType);						
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);              					
#              my @arrayProprties = ();
#              $arrayProprties[0] = $dataType;
#              $arrayProprties[1] = $arraySize;
#              $arrayProprties[2] = $lowerLimit;
#              $arrayProprties[3] = $upperLimit;
#              $arrayProprties[4] = $compuMethod;	                      
#              push(@{$parmArrayTypes{$arrayDataElement} }, @arrayProprties);					          
#            }
#            #else{ print "ERROR: Not an Array Check the module \n";}	
#          }	   
#        } 
#        # IMPLEMENTATION-DATA-TYPE and ARRAY ########################################################################################################
#        if($psaType->getAttribute("DEST") eq "IMPLEMENTATION-DATA-TYPE")
#        {        
#          my $arrayTypeName = $psaType->textContent;
#          $arrayTypeName=~ s/.*\///;	
#          my $arrayDataElement = ($parameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#          foreach my $psaArrayType($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
#          {
#            my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#            {
#              #print "Parsing IMPLEMENTATION-DATA-TYPE of ARRAY...... \n"; 
#              my $arraySize = (($psaArrayType->getElementsByTagName("IMPLEMENTATION-DATA-TYPE-ELEMENT"))[0]->getChildrenByTagName("ARRAY-SIZE"))[0]->textContent;
#              my $implDataType = (($psaArrayType->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0]->getChildrenByTagName("IMPLEMENTATION-DATA-TYPE-REF"))[0]->textContent;
#              $implDataType=~ s/.*\///;						
#              my $compuMethod = getCompuMethodImplType($element,$implDataType);	
#              my $arrayDataType = getArrayDataType($element,$implDataType);							
#              my $dataType="";
#              if($arrayDataType eq 'boolean')
#              {			
#                $dataType = 'bool';							
#              }
#              else						
#              {
#                $dataType = getDataTypeAR4($arrayDataType);
#              }							
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);            					
#              my @arrayProprties = ();
#              $arrayProprties[0] = $dataType;
#              $arrayProprties[1] = $arraySize;
#              $arrayProprties[2] = $lowerLimit;
#              $arrayProprties[3] = $upperLimit;
#              $arrayProprties[4] = $compuMethod;	                      
#              push(@{$parmArrayTypes{$arrayDataElement} }, @arrayProprties);					          
#            }
#            # IMPLEMENTATION-DATA-TYPE and VALUE ########################################################################################################
#            elsif(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "VALUE" ))
#            {
#              #print "Parsing IMPLEMENTATION-DATA-TYPE of VALUE...... \n"; 	
#              my $intTypeName = getArrayDataType($element,$arrayTypeName);	
#              my $dataType = getDataTypeAR4($intTypeName);             	
#              my $compuMethod = getCompuMethodImplType($element,$arrayTypeName);					
#              my $dataConstraintsRef = getDataConstrRef($element,$arrayTypeName);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);									
#              my @varProprties = ();
#              $varProprties[0] = $dataType;
#              $varProprties[1] = $lowerLimit;
#              $varProprties[2] = $upperLimit;	
#              $varProprties[3] = $compuMethod;  						
#              push(@{$parmIntTypes{$arrayDataElement} }, @varProprties);	              
#            }						
#          }	   
#        } 		
#        elsif($psaType->getAttribute("DEST") eq "APPLICATION-PRIMITIVE-DATA-TYPE")
#        {
#          #Extract Integer Type Name ########################################################################################################
#          my $implDataTypeName = $psaType->textContent;
#          $implDataTypeName=~ s/.*\///;		
#          my $intDataElement = ($parameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;				
#          foreach my $appPrimitiveDataType($element->getElementsByTagName("APPLICATION-PRIMITIVE-DATA-TYPE"))
#          {				  			  
#            my $appPrimitiveDataTypeNameRef = (($appPrimitiveDataType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $appPrimitiveTypeCategory = (($appPrimitiveDataType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "VALUE" ))
#            {
#              #print "Parsing APPLICATION-PRIMITIVE-DATA-TYPE of VALUE...... \n";					
#              my $compuMethod = getCompuMethod($element,$implDataTypeName);		
#              my $implDataType = getImplDataType($element,$implDataTypeName);	
#              my $intTypeName = getArrayDataType($element,$implDataType);						
#              my $dataType = getDataTypeAR4($intTypeName);   
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef); 	
#              my @varProprties = ();
#              $varProprties[0] = $dataType;
#              $varProprties[1] = $lowerLimit;
#              $varProprties[2] = $upperLimit;	
#              $varProprties[3] = $compuMethod;  						
#              push(@{$parmIntTypes{$intDataElement} }, @varProprties);	              
#            }
#            elsif(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "BOOLEAN" ))
#            {					       
#              push (@boolParmElements,$intDataElement);	              
#            }						
#          }	   
#        }		
#      }
#    }
#    
#    #Read Shared Parameters ########################################################################################################
#    my @sharedparameters = $element->getElementsByTagName("SHARED-PARAMETERS");
#    if(@sharedparameters)
#    {
#      foreach my $sharedParameter($sharedparameters[0]->getElementsByTagName("PARAMETER-DATA-PROTOTYPE"))
#      {
#        my $psaType = ($sharedParameter->getChildrenByTagName("TYPE-TREF"))[0];
#        #Array Type
#        if($psaType->getAttribute("DEST") eq "APPLICATION-ARRAY-DATA-TYPE")
#        {			  				
#          my $arrayTypeName = $psaType->textContent;
#          $arrayTypeName=~ s/.*\///;	
#          my $arrayDataElement = ($sharedParameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#          foreach my $psaArrayType($element->getElementsByTagName("APPLICATION-ARRAY-DATA-TYPE"))
#          {
#            my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#            {
#              #print "Parsing APPLICATION-ARRAY-DATA-TYPE ...... \n";					
#              my $arraySize = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("MAX-NUMBER-OF-ELEMENTS"))[0]->textContent;
#              my $appPrimDataType = (($psaArrayType->getElementsByTagName("ELEMENT"))[0]->getChildrenByTagName("TYPE-TREF"))[0]->textContent;
#              $appPrimDataType=~ s/.*\///;
#              my $compuMethod = "OneToOne";	
#              $compuMethod = getCompuMethod($element,$appPrimDataType);						
#              my $implDataType = getImplDataType($element,$appPrimDataType);		
#              my $arrayDataType = getArrayDataType($element,$implDataType);												
#              my $dataType = getDataTypeAR4($arrayDataType);						
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);              					
#              my @arrayProprties = ();
#              $arrayProprties[0] = $dataType;
#              $arrayProprties[1] = $arraySize;
#              $arrayProprties[2] = $lowerLimit;
#              $arrayProprties[3] = $upperLimit;
#              $arrayProprties[4] = $compuMethod;	                      
#              push(@{$parmArrayTypes{$arrayDataElement} }, @arrayProprties);					          
#            }
#            #else{ print "ERROR: Not an Array Check the module \n";}	
#          }	   
#        } 
#        # IMPLEMENTATION-DATA-TYPE and ARRAY ########################################################################################################
#        if($psaType->getAttribute("DEST") eq "IMPLEMENTATION-DATA-TYPE")
#        {        
#          my $arrayTypeName = $psaType->textContent;
#          $arrayTypeName=~ s/.*\///;	
#          my $arrayDataElement = ($sharedParameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;           
#          foreach my $psaArrayType($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
#          {
#            my $arrayDataTypeName = (($psaArrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $arrayDataTypeCategory = (($psaArrayType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "ARRAY"))
#            {
#              #print "Parsing IMPLEMENTATION-DATA-TYPE of ARRAY...... \n"; 
#              my $arraySize = (($psaArrayType->getElementsByTagName("IMPLEMENTATION-DATA-TYPE-ELEMENT"))[0]->getChildrenByTagName("ARRAY-SIZE"))[0]->textContent;
#              my $implDataType = (($psaArrayType->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0]->getChildrenByTagName("IMPLEMENTATION-DATA-TYPE-REF"))[0]->textContent;
#              $implDataType=~ s/.*\///;						
#              my $compuMethod = getCompuMethodImplType($element,$implDataType);	
#              my $arrayDataType = getArrayDataType($element,$implDataType);							
#              my $dataType="";
#              if($arrayDataType eq 'boolean')
#              {			
#                $dataType = 'bool';							
#              }
#              else						
#              {
#                $dataType = getDataTypeAR4($arrayDataType);
#              }							
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);            					
#              my @arrayProprties = ();
#              $arrayProprties[0] = $dataType;
#              $arrayProprties[1] = $arraySize;
#              $arrayProprties[2] = $lowerLimit;
#              $arrayProprties[3] = $upperLimit;
#              $arrayProprties[4] = $compuMethod;	                      
#              push(@{$parmArrayTypes{$arrayDataElement} }, @arrayProprties);					          
#            }
#            # IMPLEMENTATION-DATA-TYPE and VALUE
#            elsif(($arrayDataTypeName eq $arrayTypeName) and ($arrayDataTypeCategory eq "VALUE" ))
#            {
#              #print "Parsing IMPLEMENTATION-DATA-TYPE of VALUE...... \n"; 	
#              my $intTypeName = getArrayDataType($element,$arrayTypeName);	
#              my $dataType = getDataTypeAR4($intTypeName);             	
#              my $compuMethod = getCompuMethodImplType($element,$arrayTypeName);					
#              my $dataConstraintsRef = getDataConstrRef($element,$arrayTypeName);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef);									
#              my @varProprties = ();
#              $varProprties[0] = $dataType;
#              $varProprties[1] = $lowerLimit;
#              $varProprties[2] = $upperLimit;	
#              $varProprties[3] = $compuMethod;  						
#              push(@{$parmIntTypes{$arrayDataElement} }, @varProprties);	              
#            }						
#          }	   
#        } 		
#        elsif($psaType->getAttribute("DEST") eq "APPLICATION-PRIMITIVE-DATA-TYPE")
#        {
#          #Extract Integer Type Name ########################################################################################################
#          my $implDataTypeName = $psaType->textContent;
#          $implDataTypeName=~ s/.*\///;		
#          my $intDataElement = ($sharedParameter->getChildrenByTagName("SHORT-NAME"))[0]->textContent;				
#          foreach my $appPrimitiveDataType($element->getElementsByTagName("APPLICATION-PRIMITIVE-DATA-TYPE"))
#          {				  			  
#            my $appPrimitiveDataTypeNameRef = (($appPrimitiveDataType->getChildrenByTagName("SHORT-NAME"))[0]->textContent);
#            my $appPrimitiveTypeCategory = (($appPrimitiveDataType->getChildrenByTagName("CATEGORY"))[0]->textContent);
#            if(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "VALUE" ))
#            {
#              #print "Parsing APPLICATION-PRIMITIVE-DATA-TYPE of VALUE...... \n";					
#              my $compuMethod = getCompuMethod($element,$implDataTypeName);		
#              my $implDataType = getImplDataType($element,$implDataTypeName);	
#              my $intTypeName = getArrayDataType($element,$implDataType);						
#              my $dataType = getDataTypeAR4($intTypeName);   
#              my $dataConstraintsRef = getDataConstrRef($element,$implDataType);
#              my $lowerLimit = getLowerLimitDC($element,$dataConstraintsRef);
#              my $upperLimit = getUpperLimitDC($element,$dataConstraintsRef); 	
#              my @varProprties = ();
#              $varProprties[0] = $dataType;
#              $varProprties[1] = $lowerLimit;
#              $varProprties[2] = $upperLimit;	
#              $varProprties[3] = $compuMethod;  						
#              push(@{$parmIntTypes{$intDataElement} }, @varProprties);	              
#            }
#            elsif(($appPrimitiveDataTypeNameRef eq $implDataTypeName) and ($appPrimitiveTypeCategory eq "BOOLEAN" ))
#            {					       
#              push (@boolParmElements,$intDataElement);	              
#            }						
#          }	   
#        }		
#      }
#    }
#    
#    #Read Runnables and Data Elements
#    readRunnables($element);
#
#    readLinearCompuMethods($element);
#		readUnitShartNames($element);    
#	}
  return 1;
} #End readModuleArxml

####################################################################################################
#
# Subroutine to Remove the Blank lines after deleteting unwanted nodes
#
####################################################################################################

sub removeBlankLines
{
  print "\n------------------------------------------------\n";
  print "[INFO]: Removing Blank Lines from the Generated ARXML file \n";
  print "\n------------------------------------------------\n";
  my ($file) = @_;  
  my $tmpfile = $ScriptPath.'tempfile.$$';
  my $bkpfile = $ScriptPath.'file_new.bak';	
  open FILE, $file or die "$!\n";  
  open OUT, '>' , $tmpfile or die "$!\n";		
  while(<FILE>) 
  {
    next if /^\s*$/;		
    print OUT $_;
  }
  close FILE; 
  close OUT;	
  #rename($file, $bkpfile) or die "Error in rename: $!\n";	
  unlink($file) or die "Error in File deletion";
  rename($tmpfile, $file) or die "Error in rename: $!";	
} # End removeBlankLines

####################################################################################################
#
# 
#
####################################################################################################

sub getDataType
{
  my $datatype = "";
  my($mystring) = @_;   
  if($mystring =~ m/Boolean/) { $datatype = "uint8";}
	elsif($mystring =~ m/boolean/) { $datatype = "uint8"; }
  elsif($mystring =~ m/UInt8/) { $datatype = "uint8"; }
  elsif($mystring =~ m/UInt16/) { $datatype = "uint16"; }
  elsif($mystring =~ m/UInt32/) { $datatype = "uint32"; }
  elsif($mystring =~ m/SInt8/) { $datatype = "sint8"; }
  elsif($mystring =~ m/SInt16/) { $datatype = "sint16"; }
  elsif($mystring =~ m/SInt32/) { $datatype = "sint32"; }
  elsif($mystring =~ m/real32/) { $datatype = "real32"; } 
  elsif($mystring =~ m/Real32/) { $datatype = "real32"; }
  elsif($mystring =~ m/REAL32/) { $datatype = "real32"; }
  elsif($mystring =~ m/Float/) { $datatype = "real32"; }
  else
  {
    print "[INFO]: Handle the Type: $mystring Manually \n";
  }  
  return $datatype;  
}

sub getDataTypeAR4
{
  my $datatype = "";
  my($mystring) = @_;  
  if($mystring =~ m/Boolean/) { $datatype = "uint8";}
	elsif($mystring =~ m/boolean/) { $datatype = "uint8"; }
  elsif($mystring =~ m/UInt8/) { $datatype = "uint8"; }
  elsif($mystring =~ m/UInt16/) { $datatype = "uint16"; }
  elsif($mystring =~ m/UInt32/) { $datatype = "uint32"; }
  elsif($mystring =~ m/SInt8/) { $datatype = "sint8"; }
  elsif($mystring =~ m/SInt16/) { $datatype = "sint16"; }
  elsif($mystring =~ m/SInt32/) { $datatype = "sint32"; }
  elsif($mystring =~ m/real32/) { $datatype = "real32"; } 
    elsif($mystring =~ m/Real32/) { $datatype = "real32"; }
      elsif($mystring =~ m/REAL32/) { $datatype = "real32"; }
        elsif($mystring =~ m/Float/) { $datatype = "real32"; }
  else{ return $mystring;}
  return $datatype;  
}

sub getRecordLayout
{
  my $recordLayout = "RB_Val_Wu8";
  my($mystring) = @_;  
  if($mystring =~ m/Boolean/) { $recordLayout = "RB_Val_Wu8";}
	elsif($mystring =~ m/boolean/) { $recordLayout = "RB_Val_Wu8"; }
  elsif($mystring =~ m/uint8/) { $recordLayout = "RB_Val_Wu8"; }
  elsif($mystring =~ m/uint16/) { $recordLayout = "RB_Val_Wu16"; }
  elsif($mystring =~ m/uint32/) { $recordLayout = "RB_Val_Wu32"; }
  elsif($mystring =~ m/sint8/) { $recordLayout = "RB_Val_Ws8"; }
  elsif($mystring =~ m/sint16/) { $recordLayout = "RB_Val_Ws16"; }
  elsif($mystring =~ m/sint32/) { $recordLayout = "RB_Val_Ws32"; } 
  elsif($mystring =~ m/real32/) { $recordLayout = "RB_Val_Wr32"; } 
  else
  {
    print "[INFO]: Handle Data Type Manually Unknow Data Type: $mystring \n";
  }
  return $recordLayout;  
}

sub getImplDataType
{
  my $implDataType = "";
  my($element,$appPrimDataType) = @_;  
	foreach my $dataTypeMap($element->getElementsByTagName("DATA-TYPE-MAP"))
	{
	  my $appDataTye=($dataTypeMap->getChildrenByTagName("APPLICATION-DATA-TYPE-REF"))[0]->textContent;
		$appDataTye=~ s/.*\///;
		if($appDataTye eq $appPrimDataType)
		{
		  $implDataType = ($dataTypeMap->getChildrenByTagName("IMPLEMENTATION-DATA-TYPE-REF"))[0]->textContent;
			$implDataType=~ s/.*\///;
			return $implDataType;
		}
	}
}

sub getCompuMethod
{
  my $compuMethod = "";
  my($element,$appPrimDataType) = @_;  
	foreach my $appPrimDataTypeRef($element->getElementsByTagName("APPLICATION-PRIMITIVE-DATA-TYPE"))
	{
	  my $appPrimDataTypeRefName=($appPrimDataTypeRef->getChildrenByTagName("SHORT-NAME"))[0]->textContent;		
		if($appPrimDataTypeRefName eq $appPrimDataType)
		{
		  $compuMethod = ((($appPrimDataTypeRef->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0])->getChildrenByTagName("COMPU-METHOD-REF"))[0]->textContent;
			$compuMethod=~ s/.*\///;			
			foreach my $compu($element->getElementsByTagName("COMPU-METHOD"))
			{
			  my $compuName = ($compu->getChildrenByTagName("SHORT-NAME"))[0]->textContent; 
				if(($compuName eq $compuMethod) and (($compu->getChildrenByTagName("CATEGORY"))[0]->textContent eq "IDENTICAL") )
				{ 
          $compuMethod = "OneToOne";          				
				}				
		  }
      return $compuMethod;			
		}		
	}	
}

sub getCompuMethodImplType
{
  my $compuMethod = "OneToOne";
  my($element,$implDataType) = @_;  
	foreach my $implDataTypeRef($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
	{
	  my $implDataTypeRefName=($implDataTypeRef->getChildrenByTagName("SHORT-NAME"))[0]->textContent;		
		if($implDataTypeRefName eq $implDataType)
		{
		  if((($implDataTypeRef->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0])->getChildrenByTagName("COMPU-METHOD-REF"))
			{
			  $compuMethod = ((($implDataTypeRef->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0])->getChildrenByTagName("COMPU-METHOD-REF"))[0]->textContent;
				$compuMethod=~ s/.*\///;		
        foreach my $compu($element->getElementsByTagName("COMPU-METHOD"))
			  {
				  my $compuName = ($compu->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
				  if(($compuName eq $compuMethod) and ((($compu->getChildrenByTagName("CATEGORY"))[0]->textContent) eq "IDENTICAL"))			    
				  {
				    $compuMethod = "OneToOne";
				  }
		    }				      			
		  }
			return $compuMethod;
		}
	}	
}

sub getArrayDataType
{
  my $arrayDataType = "";
  my($element,$implDataType) = @_; 
  my @implDataTypes = $element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE");
	if(@implDataTypes)
	{
	  foreach my $implDataTypeRef($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
	  {
	    my $implDataTypeRefName=($implDataTypeRef->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
		  if($implDataTypeRefName eq $implDataType)
		  {
		    $arrayDataType = (($implDataTypeRef->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0]->getChildrenByTagName("BASE-TYPE-REF"))[0]->textContent;
			  $arrayDataType=~ s/.*\///;
			  return $arrayDataType;
			}
		}
	}
	else
	{
	  print "ERROR: ARXML file is not self contianed\n";
		print "Pleas use proper ARXML file\n";
		print "-----------------------------------------\n";
		exit;
	}
}

sub getDataConstrRef
{
  my $dataConstrRef = "";
  my($element,$implDataType) = @_;  	
	my @implDataTypes = $element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE");
	if(@implDataTypes)
	{
	  foreach my $implDataTypeRef($element->getElementsByTagName("IMPLEMENTATION-DATA-TYPE"))
	  {
	    my $implDataTypeRefName=($implDataTypeRef->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
		  if($implDataTypeRefName eq $implDataType)
		  {
		    $dataConstrRef = (($implDataTypeRef->getElementsByTagName("SW-DATA-DEF-PROPS-CONDITIONAL"))[0]->getChildrenByTagName("DATA-CONSTR-REF"))[0]->textContent;
			  $dataConstrRef=~ s/.*\///;
			  return $dataConstrRef;
			}
		}
	}
	else
	{
	  print "ERROR: ARXML file is not self contianed\n";
		print "Pleas use proper ARXML file\n";
		print "-----------------------------------------\n";
		exit;
	}
}

sub getLowerLimit
{
  my $lowerLimit = 0;
  my ($element,$arrayTypeName) = @_;  
  if($arrayTypeName eq 'Boolean')
  {
    return $lowerLimit;
  }  
  foreach my $arrayType($element->getElementsByTagName("INTEGER-TYPE"))
  {
    if((($arrayType->getChildrenByTagName("SHORT-NAME"))[0]->textContent) ne $arrayTypeName) { next; }
    {
      $lowerLimit = ($arrayType->getChildrenByTagName("LOWER-LIMIT"))[0]->textContent;        
      return $lowerLimit;
    }	    
  }  
}   
  

sub getUpperLimit
{
  my $upperLimit = 1;
  my ($element,$arrayTypeName) = @_;
  if($arrayTypeName eq 'Boolean')
  {
    return $upperLimit;
  }
  foreach my $psaIntTypes($element->getElementsByTagName("INTEGER-TYPE"))
  {
    if((($psaIntTypes->getChildrenByTagName("SHORT-NAME"))[0]->textContent) ne $arrayTypeName) 
    { 
        next; 
    }
    {
      $upperLimit = ($psaIntTypes->getChildrenByTagName("UPPER-LIMIT"))[0]->textContent;            
      return $upperLimit;
    }    
  }  
}  

sub getDataConsReal
{
  my $DataConsReal = "DataConstrC_0_0560_1_0560";
  my ($pavastFile,$arrayTypeTref) = @_;
#  foreach my $swDataProp($pavastFile->getElementsByTagName("SW-DATA-DEF-PROPS"))
#  {
##    if(($swDataProp->getChildrenByTagName("SW-COMPU-METHOD-REF"))[0]->textContent)
##    {
##      if((($swDataProp->getChildrenByTagName("SW-COMPU-METHOD-REF"))[0]->textContent) eq $arrayTypeTref)
##      {
##        $DataConsReal = ($swDataProp->getChildrenByTagName("SW-DATA-CONSTR-REF"))[0]->textContent; 
##      }           
##    } 
##    else 
##    {
##        $DataConsReal = "else sle sel";
##    }  
#  }  
   return $DataConsReal;
}  

sub getLowerLimitDC
{
  my $lowerLimit = "";
  my($element,$dataConstraintsRef) = @_; 
	foreach my $DataConstr($element->getElementsByTagName("DATA-CONSTR"))
	{
	  if((($DataConstr->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $dataConstraintsRef)
		{
		  $lowerLimit = ((($DataConstr->getElementsByTagName("INTERNAL-CONSTRS"))[0])->getChildrenByTagName("LOWER-LIMIT"))[0]->textContent;  
			return $lowerLimit;
  	}
	}		
}

sub getUpperLimitDC
{
  my $upperLimit = "";
  my($element,$dataConstraintsRef) = @_; 
	foreach my $DataConstr($element->getElementsByTagName("DATA-CONSTR"))
	{
	  if((($DataConstr->getChildrenByTagName("SHORT-NAME"))[0]->textContent) eq $dataConstraintsRef)
		{
      $upperLimit = ((($DataConstr->getElementsByTagName("INTERNAL-CONSTRS"))[0])->getChildrenByTagName("UPPER-LIMIT"))[0]->textContent;  	
      return $upperLimit;			
		}
	}		
}

sub defineLowerLimit
{
  my ($datatype) = @_;
	my $lowerLimit = 0;
	if($datatype eq 'uint8')
  {
	  $lowerLimit = 0;      
	}
	elsif($datatype eq 'uint16')
	{
    $lowerLimit = 0;      
	}
	elsif($datatype eq 'uint32')
	{
    $lowerLimit = 0;      
	}
	elsif($datatype eq "sint8")
	{
	  $lowerLimit = -128;      
	}
	elsif($datatype eq "sint16")
	{
	  $lowerLimit = -32768;      
	}
	elsif($datatype eq "sint32")
	{
	  $lowerLimit = -2147483648;      
	} 
	elsif($datatype eq "Float")
	{
    $lowerLimit = -3.40282E38;
	}
	elsif($datatype eq "real32")
    {
    $lowerLimit = -2147483648;
    }
	return $lowerLimit;
} 

sub defineUpperLimit
{
  my ($datatype) = @_;
	my $upprLimit = 2147483647;
	if($datatype eq 'uint8')
  {
	  $upprLimit = 255;
	}
	elsif($datatype eq 'uint16')
	{
	  $upprLimit = 65535;
	}
	elsif($datatype eq 'uint32')
	{
	  $upprLimit = 4294967295;
	}
	elsif($datatype eq "sint8")
	{
	  $upprLimit = 127;
	}
	elsif($datatype eq "sint16")
	{
	  $upprLimit = 32767;
	}
	elsif($datatype eq "sint32")
	{
	  $upprLimit = 2147483647;
	} 
	elsif($datatype eq "Float")
	{
	  $upprLimit = 3.40282E38;
	}
	elsif($datatype eq "real32")
    {
      $upprLimit = 2147483647;
   }
	return $upprLimit;
} 

sub readRunnables
{
  my($element) = @_; 
  
  print "Reading Runnables ......\n";
  foreach my $runnable($element->getElementsByTagName("RUNNABLE-ENTITY"))
	{
    # print "Runnable Short Name: $runnable\n";
    my @dataSendPointElements =();
    my @dataReceivePointElements =();
	  my @dataWriteElements =();
    my @dataReadElements =();
    my $runnableShortName = ($runnable->getChildrenByTagName("SHORT-NAME"))[0]->textContent;
    #print "Runnable Short Name: $runnableShortName\n";
    
    #Read Data Send Points
    # Both Implicit and Explict access are added as OPTIMISED in PaVaSt
    my @dataSendPoints = $runnable->getElementsByTagName("DATA-SEND-POINTS") ;
    if(@dataSendPoints)
    {
      if($dataSendPoints[0]->getElementsByTagName("VARIABLE-ACCESS"))
      {
        foreach my $variableAccessDSP($dataSendPoints[0]->getElementsByTagName("VARIABLE-ACCESS"))
        {
          if($variableAccessDSP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))
          {
            my $dataElementDSP = ($variableAccessDSP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))[0]->textContent; 					
            $dataElementDSP=~ s/.*\///;			
            $dataElementDSP='DSP_'.$dataElementDSP;			      
            push(@dataSendPointElements,$dataElementDSP);            
          }
        }
        # Store Array to hash
        push(@{$runnableDetails{$runnableShortName}}, @dataSendPointElements);        
      }
    }  	
	
	  #Read write access
	  my @dataWriteAccess = $runnable->getElementsByTagName("DATA-WRITE-ACCESSS");
    if(@dataWriteAccess)
    {	   
      if($dataWriteAccess[0]->getElementsByTagName("VARIABLE-ACCESS"))
      {
        foreach my $variableAccessDSP($dataWriteAccess[0]->getElementsByTagName("VARIABLE-ACCESS"))
        {
          if($variableAccessDSP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))
          {
            my $dataElementDSP = ($variableAccessDSP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))[0]->textContent; 				
            $dataElementDSP=~ s/.*\///;			
            $dataElementDSP='DSP_'.$dataElementDSP;			
            push(@dataWriteElements,$dataElementDSP);            
          }
        }
        # Store Array to hash
        push(@{$runnableDetails{$runnableShortName}}, @dataWriteElements);        
      }
    }
    
    #Read Data Receive Points By Arguments
    # Both Implicit and Explict access are added as OPTIMISED in PaVaSt
    my @dataReceivePoints = $runnable->getElementsByTagName("DATA-RECEIVE-POINT-BY-ARGUMENTS"); 
    if(@dataReceivePoints)
    {
      if($dataReceivePoints[0]->getElementsByTagName("VARIABLE-ACCESS"))
      {
        foreach my $variableAccessDRP($dataReceivePoints[0]->getElementsByTagName("VARIABLE-ACCESS"))
        {
          if($variableAccessDRP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))
          {
            my $dataElementDRP = ($variableAccessDRP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))[0]->textContent;  
			      $dataElementDRP=~ s/.*\///;
			      $dataElementDRP='DRP_'.$dataElementDRP;
			      push(@dataReceivePointElements, $dataElementDRP);            
          }
        }        
        # Store Array to hash
        push(@{$runnableDetails{$runnableShortName}}, @dataReceivePointElements);
      }      
    }

    #Read Data Read Access
	  my @dataReadAcess = $runnable->getElementsByTagName("DATA-READ-ACCESSS"); 
    if(@dataReadAcess)
    {
      if($dataReadAcess[0]->getElementsByTagName("VARIABLE-ACCESS"))
      {
        foreach my $variableAccessDRP($dataReadAcess[0]->getElementsByTagName("VARIABLE-ACCESS"))
        {
          if($variableAccessDRP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))
          {
            my $dataElementDRP = ($variableAccessDRP->getElementsByTagName("TARGET-DATA-PROTOTYPE-REF"))[0]->textContent;  			
            $dataElementDRP=~ s/.*\///;			
            $dataElementDRP='DRP_'.$dataElementDRP;			
            push(@dataReadElements, $dataElementDRP);            
          }
        }        
        # Store Array to hash
        push(@{$runnableDetails{$runnableShortName}}, @dataReadElements);
      }      
    } 	
  }  	
}

sub readLinearCompuMethods
{
  my($element) = @_; 
	my @compuMethodDetails = ();
	print "Reading Compu Methods ......\n";
	foreach my $compuMethod($element->getElementsByTagName("COMPU-METHOD"))
	{
	  if((($compuMethod->getChildrenByTagName("CATEGORY"))[0]->textContent) eq "LINEAR")
		{
		  my $compuMethodName = ($compuMethod->getChildrenByTagName("SHORT-NAME"))[0]->textContent;       		 
      my $unit = ($compuMethod->getChildrenByTagName("UNIT-REF"))[0]->textContent; 			 
			$unit=~ s/.*\///;			 
			$compuMethodDetails[0]=$unit;
			$compuMethodDetails[1]=(($compuMethod->getElementsByTagName("COMPU-NUMERATOR"))[0]->getChildrenByTagName("V"))[0]->textContent;			 
			$compuMethodDetails[2]=(($compuMethod->getElementsByTagName("COMPU-NUMERATOR"))[0]->getChildrenByTagName("V"))[1]->textContent;			 
			$compuMethodDetails[3]=(($compuMethod->getElementsByTagName("COMPU-DENOMINATOR"))[0]->getChildrenByTagName("V"))[0]->textContent;			 
			push(@{$linearCompuMethods{$compuMethodName} }, @compuMethodDetails);	
	  }		 
  }  
}

sub readUnitShartNames
{
  my($element) = @_; 
	my @unitDetails = ();
	print "Reading Units ......\n";
	foreach my $unit($element->getElementsByTagName("UNIT"))
	{
	  my $unitShortName = ($unit->getChildrenByTagName("SHORT-NAME"))[0]->textContent;  
    my $unitDisplayName = '-';		 
    if($unit->getChildrenByTagName("DISPLAY-NAME"))
    {
		  $unitDisplayName = ($unit->getChildrenByTagName("DISPLAY-NAME"))[0]->textContent
		}
		$unitDetails[0]=$unitDisplayName;
    push(@{$unitShortNames{$unitShortName} }, @unitDetails);			 		 
  }  
}

sub replaceShortName 
{
  my ($element, $value) = @_;
  my $newNode = XML::LibXML::Element->new("SHORT-NAME");
  $newNode->appendText($value);
  $element->replaceNode($newNode);
}

sub replaceSwFeatureRef
{
  my ($element, $value) = @_;
  my $newNode = XML::LibXML::Element->new("SW-FEATURE-REF");
  $newNode->appendText($value);
  $element->replaceNode($newNode);
}

# Code Ends
